c
c $Id: subcon1.f,v 1.21 2010-03-11 15:36:39 georg Exp $
c
c routines for concentration (utilities) (old newcon1.f)
c
c contents :
c
c subroutine conini0(nlvddi,c,cref)                      sets initial conditions
c subroutine conini(nlvddi,c,cref,cstrat)		sets initial conditions
c
c subroutine conbnd(nlvddi,c,rbc)			boundary condition
c subroutine con3bnd(nlvddi,c,nlvbnd,rbc)		boundary condition (3D)
c
c subroutine confop(iu,itmcon,idtcon,nlv,nvar,type)	opens (NOS) file
c subroutine confil(iu,itmcon,idtcon,ivar,nlvddi,c)	writes NOS file
c subroutine conwrite(iu,type,nvar,ivar,nlvddi,c)        shell for writing file
c
c subroutine conmima(nlvddi,c,cmin,cmax)                 computes min/max
c subroutine conmimas(nlvddi,c,cmin,cmax)                computes scalar min/max
c
c notes :
c
c conbnd and con3bnd are not used and can be deleted
c
c revision log :
c
c 19.08.1998	ggu	call to conzfi changed
c 20.08.1998	ggu	makew removed (routine used is sp256w)
c 24.08.1998    ggu     levdbg used for debug
c 26.08.1998    ggu     subroutine convol, tstvol transferred to newchk
c 26.08.1998    ggu     all subroutines re-written more generally
c 26.01.1999    ggu     can be used also with 2D routines
c 16.11.2001    ggu     subroutine conmima and diffstab
c 05.12.2001    ggu     new routines diffstab,diffstab1,difflimit
c 11.10.2002    ggu     commented diffset
c 09.09.2003    ggu     new routine con3bnd
c 10.03.2004    ggu     new routine conwrite()
c 13.03.2004    ggu     new routines set_c_bound, distribute_vertically
c 13.03.2004    ggu     exec routine con3bnd() only for level BC (LEVELBC)
c 14.03.2004    ggu     new routines open_b_flux
c 05.01.2005    ggu     routine to write 2d nos file into subnosa.f
c 07.01.2005    ggu     routine diffwrite deleted
c 14.01.2005    ggu     new file for diffusion routines (copied to subdif.f)
c 23.03.2006    ggu     changed time step to real
c 31.05.2007    ggu     reset BC of flux type to old way (DEBHELP)
c 07.04.2008    ggu     deleted set_c_bound
c 08.04.2008    ggu     cleaned, deleted distribute_vertically, open_b_flux
c 09.10.2008    ggu&ccf call to confop changed -> nlv
c 20.11.2009    ggu	in conwrite only write needed (nlv) layers
c 20.01.2014    ggu	new writing format for nos files in confop, confil
c
c*****************************************************************

	subroutine conini0(nlvddi,c,cref)

c sets initial conditions (no stratification)

	use basin, only : nkn,nel,ngr,mbw

	implicit none

	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!variable to initialize
	real cref		!reference value
c common
c local
	integer k,l
	real depth,hlayer

	do k=1,nkn
	  do l=1,nlvddi
	    c(l,k) = cref
	  end do
	end do

	end

c*****************************************************************

	subroutine conini(nlvddi,c,cref,cstrat,hdko)

c sets initial conditions (with stratification)

	use basin, only : nkn,nel,ngr,mbw

	implicit none

	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!variable to initialize
	real cref		!reference value
	real cstrat		!stratification [conc/km]
	real hdko(nlvddi,1)	!layer thickness
c common
c local
	integer k,l
	real depth,hlayer

	do k=1,nkn
	  depth=0.
	  do l=1,nlvddi
	    hlayer = 0.5 * hdko(l,k)
	    depth = depth + hlayer
	    c(l,k) = cref + cstrat*depth/1000.
	    depth = depth + hlayer
	  end do
	end do

	end

c*************************************************************

	subroutine conbnd(nlvddi,c,rbc)

c implements boundary condition (simplicistic version)

	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

c arguments
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!concentration (cconz,salt,temp,...)
	real rbc(1)		!boundary condition
