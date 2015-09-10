c
c $Id: subcoo.f,v 1.3 2009-03-31 15:37:07 georg Exp $
c
c generic coo and csr handling routines
c
c revision log :
c
c 31.01.2009    ggu     cleaned, only generic coo routines here
c 29.03.2012    ggu     in loccoo avoid call to coo_find (speed)
c
!******************************************************************

	subroutine coo_init(nnel,nnkn,mmbw,nnen3v,ndim,nnot0,iijp,ip,jp)

! construct pointers for co matrix

	use mod_system

	implicit none
	include 'param.h'

	integer nnel,nnkn,mmbw		!size of elements, nodes, bandwidth
	integer nnen3v(3,1)		!element index
	integer ndim			!dimension of arrays ip, jp (non zero)
	integer nnot0			!number of non 0 elements (return)
	integer iijp(-mmbw:mmbw,nnkn)	!index pointer into matrix (return)
	integer ip(ndim)		!row index of non zero element (return)
	integer jp(ndim)		!col index of non zero element (return)

	integer k,m,n,ie,ii,ii1,k1,k2

	do k=1,nnkn
	  do m=-mmbw,mmbw
	    iijp(m,k) = 0
	  end do
	end do

	n = 0

	do ie=1,nnel
	  do ii=1,3
	    k1 = nnen3v(ii,ie)
	    ii1 = mod(ii,3) + 1
	    k2 = nnen3v(ii1,ie)
	    call coo_init_insert(k1,k2,nnkn,mmbw,iijp,n)	!out of diagonal
	    call coo_init_insert(k1,k1,nnkn,mmbw,iijp,n)	!in diagonal
	  end do
	end do

	if( n .gt. ndim) goto 99

	nnot0 = n

	do k=1,nnkn
	  do m=-mmbw,mmbw
	    n = iijp(m,k)
	    jp(n) = k
	    ip(n) = k + m
	  end do
	end do

	!call coo_debug(nnkn,mmbw,iijp)
	call coo_check(nnkn,mmbw,iijp,ip,jp)

	return
   99	continue
	write(6,*) 'nnot0,ndim: ',nnot0,ndim
	stop 'error stop coo_init: ndim'
	end

!******************************************************************

	subroutine coo_find(i,j,mmbw,iijp,n)

! finds position of non zero element in arrays

	implicit none

	integer i,j			!row and col
	integer mmbw
	integer iijp(-mmbw:mmbw,1)
	integer n			!position

	n = iijp(i-j,j)

	end

!******************************************************************

	subroutine coo_debug(nnkn,mmbw,iijp)

! checks sanity of iijp, ip, jp arrays

	implicit none

	integer nnkn,mmbw
	integer iijp(-mmbw:mmbw,1)

	integer k,m,n,nn,nmax

	n = 0
	nn = 0
	nmax = 0

	do k=1,nnkn
	  do m=-mmbw,mmbw
	    n = iijp(m,k)
	    nmax = max(n,nmax)
	    if( n .gt. 0 ) then
		    nn = nn + 1
	    	    !write(6,*) 'ggg: ',m,k,n
		    if( iijp(-m,k+m) .eq. 0 ) then !check symmetric element
			    write(6,*) m,k,nn,n,iijp(-m,k+m)
			    stop 'error stop coo_debug: internal error (7)'
		    end if
	    end if
	  end do
	end do

	if( nn .ne. nmax ) then
		write(6,*) 'coo_debug: ',nmax,nn
		stop 'error stop coo_debug: nn /= nmax'
	end if

	write(6,*) 'coo_debug: ',nmax,nn

	end

!******************************************************************

	subroutine coo_check(nnkn,mmbw,iijp,ip,jp)

