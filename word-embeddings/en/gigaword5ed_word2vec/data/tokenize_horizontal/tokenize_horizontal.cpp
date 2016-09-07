#include <ctime>
#include <iomanip>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "morphodita.h"

using namespace ufal::morphodita;
using namespace std;

int main() {
  unique_ptr<tokenizer> tokenizer(tokenizer::new_english_tokenizer());

  string line, output;
  vector<string_piece> forms;

  clock_t now = clock();
  while (getline(cin, line)) {
    tokenizer->set_text(line);
    while (tokenizer->next_sentence(&forms, nullptr)) {
      output.clear();
      for (auto&& form : forms) {
        if (!output.empty()) output.push_back(' ');
        output.append(form.str, form.len);
      }
      output.push_back('\n');
      cout << output;
    }
  }
  cerr << "Tokenizing done in " << fixed << setprecision(3) << (clock() - now) / double(CLOCKS_PER_SEC) << " seconds." << endl;

  return 0;
}
