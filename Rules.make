
#------------------------------------------------------------
# This file defines various parameters to be used
# during compilation. Please customize the first part
# of this file to your needs.
#------------------------------------------------------------

##############################################
# User defined parameters and flags
##############################################

# skel version

##############################################
# Parameters
##############################################
#
# Here you should set all your application 
# specific parameters. The ones below are
# usually the only ones you have to bother.
# However, if you have special needs you can
# also set all the other parameters. Please see
# param.h for more details.
#
# NKNDIM	total number of nodes in domain
# NELDIM	total number of elements in domain
# NGRDIM	maximum number of elements attached to one vertex (node)
# MBWDIM	dimension of bandwidth for system matrix (see output from vpgrd)
# NLVDIM	total number of vertical layers for application (1 for 2D)
# NBDYDIM	maximum number of particles for lagrangian model
#
# N.B.: the parameters set here may be bigger than the actual application
#
##############################################

export NKNDIM = 1
export NELDIM = 1
export NLVDIM = 1

export MBWDIM = 1
export NGRDIM = 1

export NBCDIM = 1
export NRBDIM = 1
export NB3DIM = 1

export NARDIM = 1
export NEXDIM = 1
export NFXDIM = 1
export NCSDIM = 1

export NBDYDIM = 100000

##############################################
# Compiler
##############################################
#
# Please choose a compiler. Compiler options are
# usually correct. You might check below.
#
# Available options for the Fortran compiler are:
#
# GNU_G77		->	g77
# GNU_GFORTRAN		->	gfortran
# INTEL			->	ifort
# PORTLAND		->	pgf90
# IBM			->	xlf
#
# Available options for the C compiler are:
#
# GNU_GCC		->	gcc
# INTEL			->	icc
# IBM			->	xlc
#
##############################################

#FORTRAN_COMPILER = GNU_G77
FORTRAN_COMPILER = GNU_GFORTRAN
#FORTRAN_COMPILER = INTEL
#FORTRAN_COMPILER = PORTLAND
#FORTRAN_COMPILER = IBM

C_COMPILER = GNU_GCC
#C_COMPILER = INTEL
#C_COMPILER = IBM

##############################################
# Parallel compilation
##############################################
#
# For some compilers you can specify
# parallel execution of some parts of the
# code. This can be specified here. Please
# switch back to serial execution if you are
# in doubt of the results.
#
# If running in parallel you get a segmentation fault
# then you might have to run one of the following
# commands on the command line, before you run
# the model:
#
#	ulimit -a		# gives you the system settings
#	ulimit -s 32000		# sets stack to 32MB
#	ulimit -s unlimited	# sets stack to unlimited
#
# For the Intel compiler you may also try inserting a
# command similar to the following in your .bashrc file:
#
#       export KMP_STACKSIZE=32M
#
##############################################

PARALLEL=false
#PARALLEL=true

##############################################
# Solver for matrix solution
##############################################
#
# Here you have to specify what solver you want
# to use for the solution of the system matrix.
# You have a choice between Gaussian elimination,
# iterative solution (Sparskit) and the Pardiso
# solver. 
# The gaussian elimination is the most robust.
# Sparskit is very fast on big matrices.
# To use the Pardiso solver you must have the 
# libraries installed. It is generally faster
# then the default method. Please note that
# in order to use Pardiso you must also use
# the INTEL compiler. The option to use the
# Pardiso solver is considered experimental.
#
##############################################

#SOLVER=GAUSS
SOLVER=SPARSKIT
#SOLVER=PARDISO

##############################################
# NetCDF library
##############################################
#
# If you want output in NetCDF format and have
# the library installed, then you can specify
# it here. The directory where the netcdf files
# reside must also be indicated.
#
##############################################

NETCDF=false
#NETCDF=true
NETCDFDIR = /usr/local/netcdf
NETCDFDIR = /usr

##############################################
# GOTM library
##############################################
#
# This software comes with a version of the
# GOTM turbulence model. It is needed if you
# want to run the model in 3D mode, unless you
# uses constant vertical viscosity and diffusivity.
# If you have problems compiling the GOTM
# library, you can set GOTM to false. This will use
# an older version of the program without the
# need of the external library.
#
##############################################

#GOTM=false
GOTM=true

##############################################
# Ecological models
##############################################
#
# The model also comes with code for some
# ecological models. You can activiate this
# code here. Choices are between EUTRO
# ERSEM and AQUABC. These choices have to be 
# integrated explicitly.
# This feature is still experimental.
#
##############################################

