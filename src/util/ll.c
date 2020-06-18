#include "util/ll.h"

linkedlist* ll_append(linkedlist* n, void* o) {
  linkedlist* x = n;
  while(x->next != 0) {
    x = x->next;
  }
  linkedlist *y = malloc(sizeof(linkedlist));
  y->obj = o;
  y->head = n->head;
  y->next = 0;
  x->next = y;
  return y;
}

linkedlist* ll_new(void* o) {
  linkedlist *x = malloc(sizeof(linkedlist));
  x->head = x; //id
  x->obj = o;
  x->next = 0;
  return x;
}

void ll_foreach(linkedlist* start, void (*call)(void*)) {
  linkedlist* x = start;
  while(x->next != 0) {
    call(x->obj);
    x = x->next;
  }
  call(x->obj);
}

void ll_free2(void* x) {
  if (x != 0) {
    free(x);
  }
}

void ll_free(linkedlist* ll) {
  ll_foreach(ll, ll_free2);
}
