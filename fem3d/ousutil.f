c
c $Id: ousutil.f,v 1.3 2009-09-14 08:20:58 georg Exp $
c
c utilities for OUS files
c
c revision log :
c
c 16.12.2010	ggu	copied from ousextr_gis.f
c 03.06.2011	ggu	some routines transfered to genutil.f
c 08.06.2011	ggu	new routine transp2nodes()
c 10.11.2011    ggu     new routines for hybrid levels
c 02.12.2011    ggu     bug fix for call to get_sigma_info() (missing argument)
c 21.01.2013    ggu     added two new routines comp_vel2d, comp_barotropic
c 05.09.2013    ggu     new call to get_layer_thickness()
c 20.01.2014    ggu     new helper routines
c 29.04.2015    ggu     new helper routines for start/end time in file
c
c******************************************************************

        subroutine transp2vel(nel,nkn,nlv,nlvddi,hev,zenv,nen3v
     +				,ilhv,hlv,utlnv,vtlnv
     +                          ,uprv,vprv,weight,hl)

c transforms transports at elements to velocities at nodes

        implicit none

        integer nel
        integer nkn
	integer nlv
        integer nlvddi
        real hev(1)
        real zenv(3,1)
	integer nen3v(3,1)
	integer ilhv(1)
	real hlv(1)
        real utlnv(nlvddi,1)
        real vtlnv(nlvddi,1)
        real uprv(nlvddi,1)
        real vprv(nlvddi,1)
        real weight(nlvddi,1)		!aux variable for weights
	real hl(1)			!aux variable for real level thickness

	logical bsigma
        integer ie,ii,k,l,lmax,nsigma,nlvaux
        real hmed,u,v,area,zeta
	real hsigma

	real area_elem

	call get_sigma_info(nlvaux,nsigma,hsigma)
	if( nlvaux .gt. nlvddi ) stop 'error stop transp2vel: nlvddi'
	bsigma = nsigma .gt. 0

	do k=1,nkn
	  do l=1,nlv
	    weight(l,k) = 0.
	    uprv(l,k) = 0.
	    vprv(l,k) = 0.
	  end do
	end do
	      
        do ie=1,nel

	  area = area_elem(ie)
	  lmax = ilhv(ie)
	  call compute_levels_on_element(ie,zenv,zeta)
	  call get_layer_thickness(lmax,nsigma,hsigma,zeta,hev(ie),hlv,hl)
	  !call get_layer_thickness_e(ie,lmax,bzeta,nsigma,hsigma,hl)

	  do l=1,lmax
	    hmed = hl(l)
	    u = utlnv(l,ie) / hmed
	    v = vtlnv(l,ie) / hmed
	    do ii=1,3
	      k = nen3v(ii,ie)
	      uprv(l,k) = uprv(l,k) + area * u
	      vprv(l,k) = vprv(l,k) + area * v
	      weight(l,k) = weight(l,k) + area
	    end do
	  end do
	end do

	do k=1,nkn
	  do l=1,nlv
	    area = weight(l,k)
	    if( area .gt. 0. ) then
	      uprv(l,k) = uprv(l,k) / area
	      vprv(l,k) = vprv(l,k) / area
	    end if
	  end do
	end do
	      
	end

c******************************************************************

        subroutine transp2nodes(nel,nkn,nlv,nlvddi,hev,zenv,nen3v
     +				,ilhv,hlv,utlnv,vtlnv
     +                          ,utprv,vtprv,weight)

c transforms transports at elements to transports at nodes

        implicit none

        integer nel
        integer nkn
	integer nlv
        integer nlvddi
        real hev(1)
        real zenv(3,1)
	integer nen3v(3,1)
	integer ilhv(1)
	real hlv(1)
        real utlnv(nlvddi,1)
        real vtlnv(nlvddi,1)
        real utprv(nlvddi,1)
        real vtprv(nlvddi,1)
        real weight(nlvddi,1)

        integer ie,ii,k,l,lmax
        real u,v,w

	do k=1,nkn
	  do l=1,nlv
	    weight(l,k) = 0.
	    utprv(l,k) = 0.
	    vtprv(l,k) = 0.
	  end do
	end do
	      
        do ie=1,nel
	  lmax = ilhv(ie)
	  do l=1,lmax
	    u = utlnv(l,ie)
	    v = vtlnv(l,ie)
	    do ii=1,3
	      k = nen3v(ii,ie)
	      utprv(l,k) = utprv(l,k) + u
	      vtprv(l,k) = vtprv(l,k) + v
	      weight(l,k) = weight(l,k) + 1.
	    end do
	  end do
	end do

	do k=1,nkn
	  do l=1,nlv
	    w = weight(l,k)
	    if( w .gt. 0. ) then
	      utprv(l,k) = utprv(l,k) / w
	      vtprv(l,k) = vtprv(l,k) / w
	    end if
	  end do
	end do
	      
	end

