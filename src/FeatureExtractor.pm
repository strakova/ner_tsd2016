package FeatureExtractor;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_entity read_gazetteers extract_features is_beginning is_last is_multiword extract_class_features get_type %window_size %prediction_history_size %large_prediction_history_size init_feature_extractor extract_features_for_sentence);

use Common;
use CzechFeatureExtractor;
use EnglishFeatureExtractor;
use GermanFeatureExtractor;
use Gazetteers;
use BrownClusters;

our $tmp_path = "../";

our $first_names_ref;
our $last_names_ref;
our $cities_ref;

our %window_size = ("de" => 2, "cs" => 2, "en" => 2);
our %prediction_history_size = ("de" => 5, "cs" => 5, "en" => 5);
our %large_prediction_history_size = ("de" => 500, "cs" => 500, "en" => 500);

our %settings = ( "use_forms" => 1,
                  "use_lemmas" => 1,
                  "use_tags" => 1,
                  "use_prefixes" => 1,
                  "use_suffixes" => 1,
                  "support_path" => "/net/work/people/strakova/named_entities_redmine/support/"
                );

sub is_entity {
  my ($label) = @_;
  return ($label ne EMPTY and $label ne OUTSIDE);
}

sub is_beginning {
  my ($plabel, $label) = @_;

  # previous token was not entity and new entity starts here
  return 1 if ((not is_entity($plabel)) and is_entity($label));
  
  # previous token was entity and different entity type starts here
  return 1 if (is_entity($plabel) and is_entity($label) and raw_label($plabel) ne raw_label($label));

  # previous token was entity and same entity type but new instance starts here
  return 1 if (is_entity($plabel) and is_entity($label) and $label =~ /B-/);

  return 0;
}

sub is_last {
  my ($label, $nlabel) = @_;

  # current token is entity and next token is not
  return 1 if (is_entity($label) and not is_entity($nlabel));
  
  # current token is entity and different entity type starts on next token
  return 1 if (is_entity($label) and is_entity($nlabel)
               and raw_label($label) ne raw_label($nlabel));
    
  # current token is entity and same entity type but new instance starts on next token
  return 1 if (is_entity($label) and is_entity($nlabel) and $nlabel =~ /B-/);

  return 0;
}

sub is_multiword {
  my ($label, $nlabel) = @_;

  return (is_entity($label) and is_entity($nlabel)
            and raw_label($label) eq raw_label($nlabel)
            and not $nlabel =~ /B-/);
}

sub extract_features {
  my ($lang, $args) = @_;

  ### ENGLISH
  return extract_English_features($args, \%settings) if $lang eq "en";
  
  ### CZECH
  return extract_Czech_features($args, \%settings) if $lang eq "cs";

  ### GERMAN
  return extract_German_features($lang, $args, \%settings) if $lang eq "de";
}

sub init_feature_extractor {
  my ($lang, $settings_ref) = @_;

  print STDERR "Initializing feature extractor with settings:\n";

  foreach my $setting (keys %{$settings_ref}) {
    if (exists $settings{$setting}) {
      $settings{$setting} = $settings_ref->{$setting};
      print STDERR $setting."=".$settings_ref->{$setting}."\n";
    }
    else {
      die "Unknown feature extractor setting \"$setting\".\n";
    }
  }

  read_gazetteers($settings_ref->{"support_path"}, $lang);
}

sub extract_features_for_sentence {
  my ($lang, $forms_ref, $lemmas_ref, $tags_ref) = @_;

  # each index contains an array of string features
  my @sentence_features; 

  my $gazetteer_matches_ref;
  if ($lang eq "cs") {
    my @raw_lemmas;
    foreach my $lemma (@{$lemmas_ref}) {
      push @raw_lemmas, raw_lemma($lemma);
    }
    $gazetteer_matches_ref = find_gazetteers(@raw_lemmas);
  }
  else {
    $gazetteer_matches_ref = find_gazetteers(@{$lemmas_ref});
  }

  my $n = @{$forms_ref};
  for (my $i = 0; $i < $n; $i++) {
    my %args;

    # gazetteers
    foreach my $match (keys %{$gazetteer_matches_ref->[$i]}) {
      $args{$match} = 1;
    }

    # current form, lemma, tag
    $args{"Form_0"} = $forms_ref->[$i];
    $args{"Lemma_0"} = $lemmas_ref->[$i];
    $args{"Tag_0"} = $tags_ref->[$i];

    # forms, lemmas and tags in window
    for (my $j = 1; $j <= $window_size{$lang}; $j++) {

      if ($i-$j >= 0) {
        $args{"Form_i-".$j} = $forms_ref->[$i-$j];
        $args{"Lemma_i-".$j} = $lemmas_ref->[$i-$j];
        $args{"Tag_i-".$j} = $tags_ref->[$i-$j];
      }
      else {
        $args{"Form_i-".$j} = EMPTY;
        $args{"Lemma_i-".$j} = EMPTY;
        $args{"Tag_i-".$j} = EMPTY;
      }

      if ($i+$j < $n) {
        $args{"Form_i+".$j} = $forms_ref->[$i+$j];
        $args{"Lemma_i+".$j} = $lemmas_ref->[$i+$j];
        $args{"Tag_i+".$j} = $tags_ref->[$i+$j];
      }
      else {
        $args{"Form_i+".$j} = EMPTY;
        $args{"Lemma_i+".$j} = EMPTY;
        $args{"Tag_i+".$j} = EMPTY;
      }
    }
    my @features = extract_features($lang, \%args);
    push @sentence_features, \@features;
  }
  return \@sentence_features;
}


sub get_type {
  my ($pplabel, $plabel, $label, $nlabel) = @_;
  
  my $type = EMPTY;
  
  if (is_entity($label) and is_entity($nlabel)
      and is_beginning($plabel, $label)
      and is_multiword($label, $nlabel)) {
    $type = "B";
  }

  if (is_entity($plabel) and is_entity($label)
      and is_multiword($plabel, $label)
      and (not is_beginning($label, $nlabel))) {
    $type = "I";
  }

  if (is_entity($plabel) and is_entity($label)
      and is_multiword($plabel, $label)
      and is_last($label, $nlabel)) {
    $type = "L";
  }

  if (not is_entity($label)) {
    $type = "O";
  }

  if (is_entity($label)
      and (not is_multiword($plabel, $label))
      and (not is_multiword($label, $nlabel))) {
    $type = "U";
  }

  $type ne EMPTY or die "Unknown entity type: $pplabel $plabel $label $nlabel.\n";
  return $type;
}

1;
