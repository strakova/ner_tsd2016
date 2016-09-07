#!/bin/bash

# This script removes converted and re-tagged data from data directories.
#       - Czech Named Entity Corpus 1.0 (http://ufal.mff.cuni.cz/cnec/)
#         Usage: ./clean_data.sh cnec1.0
#       - Konkol's Extended Czech Named Entity Corpus 2.0 (http://home.zcu.cz/~konkol/cnec2.0.php)
#         Usage: ./clean_data.sh cnec2.0_konkol
# with MorphoDiTa (http://ufal.mff.cuni.cz/morphodita). 

CORPUS=$1

if [ $CORPUS = "cnec1.0" ]; then
  rm -rf ../data_tagged/CNEC_1.0
elif [ $CORPUS = "cnec2.0_konkol" ]; then
  rm -rf ../data_tagged/CNEC_2.0_konkol
else 
  echo "Unknown corpus $CORPUS"
  exit 1
fi
