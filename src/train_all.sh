#!/bin/bash

for mode in \
  "--features_dirname=forms_we --forms_only=1 --characters=0 --features=0 --brown_clusters=0" \
  "--features_dirname=forms_we+2ch --forms_only=1 --characters=1 --features=0 --brown_clusters=0" \
  "--features_dirname=flt_we --characters=0 --features=0 --brown_clusters=0" \
  "--features_dirname=flt_we+2ch --characters=1 --features=0 --brown_clusters=0" \
  "--features_dirname=forms_cle32 --forms_only=1 --characters=0 --features=0 --brown_clusters=0 --form_embeddings=/net/projects/word-embeddings/null.vectors.txt --cle_form=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=forms_cle64 --forms_only=1 --characters=0 --features=0 --brown_clusters=0 --form_embeddings=/net/projects/word-embeddings/null.vectors.txt --cle_form=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=forms_we+cle32 --forms_only=1 --characters=0 --features=0 --brown_clusters=0 --cle_form=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=forms_we+cle64 --forms_only=1 --characters=0 --features=0 --brown_clusters=0 --cle_form=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=forms_we+2ch+cle32 --forms_only=1 --characters=1 --features=0 --brown_clusters=0 --cle_form=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=forms_we+2ch+cle64 --forms_only=1 --characters=1 --features=0 --brown_clusters=0 --cle_form=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=forms_we+2ch+cf+cle32 --forms_only=1 --characters=1 --features=1 --brown_clusters=1 --cle_form=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=forms_we+2ch+cf+cle64 --forms_only=1 --characters=1 --features=1 --brown_clusters=1 --cle_form=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=flt_cle32 --characters=0 --features=0 --brown_clusters=0 --form_embeddings=/net/projects/word-embeddings/null.vectors.txt --lemma_embeddings=/net/projects/word-embeddings/null.vectors.txt --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=flt_cle64 --characters=0 --features=0 --brown_clusters=0 --form_embeddings=/net/projects/word-embeddings/null.vectors.txt --lemma_embeddings=/net/projects/word-embeddings/null.vectors.txt --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=flt_we+cle32 --characters=0 --features=0 --brown_clusters=0 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=flt_we+cle64 --characters=0 --features=0 --brown_clusters=0 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=flt_we+2ch+cle32 --characters=1 --features=0 --brown_clusters=0 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=flt_we+2ch+cle64 --characters=1 --features=0 --brown_clusters=0 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \
  "--features_dirname=flt_we+2ch+cf+cle32 --characters=1 --features=1 --brown_clusters=1 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=32 --cle_chardim=32 --cle_unit=GRU" \
  "--features_dirname=flt_we+2ch+cf+cle64 --characters=1 --features=1 --brown_clusters=1 --cle_form=1 --cle_lemma=1 --cle_maxlen=12 --cle_dim=64 --cle_chardim=64 --cle_unit=GRU" \

do
  for args in \
    "cs cnec1.0 etest $mode" \
    "cs cnec1.0 etest --no_dtest=1 ${mode/features_dirname=/features_dirname=nodtest_}" \
    "cs cnec1.1 etest $mode" \
    "cs cnec2.0 etest $mode" \
    "cs cnec1.1_konkol etest $mode" \
    "cs cnec2.0_konkol etest $mode" \
    "en conll2003_en etest $mode"
  do
    ./train_nn_optim.sh $args
  done
done
