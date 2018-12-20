%{
#include <stdio.h>
#include <stdlib.h>
#include "logic.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%

[a-z] 	{
		yylval.sIndex = *yytext - 'a';
		return VARIABLE;
	}

0 	{
		yylval.iValue = atoi(yytext);
		return INTEGER;

	}

[1-9][0-9]* {
		yylval.iValue = atoi(yytext);
		return INTEGER;
	}
[()]    return *yytext;
\n    return *yytext;

AND return AND;
NAND return NAND;
NOT return NOT;
OR return OR;
NOR return NOR;
XOR return XOR;

and return AND;
nand return NAND;
not return NOT;
or return OR;
nor return NOR;
xor return XOR;

[ \t]+ ;

. yyerror("Unknown character");

%%

int yywrap(void) {
	return 1;
}
