c
c $Id: newini.f,v 1.45 2009-11-18 16:50:37 georg Exp $
c
c routines for initialization
c
c contents :
c
c subroutine inicfil(name,var,nvar)
c				initializes nodal value variable from file
c subroutine inic2fil(name,var,nvar)
c				initializes nodal value variable from file (2D)
c
c revision log :
c
c 20.08.1998	ggu	initialization routines copied from subn11/new11
c 20.08.1998	ggu	new routine inicfil to init nodal values from file
c 06.11.1998	ggu	computation of hkv/hev taken out of sp211 -> cstset
c 22.10.1999	ggu	igrv, ngrv eliminated (subst by ilinkv, lenkv)
c 07.03.2000    ggu     arrays for vertical turbulent diffusion coefficient
c 07.03.2000    ggu     useless parts commented
c 20.06.2000    ggu     useless parts deleted
c 21.06.2000    ggu     dzreg introduced
c 08.08.2000    ggu     hlvmin is now percentage of last layer thickness
c 25.03.2003    ggu     voldist adjusted for 3D, new routine surinl
c 07.08.2003    ggu     deleted sp212
c 09.08.2003    ggu     cleaned up (sp211 is completely different)
c 14.08.2003    ggu     error in check_ilevels (integer instead of real)
c 14.08.2003    ggu     error in check_ilevels (must test .lt.)
c 14.08.2003    ggu     new routine set_depth -> transferred from cstcheck
c 14.08.2003    ggu     renamed sp211 into init_vertical and init_others
c 14.08.2003    ggu     new routines init_z, init_const_z, init_file_z
c 14.08.2003    ggu     new routines init_uvt
c 02.09.2003    ggu     routine inicfil restructured for lmax=0
c 03.09.2003    ggu     some more checks for check_ilevels
c 04.03.2004    ggu     change in inicfil() for more variables
c 05.03.2004    ggu     LMAX - changed bound from 0 to 1
c 02.09.2004    ggu     rdrst transfered to subrst.f
c 15.03.2005    ggu     set_austausch() and check_austausch() eliminated
c 05.04.2005    ggu     minimum levels (for baroclinic terms) -> set_min_levels
c 28.11.2005    ggu     in set_depth use makehkv to compute hkv
c 16.02.2006    ggu     describe file format in inicfil()
c 15.11.2006    ggu     new parameters to construct streched vert. coordinates
c 27.08.2007    ccf     variable coriolis from spherical coordinates (isphe)
c 17.03.2008    ggu     better error message if missing levels
c 07.04.2008    ggu     deleted surinl, volinl, voldist
c 12.11.2008    ggu     set_last_layer() rewritten, new adjust_k_depth()
c 06.12.2008    ggu&ccf small bug fix in set_last_layer()
c 21.01.2009    ggu	cleaned up, new read_scalar()
c 27.01.2009    ggu	mzreg and hlvmax deleted (not used)
c 24.03.2009    ggu	bug fix: in set_last_layer() do not adjust for 2D
c 21.04.2009    ggu	new routine inic2fil()
c 28.09.2010    ggu	bug fix in init_coriolis() for isphe=1
c 08.10.2010    ggu	bug fix in init_coriolis() -> ym not set for isphe=1
c 16.12.2010    ggu	big restructering for sigma levels (look for bsigma)
c 21.02.2011    ggu	error check for dzreg, nsigma and levels
c 23.03.2011    ggu	new routine adjust_spherical(), error check isphe
c 24.08.2011    ggu	eliminated hbot for sigma due to run time error
c 25.10.2011    ggu	hlhv eliminated
c 04.11.2011    ggu	adapted for hybrid coordinates
c 11.11.2011    ggu	bug fix in adjust_levels: for zeta levels set nlv
c 23.08.2013    ggu	renamed adjust_k_depth() to make_hkv() -> to subdep
c 23.08.2013    ggu	depth routines to subdep.f
c 05.09.2013    ggu	in adjust_levels() allow for nlv==1
c 31.10.2014    ccf	initi_z0 for zos and zob
c 25.05.2015    ggu	file cleaned and prepared for module
c
c notes :
c
c for information on hybrid levels see adjust_levels()
c
c**************************************************************

	subroutine init_vertical

c set up time independent vertical vectors

	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'

	integer nlv_est,nlv_read,nlv_final
	real, allocatable :: hlv_aux(:)

	write(6,*) 'setting up vertical structure'

c------------------------------------------------------------------
c sanity check
c------------------------------------------------------------------

	nlv_est = nlv
	call estimate_nlv(nlv_est)
	write(6,*) 'nlv,nlv_est,nlvdi: ',nlv,nlv_est,nlvdi

	call check_nlv

	if( nlv > 0 ) then
	  allocate(hlv_aux(nlv))
	  hlv_aux(1:nlv) = hlv(1:nlv)
	  call levels_hlv_init(0)
	end if
	call levels_init(nkn,nel,nlv_est)
	if( nlv > 0 ) then
	  hlv(1:nlv) = hlv_aux(1:nlv)
	  deallocate(hlv_aux)
	end if

	!write(6,*) nlv,nlvdi,nlv_est
	!call levels_reinit(nlv_est)
	!write(6,*) nlv,nlvdi,nlv_est

