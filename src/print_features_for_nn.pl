#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use Common;
use WordEmbeddings;
use Characters;
use FeatureExtractor;
use CzechFeatureExtractor;
use VectorEncoder;
use FeatureEncoder;
use BrownClusters;
use CharacterLevelEmbeddings;

use Getopt::Long;

# Constants
my $usage="Usage:./print_features_for_nn.pl \
            --data=data filename \
            --corpus=[cnec1.0|cnec1.1|cnec2.0|cnec2.0_konkol|cnec1.1_konkol|conll2003_en] \
            --language=[cs|en] \
            --support_path=support data path (gazetteers, Brown clusters) \
            --forms=form embeddings filename \
            --lemmas=lemma embeddings filename \
            --tags=tag embeddings filename \
            --features=features vocabulary filename \
            --characters=character vocabulary filename \
            --characters_form=nr of form chars from beginning and end \
            --characters_lemma=nr of lemma chars from beginning and end \
            --characters_tag=nr of tag chars from beginning and end \
            --cle=character vocabulary file \
            --cle_maxlen=maximal word length \
            --cle_form=use cle for forms \
            --cle_lemma=use cle for lemmas \
            --window_size=embeddings window size(default=2) \
            --use_brown_clusters \
            --use_nil=[0|1] \
            --use_unk=[0|1]\n";

# read commandline arguments or print usage
my $data_filename = "";
my $corpus = "";
my $language = "";
my $support_path = "";
my $form_embeddings_filename = "";
my $lemma_embeddings_filename = "";
my $tag_embeddings_filename ="";
my $characters_vocabulary_filename = "";
my $characters_form = 2;
my $characters_lemma = 2;
my $characters_tag = 2;
my ($cle, $cle_maxlen, $cle_form, $cle_lemma) = ("", 20, 0, 0);
my $features_vocabulary_filename = "";
my $window_size = 2;
my $use_brown_clusters = 0;
my $use_nil = 1;
my $use_unk = 0;
GetOptions( "data=s"            => \$data_filename,     
            "corpus=s"          => \$corpus,            
            "language=s"        => \$language,
            "support_path=s"    => \$support_path,
            "forms:s"           => \$form_embeddings_filename,  
            "lemmas:s"          => \$lemma_embeddings_filename, 
            "tags:s"            => \$tag_embeddings_filename,   
            "characters:s"      => \$characters_vocabulary_filename,   
            "characters_form:i" => \$characters_form,   
            "characters_lemma:i"=> \$characters_lemma,   
            "characters_tag:i"  => \$characters_tag,   
            "cle:s"             => \$cle,
            "cle_maxlen:i"      => \$cle_maxlen,
            "cle_form:i"        => \$cle_form,
            "cle_lemma:i"       => \$cle_lemma,
            "features:s"        => \$features_vocabulary_filename,    
            "window_size=i"     => \$window_size,       
            "use_brown_clusters" => \$use_brown_clusters,
            "use_nil=i"         => \$use_nil,
            "use_unk=i"         => \$use_unk,
          )
  or die("Error in commandline arguments\n" . $usage);

# sanity check
$data_filename ne "" or die "Missing argument --data\n".$usage;
$corpus ne "" or die "Missing argument --corpus\n".$usage;
$language ne "" or die "Missing argument --language\n".$usage;
$support_path ne "" or die "Missing argument --support_path\n".$usage;

# find which classification features to use
my $form_embeddings = ($form_embeddings_filename ne "");
my $lemma_embeddings = ($lemma_embeddings_filename ne "");
my $tag_embeddings = ($tag_embeddings_filename ne "");
my $characters = ($characters_vocabulary_filename ne "");
my $features = ($features_vocabulary_filename ne "");

# read training data file
open (my $file, "<", $data_filename) or die "Cannot open training file $data_filename.\n";
my @lines = map { chomp; $_ } <$file>;
push @lines, "" if !@lines || $lines[-1] ne "";

my $instances = 0;
for (my $i = 0; $i < @lines; $i++) {
  next if ($lines[$i] eq "");
  $instances++;
}

# Brown clusters

my $nbrownclusters = 0;
if ($use_brown_clusters) {
  $nbrownclusters = read_brown_clusters($language, $support_path);
}

