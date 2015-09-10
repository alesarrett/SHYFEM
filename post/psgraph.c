
/* debugging: look for setcolor_ggu and post_ggu */

/************************************************************************\ 
 *									*
 * psgraph.c - graphic routines for postscript output			*
 *									*
 * Copyright (c) 1992-2010 by Georg Umgiesser				*
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
 *			ISDGM-CNR					*
 *			Castello 1364/A					*
 *			30122 Venezia					*
 *			Italy						*
 *									*
 *			Tel.   : ++39-41-2404773			*
 *			Fax    : ++39-41-5204126			*
 *			E-Mail : georg.umgiesser@ismar.cnr.it		*
 *									*
 * Revision History:							*
 * 29-Sep-2010: new routine PsArcFill()					*
 * 23-Feb-2010: change color table in PS file, default color table	*
 * 22-Feb-2010: new flag NoClip and routine PsSetNoClip()		*
 * 14-Sep-2009: new routine PsCmLength() to get length in cm		*
 * 12-Jun-2009: maximize viewport for new factor			*
 * 11-Jun-2009: new routine PsFactorScale() for spheric coordinates	*
 * 06-Apr-2009: changes in pcalp.f to avoid compiler warnings		*
 * 27-Jan-2009: bug computing VS in PsTextSetCenter()			*
 * 20-Jan-2009: text centering routines					*
 * 09-Dec-2008: small changes to Makefile				*
 * 16-Apr-2008: New Makefile structure					*
 * 20-Mar-2007: Fake                                                    *
 * 18-Oct-2006: Minor                                                   *
 * 06-Dec-2004: new copyright and version                               *
 * 24-Sep-2004: new routine PsFlush                                     *
 * 28-Apr-2004: new routines dash, rotate text and arc                  *
 * 18-Aug-2003: new routines dealing with color table			*
 * 26-Apr-2001: new routine PsSetPointSize                              *
 * 12-Sep-97: PsAdjustScale becomes static, PsWindow -> PsSetWorld      *
 * 11-Sep-97: minor modifications (PsGraphOpen,...)                     *
 * 03-Jun-97: PsRectFill() optimized, also PsSetColor() for Hue         *
 * 09-May-97: append feature in PsText()                                *
 * 03-May-97: restructured, PsRectFill() new calling arguments,         *
 *            no integer color any more                                 *
 * 07-Dec-95: PPageHeader() now declared and defined static (bug)       *
 * 21-Oct-94: PSetClipWindow does clipping,                             *
 *            translate whole plot area 0.5 cm into the paper           *
 *            change names from Q to P                                  *
 *            rectify scale with PRectifyScale (Aspect ratios are       *
 *              not distorted anymore                                   *
 * 06-Apr-94: copyright notice added to file				*
 * ..-...-92: routines written from scratch				*
 *									*
\************************************************************************/

/**********************************************/
static char  VERSION [7] ="1.78";
/**********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "general.h"
#include "gustd.h"
#include "colorutil.h"
#include "psgraph.h"


#define PsxWtoV(x) (SxWtoV*((x)-WinXmin)+ViewLeft)
#define PsyWtoV(y) (SyWtoV*((y)-WinYmin)+ViewBottom)
#define PsxVtoW(x) (SxVtoW*((x)-ViewLeft)+WinXmin)
#define PsyVtoW(y) (SyVtoW*((y)-ViewBottom)+WinYmin)

#define InSide(x,y) ( NoClip || \
			( (x) >=ViewLeft && (x) <= ViewRight && \
			  (y) >= ViewBottom && (y) <= ViewTop ) )

#define MINMAX(c) 					\
			if( (c) < 0. ) {		\
				(c) = 0.;		\
			} else if( (c) > 1. ) {		\
				(c) = 1.;		\
			}

#define SETCOLOR	if( ColorChanged == YES ) PsSetColor()
#define SETTEXT		if(  FontChanged == YES ) PsSetFont()
#define ISWHITE		( IsWhite && !BPaintWhite )
#define MUSTROTATE      ( FontRotate != 0. )

#define CMODE_GRAY	1
#define CMODE_HSB	2
#define CMODE_RGB	4
#define CMODE_COLOR	8

#define FLUSH	0
#define APPEND	1

#define LINEWIDTH       0.01
#define POINTSIZE       0.01
#define FONTSIZE        12

#define TFACTOR		(5.1/3.)	/* text factor for unknown reason */
#define POINTS_IN_CM	28.3		/* points in cm */

#define MAX_VIEW_X	19.0		/* max Viewport (x) in cm */
#define MAX_VIEW_Y	28.0		/* max Viewport (y) in cm */

static long int NPlot       = 0;	/* number of plotted items */
static long int NPath       = 0;	/* subpaths in actual path */
static      int NPage       = 0;	/* actual page */
static	    int NClip       = 0;	/* number of page clipping */
static	    int NoClip      = 0;	/* flag for no clipping */
static	    int BOutSide    = NO;	/* actual point is outside ? */
static	    int BPageOpened = NO;	/* page has been opened for plot ? */
static	    int BPaintWhite = NO;	/* paint with white ? (only for gray) */

