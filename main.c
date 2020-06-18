//#include "tokens.h"
#include "scanner.h"
#include "token.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void pf(void* o) {
  printf("token: %s\n", token_str(o));
}

int main(int argc, char* argv[]) {
  if(argc != 2){
    printf("Please provide a file to parse.\n");
    return 255;
  }
  char* src;
  long src_len;
  FILE* in = fopen(argv[1], "rb");
  if(!in){
    printf("Unable to open file: %s\n", argv[1]);
    return 128;
  }
  fseek(in, 0, SEEK_END);
  src_len = ftell(in);
  src = malloc(src_len + 1);
  src[src_len+1] = 0;
  fseek(in, 0, SEEK_SET);
  fread(src, src_len, 1, in);
  fclose(in);

  printf("scanning src:\n%s\n(EOF)\n", src);
  scanner* s = scan(src, strlen(src));
  ll_foreach(s->tokens, pf); 
  scanner_free(s);
  
  return 0;
}
