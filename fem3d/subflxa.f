c
c $Id: subflxa.f,v 1.25 2009-05-21 09:24:00 georg Exp $
c
c subroutines for computing discharge / flux
c
c contents :
c
c subroutine inflxa
c subroutine rdflxa
c subroutine ckflxa
c subroutine prflxa
c subroutine tsflxa
c
c subroutine wrflxa(it)				write of flux data
c
c subroutine flxscs(n,kflux,iflux,az,fluxes)	flux through sections
c subroutine flxsec(n,kflux,iflux,az,fluxes)	flux through section
c
c subroutine flxini				initializes flux routines
c subroutine flx_init(kfluxm,kflux,nsect,iflux)	sets up array iflux
c subroutine flxinf(m,kflux,iflux)		sets up one info structure
c function igtnsc(k1,k2)			gets number of internal section
c
c revision log :
c
c 30.04.1998    ggu	newly written routines (subpor deleted)
c 07.05.1998    ggu	check nrdveci on return for error
c 08.05.1998    ggu	restructured with new comodity routines
c 13.09.1999    ggu	type of node computed in own routine flxtype
c 19.11.1999    ggu	iskadj into sublin
c 20.01.2000	ggu	old routines substituted, new routine extrsect
c 20.01.2000    ggu     common block /dimdim/ eliminated
c 20.01.2000    ggu     common block /dimdim/ eliminated
c 01.09.2002	ggu	ggu99 -> bug in flx routines (how to reproduce?)
c 26.05.2003	ggu	in flxnov substituted a,b with b,c
c 26.05.2003	ggu	new routine make_fluxes (for lagrangian)
c 10.08.2003	ggu	do not call setweg, setnod, setkan
c 23.03.2006    ggu     changed time step to real
c 28.09.2007    ggu     use testbndo to determine boundary node in flxtype
c 28.04.2009    ggu     links re-structured
c 23.02.2011    ggu     new routine call write_node_fluxes() for special output
c 01.06.2011    ggu     documentation to flxscs() changed
c 21.09.2011    ggu     some lower-level subroutines copied to subflx.f
c 07.10.2011    ggu     adjusted for 3d flux routines
c 19.10.2011    ggu     added T/S variables, created fluxes_*() routines
c 19.10.2011    ggu     added conz variables, created fluxes_template()
c 10.05.2013    ggu     introduced subflxa.h, common routines to subflxu.f
c 20.05.2015    ggu     modules introduced
c
c notes :
c
c These routines can also be used internally to compute the flux
c over various sections. The following calling sequence must be respected:
c
c call flx_init(kfluxm,kflux,nsect,iflux)		initializes iflux
c
c call flxscs(kfluxm,kflux,iflux,az,fluxes) computes fluxes 
c
c Initialization can be done anytime.
c
c******************************************************************
c******************************************************************
c******************************************************************

!==================================================================
        module flux
!==================================================================

        implicit none

        integer, save :: nsect = -1
        integer, save :: kfluxm = 0
        integer, save, allocatable :: kflux(:)
        integer, save, allocatable :: iflux(:,:)

        integer, save, allocatable :: nlayers(:)
        real, save, allocatable :: fluxes(:,:,:)

        real, save, allocatable :: masst(:,:,:)
        real, save, allocatable :: saltt(:,:,:)
        real, save, allocatable :: tempt(:,:,:)
        real, save, allocatable :: conzt(:,:,:)

        integer, save, allocatable :: nrcc(:)
        real, save, allocatable :: cflux(:,:,:,:)

!==================================================================
        contains
!==================================================================

!==================================================================
        end module flux
!==================================================================

        subroutine flux_read_section(n)

        use flux
        use nls

        integer n

        n = nls_read_vector()
        kfluxm = n

        if( n > 0 ) then
          allocate(kflux(n))
          allocate(iflux(3,n))
          call nls_copy_int_vect(n,kflux)
        end if

        end subroutine flux_read_section

c******************************************************************

        subroutine flux_alloc_arrays(nl,ns)

	use flux

	implicit none

	integer nl	!layers
	integer ns	!sections

	if( ns <= 0 ) return

        allocate(nlayers(ns))
        allocate(fluxes(0:nl,3,ns))

        allocate(masst(0:nl,3,ns))
        allocate(saltt(0:nl,3,ns))
        allocate(tempt(0:nl,3,ns))
        allocate(conzt(0:nl,3,ns))

	end