c------------------------------------------------------------------
c levels read in from $levels section
c------------------------------------------------------------------

	call adjust_levels	!sets hlv, hldv, nlv

c------------------------------------------------------------------
c set up layer vectors
c------------------------------------------------------------------

	write(6,*) '... ',nlv
	call set_ilhv		!sets nlv, ilhv (elemental)
	write(6,*) '... ',nlv
	call set_last_layer	!adjusts nlv, ilhv, hm3v
	write(6,*) '... ',nlv
	call set_ilhkv		!sets ilhkv (nodal)
	call set_min_levels	!sets ilmkv and ilmv

c------------------------------------------------------------------
c check data structure
c------------------------------------------------------------------

	nlv_final = nlv
	!nlv_final = nlvdim		!to be removed later
	call levels_reinit(nlv_final)

	call check_vertical

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

	end

c**************************************************************

	subroutine init_others

c set up various arrays (coriolis, eddy)

	implicit none

c------------------------------------------------------------------
c set others
c------------------------------------------------------------------

	call init_coriolis
	call set_eddy

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

	end

c*****************************************************************

	subroutine set_eddy

c sets vertical eddy coefficient

	use mod_diff_visc_fric
	use levels, only : nlvdi,nlv
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'



	integer k,l
	real vistur,diftur

	real getpar

c------------------------------------------------------------------
c get parameters
c------------------------------------------------------------------

	vistur=getpar('vistur')
	diftur=getpar('diftur')

c------------------------------------------------------------------
c set eddy coefficient
c------------------------------------------------------------------

	do k=1,nkn
	  do l=0,nlv
	    visv(l,k)=vistur
	    difv(l,k)=diftur
	  end do
	end do

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

	end

c*****************************************************************

	subroutine check_eddy

c checks vertical eddy coefficient

	use mod_diff_visc_fric
	use levels, only : nlvdi,nlv
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'



	integer k,l
	real v,d

c------------------------------------------------------------------
c check eddy coefficient
c------------------------------------------------------------------

	do k=1,nkn
	  do l=0,nlv
	    v = visv(l,k)
	    d = difv(l,k)
	    if( v .lt. 0. .or. v .gt. 1.e+5 ) goto 99
	    if( d .lt. 0. .or. d .gt. 1.e+5 ) goto 99
	  end do
	end do

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

	return
   99	continue
	write(6,*) k,l,v,d
	stop 'error stop check_eddy: error in values'
	end

c*****************************************************************

	subroutine check_vertical

c checks arrays containing vertical structure

	implicit none

	call check_nlv
	call check_hlv
	call check_levels
	call check_ilevels

	end

c*****************************************************************

	subroutine check_hlv

	use levels

	implicit none

	include 'param.h'

	integer l

	write(6,*) 'check_hlv: ',nlv,nlvdi
	write(6,*) (hlv(l),l=1,nlv)

	end

c*****************************************************************

	subroutine check_nlv

c checks nlv and associated parameters

	use levels, only : nlvdi,nlv

	implicit none

	include 'param.h'


	write(6,*) 'check_nlv : '
	write(6,*) '    nlvdi : ',nlvdi
	write(6,*) '      nlv : ',nlv

	if(nlv.gt.nlvdi) stop 'error stop check_nlv: level dimension'

	end

c*****************************************************************

	subroutine estimate_nlv(nlv_est)

c estimates maximum value for nlv

	use basin

	implicit none

	integer nlv_est		!nlv_read on entry, estimate on return

	include 'param.h'

	integer ie,ii
	integer nsigma,nreg
	real hsigma,hmax,dzreg

	real getpar

	hmax = 0.
	do ie=1,nel
	  do ii=1,3
	    hmax = max(hmax,hm3v(ii,ie))
	  end do
	end do

	write(6,*) 'maximum depth: ',hmax

	dzreg = getpar('dzreg')
	call get_sigma(nsigma,hsigma)

	nreg = 0
	if( dzreg > 0 ) nreg = hmax/dzreg

	!nlv_est = nlv_est + nsigma + nreg + 1
	nlv_est = nlv_est + nsigma + nreg
	nlv_est = max(nlv_est,1)

	end

c*****************************************************************

	subroutine adjust_levels

