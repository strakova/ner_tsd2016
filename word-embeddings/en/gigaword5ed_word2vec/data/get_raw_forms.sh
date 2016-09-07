#!/bin/sh

for f in /net/data/LDC/EnglishGigaword5thEd_LDC2011T07/data/*/*.gz; do
  zcat "$f" | perl -ne '
  BEGIN { $block=0 }
  if (/^<P>/) {
    $block=1;
    $text="";
  } elsif (/^<\/P>/) {
    print $text."\n";
    $block = 0;
  } elsif ($block) {
    chomp;
    $text .= " " if length $text;
    $text .= $_;
  }
  '
done | tokenize_horizontal/tokenize_horizontal >forms.raw.txt