! checks sanity of iijp, ip, jp arrays

	implicit none

	integer nnkn,mmbw
	integer iijp(-mmbw:mmbw,1)
	integer ip(1)
	integer jp(1)

	integer i,j,k,m,n
	integer n0
	logical debug

	debug = .true.
	n0 = 0
	n = 0
	j = 0
	i = 0

	do k=1,nnkn
	  do m=-mmbw,mmbw
	    n = iijp(m,k)
	    if( n .gt. 0 ) then
	      n0 = n0 + 1
	      j = k
	      i = j + m
	      if( ip(n) .ne. i ) goto 99
	      if( jp(n) .ne. j ) goto 99
	    end if
	  end do
	end do

	if( debug ) then
	  write(6,*) 'coo routine setup:'
	  write(6,*) '  non zeros   = ',n0
	  write(6,*) '  real band   = ',nnkn + mmbw * (2*nnkn-mmbw-1)
	  write(6,*) '  full band   = ',(1+2*mmbw) * nnkn
	  write(6,*) '  full matrix = ',nnkn*nnkn
	end if

	return
   99	continue
	write(6,*) n,k,m
	write(6,*) i,ip(n)
	write(6,*) j,jp(n)
	stop 'error stop coo_check: internal error'
	end

!******************************************************************

	subroutine coo_init_insert(k1,k2,nnkn,mmbw,ip,n)

! internal routine for insertion of non 0 elements

	use mod_system

	implicit none
	include 'param.h'

	integer k1,k2,n,nnkn,mmbw
	integer ip(-mmbw:mmbw,nnkn)

	integer idk    
	integer ip1,ip2

	idk = k1 - k2

	if( idk .ne. 0 ) then		!out of diagonal
	  ip1 = ip(idk,k2)
	  ip2 = ip(-idk,k2+idk)
	  !write(6,*) k1,k2,idk,n
	  if( ip1 .ne. 0 .and. ip2 .ne. 0 ) then	!already inserted
	    return
	  else if( ip1 .eq. 0 .and. ip2 .eq. 0 ) then	!must insert
	    ip(idk,k2) = n + 1
	    ip(-idk,k2+idk) = n + 2
	    n = n + 2
	  else						!not possible
	    write(6,*) k1,k2,idk,n
	    write(6,*) 'internal error: ',ip1,ip2
	    stop 'error stop coo_insert: internal error (1)'
	  end if
	else				!on diagonal
	  !write(6,*) k1,k2,idk,n
	  ip1 = ip(0,k1)
	  if( ip1 .eq. 0 ) then
	    n = n + 1
	    ip(0,k1) = n
	  end if
	end if

	end
	  
!******************************************************************

	function loccoo(i,j,nnkn,mmbw)

c localize for COO routines

	use mod_system

	implicit none
	include 'param.h'

	integer loccoo			!position
	integer i,j			!row and col
	integer nnkn			!size of system
	integer mmbw			!bandwidth

	integer ip,loccoo1

	!loccoo = ijp(i-j,j)
	ip = j*(2*mmbw+1)+i-j-mmbw
	!ip = j*(2*mmbw)+i-mmbw
	loccoo=ijp(ip)

	!call coo_find(i,j,mmbw,ijp,loccoo1)

	!if( loccoo .ne. loccoo1) then
	!  write(6,*) 'loccoo...',i,j,mmbw,loccoo,loccoo1
	!  stop 'error stop loccoo'
	!end if

	end

!******************************************************************

!----------------------------------------------------------------------- 
      subroutine cooclr(co,ico,jco,iijp,ndim,mmbw,nnkn,nnz)
!----------------------------------------------------------------------- 
! NOT USED
! Clear the co matrix of the zeros inside the band of the original matrix.
! and corrects the nnz value.
! Input:
! co,ico,jco,iijp,ndim,mmbw,nnkn,nnz
! Output overwritten:
! co,ico,jco,iijp,nnz
      implicit none
      integer ndim
      integer nnkn,mmbw
      integer nnz
      real*8 co(ndim),coon(ndim)
      integer ico(ndim),jco(ndim)
      integer icoon(ndim),jcoon(ndim)
      integer iijp(-mmbw:mmbw,nnkn)
      integer n,m,k

      k=0
      do n=1,nnkn
         do m=-mmbw,mmbw
            if( co(iijp(m,n)).ne.0 ) then
		    k=k+1
		    coon(k)=co(iijp(m,n))
		    icoon(k)=ico(iijp(m,n))
		    jcoon(k)=jco(iijp(m,n))
		    iijp(m,n)=k
	    else
		    iijp(m,n)=0
	    end if
	 end do
      end do

      do n=1,nnz
         co(n)=coon(n)
	 ico(n)=icoon(n)
	 jco(n)=jcoon(n)
      end do

      nnz=k

      end