c adjusts levels read in from $levels section
c
c creates hlv if not set
c from hlv creates hldv
c needs hm3v to compute hmax
c
c strategy:
c
c set hsigma < hmax to ask for hybrid levels
c set nsigma > 1 to ask for sigma coordinates
c set dzreg > 0. to ask for regular zeta levels
c
c only nsigma				only sigma levels
c only dzreg				only regular zeta levels
c nsigma, dzreg and hsigma		hybrid levels
c
c only sigma levels			only sigma levels
c only zeta levels			only zeta levels
c sigma levels, dzreg and hsigma	hybrid levels
c zeta levels, nsigma and hsigma	hybrid levels
c sigma and zeta levels and hsigma	hybrid levels

	use levels
	use basin

	implicit none

c common
	include 'param.h'

c local
	logical bsigma,bhybrid,bzeta
	integer l,ie,ii,nsigma,second
	real dzreg,hl,fact,hsigma
	real hmax,hbot,htop

	real getpar

	write(6,*) 'adjust layer structure'

c--------------------------------------------------------------
c get maximum depth
c--------------------------------------------------------------

	hmax = 0.
	do ie=1,nel
	  do ii=1,3
	    hmax = max(hmax,hm3v(ii,ie))
	  end do
	end do

	write(6,*) 'maximum depth: ',hmax

c--------------------------------------------------------------
c create hlv values
c--------------------------------------------------------------

	second = 2
	dzreg = getpar('dzreg')
	call get_sigma(nsigma,hsigma)
	write(6,*) 'nlv,nsigma,hsigma: ',nlv,nsigma,hsigma

	bsigma = nsigma .gt. 0
	bhybrid = hsigma .lt. hmax
	bzeta = dzreg .gt. 0.

	if( nsigma .eq. 1 ) goto 92

	if( nlv .le. 0 ) then		! hlv not set -> must set

	  if( bsigma ) then		!sigma layers
	    call make_sigma_levels(nsigma,hlv)
	    nlv = nsigma
	  end if

	  if( bhybrid .or. bzeta ) then	!zeta levels
	    if( bhybrid .and. .not. bzeta ) goto 99
	    if( bhybrid .and. .not. bsigma ) goto 90
	    nlv = nlvdi
	    if( bhybrid ) then
	      call make_zeta_levels(nsigma,hsigma,dzreg,nlv,hlv)
	    else if( .not. bsigma ) then	!no sigma layers given
	      call make_zeta_levels(0,0.,dzreg,nlv,hlv)
	    else
	      goto 89
	    end if
	  else if( .not. bsigma ) then		!just one layer
	    nlv = 1
	    hlv(1) = hsigma
	  end if

	else				!level section present

	  if( nlv .eq. 1 ) then		!just one level (barotropic)
	    if( bsigma .or. bhybrid ) goto 98
	  else if( hlv(second) .gt. hlv(1) ) then	!zeta layers given
	    if( bzeta ) goto 97
	    if( bsigma ) then		!put sigma layers on top
	      if( .not. bhybrid ) goto 88
	      if( hlv(1) .ne. hsigma ) goto 96
	      if( nsigma + nlv - 1 .gt. nlvdi ) goto 95
	      do l=1,nlv
	        hlv(nsigma+l-1) = hlv(l)
	      end do
	      call make_sigma_levels(nsigma,hlv)
	      hlv(nsigma) = hsigma
	      nlv = nlv + nsigma - 1
	    end if
	  else if( hlv(nlv) .eq. -1. ) then	!only sigma layers given
	    if( bsigma ) goto 91
	    nsigma = nlv
	    if( bhybrid ) then		!put zeta levels below
	      if( .not. bzeta ) goto 94
	      nlv = nlvdi
	      call make_zeta_levels(nsigma,hsigma,dzreg,nlv,hlv)
	    end if
	  else				!both sigma and zeta levels given
	    if( bsigma ) goto 91
	    if( bzeta ) goto 97
	    if( .not. bhybrid ) goto 88
	    do l=2,nlv
	      if( hlv(l) .gt. hlv(l-1) ) goto 1
	    end do
	    goto 93
    1	    continue
	    if( hlv(l-1) .eq. -1. ) then
	      nsigma = l-1
	      hlv(l-1) = hsigma
	    else if( hlv(l) .eq. hsigma ) then
	      nsigma = l
	    else
	      goto 93
	    end if
	    if( hlv(nsigma) .eq. hlv(nsigma+1) ) then	!double entry
	      do l=nsigma+1,nlv
		hlv(l-1) = hlv(l)
	      end do
	      nlv = nlv - 1
	    else if( hlv(nsigma) .ge. hlv(nsigma+1) ) then
	      goto 93
	    end if
	  end if

	end if

	call set_sigma(nsigma,hsigma)		!uses putpar
	call set_sigma_info(nlv,nsigma,hsigma)	!sets internal data structure

