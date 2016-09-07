#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use constant id => 0;
use constant class => 1;
use constant name => 2;

my @lines;
while (<>) {
  my $line = $_;
  print $line;

  chomp $line;
  my ($ids, $class, $normalized_name) = split /\t/, $line;
  push @lines, [$ids, $class, $normalized_name];
}

my @chunks;
my @chunk;
for (my $i = 0; $i < @lines; $i++) {
  my $last_id = @chunk && $chunk[-1]->[id] =~ /(\d+)$/ ? $1 : -999;
  my $next_id = $lines[$i]->[id] =~ /^(\d+)/ ? $1 : die;
  if ($last_id+1 > $next_id) {
    push @chunks, [@chunk];
    @chunk = ();
  }
  push @chunk, $lines[$i];
}
push @chunks, [@chunk] if @chunk;

sub merge {
  my ($class, @ents) = @_;

  return join(",", map { $_->[id] } @ents) . "\t$class\t" . join(" ", map { $_->[name] } @ents) . "\n";
}

foreach my $chunk_ref (@chunks) {
  my @c = @{$chunk_ref};
  for (my $i = 0; $i < @c; $i++) {
    print merge("P", @c[$i-1..$i]) if $i >= 1 && $c[$i-1]->[class] eq "pf" && $c[$i]->[class] eq "ps";
    print merge("T", @c[$i-2..$i]) if $i >= 2 && $c[$i-2]->[class] eq "td" && $c[$i-1]->[class] eq "tm" && $c[$i]->[class] eq "ty";
    print merge("T", @c[$i-1..$i]) if $i >= 1 && $c[$i-1]->[class] eq "td" && $c[$i]->[class] eq "tm" && ($i+1 >= @c || $c[$i+1]->[class] ne "ty");
    print merge("T", @c[$i-1..$i]) if $i >= 1 && $c[$i-1]->[class] eq "tm" && $c[$i]->[class] eq "ty" && ($i-2 < 0 || $c[$i-2]->[class] ne "td");
  }
}
