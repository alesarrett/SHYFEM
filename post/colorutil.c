
/************************************************************************\ 
 *									*
 * colorutil.c - color utilities for color space conversion		*
 *									*
 * Copyright (c) 1992-2003 by Georg Umgiesser				*
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
 *			ISMAR-CNR					*
 *			S. Polo 1364					*
 *			30125 Venezia					*
 *			Italy						*
 *									*
 *			Tel.   : ++39-041-5216875			*
 *			Fax    : ++39-041-2602340			*
 *			E-Mail : georg.umgiesser@ismar.cnr.it		*
 *									*
 * Revision History:							*
 * 18-Aug-2003	bug fix in hsv2rgb -> i=i%6 after other statements	*
 * 18-Aug-2003	adapted for use in psgraph				*
 *									*
\************************************************************************/


#include <stdio.h>
#include "general.h"

#define	hmax	1.			/* h [0-1] */
/* #define	hmax	360. */		/* h [0-360] */

#define hdist	(hmax/6.)
#define hconv	(6./hmax)
#define undef	0.

#define abs__(a)	( (a) > 0 ? (a) : (-(a)) )


/*********************************************************************/

static float max3(float a, float b, float c)

{
	if( a > b ) {
	  if( a > c ) {
	    return a;
	  } else {
	    return c;
	  }
	} else {
	  if( c > b ) {
	    return c;
	  } else {
	    return b;
	  }
	}
}

static float min3(float a, float b, float c)

{
	if( a < b ) {
	  if( a < c ) {
	    return a;
	  } else {
	    return c;
	  }
	} else {
	  if( c < b ) {
	    return c;
	  } else {
	    return b;
	  }
	}
}

/*********************************************************************/

void rgb2cmy(float r ,float g ,float b ,float *c ,float *m ,float *y)

/*
	rgb -> cmy

	real r,g,b	![0-1]
	real c,m,y	![0-1]
*/

{
	*c = 1. - r;
	*m = 1. - g;
	*y = 1. - b;
}


void cmy2rgb(float c ,float m ,float y ,float *r ,float *g ,float *b)

/*
	cmy -> rgb

	real c,m,y	![0-1]
	real r,g,b	![0-1]
*/

{
	*r = 1. - c;
	*g = 1. - m;
	*b = 1. - y;
}


void rgb2hsv(float r ,float g ,float b ,float *h ,float *s ,float *v)

/*
	rgb -> hsv		note: h is not [0-360] but [0-1]

	real r,g,b	![0-1]
	real h,s,v	![0-1]
*/

{

	float maxv,minv;
	float diff;
	float rdist,gdist,bdist;

	maxv = max3(r,g,b);
	minv = min3(r,g,b);
	diff = maxv - minv;

	*v = maxv;
	*s = 0.;
	if( maxv > 0. ) *s = diff/maxv;

	if( *s == 0. ) {
	  *h = undef;
	} else {
	  rdist = (maxv-r)/diff;
	  gdist = (maxv-g)/diff;
	  bdist = (maxv-b)/diff;
	  if( r == maxv ) {
	    *h = bdist - gdist;
	  } else if( g == maxv ) {
	    *h = 2. + rdist - bdist;
	  } else if( b == maxv ) {
	    *h = 4. + gdist - rdist;
	  } else {
	    Error("error stop rgb2hsv: internal error (1)");
	  }
	  *h = *h * hdist;
	  if( *h < 0. ) *h = *h + hmax;
	}

}

void hsv2rgb(float h, float s, float v, float *r, float *g, float *b)

/*
	hsv -> rgb		note: h is not [0-360] but [0-1]

	real h,s,v	![0-1]
	real r,g,b	![0-1]
*/

