package Characters;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

# This is a package for handling characters and character windows (i.e.,
# prefixes and suffixes). It creates a vocabulary and produces 1-of-V
# representations.

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(create_characters_vocabulary read_characters_vocabulary encode_characters_in_token);

# This procedure reads training file in conll-like format and extracts
# characters.
sub create_characters_vocabulary {
  my ($filename, $output_filename, $only_letters) = @_;

  open (my $file, "<", $filename) or die "Cannot open character file \"$filename\".\n";

  print STDERR "Creating character vocabulary from file \"$filename\".\n";

  my %chars;
  my $nchars = 2; # reserve 0 for OOV and 1 for padding character

  foreach my $line(<$file>) {
    chomp $line;
    next if $line eq "";

    my @cols = split / /, $line;
    my ($form, $lemma, $tag) = ($cols[0], $cols[1], $cols[2]);

    for my $token ($form, $lemma, $tag) {
      my @chars = split //, $token;
      for my $char (@chars) {
        next if $only_letters && $char =~ /\W/;
        if (not exists($chars{$char})) {
          $chars{$char} = $nchars; $nchars++;
        }
      }
    }
  }

  close($file);

  open (my $output, ">", $output_filename) or die "Cannot open character vocabulary file \"$output_filename\".\n";

  foreach my $char (keys(%chars)) {
    print $output $char." ".$chars{$char}."\n";
  }
}

sub read_characters_vocabulary {
  my ($filename, $hash_ref) = @_;

  open (my $file, "<", $filename) or die "Cannot open characters vocabulary \"$filename\".\n";

  print STDERR "Reading characters vocabulary from file \"$filename\n";

  my $nchars = 0;

  foreach my $line (<$file>) {
    chomp $line;

    my ($char, $int) = split / /, $line;
    $hash_ref->{$char} = $int;
    $nchars = $int+1 if $int+1 > $nchars;
  }

  return $nchars;
}

sub encode_character {
  my ($char, $chars_ref, $nchars) = @_;

  my @encoded_vector = (0) x $nchars;

  if (not exists $chars_ref->{$char}) {
    @encoded_vector = encode_unknown_character($nchars);
  }
  else {
    @encoded_vector[$chars_ref->{$char}] = 1;
  }

  return @encoded_vector;
}

sub encode_characters_in_token {
  my ($token, $chars_ref, $nchars, $number) = @_;
  my @encoded_characters;
  
  my @chars = split //, $token;

  for (my $i = 0; $i < $number; $i++) {

    if ($i < @chars) {
      push @encoded_characters, encode_character($chars[$i], $chars_ref, $nchars);
    }
    else {
      push @encoded_characters, encode_padding_character($nchars);
    }
    
  }
  
  for (my $i = 1; $i <= $number; $i++) {
    push @encoded_characters, (($i > @chars) ? encode_padding_character($nchars) : encode_character($chars[-$i], $chars_ref, $nchars));
    
  }

  return join(" ", @encoded_characters);
}

sub encode_unknown_character {
  my ($nchars) = @_;
  
  my @encoded_vector = (0) x $nchars;
  $encoded_vector[0] = 1;

  return @encoded_vector;
}

sub encode_padding_character {
  my ($nchars) = @_;

  my @encoded_vector = (0) x $nchars;
  $encoded_vector[1] = 1;

  return @encoded_vector;
}

1;