!----------------------------------------------------------------------- 
      subroutine srtcsr(nnz,n,a,ja,ia,iwork)
!-----------------------------------------------------------------------
! Sort the csr matrix in ascending column order
      implicit none
      integer n, nnz, ja(*), ia(n+1)
      real*8 a(*)
      integer iwork(*)

      call csort (n,a,ja,ia,iwork,.true.)
      end


!-----------------------------------------------------------------------
!     CSR routines from SPARSKIT2 (vers. 2005)
!-----------------------------------------------------------------------
!----------------------------------------------------------------------- 
      subroutine coocsr(nrow,nnz,a,ir,jc,ao,jao,iao)
!----------------------------------------------------------------------- 
      real*8 a(*),ao(*),x
      integer ir(*),jc(*),jao(*),iao(*)
!-----------------------------------------------------------------------
!  Coordinate     to   Compressed Sparse Row 
!----------------------------------------------------------------------- 
! converts a matrix that is stored in coordinate format
!  a, ir, jc into a row general sparse ao, jao, iao format.
!
! on entry:
!--------- 
! nrow	= dimension of the matrix 
! nnz	= number of nonzero elements in matrix
! a,
! ir, 
! jc    = matrix in coordinate format. a(k), ir(k), jc(k) store the nnz
!         nonzero elements of the matrix with a(k) = actual real value of
! 	  the elements, ir(k) = its row number and jc(k) = its column 
!	  number. The order of the elements is arbitrary. 
!
! on return:
!----------- 
! ir 	is destroyed    ! not true!!
!
! ao, jao, iao = matrix in general sparse matrix format with ao 
! 	continung the real values, jao containing the column indices, 
!	and iao being the pointer to the beginning of the row, 
!	in arrays ao, jao.
!
! Notes:
!------ This routine is NOT in place.  See coicsr
!
!------------------------------------------------------------------------
      do 1 k=1,nrow+1
         iao(k) = 0
 1    continue
! determine row-lengths.
      do 2 k=1, nnz
         iao(ir(k)) = iao(ir(k))+1
 2    continue
! starting position of each row..
      k = 1
      do 3 j=1,nrow+1
         k0 = iao(j)
         iao(j) = k
         k = k+k0
 3    continue
! go through the structure  once more. Fill in output matrix.
      do 4 k=1, nnz
         i = ir(k)
         j = jc(k)
         x = a(k)
         iad = iao(i)
         ao(iad) =  x
         jao(iad) = j
         iao(i) = iad+1
 4    continue
! shift back iao
      do 5 j=nrow,1,-1
         iao(j+1) = iao(j)
 5    continue
      iao(1) = 1
      return
!------------- end of coocsr ------------------------------------------- 
!----------------------------------------------------------------------- 
      end

!-----------------------------------------------------------------------
      subroutine clncsr(job,value2,nrow,a,ja,ia,indu,iwk)
!-----------------------------------------------------------------------
!     .. Scalar Arguments ..
      integer job, nrow, value2
!     ..
!     .. Array Arguments ..
      integer ia(nrow+1),indu(nrow),iwk(nrow+1),ja(*)
      real*8  a(*)
