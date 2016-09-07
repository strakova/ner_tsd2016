package WordEmbeddings;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(read_word_embeddings get_word_embedding get_embedding_dimension subset_embeddings);

# Subsets word embeddings by given filenames with data.
sub subset_embeddings {
  my ($filenames_ref, $col, $embeddings_filename) = @_;

  print STDERR "Subsetting word embeddings (column $col) for files:\n";

  my %words;
  $words{"<unk>"} = 1;
  $words{"</s>"} = 1;
  foreach my $filename (@{$filenames_ref}) {
    print STDERR "$filename\n";
    open (my $file, "<", $filename) or die "Cannot open file \"$filename\".\n";

    foreach my $line (<$file>) {
      chomp $line;
      next if $line eq "";
      my @cols = split / /, $line;
      my $ncols = @cols;
      $col < $ncols or die "File \"$filename\" has only $ncols columns, requested $col.\n";
      my $word = $cols[$col-1];
      $words{lc($word)} = 1;
    }

    close($file);
  }

  my $N = (keys %words);

  open (my $file, "<", $embeddings_filename) or die "Cannot open embeddings file \"$embeddings_filename\".\n";
  
  my $first_line = <$file>;
  chomp $first_line;
  my ($dummy, $d) = split / /, $first_line; # number of lines and dimension of vectors
  print "$N $d\n";

  foreach my $line (<$file>) {
    chomp $line;
    my @cols = split / /, $line;
    my $word = shift @cols;
    print $line."\n" if exists $words{lc($word)};
  }
}

sub read_word_embeddings {
  my ($filename, $hash_ref, $use_nil, $use_unk) = @_;

  open (my $file, "<", $filename) or die "Cannot open word embeddings file \"$filename\".\n";

  print STDERR "Reading word embeddings from file \"$filename\".\n";

  my $first_line = <$file>;
  chomp $first_line;
  my ($N, $d) = split / /, $first_line; # number of lines and dimension of vectors

  $hash_ref->{"<unk>"} = join " ", (0) x $d;
  $hash_ref->{"</s>"} = join " ", (0) x $d;

  foreach my $line (<$file>) {
    chomp $line;
    my @cols = split / /, $line;
    my $word = shift @cols;
    next if !$use_unk && $word eq "<unk>";
    next if !$use_nil && $word eq "</s>";
    $hash_ref->{$word} = join(" ", @cols) if exists $hash_ref->{$word};
  }

  # remove words without embeddings
  foreach my $k (keys %{$hash_ref}) {
    delete $hash_ref->{$k} if $hash_ref->{$k} eq "";
  }
}

sub get_word_embedding {
  my ($word, $hash_ref) = @_;

  return $hash_ref->{$word} if exists $hash_ref->{$word};
  return $hash_ref->{"<unk>"};
}

sub get_embedding_dimension {
  my ($hash_ref) = @_;

  die "Hash with embeddings does not contain embedding for unknown word \"<unk>\" !\n" if not exists $hash_ref->{"<unk>"};

  my @embedding = split " ", $hash_ref->{"<unk>"};
  my $embedding_dimension = @embedding;

  return $embedding_dimension;
}

1;