c common
	include 'param.h'
	include 'mkonst.h'
c local
	integer k,l,lmax
	real rb

	do k=1,nkn
	  if( rbc(k) .ne. flag ) then
	    rb = rbc(k)
	    lmax=ilhkv(k)
	    !write(6,*) 'conbnd: ',k,lmax,rb
	    do l=1,lmax
		c(l,k) = rb
	    end do
	  end if
	end do

	end

c*************************************************************

	subroutine con3bnd(nlvddi,c,nlvbnd,rbc)

c implements boundary condition (simplicistic 3D version)

	use mod_bound_dynamic
	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

c arguments
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!concentration (cconz,salt,temp,...)
	integer nlvbnd		!vertical dimension of boundary conditions
	real rbc(nlvbnd,1)	!boundary condition
c common
	include 'param.h'
	include 'mkonst.h'
c local
	integer k,l,lmax
	real rb
        integer ipext

	if( nlvbnd .ne. 1 .and. nlvbnd .ne. nlvddi ) then
	  write(6,*) 'nlvddi,nlvbnd: ',nlvddi,nlvbnd
	  stop 'error stop con3bnd: impossible nlvbnd'
	end if
	if( nlvbnd .ne. nlvddi ) then
	  write(6,*) 'nlvddi,nlvbnd: ',nlvddi,nlvbnd
	  stop 'error stop con3bnd: only 3D boundary conditions'
	end if

	do k=1,nkn
	 if( rzv(k) .ne. flag ) then    !only level BC  !LEVELBC !DEBHELP
	  if( rbc(1,k) .ne. flag ) then
	    lmax=ilhkv(k)
            !write(94,*) 'con3bnd: ',k,ipext(k),lmax,nlvbnd,rbc(1,k)
	    if( nlvbnd .eq. 1 ) then
	      rb = rbc(1,k)
	      do l=1,lmax
		c(l,k) = rb
	      end do
	    else
	      do l=1,lmax
		c(l,k) = rbc(l,k)
	      end do
	    end if
	  end if
	 end if
	end do

	end

c*************************************************************
c*************************************************************
c*************************************************************

	subroutine confop(iu,itmcon,idtcon,nl,nvar,type)

c opens (NOS) file

c on return iu = -1 means that no file has been opened and is not written

	use mod_depth
	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	integer iu		!unit				       (in/out)
	integer itmcon		!time of first write		       (in/out)
	integer idtcon		!time intervall of writes	       (in/out)
	integer nl		!vertical dimension of scalar          (in)
	integer nvar		!total number of variables to write    (in)
	character*(*) type	!extension of file		       (in)

	include 'param.h'
	include 'simul.h'
	include 'femtime.h'

	integer nvers
	integer date,time
	integer ierr
	integer itcon
	!character*80 dir,nam,file
	character*80 title,femver

	integer ifemop
	real getpar
	double precision dgetpar

c-----------------------------------------------------
c check idtcon and itmcon and adjust
c-----------------------------------------------------

	call adjust_itmidt(itmcon,idtcon,itcon)

	iu = -1
        if( idtcon .le. 0 ) return

c-----------------------------------------------------
c open file
c-----------------------------------------------------

	iu = ifemop(type,'unformatted','new')
	if( iu .le. 0 ) goto 98

c-----------------------------------------------------
c initialize parameters
c-----------------------------------------------------

	nvers = 5
	date = nint(dgetpar('date'))
	time = nint(dgetpar('time'))
	title = descrp
	call get_shyfem_version(femver)

c-----------------------------------------------------
c write header of file
c-----------------------------------------------------

	call nos_init(iu,nvers)
	call nos_set_title(iu,title)
	call nos_set_date(iu,date,time)
	call nos_set_femver(iu,femver)
	call nos_write_header(iu,nkn,nel,nl,nvar,ierr)
        if(ierr.gt.0) goto 99
	call nos_write_header2(iu,ilhkv,hlv,hev,ierr)
        if(ierr.gt.0) goto 99

c-----------------------------------------------------
c write informational message to terminal
c-----------------------------------------------------

        write(6,*) 'confop: ',type,' file opened ',it