!     ..
!
!     This routine performs two tasks to clean up a CSR matrix
!     -- remove duplicate/zero entries,
!     -- perform a partial ordering, new order lower triangular part,
!        main diagonal, upper triangular part.
!
!     On entry:
!
!     job   = options
!         0 -- nothing is done
!         1 -- eliminate duplicate entries, zero entries.
!         2 -- eliminate duplicate entries and perform partial ordering.
!         3 -- eliminate duplicate entries, sort the entries in the
!              increasing order of column indices.
!
!     value2  -- 0 the matrix is pattern only (a is not touched)
!                1 matrix has values too.
!     nrow    -- row dimension of the matrix
!     a,ja,ia -- input matrix in CSR format
!
!     On return:
!     a,ja,ia -- cleaned matrix
!     indu    -- pointers to the beginning of the upper triangular
!                portion if job > 1
!
!     Work space:
!     iwk     -- integer work space of size nrow+1
!
!     .. Local Scalars ..
      integer i,j,k,ko,ipos,kfirst,klast
      real*8  tmp
!     ..
!
      if (job.le.0) return
!
!     .. eliminate duplicate entries --
!     array INDU is used as marker for existing indices, it is also the
!     location of the entry.
!     IWK is used to stored the old IA array.
!     matrix is copied to squeeze out the space taken by the duplicated
!     entries.
!
      do 90 i = 1, nrow
         indu(i) = 0
         iwk(i) = ia(i)
 90   continue
      iwk(nrow+1) = ia(nrow+1)
      k = 1
      do 120 i = 1, nrow
         ia(i) = k
         ipos = iwk(i)
         klast = iwk(i+1)
 100     if (ipos.lt.klast) then
            j = ja(ipos)
            if (indu(j).eq.0) then
!     .. new entry ..
               if (value2.ne.0) then
                  if (a(ipos) .ne. 0.0D0) then
                     indu(j) = k
                     ja(k) = ja(ipos)
                     a(k) = a(ipos)
                     k = k + 1
                  endif
               else
                  indu(j) = k
                  ja(k) = ja(ipos)
                  k = k + 1
               endif
            else if (value2.ne.0) then
!     .. duplicate entry ..
               a(indu(j)) = a(indu(j)) + a(ipos)
            endif
            ipos = ipos + 1
            go to 100
         endif
!     .. remove marks before working on the next row ..
         do 110 ipos = ia(i), k - 1
            indu(ja(ipos)) = 0
 110     continue
 120  continue
      ia(nrow+1) = k
      if (job.le.1) return
!
!     .. partial ordering ..
!     split the matrix into strict upper/lower triangular
!     parts, INDU points to the the beginning of the upper part.
!
      do 140 i = 1, nrow
         klast = ia(i+1) - 1
         kfirst = ia(i)
 130     if (klast.gt.kfirst) then
            if (ja(klast).lt.i .and. ja(kfirst).ge.i) then
!              ... swap klast with kfirst ..
               j = ja(klast)
               ja(klast) = ja(kfirst)
               ja(kfirst) = j
               if (value2.ne.0) then
                  tmp = a(klast)
                  a(klast) = a(kfirst)
                  a(kfirst) = tmp
               endif
            endif
            if (ja(klast).ge.i)
     &         klast = klast - 1
            if (ja(kfirst).lt.i)
     &         kfirst = kfirst + 1
            go to 130
         endif
         if (ja(klast).lt.i) then
            indu(i) = klast + 1
         else
            indu(i) = klast
         endif
 140  continue
      if (job.le.2) return
!
!     .. order the entries according to column indices
!     burble-sort is used
!
      do 190 i = 1, nrow
         do 160 ipos = ia(i), indu(i)-1
            do 150 j = indu(i)-1, ipos+1, -1
               k = j - 1
               if (ja(k).gt.ja(j)) then
                  ko = ja(k)
                  ja(k) = ja(j)
                  ja(j) = ko
                  if (value2.ne.0) then
                     tmp = a(k)
                     a(k) = a(j)
                     a(j) = tmp
                  endif
               endif
 150        continue
 160     continue
         do 180 ipos = indu(i), ia(i+1)-1
            do 170 j = ia(i+1)-1, ipos+1, -1
               k = j - 1
               if (ja(k).gt.ja(j)) then
                  ko = ja(k)
                  ja(k) = ja(j)
                  ja(j) = ko
                  if (value2.ne.0) then
                     tmp = a(k)
                     a(k) = a(j)
                     a(j) = tmp
                  endif
               endif
 170        continue
 180     continue
 190  continue
      return