/*****************************************************************/


/* viewport coordinates relative to page - (left,bottom) = (0,0) */

static float ViewLeft   = 0.;
static float ViewTop    = 0.;
static float ViewRight  = 0.;
static float ViewBottom = 0.;

static float WinXmin  = 0.;
static float WinYmin  = 0.;
static float WinXmax  = 0.;
static float WinYmax  = 0.;

static float SxWtoV   = 0.;
static float SyWtoV   = 0.;
static float SxVtoW   = 0.;
static float SyVtoW   = 0.;

/*
static int	LineCap		= 1;
static int	LineJoin	= 1;
*/
static float    LineWidth       = LINEWIDTH;
static float    PointSize       = POINTSIZE;    /* size for single point */

static char	Font[81]	= "Courier";
static float    FontSize        = FONTSIZE;
static float    FontRotate      = 0.;
static int	FontChanged	= NO;

static float	C1		= 0.;		/* gray, hue, red */
static float	C2		= 0.;		/* sat, green */
static float	C3		= 0.;		/* bri, blue */
static int	ColorMode	= CMODE_GRAY;
static int	ColorChanged	= NO;
static int	IsWhite		= NO;
static int	DefColorTable	= 0;

static int	Csize		= 0;
static float	*CT1		= NULL;
static float	*CT2		= NULL;
static float	*CT3		= NULL;

static float	XAct		= 0.;
static float	YAct		= 0.;

static int	TEST		= 0;

static float	HCenter		= -1;
static float	VCenter		= -1;

static FILE	*FP		= NULL;

/* internal routines */

static void PsPageHeader( void );
static void PsReset( void );
static void PsSetClipWindow( void );
static void PsStroke( int mode );
static void PsSetColor( void );
static void PsSetFont( void );

/* 
	scale used : 28.3

	corresponds to 1. cm

	28.3 points =^= 1.0 cm
	72   points =^= 1.0 inch
   ==>	1.0 inch = (72/28.3) cm = 2.54 cm
 */
	/* unit in centimeters */

/*
	every page resets parameters to initital
	every call to SetViewport calls PsReset, so
	changed parameters on one page are always
	conserved
*/
/*
 *	to do : setlinewidth, rotate, dash,...
 */

/*****************************************************************/
/****************** Static Routines ******************************/
/*****************************************************************/

static void PsPageHeader( void )

{
    NPage++;
    NPlot = 0;
    NPath = 0;
    NClip = 0;
    NoClip = 0;
    BOutSide = NO;
    BPaintWhite = NO;

    fprintf(FP,"%%%%Page: %d %d\n",NPage,NPage);
    fprintf(FP,"%%%%BeginPageSetup\n");
    fprintf(FP,"GS\n");
/*    fprintf(FP,"initmatrix %f dup scale\n",POINTS_IN_CM); */
    fprintf(FP,"%f dup scale\n",POINTS_IN_CM);
    fprintf(FP,"1.0 1.0 translate\n");
    fprintf(FP,"1 LC 1 LJ\n");

    PsPaintWhite(NO);
    PsSetGray(0.);
    LineWidth = LINEWIDTH;
    PointSize = POINTSIZE;
    FontRotate = 0.0;
    PsResetDashPattern();
    PsTextPointSize(FONTSIZE);
    PsTextFont("Courier");

    PsSetViewport(0.0,0.0,19.,28.0);
    PsSetWorld(0.0,0.0,19.,28.0);

    fprintf(FP,"%%%%EndPageSetup\n");
}

static void PsReset( void )

{
	PsSetColor();
	PsSetLineWidth(LineWidth);
	PsSetFont();
}

static void PsSetNoClip( void )

{
	NoClip = 1;		/* flag to avoid clipping */
}

static void PsSetClipWindow( void )

{
	float x,y,width,height;

	NoClip = 0;

	x = ViewLeft;
	y = ViewBottom;
	width = ViewRight - x;
	height = ViewTop - y;

	PsStroke(FLUSH);
	fprintf(FP,"%% new clipping window\n");
	if( NClip ) {
		fprintf(FP,"GR GS\n");
	} else {
		fprintf(FP,"GS\n");
	}
	PsReset();	/* re-establish parameters from before */
	fprintf(FP,"N %1.3f %1.3f M\n",x,y);
	fprintf(FP,"%1.3f %1.3f L\n",x+width,y);
	fprintf(FP,"%1.3f %1.3f L\n",x+width,y+height);
	fprintf(FP,"%1.3f %1.3f L\n",x,y+height);
	fprintf(FP,"CP clip N\n");
	NClip++;
}

static void PsStroke( int mode )

/*
    mode == FLUSH  -> flush buffer
    mode == APPEND -> increment counter
 */

{
	if( mode == FLUSH && NPath != 0 ) {
		fprintf(FP,"S\n");
		NPath=0;
	} else if( mode == APPEND ) {
		NPath++;
		if( NPath > 100 ) {
			fprintf(FP,"S\n");
			NPath=0;
		}
	}
}
			
/*****************************************************************/
/******************* Administration Routines *********************/
/*****************************************************************/

void PsGraphInit( char *file )

