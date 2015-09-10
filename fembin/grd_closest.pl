#!/usr/bin/perl -s -w
#
# finds closest grid nodes to sparse nodes (in grd format)
#
#--------------------------------------------------------

use lib ("$ENV{SHYFEMDIR}/femlib/perl","$ENV{HOME}/shyfem/femlib/perl");

use grd;
use strict;

#-------------------------------------------------------------

my $grid_file = $ARGV[0];
my $node_list = $ARGV[1];

unless( $node_list ) {
  die "Usage: grd_closest.pl grd-file grd-nodes\n";
}

my $grid = new grd;
$grid->readgrd("$grid_file");
my $ngrid = new grd;
$ngrid->readgrd("$node_list");

my @list = ();

#------------------------------------------------------------

my $nodes = $ngrid->get_nodes();
foreach my $nitem (sort by_node_number values %$nodes) {
  my $number = $nitem->{number};
  my $x = $nitem->{x};
  my $y = $nitem->{y};

  my $n = get_closest($grid,$x,$y);
  push(@list,"$number    $n");

  my $item = $grid->get_node($n);
  my $type = $item->{type};
  $number = $item->{number};
  $x = $item->{x};
  $y = $item->{y};
  print "1 $number $type $x $y\n";
}

foreach my $line (@list) {
  print STDERR "$line\n";
}

#------------------------------------------------------------

sub get_closest {

  my ($grid,$xn,$yn) = @_;

  my $nn = 0;
  my $dist = 1.e+30;

  my $nodes = $grid->get_nodes();
  foreach my $item (values %$nodes) {
    my $number = $item->{number};
    my $x = $item->{x};
    my $y = $item->{y};

    my $d = ($x-$xn)*($x-$xn) + ($y-$yn)*($y-$yn);
    if( $d < $dist ) {
      $dist = $d;
      $nn = $number;
    }
  }

  return $nn;
}

#------------------------------------------------------------

sub by_node_number {

  if( $a->{number} > $b->{number} ) {
    return 1;
  } elsif( $a->{number} < $b->{number} ) {
    return -1;
  } else {
    return 0;
  }
}
