#header
<<
#include <string>
#include <iostream>
#include <map>

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

map<string,int> m;

void zzcr_attr(Attrib *attr, int type, char *text) {
    if (type == NUM) {
        attr->kind = "intconst";
        attr->text = text;
    } else if (type == IDTUBE) {
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
        cout << "Returning constant: "<< atoi(a->text.c_str()) << endl; // debug
        return atoi(a->text.c_str());
    }
    else if (a->kind == "+") {
        cout << "Sum: " << child(a, 0)->text << " + " << child(a, 1)->text << endl;
        return evaluateNumExpr(child(a,0)) + evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "-") {
        cout << "Sub: " << child(a, 0)->text << " - " << child(a, 1)->text << endl;
        return evaluateNumExpr(child(a,0)) - evaluateNumExpr(child(a,1));
    }
    else if (a->kind == "*") {
        cout << "Mult: " << child(a, 0)->text << " * " << child(a, 1)->text << endl;
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
    return false;
}

void execute(AST *a) {
    if (a == NULL) return;
    else if  (a->kind == "=") {
        m[child(a, 0)->text] = evaluateNumExpr(child(a, 1));
    }
    else if (a->kind == "GET") { // debug
        string key = child(a, 0)->text;
        cout << "Im getting the value for " << key << ": " << m[key] << endl; //DEBUG
    }
    // else if (isBoolExpr(a)) {
    //     cout << "I found a boolean expression. Result: "
    //             << evaluateBoolExpr(child(a, 0)) << endl;
    // }
    else { // exprnum (isNumExpr(a))
        cout << "Result: " << evaluateNumExpr(a) << endl;
    }
    execute(a->right);
}

int main() {
    AST *root = NULL;
    ANTLR(plumber(&root), stdin);
    ASTPrint(root);
    execute(root); // DEBUG
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

#token GET "GET" // debug

#token ASSIG "="

#token IDTUBE "[a-zA-Z][a-zA-Z0-9]"

#token SPACE "[\ \n\t]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;
ops: num_expr | id_expr | getter /* bool_expr */;
num_expr: term ((PLUS^ | MINUS^) term)* ;
term: NUM (TIMES^ NUM)* ;
//bool_expr: bool_term ((AND^ | OR^) bool_term)* ;
//bool_term: (NOT^)? num_expr (AND^ | OR^) num_expr;
id_expr: IDTUBE ASSIG^ num_expr;
getter: GET^ IDTUBE ; // debug
//...

// TODO: remove getter and bool_expr from ops.

// ops = assignacions, LONG I DIAM, WHILES
// assignacio = connector, tub, merge, (split) <- pel final
// variables de uso unico (si hay un error no se hace el merge, deshacer todo lo que ya se ha hecho si error)
