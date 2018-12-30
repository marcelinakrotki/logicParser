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

//CNF
nodeType* cnfMode(nodeType* p);
nodeType* cnfTransform(nodeType* p);
nodeType* transformToBasicOperators(nodeType* p);
nodeType* applyDemorganLaws(nodeType* p);

//DNF
nodeType* dnfMode(nodeType* p);
nodeType* dnfTransform(nodeType* p);

//NOR
nodeType* norMode(nodeType* p);
nodeType* andToNor(nodeType* left, nodeType* right);
nodeType* orToNor(nodeType* left, nodeType* right);
nodeType* notToNor(nodeType* right);
nodeType* norToNor(nodeType* left, nodeType* right);
nodeType* nandToNor(nodeType* left, nodeType* right);
nodeType* xorToNor(nodeType* left, nodeType* right);


//NAND
nodeType* nandMode(nodeType* p);
nodeType* andToNand(nodeType* left, nodeType* right);
nodeType* orToNand(nodeType* left, nodeType* right);
nodeType* notToNand(nodeType* right);
nodeType* norToNand(nodeType* left, nodeType* right);
nodeType* nandToNand(nodeType* left, nodeType* right);
nodeType* xorToNand(nodeType* left, nodeType* right);

//optimization
nodeType* optimize(nodeType* p);
nodeType* optimize_xand0_xand1(nodeType* p, nodeType* left, nodeType* right);
nodeType* optimize_xandnotx(nodeType* p, nodeType* left, nodeType* right);
nodeType* optimize_xandx(nodeType* p, nodeType* left, nodeType* right);
nodeType* optimize_not0to1(nodeType* p, nodeType* left, nodeType* right);
nodeType* optimize_1and1_0or1(nodeType* p, nodeType* left, nodeType* right);

int sym[26]; /* symbol table */
int method = 0;
nodeType *createNodeOper1(int oper, nodeType* child);
nodeType *createNodeOper2(int oper, nodeType* leftChild, nodeType* rightChild);
nodeType *createNodeValue(int value);
nodeType *createNodeVariable(int variable);
void printTree(nodeType* tree);
nodeType* transformOper1ToOper2(int oper1, int oper2, nodeType* right, nodeType* left);

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
nodeType *createNodeValue(int value)
{
	printf("nodeValue\n");
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeCon;
	p->con.value = value;
	return p;
}

nodeType *createNodeVariable(int i)
{
	printf("create node variable\n");
	nodeType *p;
	if ((p = malloc(sizeof(nodeType))) == NULL)
		yyerror("out of memory");
	p->type = typeId;
	p->id.i = i;
	return p;
}

void freeNode(nodeType *p)
{
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
        if(tree->type==typeOpr && tree->opr.op[0] != NULL)
        {
            printf("( ");
            printTree(tree->opr.op[0]);
        }

        if(tree->type==typeOpr)
        {
            printOper(tree->opr.oper);
        }

        if(tree->type==typeId)
        {
            printf("%c ", 'a' + tree->id.i );
        }

        if(tree->type==typeCon)
        {
            printf("%d ", tree->con.value );
        }

        if(tree->type==typeOpr && tree->opr.op[1] != NULL)
        {
            if(tree->opr.nops==1) printf("( ");
            printTree(tree->opr.op[1]);
            printf(") ");        
        }
}