!---- end of clncsr ----------------------------------------------------
!-----------------------------------------------------------------------
      end


!-----------------------------------------------------------------------
      subroutine csort (n,a,ja,ia,iwork,values) 
!-----------------------------------------------------------------------
      logical values
      integer n, ja(*), ia(n+1), iwork(*) 
      real*8 a(*) 
!-----------------------------------------------------------------------
! This routine sorts the elements of  a matrix (stored in Compressed
! Sparse Row Format) in increasing order of their column indices within 
! each row. It uses a form of bucket sort with a cost of O(nnz) where
! nnz = number of nonzero elements. 
! requires an integer work array of length 2*nnz.  
!-----------------------------------------------------------------------
! on entry:
!--------- 
! n     = the row dimension of the matrix
! a     = the matrix A in compressed sparse row format.
! ja    = the array of column indices of the elements in array a.
! ia    = the array of pointers to the rows. 
! iwork = integer work array of length max ( n+1, 2*nnz ) 
!         where nnz = (ia(n+1)-ia(1))  ) .
! values= logical indicating whether or not the real values a(*) must 
!         also be permuted. if (.not. values) then the array a is not
!         touched by csort and can be a dummy array. 
! 
! on return:
!----------
! the matrix stored in the structure a, ja, ia is permuted in such a
! way that the column indices are in increasing order within each row.
! iwork(1:nnz) contains the permutation used  to rearrange the elements.
!----------------------------------------------------------------------- 
! Y. Saad - Feb. 1, 1991.
!-----------------------------------------------------------------------
! local variables
      integer i, k, j, ifirst, nnz, next  
!
! count the number of elements in each column
!
      do 1 i=1,n+1
         iwork(i) = 0
 1    continue
      do 3 i=1, n
         do 2 k=ia(i), ia(i+1)-1 
            j = ja(k)+1
            iwork(j) = iwork(j)+1
 2       continue 
 3    continue
!
! compute pointers from lengths. 
!
      iwork(1) = 1
      do 4 i=1,n
         iwork(i+1) = iwork(i) + iwork(i+1)
 4    continue
! 
! get the positions of the nonzero elements in order of columns.
!
      ifirst = ia(1) 
      nnz = ia(n+1)-ifirst
      do 5 i=1,n
         do 51 k=ia(i),ia(i+1)-1 
            j = ja(k) 
            next = iwork(j) 
            iwork(nnz+next) = k
            iwork(j) = next+1
 51      continue
 5    continue
!
! convert to coordinate format
! 
      do 6 i=1, n
         do 61 k=ia(i), ia(i+1)-1 
            iwork(k) = i
 61      continue
 6    continue
!
! loop to find permutation: for each element find the correct 
! position in (sorted) arrays a, ja. Record this in iwork. 
! 
      do 7 k=1, nnz
         ko = iwork(nnz+k) 
         irow = iwork(ko)
         next = ia(irow)
!
! the current element should go in next position in row. iwork
! records this position. 
! 
         iwork(ko) = next
         ia(irow)  = next+1
 7       continue
!
! perform an in-place permutation of the  arrays.
! 
         call ivperm (nnz, ja(ifirst), iwork) 
         if (values) call dvperm (nnz, a(ifirst), iwork) 
!
! reshift the pointers of the original matrix back.
! 
      do 8 i=n,1,-1
         ia(i+1) = ia(i)
 8    continue
      ia(1) = ifirst 
!
      return 
!---------------end-of-csort-------------------------------------------- 
!-----------------------------------------------------------------------
      end

      
      subroutine dvperm (n, x, perm) 
      integer n, perm(n) 
      real*8 x(n)
