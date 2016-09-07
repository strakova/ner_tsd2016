#!/bin/sh

./word2vec -train ../data/forms.txt -min-count 10 -save-vocab ../forms.vocab.txt
