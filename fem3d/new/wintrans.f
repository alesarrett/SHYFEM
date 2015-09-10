
	program wintrans

	implicit none

	integer nkndim
	parameter (nkndim=50000)

	real wx(nkndim)
	real wy(nkndim)
	real p(nkndim)

	integer it,nkn
	integer i,ibyte,irecl,nrec

	ibyte = 4
	nrec = 0

	do i=1,nkndim
	  p(i) = 0.
	end do

	open(1,file='wind.win',status='old',form='unformatted')

    1	continue

          read(1,end=2) it,nkn
	  nrec = nrec + 1
	  irecl = ibyte*(2+3*nkn)
	  write(6,*) it,nkn,nrec,irecl

	  if( nrec .eq. 1 ) then
	    open(2,file='windout.win',status='unknown',form='unformatted'
     +		,access='direct',recl=irecl)
	  end if


	  if( nkn .gt. 0 ) then
            read(1) (wx(i),wy(i),i=1,nkn)
	  else
	    nkn = -nkn
            read(1) (wx(i),wy(i),i=1,nkn),(p(i),i=1,nkn)
	  end if

	  write(2,rec=nrec) it,nkn,(wx(i),wy(i),i=1,nkn),(p(i),i=1,nkn)

	  goto 1
    2	continue

	close(1)
	close(2)

	call test_wind(irecl,nkndim,wx,wy,p)

	end

c*******************************************************************

	subroutine test_wind(irecl,nkndim,wx,wy,p)

	implicit none

	integer irecl,nkndim
	real wx(nkndim)
	real wy(nkndim)
	real p(nkndim)

	integer i,nkn,it

	write(6,*) 're-reading direct file...'

	open(2,file='windout.win',status='old',form='unformatted'
     +          ,access='direct',recl=irecl)

	read(2,rec=5) it,nkn,(wx(i),wy(i),i=1,nkn),(p(i),i=1,nkn)
	write(6,*) it,nkn

	read(2,rec=9) it,nkn,(wx(i),wy(i),i=1,nkn),(p(i),i=1,nkn)
	write(6,*) it,nkn

	close(2)

	end
	 
c*******************************************************************