ECOLOGICAL = NONE
#ECOLOGICAL = EUTRO
#ECOLOGICAL = ERSEM
#ECOLOGICAL = AQUABC

##############################################
# experimental features
##############################################

FLUID_MUD = false
#FLUID_MUD = true

##############################################
# end of user defined parameters and flags
##############################################

#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------
# Normally it should not be necessary to change anything beyond here.
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------

##############################################
# DEFINE VERSION
##############################################

RULES_MAKE_VERSION = 1.3
DISTRIBUTION_TYPE = experimental

##############################################
# DEFINE DIRECTORIES
##############################################

DEFDIR  = $(HOME)
FEMDIR  = ..
DIRLIB  = $(FEMDIR)/femlib
MODDIR  = 
MODDIR  = $(DIRLIB)/mod

LIBX = -L/usr/X11R6/lib -L/usr/X11/lib -L/usr/lib/X11  -lX11

##############################################
# check compatibility of options
##############################################

RULES_MAKE_PARAMETERS = RULES_MAKE_OK
RULES_MAKE_MESSAGE = ""

ifeq ($(FORTRAN_COMPILER),GNU_G77)
  ifeq ($(GOTM),true)
    RULES_MAKE_PARAMETERS = RULES_MAKE_PARAMETER_ERROR
    RULES_MAKE_MESSAGE = "g77 compiler and GOTM=true are incompatible"
  endif
  ifeq ($(PARALLEL),true)
    RULES_MAKE_PARAMETERS = RULES_MAKE_PARAMETER_ERROR
    RULES_MAKE_MESSAGE = "g77 compiler and PARALLEL=true are incompatible"
  endif
endif

ifneq ($(FORTRAN_COMPILER),INTEL)
  ifeq ($(SOLVER),PARDISO)
    RULES_MAKE_PARAMETERS = RULES_MAKE_PARAMETER_ERROR
    RULES_MAKE_MESSAGE = "Pardiso solver needs Intel compiler"
  endif
endif

ifeq ($(C_COMPILER),INTEL)
  ifneq ($(FORTRAN_COMPILER),INTEL)
    RULES_MAKE_PARAMETERS = RULES_MAKE_PARAMETER_ERROR
    RULES_MAKE_MESSAGE = "INTEL C works only with INTEL Fortran compiler"
  endif
endif

#------------------------------------------------------------

##############################################
# COMPILER OPTIONS
##############################################

##############################################
# General Compiler options
##############################################

# if unsure please leave defaults
#
# DEBUG        insert debug information and run time checks
# PROFILE      insert profiling instructions
# OPTIMIZE     optimize program for speed
# WARNING      generate compiler warnings for unusual constructs

#PROFILE = true
PROFILE = false

DEBUG = true
#DEBUG = false

OPTIMIZE = true
#OPTIMIZE = false

WARNING = true
#WARNING = false

##############################################
#
# GNU compiler (g77, f77 or gfortran)
#
##############################################
#
# -Wall			warnings
# -pedantic		a lot of warnings
# -fautomatic		forget local variables
# -static		save local variables
# -no-automatic		save local variables
# -O			optimization
# -g			debug code
# -r8			double precision for old compiler
# -fdefault-real-8	double precision for new compiler
# -p			use profiling
#
# problems with stacksize (segmentation fault)
#	ulimit -a
#	ulimit -s 32000		(32MB)
#	ulimit -s unlimited
#
##############################################

FGNU_GENERAL = 
ifdef MODDIR
  FGNU_GENERAL = -J$(MODDIR)
endif

FGNU_PROFILE = 
ifeq ($(PROFILE),true)
  FGNU_PROFILE = -p
endif

FGNU_WARNING = 
ifeq ($(WARNING),true)
  FGNU_WARNING = -Wall -pedantic
  FGNU_WARNING = -Wall -Wtabs -Wno-unused -Wno-uninitialized
  FGNU_WARNING = -Wall -Wtabs -Wno-unused
endif

FGNU_NOOPT = 
ifeq ($(DEBUG),true)
  FGNU_NOOPT = -g
endif

FGNU_OPT   = 
ifeq ($(OPTIMIZE),true)
  FGNU_OPT   = -O3
  FGNU_OPT   = -O
endif

FGNU_OMP   =
ifeq ($(PARALLEL),true)
  FGNU_OMP   =  -fopenmp
endif

#----------------------------------

