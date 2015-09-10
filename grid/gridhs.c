
/************************************************************************\
 *									*
 * gridhs.c - hash aministration routines and check of data strucures   *
 *									*
 * Copyright (c) 1992-1994 by Georg Umgiesser				*
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
 * 01-Oct-2004: new routines GetHashTable*() to get hash table          *
 * 14-Oct-97: Administer use of nodes with routines                     *
 *            new routine CheckUseConsistency()                         *
 * 13-Oct-97: in CheckConnections: FreeNumberList() is called only      *
 *              for non-null argument                                   *
 * 19-Sep-97: CheckUniqueVects introduced                               *
 *            Call to CheckNodes changed                                *
 * 12-Mar-95: CheckTwoVertexElems checks for elements with <3 vertices  *
 *            CheckOneVertexLines checks for lines with <2 vertices     *
 *            CheckIdentVertices checks for non unique nodes in element *
 * 11-Mar-95: corrected bug in MakeIndexNumber                          *
 *            -> created negative index number in overflow              *
 *            CheckConnections for any number of vertices               *
 *            CheckConnections did not free memory of                   *
 *            	allocated Conn structure !!!                            *
 *            Conn... is local to gridhs.c                              *
 *            CheckErrorE/N static to file                              *
 *            restructured organization of file                         *
 *            -> static routines introduced for local routines          *
 *            AreaElement, InvertIndex to gridut.c                      *
 *            CheckUniqueLines was not called                           *
 *            -> now called by CheckNodes                               *
 * 09-Mar-95: use double in AreaElement as accumulator                  *
 *            check for area <= AREAMIN in CheckClockwise               *
 *            in CheckConnections work only for 3 vertices              *
 * 13-Apr-94: completely restructured -> uses hash.c to do work         *
 * 06-Apr-94: copyright notice added to file				*
 * ..-...-92: routines written from scratch				*
 *									*
\************************************************************************/

#include <stdio.h>
#include <stdlib.h>

#include "general.h"
#include "list.h"
#include "queue.h"
#include "keybd.h"
#include "gridhs.h"
#include "gridnl.h"
#include "grid_df.h"
#include "grid_ex.h"

#include "grid_fp.h"	/* really only gridut.h and gridfi.h */


#define HASH_INDEX 317
#define MAX_INT 32767


#ifdef LOCAL_DEBUG
#define LOCAL_DEBUG
static void CheckErrorE( Hashtable_type H );
static void CheckErrorN( Hashtable_type H );
#endif


static int CheckUniqueNodes( Hashtable_type H );
static int CheckUniqueElems( Hashtable_type H );
static int CheckUniqueLines( Hashtable_type H );
static int CheckUniqueVects( Hashtable_type H );
static int CheckExistNodesE( Hashtable_type HN, Hashtable_type HE);
static int CheckExistNodesL( Hashtable_type HN, Hashtable_type HL);
static int CheckTwoVertexElems( Hashtable_type H );
static int CheckOneVertexLines( Hashtable_type H );

static int Elim2Lines( Hashtable_type HN , Hashtable_type HL );
static int CheckUse( Hashtable_type H );
static int CheckClockwise( Hashtable_type HN , Hashtable_type HE );
static int CheckIdentVertices( Hashtable_type H );


static int CheckIndexNumber( Hashtable_type H );
static int CheckConnections( Hashtable_type HN , Hashtable_type HE);


/*******************************************************************\
 *************** General Hash Table Utility Routines ***************
\*******************************************************************/


Hashtable_type GetHashTableN( void ) { return HNN; }
Hashtable_type GetHashTableE( void ) { return HEL; }
Hashtable_type GetHashTableL( void ) { return HLI; }

Node_type *VisitHashTableN( Hashtable_type H )

{
	return (Node_type *) VisitHashTable( H );
}

Elem_type *VisitHashTableE( Hashtable_type H )

{
        return (Elem_type *) VisitHashTable( H );
}

Line_type *VisitHashTableL( Hashtable_type H )

{
        return (Line_type *) VisitHashTable( H );
}


void InsertByNodeNumber( Hashtable_type H , Node_type *nodep )

{
	InsertHashByNumber( H , (void *) nodep , nodep->number );
}

void InsertByElemNumber( Hashtable_type H , Elem_type *elemp )

{
	InsertHashByNumber( H , (void *) elemp , elemp->number );
}

