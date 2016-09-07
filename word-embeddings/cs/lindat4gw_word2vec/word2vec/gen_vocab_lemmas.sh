#!/bin/sh

./word2vec -train ../data/lemmas.txt -min-count 10 -save-vocab ../lemmas.vocab.txt