{
	int i;
	float p,q;

	i = hconv * h;
	p = v * (h-i*hdist) / hdist;	/* rising */
	q = v - p;			/* falling */
	i = i % 6;			/* bug adjusted 18.08.2003 */

	if( i == 0 ) {
	    *r=v;
	    *g=p;
	    *b=0;
	} else if( i == 1 ) {
	    *r=q;
	    *g=v;
	    *b=0;
	} else if( i == 2 ) {
	    *r=0;
	    *g=v;
	    *b=p;
	} else if( i == 3 ) {
	    *r=0;
	    *g=q;
	    *b=v;
	} else if( i == 4 ) {
	    *r=p;
	    *g=0;
	    *b=v;
	} else if( i == 5 ) {
	    *r=v;
	    *g=0;
	    *b=q;
	} else {
	    Error("error stop hsv2rgb: internal error (1)");
	}

/*
	printf("hsv2rgb: %f %f %f %d %f %f\n",h,s,v,i,p,q);
	printf("%f %f %f    ",*r,*g,*b);
*/
	*r = v + (*r-v) * s;
	*g = v + (*g-v) * s;
	*b = v + (*b-v) * s;
/*
	printf("%f %f %f    \n",*r,*g,*b);
*/

}

/*********************************************************************/
/*********************************************************************/
/*********************************************************************/

#define	m	714025
#define	ia	1366
#define	ic	150889
#define	rm	1.4005112e-6

#define	nrdim	97
#define	nrdim1	(nrdim+1)

static float randomtb(int *idump)

{
      static int ir[nrdim1];
      static int iy;
      static int iff=0;

      int j;
      int idum = *idump;
      float randomtb;

      if(idum==0 || iff==0) {
        iff=1;
        idum=(ic-idum)%m;
        for(j=1;j<=nrdim;j++) {
          idum=(ia*idum+ic)%m;
          ir[j]=idum;
	}
        idum=(ia*idum+ic)%m;
        iy=idum;
      }

      j=1+(97*iy)/m;
      if(j>97 || j<1) {
	Error("error stop ran2: internal error");
      }

      iy=ir[j];
      randomtb=iy*rm;
      idum=(ia*idum+ic)%m;
      ir[j]=idum;

      *idump = idum;
      return randomtb;
}

static void equaltb(float a, float b, float eps, int *berror)

{
	/*
		tests for nearly equality
	*/

	float absab = abs__(a-b);

	if( absab > eps ) {
	  printf("*** %f %f %f %f\n",a,b,absab,eps);
	  *berror = 1;
	}
}

void test_color_conversion()

{

	/*
		tests conversion routine
	*/

	int i;
	int itot,iseed;
	int berror;
	float r,g,b;
	float rn,gn,bn;
	float h,s,v;
	float hn,sn,vn;
	float eps;

	eps = 0.0001;
	itot = 100;
	iseed = 124357;
	berror = 0;

	for(i=1;i<=itot;i++) {
	      
	  h = randomtb(&iseed);
	  s = randomtb(&iseed);
	  v = randomtb(&iseed);

	  h = h * hmax;
	  hsv2rgb(h,s,v,&r,&g,&b);
	  rgb2hsv(r,g,b,&hn,&sn,&vn);

	  printf("%7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f\n"
			,h,hn,s,sn,v,vn,r,g,b);

	  equaltb(h,hn,eps,&berror);
	  equaltb(s,sn,eps,&berror);
	  equaltb(v,vn,eps,&berror);
	  if( berror ) Error("error in computation h2r...");

	}
	      
	printf("-------------------------------------\n");

	for(i=1;i<=itot;i++) {

	  r = randomtb(&iseed);
	  g = randomtb(&iseed);
	  b = randomtb(&iseed);

	  rgb2hsv(r,g,b,&h,&s,&v);
	  hsv2rgb(h,s,v,&rn,&gn,&bn);

	  printf("%7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f\n"
			,r,rn,g,gn,b,bn,h,s,v);

	  equaltb(r,rn,eps,&berror);
	  equaltb(g,gn,eps,&berror);
	  equaltb(b,bn,eps,&berror);
	  if( berror ) Error("error in computation r2h...");

	}

	printf("no error in conversion ...\n");
}


/*
int main( void )
{
	test_color_conversion();
	return 0;
}
*/

