#!/usr/bin/perl

use strict;
use warnings;

use Common;

my $prev_type = "O";
while(<>) {
  chomp;
  my $type = $_;

  if (/^$/) {
    $prev_type = "O";
    print "\n";
  }
  else {
    if ($prev_type eq "O" and $type ne "O") {
      $type =~ s/^./B/;
    }
    print $type."\n";
    $prev_type=$type;
  }
}