c--------------------------------------------------------------
c create hldv values
c--------------------------------------------------------------

	hldv(1)=hlv(1)
	do l=2,nlv
	  htop = hlv(l-1)
	  hbot = hlv(l)
	  if( l .eq. nsigma ) hbot = -1.
	  hldv(l) = hbot - htop
	end do

	write(6,*) 'adjust_levels: '
	write(6,*) 'nlv,nsigma,hsigma: ',nlv,nsigma,hsigma
	write(6,*) 'hlv:  ',(hlv(l),l=1,nlv)
	write(6,*) 'hldv: ',(hldv(l),l=1,nlv)

c--------------------------------------------------------------
c check hlv and hldv values
c--------------------------------------------------------------

	call check_levels

	write(6,*) 'finished adjusting layer structure ',nlv

c--------------------------------------------------------------
c end of routine
c--------------------------------------------------------------

	return
   88	continue
	write(6,*) 'hsigma: ',hsigma
	write(6,*) 'for hybrid levels hsigma must be set'
	stop 'error stop adjust_levels: hsigma'
   89	continue
	write(6,*) 'nsigma,dzreg: ',nsigma,dzreg
	write(6,*) 'with pure sigma layers cannot give dzreg'
	stop 'error stop adjust_levels: bsigma and dzreg'
   90	continue
	write(6,*) 'nsigma,hsigma: ',nsigma,hsigma
	write(6,*) 'with hsigma set nsigma must be > 0'
	stop 'error stop adjust_levels: nsigma and hsigma'
   91	continue
	write(6,*) 'nlv,nsigma: ',nlv,nsigma
	write(6,*) 'You cannot give both sigma levels and nsigma'
	stop 'error stop adjust_levels: nsigma'
   92	continue
	write(6,*) 'nsigma must be > 1'
	stop 'error stop adjust_levels: nsigma = 1'
   93	continue
	write(6,*) 'error in level structure'
	write(6,*) (hlv(l),l=1,nlv)
	stop 'error stop adjust_levels: hlv'
   94	continue
	write(6,*) 'for hybrid levels dzreg must be > 0'
	stop 'error stop adjust_levels: dzreg'
   95	continue
	write(6,*) 'nlv,nsigma,nlvdi: ',nlv,nsigma,nlvdi
	write(6,*) 'not enough space to add zeta levels'
	stop 'error stop adjust_levels: nlvdi'
   96	continue
	write(6,*) 'hlv(1),hsigma: ',hlv(1),hsigma
	write(6,*) 'for hybrid levels first zeta level must be hsigma'
	stop 'error stop adjust_levels: hsigma'
   97	continue
	write(6,*) 'nlv,dzreg: ',nlv,dzreg
	write(6,*) 'You cannot give both zeta levels and dzreg'
	stop 'error stop adjust_levels: dzreg'
   98	continue
	write(6,*) 'only one level given in level section'
	write(6,*) hlv(1)
	write(6,*) 'cannot have sigma levels...'
	stop 'error stop adjust_levels: nlv = 1'
   99	continue
	write(6,*) 'for hybrid levels dzreg must be > 0'
	stop 'error stop adjust_levels: dzreg = 0'
	end

c*****************************************************************

	subroutine check_levels

c checks arrays hlv and hldv

	use levels

	implicit none

c common
	include 'param.h'

c local
	logical bstop,bsigma
	integer l,nsigma,levmin
	real h,hd,fact,hsigma
	real hbot,htop

	call get_sigma(nsigma,hsigma)
	bsigma = nsigma .gt. 0

	bstop = .false.

c--------------------------------------------------------------
c check hlv values
c--------------------------------------------------------------

	if( nsigma .gt. 0 ) then
	  h = hlv(nsigma)
	  if( h .ne. -1. .and. h .ne. hsigma ) then
	    write(6,*) h,hsigma
	    stop 'error stop check_levels: hsigma'
	  end if
	end if

	hbot = -hlv(1)
	do l=2,nsigma
	  htop = hbot
	  hbot = -hlv(l)
	  if( l .eq. nsigma ) hbot = 1.
	  if( hbot .le. htop ) then
	    write(6,*) 'Error in level values for level : ',l
	    write(6,*) '   hlv(l-1),hlv(l) :',hlv(l-1),hlv(l)
	    bstop = .true.
	  end if
	end do

	levmin = nsigma + 1
	if( levmin .eq. 1 ) levmin = 2
	do l=levmin,nlv
	  if( hlv(l) .le. hlv(l-1) ) then
	    write(6,*) 'Error in level values for level : ',l
	    write(6,*) '   hlv(l-1),hlv(l) :',hlv(l-1),hlv(l)
	    bstop = .true.
	  end if
	end do

	if( bstop ) stop 'error stop check_levels: level error'

c--------------------------------------------------------------
c check hldv values
c--------------------------------------------------------------

	hbot = hlv(1)
	do l=2,nlv
	  htop = hbot
	  hbot = hlv(l)
	  if( l .eq. nsigma ) hbot = -1.
	  hd=hbot-htop
	  if( hd .ne. hldv(l) ) then
	    write(6,*) 'Error in dlevel values for level : ',l
	    write(6,*) '   hd,hldv(l) :',hd,hldv(l)
	    bstop = .true.
	  end if
	  hbot = hlv(l)
	end do
	if( bstop ) stop 'error stop check_levels: dlevel error'

