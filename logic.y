%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include "logic.h"

//nodeType *opr(int oper, int nops, ...);
enum ProgramMode {cnf=1, dnf, nor, nand};
void freeNode(nodeType *p);
int ex(nodeType *p);
int yylex(void);
void yyerror(char *s);
int cnfMode(nodeType* p);
int dnfMode(nodeType* p);
int norMode(nodeType* p);
int nandMode(nodeType* p);

int sym[26]; /* symbol table */
int method = 0;
nodeType *createNodeOper1(int oper, nodeType* child);
nodeType *createNodeOper2(int oper, nodeType* leftChild, nodeType* rightChild);
nodeType *createNodeValue(int value);
nodeType *createNodeVariable(int variable);
void printTree(nodeType* tree);
%}

%union {
	int iValue; /* integer value */
	char sIndex; /* symbol table index */
	nodeType *nPtr; /* node pointer */
};

%token <iValue> INTEGER
%token <sIndex> VARIABLE
%nonassoc NOT
%left AND OR NOR XOR NAND
%type <nPtr> stmt expr

%%
program:
	function { exit(0); }
	;

function:
	function stmt { ex($2); freeNode($2); }
	| /* NULL */
	;

stmt:
	'\n' { $$ = createNodeOper2(';', NULL, NULL); } 
	| expr '\n' { $$ = $1; printf("Function stmt\n"); }
	;

expr:
	 INTEGER { $$ = createNodeValue($1); }
	|VARIABLE {$$=createNodeVariable($1);}
	|NOT expr {$$=createNodeOper1(NOT, $2);}
	|expr AND expr  {$$=createNodeOper2(AND, $1, $3);}
	|expr NAND expr {$$=createNodeOper2(NAND, $1, $3);}
	|expr OR expr   {$$=createNodeOper2(OR, $1, $3);}
	|expr NOR expr  {$$=createNodeOper2(NOR, $1, $3);}
	|expr XOR expr  {$$=createNodeOper2(XOR, $1, $3);}
	;

%%

#define SIZEOF_NODETYPE ((char *)&p->con - (char *)p)

nodeType *createNodeValue(int value) {
	printf("nodeValue\n");
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeCon;
	p->con.value = value;
	return p;
}

nodeType *createNodeVariable(int i) {
	printf("create node variable\n");
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeId;
	p->id.i = i;
	return p;
}

void freeNode(nodeType *p) {
	int i;
	if (!p) return;
	if (p->type == typeOpr) {
		for (i = 0; i < p->opr.nops; i++)
			freeNode(p->opr.op[i]);
	}
	free (p);
}
nodeType *createNodeOper1(int oper, nodeType* child)
{
        printf("nodeOper1\n");
        nodeType *p;
        if ((p = malloc(sizeof(nodeType) + sizeof(nodeType *))) == NULL)
                yyerror("out of memory");
        p->type = typeOpr;
        p->opr.oper = oper;
        p->opr.nops = 1;
        p->opr.op[0] = child;
        return p;
}
nodeType *createNodeOper2(int oper, nodeType* leftChild, nodeType* rightChild)
{
        printf("nodeOper2\n");

        nodeType *p;
        if ((p = malloc(sizeof(nodeType) + ( 2 * sizeof(nodeType *)))) == NULL)
                yyerror("out of memory");
        p->type = typeOpr;
        p->opr.oper = oper;
        p->opr.nops = 2;
        p->opr.op[0] = leftChild;
        p->opr.op[1] = rightChild;
        return p;
}

void printTree(nodeType* tree)
{
        printf("printing tree\n");
}


void yyerror(char *s) {
	fprintf(stdout, "%s\n", s);
}

int main(int argc, char** argv) {
    if(argc==2)
    {   
        if(strcmp(argv[1], "-cnf") == 0) {
                method = cnf;
        }
        if(strcmp(argv[1], "-dnf") == 0) {
                method = dnf;
        }
        if(strcmp(argv[1], "-nor") == 0) {
                method = nor;
        }
        if(strcmp(argv[1], "-nand") == 0) {
                method = nand;
        }
    }   
    else
    {   
        printf("Not enough parameters\n");
        return 1;
    } 	
    
    yyparse();
    return 0;
}


static int lbl;
int ex(nodeType *p)
{   
    if(method == cnf) 
    {
	cnfMode(p);
    }
    else if(method == dnf) 
    {
	dnfMode(p);
    }
    else if(method == nor) 
    {
	norMode(p);
    }
    else if(method == nand) 
    {
	nandMode(p);
    }
    int lbl1, lbl2;
    if (!p) 
    	return 0;
    
    switch(p->type) {
        case typeCon:
            printf("\tpush\t%d\n", p->con.value);
            break;
        case typeId:
            printf("\tpush\t%c\n", p->id.i + 'a');
            break;
        case typeOpr:
            switch(p->opr.oper) {
                /*case WHILE:
                    printf("L%03d:\n", lbl1 = lbl++);
                    ex(p->opr.op[0]);
                    printf("\tjz\tL%03d\n", lbl2 = lbl++);
                    ex(p->opr.op[1]);
                    printf("\tjmp\tL%03d\n", lbl1);
                    printf("L%03d:\n", lbl2);
                    break;
                case IF:
                    ex(p->opr.op[0]);
                    if (p->opr.nops > 2) {
                        printf("\tjz\tL%03d\n", lbl1 = lbl++);
                        ex(p->opr.op[1]);
                        printf("\tjmp\tL%03d\n", lbl2 = lbl++); printf("L%03d:\n", lbl1);
                        ex(p->opr.op[2]); printf("L%03d:\n", lbl2);
                    } else {
                        printf("\tjz\tL%03d\n", lbl1 = lbl++); ex(p->opr.op[1]);
                        printf("L%03d:\n", lbl1); 
                    }
                    break;
                case PRINT:
                    ex(p->opr.op[0]);
                    printf("\tprint\n");
                    break;*/
                case '=':
                    ex(p->opr.op[1]);
                    printf("\tpop\t%c\n", p->opr.op[0]->id.i + 'a');
                    break;
                default: 
                    ex(p->opr.op[0]);
                    ex(p->opr.op[1]); 
		    switch(p->opr.oper) {
			case '+': printf("\tadd\n"); break;
			case '-': printf("\tsub\n"); break;
			case '*': printf("\tmul\n"); break;
			case '/': printf("\tdiv\n"); break;
			case '<': printf("\tcompLT\n"); break;
			case '>': printf("\tcompGT\n"); break;
			case AND: printf("\tcompAND\n"); break;
			case NAND: printf("\tcompNAND\n"); break;
			case NOR: printf("\tcompNOR\n"); break;
			case OR: printf("\tcompOR\n"); break;
			case XOR: printf("\tcompXOR\n"); break;
			case NOT: printf("\tcompNOT\n"); break;
		    }
            }
        }
    
    return 0;
}

int dnfMode(nodeType* p)
{
	printf("DNF type");
	return 0;
}

int cnfMode(nodeType* p)
{
	printf("CNF type");
	return 0;
}
int nandMode(nodeType* p)
{
	printf("Nand type");
	return 0;
}
int norMode(nodeType* p)
{
	printf("Nor type");
	return 0;
}