c***************************************************************

        subroutine comp_vel2d(nel,hev,zenv,ut2v,vt2v,u2v,v2v
     +				,umin,vmin,umax,vmax)

c computes 2D velocities from 2D transports - returns result in u2v,v2v

        implicit none

        integer nel
        real hev(1)
        real zenv(3,1)
        real ut2v(1)
        real vt2v(1)
	real u2v(1), v2v(1)
        real umin,vmin
        real umax,vmax

        integer ie,ii
        real zmed,hmed,u,v

	umin = +1.e+30
	vmin = +1.e+30
	umax = -1.e+30
	vmax = -1.e+30

        do ie=1,nel
          zmed = 0.
          do ii=1,3
            zmed = zmed + zenv(ii,ie)
          end do
          zmed = zmed / 3.
          hmed = hev(ie) + zmed

          u = ut2v(ie) / hmed
          v = vt2v(ie) / hmed

	  u2v(ie) = u
	  v2v(ie) = v

          umin = min(umin,u)
          vmin = min(vmin,v)
          umax = max(umax,u)
          vmax = max(vmax,v)
        end do

        end

c***************************************************************

	subroutine comp_barotropic(nel,nlvddi,ilhv
     +			,utlnv,vtlnv,ut2v,vt2v)

c computes barotropic transport

	implicit none

	integer nel,nlvddi
	integer ilhv(1)
	real utlnv(nlvddi,1)
	real vtlnv(nlvddi,1)
	real ut2v(1)
	real vt2v(1)

	integer ie,l,lmax
	real utot,vtot

	do ie=1,nel
	  lmax = ilhv(ie)
	  utot = 0.
	  vtot = 0.
	  do l=1,lmax
	    utot = utot + utlnv(l,ie)
	    vtot = vtot + vtlnv(l,ie)
	  end do
	  ut2v(ie) = utot
	  vt2v(ie) = vtot
	end do

	end

c***************************************************************

	subroutine compute_volume(nel,zenv,hev,volume)

	use evgeom

	implicit none


	integer nel
	real zenv(3,1)
	real hev(1)
	real volume

	integer ie,ii
	real zav,area
	double precision vol,voltot,areatot

	real area_elem

	voltot = 0.
	areatot = 0.

	do ie=1,nel
	  zav = 0.
	  do ii=1,3
	    zav = zav + zenv(ii,ie)
	  end do
	  area = area_elem(ie)
	  vol = area * (hev(ie) + zav/3.)
	  voltot = voltot + vol
	  !areatot = areatot + area
	end do

	volume = voltot

	end

c***************************************************************

        subroutine debug_write_node(ks,it,nrec
     +		,nknddi,nelddi,nlvddi,nkn,nel,nlv
     +          ,nen3v,zenv,znv,utlnv,vtlnv)

c debug write

        implicit none

	integer ks	!internal node number to output (0 for none)
        integer it,nrec
        integer nknddi,nelddi,nlvddi,nkn,nel,nlv
        integer nen3v(3,nelddi)
        real znv(nknddi)
        real zenv(3,nelddi)
        real utlnv(nlvddi,nelddi)
        real vtlnv(nlvddi,nelddi)

        integer ie,ii,k,l
        logical bk

	if( ks .le. 0 ) return

        write(66,*) 'time: ',it,nrec
        write(66,*) 'kkk: ',ks,znv(ks)

        do ie=1,nel
          bk = .false.
          do ii=1,3
            k = nen3v(ii,ie)
            if( k .eq. ks ) then
              write(66,*) 'ii: ',ii,ie,zenv(ii,ie)
              bk = .true.
            end if
          end do
          if( bk ) then
          do l=1,nlv
            write(66,*) 'ie: ',ie,l,utlnv(l,ie),vtlnv(l,ie)
          end do
          end if
        end do

        end

c***************************************************************
c***************************************************************
c***************************************************************

        subroutine write_ous_header(iu,ilhv,hlv,hev)

c other variables are stored internally
c
c must have been initialized with ous_init
c all other variables must have already been stored internally (title,date..)

        implicit none

        integer iu
        integer ilhv(1)
        real hlv(1)
        real hev(1)

        integer nkn,nel,nlv
        integer ierr

        call ous_get_params(iu,nkn,nel,nlv)
        call ous_write_header(iu,nkn,nel,nlv,ierr)
        if( ierr .ne. 0 ) goto 99
        call ous_write_header2(iu,ilhv,hlv,hev,ierr)
        if( ierr .ne. 0 ) goto 99

        return
   99   continue
        write(6,*) 'error in writing header of OUS file'
        stop 'error stop write_ous_header: writing header'
        end

c***************************************************************

        subroutine peek_ous_header(iu,nkn,nel,nlv)

c get size of data

        implicit none

        integer iu
        integer nkn,nel,nlv

        integer nvers
        integer ierr

        nvers = 2
        call ous_init(iu,nvers)

        call ous_read_header(iu,nkn,nel,nlv,ierr)
        if( ierr .ne. 0 ) goto 99

        call ous_close(iu)
        rewind(iu)

        return
   99   continue
        write(6,*) 'error in reading header of OUS file'
        stop 'error stop peek_ous_header: reading header'
        end