c--------------------------------------------------------------
c end of routine
c--------------------------------------------------------------

	end

c*****************************************************************

	subroutine set_ilhv

c sets nlv and ilhv - only needs hm3v and hlv, hev is temporary array

	use levels
	use basin

	implicit none

	include 'param.h'

c local
	logical bsigma
	integer ie,ii,l,lmax,nsigma
	real hsigma

	real h,hmax,hm
	real hev(nel)		!local
	!double precision h,hmax,hm
	!double precision hev(nel)		!local

	lmax=0
	hmax = 0.

	call get_sigma(nsigma,hsigma)
	bsigma = nsigma .gt. 0

	do ie=1,nel
	  hm = 0.
	  do ii=1,3
	    hm = hm + hm3v(ii,ie)
	  end do
	  hm = hm / 3.
	  hev(ie) = hm
	  hmax = max(hmax,hm)
	end do

	do ie=1,nel

	  h=hev(ie)

	  if( bsigma .and. h .le. hsigma ) then
	    l = nsigma
	  else
	    do l=nsigma+1,nlv
	      if(hlv(l).ge.h) exit
	    end do
	    if( l .gt. nlv ) goto 99
	  end if

	  ilhv(ie)=l
	  lmax = max(lmax,l)

	end do

	nlv = lmax

	write(6,*) 'finished setting ilhv and nlv'
	write(6,*) 'nsigma,hsigma: ',nsigma,hsigma
	write(6,*) 'lmax,hmax: ',lmax,hmax
	write(6,*) 'nlv,hlv: ',nlv,(hlv(l),l=1,nlv)

	return
   99	continue
	write(6,*) ie,l,nlv,h,hlv(nlv)
	write(6,*) 'maximum basin depth: ',hmax
	write(6,*) 'maximum layer depth: ',hlv(nlv)
	write(6,*) 'nlv,hlv: ',nlv,(hlv(l),l=1,nlv)
	stop 'error stop set_ilhv: not enough layers'
	end

c*****************************************************************

	subroutine set_ilhkv

c set ilhkv array - only needs ilhv

	use levels
	use basin

	implicit none

	include 'param.h'

	integer ie,ii,k,l

	do k=1,nkn
	  ilhkv(k)=0
	end do

	do ie=1,nel
	  l=ilhv(ie)
	  do ii=1,3
	    k=nen3v(ii,ie)
	    if(l.gt.ilhkv(k)) ilhkv(k)=l
	  end do
	end do

	!do k=1,nkn
	!  if( ilhkv(k) .eq. 2 ) then
	!    write(6,*) '2 layer node: ',k,ilhkv(k)
	!  end if
	!end do

	end

c*****************************************************************

	subroutine set_min_levels

c set minimum number of levels for node and element

	use levels
	use basin

	implicit none

	include 'param.h'

	integer ie,ii,k,l
	integer lmin,lmax

	do k=1,nkn
	  ilmkv(k) = 99999
	end do

	do ie=1,nel
	  l=ilhv(ie)
	  do ii=1,3
	    k=nen3v(ii,ie)
	    if(l.lt.ilmkv(k)) ilmkv(k)=l
	  end do
	end do

	do k=1,nkn
	  lmin = ilmkv(k)
	  lmax = ilhkv(k)
	  if( lmin .gt. lmax .or. lmin .le. 0 ) then
	    stop 'error stop set_min_levels: lmin'
	  end if
	  !write(6,*) 'set_min_levels (nodes): ',k,lmin,lmax
	end do

	do ie=1,nel
	  lmin = 99999
	  lmax = ilhv(ie)
	  do ii=1,3
	    k=nen3v(ii,ie)
	    if(lmin.gt.ilmkv(k)) lmin = ilmkv(k)
	  end do
	  ilmv(ie) = lmin
	  !write(6,*) 'set_min_levels (elems): ',ie,lmin,lmax
	end do

	end

c*****************************************************************

	subroutine check_ilevels

