
!==================================================================
	module mod_hydro
!==================================================================

	implicit none

        !real zov(nkndim), znv(nkndim)
        !common /zov/zov, /znv/znv
        !real zeov(3,neldim), zenv(3,neldim)       !$$ZEONV
        !common /zeov/zeov, /zenv/zenv
        !save /zov/,/znv/,/zeov/,/zenv/
        !real utlov(nlvdim,neldim)
        !common /utlov/utlov
        !real utlnv(nlvdim,neldim)
        !common /utlnv/utlnv
        !real vtlov(nlvdim,neldim)
        !common /vtlov/vtlov
        !real vtlnv(nlvdim,neldim)
        !common /vtlnv/vtlnv
        !save /utlov/,/utlnv/,/vtlov/,/vtlnv/

	integer, private, save :: nkn_hydro = 0
	integer, private, save :: nel_hydro = 0
	integer, private, save :: nlv_hydro = 0

	real, allocatable, save :: zov(:), znv(:)
	real, allocatable, save :: zeov(:,:), zenv(:,:)
	real, allocatable, save :: utlov(:,:)
	real, allocatable, save :: utlnv(:,:)
	real, allocatable, save :: vtlov(:,:)
	real, allocatable, save :: vtlnv(:,:)

!==================================================================
	contains
!==================================================================

        subroutine mod_hydro_init(nkn,nel,nlv)
        
        integer nkn, nel, nlv
        
        if( nkn == nkn_hydro .and. nel == nel_hydro .and.
     +      nlv == nlv_hydro ) return

        if( nel > 0 .or. nkn > 0 .or. nlv > 0 ) then
          if( nel == 0 .or. nkn == 0 .or. nlv == 0 ) then
            write(6,*) 'nel,nkn,nlv: ',nel,nkn,nlv
            stop 'error stop mod_hydro_init: incompatible parameters'
          end if
        end if

        if( nkn_hydro > 0 ) then
          deallocate(zov)
          deallocate(znv)
        
          deallocate(zeov)
          deallocate(zenv)

          deallocate(utlov)
          deallocate(utlnv)
          deallocate(vtlov)
          deallocate(vtlnv)
        end if

        nkn_hydro = nkn
        nel_hydro = nel
        nlv_hydro = nlv

        if( nkn == 0 ) return

        allocate(zov(nkn))
        allocate(znv(nkn))

        allocate(zeov(3,nel))
        allocate(zenv(3,nel))

        allocate(utlov(nlv,nel))
        allocate(utlnv(nlv,nel))
        allocate(vtlov(nlv,nel))
        allocate(vtlnv(nlv,nel))

        end subroutine mod_hydro_init

!==================================================================
        end module mod_hydro
!==================================================================

