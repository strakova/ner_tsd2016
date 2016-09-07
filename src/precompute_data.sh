#!/bin/bash

# This script will precompute large data for NN training, mainly word
# embeddings, classification features, etc.
#
# This script is not supposed to be called from commandline, it is called from
# main script train_nn_optim.sh.

set -e

FORM_EMBEDDINGS_ARG=
LEMMA_EMBEDDINGS_ARG=
TAG_EMBEDDINGS_ARG=
CHARACTERS=1
CHARACTERS_FORM=2
CHARACTERS_LEMMA=2
CHARACTERS_TAG=2
CLE_MAXLEN=20
CLE_FORM=0
CLE_LEMMA=0
FEATURES=1
BROWN_CLUSTERS=1
USE_NIL=1
USE_UNK=0
NO_DTEST=0
FORMS_ONLY=0

## Parse options using `getopt` binary
PARSED_ARGS=`getopt -n $0 -o "" -a -l form_embeddings:,lemma_embeddings:,tag_embeddings:,characters:,characters_form:,characters_lemma:,characters_tag:,cle_maxlen:,cle_form:,cle_lemma:,features:,brown_clusters:,use_nil:,use_unk:,no_dtest:,forms_only: -- "$@"`
eval set -- "$PARSED_ARGS"
while true; do
  case "$1" in
    --) shift; break;;
    --form_embeddings) FORM_EMBEDDINGS_ARG="$2"; shift 2;;
    --lemma_embeddings) LEMMA_EMBEDDINGS_ARG="$2"; shift 2;;
    --tag_embeddings) TAG_EMBEDDINGS_ARG="$2"; shift 2;;
    --characters) CHARACTERS="$2"; shift 2;;
    --characters_form) CHARACTERS_FORM="$2"; shift 2;;
    --characters_lemma) CHARACTERS_LEMMA="$2"; shift 2;;
    --characters_tag) CHARACTERS_TAG="$2"; shift 2;;
    --cle_maxlen) CLE_MAXLEN="$2"; shift 2;;
    --cle_form) CLE_FORM="$2"; shift 2;;
    --cle_lemma) CLE_LEMMA="$2"; shift 2;;
    --features) FEATURES="$2"; shift 2;;
    --brown_clusters) BROWN_CLUSTERS="$2"; shift 2;;
    --use_nil) USE_NIL="$2"; shift 2;;
    --use_unk) USE_UNK="$2"; shift 2;;
    --no_dtest) NO_DTEST="$2"; shift 2;;
    --forms_only) FORMS_ONLY="$2"; shift 2;;
  esac
done

### COMMANDLINE PARAMETERS
LANGUAGE=$1
CORPUS=$2
TEST=$3
WORK_DIR=$4

### EXPERIMENT SETTING
WORD_EMBEDDINGS_WINDOW_SIZE=2

### SETTING
PRECOMPUTED_DIR=../../../precomputed_data
if [ $CORPUS = "cnec1.0" ]; then
  DATA=../../../data_tagged/CNEC_1.0
elif [ $CORPUS = "cnec1.1" ]; then
  DATA=../../../data_tagged/CNEC_1.1
elif [ $CORPUS = "cnec2.0" ]; then
  DATA=../../../data_tagged/CNEC_2.0
elif [ $CORPUS = "cnec2.0_konkol" ]; then
  DATA=../../../data_tagged/CNEC_2.0_konkol
elif [ $CORPUS = "cnec1.1_konkol" ]; then
  DATA=../../../data_tagged/CNEC_1.1_konkol
elif [ $CORPUS = "conll2003_en" ]; then
  DATA=../../../data_tagged/CoNLL2003_English
else
  echo "Unknown corpus $CORPUS"
  exit 1
fi

mkdir -p $WORK_DIR

if [ $LANGUAGE = "cs" ]; then
  SUPPORT_PATH=/net/work/people/strakova/named_entities_redmine/support/
  FORM_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/cs/lindat4gw_word2vec/forms.vectors-w5-d200-ns5.txt"
  LEMMA_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/cs/lindat4gw_word2vec/lemmas.vectors-w5-d200-ns5.txt"
  TAG_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/cs/tags_pdt/tags.vectors-first-2-one-hot.txt"
elif [ $LANGUAGE = "en" ]; then
  SUPPORT_PATH=/net/work/people/strakova/named_entities_redmine/support/
  FORM_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/en/gigaword5ed_word2vec/forms.vectors-w5-d200-ns5.txt"
  LEMMA_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/en/gigaword5ed_word2vec/lemmas.vectors-w5-d200-ns5.txt"
  TAG_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/en/tags_ptb/tags.vectors-one-hot.txt"
else
  echo "Unknown language $LANGUAGE"
  exit 1
fi

[ -n "$FORM_EMBEDDINGS_ARG" ] && FORM_EMBEDDINGS_SOURCE="cat $FORM_EMBEDDINGS_ARG"
[ -n "$LEMMA_EMBEDDINGS_ARG" ] && LEMMA_EMBEDDINGS_SOURCE="cat $LEMMA_EMBEDDINGS_ARG"
[ -n "$TAG_EMBEDDINGS_ARG" ] && TAG_EMBEDDINGS_SOURCE="cat $TAG_EMBEDDINGS_ARG"

### INPUT DATA PREPROCESSING
# For testing, train on concatenated train+devel data
if [ $TEST = "dtest" ]; then
  cp $DATA/train.tagged.conll $WORK_DIR/train.conll
  cp $DATA/dtest.tagged.conll $WORK_DIR/dtest.conll
  [ -f $DATA/dtest.tmt ] && cp $DATA/dtest.tmt $WORK_DIR/
  [ -f $DATA/dtest.treex ] && cp $DATA/dtest.treex $WORK_DIR/
