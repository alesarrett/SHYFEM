
/************************************************************************\
 *									*
 * grdio.c - read/write grd files                                       *
 *									*
 * Copyright (c) 1995 by Georg Umgiesser				*
 *									*
 * Permission to use, copy, modify, and distribute this software	*
 * and its documentation for any purpose and without fee is hereby	*
 * granted, provided that the above copyright notice appear in all	*
 * copies and that both that copyright notice and this permission	*
 * notice appear in supporting documentation.				*
 *									*
 * This file is provided AS IS with no warranties of any kind.		*
 * The author shall have no liability with respect to the		*
 * infringement of copyrights, trade secrets or any patents by		*
 * this file or any part thereof.  In no event will the author		*
 * be liable for any lost revenue or profits or other special,		*
 * indirect and consequential damages.					*
 *									*
 * Comments and additions should be sent to the author:			*
 *									*
 *			Georg Umgiesser					*
 *			ISDGM/CNR					*
 *			S. Polo 1364					*
 *			30125 Venezia					*
 *			Italy						*
 *									*
 *			Tel.   : ++39-41-5216875			*
 *			Fax    : ++39-41-2602340			*
 *			E-Mail : georg@lagoon.isdgm.ve.cnr.it		*
 *									*
 * Revision History:							*
 * 01-Nov-2008: handle .grd extension in ReadStandard			*
 * 17-Aug-95: split from meshfi to make own file                        *
 *            NTotNodes... are static to file and accessed in           *
 *              grdut via GetTotNodes...                                *
 * 10-Feb-95: closefile calls fclose only if file opened                *
 * 08-Oct-94: reading/writing comments (QueueTable routines)            *
 * 07-May-94: new routines for opening and reading file                 *
 *									*
\************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "general.h"
#include "gustd.h"

#include "fund.h"
#include "hash.h"
#include "queue.h"
#include "args.h"

#include "grd.h"
#include "grdhs.h"
#include "grdut.h"

static int ReadNode( Hashtable_type H );
static int ReadElem( Hashtable_type H );
static int ReadLine( Hashtable_type H );

/*
	next vars are only local to this file and are only used to
	comunicate the total number of items already read to the
	single item reading routines
	-> this could be done better
*/

static int NTotNodes;
static int NTotElems;
static int NTotLines;

/**************************************************************************/

static FILE *FpFile=NULL;
static int   FpLine=0;
static int   FpStdio=0;

static int openfile( char *name , char *mode )

{
	FpLine=0;
	FpFile=fopen(name,mode);
	return FpFile ? 1 : 0;
}

static char *getnewline( void )

{
	char *s;

	s = getlin(FpFile);
	if( s )
		FpLine++;
	return s;
}

static char *stripext( char *s , char *ext ) /* strips ext from file name */

{
        int ls;
        char *t;

        ls = strlen(s);
        ls -= 4;

        if( ls > 0 ) {
                t = &s[ls];
                if( !strcmp(t,ext) ) {
                        t[0] = '\0';
                }
        }

        return s;
}

static char *makefilename( char *name , char *ext )
{
	name = stripext(name,ext);
	name = strcat(name,ext);
	return name;
}

static int gettotlines( void ) { return FpLine; }
static void closefile( void ) { if(FpFile && !FpStdio) fclose(FpFile); }
static void stdinfile( void ) { FpStdio = 1; FpFile = stdin; }
/* static void stdoutfile( void ) { FpStdio = 1; FpFile = stdout; } */

/**************************************************************************/


void ReadStandard( char *fname , Grid_type *G , char *ext )

{
	int comms=0,nodes=0,elems=0,lines=0;
	int nodemax=0,elemmax=0,linemax=0;
	int err=0;
	int error=FALSE;
	int narg,what,n;
	char *s,*t;

	if( !fname ) {
		stdinfile();
	} else {
		fname = makefilename(fname,ext);
		if( openfile(fname,"r") )
			printf("Reading file %s\n",fname);
		else
			Error2("ReadStandard : Cannot open file ",fname);
	}

	SetGrid(G);

	NTotNodes = GetTotNodes();
	NTotElems = GetTotElems();
	NTotLines = GetTotLines();

	while( (s=getnewline()) != NULL ) {
		t=firstchar(s);
		if( *t == '0' ) {
			t=savestring(s,-1);
			what=0;
		} else {
			narg = nargs(s);
			if(narg == 0) continue;
			t=readargs();
			what=atoi(t);
		}

		switch(what) {
		case 0 :			/* comment */
			EnQueue(G->C,(void *)t);
			comms++;
			break;
		case 1 :			/* node */
			n = ReadNode(G->HN);
			if( n ) nodes++ ; else error=TRUE ;
			if( n > nodemax ) nodemax=n;
			break;
		case 2 :			/* element */
			n = ReadElem(G->HE);
			if( n ) elems++ ; else error=TRUE ;
			if( n > elemmax ) elemmax=n;
			break;
		case 3 :			/* line */
			n = ReadLine(G->HL);
			if( n ) lines++ ; else error=TRUE ;
			if( n > linemax ) linemax=n;
			break;
		default:
			err++;
			printf("Line %d : ",gettotlines());
			printf("Shape %s not recognized\n",t);
			break;
		}
		if( error ) {
			printf("Read error in line %d :\n",gettotlines());
			error=FALSE;
			err++;
		}
	}

	SetTotNodes(NTotNodes+nodemax);
	SetTotElems(NTotElems+elemmax);
	SetTotLines(NTotLines+linemax);

	printf("%d lines read\n",gettotlines());
	printf("Following shapes read :\n");
	if(comms) printf("Comments : %d ",comms);
	if(nodes) printf("Nodes : %d ",nodes);
	if(elems) printf("Elements : %d ",elems);
	if(lines) printf("Lines : %d ",lines);
	printf("\n");
	if( err ) {
		Error("Errors detected in input file");
	}

	closefile();
}