c******************************************************************

        subroutine flux_alloc_conz_arrays(nl,ns,nc)

	use flux

	implicit none

	integer nl	!layers
	integer ns	!sections
	integer nc	!number of concentrations

	if( ns <= 0 .or. nc <= 0 ) return

        allocate(nrcc(nc))
        allocate(cflux(0:nl,3,ns,nc))

	end

c******************************************************************
c******************************************************************
c******************************************************************

        subroutine mod_flx(mode)
 
        implicit none
 
        integer mode
 
        include 'modules.h'
 
	include 'femtime.h'
 
        if( mode .eq. M_AFTER ) then
           call wrflxa(it)
        else if( mode .eq. M_INIT ) then
           call inflxa
        else if( mode .eq. M_READ ) then
           call rdflxa
        else if( mode .eq. M_CHECK ) then
           call ckflxa
        else if( mode .eq. M_SETUP ) then
           call flxini
        else if( mode .eq. M_PRINT ) then
           call prflxa
        else if( mode .eq. M_TEST ) then
           call tsflxa
        else if( mode .eq. M_BEFOR ) then
c          nothing
        else
           write(6,*) 'unknown mode : ', mode
           stop 'error stop mod_flx'
        end if
 
        end

c******************************************************************

        subroutine inflxa

c nsect		total number of sections
c kfluxm	total number of nodes defining sections
c kflux()	node numbers defining sections

        implicit none

        end

c******************************************************************

        subroutine rdflxa

	use flux

        implicit none

	integer n

        call flux_read_section(n)

        if( n .lt. 0 ) then
          write(6,*) 'read error in section $flux'
          stop 'error stop rdflxa'
        end if

        end

c******************************************************************

        subroutine ckflxa

	use flux

        implicit none

	integer k,ii
        logical berror

	call n2int(kfluxm,kflux,berror)

        if( berror ) then
		write(6,*) 'error in section FLUX'
		stop 'error stop: ckflxa'
	end if

c initialize vectors (not strictly necessary)

	do k=1,kfluxm
	  do ii=1,3
	    iflux(ii,k) = 0
	  end do
	end do

c the real set up is done in flxini
c but since at this stage we do not have all the arrays set up
c we post-pone it until later

        end

c******************************************************************

	subroutine prflxa

	use flux

	implicit none

	integer nnode,ifirst,ilast
	integer ntotal,ns
	integer i,ii

	integer ipext
	logical nextline

	write(6,*)
	write(6,*) 'flux section :'
	write(6,*)
	write(6,*) 'nsect,kfluxm ',nsect,kfluxm
	write(6,*)

	ns = 0
	nnode = 0

	do while( nextline(kflux,kfluxm,nnode,ifirst,ilast) )
	  ns = ns + 1
	  ntotal = ilast - ifirst + 1
	  write(6,*) 'section : ',ns,ntotal
	  do i=ifirst,ilast
	    write(6,*) ipext(kflux(i)),(iflux(ii,i),ii=1,3)
	  end do
	end do

	end

c******************************************************************

	subroutine tsflxa

	use flux

	implicit none

	integer i,ii

	write(6,*) '/kfluxc/'
	write(6,*) nsect,kfluxm
	write(6,*) (kflux(i),i=1,kfluxm)

	write(6,*) '/iflux/'
	write(6,*) ((iflux(ii,i),ii=1,3),i=1,kfluxm)

	end

c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************

	subroutine wrflxa(it)

c administers writing of flux data

	use mod_conz
	use mod_ts
	use levels, only : nlvdi,nlv
	use flux

	implicit none

	include 'param.h'

	integer it

	integer itend
	integer j,i,l,lmax,nlmax,ivar,nvers
	integer idtflx
	real az,azpar,rr


	integer ifemop
	real getpar
	double precision dgetpar
	logical has_output,next_output,is_over_output

        integer nrm,nrs,nrt,nrc
	save nrm,nrs,nrt,nrc

        integer ia_out(4)
        save ia_out
        integer nbflx
        save nbflx
	integer ibarcl,iconz
	save ibarcl,iconz

        data nbflx /0/

c-----------------------------------------------------------------
c start of code
c-----------------------------------------------------------------

        if( nbflx .eq. -1 ) return

