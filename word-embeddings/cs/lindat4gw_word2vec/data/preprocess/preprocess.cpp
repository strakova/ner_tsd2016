#include <ctime>
#include <iomanip>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "string_piece.h"
#include "unicode.h"
#include "uninorms.h"
#include "utf8.h"

using namespace ufal::unilib;
using namespace ufal::utils;
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
  if (argc < 2) return cerr << "Usage: " << argv[0] << " perform_lowercasing" << endl, 1;

  bool perform_lowercasing = stoi(argv[1]) > 0;

  string line, output, utf8;
  u32string utf32;
  vector<string_piece> forms;

  clock_t now = clock();
  while (getline(cin, line)) {
    split(line, ' ', forms);

    output.clear();
    for (auto&& form : forms) {
      if (!utf8::valid(form.str, form.len))
        cerr << "Invalid UTF8 word '" << form << "'" << endl;

      utf8::decode(form.str, form.len, utf32);
      bool drop = false;
      for (auto&& chr : utf32) {
        if (chr == 0x9A || chr == 0x9E) goto next_sentence; // Heuristics for bad encoding

        if (chr >= 128 && unicode::category(chr) & ~(unicode::L)) {
          // We might have found non-NFC string, try normalizing.
          uninorms::nfc(utf32);
          for (auto&& chr : utf32)
            if (chr >= 128 && unicode::category(chr) & ~(unicode::L)) {
              drop = true;
              break;
            }
          break;
        }
      }

      if (!drop) {
        if (!output.empty()) output.push_back(' ');
        if (perform_lowercasing)
          for (auto&& chr : utf32)
            utf8::append(output, unicode::lowercase(chr));
        else
          output.append(form.str, form.len);
      }
    }

    if (!output.empty()) {
      output.push_back('\n');
      cout << output;
    }
next_sentence:;
  }
  cerr << "Preprocessing done in " << fixed << setprecision(3) << (clock() - now) / double(CLOCKS_PER_SEC) << " seconds." << endl;

  return 0;
}