void InsertByLineNumber( Hashtable_type H , Line_type *linep )

{
	InsertHashByNumber( H , (void *) linep , linep->number );
}


Node_type *RetrieveByNodeNumber( Hashtable_type H , int node )

{
	return (Node_type *) RetrieveHashByNumber( H , node );
}

Elem_type *RetrieveByElemNumber( Hashtable_type H , int elem )

{
	return (Elem_type *) RetrieveHashByNumber( H , elem );
}

Line_type *RetrieveByLineNumber( Hashtable_type H , int line )

{
	return (Line_type *) RetrieveHashByNumber( H , line );
}


/*******************************************************************\
 ****************** Check Routines called by Main ******************
\*******************************************************************/


void CheckNodes( Hashtable_type HN , Hashtable_type HE , Hashtable_type HL 
			, Hashtable_type HV )

{
        int errors=FALSE;


        /* look for not unique numbers */
        errors += CheckUniqueNodes(HN);
        errors += CheckUniqueElems(HE);
        errors += CheckUniqueLines(HL);
        errors += CheckUniqueVects(HV);

        /* look if all nodes in element index are existing */
        errors += CheckExistNodesE(HN,HE);
        errors += CheckExistNodesL(HN,HL);

	/* look for element consisting of only two vertices */
	errors += CheckTwoVertexElems(HE);
	errors += CheckOneVertexLines(HL);


        if( errors == TRUE )
                Error("CheckNodes : Errors in structure of input file");
}


void CheckMore( Hashtable_type HN , Hashtable_type HE , Hashtable_type HL )

{
        int errors=0;

        /* should we eliminate double end points of lines */
        if( OpElim2Lines )
            errors = Elim2Lines(HN,HL);
        if( errors )
                press_any_key();


        /* look if all nodes are used */
        if( OpCheckUse )
                errors = CheckUse(HN);
        if( errors )
                press_any_key();


        /* look for clockwise elements */
        errors = CheckClockwise(HN,HE);
        if( errors )
                press_any_key();

	/* look for identical nodes in element */
	errors = CheckIdentVertices(HE);
        if( errors )
                press_any_key();

        /* look for identical elements */
        errors = CheckIndexNumber(HE);
        if( errors )
                press_any_key();


        /* look for strange connections */
        errors = CheckConnections(HN,HE);
        if( errors )
                press_any_key();
}


/*******************************************************************\
 ******************** Auxiliary Check Routines *********************
\*******************************************************************/


static int CheckUniqueNodes( Hashtable_type H )

{
	Node_type *pn;
        int errors=FALSE;

	ResetHashTable(H);
	while( (pn=(Node_type *) CheckHashByNumber(H)) != NULL ) {
            printf("Node number %d is not unique\n",pn->number);
            errors = TRUE;
	}
	return errors;
}

static int CheckUniqueElems( Hashtable_type H )

{
        Elem_type *pe;
        int errors=FALSE;

        ResetHashTable(H);
        while( (pe=(Elem_type *) CheckHashByNumber(H)) != NULL ) {
            printf("Element number %d is not unique\n",pe->number);
            errors = TRUE;
        }
        return errors;
}

static int CheckUniqueLines( Hashtable_type H )

{
        Line_type *pl;
        int errors=FALSE;

        ResetHashTable(H);
        while( (pl=(Line_type *) CheckHashByNumber(H)) != NULL ) {
            printf("Line number %d is not unique\n",pl->number);
            errors = TRUE;
        }
        return errors;
}

static int CheckUniqueVects( Hashtable_type H )

{
	Node_type *pv;
        int errors=FALSE;

	ResetHashTable(H);
	while( (pv=(Node_type *) CheckHashByNumber(H)) != NULL ) {
            printf("Vector number %d is not unique\n",pv->number);
            errors = TRUE;
	}
	return errors;
}

static int CheckExistNodesE( Hashtable_type HN , Hashtable_type HE )

{
        int i;
        int errors=FALSE;
        Elem_type *pe;
        Node_type *pn;

        ResetHashTable(HE);
        while( (pe=VisitHashTableE(HE)) != NULL ) {
                for(i=0;i<pe->vertex;i++) {
                        pn=RetrieveByNodeNumber(HN,pe->index[i]);
                        if( pn == NULL ){
                                printf("Node %d in element %d not found\n",
                                        pe->index[i], pe->number);
                                errors = TRUE;
                        } else {
				AddUseN(pn);
                        }
                }
        }
        return errors;
}

