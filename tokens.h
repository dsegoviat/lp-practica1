#ifndef tokens_h
#define tokens_h
/* tokens.h -- List of labelled tokens and stuff
 *
 * Generated from: plumber.g
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-2001
 * Purdue University Electrical Engineering
 * ANTLR Version 1.33MR33
 */
#define zzEOF_TOKEN 1
#define NUM 2
#define PLUS 3
#define MINUS 4
#define TIMES 5
#define EQUALS 6
#define LTHAN 7
#define MTHAN 8
#define NOT 9
#define AND 10
#define OR 11
#define LPAR 12
#define RPAR 13
#define GET 14
#define ASSIG 15
#define IDTUBE 16
#define SPACE 17

#ifdef __USE_PROTOS
void plumber(AST**_root);
#else
extern void plumber();
#endif

#ifdef __USE_PROTOS
void ops(AST**_root);
#else
extern void ops();
#endif

#ifdef __USE_PROTOS
void num_expr(AST**_root);
#else
extern void num_expr();
#endif

#ifdef __USE_PROTOS
void term(AST**_root);
#else
extern void term();
#endif

#ifdef __USE_PROTOS
void id_expr(AST**_root);
#else
extern void id_expr();
#endif

#ifdef __USE_PROTOS
void getter(AST**_root);
#else
extern void getter();
#endif

#endif
extern SetWordType zzerr1[];
extern SetWordType zzerr2[];
extern SetWordType setwd1[];
