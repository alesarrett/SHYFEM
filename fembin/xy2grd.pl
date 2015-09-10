#!/usr/bin/perl -s
#
# converts files containing (x,y,z) coordinates to grd format
#
# z value may be missing
# as separator space ( ), comma (,) or semicolon (;) can be used
#
# options: -invert
#
#---------------------------------------------------------

$invert = 0 unless $invert;	# invert rows 1 and 2 (lat/lon)

$n = 0;
$type = 3;

while(<>) {

  chomp;
  s/^\s*//;	# get rid of leading spaces
  s/,/ /g;	# convert commas to spaces
  s/;/ /g;	# convert semicolon to spaces

  @f = split;
  $nf = @f;

  if( $nf == 2 ) {
    $x = $f[0];
    $y = $f[1];
    $z = "";
  } elsif( $nf == 3 ) {
    $x = $f[0];
    $y = $f[1];
    $z = $f[2];
  } else {
    die "expecting 2 or 3 values: $_\n";
  }

  if( $invert ) {
    $aux = $x;
    $x = $y;
    $y = $aux;
  }

  $n++;
  print "1 $n $type $x $y $z\n";
}

