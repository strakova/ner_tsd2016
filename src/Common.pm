package Common;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use constant EMPTY => "_";
use constant OUTSIDE => "O";
use constant DELIM => "/";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_ith_line get_ith_label get_suffixes get_prefixes get_substrings EMPTY OUTSIDE get_first_n_words raw_label DELIM);

sub raw_label {
  my ($label) = @_;
  if ($label =~ /-(.*)$/) {
    return $1;
  }
  else {
    return $label;
  }
#  return ((is_entity($label) and $label =~ /-(.*)$/) ? $1 : $label);
}

sub get_ith_line {
  my ($i, $lines_ref) = @_;

  if ($i < 0 or $i >= @{$lines_ref} or $lines_ref->[$i] eq "") {
    return (EMPTY, EMPTY, EMPTY);
  }
  else {
    my @cols = split / /, $lines_ref->[$i];
    return @cols;
  }
}

sub get_ith_label {
  my ($i, $lines_ref) = @_;

  if ($i < 0 or $i >= @{$lines_ref} or $lines_ref->[$i] eq "") {
    return EMPTY;
  }
  else {
    my @cols = split / /, $lines_ref->[$i];
    my $ncols = @cols;
    return $ncols == 5 ? $cols[4] : $cols[3];
  }
}

sub get_suffixes {
  my ($word) = @_;

  my @chars = split //, $word;
  my $n = @chars;

  my @suffixes;
  push @suffixes, ($chars[$n-1]) if $n-1 >= 0;
  push @suffixes, ($chars[$n-2].$chars[$n-1]) if $n-2 >= 0;
  push @suffixes, ($chars[$n-3].$chars[$n-2].$chars[$n-1]) if $n-3 >= 0;
  push @suffixes, ($chars[$n-4].$chars[$n-3].$chars[$n-2].$chars[$n-1]) if $n-4 >= 0;

  return @suffixes;
}

sub get_prefixes {
  my ($word) = @_;
  my @chars = split //, $word;
  my $n = @chars;
  
  my @prefixes;
  push @prefixes, ($chars[0]) if $n >= 1;
  push @prefixes, ($chars[0].$chars[1]) if $n >= 2;
  push @prefixes, ($chars[0].$chars[1].$chars[2]) if $n >= 3;
  push @prefixes, ($chars[0].$chars[1].$chars[2].$chars[3]) if $n >= 4;

  return @prefixes;
}

sub get_substrings {
  my ($word) = @_;

  my @chars = split //, lc($word);
  my @subs;
  for (my $i = 0; $i < @chars; $i++) {
    for (my $j = 5; $i+$j <= @chars; $j++) {
      my $sub = substr $word, $i, $j;
      next if $sub eq $word;
      push @subs, $sub;
    }
  }
  return @subs;
}

sub get_first_n_words {
  my ($sentence, $n) = @_;

  my @output;
  my @tokens = split / /, $sentence;
  for (my $i = 0; $i < $n and $i < @tokens; $i++) {
    push @output, $tokens[$i];
  }

  return join(" ", @output);
}

1;
