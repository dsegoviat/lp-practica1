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
map<string, int> connectors;

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
void ASTPrintIndent(AST *a,string s) {
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

void error(string msg) {
    cout << "Error: " << msg << "." << endl;
}
/// print AST
void ASTPrint(AST *a) {
    while (a!=NULL) {
        cout<<" ";
        ASTPrintIndent(a,"");
        a=a->right;
    }
}

int getLength(AST *a, bool &result) {
    string key = a->text;
    map<string, Tube>::iterator it = tubes.find(key);
    result = (it != tubes.end());
    int length;
    if (result) length = tubes[key].length;
    else length = 0;
    return length;
}

int getDiameter(AST *a, bool &result) {
    string key = a->text;
    map<string, Tube>::iterator it = tubes.find(key);
    result = (it != tubes.end());
    int diameter;
    if (result) diameter = tubes[key].diameter;
    else diameter = 0;
    return diameter;
}

bool isNumExpr(AST *a) {
    return a->kind == "+" or a->kind == "-" or a->kind == "*" ;
}

bool isBoolExpr(AST *a) {
    return a->kind == "<" or a->kind == ">" or a->kind == "=="
            or a->kind == "AND" or a->kind == "OR" or a->kind == "NOT"
            or a->kind == "EMPTY" or a->kind == "FULL";
}

bool isVectorEmpty(string key){
    vector<string> temp = tubeVectors[key];
    for (int i = 0; i < temp.size(); ++i) {
        if (temp[i] != "null") return true;
    }
    return false;
}

bool isVectorFull(string key){
    vector<string> temp = tubeVectors[key];
    for (int i = 0; i < temp.size(); ++i) {
        if (temp[i] == "null") return false;
    }
    return true;
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
    else if (a->kind == "DIAMETER") {
        bool found = false;
        int diameter = getDiameter(child(a, 0), found);
        if (!found) {
            error(child(a, 0)->text + " does not exist");
            return 0;
        }
        else return diameter;
    }
    else if (a->kind == "LENGTH") {
        bool found = false;
        int length = getLength(child(a, 0), found);
        if (!found) {
            error(child(a, 0)->text + " does not exist");
            return 0;
        }
        else return length;
    }
    else return 0;
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
    else if (a->kind == "FULL") {
        string key = child(a, 0)->text;
        return isVectorFull(key);
    }
    else if (a->kind == "EMPTY") {
        string key = child(a, 0)->text;
        return isVectorFull(key);
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

void storeConnector(string key, AST *a) {
    connectors[key] = evaluateNumExpr(child(a, 0));
}


void createTubeVector(string key, AST *a) {
    int size = atoi(child(a, 0)->text.c_str());
    vector<string> tempTube(size, "null");
    tubeVectors[key] = tempTube;
}

void copyVector(string copy, string copied) {
    tubes[copy] = tubes[copied];
}

void consumeTube(string tube) {
    tubes.erase(tube);
}

void consumeConnector(string connector) {
    connectors.erase(connector);
}

// result stores a boolean that indicates if the tube returned is correct
Tube mergeTubeAux(AST *a, bool &result) {
    map<string, Tube>::iterator it;
    it = tubes.find(a->text);
    result = (it != tubes.end());
    return tubes[a->text];
}

int mergeConnector(AST *a, bool &result) {
    map<string, int>::iterator it;
    it = connectors.find(a->text);
    result = (it != connectors.end());
    return connectors[a->text];
}

Tube mergeTube(AST *a, bool& res, vector<string> &toEraseTubes,
    vector<string> &toEraseConnectors) {
    Tube tubeResult;
    bool res1, res2, res3;
    Tube tube1, tube2;
    int connector;

    if (child(a, 0)->kind != "MERGE") {
        tube1 = mergeTubeAux(child(a, 0), res1);
        toEraseTubes.push_back(child(a, 0)->text);
    }
    else tube1 = mergeTube(child(a, 0), res1, toEraseTubes, toEraseConnectors);

    if (child(a, 1)->kind != "MERGE") {
        connector = mergeConnector(child(a, 1), res2);
        toEraseConnectors.push_back(child(a, 1)->text);
    }
    else res2 = false;

    if (child(a, 2)->kind != "MERGE") {
        tube2 = mergeTubeAux(child(a, 2), res3);
        toEraseTubes.push_back(child(a, 2)->text);
    }
    else tube2 = mergeTube(child(a, 2), res3, toEraseTubes, toEraseConnectors);

    // error handling
    if (!res1) error("Tube " + child(a, 0)->text + " does not exist");
    if (!res2) error("Connector " + child(a, 1)->text + " does not exist");
    if (!res3) error("Tube " + child(a, 2)->text + " does not exist");

    res = res1 and res2 and res3;
    if (res) {
        if (tube1.diameter != tube2.diameter or tube1.diameter != connector) {
            cout << "Error: diameters do not match" << endl;
            res = false;
        }
        else {
            tubeResult.length = tube1.length + tube2.length;
            tubeResult.diameter = tube1.diameter;
        }
    }
    return tubeResult;
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
        else if (child(a, 1)->kind == "CONNECTOR") {
            storeConnector(child(a, 0)->text, child(a, 1));
        }
        else if (child(a, 1)->kind == "id") {
            cout << "I found a copy" << endl;
            copyVector(child(a, 0)->text, child(a, 1)->text);
        }
        else if (child(a, 1)->kind == "MERGE") {
            bool correct = false;
            vector<string> toEraseTubes;
            vector<string> toEraseConnectors;
            Tube tubeTemp = mergeTube(child(a, 1), correct, toEraseTubes, toEraseConnectors);
            if (correct) {
                string key = child(a, 0)->text;
                tubes[key] = tubeTemp;
                for (int i = 0; i < toEraseTubes.size(); ++i)
                    consumeTube(toEraseTubes[i]);
                for (int i = 0; i < toEraseConnectors.size(); ++i)
                    consumeConnector(toEraseConnectors[i]);
            }
            else error("Unable to perform MERGE");
        }
    }
    else if (a->kind == "GET") { // debug
        string key = child(a, 0)->text;
        cout << "Im getting the value for " << key << " LENGTH: " << tubes[key].length << ", DIAMETER: " << tubes[key].diameter << endl; //DEBUG
    }
    else if (a->kind == "GETVECTOR") { // debug
        string key = child(a, 0)->text;
        cout << "Getting vector: " << key << " of size: " << tubeVectors[key].size() << endl; // debug
    }
    else if (a->kind == "GETCON") { // debug
        string key = child(a, 0)->text;
        cout << "Im getting the value for " << key << ": " << connectors[key] << endl; // debug
    }
    else if (a->kind == "LENGTH") {
        bool found = false;
        int length = getLength(child(a, 0), found);
        if (!found) error(child(a, 0)->text + " does not exist");
        else cout << length << endl;
    }
    else if (a->kind == "DIAMETER") {
        bool found = false;
        int length = getDiameter(child(a, 0), found);
        if (!found) error(child(a, 0)->text +" does not exist");
        else cout << length << endl;
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

#token GETCONNECTOR "GETCON"
#token GETVECTOR "GETVECTOR" // debug
#token GET "GET" // debug

#token ASSIG "="

#token LENGTH "LENGTH"
#token DIAMETER "DIAMETER"

#token FULL "FULL"
#token EMPTY "EMPTY"

#token TUBEVECTOR "TUBEVECTOR"
#token OF "OF"
#token TUBE "TUBE"
#token CONNECTOR "CONNECTOR"

#token MERGE "MERGE"

#token ID "[a-zA-Z][a-zA-Z0-9]*"


#token SPACE "[\ \n\t]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;

ops: id_expr | getters | getters_debug | bool_expr | merge_expr;

num_expr: term ((PLUS^ | MINUS^) term)* ;
term: (NUM | getters) (TIMES^ (getters | NUM))*;

bool_expr: bool_and (OR^ bool_and)*;
bool_and: bool_not (AND^ bool_not)*;
bool_not: NOT^ bool_eval | bool_eval;
bool_eval: (NUM (LTHAN^ | MTHAN^ | EQUALS^) NUM) | bool_vector;
bool_vector: (FULL^ | EMPTY^) LPAR! ID RPAR!;

getters: (LENGTH^ | DIAMETER^) LPAR! ID RPAR!;

id_expr: ID ASSIG^ (tube_expr | ID | merge_expr);
merge_expr: MERGE^ merge_basic_expr merge_basic_expr merge_basic_expr;
merge_basic_expr: ID | (MERGE^ ID ID ID);
tube_expr: (CONNECTOR^ | TUBEVECTOR^ OF!| (TUBE^ num_expr)) num_expr;


getters_debug:gettercon | getter | gettervector;
getter: GET^ ID ; // DEBUG
gettervector: GETVECTOR^ ID ; // DEBUG
gettercon: GETCONNECTOR^ ID ; // DEBUG


//...

// TODO: remove getter and bool_expr from ops.

// ops = assignacions, LONG I DIAM, WHILES
// assignacio = connector, tub, merge, (split) <- pel final
// variables de uso unico (si hay un error no se hace el merge, deshacer todo lo que ya se ha hecho si error)
