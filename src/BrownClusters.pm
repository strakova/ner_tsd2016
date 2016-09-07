package BrownClusters;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(read_brown_clusters word_2_brown_cluster_vector);

our %word2cluster;
our %cluster2int;
our $nclusters = 0;
our %PATHS = ( "en" => "/clusters/en/bllip-clusters",
               "cs" => "/clusters/cs/wiki-1000",
               "de" => "/clusters/de/wiki_1000_cutoff_2"
             );

sub read_brown_clusters {
  my ($lang, $support_path) = @_;

  if (not exists $PATHS{$lang}) {
    die "No Brown clusters available for language \"$lang\".\n";
  }

  my $filename = $support_path . $PATHS{$lang};
  print STDERR "Reading Brown clusters from file \"$filename\".\n";

  open (my $file, "<", $filename) or die "Cannot open file with Brown clusters.\n";
  my $i = 0;
  while (<$file>) {
    $i++;
    print STDERR "Lines: $i\n" if $i % 100000 == 0;

    chomp;
    my ($cluster, $word, $dummy) = split /\t/;

    if (not exists($cluster2int{$cluster})) {
      $cluster2int{$cluster} = $nclusters;
      $nclusters++;
    }

    $word2cluster{$word} = $cluster;
  }

  return $nclusters;
}

sub word_2_brown_cluster_vector {
  my ($word) = @_;

  my @vector = (0) x $nclusters;

  if (exists $word2cluster{$word}) {
    my $cluster = $word2cluster{$word};
    $vector[$cluster2int{$cluster}] = 1;
  }

  return join(" ",@vector);
}

1;
