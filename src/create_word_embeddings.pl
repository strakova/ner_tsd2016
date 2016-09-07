#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use WordEmbeddings;

use Getopt::Long;

my $usage="Usage: ./create_word_embeddings.pl \
            --filenames=filename1,filename2,...,filenameN \
            --column=columns \
            --embeddings=embeddings filename\n";

my $filenames = "";
my $column = -1;
my $embeddings = "";
GetOptions( "filenames=s"       => \$filenames,
            "column=i"          => \$column,
            "embeddings=s"      => \$embeddings,
          )
  or die ("Error in commandline arguments\n" . $usage);

# sanity check
$filenames ne "" or die "Missing argument --filenames\n".$usage;
$column != -1 or die "Missing argument --column\n".$usage;
$embeddings ne "" or die "Missing argument --embeddings\n".$usage;

# feature extractor settings
my @filenames_array = split /,/, $filenames;

subset_embeddings(\@filenames_array, $column, $embeddings);
