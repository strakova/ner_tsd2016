#!/bin/bash

# This is the main script for the NER training and testing pipeline.

set -e

### EXPERIMENT SETTING
FEATURES_DIRNAME=default
PRECOMPUTE_DATA_ARGS=
# parameters for NN training in Torch
ACTIVATION=prelu
HIDDEN_LAYER=200
HIDDEN_LAYERS=1
MAX_ITER=50
BATCH_SIZE=100
METHOD=adagrad
LEARNING_RATE=0.02
LEARNING_RATE_FINAL=0.005
MOMENTUM=0
ALPHA=0.99
L2=0
DROPOUT=0.5
SHUFFLE=0
CLE_CHARDIM=64
CLE_DIM=128
CLE_UNIT=LSTM
ENSEMBLES=5
SEED_VALUE=0

## Parse options using `getopt` binary
ORIGINAL_ARGS=("$@")
PARSED_ARGS=`getopt -n $0 -o "" -a -l features_dirname:,activation:,hidden_layer:,hidden_layers:,max_iter:,batch_size:,method:,learning_rate:,learning_rate_final:,momentum:,alpha:,l2:,dropout:,shuffle:,cle_dim:,cle_chardim:,cle_unit:,ensembles:,seed:,form_embeddings:,lemma_embeddings:,tag_embeddings:,characters:,characters_form:,characters_lemma:,characters_tag:,cle_maxlen:,cle_form:,cle_lemma:,features:,brown_clusters:,use_nil:,use_unk:,no_dtest:,forms_only: -- "$@"`
eval set -- "$PARSED_ARGS"
while true; do
  case "$1" in
    --) shift; break;;
    --features_dirname) FEATURES_DIRNAME="$2"; shift 2;;
    --activation) ACTIVATION="$2"; shift 2;;
    --hidden_layer) HIDDEN_LAYER="$2"; shift 2;;
    --hidden_layers) HIDDEN_LAYERS="$2"; shift 2;;
    --max_iter) MAX_ITER="$2"; shift 2;;
    --batch_size) BATCH_SIZE="$2"; shift 2;;
    --method) METHOD="$2"; shift 2;;
    --learning_rate) LEARNING_RATE="$2"; shift 2;;
    --learning_rate_final) LEARNING_RATE_FINAL="$2"; shift 2;;
    --momentum) MOMENTUM="$2"; shift 2;;
    --alpha) ALPHA="$2"; shift 2;;
    --l2) L2="$2"; shift 2;;
    --dropout) DROPOUT="$2"; shift 2;;
    --shuffle) SHUFFLE="$2"; shift 2;;
    --cle_dim) CLE_DIM="$2"; shift 2;;
    --cle_chardim) CLE_CHARDIM="$2"; shift 2;;
    --cle_unit) CLE_UNIT="$2"; shift 2;;
    --ensembles) ENSEMBLES="$2"; shift 2;;
    --seed) SEED_VALUE="$2"; shift 2;;
    --form_embeddings) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --form_embeddings=$2"; shift 2;;
    --lemma_embeddings) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --lemma_embeddings=$2"; shift 2;;
    --tag_embeddings) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --tag_embeddings=$2"; shift 2;;
    --characters) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --characters=$2"; shift 2;;
    --characters_form) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --characters_form=$2"; shift 2;;
    --characters_lemma) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --characters_lemma=$2"; shift 2;;
    --characters_tag) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --characters_tag=$2"; shift 2;;
    --cle_maxlen) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --cle_maxlen=$2"; shift 2;;
    --cle_form) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --cle_form=$2"; shift 2;;
    --cle_lemma) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --cle_lemma=$2"; shift 2;;
    --features) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --features=$2"; shift 2;;
    --brown_clusters) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --brown_clusters=$2"; shift 2;;
    --use_nil) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --use_nil=$2"; shift 2;;
    --use_unk) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --use_unk=$2"; shift 2;;
    --no_dtest) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --no_dtest=$2"; shift 2;;
    --forms_only) PRECOMPUTE_DATA_ARGS="$PRECOMPUTE_DATA_ARGS --forms_only=$2"; shift 2;;
  esac
done

[ $# -ge 3 ] || { echo "Usage: $0 [cs] [cnec1.0|cnec1.1|cnec2.0|cnec2.0_konkol|cnec1.1_konkol|conll2003_en] [dtest|etest]" >&2; exit 1; }

### COMMANDLINE PARAMETERS
LANGUAGE=$1
CORPUS=$2
TEST=$3

### PATHS AND GRID SETTING
[ -z "$SGE_ARGS" ] && SGE_ARGS='-q *@!pandora*'
EXPERIMENT=ner-$LANGUAGE-$CORPUS-$TEST-$FEATURES_DIRNAME-$ACTIVATION-h$HIDDEN_LAYER-l$HIDDEN_LAYERS-i$MAX_ITER-b$BATCH_SIZE-$METHOD-$LEARNING_RATE-$LEARNING_RATE_FINAL-m$MOMENTUM-a$ALPHA-l$L2-d$DROPOUT-s$SHUFFLE-ce$CLE_UNIT-$CLE_DIM-$CLE_CHARDIM-e$ENSEMBLES-s$SEED_VALUE
WORK_DIR=../
UTILS=../../../utils

case "$CORPUS" in
  cnec1.0) ;;
  cnec1.1) ;;
  cnec2.0) ;;
  cnec2.0_konkol) ;;
  cnec1.1_konkol) ;;
  conll2003_en) ;;
  *) echo "Unknown corpus $CORPUS"; exit 1;;