!-----------------------------------------------------------------------
! this subroutine performs an in-place permutation of a real vector x 
! according to the permutation array perm(*), i.e., on return, 
! the vector x satisfies,
!
!	x(perm(j)) :== x(j), j=1,2,.., n
!
!-----------------------------------------------------------------------
! on entry:
!---------
! n 	= length of vector x.
! perm 	= integer array of length n containing the permutation  array.
! x	= input vector
!
! on return:
!---------- 
! x	= vector x permuted according to x(perm(*)) :=  x(*)
!
!----------------------------------------------------------------------c
!           Y. Saad, Sep. 21 1989                                      c
!----------------------------------------------------------------------c
! local variables 
      real*8 tmp, tmp1
!
      init      = 1
      tmp	= x(init)	
      ii        = perm(init)
      perm(init)= -perm(init)
      k         = 0
!     
! loop
! 
 6    k = k+1
!
! save the chased element --
! 
      tmp1	  = x(ii) 
      x(ii)     = tmp
      next	  = perm(ii) 
      if (next .lt. 0 ) goto 65
!     
! test for end 
!
      if (k .gt. n) goto 101
      tmp       = tmp1
      perm(ii)  = - perm(ii)
      ii        = next 
!
! end loop 
!
      goto 6
!
! reinitilaize cycle --
!
 65   init      = init+1
      if (init .gt. n) goto 101
      if (perm(init) .lt. 0) goto 65
      tmp	= x(init)
      ii	= perm(init)
      perm(init)=-perm(init)
      goto 6
!     
 101  continue
      do 200 j=1, n
         perm(j) = -perm(j)
 200  continue 
!     
      return
!-------------------end-of-dvperm--------------------------------------- 
!-----------------------------------------------------------------------
      end

!-----------------------------------------------------------------------
      subroutine ivperm (n, ix, perm) 
      integer n, perm(n), ix(n)
!-----------------------------------------------------------------------
! this subroutine performs an in-place permutation of an integer vector 
! ix according to the permutation array perm(*), i.e., on return, 
! the vector x satisfies,
!
!	ix(perm(j)) :== ix(j), j=1,2,.., n
!
!-----------------------------------------------------------------------
! on entry:
!---------
! n 	= length of vector x.
! perm 	= integer array of length n containing the permutation  array.
! ix	= input vector
!
! on return:
!---------- 
! ix	= vector x permuted according to ix(perm(*)) :=  ix(*)
!
!----------------------------------------------------------------------c
!           Y. Saad, Sep. 21 1989                                      c
!----------------------------------------------------------------------c
! local variables
      integer tmp, tmp1
!
      init      = 1
      tmp	= ix(init)	
      ii        = perm(init)
      perm(init)= -perm(init)
      k         = 0
!     
! loop
! 
 6    k = k+1
!
! save the chased element --
! 
      tmp1	  = ix(ii) 
      ix(ii)     = tmp
      next	  = perm(ii) 
      if (next .lt. 0 ) goto 65
!     
! test for end 
!
      if (k .gt. n) goto 101
      tmp       = tmp1
      perm(ii)  = - perm(ii)
      ii        = next 
!
! end loop 
!
      goto 6
!
! reinitilaize cycle --
!
 65   init      = init+1
      if (init .gt. n) goto 101
      if (perm(init) .lt. 0) goto 65
      tmp	= ix(init)
      ii	= perm(init)
      perm(init)=-perm(init)
      goto 6
!     
 101  continue
      do 200 j=1, n
         perm(j) = -perm(j)
 200  continue 
!     
      return
!-------------------end-of-ivperm--------------------------------------- 
!-----------------------------------------------------------------------
      end


!----------------------------------------------------------------------- 
      subroutine check_csr(nnkn,nnz,a1,ia1,ja1,a2,ia2,ja2)