c-----------------------------------------------------
c end of routine
c-----------------------------------------------------

	return
   98	continue
	write(6,*) 'error opening file with type ',type
	stop 'error stop confop'
   99	continue
	write(6,*) 'error ',ierr,' writing file with type ',type
	stop 'error stop confop'
	end

c*************************************************************

	subroutine confil(iu,itmcon,idtcon,ivar,nlvddi,c)

c writes NOS file

	use levels

	implicit none

	integer iu		!unit
	integer itmcon		!time of first write
	integer idtcon		!time intervall of writes
	integer ivar		!id of variable to be written
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!scalar to write

	include 'param.h'
	include 'femtime.h'

	logical binfo
	integer ierr

	binfo = .false.

c-----------------------------------------------------
c check if files has to be written
c-----------------------------------------------------

	if( iu .le. 0 ) return
	if( it .lt. itmcon ) return
	if( mod(it-itmcon,idtcon) .ne. 0 ) return

c-----------------------------------------------------
c write file
c-----------------------------------------------------

	call nos_write_record(iu,it,ivar,nlvddi,ilhkv,c,ierr)
	if(ierr.gt.0) goto 99

c-----------------------------------------------------
c write informational message to terminal
c-----------------------------------------------------

	if( binfo ) then
          write(6,*) 'confil: variable ',ivar,' written at ',it
	end if

c-----------------------------------------------------
c end of routine
c-----------------------------------------------------

	return
   99	continue
	write(6,*) 'error ',ierr,' writing file at unit ',iu
	stop 'error stop confil'
	end

c*************************************************************

	subroutine conwrite(iu,type,nvar,ivar,nlvddi,c)

c shell for writing file unconditionally to disk

	use levels, only : nlvdi,nlv

        implicit none

	integer iu		!unit (0 for first call, set on return)
        character*(*) type      !type of file
	integer nvar		!total number of variables
	integer ivar		!id of variable to be written
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)	!concentration to write

	include 'femtime.h'

        integer itmcon,idtcon,lmax

        itmcon = itanf
	idtcon = idt
	idtcon = 1
	lmax = min(nlvddi,nlv)

        if( iu .eq. 0 ) then
	  call confop(iu,itmcon,idtcon,lmax,nvar,type)
        end if

	call confil(iu,itmcon,idtcon,ivar,nlvddi,c)

        end

c*************************************************************
c*************************************************************
c*************************************************************

	subroutine open_scalar_file(ia_out,nl,nvar,type)

c opens (NOS) file

c on return iu = -1 means that no file has been opened and is not written

	use mod_depth
	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

	integer ia_out(4)	!time information		       (in/out)
	integer nl		!vertical dimension of scalar          (in)
	integer nvar		!total number of variables to write    (in)
	character*(*) type	!extension of file		       (in)

	include 'param.h'
	include 'femtime.h'

	include 'simul.h'

	integer nvers
	integer date,time
	integer iu,ierr
	character*80 title,femver

	integer ifemop
	double precision dgetpar

c-----------------------------------------------------
c open file
c-----------------------------------------------------

	iu = ifemop(type,'unformatted','new')
	if( iu .le. 0 ) goto 98
	ia_out(4) = iu

c-----------------------------------------------------
c initialize parameters
c-----------------------------------------------------

	nvers = 5
	date = nint(dgetpar('date'))
	time = nint(dgetpar('time'))
	title = descrp
	call get_shyfem_version(femver)

c-----------------------------------------------------
c write header of file
c-----------------------------------------------------

	call nos_init(iu,nvers)
	call nos_set_title(iu,title)
	call nos_set_date(iu,date,time)
	call nos_set_femver(iu,femver)
	call nos_write_header(iu,nkn,nel,nl,nvar,ierr)
        if(ierr.gt.0) goto 99
	call nos_write_header2(iu,ilhkv,hlv,hev,ierr)
        if(ierr.gt.0) goto 99

c-----------------------------------------------------
c write informational message to terminal
c-----------------------------------------------------

        write(6,*) 'open_scalar_file: ',type,' file opened ',it