{
    FILE *fp;
    static char sinit[] = {"%!PS-Adobe-3.0\n"};

    if( file && *file != '\0' ) {
      fp=fopen(file,"w");
      if(fp) {
	FP = fp;
      } else {
	Error2("Cannot open plot file : ",file);
      }
    } else {
      FP = stdout;
    }

    fprintf(FP,"%s",sinit);
    fprintf(FP,"%%%%BoundingBox: 10 10 588 824\n"); /* A4 paper 21x29.5cm */
    fprintf(FP,"%%%%Pages: (atend)\n");
    fprintf(FP,"%%%%Title: PostScript Graphics %s - ",VERSION);
    fprintf(FP,"(c) 1994-2010 Georg Umgiesser\n");
    fprintf(FP,"%%%%Creator: psgraph\n");
    fprintf(FP,"%%%%CreationDate: %s\n",GetTime());
    fprintf(FP,"%%%%EndComments\n");
    fprintf(FP,"%% ***********************************************\n");
    fprintf(FP,"%% * PostScript Graphics %-6.6s                  *\n",VERSION);
    fprintf(FP,"%% * Copyright (c) 1994-2010 Georg Umgiesser     *\n");
    fprintf(FP,"%% * written by                                  *\n");
    fprintf(FP,"%% * Georg Umgiesser, ISMAR-CNR                  *\n");
    fprintf(FP,"%% * 1364/A Castello, 30122 Venezia, Italy       *\n");
    fprintf(FP,"%% * Tel.   : ++39-041-2404773                   *\n");
    fprintf(FP,"%% * Fax    : ++39-041-5204126                   *\n");
    fprintf(FP,"%% * E-Mail : georg.umgiesser@ismar.cnr.it       *\n");
    fprintf(FP,"%% ***********************************************\n");

    fprintf(FP,"%%%%BeginProlog\n");

    fprintf(FP,"%%%%BeginResource: general_procset\n");
    fprintf(FP,"/M /moveto load def\n");
    fprintf(FP,"/L /lineto load def\n");
    fprintf(FP,"/RM /rmoveto load def\n");
    fprintf(FP,"/RL /rlineto load def\n");
    fprintf(FP,"/S /stroke load def\n");
    fprintf(FP,"/CP /closepath load def\n");
    fprintf(FP,"/F /fill load def\n");
    fprintf(FP,"/G /setgray load def\n");
    fprintf(FP,"/HSB /sethsbcolor load def\n");
    fprintf(FP,"/H { 1 1 sethsbcolor } bind def\n");
    fprintf(FP,"/RGB /setrgbcolor load def\n");
    fprintf(FP,"/C /G load def\n");		/* generic color */
    fprintf(FP,"%%/C /H load def\n");		/* generic color */
    fprintf(FP,"/N /newpath load def\n");
    fprintf(FP,"/CRP /currentpoint load def\n");
    fprintf(FP,"/SW /stringwidth load def\n");
    fprintf(FP,"/LC /setlinecap load def\n");
    fprintf(FP,"/LJ /setlinejoin load def\n");
    fprintf(FP,"/LW /setlinewidth load def\n");
    fprintf(FP,"/GS /gsave load def\n");
    fprintf(FP,"/GR /grestore load def\n");
    fprintf(FP,"/FF /findfont load def\n");
    fprintf(FP,"/CF /scalefont load def\n");
    fprintf(FP,"/SF /setfont load def\n");

    fprintf(FP,"/ColorTable %d def\n",DefColorTable);
    fprintf(FP,"/ColorInvert %d def\n",0);

    fprintf(FP,"/str 50 string def\n");
    fprintf(FP,"/Print {(Printing: |) print str cvs print (|\n) print} def\n");
    fprintf(FP,"/VS 0 def\n");

    fprintf(FP,"/Lshow {0 VS RM show} def\n");
    fprintf(FP,"/Rshow {dup SW pop neg VS RM show} def\n");
    fprintf(FP,"/Cshow {dup SW pop -2 div VS RM show} def\n");

    fprintf(FP,"/RF { M dup 0 RL exch 0 exch RL neg 0 RL CP F } bind def\n");
    fprintf(FP,"/TRSF { /Times-Roman FF exch CF SF } bind def %% points\n");
    fprintf(FP,"/AW { TRSF M show } bind def %% (text) x y points\n");
    fprintf(FP,"%%%%EndResource\n");

    fprintf(FP,"%%%%BeginResource: color_table\n");
    fprintf(FP,"0 ColorInvert eq { /INV {} def } \n");
    fprintf(FP,"                 { /INV {1 sub neg} def } ifelse\n");
    fprintf(FP,"/BWR {INV dup 0.5 le \n");
    fprintf(FP,"           { 0.666 exch 2 mul 1 sub neg 1 HSB }\n");
    fprintf(FP,"           { 1 exch 0.5 sub 2 mul 1 HSB }\n");
    fprintf(FP,"           ifelse } def\n");
    fprintf(FP,"/BBR {INV dup 0.5 le \n");
    fprintf(FP,"           { 0.666 exch 1 exch 2 mul 1 sub neg HSB }\n");
    fprintf(FP,"           { 1 exch 1 exch 0.5 sub 2 mul HSB }\n");
    fprintf(FP,"           ifelse } def\n");
    fprintf(FP,"0 ColorTable eq { /C { INV G } bind def } if\n");
    fprintf(FP,"1 ColorTable eq { /C { INV H } bind def } if\n");
    fprintf(FP,"2 ColorTable eq { /C { INV 0.666 exch 1 HSB } bind def } if\n");
    fprintf(FP,"3 ColorTable eq { /C { INV 1 exch 1 HSB } bind def } if\n");
    fprintf(FP,"4 ColorTable eq { /C /BWR load def } if\n");
    fprintf(FP,"5 ColorTable eq { /C /BBR load def } if\n");
    fprintf(FP,"6 ColorTable eq { /C { INV sqrt H } bind def } if\n");
    fprintf(FP,"7 ColorTable eq { /C { INV dup mul H } bind def } if\n");
    fprintf(FP,"%%%%EndResource\n");

    fprintf(FP,"%%%%BeginResource: eps_procset\n");
    fprintf(FP,"/BeginEPSF {\n");
    fprintf(FP,"  /b4_Inc_state save def\n");
    fprintf(FP,"  /dict_count countdictstack def\n");
    fprintf(FP,"  /op_count count 1 sub def\n");
    fprintf(FP,"  userdict begin\n");
    fprintf(FP,"  /showpage { } def\n");
    fprintf(FP,"  0 setgray 0 setlinecap \n");
    fprintf(FP,"  1 setlinewidth 0 setlinejoin\n");
    fprintf(FP,"  10 setmiterlimit [ ] 0 setdash newpath\n");
    fprintf(FP,"  languagelevel where\n");
    fprintf(FP,"  { pop languagelevel\n");
    fprintf(FP,"  1 ne\n");
    fprintf(FP,"    {false setstrokeadjust false setoverprint\n");
    fprintf(FP,"    } if\n");
    fprintf(FP,"  } if\n");
    fprintf(FP,"} bind def\n");
    fprintf(FP,"/EndEPSF {\n");
    fprintf(FP,"  count op_count sub {pop} repeat\n");
    fprintf(FP,"  countdictstack dict_count sub {end} repeat\n");
    fprintf(FP,"  b4_Inc_state restore\n");
    fprintf(FP,"} bind def\n");
    fprintf(FP,"/Rect { %% llx lly w h\n");
    fprintf(FP,"  4 2 roll moveto 1 index 0 rlineto\n");
    fprintf(FP,"  0 exch rlineto neg 0 rlineto closepath\n");
    fprintf(FP,"} bind def\n");
    fprintf(FP,"/ClipRect { %% llx lly w h\n");
    fprintf(FP,"  Rect clip newpath\n");
    fprintf(FP,"} bind def\n");
    fprintf(FP,"%%%%EndResource\n");

    fprintf(FP,"%%%%EndProlog\n");
    fprintf(FP,"%%%%BeginSetup\n");
    fprintf(FP,"%%%%EndSetup\n");

    PsStartPage();
}

