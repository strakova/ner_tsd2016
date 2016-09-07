## Software and data accompanying paper Neural Networks for Featureless Named Entity Recognition in Czech

This repository contains the source code and data used in the following paper:
- Jana Straková, Milan Straka and Jan Hajič: [Neural Networks for Featureless Named Entity Recognition in Czech](http://link.springer.com/chapter/10.1007/978-3-319-45510-5_20). In [Proceedings of the 19th International Conference on Text, Speech and Dialogue (TSD 2016)](http://www.springer.com/us/book/9783319455099), Brno, Czech Republic, September 2016.

The repository contains:
- training scripts (Perl pipeline and NN implemented in Lua using Torch)
- all versions of CNEC corpus (CNEC 1.0, CNEC 1.1, CNEC 1.1 Konkol's Extended, CNEC 2.0, CNEC 2.0 Konkol's Extended)
- (the English NER CoNLL 2013 corpus must be copied to data/CoNLL2003_English/ because of licensing issues)
- scripts used to generate Czech and English word embeddings
- the gazetteers for Czech and English
- various preprocessing tools

In order to run the pipeline, you have to:
 1. Compute the word embeddings using the scripts in `word-embeddings/` directory. In addition to downloading the data, you will need Czech and English POS tagger and lemmatizer models [czech-morfflex-pdt-131112](http://hdl.handle.net/11858/00-097C-0000-0023-68D8-1) and [english-morphium-wsj-140407](http://hdl.handle.net/11858/00-097C-0000-0023-68D9-0).
 2. You need to preprocess the NER corpus you wish to use using the `utils/make_data.sh` script. This script also need the above POS tagger and lemmatizer models. Note that the script uses hardcoded paths to the models.
 3. In order to start the training, run `src/train_all.sh`. By default, the script trains all NER corpora on all configurations, so you should choose only the ones you are interested in. Note that the `src/precompute_data.sh` script use hardcoded paths of word embeddings.
