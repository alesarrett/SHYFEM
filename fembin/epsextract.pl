#!/usr/bin/perl

# extracts eps files from ps file

$open = 0;

while(<>) {

  if( /^%%EndDocument$/ ) {
    $open--;
    if( $open == 0 ) {
      print STDERR "closing $file\n";
    }
  }

  if( $open ) {
    print FILE;
  }

  if( /^%%BeginDocument: (.*)$/ ) {
    $open++;
    if( $open == 1 ) {
      $file = $1;
      $file =~ s/\//__/g;
      print STDERR "opening $file\n";
      open(FILE,">$file");
    }
  }

}
