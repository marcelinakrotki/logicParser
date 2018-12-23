typedef enum { typeCon, typeId, typeOpr } nodeEnum;
// typedef enum { NOT=260, AND, OR, NOR, XOR, NAND } operEnum;

/* constants */
typedef struct {
	int value; /* value of constant */
} conNodeType;
	
/* identifiers */
typedef struct {
	int i; /* subscript to sym array */
} idNodeType;

/* operators */
typedef struct {	
	int oper; /* operator */
	int nops; /* number of operands */
	struct nodeTypeTag *op[1]; /* operands, extended at runtime */
} oprNodeType;

typedef struct nodeTypeTag {
	nodeEnum type; /* type of node */
	union {
		conNodeType con; /* constants */
		idNodeType id; /* identifiers */
		oprNodeType opr; /* operators */
	};
} nodeType;
extern int sym[26];
