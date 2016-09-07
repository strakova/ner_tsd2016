package EnglishFeatureExtractor;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(extract_English_features);

use Common;

sub extract_English_features {
  my ($args_ref, $settings_ref) = @_;

  my @features;
  my $form = $args_ref->{"Form_0"};

  foreach my $k (sort keys %{$args_ref}) {
    my $v = $args_ref->{$k};

    ### FORM, LEMMA AND TAG
    if ($settings_ref->{"use_forms"}) {
      push @features, $k.DELIM.$v if $k =~ /^Form/;

      # Lowercase and uppercase
      push @features, "Lowercase_$k".DELIM.lc($v) if $k =~ /^Form/;
      push @features, "Uppercase_$k".DELIM.uc($v) if $k =~ /^Form/;
      push @features, "Token_length_$k".DELIM.length($v) if $k =~ /^Form/;
    }
    if ($settings_ref->{"use_lemmas"}) {
      push @features, $k.DELIM.$v if $k =~ /^Lemma/;
    }
    if ($settings_ref->{"use_tags"}) {
      push @features, $k.DELIM.$v if $k =~ /^Tag/;
      push @features, "SimplifiedPOS_$k".DELIM.substr($v, 0, 1) if $k =~ /^Tag/;
    }

    # ORTHOGRAPHIC FEATURES
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
    }

    ### GAZETTEERS
    push @features, $k if $k =~ /^Gazetteer/;
  }
 
  return @features;
}

1;