void PsGraphOpen( void )

{
	PsGraphInit("plot.ps");
}

void PsGraphClose( void )

{
    PsEndPage();

    fprintf(FP,"%%%%Trailer\n"); 
    fprintf(FP,"%%%%Pages: %d\n",NPage);
    fprintf(FP,"%%%%EOF\n"); 
    fclose(FP);
    FP=NULL;

    if( !NPlot )
	printf("PsGraphClose: empty last page\n");
}

void PsStartPage( void )

{
    if( !BPageOpened ) {
        BPageOpened = 1;
        PsPageHeader();
    }
}

void PsEndPage( void )

{
    if( BPageOpened ) {
        BPageOpened = 0;
        PsStroke(FLUSH);
	if( NClip ) fprintf(FP,"GR\n");
        fprintf(FP,"GR\n");
        fprintf(FP,"%%PsEndPage\n");
        fprintf(FP,"showpage\n");
    }
}

void PsNewPage( void )

{
    PsEndPage();
    PsStartPage();
}

/***********************************************************************/
/************************ Color Routines *******************************/
/***********************************************************************/

static void PsSetColor( void )

{
//	PsComment("aiuto..."); /* setcolor_ggu */
	PsFlush();

//	  printf("setcolor_ggu %i RGB\n",ColorMode);
	PsStroke(FLUSH);
//	  printf("setcolor_ggu %i RGB\n",ColorMode);
	if( ColorMode == CMODE_COLOR ) {
	  if( ! ISWHITE ) fprintf(FP,"%1.3f C\n",C1);
	} else if( ColorMode == CMODE_GRAY ) {
//	  printf("setcolor_ggu 1 %i RGB\n",ColorMode);
//	  printf("setcolor_ggu 2 %i RGB\n",IsWhite);
//	  printf("setcolor_ggu 3 %i RGB\n",BPaintWhite);
//	  printf("setcolor_ggu 4 %f RGB\n",C1);
//	  printf("setcolor_ggu 5 %i RGB\n",FP);
	  if( ! (ISWHITE) ) fprintf(FP,"%1.3f G\n",C1);
//	  printf("setcolor_ggu 9 %i RGB\n",ColorMode);
	} else if( ColorMode == CMODE_HSB ) {
	  if( C2 == 1. && C3 == 1. ) {
	    fprintf(FP,"%1.3f H\n",C1);
	  } else {
	    fprintf(FP,"%1.3f %1.3f %1.3f HSB\n",C1,C2,C3);
	  }
	} else if( ColorMode == CMODE_RGB ) {
	  fprintf(FP,"%1.3f %1.3f %1.3f RGB\n",C1,C2,C3);
	} else {
	  Error2("Internal error PsSetColor: ",itos(ColorMode));
	}
	ColorChanged = NO;
}