esac

### QSUB
if [ -d ../.git ]; then
  # Running from original location, copy to the SRC_DIR and reexecute.
  ORIG_SRC_DIR=.
  SRC_DIR=../tmp/$EXPERIMENT/src

  mkdir -p $SRC_DIR
  cp -rf $ORIG_SRC_DIR/* $SRC_DIR

  cd $SRC_DIR
  SGE_ARGS="$SGE_ARGS -l mem_free=4G"
  [ "$ENSEMBLES" -gt 1 ] && SGE_ARGS="$SGE_ARGS -pe smp $ENSEMBLES"
  qsub -cwd -V -b y $SGE_ARGS -N $EXPERIMENT ./train_nn_optim.sh "${ORIGINAL_ARGS[@]}"
  exit
fi

# Save options
echo "${ORIGINAL_ARGS[@]}" >$WORK_DIR/cmd_args

# PRECOMPUTED DATA
# If precomputed data exist, the script will use training data, word
# embeddings, etc. from this location to save time.
PRECOMPUTED_DATA=../../../precomputed_data/features-$LANGUAGE-$CORPUS-$TEST-$FEATURES_DIRNAME
[ -d $PRECOMPUTED_DATA ] || ./precompute_data.sh $PRECOMPUTE_DATA_ARGS $LANGUAGE $CORPUS $TEST $PRECOMPUTED_DATA

### TORCH
for ((i=0; $i<$ENSEMBLES; i++)); do
OMP_NUM_THREADS=1 th train_nn_optim.lua \
  --trainData=$PRECOMPUTED_DATA/trainingData.txt \
  --testData=$PRECOMPUTED_DATA/testingData.txt \
  --outputProbs=$WORK_DIR/outputProbs$i.txt \
  --seed=$(($SEED_VALUE+$i)) \
  --save=$WORK_DIR \
  --activation=$ACTIVATION \
  --hiddenLayerSize=$HIDDEN_LAYER \
  --hiddenLayers=$HIDDEN_LAYERS \
  --batchSize=$BATCH_SIZE \
  --maxIter=$MAX_ITER \
  --method=$METHOD \
  --learningRate=$LEARNING_RATE \
  --learningRateFinal=$LEARNING_RATE_FINAL \
  --momentum=$MOMENTUM \
  --alpha=$ALPHA \
  --l2=$L2 \
  --dropout=$DROPOUT \
  --shuffle=$SHUFFLE \
  --cleDim=$CLE_DIM \
  --cleCharDim=$CLE_CHARDIM \
  --cleUnit=$CLE_UNIT \
  &
done
wait

### Merge probs with CoNLL file and run Viterbi
./merge_probs_from_torch.pl $CORPUS $PRECOMPUTED_DATA/${TEST}.conll $WORK_DIR/outputProbs*.txt | ./inference_and_classify.pl > $WORK_DIR/${TEST}.output
cut -f1,3,4,6 -d" " $WORK_DIR/${TEST}.output > $WORK_DIR/${TEST}_system.conll
rm $WORK_DIR/outputProbs*.txt

### Evaluation
if [ $CORPUS = "cnec1.0" ]; then
  $UTILS/tmt2eval.pl < $PRECOMPUTED_DATA/${TEST}.tmt > $WORK_DIR/${TEST}.gold_entities
  $UTILS/conll2eval.pl < $WORK_DIR/${TEST}_system.conll | ./add_containers.pl > $WORK_DIR/${TEST}.system_entities
  $UTILS/compare_ne_outputs_v2.pl $WORK_DIR/${TEST}.system_entities $WORK_DIR/${TEST}.gold_entities
elif [ $CORPUS = "cnec1.1" -o $CORPUS = "cnec2.0" ]; then
  $UTILS/treex2eval.pl < $PRECOMPUTED_DATA/${TEST}.treex > $WORK_DIR/${TEST}.gold_entities
  $UTILS/conll2eval.pl < $WORK_DIR/${TEST}_system.conll | ./add_containers.pl > $WORK_DIR/${TEST}.system_entities
  $UTILS/compare_ne_outputs_v3.pl $WORK_DIR/${TEST}.system_entities $WORK_DIR/${TEST}.gold_entities
elif [ $CORPUS = "cnec2.0_konkol" -o $CORPUS = "cnec1.1_konkol" ]; then
  cut -d" " -f6 $WORK_DIR/${TEST}.output | $UTILS/konkol_2_conll2003bio.pl > $WORK_DIR/${TEST}.system_output
  paste -d" " $PRECOMPUTED_DATA/${TEST}.conll $WORK_DIR/${TEST}.system_output > $WORK_DIR/${TEST}.for_conlleval
  $UTILS/conlleval < $WORK_DIR/${TEST}.for_conlleval
elif [ $CORPUS = "conll2003_en" ]; then
  cut -d" " -f6 $WORK_DIR/${TEST}.output > $WORK_DIR/${TEST}.system_output
  paste -d" " $PRECOMPUTED_DATA/${TEST}.conll $WORK_DIR/${TEST}.system_output > $WORK_DIR/${TEST}.for_conlleval
  $UTILS/conlleval < $WORK_DIR/${TEST}.for_conlleval
fi
