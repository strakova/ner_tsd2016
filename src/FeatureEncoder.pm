package FeatureEncoder;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

# This package encodes and decodes features

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(create_features_vocabulary read_features_vocabulary features_2_vector);

use FeatureExtractor;
use Common;

our $DELIM = " "; 
our %feature_2_int = (); 
our $nfeatures = 0;

sub read_features_vocabulary {
  my ($filename, $lang) = @_;

  open (my $file, "<", $filename) or die "Cannot open feature vocabulary file \"$filename\"\n";

  print STDERR "Reading features vocabulary from file \"$filename\"\n";
 
  my @lines = map { chomp; $_ } <$file>;
  my $n = @lines;

  my $i = 0;
  foreach my $line (@lines) {
    my ($feature, $int) = split $DELIM, $line;
    $feature_2_int{$feature} = $int;
    $nfeatures = $int + 1 if $int + 1 > $nfeatures;
    print STDERR "Lines: $i / $n\n" if $i % 1000 == 0;
    $i++;
  }

  return $nfeatures;
}

sub create_features_vocabulary {
  my ($filename, $lang, $settings_ref) = @_;

  init_feature_extractor($lang, $settings_ref);
  
  # read training data file
  open (my $file, "<", $filename) or die "Cannot open training file \"$filename\".\n";
  my @lines = map { chomp; $_ } <$file>;

  print STDERR "Creating features vocabulary from file \"$filename\".\n";

  # print classification features
  my @forms = ();
  my @lemmas = ();
  my @tags = ();
  my %features2int = ();
  my $nfeatures = 0;
  for (my $i = 0; $i < @lines; $i++) {
    if ($lines[$i] eq "") {
      my $sentence_features_ref = extract_features_for_sentence($lang, \@forms, \@lemmas, \@tags); 
      foreach my $token_features_ref (@{$sentence_features_ref}) {
        foreach my $feature (@{$token_features_ref}) {
          if (not exists $features2int{$feature}) {
            $features2int{$feature} = $nfeatures;
            $nfeatures++;
          }
        }
      }
      @forms = ();
      @lemmas = ();
      @tags = ();
      next;
    }
    else {
      my ($form, $lemma, $tag) = get_ith_line($i, \@lines);
      push @forms, $form;
      push @lemmas, $lemma;
      push @tags, $tag;
    }
  }
  foreach my $feature (keys %features2int) {
    print $feature." ".$features2int{$feature}."\n";
  }
}

sub features_2_vector {
  my (@features) = @_;

  my @vector = (0) x $nfeatures;

  foreach my $feature (@features) {
    if (exists $feature_2_int{$feature}) {
      $vector[$feature_2_int{$feature}] = 1;
    }
  }

  return join $DELIM, @vector;
}

1;