void PsSetDefaultColorTable( int color_table )

{
	DefColorTable = color_table;
}

void PsSetGenericColor( float color )

{
	MINMAX(color);
	if( ColorMode == CMODE_COLOR && C1 == color ) return;
	C1 = color;
	ColorMode = CMODE_COLOR;
	ColorChanged = YES;
	IsWhite = NO;
}

void PsSetGray( float gray )

{
	MINMAX(gray);
	if( ColorMode == CMODE_GRAY && C1 == gray ) return;
	C1 = gray;
	ColorMode = CMODE_GRAY;
	ColorChanged = YES;
	if( gray >= 1. ) {
	  IsWhite = YES;
	} else {
	  IsWhite = NO;
	}
}

void PsSetHue( float hue )

{
	MINMAX(hue); 
	if( ColorMode == CMODE_HSB && C1 == hue ) return;
	if( ColorMode != CMODE_HSB ) {
	   C2 = 1.; C3 = 1.;
	}
	C1 = hue;
	ColorMode = CMODE_HSB;
	ColorChanged = YES;
	IsWhite = NO;
}

void PsSetHSB( float hue , float sat , float bri )

{
	MINMAX(hue); MINMAX(sat); MINMAX(bri);
	C1 = hue; C2 = sat; C3 = bri;
	ColorMode = CMODE_HSB;
	ColorChanged = YES;
	IsWhite = NO;
}

void PsSetRGB( float red , float green , float blue )

{
	MINMAX(red); MINMAX(green); MINMAX(blue);
	C1 = red; C2 = green; C3 = blue;
	ColorMode = CMODE_RGB;
	ColorChanged = YES;
	IsWhite = NO;
}

void PsPaintWhite( int ipaint )

{
	BPaintWhite = ipaint;
	ColorChanged = YES;
}

void PsInitColorTable( int size )

{
	int i;

	Csize = size;

	CT1 = (float *) realloc((void *)CT1,size*sizeof(float));
	CT2 = (float *) realloc((void *)CT2,size*sizeof(float));
	CT3 = (float *) realloc((void *)CT3,size*sizeof(float));

	for(i=0;i<size;i++) {
	  CT1[i] = 0.;
	  CT2[i] = 0.;
	  CT3[i] = 0.;
	}
}

void PsSetColorTable( int i , int type , float c1 , float c2 , float c3 )

{
	float r,g,b;

	if( Csize <= 0 ) return;
	i = i % Csize;

	if( type ) {	/* RGB */
	  CT1[i] = c1;
	  CT2[i] = c2;
	  CT3[i] = c3;
	} else {	/* HSB */
	  hsv2rgb(c1,c2,c3,&r,&g,&b);
	  c1=r; c2=g; c3=b;
	  CT1[i] = c1;
	  CT2[i] = c2;
	  CT3[i] = c3;
	}

	/*
	printf("%d: %f %f %f\n",i,c1,c2,c3);
	*/
}

void PsSetColorPen( int i )

{
	i = i % Csize;

	C1 = CT1[i]; C2 = CT2[i]; C3 = CT3[i];

	ColorMode = CMODE_RGB;
	ColorChanged = YES;
	IsWhite = NO;
}

void PsSetColorRange( float col )

{
	int i;

	MINMAX(col); 

	i = (int) col * Csize;
	if( i >= Csize ) i = Csize-1;
	if( i < 0 ) i = 0;

	PsSetColorPen(i);
}

/***********************************************************************/
/**************************** Line properties **************************/
/***********************************************************************/

void PsSetDashPattern( float fact, float offset, int n, float *array )

{
        float val;

        PsStroke(FLUSH);
        fprintf(FP,"[");
        while( n-- ) {
          val = *array++;
          val = SxWtoV * val * fact;
          fprintf(FP,"%1.3f",val);
          if( n > 0 ) fprintf(FP," ");
        }
        fprintf(FP,"] %1.3f setdash\n",offset);
}

void PsResetDashPattern( void )

{
        fprintf(FP,"[] 0 setdash\n");
}

void PsSetLineWidth( float width )

{
        if( width <= 0 ) width = LINEWIDTH;
        LineWidth = width;
        PsStroke(FLUSH);
        fprintf(FP,"%1.3f LW\n",width);
}

void PsSetPointSize( float size )

{
        if( size <= 0 ) size = POINTSIZE;
        PointSize = size;
}