# read word embeddings
my %form_embeddings_map = ();
my %lemma_embeddings_map = ();
my %tag_embeddings_map = ();

for (my $i = 0; $i < @lines; $i++) {
  next if ($lines[$i] eq "");
 
  my ($form, $lemma, $tag) = get_ith_line($i, \@lines);        
  $form_embeddings_map{$form} = "";
  $lemma_embeddings_map{$lemma} = "";
  $tag_embeddings_map{$tag} = "";
}

if ($form_embeddings) {
  read_word_embeddings($form_embeddings_filename, \%form_embeddings_map, $use_nil, $use_unk);
}
if ($lemma_embeddings) {
  read_word_embeddings($lemma_embeddings_filename, \%lemma_embeddings_map, $use_nil, $use_unk);
}
if ($tag_embeddings) {
  read_word_embeddings($tag_embeddings_filename, \%tag_embeddings_map, $use_nil, $use_unk);
}

# read characters
my %characters = ();
my $nchars = 0;
if ($characters) {
  $nchars = read_characters_vocabulary($characters_vocabulary_filename, \%characters);
}

# read and generate cle
my %cle;
my $cle_nchars = 0;
if ($cle) {
  $cle_nchars = cle_read_vocabulary(\%cle, $cle);

  cle_embedding(\%cle, "</s>");
  for (my $i = 0; $i < @lines; $i++) {
    next if ($lines[$i] eq "");

    my ($form, $lemma) = get_ith_line($i, \@lines);
    $cle_form && cle_embedding(\%cle, $form);
    $cle_lemma && cle_embedding(\%cle, $lemma);
  }
}

# feature extractor settings
my %settings;
$settings{"use_forms"} = 0 if $form_embeddings;
$settings{"use_lemmas"} = 0 if $lemma_embeddings;
$settings{"use_tags"} = 0 if $tag_embeddings;
$settings{"use_prefixes"} = 0 if $characters;
$settings{"use_suffixes"} = 0 if $characters;
$settings{"support_path"} = $support_path;

# read features
my $nfeatures = 0;
if ($features) {
  init_feature_extractor($language, \%settings);
  $nfeatures = read_features_vocabulary($features_vocabulary_filename);
}

# print classification features

print STDERR "Printing classification features for file \"$data_filename\".\n";

