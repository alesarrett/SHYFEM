c
c $Id: lagrange_cont.f,v 1.5 2009-09-14 08:20:57 georg Exp $
c
c simulates continuous release over open boundaries
c
c revision log :
c
c 12.12.2007    ggu	written from scratch
c 12.06.2008    ggu	initialize also z
c 28.08.2009    ggu	new call to find_elems_to_segment (before line_elems)
c 16.12.2011    ggu	new routine lagr_continuous_release_ppv()
c 23.01.2012    ggu	new routine for release in point, connectivity
c 23.10.2012    ggu	do not call connectivity here anymore
c 28.03.2014    ggu	new routine lagr_continuous_release_pps_ppv()
c
c*******************************************************************

	subroutine lagr_continuous_release_shell

	implicit none

	!call lagr_continuous_release_pps
	!call lagr_continuous_release_ppv
	call lagr_continuous_release_pps_ppv

	end

c*******************************************************************

	subroutine lagr_continuous_release_ppv

c continuous release - number of particles depends on volume flux

	implicit none

        include 'param.h'
        include 'lagrange.h'

	integer k1,k2
	integer ibc,nk,i,ibtyp,np
	real dt
	real q,ppv

	logical bdebug
	integer nbnds,nkbnds,kbnds,nbc
	integer nptot,iptot
	real rp

	real ggrand
	real get_bflux_ppv

	call get_timestep(dt)

	bdebug = .false.

	nbc = nbnds()

	do ibc=1,nbc

	  nk = nkbnds(ibc)
	  call get_bnd_ipar(ibc,'ibtyp',ibtyp)
	  call get_bnd_par(ibc,'lgrppv',ppv)

	  if( ibtyp .eq. 1 ) then	!only for level boundaries

	    iptot = 0
	    rp = ggrand(77)		! vary starting point of particles
	    do i=2,nk
	      k1 = kbnds(ibc,i-1)
	      k2 = kbnds(ibc,i)
	      q = get_bflux_ppv(k1,k2)
	      q = max(q,0.)
	      rp = rp + q*ppv*dt
	      np = rp
	      if( np .gt. 0 ) then
		rp = rp - np
		iptot = iptot + np
	        call create_parts(ibc,np,k1,k2)
	      end if
	    end do

	    if( iptot .ne. 0 ) then
	      write(lunit,*) 'number of particles released: ',ibc,iptot
	    end if

	  end if

	end do

	end

c*******************************************************************

	subroutine lagr_continuous_release_pps

c continuous release - number of particles is independent of boundary length

	implicit none

        include 'param.h'
        include 'lagrange.h'

	integer k1,k2
	integer ibc,nk,i,ibtyp,np
	real totdist,dxy,part,dt

	integer nbnds,nkbnds,kbnds,nbc
	integer iptot
	real rp,pps,q
	real dist_node

	real ggrand

	call get_timestep(dt)

	nbc = nbnds()

	do ibc=1,nbc

	  nk = nkbnds(ibc)
	  call get_bnd_ipar(ibc,'ibtyp',ibtyp)
	  call get_bnd_par(ibc,'lgrpps',pps)

	  if( ibtyp .eq. 1 ) then	!only for level boundaries

	    call dist_total(ibc,totdist)

	    iptot = 0
	    rp = ggrand(77)		! vary starting point of particles
	    do i=2,nk
	      k1 = kbnds(ibc,i-1)
	      k2 = kbnds(ibc,i)
	      dxy = dist_node(k1,k2)
	      q = dxy/totdist
	      rp = rp + q*pps*dt
	      np = rp
	      if( np .gt. 0 ) then
		rp = rp - np
		iptot = iptot + np
	        call create_parts(ibc,np,k1,k2)
	      end if
	    end do

	    if( iptot .ne. 0 ) then
	      write(lunit,*) 'number of particles released: ',iptot
	    end if

	  end if

	end do

	end

c*******************************************************************

	subroutine lagr_continuous_release_pps_ppv