/***********************************************************************/
/*********************** Clipping Routines *****************************/
/***********************************************************************/

static void PsAdjustScale( void )

{
    if( WinXmax-WinXmin > 0. )
	SxWtoV = (ViewRight-ViewLeft)/(WinXmax-WinXmin);

    if( WinYmax-WinYmin > 0. )
	SyWtoV = (ViewTop-ViewBottom)/(WinYmax-WinYmin);

    if( SxWtoV != 0. )
	SxVtoW = 1./SxWtoV;

    if( SyWtoV != 0. )
	SyVtoW = 1./SyWtoV;

}

void PsSetViewportNoClip( float left , float bottom , float right , float top )

{
    ViewLeft   = left;
    ViewTop    = top;
    ViewRight  = right;
    ViewBottom = bottom;

    PsAdjustScale();
    PsSetNoClip();
    /* PsSetClipWindow(); */
}

void PsSetViewport( float left , float bottom , float right , float top )

{
    ViewLeft   = left;
    ViewTop    = top;
    ViewRight  = right;
    ViewBottom = bottom;

    PsAdjustScale();
    PsSetClipWindow();
}

void PsGetViewport( float *left , float *bottom , float *right , float *top )

{
    *left = ViewLeft;
    *top = ViewTop;
    *right = ViewRight;
    *bottom = ViewBottom;
}

void PsClearViewport( void )

{
    PsStroke(FLUSH);
    fprintf(FP,"GS 1 G N\n");
    fprintf(FP,"%1.3f %1.3f M\n",ViewLeft,ViewTop);
    fprintf(FP,"%1.3f %1.3f L\n",ViewLeft,ViewBottom);
    fprintf(FP,"%1.3f %1.3f L\n",ViewRight,ViewBottom);
    fprintf(FP,"%1.3f %1.3f L\n",ViewRight,ViewTop);
    fprintf(FP,"CP F GR\n");
}

void PsSetWorld( float xmin , float ymin , float xmax , float ymax )

{
    WinXmin = xmin;
    WinYmin = ymin;
    WinXmax = xmax;
    WinYmax = ymax;

    PsAdjustScale();
/*    PsSetClipWindow(); */
}

void PsRectifyScale( void )

{
	if( SxWtoV > SyWtoV )
		SxWtoV = SyWtoV;
	else
		SyWtoV = SxWtoV;

	if( SxWtoV != 0. ) {
	        SxVtoW = 1./SxWtoV;
       		SyVtoW = 1./SyWtoV;
	}

	PsSetViewport( PsxWtoV(WinXmin) , PsyWtoV(WinYmin) , 
			PsxWtoV(WinXmax) , PsyWtoV(WinYmax) );
}

void PsFactorScale( float xfact , float yfact  )

{
	float rx,ry,rr;

	SxWtoV = xfact * SxWtoV;
	SyWtoV = yfact * SyWtoV;

	/* next block maximizes viewport - may comment if not needed */

	rx = PsxWtoV(WinXmax) / MAX_VIEW_X;
	ry = PsyWtoV(WinYmax) / MAX_VIEW_Y;
	rr = (rx > ry) ? rx : ry;
	SxWtoV = SxWtoV / rr;
	SyWtoV = SyWtoV / rr;

	/* leave from here */

	if( SxWtoV != 0. ) {
	        SxVtoW = 1./SxWtoV;
       		SyVtoW = 1./SyWtoV;
	}

	PsSetViewport( PsxWtoV(WinXmin) , PsyWtoV(WinYmin) , 
			PsxWtoV(WinXmax) , PsyWtoV(WinYmax) );
}

/***********************************************************************/
/*********************** Plotting Routines *****************************/
/***********************************************************************/

void PsLine( float x1 , float y1 , float x2 , float y2 )

{
    float vx1,vy1,vx2,vy2;

    vx1=PsxWtoV(x1);
    vy1=PsyWtoV(y1);
    vx2=PsxWtoV(x2);
    vy2=PsyWtoV(y2);

    if(TEST) printf("PsLine: %f %f %f %f\n",vx1,vy1,vx2,vy2);

    if( !InSide(vx1,vy1) && !InSide(vx2,vy2) ) {
	BOutSide = TRUE;
	XAct=vx2;
	YAct=vy2;
	return;
    }

    if( ISWHITE ) return;
    SETCOLOR;
    if( vx1 != XAct || vy1 != YAct || NPath == 0 || BOutSide ) 
        fprintf(FP,"%1.3f %1.3f M\n",vx1,vy1);
    fprintf(FP,"%1.3f %1.3f L\n",vx2,vy2);

    XAct=vx2;
    YAct=vy2;
    NPlot++;
    BOutSide = FALSE;
    PsStroke(APPEND);
}

void PsPlot( float x , float y )

{
    float vx,vy;

    vx=PsxWtoV(x);
    vy=PsyWtoV(y);

    if(TEST) printf("PsPlot: %f %f %f %f\n",XAct,YAct,vx,vy);

    if( !InSide(vx,vy) && !InSide(XAct,YAct) ) {
	BOutSide = TRUE;
	XAct=vx;
	YAct=vy;
	return;
    }

    if( ISWHITE ) return;
    SETCOLOR;
    if( NPath == 0 || BOutSide )
        fprintf(FP,"%1.3f %1.3f M\n",XAct,YAct);
    fprintf(FP,"%1.3f %1.3f L\n",vx,vy);

    XAct=vx;
    YAct=vy;
    NPlot++; 
    BOutSide = FALSE;
    PsStroke(APPEND);
}

