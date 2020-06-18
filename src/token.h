#ifndef __TOKEN_H__
#define __TOKEN_H__

#include <stdio.h>
#include <stdlib.h>

static char* token_type_s[] = {
  "LPAR", "RPAR", "LBRACKET", "RBRACKET",
  "COMMA", "DOT", "MINUS", "PLUS", "SLASH", "STAR",

  "NOT", "NE", "EQ", "GT", "GE", "LT", "LE", "DEF",

  "ID", "STR", "NUM",

  "AND", "OBJ", "ELSE", "FALSE", "FUN", "FOR", "IF", "UNDEF", "OR",
  "PRINT", "RET", "PARENT", "ME", "TRUE", "VAR", "WHILE", "COLON",

  "WS", "IGNORE", "SPACE", "NL",

  "END"
};
  

typedef enum token_type {
  LPAR, RPAR, LBRACKET, RBRACKET,
  COMMA, DOT, MINUS, PLUS, SLASH, STAR,

  NOT, NE, EQ, GT, GE, LT, LE, DEF,

  ID, STR, NUM,

  AND, OBJ, ELSE, FALSE, FUN, FOR, IF, UNDEF, OR,
  PRINT, RET, PARENT, ME, TRUE, VAR, WHILE, COLON,

  WS, IGNORE, SPACE, NL,

  END
} token_type;

typedef struct token {
  char* val;
  int val_l;
  void* literal;
  int line;
  token_type type;
} token;

char* token_str(token*);
token* token_make(token_type,char*,int,void*,int);

#endif