c-----------------------------------------------------
c end of routine
c-----------------------------------------------------

	return
   98	continue
	write(6,*) 'error opening file with type ',type
	stop 'error stop open_scalar_file'
   99	continue
	write(6,*) 'error ',ierr,' writing file with type ',type
	stop 'error stop open_scalar_file'
	end

c*************************************************************

	subroutine write_scalar_file(ia_out,ivar,nlvddi,c)

c writes NOS file
c
c the file must be open, the file will be written unconditionally

	use levels

	implicit none

	integer ia_out(4)	!time information
	integer ivar		!id of variable to be written
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!scalar to write

	include 'param.h'
	include 'femtime.h'


	logical binfo
	integer iu,ierr

	binfo = .false.

c-----------------------------------------------------
c check if files has to be written
c-----------------------------------------------------

	iu = ia_out(4)
	if( iu .le. 0 ) return

c-----------------------------------------------------
c write file
c-----------------------------------------------------

	call nos_write_record(iu,it,ivar,nlvddi,ilhkv,c,ierr)
	if(ierr.gt.0) goto 99

c-----------------------------------------------------
c write informational message to terminal
c-----------------------------------------------------

	if( binfo ) then
          write(6,*) 'write_scalar_file: ivar = ',ivar,' written at ',it
	end if

c-----------------------------------------------------
c end of routine
c-----------------------------------------------------

	return
   99	continue
	write(6,*) 'error ',ierr,' writing file at unit ',iu
	stop 'error stop write_scalar_file: error in writing record'
	end

c*************************************************************
c*************************************************************
c*************************************************************

        subroutine conmima(nlvddi,c,cmin,cmax)

c computes min/max for scalar field

	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

c arguments
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!concentration (cconz,salt,temp,...)
        real cmin,cmax
c common
	include 'param.h'
c local
	integer k,l,lmax
	real cc
        logical debug
        integer kcmin,lcmin,kcmax,lcmax

        debug = .false.
        cmin = c(1,1)
        cmax = c(1,1)

	do k=1,nkn
	  lmax=ilhkv(k)
	  do l=1,lmax
	    cc = c(l,k)
            if( debug ) then
              if( cc .lt. cmin ) then
                    kcmin = k
                    lcmin = l
              end if
              if( cc .gt. cmax ) then
                    kcmax = k
                    lcmax = l
              end if
            end if
            cmin = min(cmin,cc)
            cmax = max(cmax,cc)
	  end do
	end do

        if( debug ) then
          write(6,*) 'conmima: ',kcmin,lcmin,cmin
          write(6,*) 'conmima: ',kcmax,lcmax,cmax
        end if

        end

c*************************************************************

        subroutine conmimas(nlvddi,c,cmin,cmax)

c computes min/max for scalar field -> writes some info

	use levels
	use basin, only : nkn,nel,ngr,mbw

	implicit none

c arguments
	integer nlvddi		!vertical dimension of c
	real c(nlvddi,1)		!concentration (cconz,salt,temp,...)
        real cmin,cmax
c common
	include 'param.h'
	include 'femtime.h'
c local
	integer k,l,lmax
        integer ntot
	real cc
        logical debug
        integer kcmin,lcmin,kcmax,lcmax

        debug = .false.
        cmin = c(1,1)
        cmax = c(1,1)

        ntot = 0
	do k=1,nkn
	  lmax=ilhkv(k)
	  do l=1,lmax
	    cc = c(l,k)
            if( debug ) then
              if( cc .lt. cmin ) then
                    kcmin = k
                    lcmin = l
              end if
              if( cc .gt. cmax ) then
                    kcmax = k
                    lcmax = l
              end if
            end if
            cmin = min(cmin,cc)
            cmax = max(cmax,cc)
            if( cc .le. 0. ) then
                    ntot = ntot + 1
                    write(96,*) it,l,k,cc,ntot
            end if
	  end do
	end do

        if( ntot .gt. 0 ) then
                write(96,*) 'ntot: ',it,ntot
        end if

        if( debug ) then
          write(6,*) 'conmima: ',kcmin,lcmin,cmin
          write(6,*) 'conmima: ',kcmax,lcmax,cmax
        end if

        end

c*************************************************************

