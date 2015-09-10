c
c $Id: color.h,v 1.7 2009-04-07 09:33:35 georg Exp $
c
c include file for colors
c
c-----------------------------------------------------------------------

	integer isodim		!maximum number of isolines
	parameter(isodim=256)

        integer isopar		!dimension of arrays ( = isodim )
        integer isoanz		!number of isolines used
        integer nisord		!number of isolines read
        integer ncolrd		!number of colors read
	integer icauto		!automatic computation of iso-values
	integer nriso		!number of single isolines to plot
	integer iusear		!use array looking up values for colors

        real fnull		!flag for value not to plot

        real fiso(isodim)	!array with iso-values
        real ciso(isodim+1)	!array with colors
        real riso(isodim)	!array with iso-values of single isolines

        common /isolin/ isopar,isoanz,nisord,ncolrd,icauto,nriso,iusear
        common /fsolin/ fnull
        common /isofol/ fiso
        common /isocol/ ciso
        common /isorol/ riso

	save /isolin/,/fsolin/,/isofol/,/isocol/,/isorol/

c-----------------------------------------------------------------------

