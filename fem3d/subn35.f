c
c $Id: subn35.f,v 1.17 2009-02-04 15:26:54 georg Exp $
c
c parameter changing area routines
c
c contents :
c
c subroutine bofric(uv,vv,hl)	computes bottom friction
c function cdf(h,z0)		computes cd from h and z0
c
c subroutine rdarea		reads area section (chezy) from STR file
c subroutine ckarea		checks values for chezy parameters
c subroutine prarea		prints chezy values to log file
c subroutine tsarea		prints test message to terminal
c subroutine inarea		initializes chezy values
c
c revision log :
c
c revised on 31.08.88 by ggu  (writes real chezy on czv)
c revised on 29.11.88 by ggu  (new chezy, iarv array)
c revised on 12.04.90 by ggu  (href)
c revised on 03.06.90 by ggu  (austausch)
c revised on 26.06.97 by ggu  (implicit none, useless parts deleted)
c 25.05.1998	ggu	documentation started
c 21.08.1998	ggu	xv eliminated
c 25.05.1999	ggu	new routine bofric
c 20.01.2000    ggu     common block /dimdim/ eliminated
c 09.08.2003    ggu     bofric now returns array with friction
c 10.08.2003    ggu     completely restructured, counter from 0 to nczdum
c 04.09.2003    ggu     bug fix for missing return in get_chezy_values
c 11.01.2005    ggu     ausv eliminated (was not used anymore)
c 02.04.2007    ggu     in check -> warning only for cz=0 and Chezy/Strickler
c 10.12.2008    ggu     re-organized, deleted sp135r(), use bottom_friction()
c 29.01.2009    ggu     ausdef eliminated (chezy(5,.) is not used anymore)
c 16.02.2011    ggu     new routines to deal with nodal area code
c 21.06.2012    ggu&aar new friction for mud module
c 28.04.2015    ggu     czdef is default for all areas not given
c 12.05.2015    ggu     rewritten with modules and allocatable
c
c***********************************************************
c***********************************************************
c***********************************************************

!==================================================================
        module chezy
!==================================================================

        implicit none

        integer, save :: nczdum = 0
        real, save, allocatable :: czdum(:,:)

        integer, save :: nz_lines = 0
	character*80, save, allocatable :: cz_lines(:)

!==================================================================
        contains
!==================================================================

	subroutine chezy_init(n)

	integer n

	nczdum = n
	allocate(czdum(6,0:n))

	czdum = -1.

	end subroutine chezy_init

!==================================================================
        end module chezy
!==================================================================

c
c-------------------------------------------------------------------
c
c DOCS  START   P_friction
c
c DOCS  FRICTION		Bottom friction
c
c The friction term in the momentum equations can be written as
c $Ru$ and $Rv$ where $R$ is the variable friction coefficient and
c $u,v$ are the velocities in $x,y$ direction respectively.
c The form of $R$ can be specified in various ways. The value of 
c |ireib| is choosing between the formulations. In the parameter
c input file a value $\lambda$ is specified that is used in 
c the formulas below.
c
c |ireib|	Type of friction used (default 0):
c		\begin{description}
c		\item[0] No friction used
c		\item[1] $R=\lambda$ is constant
c		\item[2] $\lambda$ is the Strickler coefficient.
c			 In this formulation $R$ is written as
c			 $R = \frac{g}{C^2} \frac{\vert u \vert}{H}$
c			 with $C=k_s H^{1/6}$ and $\lambda=k_s$ is
c			 the Strickler coefficient. In the above
c			 formula $g$ is the gravitational acceleration,
c			 $\vert u \vert$ the modulus of the current velocity
c			 and $H$ the total water depth.
c		\item[3] $\lambda$ is the Chezy coefficient.
c			 In this formulation $R$ is written as
c			 $R = \frac{g}{C^2} \frac{\vert u \vert}{H}$
c			 and $\lambda=C$ is the Chezy coefficient.
c		\item[4] $R=\lambda/H$ with $H$ the total water depth
c		\item[5] $R=\lambda\frac{\vert u \vert}{H}$
c		\end{description}
c |czdef|	The default value for the friction parameter $\lambda$.
c		Depending on the value of |ireib| the coefficient $\lambda$
c		is describing linear friction, constant drag coefficient
c		or a Chezy or Strickler
c		form of friction (default 0).
c |iczv|	Normally $R$ is evaluated at every time step (|iczv| = 1).
c		If for some reason this behavior is not desirable,
c		|iczv| = 0 evaluates the value of $R$ only before the
c		first time step, keeping it constant for the
c		rest of the simulation. (default 1)
c
c The value of $\lambda$ may be specified for the whole basin through
c the value of |czdef|. For more control over the friction parameter
c it can be also specified in section |area| where the friction
c parameter depending on the type of the element may be varied. Please
c see the paragraph on section |area| for more information.
c
c DOCS  END
c
c-------------------------------------------------------------------
c
c***********************************************************

	subroutine bottom_friction

