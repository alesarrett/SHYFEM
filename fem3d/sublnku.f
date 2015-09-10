c
c $Id: sublnku.f,v 1.7 2009-09-14 08:20:58 georg Exp $
c
c topological set up routines
c
c contents :
c
c function kthis(i,ie)	        gets node at position i in ie
c function knext(k,ie) 	        gets node after k in ie
c function kbhnd(k,ie)          gets node before k in ie
c function ithis(k,ie) 	        gets i of k in ie
c function inext(k,ie) 	        gets i after k in ie
c function ibhnd(k,ie)	        gets i before k in ie
c
c subroutine link_fill(n)       returns filling of linkv
c
c subroutine get_elem_linkp(k,ipf,ipl)	gets pointer to elements around k
c subroutine get_node_linkp(k,ipf,ipl)	gets pointer to nodes around k
c subroutine get_elem_links(k,n,ibase)	gets pointer to elements around k
c subroutine get_node_links(k,n,ibase)	gets pointer to nodes around k
c subroutine set_elem_links(k,n)	copies elements around k to lnk_elems
c subroutine set_node_links(k,n)	copies nodes around k to lnk_nodes
c subroutine get_elems_around(k,ndim,n,elems) returns all elems around node k
c subroutine get_nodes_around(k,ndim,n,nodes) returns all nodes around node k
c
c subroutine find_elems_to_segment(k1,k2,ie1,ie2) finds elements to segment
c
c revision log :
c
c 01.08.2003	ggu	created from sublnk.f
c 16.03.2004	ggu	new routine node_links() and link_fill()
c 10.11.2007	ggu	new routine line_elems
c 28.08.2009	ggu	routine line_elems renamed to find_elems_to_segment
c 28.08.2009	ggu	new routines get_elems_around, get_nodes_around
c 09.09.2009	ggu	bug fix in find_elems_to_segment (BUGip2)
c 20.10.2011	ggu	check dimension in set_elem_links(), set_node_links()
c 16.12.2011	ggu	in lnk_elems at boundary set last value to 0
c
c****************************************************************

        function kthis(i,ie)

c gets node at position i in ie
c
c i     position
c ie    element

	use basin

        implicit none

c arguments
	integer kthis
        integer i,ie
c common
	include 'param.h'

	kthis = nen3v(i,ie)

	end

c****************************************************************
c
        function knext(k,ie)
c
c gets node after k in ie
c
c k     actual node
c ie    element
c
	use basin

        implicit none
c
c arguments
	integer knext
        integer k,ie
c common
	include 'param.h'
c local
        integer i
c
        do i=1,3
          if( nen3v(i,ie) .eq. k ) then
            knext=nen3v(mod(i,3)+1,ie)
            return
          end if
        end do
c
        knext=0
c
        return
        end
c
c****************************************************************
c
        function kbhnd(k,ie)
c
c gets node before k in ie
c
c k     actual node
c ie    element
c
	use basin

        implicit none
c
c arguments
	integer kbhnd
        integer k,ie
c common
	include 'param.h'
c local
        integer i
c
        do i=1,3
          if( nen3v(i,ie) .eq. k ) then
            kbhnd=nen3v(mod(i+1,3)+1,ie)
            return
          end if
        end do
c
        kbhnd=0
c
        return
        end
c
c****************************************************************
c
        function ithis(k,ie)
c
c gets i of k in ie
c
c k     actual node
c ie    element
c
	use basin

        implicit none
c
c arguments
	integer ithis
        integer k,ie
c common
	include 'param.h'
c local
        integer i
c
        do i=1,3
          if( nen3v(i,ie) .eq. k ) then
            ithis=i
            return
          end if
        end do
c
        ithis=0
c
        return
        end
c
c****************************************************************
c
        function inext(k,ie)
c
c gets i after k in ie
c
c k     actual node
c ie    element
c
	use basin

        implicit none
c
c arguments
	integer inext
        integer k,ie
c common
	include 'param.h'
c local
        integer i
c
        do i=1,3
          if( nen3v(i,ie) .eq. k ) then
            inext=mod(i,3)+1
            return
          end if
        end do
