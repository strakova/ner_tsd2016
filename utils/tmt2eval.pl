#!/usr/bin/perl

use strict;
use warnings;
use open qw{:utf8 :std};

my $lines = 0;
my $ne_type = "";
my $normalized_name = "";
my @ids;
my %m_rf2line;
while(<>) {
  chomp;

  if (/<LM id=\"(SCzechM-.*)\">/) {
    $m_rf2line{$1} = $lines;
    $lines++;
  }

  $lines++ if /<\/trees>/;

  if (/<ne_type>(.*)<\/ne_type>/) {
    $ne_type = $1;
  }

  if (/<normalized_name>(.*)<\/normalized_name>/) {
    $normalized_name = $1;
  }

  if (/<LM>(.*)<\/LM>/) {
    push @ids, $m_rf2line{$1};
  }

  if (/<\/m.rf>/) {
    print join(",", @ids)."\t".$ne_type."\t".$normalized_name."\n";
    ($ne_type, $normalized_name) = ("", "");
    @ids = ();
  }
}


