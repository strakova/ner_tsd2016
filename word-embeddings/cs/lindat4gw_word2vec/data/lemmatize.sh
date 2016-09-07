#!/bin/sh

preprocess/preprocess 0 <forms.raw.txt | lemmatize/lemmatize lemmatize/czech-morfflex-pdt-131112-pos_only.tagger >lemmas.txt
