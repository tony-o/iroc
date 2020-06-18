#ifndef __KEYWORD_H__
#define __KEYWORD_H__

#include "token.h"

static char* keywords[] = {
  "and", "obj", "else", "false", "fun", "for", "if",
  "undef", "or", "print", "ret", "parent", "me", "true",
  "var", "while"
};

static token_type keywords_map[] = {
  AND, OBJ, ELSE, FALSE, FUN, FOR, IF, UNDEF, OR,
  PRINT, RET, PARENT, ME, TRUE, VAR, WHILE
};

token_type keyword_token_type(char*);

#endif
