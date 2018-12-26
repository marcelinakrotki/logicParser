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

nodeType* cnfMode(nodeType* p);
nodeType* removeDoubleNegation(nodeType* p);
nodeType* deMorganOrToAnd(nodeType* p);
nodeType* deMorganAndToOr(nodeType* p);
nodeType* cnfTransform(nodeType* p);

nodeType* dnfMode(nodeType* p);
nodeType* dnfTransform(nodeType* p);

nodeType* norMode(nodeType* p);
nodeType* andToNor(nodeType* left, nodeType* right);
nodeType* orToNor(nodeType* left, nodeType* right);
nodeType* notToNor(nodeType* right);
nodeType* norToNor(nodeType* left, nodeType* right);
nodeType* nandToNor(nodeType* left, nodeType* right);
nodeType* xorToNor(nodeType* left, nodeType* right);

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
    |'(' expr ')' { $$ = $2; }
	;

%%

#define SIZEOF_NODETYPE ((char *)&p->con - (char *)p)
void printOper(int oper);
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
        p->opr.op[1] = child;
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
        if(tree->type==typeOpr && tree->opr.op[0] != NULL){
            printf("( ");
            printTree(tree->opr.op[0]);
        }
        if(tree->type==typeOpr){
            printOper(tree->opr.oper);
        }
        if(tree->type==typeId){
            printf("%c ", 'a' + tree->id.i );
        }
        if(tree->type==typeOpr && tree->opr.op[1] != NULL){
            if(tree->opr.nops==1) printf("( ");
            printTree(tree->opr.op[1]);
            printf(") ");        
        }
}

void printOper(int oper){
    switch(oper){
        case NOT: 
            printf("NOT ");
            break;
        case AND:
            printf("AND ");
            break;
        case OR:
            printf("OR ");
            break;
        case NOR:
            printf("NOR ");
            break;
        case XOR:
            printf("XOR ");
            break;
        case NAND:
            printf("NAND ");
            break;
        default:
            printf("%d ", oper);
    }
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
	    printTree(cnfMode(p));
        return 0;
    }
    else if(method == dnf) 
    {
	    printTree(dnfMode(p));
        return 0;
    }
    else if(method == nor) 
    {
	    printTree(norMode(p));
        return 0;
    }
    else if(method == nand) 
    {
	    nandMode(p);
    }
    
    return 0;
}

nodeType* dnfMode(nodeType* p)
{
	return dnfTransform(deMorganAndToOr(deMorganOrToAnd(removeDoubleNegation(p))));
}

/*
    Sprowadzenie do cnf/dnf:
    1. Eliminacja zagnieżdżonych negacji: NOT(NOT a) -> a
    2. De Morgan: NOT(a OR b) -> NOT a AND NOT b
    3. De MOrgan: NOT(a AND b) -> NOT a OR NOT b
    4. CNF: a OR (b AND c) -> (a OR b) AND (a OR c)
    4. DNF: a AND (b OR c) -> (a AND b) OR (a AND c)
*/

nodeType* cnfMode(nodeType* p)
{
	return cnfTransform(deMorganAndToOr(deMorganOrToAnd(removeDoubleNegation(p))));
}
int nandMode(nodeType* p)
{
	printf("Nand type");
	return 0;
}
nodeType* norMode(nodeType* p)
{
	if(p->type == typeId){
        return p;
    }

    if(p->type == typeOpr){

        nodeType* leftChild = NULL;
        nodeType* rightChild = NULL;
    
        if(p->opr.op[0] != NULL) leftChild = norMode(p->opr.op[0]);
        if(p->opr.op[1] != NULL) rightChild = norMode(p->opr.op[1]);

        switch(p->opr.oper){
            case AND:
                return andToNor(leftChild, rightChild);
            case OR:
                return orToNor(leftChild, rightChild);
            case NOT:
                return notToNor(rightChild);
            case NOR:
                return norToNor(leftChild, rightChild);
            case NAND:
                return nandToNor(leftChild, rightChild);
            case XOR:
                return xorToNor(leftChild, rightChild);
        }
    }
}