void WriteStandard( char *fname , Grid_type *G )

{
	FILE *fp;
	Node_type *pn;
	Elem_type *pe;
	Line_type *pl;
	int nodes=0,elems=0,lines=0,comments=0;
	int i,j;
	char *s;

	if( !fname )
		fp = stdout;
	else if( (fp=fopen(fname,"w")) != NULL )
                printf("Writing file %s\n",fname);
        else
                Error2("WriteStandard : Cannot open file ",fname);

	SetGrid(G);

	NTotNodes = GetTotNodes();
	NTotElems = GetTotElems();
	NTotLines = GetTotLines();

	while( (s=(char *)DeQueue(G->C)) != NULL ) {
		fprintf(fp,"%s\n",s);
		comments++;
	}
        printf("Comments written : %d\n",comments);

	fprintf(fp,"\n");

        for(i=1;i<=NTotNodes;i++) {
          if( (pn=RetrieveByNodeNumber(G->HN,i)) != NULL ) {
                fprintf(fp,"1 %d %d %f %f"
                        ,pn->number
                        ,(int) pn->type
                        ,pn->coord.x
                        ,pn->coord.y
                        );
		if( pn->depth != NULLDEPTH )
			fprintf(fp," %f\n",pn->depth);
		else
			fprintf(fp,"\n");
                nodes++;
          }
        }
        printf("Nodes written : %d\n",nodes);

	fprintf(fp,"\n");

        for(i=1;i<=NTotElems;i++) {
          if( (pe=RetrieveByElemNumber(G->HE,i)) != NULL ) {
                fprintf(fp,"2 %d %d %d"
                        ,pe->number
                        ,(int) pe->type
			,pe->vertex
                        );

		for(j=0;j<pe->vertex;j++) {
			if( j%10 == 0 && pe->vertex > 3 )
				fprintf(fp,"\n");
			fprintf(fp," %d",pe->index[j]);
		}

                if( pe->depth != NULLDEPTH )
                        fprintf(fp," %f\n",pe->depth);
                else
                        fprintf(fp,"\n");
                elems++;
          }
        }
        printf("Elements written : %d\n",elems);

	fprintf(fp,"\n");

        for(i=1;i<=NTotLines;i++) {
          if( (pl=RetrieveByLineNumber(G->HL,i)) != NULL ) {
                fprintf(fp,"3 %d %d %d"
                        ,pl->number
                        ,(int) pl->type
                        ,pl->vertex
                        );

                for(j=0;j<pl->vertex;j++) {
                        if( j%10 == 0 )
                                fprintf(fp,"\n");
                        fprintf(fp," %d",pl->index[j]);
                }

                if( pl->depth != NULLDEPTH )
                        fprintf(fp," %f\n",pl->depth);
                else
                        fprintf(fp,"\n");
                lines++;
          }
        }
        printf("Lines written : %d\n",lines);

	fclose(fp);
}

static int ReadNode( Hashtable_type H )

{
	char *t;
	int number,ntype;
	Point c;
	float depth;
	Node_type *p;

	t=readargs();
	if( !t ) return 0;
	number = atoi(t);

	t=readargs();
	if( !t ) return 0;
	ntype = atoi(t);

	t=readargs();
	if( !t ) return 0;
	c.x = atof(t);

	t=readargs();
	if( !t ) return 0;
	c.y = atof(t);

	t=readargs();
	if( !t )
		depth = NULLDEPTH;
	else
		depth = atof(t);

	p=MakeNode(number+NTotNodes,ntype,&c);
	p->depth = depth;
	InsertByNodeNumber(H,p);

	return number;
}

static int ReadElem( Hashtable_type H )

{
	char *t,*s;
	int number,ntype;
	int i,vertex;
	int *index;
	float depth;
	Elem_type *p;

	t=readargs();
	if( !t ) return 0;
	number = atoi(t);

	t=readargs();
	if( !t ) return 0;
	ntype = atoi(t);

	t=readargs();
	if( !t ) return 0;
	vertex = atoi(t);

	index = MakeIndex(vertex);

	i=0;
	while( i<vertex ) {
		t=readargs();
		if( !t ) {
			s=getnewline();
			if( !s ) return 0;
			initargs(s);
		} else {
			index[i++] = atoi(t) + NTotNodes;
		}
	}

	t=readargs();
	if( !t )
		depth = NULLDEPTH;
	else
		depth = atof(t);

	p = MakeElem(number+NTotElems,ntype,vertex,index);
	p->depth = depth;
	InsertByElemNumber(H,p);

	return number;
}

static int ReadLine( Hashtable_type H )

{
	char *t,*s;
	int number,ntype;
	int i,vertex;
	int *index;
	float depth;
	Line_type *p;

	t=readargs();
	if( !t ) return 0;
	number = atoi(t);

	t=readargs();
	if( !t ) return 0;
	ntype = atoi(t);

	t=readargs();
	if( !t ) return 0;
	vertex = atoi(t);

	index = MakeIndex(vertex);

	i=0;
	while( i<vertex ) {
		t=readargs();
		if( !t ) {
			s=getnewline();
			if( !s ) return 0;
			initargs(s);
		} else {
			index[i++] = atoi(t) + NTotNodes;
		}
	}

	t=readargs();
	if( !t )
		depth = NULLDEPTH;
	else
		depth = atof(t);

	p = MakeLine(number+NTotLines,ntype,vertex,index);
	p->depth = depth;
	InsertByLineNumber(H,p);

	return number;
}

