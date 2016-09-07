package Gazetteers;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

use Common;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(read_gaz_from_file gazetteer_prefix_match gazetteer_exact_match read_gazetteers is_gazetteer_beginning find_gazetteers count_gazetteers);

our %gazetteers;
our %MAX_GAZETTEER_LENGTH = ("de" => 4, "cs" => 4, "en" => 3);
our $lang;
our $gaz_path;
our $wiki_path;

sub read_gazetteers {
  my ($support_path, $lang) = @_;

  $gaz_path = $support_path . "/gazetteers/";
  $wiki_path = $support_path . "/wikipedia/";

  if ($lang eq "en") {
    # Manually collected gazetteers
    $gazetteers{"CountryGaz"}   = read_gaz_from_file(
                                    $gaz_path. "$lang/countries.$lang");
    $gazetteers{"CityGaz"}      = read_gaz_from_file(
                                    $gaz_path. "$lang/cities.$lang");
    $gazetteers{"FirstNameGaz"} = read_gaz_from_file(
                                    $gaz_path. "$lang/first_names.$lang");
    $gazetteers{"LastNameGaz"}  = read_gaz_from_file(
                                    $gaz_path. "$lang/last_names.$lang");
    $gazetteers{"PERGaz"}       = read_gaz_from_file(
                                    $gaz_path. "$lang/PER_gazetteers.$lang");
    $gazetteers{"LOCGaz"}       = read_gaz_from_file(
                                    $gaz_path. "$lang/LOC_gazetteers.$lang");
    $gazetteers{"ORGGaz"}       = read_gaz_from_file(
                                    $gaz_path. "$lang/ORG_gazetteers.$lang");
    
    # Wikipedia gazetteers
    $gazetteers{"WikiPersonCat"}        = read_gaz_from_file(
                                            $wiki_path. "$lang/people.txt");
    $gazetteers{"WikiLocationCat"}      = read_gaz_from_file(
                                            $wiki_path. "$lang/locations.txt");
    $gazetteers{"WikiOrganizationCat"}  = read_gaz_from_file(
                                            $wiki_path. "$lang/organizations.txt");
    $gazetteers{"WikiNamedObjectCat"}   = read_gaz_from_file(
                                            $wiki_path. "$lang/named_objects.txt");
    $gazetteers{"WikiArtWorkCat"}       = read_gaz_from_file(
                                            $wiki_path. "$lang/art_work.txt");
    $gazetteers{"WikiFilmCat"}          = read_gaz_from_file(
                                            $wiki_path. "$lang/films.txt");
    $gazetteers{"WikiSongsCat"}         = read_gaz_from_file(
                                            $wiki_path. "$lang/songs.txt");

    # Stopwords
    $gazetteers{"StopWords1"}           = read_gaz_from_file(
                                            $gaz_path. "$lang/stopwords_1.$lang");
    $gazetteers{"StopWordsMySQL"}       = read_gaz_from_file(
                                            $gaz_path. "$lang/stopwords_mysql.$lang");

    # Pronouns
    $gazetteers{"FirstPersonPronouns"}  = read_gaz_from_file(
                                            $gaz_path. "$lang/first_person_pronouns.$lang");
    $gazetteers{"PersonPronouns"}       = read_gaz_from_file(
                                            $gaz_path. "$lang/person_pronouns.$lang");
    
    # English capitalized words
    $gazetteers{"DayGaz"}               = read_gaz_from_file(
                                            $gaz_path. "$lang/days.$lang");
    $gazetteers{"MonthGaz"}             = read_gaz_from_file(
                                            $gaz_path. "$lang/months.$lang");

    # Gazetteers from CoNLL2003
    $gazetteers{"ned.list.LOC"} = read_gaz_from_file($gaz_path. "$lang/ned.list.LOC");
    $gazetteers{"ned.list.ORG"} = read_gaz_from_file($gaz_path. "$lang/ned.list.ORG");
    $gazetteers{"ned.list.PER"} = read_gaz_from_file($gaz_path. "$lang/ned.list.PER");
    $gazetteers{"ned.list.MISC"} = read_gaz_from_file($gaz_path. "$lang/ned.list.MISC");

  }

  if ($lang eq "cs") {
    $gazetteers{"CityGaz"}        = read_gaz_from_file($gaz_path."$lang/cities.cs");
    $gazetteers{"ClubGaz"}        = read_gaz_from_file($gaz_path."$lang/clubs.cs");
    $gazetteers{"CountryGaz"}     = read_gaz_from_file($gaz_path."$lang/countries.cs");
    $gazetteers{"FirstNameGaz"}   = read_gaz_from_file($gaz_path."$lang/first_names.".$lang);
    $gazetteers{"InstitutionGaz"} = read_gaz_from_file($gaz_path."$lang/institutions.".$lang);
    $gazetteers{"LastNameGaz"}    = read_gaz_from_file($gaz_path."$lang/last_names.".$lang);
    $gazetteers{"MonthGaz"}       = read_gaz_from_file($gaz_path."$lang/months.".$lang);
    $gazetteers{"ObjectGaz"}      = read_gaz_from_file($gaz_path."$lang/objects.".$lang);
    $gazetteers{"PostCodeGaz"}    = read_gaz_from_file($gaz_path."$lang/psc.$lang");
    $gazetteers{"StreetGaz"}      = read_gaz_from_file($gaz_path."$lang/streets.$lang");
#    $gazetteers{"FilmGaz"}      = read_gaz_from_file($gaz_path."$lang/films.$lang");

    # Wikipedia gazetteers
    $gazetteers{"WikiPersonCat"}        = read_gaz_from_file(
                                            $wiki_path. "$lang/people.txt");
    $gazetteers{"WikiLocationCat"}      = read_gaz_from_file(
                                            $wiki_path. "$lang/locations.txt");
    $gazetteers{"WikiOrganizationCat"}  = read_gaz_from_file(
                                            $wiki_path. "$lang/organizations.txt");
    $gazetteers{"WikiNamedObjectCat"}   = read_gaz_from_file(
                                            $wiki_path. "$lang/named_objects.txt");
    $gazetteers{"WikiArtWorkCat"}       = read_gaz_from_file(
                                            $wiki_path. "$lang/art_work.txt");
    $gazetteers{"WikiFilmCat"}          = read_gaz_from_file(
                                            $wiki_path. "$lang/films.txt");
    $gazetteers{"WikiSongsCat"}         = read_gaz_from_file(
                                            $wiki_path. "$lang/songs.txt");

  }

  if ($lang eq "de") {
    $gazetteers{"FirstNameGaz"}  = read_gaz_from_file($gaz_path."first_names.".$lang);
    $gazetteers{"LastNameGaz"}   = read_gaz_from_file($gaz_path."last_names.".$lang);
    $gazetteers{"CityGaz"}        = read_gaz_from_file($gaz_path."cities.all");
  }
}

