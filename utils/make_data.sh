#!/bin/bash

# This script converts data to CoNLL-2003 BIO format, where necessary; and it
# re-tags and re-lemmatizes train, dtest and etest files in
#       - Czech Named Entity Corpus 1.0, 1.1 and 2.0 (http://ufal.mff.cuni.cz/cnec/)
#         Usage: ./make_data.sh [cnec1.0|cnec1.1|cnec2.0]
#       - Konkol's Extended Czech Named Entity Corpus 1.1 (http://home.zcu.cz/~konkol/cnec1.1.php)
#         Usage: ./make_data.sh cnec1.1_konkol.
#       - Konkol's Extended Czech Named Entity Corpus 2.0 (http://home.zcu.cz/~konkol/cnec2.0.php)
#         Usage: ./make_data.sh cnec2.0_konkol.
#       - CoNLL-2003 English data
#         Usage: ./make_data.sh conll2003_en

CORPUS=$1

if [ $CORPUS="cnec1.0" -o $CORPUS="cnec1.1" -o $CORPUS="cnec2.0" -o $CORPUS="cnec2.0_konkol" -o $CORPUS="cnec1.1_konkol" ]; then
  MODEL=/net/projects/morphodita/models/czech-morfflex-pdt-131112/czech-morfflex-pdt-131112.tagger-best_accuracy
elif [ $CORPUS="conll2003_en" ]; then
  MODEL=/net/projects/morphodita/models/english-morphium-wsj-140407/english-morphium-wsj-140407-no_negation.tagger
else
  echo "Unknown corpus $CORPUS"
  exit 1
fi

TMP=../tmp

make -C tagger_lemmatizer

if [ $CORPUS = "cnec1.0" ]; then
  DATA=../data/CNEC_1.0
  DATA_TAGGED=../data_tagged/CNEC_1.0
  mkdir -p $DATA_TAGGED

  for name in train dtest etest; do
    # copy tmt
    cp $DATA/$name.tmt $DATA_TAGGED/$name.tmt

    # convert tmt to CoNLL-2003
    cat $DATA/$name.tmt | ./tmt2conll2003.pl > $DATA_TAGGED/$name.conll

    # re-tag and re-lemmatize with MorphoDiTa
    cut -f4,5 -d" " $DATA_TAGGED/$name.conll > $TMP/cols45.tmp
    cut -f1 -d" " $DATA_TAGGED/$name.conll | tagger_lemmatizer/tagger_lemmatizer $MODEL | tr "\t" " " > $TMP/cols123.tmp
    paste -d" " $TMP/cols123.tmp $TMP/cols45.tmp | sed "s/^ $//" > "$DATA_TAGGED/$name.tagged.conll"
    rm -f $TMP/cols123.tmp $TMP/cols45.tmp
  done
elif [ $CORPUS="cnec1.1" -o $CORPUS="cnec2.0" ]; then
  case $CORPUS in
    cnec1.1) DATA=../data/CNEC_1.1; CNEC_VERSION=1;;
    cnec2.0) DATA=../data/CNEC_2.0; CNEC_VERSION=2;;
  esac
  DATA_TAGGED=${DATA/data/data_tagged}
  mkdir -p $DATA_TAGGED

  for name in train dtest etest; do
    # copy treex
    cp $DATA/named_ent_$name.treex $DATA_TAGGED/$name.treex

    # convert treex to CoNLL-2003
    cat $DATA/named_ent_$name.treex | ./treex2conll2003.pl $CNEC_VERSION > $DATA_TAGGED/$name.conll

    # re-tag and re-lemmatize with MorphoDiTa
    cut -f4,5 -d" " $DATA_TAGGED/$name.conll > $TMP/cols45.tmp
    cut -f1 -d" " $DATA_TAGGED/$name.conll | tagger_lemmatizer/tagger_lemmatizer $MODEL | tr "\t" " " > $TMP/cols123.tmp
    paste -d" " $TMP/cols123.tmp $TMP/cols45.tmp | sed "s/^ $//" > "$DATA_TAGGED/$name.tagged.conll"
    rm -f $TMP/cols123.tmp $TMP/cols45.tmp
  done
elif [ $CORPUS = "cnec2.0_konkol" ]; then
  DATA=../data/CNEC_2.0_konkol
  DATA_TAGGED=../data_tagged/CNEC_2.0_konkol
  mkdir -p $DATA_TAGGED

  # re-tag and re-lemmatize with MorphoDiTa
  for name in train dtest etest; do
    cut -f4 $DATA/${name}.conll > $TMP/col4.tmp
    cut -f1 $DATA/${name}.conll | tagger_lemmatizer/tagger_lemmatizer $MODEL | tr "\t" " " > $TMP/cols123.tmp
    paste -d" " $TMP/cols123.tmp $TMP/col4.tmp | sed "s/^ $//" > $DATA_TAGGED/${name}.tagged.conll
    rm -f $TMP/cols123.tmp $TMP/col4.tmp
  done
elif [ $CORPUS = "cnec1.1_konkol" ]; then
  DATA=../data/CNEC_1.1_konkol
  DATA_TAGGED=../data_tagged/CNEC_1.1_konkol
  mkdir -p $DATA_TAGGED

  # re-tag and re-lemmatize with MorphoDiTa
  for name in train dtest etest; do
    cut -f4 $DATA/${name}.conll > $TMP/col4.tmp
    cut -f1 $DATA/${name}.conll | tagger_lemmatizer/tagger_lemmatizer $MODEL | tr "\t" " " > $TMP/cols123.tmp
    paste -d" " $TMP/cols123.tmp $TMP/col4.tmp | sed "s/^ $//" > $DATA_TAGGED/${name}.tagged.conll
    rm -f $TMP/cols123.tmp $TMP/col4.tmp
  done
elif [ $CORPUS = "conll2003_en" ]; then
  DATA=../data/CoNLL2003_English
  DATA_TAGGED=../data_tagged/CoNLL2003_English
  mkdir -p $DATA_TAGGED

  # re-tag and re-lemmatize with MorphoDiTa
  for name in train dtest etest; do
    cut -f4 -d" " $DATA/${name}.conll > $TMP/col4.tmp
    cut -f1 -d" " $DATA/${name}.conll | tagger_lemmatizer/tagger_lemmatizer $MODEL | tr "\t" " " > $TMP/cols123.tmp
    paste -d" " $TMP/cols123.tmp $TMP/col4.tmp | sed "s/^ $//" > $DATA_TAGGED/${name}.tagged.conll
    rm -f $TMP/cols123.tmp $TMP/col4.tmp
  done
fi
