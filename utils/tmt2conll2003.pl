#!/usr/bin/perl

# This script converts tmt files in Czech Named Entity Corpus 1.0 to CoNLL
# files.

use strict;
use warnings;
use open qw{:utf8 :std};

our %CLASSES = ( 'ps' => 1, 'pf' => 1, 'p_' => 1, 'pc' => 1, 
                 'pp' => 1, 'pm' => 1, 'pd' => 1, 'pb' => 1,
                 'gu' => 1, 'gc' => 1, 'gr' => 1, 'gs' => 1, 
                 'gq' => 1, 'gh' => 1, 'gl' => 1, 'gt' => 1,
                 'g_' => 1, 'gp' => 1,
                 'ic' => 1, 'if' => 1, 'io' => 1, 'ia' => 1, 
                 'i_' => 1,
                 'oa' => 1, 'op' => 1, 'om' => 1, 'oe' => 1,
                 'o_' => 1, 'or' => 1, 'oc' => 1,
                 'th' => 1, 'ty' => 1, 'tm' => 1, 'td' => 1,
                 'ti' => 1, 'tf' => 1,
                 'mn' => 1, 'mt' => 1, 'mr' => 1,
                 'ah' => 1, 'at' => 1, 'az' => 1, );

my ($inside_M_tree, $inside_N_tree, $inside_m_rf) = (0, 0, 0);
my ($id, $form, $lemma, $tag, $ne_type)  = ("", "", "", "", "");
my @lines;
my %ne_types;
my $entity_beginning = 0; # first entity word
while(<>) {
  chomp;

  $inside_M_tree = 1 if /<SCzechM/;
  $inside_M_tree = 0 if /<\/SCzechM>/;
  $inside_N_tree = 1 if /<SCzechN/;
  $inside_N_tree = 0 if /<\/SCzechN/;
  
  # size of inside_m_rf shows depth of included entity
  if (/<m\.rf>/) { # named entity starts here
    $inside_m_rf++;
    $entity_beginning = 1 if $inside_m_rf == 1;
  }
  if (/<\/m\.rf>/) { # named entity ends here
    $inside_m_rf-- if exists $CLASSES{$ne_type};
  }

  if (/<LM id=\"(.*)\">/) { $id = $1;};
  
  # M tree
  if (/<form>(.*)<\/form>/) { $form = $1; }
  if (/<lemma>(.*)<\/lemma>/) { $lemma = $1; }
  if (/<tag>(.*)<\/tag>/) { $tag = $1; }
  if (/<\/LM>/ and $inside_M_tree) {
    push @lines, $id." ".$form." ".$lemma." ".$tag." _";
  }

  # N tree
  if (/<ne_type>(.*)<\/ne_type>/) {
    $ne_type = $1;

    # ignore weird and container classes
    if (not exists $CLASSES{$ne_type}) {
      $inside_m_rf--;
      $entity_beginning = 0;
    }

  }

  # entity found
  if (/<LM>(.*)<\/LM>/ and $inside_m_rf == 1) { # only in first level entities
    my $m_rf = $1;
    $ne_types{$m_rf} = ($entity_beginning == 1 ? "B-" : "I-") . $ne_type if not exists $ne_types{$m_rf};
    $entity_beginning = 0;
  }
  
  # print
  if (/<\/SCzechN/) {
    my $prev_raw_type = "O";
    foreach my $line (@lines) {
      my ($id, $form, $lemma, $tag, $chunk) = split / /, $line;
      my $type = (exists $ne_types{$id} ? $ne_types{$id} : "O");
      
      # If previous was not entity or was different type, replace B- with I- (CoNLL2003 format).
      if ($type eq "O") {
        $prev_raw_type = "O";
      }
      else {
        $type =~ /(.*)-(.*)/;
        my ($beginning, $raw_type) = ($1, $2);
        if ($beginning eq "B" and $prev_raw_type ne $raw_type) {
          $type = "I-".$raw_type;
        }
        $prev_raw_type = $raw_type;
      }
      
      print join(" ", ($form, $lemma, $tag, "_", $type))."\n";
    }
    print "\n";
    @lines = ();
  }
}