void PsMove( float x , float y )

{
    float vx,vy;

    vx=PsxWtoV(x);
    vy=PsyWtoV(y);

    if(TEST) printf("PsMove: %f %f\n",vx,vy);

    if( !InSide(vx,vy) ) {
	BOutSide = TRUE;
	XAct=vx;
	YAct=vy;
	return;
    }

    fprintf(FP,"%1.3f %1.3f M\n",vx,vy);

    XAct=vx;
    YAct=vy;
    BOutSide = FALSE;
}

void PsPoint( float x , float y )

{
    float dd=PointSize;
    float vx,vy;
    float dx,dy;

    vx=PsxWtoV(x);
    vy=PsyWtoV(y);

    if(TEST) printf("PsPoint: %f %f\n",vx,vy);

    if( !InSide(vx,vy) ) {
	BOutSide = TRUE;
	XAct=vx;
	YAct=vy;
	return;
    }

    if( ISWHITE ) return;
    SETCOLOR;
    dx = PsxVtoW(dd) - PsxVtoW(0.);
    dy = PsyVtoW(dd) - PsyVtoW(0.);
    PsRectFill(x,y,x+dx,y+dy);
    XAct=vx;
    YAct=vy;
    NPlot++;
    BOutSide = FALSE;
}

void PsAreaFill( int ndim , float *x , float *y )

{
    int i;
    int in=0;
    float vx,vy;

    if(ndim<3) return;

    for(i=0;i<ndim;i++) {
	vx = PsxWtoV(x[i]);
	vy = PsyWtoV(y[i]);
        if( InSide(vx,vy) ) in++;
    }
    if( !in ) return;

    if( ISWHITE ) return;
    PsStroke(FLUSH);
    SETCOLOR;
    vx = PsxWtoV(x[0]);
    vy = PsyWtoV(y[0]);
    fprintf(FP,"N %1.3f %1.3f M\n",vx,vy);
    for(i=1;i<ndim;i++) {
	vx = PsxWtoV(x[i]);
	vy = PsyWtoV(y[i]);
	fprintf(FP,"%1.3f %1.3f L\n",vx,vy);
    }
    fprintf(FP,"CP F\n");
    NPlot++;
}

void PsRectFill( float x1 , float y1 , float x2 , float y2 )

{
	float ix1,iy1,ix2,iy2;
	float vw,vh;
	float vx1,vy1,vx2,vy2;

//	printf("post_ggu: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);

	ix1 =  MIN(x1,x2);
	ix2 =  MAX(x1,x2);
	iy1 =  MIN(y1,y2);
	iy2 =  MAX(y1,y2);

//	printf("post_ggu: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);
	vx1 = PsxWtoV(ix1);
	vy1 = PsyWtoV(iy1);
	vx2 = PsxWtoV(ix2);
	vy2 = PsyWtoV(iy2);
	if( vx1 > ViewRight ) return;
	if( vx2 < ViewLeft ) return;
	if( vy1 > ViewTop ) return;
	if( vy2 < ViewBottom ) return;

//	printf("post_ggu 1: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);
	if( ISWHITE ) return;
//	printf("post_ggu 2: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);
	PsStroke(FLUSH);
//	printf("post_ggu 3: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);
	SETCOLOR;
//	printf("post_ggu 4: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);

//	printf("post_ggu 5: %1.3f %1.3f %1.3f %1.3f\n",x1,y1,x2,y2);
	vw = vx2 - vx1;
	vh = vy2 - vy1;
	fprintf(FP,"%1.3f %1.3f %1.3f %1.3f RF\n",vh,vw,vx1,vy1);
	NPlot++;
}

void PsArc( float x0, float y0, float r, float ang1, float ang2 )

{
        float vx,vy,vr;

        vx=PsxWtoV(x0);
        vy=PsyWtoV(y0);
        vr=SxWtoV*r;            /* problem if scale x != y */

        if( ISWHITE ) return;
        PsStroke(FLUSH);
        SETCOLOR;

        fprintf(FP,"N %1.3f %1.3f %1.3f %1.3f %1.3f",vx,vy,vr,ang1,ang2);
        fprintf(FP," arc S\n");
        NPlot++;
}

void PsArcFill( float x0, float y0, float r, float ang1, float ang2 )

{
        float vx,vy,vr;

        vx=PsxWtoV(x0);
        vy=PsyWtoV(y0);
        vr=SxWtoV*r;            /* problem if scale x != y */

        if( ISWHITE ) return;
        PsStroke(FLUSH);
        SETCOLOR;

        fprintf(FP,"N %1.3f %1.3f %1.3f %1.3f %1.3f",vx,vy,vr,ang1,ang2);
        fprintf(FP," arc CP F\n");
        NPlot++;
}

