#!/usr/bin/perl
#
# cleans path from old fembin entries
#
#-----------------------------------------------------

my $path = $ARGV[0];

my @path = split(/:/,$path);
my @new = ();

foreach my $dir (@path) {

  next if $dir =~ /fembin/;
  next if $dir =~ /shyfem/;
  next if $dir =~ /\/fem\/bin/;		#for old versions

  push(@new,$dir);
}

my $path = join(":",@new);

print "$path\n";

