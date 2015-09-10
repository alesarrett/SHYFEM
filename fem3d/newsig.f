c
c routines for sigma levels
c
c revision log :
c
c 16.12.2010    ggu     program partially finished
c 19.09.2011    ggu     new routine set_bsigma()
c 04.11.2011    ggu     new routines for hybrid levels
c 10.11.2011    ggu     adjust depth for hybrid levels
c 11.11.2011    ggu     error check in set_hkv_and_hev()
c 11.11.2011    ggu     in check_hsigma_crossing set zeta levels to const depth
c 18.11.2011    ggu     restructured hybrid - adjustment to bashsigma
c 12.12.2011    ggu     eliminated (stupid) compiler bug (getpar)
c 27.01.2012    deb&ggu adapted for hybrid levels
c 23.02.2012    ccf	bug fix in set_hybrid_depth (no call to get_sigma)
c 05.09.2013    ggu	no set_sigma_hkv_and_hev()
c
c notes :
c
c important files where sigma levels are explicitly needed:
c
c	newini.f		set up of structure
c	subele.f		set new layer thickness
c
c	newbcl.f		for computation of rho
c	newexpl.f		for baroclinic term
c
c	lagrange_flux.f		limit zeta layers to surface layer
c
c********************************************************************
c********************************************************************
c********************************************************************

	subroutine get_bsigma(bsigma)

c returns bsigma which is true if sigma layers are used

	implicit none

	logical bsigma

	real getpar

	bsigma = nint(getpar('nsigma')) .gt. 0

	end

c********************************************************************

	subroutine get_sigma(nsigma,hsigma)

	implicit none

	integer nsigma
	real hsigma

	real getpar

	nsigma = nint(getpar('nsigma'))
	hsigma = getpar('hsigma')

	end

c********************************************************************

	subroutine set_sigma(nsigma,hsigma)

	implicit none

	integer nsigma
	real hsigma

	real getpar

	call putpar('nsigma',float(nsigma))
	call putpar('hsigma',hsigma)

	end 

c********************************************************************
c********************************************************************
c********************************************************************

	subroutine make_sigma_levels(nsigma,hlv)

	implicit none

	integer nsigma
	real hlv(nsigma)

	integer l
	real hl

	if( nsigma .le. 0 ) stop 'error stop make_sigma_levels: nsigma'

        hl = -1. / nsigma
        do l=1,nsigma
          hlv(l) = l * hl
        end do

	end

c********************************************************************

	subroutine make_zeta_levels(lmin,hmin,dzreg,nlv,hlv)

	implicit none

	integer lmin
	real hmin,dzreg
	integer nlv
	real hlv(nlv)

	integer l
	real hbot

	if( dzreg .le. 0. ) stop 'error stop make_zeta_levels: dzreg'

        hbot = hmin
	if( lmin .gt. 0 ) hlv(lmin) = hbot

        do l=lmin+1,nlv
          hbot = hbot + dzreg
          hlv(l) = hbot
        end do

	end

c********************************************************************

	subroutine set_hybrid_depth(lmax,zeta,htot
     +					,hlv,nsigma,hsigma,hlfem)

c sets depth structure and passes it back in hlfem

	implicit none

	integer lmax		!total number of layers
	real zeta		!water level
	real htot		!total depth (without water level)
	real hlv(1)		!depth structure (zeta, sigma or hybrid)
	integer nsigma		!number of sigma levels
	real hsigma		!depth of hybrid closure
	real hlfem(1)		!converted depth values (return)

	logical bsigma
	integer l,i
	real hsig

	bsigma = nsigma .gt. 0

	if( nsigma .gt. 0 ) then
          hsig = min(htot,hsigma) + zeta

	  do l=1,nsigma-1
            hlfem(l) = -zeta - hsig * hlv(l)
	  end do

	  hlfem(nsigma) = -zeta + hsig
	end if

        do l=nsigma+1,lmax
          hlfem(l) = hlv(l)
        end do

	if( nsigma .lt. lmax ) hlfem(lmax) = htot	!zeta or hybrid

c check ... may be deleted

	do l=2,lmax
	  if( hlfem(l) - hlfem(l-1) .le. 0. ) then
	    write(6,*) (hlfem(i),i=1,lmax)
	    stop 'error stop set_hybrid_depth: hlfem'
	  end if
	end do

	end

c********************************************************************






