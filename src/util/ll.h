#ifndef __LL_H__
#define __LL_H__

#include <stdlib.h>

typedef struct linkedlist {
  void* head,
      * obj,
      * next;
} linkedlist;

linkedlist* ll_append(linkedlist*,void*);
linkedlist* ll_new(void*);
void ll_foreach(linkedlist*,void (*call)(void*));
void ll_free(linkedlist*);

#endif