c-----------------------------------------------------------------
c initialization
c-----------------------------------------------------------------

        if( nbflx .eq. 0 ) then

		call init_output('itmflx','idtflx',ia_out)
		call increase_output(ia_out)
                if( .not. has_output(ia_out) ) nbflx = -1

                if( kfluxm .le. 0 ) nbflx = -1
                if( nsect .le. 0 ) nbflx = -1
                if( nbflx .eq. -1 ) return

        	call flux_alloc_arrays(nlvdi,nsect)

                !if( nsect .gt. nscflxdim ) then
                !  stop 'error stop wrflxa: dimension nscflxdim'
                !end if

		ibarcl = nint(getpar('ibarcl'))
		iconz = nint(getpar('iconz'))

		call get_nlayers(kfluxm,kflux,nlayers,nlmax)

		call fluxes_init(nlvdi,nsect,nlayers,nrm,masst)
		if( ibarcl .gt. 0 ) then
		  call fluxes_init(nlvdi,nsect,nlayers,nrs,saltt)
		  call fluxes_init(nlvdi,nsect,nlayers,nrt,tempt)
		end if
		if( iconz .eq. 1 ) then
		  call fluxes_init(nlvdi,nsect,nlayers,nrc,conzt)
		end if

                nbflx=ifemop('.flx','unform','new')
                if(nbflx.le.0) then
        	   stop 'error stop wrflxa : Cannot open FLX file'
		end if

	        nvers = 5
		idtflx = ia_out(1)
                call wfflx      (nbflx,nvers
     +                          ,nsect,kfluxm,idtflx,nlmax
     +                          ,kflux
     +                          ,nlayers
     +                          )

c               here we could also compute and write section in m**2

        end if

c-----------------------------------------------------------------
c normal call
c-----------------------------------------------------------------

        if( .not. is_over_output(ia_out) ) return

	call getaz(azpar)
	az = azpar

c	-------------------------------------------------------
c	accumulate results
c	-------------------------------------------------------

	ivar = 0
	call flxscs(kfluxm,kflux,iflux,az,fluxes,ivar,rhov)
	call fluxes_accum(nlvdi,nsect,nlayers,nrm,masst,fluxes)

	if( ibarcl .gt. 0 ) then
	  ivar = 11
	  call flxscs(kfluxm,kflux,iflux,az,fluxes,ivar,saltv)
	  call fluxes_accum(nlvdi,nsect,nlayers,nrs,saltt,fluxes)
	  ivar = 12
	  call flxscs(kfluxm,kflux,iflux,az,fluxes,ivar,tempv)
	  call fluxes_accum(nlvdi,nsect,nlayers,nrt,tempt,fluxes)
	end if

	if( iconz .eq. 1 ) then
	  ivar = 10
	  call flxscs(kfluxm,kflux,iflux,az,fluxes,ivar,cnv)
	  call fluxes_accum(nlvdi,nsect,nlayers,nrc,conzt,fluxes)
	end if

c	-------------------------------------------------------
c	time for output?
c	-------------------------------------------------------

        if( .not. next_output(ia_out) ) return

c	-------------------------------------------------------
c	average and write results
c	-------------------------------------------------------

	ivar = 0
	call fluxes_aver(nlvdi,nsect,nlayers,nrm,masst,fluxes)
	call wrflx(nbflx,it,nlvdi,nsect,ivar,nlayers,fluxes)

	if( ibarcl .gt. 0 ) then
	  ivar = 11
	  call fluxes_aver(nlvdi,nsect,nlayers,nrs,saltt,fluxes)
	  call wrflx(nbflx,it,nlvdi,nsect,ivar,nlayers,fluxes)
	  ivar = 12
	  call fluxes_aver(nlvdi,nsect,nlayers,nrt,tempt,fluxes)
	  call wrflx(nbflx,it,nlvdi,nsect,ivar,nlayers,fluxes)
	end if

	if( iconz .eq. 1 ) then
	  ivar = 10
	  call fluxes_aver(nlvdi,nsect,nlayers,nrc,conzt,fluxes)
	  call wrflx(nbflx,it,nlvdi,nsect,ivar,nlayers,fluxes)
	end if

c	-------------------------------------------------------
c	reset variables
c	-------------------------------------------------------

	call fluxes_init(nlvdi,nsect,nlayers,nrm,masst)

	if( ibarcl .gt. 0 ) then
	  call fluxes_init(nlvdi,nsect,nlayers,nrs,saltt)
	  call fluxes_init(nlvdi,nsect,nlayers,nrt,tempt)
	end if

	if( iconz .eq. 1 ) then
	  call fluxes_init(nlvdi,nsect,nlayers,nrc,conzt)
	end if

c-----------------------------------------------------------------
c end of routine
c-----------------------------------------------------------------

	end

c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************

	subroutine flxini