static int CheckExistNodesL( Hashtable_type HN , Hashtable_type HL )

{
        int i;
        int errors=FALSE;
        Line_type *pl;
        Node_type *pn;

        ResetHashTable(HL);
        while( (pl=VisitHashTableL(HL)) != NULL ) {
                for(i=0;i<pl->vertex;i++) {
                        pn=RetrieveByNodeNumber(HN,pl->index[i]);
                        if( pn == NULL ){
                                printf("Node %d in line %d not found\n",
                                        pl->index[i], pl->number);
                                errors = TRUE;
                        } else {
				AddUseN(pn);
                        }
                }
        }
        return errors;
}

static int CheckTwoVertexElems( Hashtable_type H )

{
        Elem_type *pe;
        int errors=FALSE;

        ResetHashTable(H);
        while( (pe=VisitHashTableE(H)) != NULL ) {
	    if( pe->vertex < 3 ) {
                printf("Element %d has only %d vertices\n"
				,pe->number,pe->vertex);
                errors = TRUE;
	    }
        }
        return errors;
}

static int CheckOneVertexLines( Hashtable_type H )

{
        Line_type *pl;
        int errors=FALSE;

        ResetHashTable(H);
        while( (pl=VisitHashTableL(H)) != NULL ) {
	    if( pl->vertex < 2 ) {
                printf("Line %d has only %d vertex\n"
				,pl->number,pl->vertex);
                errors = TRUE;
	    }
        }
        return errors;
}


static int Elim2Lines( Hashtable_type HN , Hashtable_type HL )

{
	Line_type *pl;
	Node_type *pn1,*pn2;
	int err=0;

        ResetHashTable(HL);
        while( (pl = VisitHashTableL(HL)) != NULL ) {
		pn1 = RetrieveByNodeNumber(HN,pl->index[0]);
		pn2 = RetrieveByNodeNumber(HN,pl->index[pl->vertex - 1]);
		if( pn1->number != pn2->number ) {
		    if( pn1->coord.x == pn2->coord.x &&
			pn1->coord.y == pn2->coord.y ) {
			    if( pn1->type != pn2->type ) {
				printf("Line %d : End points ",pl->number);
				printf("equal but different type - ");
				printf("Cannot eliminate\n");
				continue;
			    }
			    if( pn1->depth != pn2->depth ) {
				printf("Line %d : End points ",pl->number);
				printf("equal but different depth - ");
				printf("Cannot eliminate\n");
				continue;
			    }
			    if( GetUseN(pn2) == 1 ) {
				pl->index[pl->vertex - 1] = pl->index[0];
				DeleteUseN(pn2);
			    } else {
				pl->index[0] = pl->index[pl->vertex - 1];
				DeleteUseN(pn1);
			    }
			    printf("Line %d : End points ",pl->number);
			    printf("unified\n");
			    err++;
		    }
		}

        }
	return err;
}

void CheckUseConsistency( void )

{
        int i;
        int errors=FALSE;
        Elem_type *pe;
        Line_type *pl;
        Node_type *pn;

        ResetHashTable(HEL);
        while( (pe=VisitHashTableE(HEL)) != NULL ) {
                for(i=0;i<pe->vertex;i++) {
                        pn=RetrieveByNodeNumber(HNN,pe->index[i]);
			DeleteUseN(pn);
		}
	}

        ResetHashTable(HLI);
        while( (pl=VisitHashTableL(HLI)) != NULL ) {
                for(i=0;i<pl->vertex;i++) {
                        pn=RetrieveByNodeNumber(HNN,pl->index[i]);
			DeleteUseN(pn);
		}
	}

        ResetHashTable(HNN);
        while( (pn=VisitHashTableN(HNN)) != NULL ) {
                if( GetUseN(pn) ) {
		  errors = TRUE;
		  printf("Error in consistency of use: %d %d)\n",
			pn->number,GetUseN(pn));
		}
	}

	if( errors ) 
		Error("Error in consistency of use.");

        ResetHashTable(HEL);
        while( (pe=VisitHashTableE(HEL)) != NULL ) {
                for(i=0;i<pe->vertex;i++) {
                        pn=RetrieveByNodeNumber(HNN,pe->index[i]);
			AddUseN(pn);
		}
	}

        ResetHashTable(HLI);
        while( (pl=VisitHashTableL(HLI)) != NULL ) {
                for(i=0;i<pl->vertex;i++) {
                        pn=RetrieveByNodeNumber(HNN,pl->index[i]);
			AddUseN(pn);
		}
	}

	/* printf("CheckUseConsistency: use of nodes checked\n"); */
}
	
