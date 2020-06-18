#ifndef __PARSER_H__
#define __PARSER_H__

fun   -> (!x=\s*)'fun' <id> <param>? <body>?
id    -> [a-zA-Z][a-zA-Z0-9_]*
param -> (\( (<id> (:= <literal> | <id>)?)* \))?
body  -> (x + x) <statement>

#endif