c checks arrays ilhv and ilhkv

	use levels
	use basin

	implicit none


	include 'param.h'

	logical bsigma,bspure
	integer nsigma
	integer ie,ii,k,lmax,lk
	real hmax,hsigma

	call get_sigma(nsigma,hsigma)
	bsigma = nsigma .gt. 0

	hmax = 0.
	do ie=1,nel
	  lmax = ilhv(ie)
	  do ii=1,3
	    hmax = max(hmax,hm3v(ii,ie))
	  end do
	  if( lmax .le. 0 ) goto 99
	end do

	bspure = bsigma .and. hmax .le. hsigma	!pure sigma coordinates

	do ie=1,nel
	  lmax=ilhv(ie)
	  do ii=1,3
	    k=nen3v(ii,ie)
	    lk = ilhkv(k)
	    if( lk .le. 0 ) goto 98
	    if( lk .lt. lmax ) goto 98
	  end do
	  if( bspure .and. lmax .ne. nsigma ) goto 96
	  if( bsigma .and. lmax .lt. nsigma ) goto 96
	end do

	do k=1,nkn
	  lmax=ilhkv(k)
	  if( lmax .le. 0 ) goto 97
	  if( bspure .and. lmax .ne. nsigma ) goto 96
	  if( bsigma .and. lmax .lt. nsigma ) goto 96
	end do

	return
   96	continue
	write(6,*) ie,k,lmax,nsigma
	stop 'error stop check_ilevels: error in vertical structure (4)'
   97	continue
	write(6,*) k,lmax
	stop 'error stop check_ilevels: error in vertical structure (3)'
   98	continue
	write(6,*) ie,lmax,k,lk
	stop 'error stop check_ilevels: error in vertical structure (2)'
   99	continue
	write(6,*) ie,lmax
	stop 'error stop check_ilevels: error in vertical structure (1)'
	end

c*****************************************************************

	subroutine set_last_layer

c sets last layer thickness
c
c adjusts nlv, hm3v, ilhv

	use levels
	use basin

	implicit none

	include 'param.h'

	logical bwrite
	logical badjust,b2d,bsigma,binsigma
	integer ie,l,ii
	integer ihtot,lmax
	integer ilytyp
        integer ic1,ic2,ic3
	integer nsigma
	real h,hold,hnew,hlast
	real hlvmin
	real hmin,hmax,hsigma
	real hm
	!double precision hm

	integer ieext
	real getpar

	bwrite = .false.

c------------------------------------------------------------
c see if 2D application
c------------------------------------------------------------

	b2d = nlv .eq. 1			!2D application

c------------------------------------------------------------
c check if sigma levels
c------------------------------------------------------------

	call get_sigma(nsigma,hsigma)
	bsigma = nsigma .gt. 0

c	if( bsigma ) then		!sigma layers
c	  write(6,*) 'set_last_layer (nlv used) : ',nlv
c	  write(6,*) 'sigma layers detected'
c	  return
c	end if

c------------------------------------------------------------
c set hlvmin
c------------------------------------------------------------

c	ilytyp: 
c	  0=no adjustment  
c	  1=adjust to full layers (change depth)
c         2=adjust to full layers only if h<hlvmin (change depth)
c         3=add to last layer if h<hlvmin (keep depth but change layer)

	hlvmin = getpar('hlvmin')		!min percentage of last layer
	ilytyp = nint(getpar('ilytyp'))

	if( hlvmin .gt. 1. .or. hlvmin .lt. 0. ) goto 98

c------------------------------------------------------------
c adjust last layer thickness
c------------------------------------------------------------

	ic1 = 0
	ic2 = 0
	ic3 = 0

	ihtot = 0
	lmax = 0

	do ie=1,nel

	  hm = 0.
	  do ii=1,3
	    hm = hm + hm3v(ii,ie)
	  end do
	  hm = hm / 3.

	  l = ilhv(ie)
	  binsigma = l .le. nsigma
	  hold = hm				!original depth of element
	  hnew = hold
	  h = hold
	  if( l .gt. 1 ) h = h - hlv(l-1)	!actual layer thickness
	  if( binsigma ) h = -hold*hldv(l)	!sigma layer
	  hlast = hldv(l)			!regular layer thickness
	  hmin = hlvmin * hlast

	  if( l .gt. 1 .and. h .le. 0. ) goto 99

	  badjust = .false.

	  if( l .gt. 1 ) then			!only for more than 1 layer
	    if( ilytyp .eq. 0 ) then
c		no adjustment
	    else if( h .le. hmin ) then		!take away layer
		badjust = .true.
		l = l-1
	    else if( ilytyp .eq. 1 ) then
		badjust = .true.
	    end if
	  end if

	  if( ilytyp .eq. 1 ) badjust = .true.	!adjust in any case
	  if( b2d ) badjust = .false.		!but never for 2D application
	  if( l .le. nsigma ) badjust = .false.	!we are in sigma layer

	  if( badjust ) then
	    if( ilytyp .le. 2 ) then		!adjust depth
		h = hldv(l)
		hnew = hlv(l)
		do ii=1,3
		  hm3v(ii,ie) = hnew
		end do
	    else if( ilytyp .eq. 3 ) then
		h = hldv(l) + h
	    else
		stop 'error stop set_last_layer: internal error (7)'
	    end if

	    ilhv(ie) = l

	    if( bwrite ) then
	      if( ihtot .eq. 0 ) then
		  write(6,*) 'set_last_layer: Adjustment of depth values'
	      end if
	      write(6,'(2i8,3f12.2)') ie,ieext(ie),l,hnew,hold,h
	    end if
	    ihtot = ihtot + 1
	  end if

	  hlast = h			!finally set last layer thickness
	  lmax = max(lmax,l)

	  if( hlv(l) .ne. hnew ) ic1 = ic1 + 1
	  if( hldv(l) .ne. hlast ) ic2 = ic2 + 1
	  if( l .eq. 1 ) ic3 = ic3 + 1
	end do

