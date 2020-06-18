#include "token.h"

char* token_str(token *a){
  char* r = malloc(sizeof(a->type) + a->val_l + 2);
  sprintf(r, "[%s] '%s'", token_type_s[a->type], a->type == NL ? "\\n" : a->val);
  return r;
}

token* token_make(token_type tt, char* v, int v_l, void* l, int n) {
  token* t = malloc(sizeof(token));
  t->type = tt;
  t->val = v;
  t->val_l = v_l;
  t->literal = l;
  t->line = n;
  return t;
}