my @forms = ();
my @lemmas = ();
my @tags = ();
my @labels = ();
my $n = @lines;
for (my $i = 0; $i < @lines; $i++) {
  # print vector dimensions to first line
  if ($i == 0) {
    my $word_feature_vector_size = 0;
    $word_feature_vector_size += get_embedding_dimension(\%form_embeddings_map) if $form_embeddings;
    $word_feature_vector_size += get_embedding_dimension(\%lemma_embeddings_map) if $lemma_embeddings;
    $word_feature_vector_size += get_embedding_dimension(\%tag_embeddings_map) if $tag_embeddings;
    my $window_feature_vector_size = $window_size * 2 * $word_feature_vector_size + $word_feature_vector_size;

    my $characters_vector_size = $characters ? $nchars * 2 * ($characters_form + $characters_lemma + $characters_tag) : 0;
    my $feature_vector_size = $features ? $nfeatures : 0;
    my $brown_clusters_vector_size = $use_brown_clusters ? $nbrownclusters : 0;
    my $input_layer_size = $window_feature_vector_size + $characters_vector_size + $feature_vector_size + $nbrownclusters;
    
    my $label_vector_size = get_label_vector_size($corpus);

    if ($input_layer_size == 0) {
      die "No classification features to print (empty input layer). Did you specify any of form, lemma, tag embeddings, classification features or characters?";
    }
    if (not $cle) {
      print "$input_layer_size 0 0 0 0 $label_vector_size $instances\n";
    } else {
      my @cle_embeddings = cle_embeddings(\%cle);
      my ($cle_per_instance, $cle_embeddings) = ((2 * $window_size + 1) * (($cle_form ? 1 : 0) + ($cle_lemma ? 1 : 0)) , scalar(@cle_embeddings));
      print "$input_layer_size $cle_per_instance $cle_embeddings $cle_nchars $cle_maxlen $label_vector_size $instances\n";

      foreach my $cle_embedding (@cle_embeddings) {
        my @chars = @{$cle_embedding};
        if (@chars >= $cle_maxlen) {
          @chars = (@chars[0..int($cle_maxlen/2)-1], @chars[@chars-int($cle_maxlen/2)..$#chars]);
        } else {
          push @chars, (0) x ($cle_maxlen - @chars);
        }
        print join(" ", scalar(@chars), (map {$_ + 1} @chars)) . "\n";
      }
    }
  }

  # empty line = end of sentence
  if ($lines[$i] eq "") {
    my $sentence_features_ref = extract_features_for_sentence($language, \@forms, \@lemmas, \@tags) if $features;
    my $sentence_size = @forms;
    for (my $j = 0; $j < @forms; $j++) {
      # get label
      print "$labels[$j]";

      # print cle
      if ($cle) {
        for (my $k = $j-$window_size; $k <= $j+$window_size; $k++) {
          print " " . (1 + cle_embedding(\%cle, $k >=0 && $k < @forms ? $forms[$k] : "</s>")) if $cle_form;
          print " " . (1 + cle_embedding(\%cle, $k >=0 && $k < @lemmas ? $lemmas[$k] : "</s>")) if $cle_lemma;
        }
      }

      # get characters
      if ($characters) {
        print " ".encode_characters_in_token($forms[$j], \%characters, $nchars, $characters_form) if $characters_form > 0;
        print " ".encode_characters_in_token($lemmas[$j], \%characters, $nchars, $characters_lemma) if $characters_lemma > 0;
        print " ".encode_characters_in_token($tags[$j], \%characters, $nchars, $characters_tag) if $characters_tag > 0;
      }

      # get feature vector for this word
      if ($features) {
        my $features_ref = $sentence_features_ref->[$j]; 
        print " ".features_2_vector(@{$features_ref}); 
      }

      # get Brown clusters for this word
      if ($use_brown_clusters) {
        if ($language eq "cs") {
          my $raw_lemma = raw_lemma($lemmas[$j]);
          print " ".word_2_brown_cluster_vector($raw_lemma);
        }
        else {
          print " ".word_2_brown_cluster_vector($lemmas[$j]);
        }
      }
    
      # get form, lemma and tag embeddings in window
      for (my $k = $j-$window_size; $k <= $j+$window_size; $k++) {
        if ($form_embeddings) {
          my $form = $k >=0 && $k < @forms ? $forms[$k] : "</s>";
          my $form_embedding = get_word_embedding(lc($form), \%form_embeddings_map);
          print " $form_embedding";
        }
        if ($lemma_embeddings) {
          my $lemma = $k >=0 && $k < @lemmas ? $lemmas[$k] : "</s>";
          my $lemma_embedding = get_word_embedding($lemma, \%lemma_embeddings_map);
          print " $lemma_embedding";
        }
        if ($tag_embeddings) {
          my $tag = $k >= 0 && $k < @tags ? $tags[$k] : "</s>";
          my $tag_embedding = get_word_embedding($tag, \%tag_embeddings_map);
          print " $tag_embedding";
        }
      }

      print "\n";
    }
   
    # clean buffers
    @forms = ();
    @lemmas = ();
    @tags = ();
    @labels = ();
  }

  else {
    # get label
    my $pplabel = get_ith_label($i-2, \@lines);
    my $plabel = get_ith_label($i-1, \@lines);
    my $label = get_ith_label($i, \@lines);
    my $nlabel = get_ith_label($i+1, \@lines);

    my $type = get_type($pplabel, $plabel, $label, $nlabel);
    my $label_bilou = $type =~ /[OIL]/ ? $type : $type."-".raw_label($label);
    my $label_bilou_int = label_2_int($corpus, $label_bilou);
    push @labels, $label_bilou_int;
 
    # get form, lemma and tag
    my ($form, $lemma, $tag) = get_ith_line($i, \@lines);
    push @forms, $form;
    push @lemmas, $lemma;
    push @tags, $tag;
    
    print STDERR "Instances: $i / $instances\n" if $i % 10000 == 0;
  }
}