void printOper(int oper)
{
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


void yyerror(char *s)
{
	fprintf(stdout, "%s\n", s);
}

int main(int argc, char** argv)
{
    if(argc==2)
    {   
        if(strcmp(argv[1], "-cnf") == 0) 
        {
                method = cnf;
        }
        else if(strcmp(argv[1], "-dnf") == 0)
        {
                method = dnf;
        }
        else if(strcmp(argv[1], "-nor") == 0)
        {
                method = nor;
        }
        else if(strcmp(argv[1], "-nand") == 0)
        {
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
	    printTree(optimize(p));
        return 0;
    }
    else if(method == nand) 
    {
	    printTree(nandMode(p));
        return 0;
    }
    
    return 0;
}

nodeType* dnfMode(nodeType* p)
{
	return dnfTransform(applyDemorganLaws(transformToBasicOperators(p)));
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
	return cnfTransform(applyDemorganLaws(transformToBasicOperators(p)));
}

nodeType* norMode(nodeType* p)
{
	if(p->type != typeOpr){
        return p;
    }

    if(p->type == typeOpr)
    {
        nodeType* leftChild = NULL;
        nodeType* rightChild = NULL;
    
        if(p->opr.op[0] != NULL) leftChild = norMode(p->opr.op[0]);
        if(p->opr.op[1] != NULL) rightChild = norMode(p->opr.op[1]);

        switch(p->opr.oper)
        {
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

nodeType* andToNor(nodeType* left, nodeType* right)
{
    nodeType* leftChild = createNodeOper2(NOR, left, left);
    nodeType* rightChild = createNodeOper2(NOR, right, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

nodeType* orToNor(nodeType* left, nodeType* right)
{
    nodeType* leftChild = createNodeOper2(NOR, left, right);
    nodeType* rightChild = createNodeOper2(NOR, left, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

nodeType* notToNor(nodeType* right)
{
    return createNodeOper2(NOR, right, right);
}

nodeType* norToNor(nodeType* left, nodeType* right)
{
    return createNodeOper2(NOR, left, right);
}

nodeType* nandToNor(nodeType* left, nodeType* right)
{
    return notToNor(andToNor(left, right));
}

nodeType* xorToNor(nodeType* left, nodeType* right)
{
    nodeType* leftChild = andToNor(left, right);
    nodeType* rightChild = norToNor(left, right);
    return createNodeOper2(NOR, leftChild, rightChild);
}

nodeType* nandMode(nodeType* p)
{
	if(p->type != typeOpr){
        return p;
    }

    if(p->type == typeOpr){

        nodeType* leftChild = NULL;
        nodeType* rightChild = NULL;
    
        if(p->opr.op[0] != NULL)
        {
            leftChild = norMode(p->opr.op[0]);
        }
        if(p->opr.op[1] != NULL)
        {
            rightChild = norMode(p->opr.op[1]);
        }

        switch(p->opr.oper)
        {
            case AND:
                return andToNand(leftChild, rightChild);
            case OR:
                return orToNand(leftChild, rightChild);
            case NOT:
                return notToNand(rightChild);
            case NOR:
                return norToNand(leftChild, rightChild);
            case NAND:
                return nandToNand(leftChild, rightChild);
            case XOR:
                return xorToNand(leftChild, rightChild);
        }
    }
}

nodeType* andToNand(nodeType* left, nodeType* right)
{
    nodeType* child = createNodeOper2(NAND, left, right);
    return createNodeOper2(NAND, child, child);
}

nodeType* orToNand(nodeType* left, nodeType* right)
{
    nodeType* leftChild = createNodeOper2(NAND, left, left);
    nodeType* rightChild = createNodeOper2(NAND, right, right);
    return createNodeOper2(NAND, leftChild, rightChild);
}

nodeType* norToNand(nodeType* left, nodeType* right)
{
    nodeType* child = orToNand(left, right);
    return createNodeOper2(NAND, child, child);
}

nodeType* notToNand(nodeType* right)
{
    return createNodeOper2(NAND, right, right);
}

nodeType* nandToNand(nodeType* left, nodeType* right)
{
    return createNodeOper2(NAND, left, right);
}

nodeType* xorToNand(nodeType* left, nodeType* right)
{
    nodeType* middleChild = createNodeOper2(NAND, left, right);
    nodeType* leftChild = createNodeOper2(NAND, left, middleChild);
    nodeType* rightChild = createNodeOper2(NAND, middleChild, right);
    return createNodeOper2(NAND, leftChild, rightChild);
}

nodeType* transformToBasicOperators(nodeType* p)
{
    if(p->type != typeOpr)
    {
        return p;
    }
    nodeType* leftChild = NULL;
    nodeType* rightChild = NULL;

    if(p->opr.op[0] != NULL) 
    {
        leftChild = transformToBasicOperators(p->opr.op[0]);
    }
    if(p->opr.op[1] != NULL)
    {
        rightChild = transformToBasicOperators(p->opr.op[1]);
    }

    nodeType* andOper;
    nodeType* orOper;
    nodeType* notOper;

    switch(p->opr.oper)
    {
        case(NAND):
            andOper = createNodeOper2(AND, p->opr.op[0], p->opr.op[1]);
            p = createNodeOper1(NOT, andOper);
            break;
        case(XOR):
            andOper = createNodeOper2(AND, p->opr.op[0], p->opr.op[1]);
            orOper = createNodeOper2(OR, p->opr.op[0], p->opr.op[1]);
            notOper = createNodeOper1(NOT, andOper);
            p = createNodeOper2(AND, orOper, notOper);
            break;
        case(NOR):
            orOper = createNodeOper2(OR, p->opr.op[0], p->opr.op[1]);
            p = createNodeOper1(NOT, orOper);
            break;
    }
    return p;
}

nodeType* applyDemorganLaws(nodeType* node){
    if(!node) return node;
    
    if (node->type != typeOpr)
    {
        return node;
    }

    if(node->opr.oper == NOT )
    {
        nodeType* child = node->opr.op[1];
        if(child->type != typeOpr)
        {
            return node;
        }

        if(child->opr.oper == NOT)
        {
            node = child->opr.op[1];
            return applyDemorganLaws(node);
        } 
        else
        {
            int oper = child->opr.oper == AND ? OR : AND;
            nodeType* notOper1 = createNodeOper1(NOT, child->opr.op[0]);
            nodeType* notOper2 = createNodeOper1(NOT, child->opr.op[1]);
            node = createNodeOper2(oper, notOper1, notOper2);
        }
    }
    if(node->type !=typeOpr )
    {
        return node;
    }
    if (node->opr.oper != NOT)
    {
        node->opr.op[0] = applyDemorganLaws(node->opr.op[0]);
    }
    node->opr.op[1] = applyDemorganLaws(node->opr.op[1]);    
}


// 4. CNF: a OR (b AND c) -> (a OR b) AND (a OR c)
nodeType* cnfTransform(nodeType* p)
{
    if(p->type != typeOpr)
    {
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) 
    {
        left = cnfTransform(p->opr.op[0]);
    }
    if(p->opr.op[1] != NULL) 
    {
        right = cnfTransform(p->opr.op[1]);
    }

    if(p->opr.oper == OR)
    {
        if(right->type == typeOpr && right->opr.oper == AND)
        {    
            return transformOper1ToOper2(OR, AND, left, right);
        }
        if(left->type == typeOpr && left->opr.oper == AND)
        {
            return transformOper1ToOper2(OR, AND, right, left);
        }
    }
    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

nodeType* transformOper1ToOper2(int oper1, int oper2, nodeType* right, nodeType* left)
{
    nodeType* orOper1 = createNodeOper2(oper1, left, right->opr.op[0]);
    nodeType* orOper2 = createNodeOper2(oper1, left, right->opr.op[1]);
    return createNodeOper2(oper2, orOper1, orOper2);
}

// 4. DNF: a AND (b OR c) -> (a AND b) OR (a AND c)
nodeType* dnfTransform(nodeType* p)
{
    if(p->type != typeOpr)
    {
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL)
    {
        left = dnfTransform(p->opr.op[0]);
    }
    if(p->opr.op[1] != NULL)
    {
        right = dnfTransform(p->opr.op[1]);
    }

    if(p->opr.oper == AND)
    {
        if(right->type == typeOpr && right->opr.oper == OR)
        {
            return transformOper1ToOper2(AND, OR, left, right);
        }
        if(left->type == typeOpr && left->opr.oper == OR)
        {
            return transformOper1ToOper2(AND, OR, right, left);
        }

    }

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

nodeType* optimize_1and1_0or1(nodeType* p, nodeType* left, nodeType* right)
{
    if(left->type == typeCon && right->type == typeCon)
    {
        int leftVal = left->con.value;
        int rightVal = right->con.value;
        if(p->opr.oper == AND)
        {
            if(leftVal==1 && rightVal==1)
            {
                return createNodeValue(1);
            }
            else
            {
                return createNodeValue(0);
            }
        }
        else if(p->opr.oper == OR)
        {
            if(leftVal==1 || rightVal==1)
            {
                return createNodeValue(1);
            }
            else{
                return createNodeValue(0);
            }
        }
    }
    return NULL;
}

nodeType* optimize_not0to1(nodeType* p, nodeType* left, nodeType* right)
{
    if(p->opr.oper == NOT)
    {
        if(right->type == typeCon)
        {
            if(right->con.value == 0)
            {
                return createNodeValue(1);
            }
            if(right->con.value == 1)
            {
                return createNodeValue(0);
            }
        }
    }
    return NULL;
}

nodeType* optimize_xandx(nodeType* p, nodeType* left, nodeType* right)
{
    if(p->opr.oper == AND)
    {
        if(right->type == typeId && left->type == typeId)
        {
            if(right->id.i == left->id.i)
            {
                return createNodeVariable(right->id.i);
            }
        }   
    }
    return NULL;
}

nodeType* optimize_xandnotx(nodeType* p, nodeType* left, nodeType* right)
{
    if(p->opr.oper == AND)
    {
        if(right->type == typeId && left->type == typeOpr)
        {
            if(left->opr.oper == NOT)
            {
                nodeType* notsChild = left->opr.op[1];
                if(notsChild->type == typeId)
                {
                    if(right->id.i == notsChild->id.i)
                    {
                        return createNodeValue(0);
                    }
                }
            }
        }  
        if(left->type == typeId && right->type == typeOpr)
        {
            if(right->opr.oper == NOT)
            {
                nodeType* notsChild = right->opr.op[1];
                if(notsChild->type == typeId)
                {
                    if(left->id.i == notsChild->id.i)
                    {
                        return createNodeValue(0);
                    }
                }
            }
        }    
    }
    return NULL;
}

nodeType* optimize_xand0_xand1(nodeType* p, nodeType* left, nodeType* right)
{
    if(p->opr.oper == AND)
    {
        if(right->type == typeId && left->type == typeCon)
        {
            if(left->con.value == 0)
            {
                return createNodeValue(0);
            }
            else if(left->con.value == 1)
            {
                return createNodeVariable(right->id.i);
            }
        }  
        if(left->type == typeId && right->type == typeCon)
        {
            if(right->con.value == 0)
            {
                return createNodeValue(0);
            }
            else if(right->con.value == 1)
            {
                return createNodeVariable(left->id.i);  
            }
        } 
    }
    return NULL;
}

nodeType* optimize(nodeType* p)
{
    printf("Optimization______:\n");
    if(p->type != typeOpr)
    {
        return p;
    }
    nodeType* left = p->opr.op[0];
    nodeType* right = p->opr.op[1];

    if(p->opr.op[0] != NULL) left = optimize(p->opr.op[0]);
    if(p->opr.op[1] != NULL) right = optimize(p->opr.op[1]);

    nodeType* returnValue;

    if ((returnValue = optimize_1and1_0or1(p, left, right)) != NULL )
        return returnValue;
    else if( ( returnValue = optimize_not0to1(p, left, right)) != NULL )
        return returnValue;
    else if( ( returnValue = optimize_xandx(p, left, right)) != NULL )
        return returnValue;
    else if( ( returnValue = optimize_xandnotx(p, left, right)) != NULL )
        return returnValue;
    else if( ( returnValue = optimize_xand0_xand1(p, left, right)) != NULL )
        return returnValue;

   //TODO: Brakuje ORa

    p->opr.op[0]=left;
    p->opr.op[1]=right;
    return p;
}

