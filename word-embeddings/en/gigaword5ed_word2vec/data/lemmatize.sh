#!/bin/sh

preprocess/preprocess 0 <forms.raw.txt | lemmatize/lemmatize lemmatize/english-morphium-wsj-140407-no_negation.tagger >lemmas.txt