c computes bottom friction

	use mod_fluidmud
	use mod_layer_thickness
	use mod_roughness
	use mod_diff_visc_fric
	use mod_hydro
	use levels
	use basin

	implicit none

	include 'param.h'

	real drittl
	parameter(drittl=1./3.)

	include 'pkonst.h'




	integer ie,ii,k,lmax
	integer ireib
	real hzg,alpha
	real hzoff
	real uso,vso,uv
	real rfric,raux,rr,ss

	real getpar,cdf

c-------------------------------------------------------------------
c get variables
c-------------------------------------------------------------------

	hzoff = getpar('hzoff')
	ireib = nint(getpar('ireib'))

c-------------------------------------------------------------------
c loop on elements
c-------------------------------------------------------------------

	do ie=1,nel

c         ----------------------------------------------------------
c	  get transport in layer
c         ----------------------------------------------------------

	  lmax = ilhv(ie)

          uso = utlov(lmax,ie)
          vso = vtlov(lmax,ie)
	  uv = sqrt(uso*uso+vso*vso)

c         ----------------------------------------------------------
c	  set total depth
c         ----------------------------------------------------------

	  hzg = hdeov(lmax,ie)
          if( hzg .lt. hzoff ) hzg = hzoff

c         ----------------------------------------------------------
c	  get friction parameter
c         ----------------------------------------------------------

	  rfric = czv(ie)

c         ----------------------------------------------------------
c	  compute friction
c         ----------------------------------------------------------

	  if(ireib.eq.0) then
		rr = 0.
          else if(ireib.eq.1) then
                rr = rfric
	  else if(ireib.eq.2) then		! Strickler
		raux = grav/((rfric**2)*(hzg**drittl))
		rr = raux*uv/(hzg*hzg)
	  else if(ireib.eq.3) then		! Chezy
		raux = grav/(rfric**2)
		rr = raux*uv/(hzg*hzg)
          else if(ireib.eq.4) then
                rr = rfric/hzg
	  else if(ireib.eq.5) then		! constant drag coefficient
		rr = rfric*uv/(hzg*hzg)
	  else if(ireib.eq.6) then		! rfric is z0
                raux = cdf(hzg,rfric)
		rr = raux*uv/(hzg*hzg)
          else if(ireib.eq.7) then		! mixed Strickler / drag
                if( rfric .ge. 1. ) then
		  raux = grav/((rfric**2)*(hzg**drittl))
                else
		  raux = rfric
                end if
		rr = raux*uv/(hzg*hzg)
          else if(ireib.eq.8) then		! use z0 computed by sedtrans
                ss = 0.
                do ii=1,3
                  k = nen3v(ii,ie)
                  ss = ss + z0bk(k)
                end do
                ss = ss / 3.
                raux = cdf(hzg,ss)
		rr = raux*uv/(hzg*hzg)
          else if(ireib.eq.9) then		! function of fluid mud (AR:)
                ss = 0.
                do ii=1,3
                  k = nen3v(ii,ie)
                  lmax = ilhkv(k)
                  call set_mud_roughness(k,lmax,alpha) ! (ARON)
                  ss = ss + alpha * rfric ! rfric = ks for this parameterization
                end do
                ss = ss / 3.
                z0bk(k) = ss
                !z0bk(k) = max(z0bkmud(k),ss)
                !ss = rfric	!ARON: do you really need to compute ss above?
                raux = cdf(hzg,ss)
                rr = raux*uv/(hzg*hzg)
		!Well not really there are mainls two issues ...
		!1. Rougnes get reduced by mud this is taken into 
		!account by calling the routine above
		!2. We need to apply mixing length for the 1st grid-cell 
		!otherwise turbulence in gotm fully collapse since k-eps 
		!is only valid for isotropic turbulence. 
	  else
		write(6,*) 'unknown friction : ',ireib
		stop 'error stop bottom_friction'
	  end if

	  rfricv(ie) = rr

	end do

