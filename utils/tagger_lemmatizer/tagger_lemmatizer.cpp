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

inline istream& getlines(istream& is, vector<string>& lines) {
  lines.clear();

  for (string line; getline(is, line) && !line.empty(); )
    lines.emplace_back(line);

  if (is.eof() && !lines.empty()) is.clear(istream::eofbit);
  return is;
}

int main(int argc, char* argv[]) {
  if (argc < 2) return cerr << "Usage: " << argv[0] << " tagger_file" << endl, 1;

  cerr << "Loading tagger: ";
  unique_ptr<tagger> tagger(tagger::load(argv[1]));
  if (!tagger) return cerr << "Cannot load tagger from file '" << argv[1] << "'!" << endl, 1;
  cerr << "done" << endl;

  vector<string> lines;
  vector<string_piece> forms;
  vector<vector<tagged_lemma>> analyses;
  vector<int> tags;
  string output;

  clock_t now = clock();
  while (getlines(cin, lines)) {
    forms.clear();
    for (auto&& line : lines)
      forms.emplace_back(line);

    if (analyses.size() < forms.size()) analyses.resize(forms.size());
    for (size_t i = 0; i < forms.size(); i++)
      if (tagger->get_morpho()->analyze(forms[i], morpho::NO_GUESSER, analyses[i]) < 0)
        utf8::map(unicode::lowercase, forms[i].str, forms[i].len, analyses[i][0].lemma);

    tagger->tag_analyzed(forms, analyses, tags);

    output.clear();
    for (unsigned i = 0; i < tags.size(); i++) {
      output.append(lines[i]).push_back('\t');
      output.append(analyses[i][tags[i]].lemma).push_back('\t');
      output.append(analyses[i][tags[i]].tag).push_back('\n');
    }
    output.push_back('\n');
    cout << output;
  }
  cerr << "Tagging done in " << fixed << setprecision(3) << (clock() - now) / double(CLOCKS_PER_SEC) << " seconds." << endl;

  return 0;
}
