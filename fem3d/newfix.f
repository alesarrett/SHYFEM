c
c $Id: newfix.f,v 1.5 2009-03-24 17:49:19 georg Exp $
c
c fix or nudge velocities at open boundary
c
c contents :
c
c subroutine bclfix_ini_intern	internal routine to initialize common values
c subroutine bclnudge		nudges velocities on open boundaries
c subroutine bclfix		fixes velocities on open boundaries
c subroutine bclfix_ini		initialization of bclfix routines
c
c revision log :
c
c 15.09.2008    ggu     written from scratch
c 03.11.2008    ggu&dbf nudging implemented
c 12.11.2008    ggu     handle sigma coordinates
c 06.12.2008    ggu     read nbfix from STR
c 19.01.2009    ggu     no error stop in initializing when nbfix=0
c 23.03.2009    ggu     tramp from start of simulation
c 16.12.2010    ggu     bsigma renamed to bosigma
c 29.10.2014    ccf     rewritten for 7_0_3, vel file for each boundary
c*****************************************************************

        subroutine bclfix_ini

c initialization of bclfix routines

	use mod_bclfix
	use mod_internal
	use mod_aux_array
	use basin

        implicit none 

        include 'param.h' 




	real tnudge	!relaxation time for nudging [s]

        integer ie,l,i,ii,k,n,nn,nf
	integer ibc,nodes
	integer nbc
       
	integer nkbnds,kbnds,nbnds
	integer ieext
	logical bdebug

	bdebug = .true.
	bdebug = .false.

c------------------------------------------------------------------
c initialize arrays
c------------------------------------------------------------------

	do ie = 1,nel
	  iuvfix(ie) = 0
	  tnudgev(ie) = 0.
	  do n = 0,3
	    ielfix(n,ie) = 0
	  end do
	end do

c------------------------------------------------------------------
c loop over boundaries
c------------------------------------------------------------------

	nbc = nbnds()

	do ibc = 1, nbc

          call get_bnd_par(ibc,'tnudge',tnudge)

	  if (tnudge .lt. 0. ) cycle

	  nodes = nkbnds(ibc)

	  !------------------------------------------------------------------
	  ! flag boundary nodes
	  !------------------------------------------------------------------

          do k=1,nkn
            v1v(k) = 0.
          end do

	  do i=1,nodes
	    k = kbnds(ibc,i)
	    v1v(k) = 1.
	  end do

	  !------------------------------------------------------------------
	  ! set up ielfix and tnudgev/iuvfix
	  !------------------------------------------------------------------

	  do ie=1,nel

	    n = 0
	    do ii=1,3
	      k = nen3v(ii,ie)
	      if( v1v(k) .ne. 0. ) then
	        n = n + 1
	        ielfix(n,ie) = k
	      end if
	    end do
	    ielfix(0,ie) = n			!total number of nodes for ele

	    if( n .gt. 0 ) then			!nudging or fixing
  	      if( tnudge == 0. ) then
		iuvfix(ie) = 1
  	      else if( tnudge > 0. ) then
		tnudgev(ie) = tnudge
	      else
		stop 'error stop bclfix_ini: internal error (1)'
	      end if
	    end if

	  end do

c------------------------------------------------------------------
c end loop over boundaries
c------------------------------------------------------------------

	end do

c------------------------------------------------------------------
c debug output
c------------------------------------------------------------------

	if( .not. bdebug ) return

	write(6,*) 'bclfix_ini has been initialized'

	nf = 0
	nn = 0
	do ie=1,nel
	  if( ielfix(0,ie) .ne. 0 ) then
	    if( iuvfix(ie) .ne. 0 ) then
	     write(6,*) 'Fix ie = ',ie,ieext(ie),'nn = ',ielfix(0,ie)
	     nf = nf + 1
	    else
	     write(6,*) 'Nudge ie = ',ie,ieext(ie),'nn = ',ielfix(0,ie)
	     nn = nn + 1
	    end if
	  end if
	end do

	write(6,*) '-------------'
	write(6,*) 'bclfix_ini has found ',nf,' elements to be fixed'
	write(6,*) 'bclfix_ini has found ',nn,' elements to be nudged'
	write(6,*) '-------------'

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

        end