c------------------------------------------------------------
c adjust nlv and write final statistics
c------------------------------------------------------------

	nlv=lmax

	write(6,*) 'set_last_layer (nlv used) : ',nlv
	write(6,*) 'Total number of elements with adjusted depth: '
     +			,ihtot
	write(6,*) 'Incomplete depth:     ',ic1
	write(6,*) 'Differing last layer: ',ic2
	write(6,*) 'One layer elements:   ',ic3

c------------------------------------------------------------
c end of routine
c------------------------------------------------------------

	return
   98	continue
	write(6,*) 'hlvmin is given in fraction of last layer'
	write(6,*) 'therefore:  0 <= hlvmin <= 1'
	write(6,*) 'hlvmin = ',hlvmin
	stop 'error stop set_last_layer: hlvmin'
   99	continue
	write(6,*) 'ie,l,hold,h: ',ie,l,hold,h
	write(6,*) 'nsigma,hsigma: ',nsigma,hsigma
	write(6,*) 'hlv: ',nlv,(hlv(l),l=1,nlv)
	if( nsigma > 0 .and. hold < 0. ) then
	  write(6,*) 'cannot yet handle salt marshes with sigma layers'
	end if
	stop 'error stop set_last_layer: layer depth 0 (internal error)'
	end

c*****************************************************************

	subroutine init_coriolis

c sets coriolis parameter

	use mod_internal
	use basin

	implicit none

	real omega2	!double frequency of earth rotation
	parameter ( omega2 = 2.0 * 0.729E-4 )
	real rearth	!radius of earth
	parameter ( rearth = 6371000. )

	include 'param.h'
	include 'mkonst.h'
	include 'pkonst.h'


	integer k,ie,ii
	integer icor
	integer isphe
	real yc,ym,y,ymin,ymax,dlat
	real aux1,aux2,rad
	real getpar

c if coordinates are cartesian (isphe=0) then icor determines 
c how Coriolis is used:
c
c 0:	no Coriolis (default)
c 1:	beta-plane (linear varying Coriolis parameter)
c 2:	f-plane (constant Coriolis parameter)
c
c please note that in case of icor=1 or 2 also the parameter dlat (the average 
c latitude of the basin) has to be set
c
c with spherical coordinates (isphe=1) the default is to always use
c Coriolis. If you really do not want to use Coriolis, then please set
c icor = -1. The parameter dlat is not needed.

	icor=nint(getpar('icor'))	!flag how to use Coriolis
	call get_coords_ev(isphe)

	rad = pi / 180.
	dlat = dcor			! average latitude

	yc=0.
	ymin=ygv(1)
	ymax=ygv(1)
	do k=1,nkn
	  y = ygv(k)
	  yc = yc + y
	  ymin = min(y,ymin)
	  ymax = max(y,ymax)
	end do
	yc=yc/nkn

	if( isphe .eq. 1 ) dlat = yc		! get directly from basin

	aux1 = 0.
	aux2 = 0.

	if(icor.eq.1) then	!beta plane
		aux1 = omega2 * sin(dlat*rad)
		aux2 = omega2 * cos(dlat*rad) / rearth
	else if(icor.eq.2) then	!f plane
		aux1 = omega2 * sin(dlat*rad)
		aux2 = 0.
	end if

	fcor = aux1		! coriolis value of average latitude

	write(6,*) 'pi, dlat     : ',pi,dlat
	write(6,*) 'icor, fcor   : ',icor,fcor
	write(6,*) 'f_0, beta    : ',aux1,aux2
	write(6,*) 'yc,ymin,ymax : ',yc,ymin,ymax

	do ie=1,nel
	  ym=0.
	  do ii=1,3
	    ym=ym+ygv(nen3v(ii,ie))
	  end do
	  ym=ym/3.
	  if( isphe .eq. 0 ) then	!cartesian
	    fcorv(ie)=aux1+aux2*(ym-yc)
	  else if( isphe .eq. 1 ) then	!spherical
	    if( icor .lt. 0 ) then	! -> do not use
	      fcorv(ie) = 0.
	    else
	      !fcorv(ie) = omega2*cos(ym*rad)	!BUG
	      fcorv(ie) = omega2*sin(ym*rad)
	    end if
	  else
	    write(6,*) 'isphe = ',isphe
	    if( isphe .eq. -1 ) write(6,*) '...not initialized'
	    stop 'error stop init_coriolis: value for isphe not allowed'
	  end if
	end do

	end

