#header
<<
#include <string>
#include <iostream>
#include <map>
#include <vector>

using namespace std;

// struct to store information about tokens

typedef struct {
    string kind;
    string text;
} Attrib;

// function to fill token information (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields for AST nodes
#define AST_FIELDS string kind; string text;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr, int ttype, char *textt);
>>

<<
#include <cstdlib>
#include <cmath>
// function to fill token information

struct Tube {
    int length;
    int diameter;
};

map<string, vector<string> > tubeVectors;
map<string, Tube> tubes;
map<string,int> m;

void zzcr_attr(Attrib *attr, int type, char *text) {
    if (type == NUM) {
        attr->kind = "intconst";
        attr->text = text;
    } else if (type == ID) {
        attr->kind = "id";
        attr->text = text;
    } else {
        attr->kind = text;
        attr->text = "";
    }
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {
    AST* as = new AST;
    as->kind = attr->kind;
    as->text = attr->text;
    as->right = NULL;
    as->down = NULL;
    return as;
}

/// create a new "list" AST node with one element
AST* createASTlist(AST *child) {
    AST *as=new AST;
    as->kind="list";
    as->right=NULL;
    as->down=child;
    return as;
}

/// get nth child of a tree. Count starts at 0.
/// if no such child, returns NULL
AST* child(AST *a,int n) {
    AST *c=a->down;
    for (int i=0; c!=NULL && i<n; i++) c=c->right;
    return c;
}

/// print AST, recursively, with indentation
void ASTPrintIndent(AST *a,string s)
{
    if (a==NULL) return;

    cout<<a->kind;
    if (a->text!="") cout<<"("<<a->text<<")";
    cout<<endl;

    AST *i = a->down;
    while (i!=NULL && i->right!=NULL) {
        cout<<s+"  \\__";
        ASTPrintIndent(i,s+"  |"+string(i->kind.size()+i->text.size(),' '));
        i=i->right;
    }

    if (i!=NULL) {
        cout<<s+"  \\__";
        ASTPrintIndent(i,s+"   "+string(i->kind.size()+i->text.size(),' '));
        i=i->right;
    }
}

/// print AST
void ASTPrint(AST *a)
{
    while (a!=NULL) {
        cout<<" ";
        ASTPrintIndent(a,"");
        a=a->right;
    }
}

int getLength(AST *a) {
    string key = a->text;
    return tubes[key].length;
}

int getDiameter(AST *a) {
    string key = a->text;
    return tubes[key].diameter;
}

bool isNumExpr(AST *a) {
    return a->kind == "+" or a->kind == "-" or a->kind == "*" ;
}

bool isBoolExpr(AST *a) {
    return a->kind == "<" or a->kind == ">" or a->kind == "=="
            or a->kind == "AND" or a->kind == "OR" or a->kind == "NOT";
}

int evaluateNumExpr(AST *a) {
    if (a == NULL) return 0;
    else if (a->kind == "intconst") {
        return atoi(a->text.c_str());
    }
    else if (a->kind == "+") {
        return evaluateNumExpr(child(a,0)) + evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "-") {
        return evaluateNumExpr(child(a,0)) - evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "*") {
        return evaluateNumExpr(child(a,0)) * evaluateNumExpr(child(a,1));
    }
}

bool evaluateBoolExpr(AST *a) {
    if (a->kind == "AND") {
        return evaluateBoolExpr(child(a,0)) and evaluateBoolExpr(child(a,1));
    }
    else if (a->kind == "OR") {
        return evaluateBoolExpr(child(a,0)) or evaluateBoolExpr(child(a,1));
    }
    else if (a->kind == "NOT") {
        return not evaluateBoolExpr(child(a, 0));
    }
    else if (a->kind == ">") {
        return evaluateNumExpr(child(a,0)) > evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "<") {
        return evaluateNumExpr(child(a,0)) < evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "==") {
        return evaluateNumExpr(child(a, 0)) == evaluateNumExpr(child(a, 1));
    }
    else if (a->kind == "LENGTH") {
        return getLength(child(a, 0));
    }
    else if (a->kind == "DIAMETER") {
        return getDiameter(child(a, 0));
    }
    return false;
}

void storeTube(string key, AST *a) {
    Tube tempTube;
    int length = evaluateNumExpr(child(a, 0));
    int diam = evaluateNumExpr(child(a, 1));
    tempTube.length = length;
    tempTube.diameter = diam;
    tubes[key] = tempTube;
}


void createTubeVector(string key, AST *a) {
//atoi(a->text.c_str())
    int size = atoi(child(a, 0)->text.c_str());
    vector<string> tempTube(size, "null");
    tubeVectors[key] = tempTube;
}

void execute(AST *a) {
    if (a == NULL) return;
    else if (a->kind == "=") {
        if (child(a, 1)->kind == "TUBE") {
            storeTube(child(a, 0)->text, child(a, 1));
        }
        else if (child(a, 1)->kind == "TUBEVECTOR") {
	    createTubeVector(child(a, 0)->text, child(a, 1));
        }
    }
    else if (a->kind == "GET") { // debug
        string key = child(a, 0)->text;
        cout << "Im getting the value for " << key << " LENGTH: " << tubes[key].length << ", DIAMETER: " << tubes[key].diameter << endl; //DEBUG
    }
    else if (a->kind == "GETVECTOR") { // debug
        string key = child(a, 0)->text;
        cout << "Getting vector: " << key  << " of size: " << tubeVectors[key].size() << endl; //DEBUG
    }
    else if (a->kind == "LENGTH") {
        cout << getLength(child(a, 0)) << endl;
    }
    else if (a->kind == "DIAMETER") {
        cout << getDiameter(child(a, 0)) << endl;
    }
    else if (isBoolExpr(a)) {
        cout << "I found a boolean expression. Result: " 
                << evaluateBoolExpr(a) << endl;
    }
    else { // exprnum (isNumExpr(a))
        cout << "Result: " << evaluateNumExpr(a) << endl;
    }
    execute(a->right);
}

int main() {
    AST *root = NULL;
    ANTLR(plumber(&root), stdin);
    ASTPrint(root);
    execute(root->down); 
}
>>

#lexclass START
//...

#token NUM "[0-9]+"

#token PLUS "\+"
#token MINUS "\-"
#token TIMES "\*"

#token EQUALS "=="
#token LTHAN "<"
#token MTHAN ">"
#token NOT "NOT"
#token AND "AND"
#token OR "OR"

#token LPAR "\("
#token RPAR "\)"

#token GETVECTOR "GETVECTOR" // debug
#token GET "GET" // debug

#token ASSIG "="

#token LENGTH "LENGTH"
#token DIAMETER "DIAMETER"
#token TUBEVECTOR "TUBEVECTOR"
#token TUBE "TUBE"
#token ID "[a-zA-Z][a-zA-Z0-9]*"


#token SPACE "[\ \n\t]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;

ops: id_expr | getter | getters | gettervector;

num_expr: term ((PLUS^ | MINUS^) term)* ;
term: NUM (TIMES^ NUM)* | getters;

bool_expr: bool_or (AND^ bool_or)*;
bool_or: bool_not (OR^ bool_not)*;
bool_not: NOT^ bool_eval | bool_eval;
bool_eval: NUM (LTHAN^ | MTHAN^ | EQUALS^) NUM;

getters: (LENGTH^ | DIAMETER^) LPAR! ID RPAR!;

id_expr: ID ASSIG^ tube_expr;
tube_expr: (TUBEVECTOR^ | (TUBE^ num_expr)) num_expr;


getter: GET^ ID ; // DEBUG
gettervector: GETVECTOR^ ID ; // DEBUG


//...

// TODO: remove getter and bool_expr from ops.

// ops = assignacions, LONG I DIAM, WHILES
// assignacio = connector, tub, merge, (split) <- pel final
// variables de uso unico (si hay un error no se hace el merge, deshacer todo lo que ya se ha hecho si error)