ifeq ($(FORTRAN_COMPILER),GNU_G77)
  FGNU		= g77
  FGNU95	= g95
  F77		= $(FGNU)
  F95		= $(FGNU95)
  LINKER	= $(F77)
  LFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_OMP)
  FFLAGS	= $(LFLAGS) $(FGNU_NOOPT) $(FGNU_WARNING)
  FINFOFLAGS	= -v
endif

ifeq ($(FORTRAN_COMPILER),GNU_GFORTRAN)
  FGNU		= gfortran
  FGNU95	= gfortran
  F77		= $(FGNU)
  F95		= $(FGNU95)
  LINKER	= $(F77)
  LFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_OMP)
  FFLAGS	= $(LFLAGS) $(FGNU_NOOPT) $(FGNU_WARNING) $(FGNU_GENERAL)
  FINFOFLAGS	= -v
endif

##############################################
#
# IBM compiler (xlf)
#
##############################################
#
# if you use xlf95  "-qnosave" is a default option
# xlf_r is thread safe
# all the compiler options are included in FIBM_OMP
# set PARALLEL = TRUE
##############################################

FIBM_PROFILE = 
ifeq ($(PROFILE),true)
  FIBM_PROFILE = 
endif

FIBM_WARNING = 
ifeq ($(WARNING),true)
  FIBM_NOOPT = 
endif

FIBM_NOOPT = 
ifeq ($(DEBUG),true)
  FIBM_NOOPT =
endif

FIBM_OPT   = 
ifeq ($(OPTIMIZE),true)
# FIBM_OPT   = -O3 
  FIBM_OPT   = 
endif

FIBM_OMP   =
ifeq ($(PARALLEL),true)
     FIBM_OMP    = -qsmp=omp -qnosave -q64 -qmaxmem=-1 -NS32648 -qextname -qsource -qcache=auto -qstrict -O3 -qarch=pwr6 -qtune=pwr6
endif

#----------------------------------

ifeq ($(FORTRAN_COMPILER),IBM)
  FIBM		= xlf_r
  F77		= $(FIBM)
  F95		= xlf_r
  LINKER	= $(FIBM)
  FFLAGS	= $(FIBM_OMP)
  LFLAGS	= $(FIBM_OMP) -qmixed  -b64 -bbigtoc -bnoquiet -lpmapi -lessl -lmass -lmassvp4
endif
 
##############################################
#
# Portland compiler
#
##############################################

FPG_PROFILE = 
ifeq ($(PROFILE),true)
  FPG_PROFILE = -Mprof=func
endif

FPG_WARNING = 
ifeq ($(WARNING),true)
  FPG_WARNING =
endif

FPG_NOOPT = 
ifeq ($(DEBUG),true)
  FPG_NOOPT = -g
endif

FPG_OPT   = 
ifeq ($(OPTIMIZE),true)
  FPG_OPT   = -O
  FPG_OPT   = -O3
endif

FPG_OMP   =
ifeq ($(PARALLEL),true)
  FPG_OMP   =  -mp
endif

#----------------------------------

ifeq ($(FORTRAN_COMPILER),PORTLAND)
  FPG		= pgf90
  FPG95		= pgf90
  F77		= $(FPG)
  F95		= $(FPG95)
  LINKER	= $(F77)
  LFLAGS	= $(FPG_OPT) $(FPG_PROFILE) $(FPG_OMP)
  FFLAGS	= $(LFLAGS) $(FPG_NOOPT) $(FPG_WARNING)
  FINFOFLAGS	= -v
endif

##############################################
#
# INTEL compiler
#
##############################################
#
# -w    warnings	no warnings
# -CU   run time exception
# -dn   level n of diagnostics
# -O    optimization (O2 O3)
# -i8   integer 8 byte (-i2 -i4 -i8)
# -r8   real 8 byte    (-r4 -r8 -r16), also -autodouble
#
# -check none
# -check all
# -check bounds
# -check uninit		(run time exception for uninitialized values)
#
# -implicitnone
# -debug
# -openmp
# -openmp-profile
# -openmp-report	(1 2)
#
# -warn interfaces -gen-interfaces
#
# problems with stacksize (segmentation fault)
#	export KMP_STACKSIZE=32M
#
#############################################

# ERSEM FLAGS -------------------------------------

REAL_4B = real\(4\)
DEFINES += -DREAL_4B=$(REAL_4B)
DEFINES += -DFORTRAN95 
DEFINES += -DPRODUCTION -static
FINTEL_ERSEM = $(DEFINES) 

#-------------------------------------------------

FINTEL_GENERAL =
ifdef MODDIR
  FINTEL_GENERAL = -module $(MODDIR)