sub read_gaz_from_file {
  my ($filename) = @_;

  my %gazetteers;
  open (my $fr, "<", $filename) or die "Cannot open gazetteers file \"$filename\".\n";
  print STDERR "Reading gazetteers from file \"$filename\".\n";
  while (<$fr>) {
    chomp;
    $gazetteers{$_} = 1;
  }

  return \%gazetteers;
}

sub gazetteer_prefix_match {
  my ($gazetteer_ref, @words) = @_;

  my $candidate = "";
  for (my $i = 0; $i < $MAX_GAZETTEER_LENGTH{$lang} and $i < @words; $i++) {
    $candidate .= " " if $i > 0;
    $candidate .= $words[$i];

    my $match = gazetteer_exact_match($gazetteer_ref, $candidate);
    return $match if $match;
  }

  return 0;
}

sub gazetteer_exact_match {
  my ($gazetteer_ref, $word) = @_;

  return (exists $gazetteer_ref->{$word} ? $gazetteer_ref->{$word} : 0);
}

sub is_gazetteer_beginning {
  my (@words) = @_;

  my @matches;
  foreach my $gazetteer_category (keys %gazetteers) {
    push @matches, $gazetteer_category if gazetteer_prefix_match($gazetteers{$gazetteer_category}, @words);
  }

  return @matches;
}

sub count_gazetteers {
  my $n_lists = keys %gazetteers;
  print "Number of lists: $n_lists\n";

  my $sum = 0;
  foreach my $gazetteer_category (keys %gazetteers) {
    foreach my $gazetteer (keys %{$gazetteers{$gazetteer_category}}) {
      $sum++;
    }
  }

  print "Number of gazetteers: $sum\n";
}

sub find_gazetteers {
  my (@forms) = @_;

  my @matches;
  for (my $i = 0; $i < @forms; $i++) {
    $matches[$i] = {};
  }

  foreach my $gazetteer_category (keys %gazetteers) {
    for (my $i = 0; $i < @forms; $i++) {
      my $was_match = 0;
      
      for (my $j = 7; $j >= 0; $j--) {
        next if $i+$j >= @forms;
        my $candidate .= join(" ", @forms[$i..$i+$j]);
        my $match = gazetteer_exact_match($gazetteers{$gazetteer_category}, $candidate);
 
        if ($match == 1) {
          $was_match = 1;
          my $dummy = $i+$j;

          # Gazetteer BI and B-X, I-X
          $matches[$i]->{"Gazetteer:B-$gazetteer_category"} = 1;
          $matches[$i]->{"IsGazetteer:B"} = 1;
          for (my $k = $i + 1; $k <= $i + $j; $k++) {
            $matches[$k]->{"Gazetteer:I-$gazetteer_category"} = 1;
            $matches[$k]->{"IsGazetteer:I"} = 1;
          }

          # Gazetteer X
          for (my $k = $i; $k <= $i + $j; $k++) {
            $matches[$k]->{"Gazetteer:$gazetteer_category"} = 1;
          }
          $i = $i+$j+1;
          last;
        }
      }
    }
  }

  return \@matches;
}

1;