c-------------------------------------------------------------------
c end of routine
c-------------------------------------------------------------------

	end

c***********************************************************

        function cdf(h,z0)

c computes cd from h and z0

        implicit none

        real cdf
        real h,z0

        real kappa,cds

        kappa = 0.4

        cds = kappa / log( (z0+0.5*h) / z0 )

        cdf = cds*cds

        end

c***********************************************************

	subroutine init_nodal_area_code

c interpolates area codes from elements to nodes (min or max)

	use basin

	implicit none

	include 'param.h'

	integer init,mode
	integer k,ie,ii,ia

	mode = -1		! -1: use minimum   +1: use maximum

	init = 99999999
	if( mode .gt. 0 ) init = -init

	do k=1,nkn
	  iarnv(k) = init
	end do

	do ie=1,nel
	  ia = iarv(ie)
	  do ii=1,3
	    k = nen3v(ii,ie)
	    if( mode .eq. -1 ) then
		iarnv(k) = min(iarnv(k),ia)
	    else
		iarnv(k) = max(iarnv(k),ia)
	    end if
	  end do
	end do

	end

c***********************************************************

	subroutine get_nodal_area_code(k,ncode)

	use basin

	implicit none

	integer k	!node number
	integer ncode	!nodal area code (return)

	include 'param.h'

	ncode = iarnv(k)

	end

c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************

	subroutine n_chezy_values(nareas)

	use chezy

	implicit none

	integer nareas

	nareas = nczdum

	end

c***********************************************************

	subroutine get_chezy_values(iar,valin,valout)

	use chezy

	implicit none

	integer iar
	real valin,valout

	if( iar .gt. nczdum ) goto 99

	valin = czdum(1,iar)
	valout = czdum(2,iar)

	return
   99	continue
	write(6,*) 'iar,nczdum: ',iar,nczdum
	stop 'error stop get_chezy_values'
	end

c***********************************************************

	subroutine set_chezy_values(iar,valin,valout)

	use chezy

	implicit none

	integer iar
	real valin,valout

	if( iar .gt. nczdum ) goto 99

	czdum(1,iar) = valin
	czdum(2,iar) = valout

	return
   99	continue
	write(6,*) 'iar,nczdum: ',iar,nczdum
	stop 'error stop set_chezy_values'
	end

c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************

	subroutine set_chezy

c initializes chezy arrays

	use mod_diff_visc_fric
	use basin
	use chezy

	implicit none

	include 'param.h'

	integer ie,iar

	do ie=1,nel
	    iar=iarv(ie)
	    czv(ie)=czdum(6,iar)
	end do

	end

c***********************************************************

	subroutine init_chezy

c initializes chezy arrays

	use chezy

	implicit none

	logical bdebug
	integer i

	bdebug = .true.
	bdebug = .false.

	do i=0,nczdum
	  czdum(6,i)=czdum(1,i)
	end do

	if( bdebug ) call print_chezy

	call set_chezy

	end

c***********************************************************

	subroutine adjust_chezy

