#include "keyword.h"
#include <string.h>

token_type keyword_token_type(char* x) {
  int i = 0;
  int l = sizeof(keywords) / sizeof(keywords[0]);
  for(; i < l; i++) {
    if(strcmp(x, keywords[i]) == 0) {
      return keywords_map[i];
    }
  }
  return ID;
}
