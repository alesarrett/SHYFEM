
c-------------------------------------------------------------
c header file for nos file format
c-------------------------------------------------------------
c
c ftype		file id
c maxvers	newest version of file
c maxcomp	compatible function calls down to here
c
c ndim		number of possible entries (open files)
c nitdim	number of integer values to be stored
c nchdim	number of string values to be stored
c
c nositem	number of maximum entries in table
c
c nosvar	integer parameters of open files
c noschar	string parameters of open files
c
c nosvar(0,n)   iunit
c nosvar(1,n)   nvers
c nosvar(2,n)   nkn
c nosvar(3,n)   nel
c nosvar(4,n)   nlv
c nosvar(5,n)   nvar
c nosvar(6,n)   date
c nosvar(7,n)   time
c
c noschar(1,n)  title
c noschar(2,n)  femver
c
c-------------------------------------------------------------
c parameters
c-------------------------------------------------------------

        integer ftype,maxvers,maxcomp
        parameter(ftype=161,maxvers=5,maxcomp=3)

        integer ndim,nitdim,nchdim
        parameter(ndim=30,nitdim=7,nchdim=2)

c-------------------------------------------------------------
c common
c-------------------------------------------------------------

        integer nositem
        common /nositm/nositem

        integer nosvar(0:nitdim,ndim)
        common /nosvar/nosvar

        character*80 noschar(nchdim,ndim)
        common /noschar/noschar

c-------------------------------------------------------------
c save
c-------------------------------------------------------------

        save /nositm/
        save /nosvar/
        save /noschar/

c-------------------------------------------------------------
c end of header
c-------------------------------------------------------------