endif

FINTEL_PROFILE = 
ifeq ($(PROFILE),true)
  FINTEL_PROFILE = -p
endif

FINTEL_WARNING = 
ifeq ($(WARNING),true)
  FINTEL_WARNING =
  FINTEL_WARNING = -w
  FINTEL_WARNING = -warn interfaces,nouncalled -gen-interfaces
endif

FINTEL_NOOPT = 
ifeq ($(DEBUG),true)
  FINTEL_NOOPT = -xP
  FINTEL_NOOPT = -CU -d1
  FINTEL_NOOPT = -CU -d5
  FINTEL_NOOPT = -g -traceback -check all
  FINTEL_NOOPT = -g -traceback -check uninit -check bounds 
  FINTEL_NOOPT = -g -traceback -check uninit 
  FINTEL_NOOPT = -g -traceback 
endif

# FINTEL_OPT   = -O -g -Mprof=time
# FINTEL_OPT   = -O3 -g -axSSE4.2 #-mcmodel=medium -shared-intel
# FINTEL_OPT   = -O3 -g -axAVX -mcmodel=medium -shared-intel
# FINTEL_OPT   = -O -g -fp-model precise -no-prec-div

FINTEL_OPT   = 
ifeq ($(OPTIMIZE),true)
  FINTEL_OPT   = -O 
  #FINTEL_OPT   = -O -mcmodel=medium
  #FINTEL_OPT   = -O -mcmodel=large
endif

FINTEL_OMP   =
ifeq ($(PARALLEL),true)
  FINTEL_OMP   = -threads -openmp
endif

ifeq ($(FORTRAN_COMPILER),INTEL)
  FINTEL	= ifort
  F77		= $(FINTEL)
  F95     	= $(F77)
  LINKER	= $(F77)
  LFLAGS	= $(FINTEL_OPT) $(FINTEL_PROFILE) $(FINTEL_OMP)
  FFLAGS	= $(LFLAGS) $(FINTEL_NOOPT) $(FINTEL_WARNING) $(FINTEL_GENERAL)
  FINFOFLAGS	= -v
endif

##############################################
#
# C compiler
#
##############################################

ifeq ($(C_COMPILER),GNU_GCC)
  CC     = gcc
  CFLAGS = -O -Wall -pedantic
  CFLAGS = -O -Wall -pedantic -std=gnu99  #no warnings for c++ style comments
  LCFLAGS = -O 
  CINFOFLAGS = -v
endif

ifeq ($(C_COMPILER),INTEL)
  CC     = icc
  CFLAGS = -O -g -traceback -check-uninit
  LCFLAGS = -O 
  CINFOFLAGS = -v
endif

ifeq ($(C_COMPILER),IBM)
  CC     = xlc
#  CFLAGS = -O -traceback -check-uninit
  CFLAGS = -O
  LCFLAGS = -O 
  CINFOFLAGS = -v
endif

##############################################
#
# old stuff - do not bother
#
##############################################

##############################################
#
# profiling: use -p for linking ; example for ht
#
#   f77 -p -c subany.f ... 	(compiles with profiling)
#   f77 -p -o ht ...     	(links with profiling)
#   ht                   	(creates mon.out)
#   prof ht              	(elaborates mon.out)
#   gprof ht              	(elaborates mon.out)
#	-b	brief
#	-p	flat profile
#
##############################################


##############################################
#
# lahey
#
#	help for options :
#		f77l3
#		386link
#		up l32 /help
#	remove kernel :
#		os386 /remove
#	compiler switches :
#		/R	remember local variables
#		/H	hardcopy listing
#		/S	create sold file .sld
#		/L	line-number traceback table
#		/O	output options
#
# compiler (all versions)
# 
# FLC             = f77l3
# FLFLAGS         = /nO /nS /L /nR /nH
# 
# linker lahey 3.01
# 
# LLINKER         = up l32
# LDFLAGS         = /nocommonwarn /stack:5004
# LDMAP           = nul
# LLIBS		=
# LDEXTRA		= ,$@,$(LDMAP),$(LLIBS) $(LDFLAGS);
# EXE		= exp
# 
# linker lahey 5.20
# 
# LLINKER		= 386link
# LDFLAGS		= -stack 2000000 -fullsym
# LDEXTRA		= $(LDFLAGS)
# EXE    		= exe
#
##############################################

##############################################
# Private stuff
##############################################

#MAKEGENERAL = $(FEMDIR)/general/Makefile.general