c initializes flux routines finally (wrapper for flx_init)

	use flux

	implicit none

	call flx_init(kfluxm,kflux,nsect,iflux)

	end

c**********************************************************************
c**********************************************************************
c**********************************************************************
c**********************************************************************
c**********************************************************************

	subroutine fluxes_template(it)

c administers writing of flux data
c
c serves as a template for new variables
c please copy to extra file and adapt to your needs
c
c in this version multiple concentrations are written
c
c to change for adaptation:
c
c ncsdim	dimension of parameter arrays (here in param.h)
c conzv		parameters to be computed
c iconz		how many parameters actually needed
c csc		new extension for file
c ivar_base	base of variable numbering

	use mod_conz
	use levels, only : nlvdi,nlv
	use flux

	implicit none

	integer it

	include 'param.h'

	integer itend
	integer j,i,k,l,lmax,nlmax,ivar,nvers,ivar_base
	integer iconz
	real az,azpar,rr

        integer idtflx,itflx,itmflx,nbflx
        save idtflx,itflx,itmflx,nbflx

        data nbflx /0/

	integer ifemop
	real getpar
	double precision dgetpar

c-----------------------------------------------------------------
c start of code
c-----------------------------------------------------------------

        if( nbflx .eq. -1 ) return

c-----------------------------------------------------------------
c initialization
c-----------------------------------------------------------------

        if( nbflx .eq. 0 ) then

                idtflx = nint(dgetpar('idtflx'))
                itmflx = nint(dgetpar('itmflx'))
                itend = nint(dgetpar('itend'))
		iconz = nint(dgetpar('iconz'))	!computing concentrations?

                if( kfluxm .le. 0 ) nbflx = -1
                if( nsect .le. 0 ) nbflx = -1
                if( idtflx .le. 0 ) nbflx = -1
                if( itmflx .gt. itend ) nbflx = -1
                if( iconz .le. 0 ) nbflx = -1
                if( nbflx .eq. -1 ) return

		!be sure that other arrays are already allocated!!!!
        	call flux_alloc_conz_arrays(nlvdi,nsect,iconz)

                !if( nsect .gt. nscflxdim ) then
                !  stop 'error stop fluxes_template: dimension nscflxdim'
                !end if

                itflx = itmflx + idtflx
		itmflx = itmflx + 1	!start from next time step

		call get_nlayers(kfluxm,kflux,nlayers,nlmax)

		do k=1,iconz
		  call fluxes_init(nlvdi,nsect,nlayers
     +				,nrcc(k),cflux(0,1,1,k))
		end do

                nbflx=ifemop('.csc','unform','new')
                if(nbflx.le.0) then
        	   stop 'error stop wrflxa : Cannot open csc file'
		end if

	        nvers = 5
                call wfflx      (nbflx,nvers
     +                          ,nsect,kfluxm,idtflx,nlmax
     +                          ,kflux
     +                          ,nlayers
     +                          )

        end if

c-----------------------------------------------------------------
c normal call
c-----------------------------------------------------------------

        if( it .lt. itmflx ) return

	iconz = nint(getpar('iconz'))
	call getaz(azpar)
	az = azpar
	ivar_base = 200		!base of variable numbering

c	-------------------------------------------------------
c	accumulate results
c	-------------------------------------------------------

	do k=1,iconz
	  ivar = ivar_base + k
	  call flxscs(kfluxm,kflux,iflux,az,fluxes,ivar,conzv(1,1,k))
	  call fluxes_accum(nlvdi,nsect,nlayers
     +			,nrcc(k),cflux(0,1,1,k),fluxes)
	end do

c	-------------------------------------------------------
c	time for output?
c	-------------------------------------------------------

        if( it .lt. itflx ) return
        itflx=itflx+idtflx

c	-------------------------------------------------------
c	average and write results
c	-------------------------------------------------------

	do k=1,iconz
	  ivar = ivar_base + k
	  call fluxes_aver(nlvdi,nsect,nlayers
     +			,nrcc(k),cflux(0,1,1,k),fluxes)
	  call wrflx(nbflx,it,nlvdi,nsect,ivar,nlayers,fluxes)
	end do

c	-------------------------------------------------------
c	reset variables
c	-------------------------------------------------------

	do k=1,iconz
	  call fluxes_init(nlvdi,nsect,nlayers
     +			,nrcc(k),cflux(0,1,1,k))
	end do

c-----------------------------------------------------------------
c end of routine
c-----------------------------------------------------------------

	end

c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************

