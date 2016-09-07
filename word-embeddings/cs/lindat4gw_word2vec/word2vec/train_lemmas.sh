#!/bin/sh

for ns in 5 15; do
  for w in 5 10; do
    for d in 50 100 150 200 300; do
      qsub $SGE_ARGS -cwd -b y -N train_lemmas_d${d}_w${w}_ns${ns} ./word2vec -train ../data/lemmas.txt -output ../lemmas.vectors-w${w}-d${d}-ns${ns}.txt -read-vocab ../lemmas.vocab.txt -size $d -window $w -negative $ns -iter 1 -cbow 0 -binary 0
    done
  done
done