c
        inext=0
c
        return
        end
c
c****************************************************************
c
        function ibhnd(k,ie)
c
c gets i before k in ie
c
c k     actual node
c ie    element
c
	use basin

        implicit none
c
c arguments
	integer ibhnd
        integer k,ie
c common
	include 'param.h'
c local
        integer i
c
        do i=1,3
          if( nen3v(i,ie) .eq. k ) then
            ibhnd=mod(i+1,3)+1
            return
          end if
        end do
c
        ibhnd=0
c
        return
        end

c****************************************************************
c****************************************************************
c****************************************************************

        subroutine link_fill(n)

c returns filling of linkv

	use mod_geom
	use basin, only : nkn,nel,ngr,mbw

        implicit none

c arguments
        integer n       !filling of linkv (return)
c common
	include 'param.h'

        n = ilinkv(nkn+1)

        end

c****************************************************************
c****************************************************************
c****************************************************************

	subroutine get_elem_linkp(k,ipf,ipl)

c gets pointer to first and last element around k
c
c to loop over the neibor elements, use similar:
c
c       call get_elem_linkp(k,ipf,ipl)
c       do ip=ipf,ipl
c         ien = lenkv(ip)          !ien is number of neibor element
c       end do

	use mod_geom

	implicit none

	integer k,ipf,ipl

	include 'param.h'

        ipf = ilinkv(k)+1
        ipl = ilinkv(k+1)

	if( lenkv(ipl) .eq. 0 ) ipl = ipl - 1	!FIXME

	end

c****************************************************************

	subroutine get_node_linkp(k,ipf,ipl)

c gets pointer to first and last node around k
c
c to loop over the neibor nodes, use similar:
c
c       call get_node_linkp(k,ipf,ipl)
c       do ip=ipf,ipl
c         kn = linkv(ip)          !kn is number of neibor node
c       end do

	use mod_geom

	implicit none

	integer k,ipf,ipl

	include 'param.h'

        ipf = ilinkv(k)+1
        ipl = ilinkv(k+1)

	end

c****************************************************************

	subroutine get_elem_links(k,n,ibase)

c gets pointer and total number of elements around k
c
c to loop over the neibor elements, use similar:
c
c       call get_elem_links(k,n,ibase)
c       do i=1,n
c         ien = lenkv(ibase+i)          !ien is number of neibor element
c       end do

	use mod_geom

	implicit none

	integer k,n,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

	if( lenkv(ibase+n) .eq. 0 ) n = n - 1

        end

c****************************************************************

	subroutine get_node_links(k,n,ibase)

c gets pointer and total number of nodes around k
c
c to loop over the neibor nodes, use similar:
c
c       call get_node_links(k,n,ibase)
c       do i=1,n
c         kn = linkv(ibase+i)          !kn is number of neibor node
c       end do

	use mod_geom

	implicit none

	integer k,n,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

        end

c****************************************************************

	subroutine set_elem_links(k,n)

c copies elements around k to lnk_elems (defined in links.h)
c
c to loop over the neibor elements, use similar:
c
c       call set_elem_links(k,n)
c       do i=1,n
c         ien = lnk_elems(ibase+i)          !ien is number of neibor element
c       end do

	use mod_geom

	implicit none

	integer k,n
	integer i,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

	if( lenkv(ibase+n) .eq. 0 ) then
	  lnk_elems(n) = 0
	  n = n - 1
	end if

	if( n .gt. maxlnk ) stop 'error stop set_elem_links: maxlnk'

	do i=1,n
	  lnk_elems(i) = lenkv(ibase+i)
	end do

        end

c****************************************************************

	subroutine set_node_links(k,n)

c copies nodes around k to lnk_nodes (defined in links.h)
c
c to loop over the neibor nodes, use similar:
c
c       call set_node_links(k,n)
c       do i=1,n
c         kn = lnk_nodes(ibase+i)          !kn is number of neibor node
c       end do

	use mod_geom

	implicit none

	integer k,n
	integer i,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

	if( n .gt. maxlnk ) stop 'error stop set_node_links: maxlnk'

	do i=1,n
	  lnk_nodes(i) = linkv(ibase+i)
	end do

	end