/***********************************************************************/
/*************************** Text Routines *****************************/
/***********************************************************************/

static void PsSetFont( void )

{
        PsStroke(FLUSH);
	fprintf(FP,"/%s FF ",Font);
/*	fprintf(FP,"%f CF ",TFACTOR*FontSize/POINTS_IN_CM); */
	fprintf(FP,"%f CF ",FontSize/POINTS_IN_CM);
	fprintf(FP,"SF\n");
	PsTextSetCenter(HCenter,VCenter);
	FontChanged = NO;
}

void PsTextFont( char *font )		/* sets new font */

{
    if( font && strncmp(Font,font,81) ) {
	strncpy(Font,font,81);
	FontChanged = YES;
    }
}
	
void PsTextRotate( float angle )

{
        FontRotate = angle;
}

void PsTextPointSize( int size )	/* size is in points */

{
    if( size <= 0 ) size = FONTSIZE;
    if( FontSize != size ) {
	FontSize = size;
	FontChanged = YES;
    }
}

void PsTextRealSize( float size )	/* size is in actual units (cm) */

{
    PsTextPointSize( (int) (size*POINTS_IN_CM) );
}

void PsText( float x , float y , char *s )	/* writes string */

{
    float vx,vy;
    int append = FALSE;
    int appendx = FALSE, appendy = FALSE;

    if( x == 999.0 || y == 999.0 ) {
      fprintf(FP,"currentpoint\n");
      fprintf(FP,"/YY exch def\n");
      fprintf(FP,"/XX exch def\n");
      append = TRUE;
      appendx = ( x == 999.0 ? TRUE : FALSE );
      appendy = ( y == 999.0 ? TRUE : FALSE );
    }

    vx=PsxWtoV(x);
    vy=PsyWtoV(y);

    if( ISWHITE ) return;
    PsStroke(FLUSH);
    SETCOLOR; SETTEXT;
    if( append ) {
	if( appendx ) {
          fprintf(FP,"XX ");
	} else {
          fprintf(FP,"%f ",vx);
	}
	if( appendy ) {
          fprintf(FP,"YY ");
	} else {
          fprintf(FP,"%f ",vy);
	}
        fprintf(FP,"M\n");
    } else {
      fprintf(FP,"%f %f M\n",vx,vy);
    }
    if( MUSTROTATE ) fprintf(FP,"%1.3f rotate\n",FontRotate);

    if( HCenter < 0 ) {
      fprintf(FP,"(%s) Lshow\n",s);
      /* fprintf(FP,"(%s) show\n",s); */
    } else if( HCenter > 0 ) {
      fprintf(FP,"(%s) Rshow\n",s);
    } else /* if( HCenter == 0 ) */ {
      fprintf(FP,"(%s) Cshow\n",s);
    }

    if( MUSTROTATE ) fprintf(FP,"%1.3f rotate\n",-FontRotate);
    NPlot++;
}

void PsTextDimensions( char *s , float *width , float *height )

{
	float empiric;				/* maybe 0.75 */

	if( strncmp(Font,"Courier",81) == 0 ) {
	  empiric = 1.0;
	} else {
	  empiric = 0.7;
	}

	*height = SyVtoW * FontSize / (TFACTOR*POINTS_IN_CM);
	*width  = (SxVtoW/SyVtoW) * empiric * (*height) * strlen(s);
}

void PsTextSetCenter( float hc , float vc )

{
    float width, height;

    HCenter = hc;
    VCenter = vc;

    PsTextDimensions( "III" , &width , &height );

/*
    if( vc < 0 ) {
        height = 0.;
    } else if( vc > 0 ) {
        height = -height;
    } else if( vc == 0 ) {
        height = -height/2.;
    }
*/
    height = -0.5*(1+vc)*height;

    /* height=PsyWtoV(height); */
    height = SyWtoV * height;

    fprintf(FP,"/VS %f def\n",height);	/* sets vertical displacement */
}

/***********************************************************************/
/************************** Utility Routines ***************************/
/***********************************************************************/

void PsComment( char *s )

{
    fprintf(FP,"%%PsComment: %s\n",s);
}

void PsRealXY( float vx , float vy , float *x , float *y )

{
	*x = PsxVtoW( vx );
	*y = PsyVtoW( vy );
}

void PsPageXY( float x , float y , float *vx , float *vy )

{
	*vx = PsxWtoV( x );
	*vy = PsyWtoV( y );
}

void PsCmLength( float *xcm, float *ycm )

/* returns length in x/y direction that corresponds to 1 cm */

{
        *xcm = SxVtoW;
        *ycm = SyVtoW;
}

/********************************************************************/

void PsFlush( void )

{
        PsStroke(FLUSH);
}

/********************************************************************/

void PsSync( void ) { }
void PsSyncron( int sync ) { }
int PsActScreen( void ) { return 0; }
void PsSetTest( void ) { TEST = 1; }
void PsClearTest( void ) { TEST = 0; }

void PsGetMinMaxPix( int *xmin , int *ymin , int *xmax , int *ymax ) { }
void PsSetMinMaxPix( int xmin , int ymin , int xmax , int ymax ) { }

