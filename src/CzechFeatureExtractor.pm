package CzechFeatureExtractor;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;

use Common;
use Gazetteers;

our @ISA = qw(Exporter);
our @EXPORT = qw(extract_Czech_features raw_lemma);

sub raw_lemma {
  my ($lemma) = @_;
  $lemma =~ /^([^-_`]*)/;
  return $1;
}

sub _is_day_number($) {
    my $token = shift;
    return ($token =~ /^[1-9]$/ || $token =~ /^[12][[:digit:]]$/ || $token =~ /^3[01]$/ ) ? 1 : 0;
}

sub _is_month_number($) {
    my $token = shift;
    return ($token =~ /^[1-9]$/ || $token =~ /^1[12]$/) ? 1 : 0;
}

sub _is_year_number($) {
    my $token = shift;
    return ($token =~ /^[12][[:digit:]][[:digit:]][[:digit:]]$/ ) ? 1 : 0;
}

sub extract_Czech_features {
  my ($args, $settings_ref) = @_;

  my @features;

  foreach my $k (sort keys %{$args}) {
    my $v = $args->{$k};

    ### FORM, LEMMA, TAG AND CHUNK IN WINDOW
    if ($settings_ref->{"use_forms"}) {
      push @features, $k."/".$v if $k =~ /^Form_/;
    }
    if ($settings_ref->{"use_lemmas"}) {
      push @features, $k."/".$v if $k =~ /^Lemma_/;
      push @features, "Raw".$k."/".raw_lemma($v) if $k =~ /^Lemma_/;
    }
    if ($settings_ref->{"use_tags"}) {
      push @features, $k."/".$v if $k =~ /^Tag_/;
    }

    ### ORTHOGRAPHIC FEATURES
    if ($k eq "L_0") {
      my $raw_lemma = raw_lemma($v);

      # Capitalization
      push @features, "FirstCap" if $raw_lemma =~ /^[[:upper:]]/;
      push @features, "AllCap" if $raw_lemma =~ /^[[:upper:]]*$/;
      push @features, "MixedCap" if $raw_lemma != /^[[:upper:]]*$/ and $raw_lemma !~ /^[[:lower:]]*$/;

      # Punctuation
      push @features, "EndsWithPeriod" if $raw_lemma =~ /\.$/;
      push @features, "InternalPeriod" if $raw_lemma =~ /\./;
      push @features, "InternalApostrophe" if $raw_lemma =~ /\'/;
      push @features, "InternalHyphen" if $raw_lemma =~ /-/;
      push @features, "InternalAmp" if $raw_lemma =~ /&/;
      push @features, "InternalPunctuation" if $raw_lemma =~ /[\.\,\-&]/;

      # Lowercase and uppercase
      push @features, "Lowercase_".lc($raw_lemma);
      push @features, "Uppercase_".uc($raw_lemma);
      push @features, "Token_length_".length($raw_lemma);
    }

    ### ORTHOGRAPHIC FEATURES IN WINDOW
    push @features, "FirstCapForm_$k" if $k =~ /^Form_/ and $v =~ /^[[:upper:]]/;
    push @features, "AllCapLemma_$k" if $k =~ /^Lemma_/ and raw_lemma($v) =~ /^[[:upper:]]*$/;
    
    ### GAZETTEERS
    push @features, $k if $k =~ /^Gazetteer/;
  }

  my $form = $args->{"Form_0"};
  my $raw_lemma = raw_lemma($args->{"Lemma_0"});

  ### PREFIXES, SUFFIXES

  # suffixes
  if ($settings_ref->{"use_suffixes"}) {
    my @suffixes = get_suffixes($form);
    for (my $i = 0; $i < @suffixes; $i++) {
      push @features, "Suffix_".$i."_".$suffixes[$i];
    }
  }

  # prefixes
  if ($settings_ref->{"use_prefixes"}) {
    my @prefixes = get_prefixes($form);
    for (my $i = 0; $i < @prefixes; $i++) {
      push @features, "Prefix_".$i."_".$prefixes[$i];
    }
  }

  ### CZECH FEATURES
  
  # Hint in lemma
  for my $hint (qw/Y S E G K R m H U L J g c y b u w p z o/) {
    push @features, $hint."_in_Lemma" if $args->{"Lemma_0"} =~ /_;$hint/;
  }

  # tag prefixes and positions
  if ($settings_ref->{"use_tags"}) {
    # tag prefixes
    my @tag_prefixes = get_prefixes($args->{"Tag_0"});
    for (my $i = 0; $i < @tag_prefixes; $i++) {
      push @features, "TagPrefix_$i/".$tag_prefixes[$i];
    }
 
    # tag positions:
    my @tag_positions = split //, $args->{"Tag_0"};
    for(my $i = 0; $i < @tag_positions; $i++) {
      push @features, "TagPosition_$i/".$tag_positions[$i] if $tag_positions[$i] ne "-"; 
    }
  }

  # day, month, year, time
  push @features, "IsDayNumber" if _is_day_number($raw_lemma);
  push @features, "IsMonthNumber" if _is_month_number($raw_lemma);
  push @features, "IsYearNumber" if _is_year_number($raw_lemma);
  push @features, "IsTime" if $raw_lemma =~ /^([01]?[0-9]|2[0-3])[.:][0-5][0-9]([ap]m)?$/;

  return @features;
}

1;
