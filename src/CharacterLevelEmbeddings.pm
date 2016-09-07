package CharacterLevelEmbeddings;
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(cle_embedding cle_embeddings cle_read_vocabulary);

sub cle_embedding {
  my ($embeddings_ref, $word, $max_length) = @_;
  my @chars = $word eq "</s>" ? (1) : map {exists $embeddings_ref->{chars}->{$_} ? $embeddings_ref->{chars}->{$_} : 0} split(//, $word);
  my $chars_str = join(" ", @chars);
  if (not exists $embeddings_ref->{word_map}->{$chars_str}) {
    $embeddings_ref->{word_map}->{$chars_str} = scalar(@{$embeddings_ref->{word_list}});
    push @{$embeddings_ref->{word_list}}, [@chars];
  }
  return $embeddings_ref->{word_map}->{$chars_str};
}

sub cle_embeddings {
  my ($embeddings_ref) = @_;

  return @{$embeddings_ref->{word_list}};
}

sub cle_read_vocabulary {
  my ($embeddings_ref, $fname) = @_;

  open (my $f, "<", $fname) or die "Cannot open characters vocabulary $fname: $!";

  my $nchars = 0;
  while (<$f>) {
    chomp;
    my ($char, $int) = split / /;
    $embeddings_ref->{chars}->{$char} = $int;
    $nchars = $int+1 if $int+1 > $nchars;
  }
  $embeddings_ref->{word_map} = {};
  $embeddings_ref->{word_list} = [];

  return $nchars;
}

1;
