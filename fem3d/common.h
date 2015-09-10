
!---------------------------------------------------------------------
! include file for pardiso solver
!---------------------------------------------------------------------

	!include 'param.h'
	!include 'nkonst.h'

!---------------------------------------------------------------------
! parameters
!---------------------------------------------------------------------

! next sets precision for iterative solver
!
! use 61 91 121 etc..  61 indicates 10E-6 of precision etc..
! best choice is 121 for iterative
! use 0 for direct solver - this should be a save choice if in doubt

        integer iprec
        parameter ( iprec = 0 )
        !parameter ( iprec = 61 )
        !parameter ( iprec = 91 )
        !parameter ( iprec = 121 )

!---------------------------------------------------------------------
! do not change anything beyond this point
!---------------------------------------------------------------------

        integer csrdim
        parameter ( csrdim = 9 * neldim )

	integer matdim
	parameter (matdim=nkndim*(1+3*mbwdim))

!---------------------------------------------------------------------
! common of shyfem
!---------------------------------------------------------------------

        double precision vs1v(nkndim),vs2v(nkndim),vs3v(nkndim)
	integer is2v(nkndim)
        common /vs1v/vs1v, /vs2v/vs2v, /vs3v/vs3v, /is2v/is2v
	save /vs1v/,/vs2v/,/vs3v/,/is2v/

!---------------------------------------------------------------------
! new arrays
!---------------------------------------------------------------------

        double precision coo(csrdim)
        integer icoo(csrdim),jcoo(csrdim)
        !integer ijp(-mbwdim:mbwdim,nkndim)
        integer ijp((2*mbwdim+1)*nkndim)

        common /coo/coo, /icoo/icoo, /jcoo/jcoo, /ijp/ijp

        double precision rvec(nkndim)
        double precision raux(nkndim)

        common /rvec/rvec
        common /raux/raux

        integer nnzero
        common /nnzero/nnzero

	save /coo/, /icoo/, /jcoo/, /ijp/
	save /rvec/, /raux/
	save /nnzero/

!---------------------------------------------------------------------
! end of include
!---------------------------------------------------------------------

