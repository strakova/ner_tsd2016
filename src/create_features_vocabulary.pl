#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use FeatureEncoder;

use Getopt::Long;

my $usage="Usage: ./create_features_vocabulary.pl \
            --data=data filename \
            --language=[cs|en] \
            --support_path=support data path (gazetteers, Brown clusters) \
            --use_forms \
            --use_lemmas \
            --use_tags \
            --use_prefixes \
            --use_suffixes\n";

my $data_filename = "";
my $language = "";
my $support_path = "";
my $use_forms = 0;
my $use_lemmas = 0;
my $use_tags = 0;
my $use_prefixes = 0;
my $use_suffixes = 0;
GetOptions( "data=s"            => \$data_filename,
            "language=s"        => \$language,
            "support_path=s"      => \$support_path,
            "use_forms"         => \$use_forms,
            "use_lemmas"        => \$use_lemmas,
            "use_tags"          => \$use_tags,
            "use_prefixes"      => \$use_prefixes,
            "use_suffixes"      => \$use_suffixes,
          )
  or die ("Error in commandline arugments\n" . $usage);

# sanity check
$data_filename ne "" or die "Missing argument --data\n".$usage;
$language ne "" or die "Missing argument --language\n".$usage;
$support_path ne "" or die "Missing argument --support_path\n".$usage;

# feature extractor settings
my %settings = ( "use_forms" => $use_forms,
                 "use_lemmas" => $use_lemmas,
                 "use_tags" => $use_tags,
                 "use_prefixes" => $use_prefixes,
                 "use_suffixes" => $use_suffixes,
                 "support_path" => $support_path,
               );

create_features_vocabulary($data_filename, $language, \%settings);
