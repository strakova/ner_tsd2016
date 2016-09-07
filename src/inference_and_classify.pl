#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use Common;

my @sentence;
while(<>) {
  chomp;

  if (/^$/) {
    my @B_probs;
    my @I_probs;
    my @L_probs;
    my @O_probs;
    my @U_probs;
    my @B_types;
    my @U_types;
    foreach my $line (@sentence) {
      my @cols = split / /, $line;
      my ($B_prob, $B_type, $U_prob, $U_type) = (-1, "", -1, "");

      # 4 or 5 beginning columns?
      my $ncols = @cols;
      my $start_col = $ncols % 2 ? 5 : 4;
      
      for (my $i = $start_col; $i+1 < @cols; $i+=2) {
        if ($cols[$i] =~ /^B-(\w+)$/) {
          next if $cols[$i+1] < $B_prob;
          $B_prob = $cols[$i+1];
          $B_type = $1;
        } elsif ($cols[$i] =~ /^U-(\w+)$/) {
          next if $cols[$i+1] < $U_prob;
          $U_prob = $cols[$i+1];
          $U_type = $1;
        }
        elsif ($cols[$i] =~ /^I$/) { push @I_probs, $cols[$i+1] if $cols[$i] =~ /^I/; }
        elsif ($cols[$i] =~ /^L$/) { push @L_probs, $cols[$i+1] if $cols[$i] =~ /^L/; }
        elsif ($cols[$i] =~ /^O$/) { push @O_probs, $cols[$i+1] if $cols[$i] =~ /^O/; }
        else { die "Unknown entity type $cols[$i] at line:\n\n$line\n"; }
      }
      push @B_probs, $B_prob;
      push @B_types, $B_type;
      push @U_probs, $U_prob;
      push @U_types, $U_type;
    }

    # dynamic programming
    my $n = @sentence;

    my @best;
    for (my $i = 0; $i <= $n; $i++) { $best[$i] = {}; }

    sub choose($%) {
      my ($best, $prob, $nexts_ref, @nexts) = (undef, @_);
      foreach my $next (@nexts) {
        my $p = $prob * $nexts_ref->{$next}->{'p'};
        $best = defined($best) && $best->{'p'} >= $p ? $best : {'next' => $next, 'p' => $p};
      }
      return $best;
    }

    $best[$n]->{O} = {'p' => 1};
    $best[$n]->{B} = $best[$n]->{I} = $best[$n]->{L} = $best[$n]->{U} = {'p' => 0};
    for (my $i = $n-1; $i >= 0; $i--) {
      $best[$i]->{B} = choose $B_probs[$i], $best[$i+1], qw{I L};
      $best[$i]->{I} = choose $I_probs[$i], $best[$i+1], qw{I L};
      $best[$i]->{L} = choose $L_probs[$i], $best[$i+1], qw{O B U};
      $best[$i]->{O} = choose $O_probs[$i], $best[$i+1], qw{O B U};
      $best[$i]->{U} = choose $U_probs[$i], $best[$i+1], qw{O B U};
    }

    my $entity = 'O';
    $entity = 'B' if $best[0]->{B}->{p} > $best[0]->{$entity}->{p};
    $entity = 'U' if $best[0]->{U}->{p} > $best[0]->{$entity}->{p};
    my ($type, $previous_type) = ('', '');
    for (my $i = 0; $i < $n; $i++) {
      my @cols = split / /, $sentence[$i];
      my $ncols = @cols;
      my ($form, $lemma, $tag, $chunk, $gold) = ($ncols % 2 ? @cols : ($cols[0], EMPTY, $cols[1], $cols[2], $cols[3]));

      if ($entity eq 'B') { $type = $B_types[$i]; }
      if ($entity eq 'U') { $type = $U_types[$i]; }

      my $entity_desc;
      $entity_desc = 'O' if $entity eq 'O';
      $entity_desc = 'I-' . $type if $entity =~ /[IL]/;
      $entity_desc = ($previous_type eq $type ? 'B' : 'I') . '-' . $type if $entity =~ /[BU]/;
      print join(' ', $form, $lemma, $tag, $chunk, $gold, $entity_desc) . "\n";

      if ($entity eq 'O') { $previous_type = ''; }
      elsif ($entity =~ /[LU]/) { $previous_type = $type; }      
      $entity = $best[$i]->{$entity}->{next};
    }
    print "\n";

    @sentence = ();
  }
  else {
    push @sentence, $_;
  }
}
