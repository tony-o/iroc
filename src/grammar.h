#ifndef __GRAMMAR_H__
#define __GRAMMAR_H__

expression → literal
           | unary
           | binary
           | grouping ;

literal    → NUMBER | STRING | "true" | "false" | "nil" ;
grouping   → "(" expression ")" ;
unary      → ( "-" | "!" ) expression ;
binary     → expression operator expression ;
operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
           | "+"  | "-"  | "*" | "/" ;


/*
  expression -> literal | unary | binary | group
  literal -> NUMBER | STRING | true | false | undef
  group   -> '(' expression ')'
  unary   -> ( '-' | '!' ) expression
  binary  -> expression operator expression
  operator-> ('==' | '!=' | '<' | '<=' | '>' | '>='
             | '+' | '-'  | '*' | '/')


*/

#endif
