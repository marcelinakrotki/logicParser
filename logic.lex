%{
#include <stdio.h>
#include <stdlib.h>
void yyerror(char *);
#include "logic.h"
#include "y.tab.h"
%}

%%

(0|1)	 {
		yylval.value = atoi(yytext);
		return NUM;
	 }
[a-zA-Z] {
		yylval.index = yytext[0];
		return VARIABLE;
	 }
\n	 {return *yytext; } ;
AND return AND;
NAND return NAND;
NOT return NOT;
OR return OR;
NOR return NOR;
XOR return XOR;

%%
	

int yywrap(void) {
 return 1;
} 
