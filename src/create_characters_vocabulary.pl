#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use Common;
use Characters;

@ARGV >= 3 or die "Usage: ./extract_characters.pl filename characters_filename only_letters\n";
my ($filename, $characters_filename, $only_letters) = @ARGV;
create_characters_vocabulary($filename, $characters_filename, $only_letters);