nodeType* andToNor(nodeType* left, nodeType* right){
    nodeType* leftChild = createNodeOper2(NOR, left, left);
    nodeType* rightChild = createNodeOper2(NOR, right, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

nodeType* orToNor(nodeType* left, nodeType* right){
    nodeType* leftChild = createNodeOper2(NOR, left, right);
    nodeType* rightChild = createNodeOper2(NOR, left, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

nodeType* notToNor(nodeType* right){
    return createNodeOper2(NOR, right, right);
}

nodeType* norToNor(nodeType* left, nodeType* right){
    return createNodeOper2(NOR, left, right);
}

nodeType* nandToNor(nodeType* left, nodeType* right){
    return notToNor(andToNor(left, right));
}

nodeType* xorToNor(nodeType* left, nodeType* right){
    nodeType* leftChild = andToNor(left, right);
    nodeType* rightChild = norToNor(left, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

// 1. Eliminacja zagnieżdżonych negacji: NOT(NOT a) -> a
nodeType* removeDoubleNegation(nodeType* p){
 	if(p->type == typeId){
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = removeDoubleNegation(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = removeDoubleNegation(p->opr.op[1]);

    if(p->opr.oper == NOT){
        nodeType* child = right;
        if(child->type == typeOpr && child->opr.oper == NOT){
            return child->opr.op[1]; 
        }
    } 

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

// 2. De Morgan: NOT(a OR b) -> NOT a AND NOT b
nodeType* deMorganOrToAnd(nodeType* p){
    if(p->type == typeId){
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = deMorganOrToAnd(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = deMorganOrToAnd(p->opr.op[1]);

    if(p->opr.oper == NOT){
        nodeType* child = right;
        if(child->type == typeOpr && child->opr.oper == OR){
            return createNodeOper2(AND,
                createNodeOper1(NOT,child->opr.op[0]),
                createNodeOper1(NOT,child->opr.op[1])); 
        }
    }

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

// 3. De MOrgan: NOT(a AND b) -> NOT a OR NOT b
nodeType* deMorganAndToOr(nodeType* p){
    if(p->type == typeId){
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = deMorganAndToOr(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = deMorganAndToOr(p->opr.op[1]);

    if(p->opr.oper == NOT){
        nodeType* child = right;
        if(child->type == typeOpr && child->opr.oper == AND){
            return createNodeOper2(OR,
                createNodeOper1(NOT,child->opr.op[0]),
                createNodeOper1(NOT,child->opr.op[1])); 
        }
    }

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

// 4. CNF: a OR (b AND c) -> (a OR b) AND (a OR c)
nodeType* cnfTransform(nodeType* p){
    if(p->type == typeId){
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = cnfTransform(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = cnfTransform(p->opr.op[1]);

    if(p->opr.oper == OR){
        if(right->type == typeOpr){
            if(right->opr.oper == AND){
                return createNodeOper2(AND,
                    createNodeOper2(OR,left,right->opr.op[0] ),
                    createNodeOper2(OR,left,right->opr.op[1]));
            }
        }
        // w drugą stronę
        if(left->type == typeOpr){
            if(left->opr.oper == AND){
                return createNodeOper2(AND,
                    createNodeOper2(OR,right,left->opr.op[0] ),
                    createNodeOper2(OR,right,left->opr.op[1]));
            }
        }
    }

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

// 4. DNF: a AND (b OR c) -> (a AND b) OR (a AND c)
nodeType* dnfTransform(nodeType* p){
    if(p->type == typeId){
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = dnfTransform(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = dnfTransform(p->opr.op[1]);

    if(p->opr.oper == AND){
        if(right->type == typeOpr){
            if(right->opr.oper == OR){
                return createNodeOper2(OR,
                    createNodeOper2(AND,left,right->opr.op[0] ),
                    createNodeOper2(AND,left,right->opr.op[1]));
            }
        }
        // w drugą stronę
        if(left->type == typeOpr){
            if(left->opr.oper == OR){
                return createNodeOper2(OR,
                    createNodeOper2(AND,right,left->opr.op[0] ),
                    createNodeOper2(AND,right,left->opr.op[1]));
            }
        }
    }

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}