c***************************************************************

        subroutine read_ous_header(iu,nknddi,nelddi,nlvddi,ilhv,hlv,hev)

c other variables are stored internally

        implicit none

        integer iu
        integer nknddi,nelddi,nlvddi
        integer ilhv(nknddi)
        real hlv(nlvddi)
        real hev(nelddi)

        integer nvers
        integer nkn,nel,nlv,nvar
        integer ierr
        integer l
        integer date,time
	real href,hzmin
        character*50 title,femver

        nvers = 2

        call ous_init(iu,nvers)

        call ous_read_header(iu,nkn,nel,nlv,ierr)
        if( ierr .ne. 0 ) goto 99

        call dimous(iu,nknddi,nelddi,nlvddi)
	!call infoous(iu,6)

        call getous(iu,nvers,nkn,nel,nlv)
        call ous_get_date(iu,date,time)
        call ous_get_title(iu,title)
        call ous_get_femver(iu,femver)
        call ous_get_hparams(iu,href,hzmin)

        write(6,*) 'nvers      : ',nvers
        write(6,*) 'nkn,nel    : ',nkn,nel
        write(6,*) 'nlv        : ',nlv
        write(6,*) 'title      : ',title
        write(6,*) 'femver     : ',femver
        write(6,*) 'date,time  : ',date,time
        write(6,*) 'href,hzmin : ',href,hzmin

        call ous_read_header2(iu,ilhv,hlv,hev,ierr)
        if( ierr .ne. 0 ) goto 99

        write(6,*) 'Available levels: ',nlv
        write(6,*) (hlv(l),l=1,nlv)

        return
   99   continue
        write(6,*) 'error in reading header of OUS file'
        stop 'error stop read_ous_header: reading header'
        end

c***************************************************************
c***************************************************************
c***************************************************************

        subroutine open_ous_type(type,status,nunit)

c open OUS file with default simulation name and given extension

        implicit none

        character*(*) type,status
        integer nunit

        integer nb
        character*80 file

        integer ifileo

        call def_make(type,file)
        nb = ifileo(0,file,'unform',status)

        if( nb .le. 0 ) then
          write(6,*) 'file: ',file
          stop 'error stop open_ous_type: opening file'
        end if

        nunit = nb

        end

c***************************************************************

        subroutine open_ous_file(name,status,nunit)

        implicit none

        character*(*) name,status
        integer nunit

        integer nb
        character*80 file

        integer ifileo

        call mkname(' ',name,'.ous',file)
        nb = ifileo(0,file,'unform',status)
        if( nb .le. 0 ) then
	  write(6,*) 'file: ',file
	  stop 'error stop open_ous_file: opening file'
	end if

        nunit = nb

        end

c***************************************************************

        subroutine qopen_ous_file(text,status,nunit)

c asks for name and opens ous file

        implicit none

        character*(*) text,status
        integer nunit

        character*80 name

        write(6,*) text
        read(5,'(a)') name
        write(6,*) name

        call open_ous_file(name,status,nunit)

        end

c***************************************************************
c***************************************************************
c***************************************************************

        subroutine ous_get_it_start(file,itstart)

c gets it of first record

        implicit none

        character*(*) file
        integer itstart

        integer nunit,nvers
        integer it,ierr
        character*80 title

        nvers = 2
        itstart = -1

        call open_ous_file(file,'old',nunit)
        call ous_init(nunit,nvers)
        call ous_skip_header(nunit,ierr)
        if( ierr .ne. 0 ) return
        call ous_skip_record(nunit,it,ierr)
        if( ierr .ne. 0 ) return
        itstart = it

        end

c***************************************************************

        subroutine ous_get_it_end(file,itend)

c gets it of last record

        implicit none

        character*(*) file
        integer itend

        integer nunit,nvers
        integer it,itlast,ierr
        character*80 title

        nvers = 2
        itend = -1
        itlast = -1

        call open_ous_file(file,'old',nunit)
        call ous_init(nunit,nvers)
        call ous_skip_header(nunit,ierr)
        if( ierr .ne. 0 ) return

    1   continue
        call ous_skip_record(nunit,it,ierr)
        if( ierr .gt. 0 ) return
        if( ierr .lt. 0 ) goto 2
        itlast = it
        goto 1
    2   continue
        itend = itlast

        end

c***************************************************************

        function check_ous_file(file)

        implicit none

        logical check_ous_file
        character*(*) file

        integer nb,nvers
        integer ifileo

        check_ous_file = .false.

        nb = ifileo(0,file,'unform','old')
        if( nb .le. 0 ) return
        call ous_is_ous_file(nb,nvers)
        close(nb)

        check_ous_file = nvers > 0
        
        end

c***************************************************************

