
/************************************************************************\ 
 *									*
 * grdut.c - grd utility routines					*
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
 * 17-Aug-95: routines copied from meshut                               *
 *									*
\************************************************************************/

#include <stdio.h>
#include <stdlib.h>

#include "general.h"
#include "fund.h"
#include "hash.h"

#include "grd.h"
#include "grdhs.h"
#include "grdut.h"


static Grid_type *ActGrid;

/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


int *MakeIndex( int vertex )

{
	int *new;

	new = (int *) malloc( vertex * sizeof( int ) );
	if( !new ) Error("MakeIndex: Cannot allocate index");

	return new;
}

int *CopyIndex( int vertex , int *index )

{
	int i;
	int *new;

	new = (int *) malloc( vertex * sizeof( int ) );
	if( !new ) Error("CopyIndex: Cannot allocate index");

	for(i=0;i<vertex;i++) {
		new[i] = index[i];
	}

	return new;
}

void InvertIndex( int *index , int nvert )

{
	int iaux,i;

	for(i=0,nvert--;i<nvert;i++,nvert--) {
		iaux=index[i];
		index[i]=index[nvert];
		index[nvert]=iaux;
	}
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


void PrintNodes( Hashtable_type H )

{
        Node_type *p;
	Point c;
	int n;

	ResetHashTable(H);
        while( (p = VisitHashTableN(H)) != NULL ) {
            c = p->coord;
            n = p->number;
            printf("%d %f %f\n",n,c.x,c.y);
        }
}

void PrintElems( Hashtable_type H )

{
        Elem_type *p;
	int *ix;
	int nv;

	ResetHashTable(H);
        while( (p = VisitHashTableE(H)) != NULL ) {
		nv = p->vertex;
		ix = p->index;
		printf("%d",p->number);
		while( nv-- > 0 )
		    printf(" %d",*ix++);
		printf("\n");
        }
}

void PrintLines( Hashtable_type H )

{
        Line_type *p;
	int *ix;
	int nv;

	ResetHashTable(H);
        while( (p = VisitHashTableL(H)) != NULL ) {
		nv = p->vertex;
		ix = p->index;
		printf("%d",p->number);
		while( nv-- > 0 )
		    printf(" %d",*ix++);
		printf("\n");
        }
}

void PrintLineS( Hashtable_type HL, Hashtable_type HN, int line, int invert )

{
        Line_type *p;
        Node_type *pn;
	int *ix;
	int i,nv,node;

        p = RetrieveByLineNumber(HL,line);
	if( p ) {
		nv = p->vertex;
		ix = p->index;
		if( invert ) InvertIndex(ix,nv);
		printf("%d %d\n",p->number,p->vertex);
		for(i=0;i<nv;i++) {
		    node = ix[i];
		    pn=RetrieveByNodeNumber(HN,node);
		    printf(" %f %f",pn->coord.x,pn->coord.y);
		    printf("         %d %d\n",pn->number,i+1);
		}
        }
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


Node_type *MakeNode( int n , int type , Point *c )

{
        Node_type *new;

	new = (Node_type *) malloc( sizeof( Node_type ) );
        if( !new ) Error("MakeNode: Cannot allocate node");

	new->number = n;
	new->type = type;
	new->extra = NULL;
	new->coord.x = c->x;
	new->coord.y = c->y;
	new->depth = NULLDEPTH;
	new->use = 0;

        return new;
}

Elem_type *MakeElem( int n , int type , int vertex , int *index )

{
	Elem_type *new;

	new = (Elem_type *) malloc( sizeof( Elem_type ) );
	if( !new ) Error("MakeElem: Cannot allocate node");

        new->number = n;
	new->type   = type;
	new->extra  = NULL;
        new->vertex = vertex;
	new->index  = index;
	new->depth = NULLDEPTH;

        return new;
}

Line_type *MakeLine( int n , int type , int vertex , int *index )

{
	Line_type *new;

	new = (Line_type *) malloc( sizeof( Line_type ) );
	if( !new ) Error("MakeLine: Cannot allocate node");

        new->number = n;
	new->type   = type;
	new->extra  = NULL;
        new->vertex = vertex;
	new->index  = index;
	new->depth = NULLDEPTH;

        return new;
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


void DeleteNode( Node_type *p )

{
	Hashtable_type H = ActGrid->HN;

	if( !p ) return;
	p=(Node_type *) DeleteHashByNumber(H,p->number);
	if(p->extra) free(p->extra);
	free(p);
}

void DeleteElem( Elem_type *p )

{
	Hashtable_type H = ActGrid->HE;

	if( !p ) return;
	p=(Elem_type *) DeleteHashByNumber(H,p->number);
	if(p->extra) free(p->extra);
	free(p->index);
	free(p);
}

void DeleteLine( Line_type *p )

{
	Hashtable_type H = ActGrid->HL;

	if( !p ) return;
	p=(Line_type *) DeleteHashByNumber(H,p->number);
	if(p->extra) free(p->extra);
	free(p->index);
	free(p);
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


int InsertNewNode( int type, float x, float y )

{
	Node_type *pn;
	Hashtable_type H = ActGrid->HN;
	int n = IncTotNodes();
	Point c;

	c.x = x; c.y = y;

	pn = MakeNode( n , type , &c );
	InsertByNodeNumber(H,pn);

	return n;
}

int InsertNewElem( int type, int vertex, int *index )

{
	Elem_type *pe;
	Hashtable_type H = ActGrid->HE;
	int n = IncTotElems();

	pe = MakeElem( n , type , vertex , index );
	InsertByElemNumber(H,pe);

	return n;
}

int InsertNewLine( int type, int vertex, int *index )

{
	Line_type *pl;
	Hashtable_type H = ActGrid->HL;
	int n = IncTotLines();

	pl = MakeLine( n , type , vertex , index );
	InsertByLineNumber(H,pl);

	return n;
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/


int GetTotNodes( void ) { return ActGrid->totnode; }
int GetTotElems( void ) { return ActGrid->totelem; }
int GetTotLines( void ) { return ActGrid->totline; }

int IncTotNodes( void ) { return ++ActGrid->totnode; }
int IncTotElems( void ) { return ++ActGrid->totelem; }
int IncTotLines( void ) { return ++ActGrid->totline; }

void SetTotNodes( int n ) { ActGrid->totnode = n; }
void SetTotElems( int n ) { ActGrid->totelem = n; }
void SetTotLines( int n ) { ActGrid->totline = n; }


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/

/* maybe can be deleted...
static int GetTotal( Hashtable_type H )

{
	int total = 0;
	Item_type *p;

	ResetHashTable(H);
	while( (p = (Item_type *) VisitHashTable(H)) != NULL ) {
		if( p->number > total ) total = p->number;
	}

	return total;
}
*/

Grid_type *MakeGrid( void )

{
	Grid_type *new;

	new = (Grid_type *) malloc( sizeof( Grid_type ) );
	if( !new ) Error("MakeGrid: Cannot allocate grid");

	new->HN = MakeHashTable();
	new->HE = MakeHashTable();
	new->HL = MakeHashTable();
	new->C  = MakeQueueTable();

	new->totnode = 0;
	new->totelem = 0;
	new->totline = 0;

	return new;
}

void SetGrid( Grid_type *G )

{
	ActGrid = G;
}

Grid_type *GetGrid( void )

{
	return ActGrid;
}


/**********************************************************************\
 ********************************************************************** 
\**********************************************************************/

