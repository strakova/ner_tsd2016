#!/bin/sh

for ns in 5; do #15; do
  for w in 5 10; do
    for d in 50 100 150 200 300; do
      qsub $SGE_ARGS -cwd -b y -N train_forms_d${d}_w${w}_ns${ns} ./word2vec -train ../data/forms.txt -output ../forms.vectors-w${w}-d${d}-ns${ns}.txt -read-vocab ../forms.vocab.txt -size $d -window $w -negative $ns -iter 1 -cbow 0 -binary 0
    done
  done
done
