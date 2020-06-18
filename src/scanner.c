#include "scanner.h"
#include "token.h"
#include "keyword.h"
#include "util/ll.h"

scanner* scan(char* src, int src_len) {
  scanner* s = scanner_make();
  int pos = 0;
  int line = 0;
  int c = 0;
  int take = 0;
  char tok;
  token_type t_tok;

  while (c < src_len) {
  //  scantok
    tok = src[c];
    t_tok = IGNORE;
    take = 1;
    switch (tok) {
      case '(': t_tok = LPAR; break;
      case ')': t_tok = RPAR; break;
      case '{': t_tok = LBRACKET; break;
      case '}': t_tok = RBRACKET; break;
      case ',': t_tok = COMMA; break;
      case '.': t_tok = DOT; break;
      case '-': t_tok = MINUS; break;
      case '+': t_tok = PLUS; break;
      case '*': t_tok = STAR; break;
      case '!':
        t_tok = c+1 < src_len && src[c+1] == '=' && ++c && (take=2) ? NE : NOT;
        break;
      case '=': t_tok = EQ; break;
      case '>':
        t_tok = c+1 < src_len && src[c+1] == '=' && ++c && (take=2) ? GE : GT;
        break;
      case '<':
        t_tok = c+1 < src_len && src[c+1] == '=' && ++c && (take=2) ? LE : LT;
        break;
      case '\r': case '\t': break;
      case '\n': line++; pos = 0; t_tok = NL; break;
      case ' ':
        t_tok = SPACE;
        take = scanner_takespc(src+c, src_len - c);
        c += take - 1;
        break;
      case '"': case '\'':
        t_tok = STR;
        take = 1+scanner_takestr(src+c, src_len - c);
        c += take - 1;
        break;
      default:
        if (tok == ':') {
          if (c+1 < src_len && src[c+1] == '=') {
            c++;
            take = 2;
            t_tok = DEF;
          } else {
            t_tok = COLON;
          }
        } else if ((take = scanner_takeid((char*)src+c, src_len - c))) {
          t_tok = ID;
          c += take - 1;
        } else if ((take = scanner_isnum((char*)src+c, src_len - c))) {
          t_tok = NUM;
          c += take - 1;
        } else {
          printf("Unexpected character '%c' line(%d) pos(%d)\n", tok, line, pos);
        }
        break;
    }
    if (t_tok != IGNORE) {
      char* x = malloc(sizeof(char)*(1+take));
      sprintf(x, "%.*s", take, c+src-take+1);
      pos += take;
      if(t_tok == ID) {
        t_tok = keyword_token_type(x);
      }
      if (s->tokens == 0) {
        s->tokens = ll_new(token_make(t_tok, x, take, 0, line));
      } else {
        ll_append(s->tokens, token_make(t_tok, x, take, 0, line));
      }
    }
    pos++;
    c++; //lol
  }

  return s;
}

int scanner_takespc(char* t, int len) {
  int s = 0;
  while (t[s] == ' ' && s < len) {
    s++;
  }
  return s;
}

int scanner_takestr(char* t, int len) {
  int s = 0;
  char d = t[s++];
  while (t[s] != d && s < len) {
    if(t[s] == '\\' && s + 1 < len && t[s+1] == d) {
      s++;
    }
    s++;
  }
  if(t[s] != d || s >= len) {
    printf("Unterminated string.\n");
    return 0;
  }
  return s;
}

int scanner_takeid(char* t, int len) {
  int s = 0;
  while (
       (t[s] >= 'A' && t[s] <= 'Z')
    || (t[s] >= 'a' && t[s] <= 'z')
    || t[s] == '_'
    || (s > 0 && t[s] >= '0' && t[s] <= '9')
  ) {
    s++;
  }
  return s;
}

int scanner_isnum(char* t, int len) {
  int s = 0;
  while (s < len && t[s] >= '0' && t[s] <= '9') {
    s++;
  }
  return s;
}

void scanner_free(scanner* s) {
  ll_free(s->tokens);
  free(s);
}

scanner* scanner_make() {
  scanner* s = malloc(sizeof(scanner));
  s->tokens = 0;
  return s;
}
