#!/bin/sh
#
# checks if all programs are installed
#
#----------------------------------------------------

log=CHECKLOG
missing=""

CheckFile()
{
  name=$1
  file=$2

  if [ -f $file ]; then
    [ "$verbose" = "YES" ] && echo "... $name is installed"
  else
    echo "*** $name is not installed"
    missing="$missing $file"
  fi
}

CheckCommand()
{
  name=$1
  command=$2

  ($command) >> $log 2>&1 < ./fembin/CR

  status=$?
  #echo "status: $status"

  if [ $status -eq 0 ]; then
    [ "$verbose" = "YES" ] && echo "... $name is installed"
  else
    echo "*** $name is not installed"
    missing="$missing $command"
  fi
}

#---------------------------------------------------

verbose="YES"
[ "$1" = "-quiet" ] && verbose="NO"

[ -f .memory ] && rm -f .memory
[ -f $log ] && rm -f $log

#CheckCommand ht ./fem3d/ht 
#CheckCommand vp ./fem3d/vp 
CheckCommand shyfem ./fem3d/shyfem 
CheckCommand shypre ./fem3d/shypre 
CheckCommand basinf ./fem3d/basinf 

CheckCommand plotsim ./femplot/plotsim 

#CheckCommand ggg ./fem3d/ggg 		#fake error

CheckCommand adjele ./femadj/adjele 
CheckCommand gridr ./femspline/gridr 

CheckCommand grid ./grid/grid 
CheckCommand mesh ./mesh/mesh 
CheckCommand exgrd ./mesh/exgrd 

CheckCommand demopost ./post/demopost 

CheckFile libcalp ./femlib/libcalp.a
CheckFile libfem ./femlib/libfem.a
#CheckFile libgotm ./femlib/libgotm.a
CheckFile libgrappa ./femlib/libgrappa.a
CheckFile libpost ./femlib/libpost.a

rm -f new*.grd
rm -f errout.dat
rm -f plot.ps

if [ -n "$missing" ]; then
  echo ""
  echo "The following programs seem not to be compiled: "
  echo ""
  echo    "$missing"
  echo ""
  echo "Please see the messages in $log and correct"
  echo ""
  exit 1
elif [ $verbose = "YES" ]; then
  echo ""
  echo "All programs are compiled and installed"
  echo ""
fi

exit 0