c adjusts chezy arrays

	use mod_hydro_print
	use basin
	use chezy

	implicit none

	include 'param.h'

	logical bdebug
	integer i,k1,k2
	integer iczv
	real dx,dy,scal

	real getpar

	bdebug = .true.
	bdebug = .false.

	iczv=nint(getpar('iczv'))
	if( iczv .eq. 0 ) return	!chezy is not adjusted

	do i=0,nczdum
	    if(czdum(2,i).eq.0.) then
		czdum(6,i)=czdum(1,i)
	    else
		k1=nint(czdum(3,i))
		k2=nint(czdum(4,i))
		dx=xgv(k2)-xgv(k1)
		dy=ygv(k2)-ygv(k1)
		scal=dx*up0v(k1)+dy*vp0v(k1)
		if(scal.ge.0.) then
			czdum(6,i)=czdum(1,i)
		else
			czdum(6,i)=czdum(2,i)
		end if
	    end if
	end do

	if( bdebug ) call print_chezy

	call set_chezy

	end

c***********************************************************

	subroutine print_chezy

c prints chezy arrays

	use chezy

	implicit none

	integer i
	integer iunit

	iunit = 6

	write(iunit,*) 'Values for chezy (czv) :'
	do i=0,nczdum
	  write(iunit,*) i,czdum(6,i)
	end do

	end

c***********************************************************

	subroutine check_chezy

c checks chezy arrays

	use basin
	use chezy

	implicit none


	include 'param.h'

	integer ie,iar
	integer i,j,k
	real cz

	do i=0,nczdum
	  cz = czdum(1,i)
	  if( cz .lt. 0. .or. cz .gt. 1.e+10 ) goto 99
	  cz = czdum(2,i)
	  if( cz .lt. 0. .or. cz .gt. 1.e+10 ) goto 99
	  if( cz .gt. 0. ) then
	    k = nint(czdum(3,i))
	    if( k .lt. 0. .or. k .gt. nkn ) goto 99
	    k = nint(czdum(4,i))
	    if( k .lt. 0. .or. k .gt. nkn ) goto 99
	  end if
	  cz = czdum(6,i)
	  if( cz .lt. 0. .or. cz .gt. 1.e+10 ) goto 99
	end do

	do ie=1,nel
	    iar=iarv(ie)
	    if( iar .gt. nczdum ) goto 98
	    cz=czdum(6,iar)
	    if( cz .lt. 0. .or. cz .gt. 1.e+10 ) goto 98
	end do

	return
   98	continue
	write(6,*) 'ie,iar,nczdum,cz: ',ie,iar,nczdum,cz
	write(6,*) (czdum(j,iar),j=1,6)
	stop 'error stop check_chezy: error in values (1)'
   99	continue
	write(6,*) 'i,iar,nczdum: ',i,i-1,nczdum
	write(6,*) (czdum(j,i),j=1,6)
	stop 'error stop check_chezy: error in values (2)'
	end

c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************
c***********************************************************

	subroutine rdarea

c reads area section (chezy) from STR file

	use nls
	use chezy

	implicit none

	integer n,i

	n = nls_read_table()

	if( n > 0 ) then
	  nz_lines = n
	  allocate(cz_lines(n))
	  call nls_copy_char_vect(n,cz_lines)
	end if

	end

c***********************************************************

	subroutine parse_area

c parses area section (chezy) from STR file

	use chezy

	implicit none

	character*80 line
	integer ianz,iar,i,n,il
	real f(10)

	integer iscanf

	do il=1,nz_lines
	  line = cz_lines(il)
	  !write(6,*) il,trim(line)
	  ianz = iscanf(line,f,10)
	  if( ianz .gt. 0 ) then
	    iar = nint(f(1))
            if(iar.lt.0) goto 88
	    if( ianz .gt. 7 ) goto 86
            if(iar.gt.nczdum) then
	      write(6,*) 'warning: no such area code... ignoring ',iar
	      cycle
	    end if
	    do i=2,ianz
	      czdum(i-1,iar) = f(i)
	    end do
	  else if( ianz .lt. 0 ) then
			goto 98
	  end if
	end do

	if( nz_lines > 0 ) then
	  nz_lines = 0
	  deallocate(cz_lines)	!we dont need it anymore
	end if

	return
   86   continue
        write(6,*) 'Too much data on line'
        write(6,*) line
        stop 'error stop : rdarea'
   88   continue
        write(6,*) 'Negative area code = ',iar,' not allowed'
        write(6,*) line
        stop 'error stop : rdarea'
   98   continue
        write(6,*) 'Read error in line :'
	write(6,*) line
        stop 'error stop : rdarea'
	end

