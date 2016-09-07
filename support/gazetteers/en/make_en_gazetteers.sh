#!/bin/bash

cat countries.en cities.en airports.en > LOC_gazetteers.en
cat first_names.en last_names.en > PER_gazetteers.en
cat cooperative_federations_wiki.en cooperatives_wiki.en employee_owned_companies_wiki.en food_cooperatives_wiki.en retailers_cooperatives_wiki.en companies_us_wiki.en > ORG_gazetteers.en

CONLL_DIR=/net/work/people/strakova/conll2003/ner/lists
for name in PER ORG LOC MISC; do
  cut -f2- -d" " $CONLL_DIR/ned.list.$name > ned.list.$name
  grep $name $CONLL_DIR/eng.list | cut -f2- -d" " > eng.list.$name
done