static int CheckUse( Hashtable_type H )

{
        int errors=FALSE;
        Node_type *pn;

        ResetHashTable(H);
        while( (pn=VisitHashTableN(H)) != NULL ) {
                if( !GetUseN(pn) ) {
                        printf("Node %d is not in use\n"
                                ,pn->number);
                        errors = TRUE;
                }
        }
        return errors;
}

static int CheckClockwise(  Hashtable_type HN , Hashtable_type HE )

{
	Elem_type *pe;
	float area;
	int errors=FALSE;

        ResetHashTable(HE);
        while( (pe = VisitHashTableE(HE)) != NULL ) {
                if( (area = AreaElement( HN , pe )) < 0 ) {
                        printf("Element %d in clockwise sense: changed.\n",
                                                pe->number);
                        area = -area;
			InvertIndex(pe->index,pe->vertex);
                        errors=TRUE;
                }
                if( area <= AREAMIN ) {
                        printf("Element %d too small : %f\n",
                                                pe->number,area);
                        errors=TRUE;
                }
        }
	return errors;
}

static int CheckIdentVertices( Hashtable_type H )

{
        Elem_type *pe;
        int *ind;
        int nvert,node,i;
	int errors=FALSE;

        ResetHashTable(H);
        while( (pe = VisitHashTableE(H)) != NULL ) {
                nvert = pe->vertex;
                ind   = pe->index;
                while( nvert-- ) {
                    node = ind[nvert];
                    for(i=0;i<nvert;i++) {
                        if( ind[i] == node ) {
                            printf("Element %d ",pe->number);
                            printf("contains node %d ",node);
                            printf("more than once\n");
                            errors=TRUE;
                        }
                    }
                }
        }
	return errors;
}


/*******************************************************************\
 ********************** Error Check Routines ***********************
\*******************************************************************/


#ifdef LOCAL_DEBUG

static void CheckErrorE( Hashtable_type H )

{
	int i=0,nv;
	int *ix;
	Elem_type *pe;

	ResetHashTable(H);
        while( (pe = VisitHashTableE(H)) != NULL ) {
                nv = pe->vertex;
                ix = pe->index;
		i++;
                printf("%d %d",i,pe->number);
                while( nv-- > 0 )
                    printf(" %d",*ix++);
                printf("\n");
        }
}

static void CheckErrorN( Hashtable_type H )

{
        int i=0;
        Node_type *pn;

        ResetHashTable(H);
        while( (pn = VisitHashTableN(H)) != NULL ) {
                printf("%d %d %f %f\n",++i,pn->number,
                        pn->coord.x,pn->coord.y);
        }
}

#endif


/*******************************************************************\
 ****************** Routines for Index Checking ********************
\*******************************************************************/


static void InsertByIndexNumber( Hashtable_type H , Elem_type *elemp );
static Elem_type *RetrieveByIndexNumber( Hashtable_type H , Elem_type *elemp );
static int MakeIndexNumber( Elem_type *elemp );


static int CheckIndexNumber( Hashtable_type HE )

{
	int errors=FALSE;
	int j,i,nvert;
	int ntot=0;
	int *id1, *id2;
        Elem_type *pe,*pe1,*pe2;
        Hashtable_type H;

        H=MakeHashTable();

        ResetHashTable(HE);
        while( (pe = VisitHashTableE(HE)) != NULL ) {
                InsertByIndexNumber(H,pe);
        }

	ResetHashTable(H);
	while( (pe2=(Elem_type *) CheckHashByNumber(H)) != NULL ) {
                pe1 = RetrieveByIndexNumber(H,pe2);
                ntot++;
                if( (nvert=pe1->vertex) != pe2->vertex ) continue;
                id1 = pe1->index;
                id2 = pe2->index;
                for(j=0;j<nvert;j++) {
                    for(i=0;i<nvert;i++)
                        if( id1[(j+i)%3] != id2[i] ) break;
                    if( i == nvert ) {
                        printf("Elements %d and %d are identical\n",
                                pe1->number, pe2->number);
                        errors=TRUE;
                    }
                }
	}

	/* if( ntot ) printf("CheckIndexNumber: ntot = %d\n",ntot); */

        FreeHashTable(H);

	return errors;
}