c***********************************************************

	subroutine ckarea

c checks values for chezy parameters

	use basin
	use chezy

	implicit none

	include 'param.h'

	integer i,knode,knodeh,ireib,nczmax
	logical bstop,bpos
	real czdef

	integer ipint
	real getpar

	bstop = .false.

c get default values

        ireib=nint(getpar('ireib'))
	!if( ireib .le. 0 ) return

	bpos = ireib .gt. 1 .and. ireib .ne. 5	!must be strictly positive

        czdef=getpar('czdef')

c compute maximum value of area code

	nczmax = 0
	do i=1,nel
          if(iarv(i).gt.nczmax) nczmax=iarv(i)
        end do

c allocate and parse arrays

	call chezy_init(nczmax)
	call parse_area

c check read in values

        do i=0,nczdum

         if(czdum(1,i).eq.-1.) czdum(1,i)=czdef

         if(czdum(1,i).lt.0.) then
                write(6,*) 'Friction value cannot be negative:'
                write(6,*) 'area = ',i,'  chezy = ',czdum(1,i)
                bstop=.true.
	 end if

	 if( bpos .and. czdum(1,i).eq.0.) then
                write(6,*) 'Friction value must be positive:'
                write(6,*) 'area = ',i,'  chezy = ',czdum(1,i)
                bstop=.true.
	 end if

         if(czdum(2,i).eq.-1.) czdum(2,i)=0.

         if(czdum(3,i).eq.-1. .or. czdum(3,i).eq.0.) then
           czdum(3,i)=0.
         else
           knodeh=nint(czdum(3,i))
           knode=ipint(knodeh)          !$$EXTINW
           if(knode.le.0) then
                write(6,*) 'section AREA : node not found ',knodeh
                bstop=.true.
           end if
           czdum(3,i)=knode
         end if

         if(czdum(4,i).eq.-1. .or. czdum(4,i).eq.0.) then
           czdum(4,i)=0.
         else
           knodeh=nint(czdum(4,i))
           knode=ipint(knodeh)          !$$EXTINW
           if(knode.le.0) then
                write(6,*) 'section AREA : node not found ',knodeh
                bstop=.true.
           end if
           czdum(4,i)=knode
         end if

         if(czdum(5,i).eq.-1.) czdum(5,i)=0.
         czdum(6,i)=0.

        end do

	if( bstop ) stop 'error stop ckarea'

	end

c***********************************************************

	subroutine prarea

c prints chezy values to log file

	use chezy

	implicit none

	integer ianf,i
	integer ipext

        ianf=0
        if(czdum(1,0).eq.0) ianf=1
        write(6,*)
        write(6,1007)

        do i=ianf,nczdum
            if(czdum(2,i).ne.0.) then			!with two chezy
                write(6,1008) i,czdum(1,i),czdum(2,i)
     +                          ,ipext(nint(czdum(3,i)))
     +                          ,ipext(nint(czdum(4,i)))
            else					!just one chezy
                write(6,1008) i,czdum(1,i)
            end if
        end do

	return
 1007   format(' area,cz1,cz2,k1,k2 : ')
 1008   format(i5,2e12.4,2i7,e12.4)
	end

c***********************************************************

	subroutine tsarea

c prints test message to terminal

	use chezy

	implicit none

	integer j,i

        write(6,*) '/chezy/'
        write(6,*) nczdum
        do j=0,nczdum
            write(6,'(1x,6e12.4)') (czdum(i,j),i=1,6)
        end do

	end

c***********************************************************

	subroutine inarea

c initializes chezy values

	use chezy

	implicit none

	end

c***********************************************************