c continuous release - works both for pps and ppv
c
c replaces the routines above

	implicit none

        include 'param.h'
        include 'lagrange.h'

	integer k,k1,k2
	integer ibc,nk,i,ibtyp,np
	real totdist,dxy,part,dt

	logical bflux
	integer nbnds,nkbnds,kbnds,nbc
	integer iptot
	integer it
	real rp,pps,q

	real dist_node
	real get_bflux_ppv
	real ggrand

	call get_timestep(dt)
	call get_act_time(it)

	nbc = nbnds()

	do ibc=1,nbc

	  nk = nkbnds(ibc)
	  call get_bnd_ipar(ibc,'ibtyp',ibtyp)
	  call get_bnd_par(ibc,'lgrpps',pps)

	  bflux = pps .lt. 0.
	  pps = abs(pps)

	  if( pps .gt. 0. ) then
	   if( ibtyp .eq. 1 .or. ibtyp .eq. 2 ) then	!level or flux bnds

	    call dist_total(ibc,totdist)

	    iptot = 0
	    rp = ggrand(77)		! vary starting point of particles
	    do i=2,nk
	      k1 = kbnds(ibc,i-1)
	      k2 = kbnds(ibc,i)
	      if( bflux ) then
		q = get_bflux_ppv(k1,k2)
	      else
	        q = dist_node(k1,k2) / totdist
	      end if
	!write(333,*) it,i,q
	      q = max(q,0.)
	      rp = rp + q*pps*dt
	      np = rp
	      if( np .gt. 0 ) then
		rp = rp - np
		iptot = iptot + np
	        call create_parts(ibc,np,k1,k2)
	      end if
	    end do

	   else if( ibtyp .eq. 3 ) then		!release on nodes

	    iptot = 0
	    rp = ggrand(77)		! vary starting point of particles
	    do i=1,nk
	      k = kbnds(ibc,i)
	      if( bflux ) then
		call get_bnd_par(ibc,'zval',q)
	      else
	        q = 1
	      end if
	      rp = rp + q*pps*dt 
	      call release_on_node(ibc,rp,k,np)
	      rp = rp - np
	      iptot = iptot + np
	    end do

	   end if
	  end if

	  if( pps .ne. 0 ) then
	    write(lunit,*) 'particles released: ',bflux,ibc,pps,iptot
	  end if

	end do

	end

c*******************************************************************

	subroutine create_parts(ity,np,k1,k2)

	use basin

	implicit none

	integer ity
	integer np,k1,k2

	include 'param.h'

	integer i,ie1,ie2
	real x1,y1,x2,y2,dx,dy
	real rl,rt,x,y

	real ggrand

	if( np .le. 0 ) return

	x1 = xgv(k1)
	y1 = ygv(k1)
	x2 = xgv(k2)
	y2 = ygv(k2)

	dx = x2 - x1
	dy = y2 - y1

	call find_elems_to_segment(k1,k2,ie1,ie2)
	if( ie1 .eq. 0 .or. ie2 .ne. 0 ) then
	  write(6,*) k1,k2,ie1,ie2
	  stop 'error stop create_parts: error in boundary'
	end if
	  
	!write(6,*) 'create_parts: ',np,k1,k2,ie1

	do i=1,np
	  rl = ggrand(77)
	  rt = ggrand(77)
	  x = x1 + rl*dx
	  y = y1 + rl*dy
	  call insert_particle_3d(ie1,ity,rt,x,y)
	  !write(6,*) i,rl,x,y,ie1
	end do

	end

c*******************************************************************

	function get_bflux_ppv(k1,k2)

	use mod_geom

	implicit none

	real get_bflux_ppv
	integer k1,k2

        include 'param.h'
        include 'lagrange.h'

	integer ie1,ie2,ii

	integer inext

	call find_elems_to_segment(k1,k2,ie1,ie2)

	if( ie1 .eq. 0 .or. ie2 .ne. 0 ) then
	  write(6,*) 'k1,k2,ie1,ie2: ',k1,k2,ie1,ie2
	  stop 'error stop get_bflux_ppv: nodes not at boundary'
	end if

	ii = inext(k2,ie1)

	get_bflux_ppv = flux2d(ii,ie1)
	
	end

c*******************************************************************
c*******************************************************************
c*******************************************************************

	subroutine release_on_node(ity,ppts,k,n)

c release on node

	use basin

	implicit none

	integer ity		!type of particle
	real ppts		!particles to be released per time step
	integer k		!node where particle is released
	integer n

	include 'param.h'

	integer ie
	real x,y

	ie = 0
	x = xgv(k)
	y = ygv(k)

	call release_on_point(ity,ppts,ie,x,y,n)

	end

c*******************************************************************

	subroutine release_on_point(ity,ppts,ie,x,y,n)

c release from one point

	implicit none

	integer ity		!type of particle
	real ppts		!particles to be released per time step
	integer ie		!element where particle is released
	real x,y		!coordinates where to release
	integer n		!number of particles released (return)

	integer i
	real rt
	real ggrand

	n = ppts + ggrand(77)			!particles to release

	do i=1,n
	  rt = ggrand(77)			!vary time
	  call insert_particle_3d(ie,ity,rt,x,y)
	  !write(55,*) 'gguuyy particle: ',ie,rt,x,y
	end do

	end

c*******************************************************************
c*******************************************************************
c*******************************************************************

