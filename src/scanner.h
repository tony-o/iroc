#ifndef __SCANNER_H__
#define __SCANNER_H__

#include "util/ll.h"
#include <stdlib.h>

typedef struct scanner {
  char* src;
  linkedlist* tokens;
} scanner;

scanner* scan(char*, int);
void scanner_free(scanner*);
scanner* scanner_make();
int scanner_isnum(char*,int);
int scanner_takeid(char*,int);
int scanner_takestr(char*,int);
int scanner_takespc(char*,int);

#endif
