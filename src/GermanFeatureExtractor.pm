package GermanFeatureExtractor;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(extract_German_features read_German_gazetteers);

use Common;
use Gazetteers;
use BrownClusters;

sub extract_German_features {
  my ($lang, $args) = @_;

  my @features;
  my $form = $args->{"Form_0"};

  ### FORM, TAG AND CHUNK
  foreach my $k (keys %{$args}) {
    my $v = $args->{$k};

    push @features, $k.DELIM.$v if $k =~ /^Form/;
    push @features, $k.DELIM.$v if $k =~ /^Lemma/;
    push @features, $k.DELIM.$v if $k =~ /^Tag/;
#    push @features, $k."/".raw_label($v) if $k =~ /^Chunk/;

    push @features, $k.DELIM.$v if $k =~ /^Window/;

    push @features, $k.DELIM.$v if $k =~ /^Label/;
    push @features, $k if $k =~ /^PreviouslyPredicted/;

    # Context aggregation
    push @features, $k if $k =~ /^Context_Lemma/;
    push @features, $k if $k =~ /^Context_Tag/;
#    push @features, $k if $k =~ /^Context_Chunk/;

    # Orthographic features
    if ($k =~ /^Form/) {
      # Capitalization
      push @features, "FirstCap_$k"     if $v =~ /^[[:upper:]]/; # +1.27 
      push @features, "AllCap_$k"       if $v =~ /^[[:upper:]]*$/;
      push @features, "MixedCap_$k"     if $v !~ /^[[:upper:]]*$/ and $v !~ /^[[:lower:]]*$/;

      # Punctuation
      push @features, "EndsWithPeriod_$k"       if $v =~ /\.$/;
      push @features, "InternalPeriod_$k"       if $v =~ /\./;
      push @features, "InternalApostrophe_$k"   if $v =~ /'/;
      push @features, "InternalHyphen_$k"       if $v =~ /-/;
      push @features, "InternalAmp_$k"          if $v =~ /&/;
      push @features, "InternalPunctuation_$k"  if $v =~ /[\.\,'\-&]/;

      # Character
      push @features, "PossessiveMark_$k"       if $v =~ /'s/;
      push @features, "NegativeMark_$k"         if $v =~ /'n/;

      # Lowercase and uppercase
      push @features, "Lowercase_$k".DELIM.lc($v);
      push @features, "Uppercase_$k".DELIM.uc($v);
      push @features, "Token_length_$k".DELIM.length($v);
    }

    push @features, "SimplifiedPOS_$k".DELIM.substr($v, 0, 1) if $k =~ /^Tag/;

    ### GAZETTEERS
    push @features, $k if $k =~ /^Gazetteer/;
  }
 
  ### PREFIXES AND SUFFIXES

  # suffixes +2.91
  my @suffixes = get_suffixes($form);
  for (my $i = 0; $i < @suffixes; $i++) {
    push @features, "Suffix_".$i.DELIM.$suffixes[$i];
  }

  # prefixes +0.44
  my @prefixes = get_prefixes($form);
  for (my $i = 0; $i < @prefixes; $i++) {
    push @features, "Prefix_".$i.DELIM.$prefixes[$i];
  }

  ### SUBSTRINGS
  # TODO
#  foreach my $substring (get_substrings($form)) {
#    push @features, "Substring_$substring" if exists $substrings{$substring};
#  }

  ### BROWN CLUSTERS
  foreach my $k (keys %{$args}) {
    if ($k =~ /Form/) {
      my $cluster = brown_cluster($args->{$k});
      if ($cluster != -1) {
        push @features, "BrownCluster".DELIM.$cluster if $cluster != -1;

        my @cluster_prefixes = brown_cluster_path_prefixes($form);
        for (my $i = 0; $i < @cluster_prefixes; $i++) {
          push @features, "BrownCluster_".$k."_".$i.DELIM.$cluster_prefixes[$i];
        }
      }
    }
  }

  return @features;
}

1;
