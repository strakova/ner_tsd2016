#!/usr/bin/perl

use strict;
use warnings;

use Common;
use FeatureExtractor;

my @lines = map { chomp; $_ } <>;

my @ids;
my @forms;
for (my $i = 0; $i < @lines; $i++) {
  my $line = $lines[$i];
  next if $line eq "";

  my @cols = split / /, $line;
  my $form = $cols[0];

  my $label = get_ith_label($i, \@lines);
  my $nlabel = get_ith_label($i+1, \@lines);

  if (is_entity($label)) {
    push @ids, $i;
    push @forms, $form;
  }

  if (is_last($label, $nlabel)) {
    print join(",", @ids)."\t".raw_label($label)."\t".join(" ", @forms)."\n";
    @ids = ();
    @forms = ();
  }
}