elif [ $TEST = "etest" ]; then
  if [ "$NO_DTEST" -gt 0 ]; then
    cat $DATA/train.tagged.conll > $WORK_DIR/train.conll
  else
    cat $DATA/train.tagged.conll $DATA/dtest.tagged.conll > $WORK_DIR/train.conll
  fi
  cp $DATA/etest.tagged.conll $WORK_DIR/etest.conll
  [ -f $DATA/etest.tmt ] && cp $DATA/etest.tmt $WORK_DIR/
  [ -f $DATA/etest.treex ] && cp $DATA/etest.treex $WORK_DIR/
fi

if [ "$FORMS_ONLY" -gt 0 ]; then
  LEMMA_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/null.vectors.txt"
  TAG_EMBEDDINGS_SOURCE="cat /net/projects/word-embeddings/null.vectors.txt"
  perl -ple '@p=split/\s+/;@p==5 and $_=join(" ", $p[0], "_", "_", @p[3..$#p])' -i $WORK_DIR/*.conll
fi

### CHARACTERS
if [ "$CHARACTERS" -gt 0 ]; then
  ./create_characters_vocabulary.pl $WORK_DIR/train.conll $WORK_DIR/character_vocabulary.txt 1
fi

### CLE
if [ "$CLE_FORM" -gt 0 -o "$CLE_LEMMA" -gt 0 ]; then
  ./create_characters_vocabulary.pl $WORK_DIR/train.conll $WORK_DIR/cle_vocabulary.txt 0
fi

### ENGINEERED FEATURES (Strakova et al., 2013)
if [ "$FEATURES" -gt 0 ]; then
  ./create_features_vocabulary.pl --data=$WORK_DIR/train.conll --language=$LANGUAGE --support_path=$SUPPORT_PATH > $WORK_DIR/features_vocabulary.txt
fi

### WORD EMBEDDINGS
# Subset word embeddings by given filenames with data.
PRECOMPUTED_EMBEDDINGS="$PRECOMPUTED_DIR/embeddings-$LANGUAGE-$CORPUS-$TEST"
mkdir -p "$PRECOMPUTED_EMBEDDINGS"

FORM_EMBEDDINGS="$PRECOMPUTED_EMBEDDINGS/${FORM_EMBEDDINGS_SOURCE//\//_}"
[ -f "$FORM_EMBEDDINGS" ] || ./create_word_embeddings.pl --filenames="$WORK_DIR/train.conll,$WORK_DIR/${TEST}.conll" --column=1 --embeddings=<($FORM_EMBEDDINGS_SOURCE) > "$FORM_EMBEDDINGS"

LEMMA_EMBEDDINGS="$PRECOMPUTED_EMBEDDINGS/${LEMMA_EMBEDDINGS_SOURCE//\//_}"
[ -f "$LEMMA_EMBEDDINGS" ] || ./create_word_embeddings.pl --filenames="$WORK_DIR/train.conll,$WORK_DIR/${TEST}.conll" --column=2 --embeddings=<($LEMMA_EMBEDDINGS_SOURCE) > "$LEMMA_EMBEDDINGS"

TAG_EMBEDDINGS="$PRECOMPUTED_EMBEDDINGS/${TAG_EMBEDDINGS_SOURCE//\//_}"
[ -f "$TAG_EMBEDDINGS" ] || ./create_word_embeddings.pl --filenames="$WORK_DIR/train.conll,$WORK_DIR/${TEST}.conll" --column=3 --embeddings=<($TAG_EMBEDDINGS_SOURCE) > "$TAG_EMBEDDINGS"

args=""
[ "$CHARACTERS" -gt 0 ] && args="$args --characters=$WORK_DIR/character_vocabulary.txt --characters_form=$CHARACTERS_FORM --characters_lemma=$CHARACTERS_LEMMA --characters_tag=$CHARACTERS_TAG"
[ "$CLE_FORM" -gt 0 -o "$CLE_LEMMA" -gt 0 ] && args="$args --cle=$WORK_DIR/cle_vocabulary.txt --cle_maxlen=$CLE_MAXLEN --cle_form=$CLE_FORM --cle_lemma=$CLE_LEMMA"
[ "$FEATURES" -gt 0 ] && args="$args --features=$WORK_DIR/features_vocabulary.txt"
[ "$BROWN_CLUSTERS" -gt 0 ] && args="$args --use_brown_clusters"

./print_features_for_nn.pl \
  --data=$WORK_DIR/train.conll --corpus=$CORPUS --language=$LANGUAGE \
  --support_path=$SUPPORT_PATH \
  --forms="$FORM_EMBEDDINGS" --lemmas="$LEMMA_EMBEDDINGS" --tags="$TAG_EMBEDDINGS" \
  $args \
  --window_size=$WORD_EMBEDDINGS_WINDOW_SIZE \
  --use_nil="$USE_NIL" --use_unk="$USE_UNK" \
  > $WORK_DIR/trainingData.txt

./print_features_for_nn.pl \
  --data=$WORK_DIR/${TEST}.conll --corpus=$CORPUS --language=$LANGUAGE \
  --support_path=$SUPPORT_PATH \
  --forms="$FORM_EMBEDDINGS" --lemmas="$LEMMA_EMBEDDINGS" --tags="$TAG_EMBEDDINGS" \
  $args \
  --window_size=$WORD_EMBEDDINGS_WINDOW_SIZE \
  --use_nil="$USE_NIL" --use_unk="$USE_UNK" \
  > $WORK_DIR/testingData.txt
