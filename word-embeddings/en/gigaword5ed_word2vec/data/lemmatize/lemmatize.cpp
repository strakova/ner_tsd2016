#include <ctime>
#include <iomanip>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "morphodita.h"
#include "unicode.h"
#include "utf8.h"

using namespace ufal::morphodita;
using namespace ufal::unilib;
using namespace std;

inline void split(const string& text, char sep, vector<string_piece>& tokens) {
  tokens.clear();
  if (text.empty()) return;

  string::size_type index = 0;
  for (string::size_type next; (next = text.find(sep, index)) != string::npos; index = next + 1)
    tokens.emplace_back(text.data() + index, next - index);

  tokens.emplace_back(text.data() + index);
}

int main(int argc, char* argv[]) {
  if (argc < 2) return cerr << "Usage: " << argv[0] << " tagger_file" << endl, 1;

  cerr << "Loading tagger: ";
  unique_ptr<tagger> tagger(tagger::load(argv[1]));
  if (!tagger) return cerr << "Cannot load tagger from file '" << argv[1] << "'!" << endl, 1;
  cerr << "done" << endl;

  string line, output;
  vector<string_piece> forms;
  vector<vector<tagged_lemma>> analyses;
  vector<int> tags;

  clock_t now = clock();
  while (getline(cin, line)) {
    split(line, ' ', forms);

    if (analyses.size() < forms.size()) analyses.resize(forms.size());
    for (size_t i = 0; i < forms.size(); i++)
      if (tagger->get_morpho()->analyze(forms[i], morpho::NO_GUESSER, analyses[i]) < 0)
        utf8::map(unicode::lowercase, forms[i].str, forms[i].len, analyses[i][0].lemma);

    tagger->tag_analyzed(forms, analyses, tags);

    output.clear();
    for (unsigned i = 0; i < tags.size(); i++) {
      output.append(analyses[i][tags[i]].lemma);
      output.push_back(" \n"[i+1 == tags.size()]);
    }
    cout << output;
  }
  cerr << "Tagging done in " << fixed << setprecision(3) << (clock() - now) / double(CLOCKS_PER_SEC) << " seconds." << endl;

  return 0;
}