static void InsertByIndexNumber( Hashtable_type H , Elem_type *elemp )

{
	InsertHashByNumber( H , (void *) elemp , MakeIndexNumber(elemp) );
}

static Elem_type *RetrieveByIndexNumber( Hashtable_type H , Elem_type *elemp )

{
	return (Elem_type *) RetrieveHashByNumber( H , MakeIndexNumber(elemp) );
}

static int MakeIndexNumber( Elem_type *elemp )

{
	int i;
	long	int n1=1;
	long	int n2=0;

	for(i=0;i<elemp->vertex;i++) {
	  n1 *= ( elemp->index[i] % HASH_INDEX );
	  n2 += elemp->index[i];
	}

	return (int) ( abs(n1+n2) % MAX_INT );
}


/*******************************************************************\
 **************** Routines for Connection Checking *****************
\*******************************************************************/


typedef struct conn_tag {
	int number;
	Number_list_type *befor;
	Number_list_type *after;
	float angle;
} Conn_type;


static Conn_type *VisitHashTableC( Hashtable_type H );
static void InsertByConnNumber( Hashtable_type H , Conn_type *connp );
static Conn_type *RetrieveByConnNumber( Hashtable_type H , int node );
static Conn_type *MakeConn( int node );


static int CheckConnections( Hashtable_type HN , Hashtable_type HE)

{
	int i;
	int nvert;
	int node,after,befor;
	int *ind;
        int errors=FALSE;
        Node_type *pn;
	Elem_type *pe;
	Conn_type *pc;
        Number_list_type *pnla,*pnlb;
        Hashtable_type H;


        H=MakeHashTable();

        ResetHashTable(HN);
        while( (pn = VisitHashTableN(HN)) != NULL ) {
                pc = MakeConn( pn->number );
                InsertByConnNumber(H,pc);
        }

	ResetHashTable(HE);
        while( (pe = VisitHashTableE(HE)) != NULL ) {
	    nvert = pe->vertex;
            for(i=0;i<nvert;i++) {
                ind   = pe->index;
                node  = ind[i];
                after = ind[(i+1)%nvert];
                befor = ind[(i+nvert-1)%nvert];
                pc = RetrieveByConnNumber( H , node );

                pnla = FindNumberList( pc->after , befor );
                pnlb = FindNumberList( pc->befor , after );

                if( pnla == NULL && pnlb == NULL ) {
                        pc->after = InsertNumberList( pc->after , after );
                        pc->befor = InsertNumberList( pc->befor , befor );
                } else if( pnla == NULL ) {
                        pnlb->number=befor;
                } else if( pnlb == NULL ) {
                        pnla->number=after;
                } else {
                        pc->after = DeleteNumberList( pc->after , befor );
                        pc->befor = DeleteNumberList( pc->befor , after );
                }
            }
        }

	ResetHashTable(H);
        while( (pc = VisitHashTableC(H)) != NULL ) {
                if( !pc->befor && !pc->after ) { /* intern or not used */
                                ;
                } else if ( !pc->befor || !pc->after ) { /* error */
                        printf("Error in connections of node %d\n",pc->number);
                        errors=TRUE;
                } else if ( pc->befor->next || pc->after->next ) { /* error */
                        printf("Too many connections of node %d\n",pc->number);
                        errors=TRUE;
                }

                if( pc->befor ) FreeNumberList( pc->befor );
                if( pc->after ) FreeNumberList( pc->after );
		free(pc);
        }

        FreeHashTable(H);

	return errors;
}

static Conn_type *VisitHashTableC( Hashtable_type H )

{
        return (Conn_type *) VisitHashTable( H );
}

static void InsertByConnNumber( Hashtable_type H , Conn_type *connp )

{
	InsertHashByNumber( H , (void *) connp , connp->number );
}

static Conn_type *RetrieveByConnNumber( Hashtable_type H , int node )

{
	return (Conn_type *) RetrieveHashByNumber( H , node );
}

static Conn_type *MakeConn( int node )

{
	Conn_type *new;

	new = (Conn_type *) malloc( sizeof( Conn_type ) );

	if( !new ) Error("MakeConn : Cannot allocate Conn structure");

	new->number = node;
	new->befor=NULL;
	new->after=NULL;
	new->angle=0.;

        return new;
}
