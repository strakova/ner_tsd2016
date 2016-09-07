#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use VectorEncoder;

@ARGV >= 3 or die "Usage: ./merge_probs.pl corpus orig_file probs_file [probs_file ...]";

my $corpus = shift @ARGV;
my $orig_filename = shift @ARGV;
my @probs_filenames = @ARGV;

open(my $fr, "<", $orig_filename) or die "Cannot open file '$orig_filename': $!";

my @probs_files;
foreach my $probs_filename (@probs_filenames) {
  open (my $probs_file, "<", $probs_filename) or die "Cannot open file '$probs_filename': $!";
  push @probs_files, $probs_file;
}

while (<$fr>) {
  chomp;

  my $line = $_;
  if (length $line) {
    my (@probs_total, @probs) = ();

    foreach my $probs_file (@probs_files) {
      my $probs = <$probs_file>;
      @probs = split / /, $probs;
      @probs_total = (0) x @probs unless @probs_total;
      for (my $i = 0; $i < @probs; $i++) {
        $probs_total[$i] += exp $probs[$i];
      }
    }

    for (my $i = 0; $i < @probs_total; $i++) {
      $line .= sprintf " %s %f", int_2_label($corpus, $i), $probs_total[$i] / scalar(@probs_files);
    }
  }
  print "$line\n";
}
