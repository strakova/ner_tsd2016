#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

my @results = ();

foreach my $arg (@ARGV) {
  foreach my $file (glob "$arg/src/*.o[0-9]*") {
    open (my $f, "<", $file) or die "Cannot open file $file: $!";
    my ($type, $suptype, $span) = ("", "", "");
    while (<$f>) {
      m#^Type:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $type = $1;
      m#^Suptype:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $suptype = $1;
      m#^Span:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $span = $1;

      m#^accuracy:\s+.*FB1:\s+([0-9.]+)\s*$# and $type = $1;
    }
    close $f;
    length($type) and push @results, {score=>$type, value=>"$arg: $type $suptype $span"};
  }
}

foreach my $item (sort {$b->{score} <=> $a->{score}} @results) {
  print "$item->{value}\n";
}