c*****************************************************************

        subroutine bclfix

c fix or nudge  velocities on open boundaries

	use mod_bclfix
	use mod_internal
	use mod_geom_dynamic
	use mod_layer_thickness
	use mod_hydro_vel
	use mod_hydro
	use levels
	use basin, only : nkn,nel,ngr,mbw

        implicit none 

        include 'param.h' 

	include 'femtime.h'

	real tnudge	!relaxation time for nudging [s]
	real tramp	!time for smooth init

        integer ie,l,i,k,ii,n
	integer lmax
	integer nbc
        real u(nlvdi),v(nlvdi)
        real h,t
        real alpha
	real uexpl,vexpl
        
	integer nintp,nvar
	real cdef(2)
        double precision dtime0,dtime
        integer, save, allocatable :: idvel(:)
        character*10 what

	integer nbnds

	integer icall
	save icall
	data icall /0/

        if( icall .eq. -1 ) return

c------------------------------------------------------------------
c initialize open boundary conditions
c------------------------------------------------------------------

	if( icall .eq. 0 ) then

          icall = -1
	  do ie = 1,nel
	    if ( ielfix(0,ie) .ne. 0 ) icall = 1
	  end do

          if( icall .eq. -1 ) return

          nbc = nbnds()
          allocate(idvel(nbc))
	  idvel = 0

          dtime0  = itanf
          nintp   = 2
          nvar    = 2
          cdef    = 0.
          what    = 'vel'
          call bnds_init_new(what,dtime0,nintp,nvar,nkn,nlv
     +                      ,cdef,idvel)

	end if

c------------------------------------------------------------------
c read boudary velocities from file and store in u/vbound
c------------------------------------------------------------------

        dtime = it

        call bnds_read_new(what,idvel,dtime)
        call bnds_trans_new(what,idvel,dtime,1,nkn,nlv,nlvdi,ubound)
        call bnds_trans_new(what,idvel,dtime,2,nkn,nlv,nlvdi,vbound)

c------------------------------------------------------------------
c simulate smooth initial discharge with tramp
c------------------------------------------------------------------

        tramp = 43200.          !smooth init
        tramp = 0.              !smooth init

        if( it-itanf .le. tramp ) then
	  alpha = (it-itanf) / tramp
        else
	  alpha = 1.
        endif

c------------------------------------------------------------------
c nudge of fix velocities in elements
c------------------------------------------------------------------

	do ie=1,nel
	  n = ielfix(0,ie)
	  if( n .gt. 0 ) then

	    lmax = ilhv(ie)

	    do l=1,lmax
	      u(l) = 0.
	      v(l) = 0.
	    end do

	    do i=1,n
	      k = ielfix(i,ie)
	      do l=1,lmax
	        u(l) = u(l) + ubound(l,k)
	        v(l) = v(l) + vbound(l,k)
	      end do
	    end do

	    do l=1,lmax
	      u(l) = u(l) / n
	      v(l) = v(l) / n
	    end do

	    tnudge = tnudgev(ie)

	    if (iuvfix(ie) .eq. 1 ) then	!fix velocities
              do l=1,lmax
                h = hdeov(l,ie)
                ulnv(l,ie) = u(l)*alpha
                vlnv(l,ie) = v(l)*alpha
                utlnv(l,ie) = ulnv(l,ie)*h
                vtlnv(l,ie) = vlnv(l,ie)*h
              end do
	    else if( tnudge > 0 ) then		!nudge velocities
	      do l=1,lmax
                h = hdeov(l,ie)
                uexpl = (ulnv(l,ie)-u(l))*alpha*h/tnudge
                vexpl = (vlnv(l,ie)-v(l))*alpha*h/tnudge
	        fxv(l,ie) = fxv(l,ie) + uexpl
	        fyv(l,ie) = fyv(l,ie) + vexpl
	      end do
	    end if
	  end if
	end do

c------------------------------------------------------------------
c end of routine
c------------------------------------------------------------------

	return
   99	continue
	stop 'error stop bclfix: internal error (1)'
        end

c*****************************************************************