c****************************************************************

        subroutine get_elems_around(k,ndim,n,elems)

c returns all elems around node k

	use mod_geom

        implicit none

        integer k               !central node
        integer ndim            !dimension of elems()
        integer n               !total number of elems around k (return)
        integer elems(ndim)     !elems around k (return)

	integer i,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

	if( lenkv(ibase+n) .eq. 0 ) n = n - 1

	do i=1,n
	  elems(i) = lenkv(ibase+i)
	end do

	end

c****************************************************************

        subroutine get_nodes_around(k,ndim,n,nodes)

c returns all nodes around node k

	use mod_geom

        implicit none

        integer k               !central node
        integer ndim            !dimension of nodes()
        integer n               !total number of nodes around k (return)
        integer nodes(ndim)     !nodes around k (return)

	integer i,ibase

	include 'param.h'

	n = ilinkv(k+1)-ilinkv(k)
	ibase = ilinkv(k)

	do i=1,n
	  nodes(i) = linkv(ibase+i)
	end do

	end

c****************************************************************
c****************************************************************
c****************************************************************

	subroutine find_elems_to_segment(k1,k2,ie1,ie2)

c finds elements to segment between nodes k1 and k2
c
c returns elements in ie1 and ie2
c
c ie1 is to the left of segment k1-k2, ie2 to the right
c if boundary segment only one ie is set, the other is zero
c if no such segment, both ie are zero

	use mod_geom

	implicit none

c arguments
        integer k1,k2,ie1,ie2
c common
	include 'param.h'

        integer k,ipf,ipl,ip,ip2

	k = k1
        ipf=ilinkv(k)+1
        ipl=ilinkv(k+1)

	ie1 = 0
	ie2 = 0

	do ip=ipf,ipl
	  k = linkv(ip)
	  if( k .eq. k2 ) then
	    ie1 = lenkv(ip)
	    if( ip .eq. ipf ) then
		ip2 = ipl		!this sets it to 0
	    else
		ip2 = ip - 1		!previous element	!BUGip2
	    end if
	    ie2 = lenkv(ip2)
	    return
	  end if
	end do

	end

c****************************************************************
c****************************************************************
c****************************************************************
c obsolete routines
c****************************************************************
c****************************************************************
c****************************************************************

        subroutine pntfla(k,ipf,ipl)

c gets pointer to first and last element in lenkv
c
c superseeded by get_elem_linkp() - do not use anymore
c
c k     actual node
c ipf   first element (return)
c ipl   last  element (return)

	use mod_geom

        implicit none

c arguments
        integer k,ipf,ipl
c common
	include 'param.h'

        ipf=ilinkv(k)+1
        ipl=ilinkv(k+1)

	if( lenkv(ipl) .eq. 0 ) ipl = ipl - 1	!FIXME

        end

c****************************************************************

        subroutine node_links(ie,ip)

c gets pointer to linkv for element ie
c
c attention - this is really CPU intensive

	use mod_geom
	use basin

        implicit none

c arguments
        integer ie              !element
        integer ip(3,3)         !pointer into linkv
c common
	include 'param.h'

        integer ii,iii,k,kn,i
        integer ipf,ipl

        do ii=1,3
          k = nen3v(ii,ie)
          ipf=ilinkv(k)+1
          ipl=ilinkv(k+1)
          do iii=1,3
            kn = nen3v(iii,ie)
            if( k .eq. kn ) then
              ip(ii,iii) = 0
            else
              do i=ipf,ipl
                if( linkv(i) .eq. kn ) goto 1
              end do
              goto 99
    1         continue
              ip(ii,iii) = i
            end if
          end do
        end do

        return
   99   continue
        write(6,*) ie,ii,iii,k,kn,ipf,ipl
        write(6,*) (linkv(i),i=ipf,ipl)
        stop 'error stop node_links: internal error (1)'
        end

c****************************************************************