c*****************************************************************

	subroutine check_coriolis

c checks coriolis parameter

	use mod_internal
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'


	integer ie
	real f,fmax

	fmax = 2.0 * 0.729E-4

	do ie=1,nel
	  f = fcorv(ie)
	  if( fmax - abs(f) .lt. 0. ) then
	    write(6,*) ie,f,fmax
	    stop 'error stop check_coriolis: f too big'
	  end if
	end do

	end

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine inicfil(name,var,nvar)

c initializes nodal value variable from file

	use levels, only : nlvdi,nlv
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'

	character*(*) name		!name of variable
	real var(nlvdi,nkn,1)		!variable to set
        integer nvar

	integer it
	character*80 file

	call getfnm(name,file)
	if( file .eq. ' ' ) return	!nothing to initialize

	write(6,*) 'this call is not supported anymore...'
	write(6,*) name
	write(6,*) file
	stop 'error stop inicfil: unsupported call'

	end

c*****************************************************************

	subroutine inic2fil(name,var,nvar)

c initializes nodal value variable from file (2D version)

	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'

	character*(*) name		!name of variable
	real var(nkn,1)			!variable to set
        integer nvar

	integer it
	integer nlvdi
	character*80 file

	call getfnm(name,file)
	if( file .eq. ' ' ) return	!nothing to initialize

	write(6,*) 'this call is not supported anymore...'
	write(6,*) name
	write(6,*) file
	stop 'error stop inic2fil: unsupported call'

	end

c*****************************************************************

	subroutine init_z(const)

c initializes variables

	implicit none

	real const		!constant z value to impose

	include 'param.h'

	character*80 name

c--------------------------------------------------------
c get name of file
c--------------------------------------------------------

        call getfnm('zinit',name)

c--------------------------------------------------------
c initialize from file or with constant
c--------------------------------------------------------

	if(name.ne.' ') then
	  call init_file_z(name)
	else
	  call init_const_z(const)
	end if

c--------------------------------------------------------
c transfer nodal values to element values
c--------------------------------------------------------

	call setzev

c--------------------------------------------------------
c end of routine
c--------------------------------------------------------

	end

c*****************************************************************

	subroutine init_const_z(const)

c initializes water level with constant

	use mod_hydro
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	real const		!constant z value to impose

	include 'param.h'


	integer k,ie,ii

	do k=1,nkn
	  znv(k) = const
	  !zov(k) = const                !FIXME -> not needed
	end do

	do ie=1,nel
	  do ii=1,3
	    zenv(ii,ie) = const
	    !zeov(ii,ie) = const         !FIXME -> not needed
	  end do
	end do

        write(6,*) 'Water levels initialized with constant z = ',const

	end

c*******************************************************************

	subroutine init_file_z(name)

c initializes water level from file

	use mod_hydro
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	character*(*) name	!file name

	include 'param.h'



	integer nb,k
	integer ifileo

	nb=ifileo(10,name,'unform','old')
	if(nb.le.0) goto 81
	read(nb,err=82,end=82) (znv(k),k=1,nkn)
	close(nb)

	write(6,*) 'Initial water levels read from file : '
	write(6,*) name

	return
   81	continue
	write(6,*) 'Error opening initial water level file :'
	write(6,*) name
	write(6,*) 'on unit ',nb
	stop 'error stop init_file_z'
   82	continue
	write(6,*) 'Error reading from initial water level file'
	write(6,*) name
	stop 'error stop init_file_z'
	end

c*******************************************************************

	subroutine init_uvt

c initializes transport in levels

	use mod_hydro

	implicit none

	include 'param.h'

	utlnv = 0.
	vtlnv = 0.

	end

c*******************************************************************

	subroutine init_z0

c initializes surface z0sk(k) and bottom z0bn(k) roughness 

	use mod_roughness
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	include 'param.h'



	integer k

	do k = 1,nkn
	  z0sk(k) = 0.02
	  z0bk(k) = 0.03 * 0.03       !ggu
	end do

	end

c*******************************************************************
c*******************************************************************
c*******************************************************************

	subroutine set_spherical

	implicit none

	integer isphe
	real getpar

	isphe = nint(getpar('isphe'))
	call set_coords_ev(isphe)

	end

c*******************************************************************

	subroutine adjust_spherical

	implicit none

	integer isphe
	real rsphe

	call get_coords_ev(isphe)
	rsphe = isphe
	call putpar('isphe',rsphe)

	end

c*******************************************************************

        subroutine print_spherical

        implicit none

        integer isphe

	call get_coords_ev(isphe)

        write(6,*) 'setting for coordinates: isphe = ',isphe
        if( isphe .eq. 0 ) then
          write(6,*) 'using cartesian coordinates'
        else
          write(6,*) 'using lat/lon coordinates'
        end if

        end

c*******************************************************************