!----------------------------------------------------------------------- 
! Compare two csr matrices and finds the differences
      implicit none
      integer nnkn,nnz
      real*8 a1(*),a2(*)
      integer ia1(nnkn+1),ia2(nnkn+1)
      integer ja1(*),ja2(*)
      integer nn
      integer na,ni,nj

      na=0
      nj=0
      do nn=1,nnz
         if (a1(nn).ne.a2(nn)) then
		 print*, 'a1  a2: ',a1(nn),a2(nn)
		 na=na+1
	 end if
         if (ja1(nn).ne.ja2(nn)) then
		 print*, 'ja1  ja2: ',ja1(nn),ja2(nn)
		 nj=nj+1
	 end if
      end do
      ni=0
      do nn=1,nnkn+1
         if (ia1(nn).ne.ia2(nn)) then
		 print*, 'ia1  ia2: ',ia1(nn),ia2(nn)
		 ni=ni+1
	 end if
      end do
      if ((na.ne.0).or.(nj.ne.0).or.(ni.ne.0)) then
	      print*, 'na,nj,ni:  ',na,nj,ni
	      stop
      end if
      end

!-----------------------------------------------------------------------
      subroutine bndcsr (n,abd,nabd,lowd,ml,mu,a,ja,ia,len,ierr)
      real*8 a(*),abd(nabd,*), t
      integer ia(n+1),ja(*)
!----------------------------------------------------------------------- 
! Banded (Linpack ) format   to    Compressed Sparse Row  format.
!----------------------------------------------------------------------- 
! on entry:
!----------
! n	= integer,the actual row dimension of the matrix.
!
! nabd  = first dimension of array abd.
!
! abd   = real array containing the values of the matrix stored in
!         banded form. The j-th column of abd contains the elements
!         of the j-th column of  the original matrix,comprised in the
!         band ( i in (j-ml,j+mu) ) with the lowest diagonal located
!         in row lowd (see below). 
!    
! lowd  = integer. this should be set to the row number in abd where
!         the lowest diagonal (leftmost) of A is located. 
!         lowd should be s.t.  ( 1  .le.  lowd  .le. nabd).
!         The subroutines dgbco, ... of linpack use lowd=2*ml+mu+1.
!
! ml	= integer. equal to the bandwidth of the strict lower part of A
! mu	= integer. equal to the bandwidth of the strict upper part of A
!         thus the total bandwidth of A is ml+mu+1.
!         if ml+mu+1 is found to be larger than nabd then an error 
!         message is set. see ierr.
!
! len   = integer. length of arrays a and ja. bndcsr will stop if the
!         length of the arrays a and ja is insufficient to store the 
!         matrix. see ierr.
!
! on return:
!-----------
! a,       !value (real*8)
! ja,      !index (integer)
! ia    = input matrix stored in compressed sparse row format. !pointer (integer)
!
! lowd  = if on entry lowd was zero then lowd is reset to the default
!         value ml+mu+l. 
!
! ierr  = integer. used for error message output. 
!         ierr .eq. 0 :means normal return
!         ierr .eq. -1 : means invalid value for lowd. 
!	  ierr .gt. 0 : means that there was not enough storage in a and ja
!         for storing the ourput matrix. The process ran out of space 
!         (as indicated by len) while trying to fill row number ierr. 
!         This should give an idea of much more storage might be required. 
!         Moreover, the first irow-1 rows are correctly filled. 
!
! notes:  the values in abd found to be equal to zero
! -----   (actual test: if (abd(...) .eq. 0.0d0) are removed.
!         The resulting may not be identical to a csr matrix
!         originally transformed to a bnd format.
!          
!----------------------------------------------------------------------- 
      ierr = 0
!-----------
      if (lowd .gt. nabd .or. lowd .le. 0) then 
         ierr = -1
         return
      endif
!-----------
      ko = 1
      ia(1) = 1
      do 30 irow=1,n
!-----------------------------------------------------------------------
         i = lowd 
          do  20 j=irow-ml,irow+mu
             if (j .le. 0 ) goto 19
             if (j .gt. n) goto 21
             t = abd(i,j) 
             if (t .eq. 0.0d0) goto 19
             if (ko .gt. len) then 
               ierr = irow 
               return
            endif
            a(ko) = t
            ja(ko) = j
            ko = ko+1
 19         i = i-1
 20      continue
!     end for row irow
 21      ia(irow+1) = ko
 30   continue
      return
!------------- end of bndcsr ------------------------------------------- 
!----------------------------------------------------------------------- 
      end

c*************************************************************************

