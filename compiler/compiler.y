%{
#include <cstdio>
#include <cstdlib>
#include <string>
#include "constant.h"
#include "type.h"
#include "declaration.h"
#include "statement.h"
#include "expression.h"
#include "semantic.h"
#include "utils.h"
#include <iostream>
#include <list>
#include <cassert>

Node rootNode;

extern char *yytext;
extern int column;
extern FILE * yyin;
extern FILE * yyout;
extern int yylineno;

extern "C"{
    void yyerror(const char *s);
    extern int yylex(void);
}
%}

%union {
    struct Expr_ *expr;
    struct Stmt_ *stmt;
    struct Decl_ *decl;
    struct Type_ *type;
    std::list<struct Stmt_ *> *stmtList;
    std::list<struct Decl_ *> *declList;
    std::list<struct Expr_ *> *exprList;
    std::list<std::list<struct Decl_ *> *> *declsList;
    char *sval;
    int operator_;
}

%type <expr> expression primary_expression postfix_expression
assignment_expression unary_expression cast_expression
multiplicative_expression additive_expression shift_expression
relational_expression equality_expression and_expression
exclusive_or_expression inclusive_or_expression
logical_and_expression logical_or_expression conditional_expression
constant_expression initializer initializer_list

%type <exprList> argument_expression_list

%type <stmt> statement labeled_statement compound_statement
expression_statement selection_statement iteration_statement
jump_statement

%type <stmtList> statement_list

%type <decl> translation_unit function_definition init_declarator declarator direct_declarator parameter_declaration
direct_abstract_declarator abstract_declarator

%type <declList> declaration external_declaration init_declarator_list parameter_type_list parameter_list identifier_list

%type <declsList> declaration_list

%type <type> declaration_specifiers type_specifier pointer

%type <operator_> unary_operator assignment_operator

%token <sval> IDENTIFIER
%token <expr> CONSTANT STRING_LITERAL
%token SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%start translation_unit
%%

/*expression*/

primary_expression
	: IDENTIFIER {
	    $$ = (Expr)new DeclRefExpr_(std::string($1));
		$$->setSourceLoc(yylineno, column);
	    free($1);
	    rootNode = (Node)$$;
	}
	| CONSTANT {
        $$ = (Expr)$1;
        rootNode = (Node)$$;
	}
	| STRING_LITERAL {
        $$ = (Expr)$1;
        rootNode = (Node)$$;
    }
	| '(' expression ')' {
	    ParenExpr p = new ParenExpr_($2);
		p->setSourceLoc(yylineno, column); 
	    $$ = (Expr)p;
	    rootNode = (Node)$$;
	}
	;

postfix_expression
	: primary_expression { $$ = $1; rootNode = (Node)$$; }
	| postfix_expression '[' expression ']' {
        $$ = (Expr)new ArraySubscriptExpr_($1, $3);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| postfix_expression '(' ')' {
        $$ = (Expr)new CallExpr_($1);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| postfix_expression '(' argument_expression_list ')' {
	    $$ = (Expr)new CallExpr_($1, *$3);
		$$->setSourceLoc(yylineno, column); 
	    delete $3;
        rootNode = (Node)$$;
	}
	| postfix_expression '.' IDENTIFIER {
        $$ = (Expr)new MemberExpr_($1, $3, false);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| postfix_expression PTR_OP IDENTIFIER {
        $$ = (Expr)new MemberExpr_($1, $3, true);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| postfix_expression INC_OP {
        $$ = (Expr)new UnaryOpExpr_($1, OP_UNARY_DOUBLEADD, true);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| postfix_expression DEC_OP {
        $$ = (Expr)new UnaryOpExpr_($1, OP_UNARY_DOUBLEMINUS, true);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

//OP_BINARY_COMMA
argument_expression_list
	: assignment_expression {
	    $$ = new std::list<Expr>();
	    $$->push_back($1);
	}
	| argument_expression_list ',' assignment_expression {
	    $1->push_back($3);
	    $$ = $1;
	}
	;

unary_expression
	: postfix_expression { $$ = $1; }
	| INC_OP unary_expression {
	    $$ = (Expr)new UnaryOpExpr_($2, OP_UNARY_DOUBLEADD, false);
		$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	| DEC_OP unary_expression {
	    $$ = (Expr)new UnaryOpExpr_($2, OP_UNARY_DOUBLEMINUS, false);
		$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	| unary_operator cast_expression {
	    $$ = (Expr)new UnaryOpExpr_($2, $1, false);
		$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	| SIZEOF unary_expression {
        $$ = (Expr)new UnaryOpExpr_($2, OP_UNARY_SIZEOF, false);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| SIZEOF '(' type_name ')'{

	}
	;

unary_operator
	: '&' { $$ = OP_UNARY_AND; }
	| '*' { $$ = OP_UNARY_STAR; }
	| '+' { $$ = OP_UNARY_POSITIVE; }
	| '-' { $$ = OP_UNARY_NEGATIVE; }
	| '~' { $$ = OP_UNARY_NOT; }
	| '!' { $$ = OP_UNARY_LOGICAL_NOT; }
	;

cast_expression
	: unary_expression { $$ = $1;rootNode = (Node)$$; }
	| '(' type_name ')' cast_expression{

	}
	;

multiplicative_expression
	: cast_expression { $$ = $1;rootNode = (Node)$$; }
	| multiplicative_expression '*' cast_expression {
        if(!($$ = doBinaryOp($1, OP_BINARY_MULTIPLY, $3)))
            $$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_MULTIPLY, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| multiplicative_expression '/' cast_expression {
	    if(!($$ = doBinaryOp($1, OP_BINARY_DIV, $3)))
	        $$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_DIV, $3);
			$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	| multiplicative_expression '%' cast_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_MOD, $3)))
	    	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_MOD, $3);
			$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	;

additive_expression
	: multiplicative_expression { $$ = $1;rootNode = (Node)$$; }
	| additive_expression '+' multiplicative_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_ADD, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_ADD, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| additive_expression '-' multiplicative_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_MINUS, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_MINUS, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

shift_expression
	: additive_expression { $$ = $1;rootNode = (Node)$$; }
	| shift_expression LEFT_OP additive_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_SHIFTLEFT, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_SHIFTLEFT, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| shift_expression RIGHT_OP additive_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_SHIFTRIGHT, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_SHIFTRIGHT, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

relational_expression
	: shift_expression { $$ = $1;rootNode = (Node)$$; }
	| relational_expression '<' shift_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_ST, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_ST, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| relational_expression '>' shift_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_GT, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_GT, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| relational_expression LE_OP shift_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_SE, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_SE, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| relational_expression GE_OP shift_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_BE, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_BE, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

equality_expression
	: relational_expression { $$ = $1;rootNode = (Node)$$; }
	| equality_expression EQ_OP relational_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_EQ, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_EQ, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	| equality_expression NE_OP relational_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_NEQ, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_NEQ, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

and_expression
	: equality_expression { $$ = $1;rootNode = (Node)$$; }
	| and_expression '&' equality_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_AND, $3)))
         	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_AND, $3);
			$$->setSourceLoc(yylineno, column); 
         rootNode = (Node)$$;
	}
	;

exclusive_or_expression
	: and_expression { $$ = $1;rootNode = (Node)$$; }
	| exclusive_or_expression '^' and_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_XOR, $3)))
         	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_XOR, $3);
			$$->setSourceLoc(yylineno, column); 
         rootNode = (Node)$$;
	}
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1;rootNode = (Node)$$; }
	| inclusive_or_expression '|' exclusive_or_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_OR, $3)))
         $$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_OR, $3);
		 $$->setSourceLoc(yylineno, column); 
         rootNode = (Node)$$;
	}
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1;rootNode = (Node)$$; }
	| logical_and_expression AND_OP inclusive_or_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_LOGICAL_AND, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_LOGICAL_AND, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

logical_or_expression
	: logical_and_expression { $$ = $1;rootNode = (Node)$$; }
	| logical_or_expression OR_OP logical_and_expression {
		if(!($$ = doBinaryOp($1, OP_BINARY_LOGICAL_OR, $3)))
        	$$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_LOGICAL_OR, $3);
			$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

conditional_expression
	: logical_or_expression { $$ = $1;rootNode = (Node)$$; }
	| logical_or_expression '?' expression ':' conditional_expression {
        $$ = (Expr)new ConditionalExpr_($1, $3, $5);
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

assignment_expression
	: conditional_expression { $$ = $1;rootNode = (Node)$$; }
	| unary_expression assignment_operator assignment_expression {
        $$ = (Expr)new AssignExpr_($1, $2, $3);
        $$->lvalue = true;
		$$->setSourceLoc(yylineno, column); 
        rootNode = (Node)$$;
	}
	;

assignment_operator
	: '=' { $$ = OP_ASSIGN_EQ; }
	| MUL_ASSIGN { $$ = OP_ASSIGN_EQ_MULTIPLY; }
	| DIV_ASSIGN { $$ = OP_ASSIGN_EQ_DIV; }
	| MOD_ASSIGN { $$ = OP_ASSIGN_EQ_MOD; }
	| ADD_ASSIGN { $$ = OP_ASSIGN_EQ_ADD; }
	| SUB_ASSIGN { $$ = OP_ASSIGN_EQ_MINUS; }
	| LEFT_ASSIGN { $$ = OP_ASSIGN_EQ_SHIFTLEFT; }
	| RIGHT_ASSIGN { $$ = OP_ASSIGN_EQ_SHIFTRIGHT; }
	| AND_ASSIGN { $$ = OP_ASSIGN_EQ_AND; }
	| XOR_ASSIGN { $$ = OP_ASSIGN_EQ_XOR; }
	| OR_ASSIGN { $$ = OP_ASSIGN_EQ_OR; }
	;

expression
	: assignment_expression { $$ = $1;rootNode = (Node)$$; }
	| expression ',' assignment_expression {
	    $$ = (Expr)new BinaryOpExpr_($1, OP_BINARY_COMMA, $3);
		$$->setSourceLoc(yylineno, column); 
	    rootNode = (Node)$$;
	}
	;

constant_expression
	: conditional_expression { $$ = $1;rootNode = (Node)$$; }
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';'
	{
	    checkType($1);
	    for(auto &e:*$2)
	    {
	        e->add2Tail($1);
	    }
	    $$=$2;
	}
	;

declaration_specifiers
	: storage_class_specifier {
	}
	| storage_class_specifier declaration_specifiers {
        $$ = $2;
    }
	| type_specifier {
        $$ = $1;
	}
	| type_specifier declaration_specifiers {
        ((BuiltinType)$1)->next = $2;
        $$ = $1;
	}
	| type_qualifier
	| type_qualifier declaration_specifiers {
	    $$ = $2;
	}
	;

init_declarator_list
	: init_declarator
	{
        $$=new std::list<Decl>();
        $$->push_back($1);
	}
	| init_declarator_list ',' init_declarator
	{
	    $1->push_back($3);
	    $$=$1;
	}
	;

init_declarator
	: declarator
	{
	    $$=$1;
	}
	| declarator '=' initializer
	{
	    if($1->id==NODE_DECL_VAR)
	    {
	        ((VarDecl)$1)->init=$3;
			if(($3->id==NODE_EXP_INITLIST))
			{
				((InitListExpr)$3)->type=((VarDecl)$1)->type;
				for(auto &e:((InitListExpr)$3)->values)
				{
					
				}
			}
	    }
	}
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_VOID, NULL); $$->setSourceLoc(yylineno, column); }
	| CHAR { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_CHAR, NULL); $$->setSourceLoc(yylineno, column); }
	| SHORT { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_SHORT, NULL); $$->setSourceLoc(yylineno, column); }
	| INT { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_INT, NULL); $$->setSourceLoc(yylineno, column); }
	| LONG { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_LONG, NULL); $$->setSourceLoc(yylineno, column); }
	| FLOAT { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_FLOAT, NULL); $$->setSourceLoc(yylineno, column); }
	| DOUBLE { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_DOUBLE, NULL); $$->setSourceLoc(yylineno, column); }
	| SIGNED { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_SIGNED, NULL); $$->setSourceLoc(yylineno, column); }
	| UNSIGNED { $$ = (Type)new BuiltinType_(CONST_TYPE_BUILTIN_UNSIGNED, NULL); $$->setSourceLoc(yylineno, column); }
	| struct_or_union_specifier {}
	| enum_specifier {}
	| TYPE_NAME {}
	;

type_qualifier
	: CONST
	| VOLATILE
	;

declarator
	: pointer direct_declarator
	{
	    $2->add2Tail($1);
	    $$=$2;
	}
	| direct_declarator
	{
	    $$=$1;
	}
	;

direct_declarator
	: IDENTIFIER
	{
        $$=new VarDecl_(NULL,NULL);
		$$->setSourceLoc(yylineno, column); 
        $$->name=std::string($1);
        free($1);
	}
	| '(' declarator ')'
	{
        $$=$2;
	}

	| direct_declarator '[' constant_expression ']'
	{
	    //("&&&&&%d\n",$1->id);
	    //printf("-----%d\n",((VarDecl)$$)->type->id);

	    $$=$1;
        ArrayType a = new ArrayType_(NULL,$3);
	    a->setSourceLoc(yylineno, column);
		$$->add2Tail(a);
	}
	| direct_declarator '[' ']'
	{
	    $$=$1;
        ArrayType a = new ArrayType_(NULL,NULL);
	    a->setSourceLoc(yylineno, column);
		$$->add2Tail(a);
	}
	| direct_declarator '(' parameter_type_list ')'
	{
		
	    if($1->id==NODE_DECL_VAR && $1->name!="")
	    {
			
	        if(((VarDecl)$1)->type==NULL && ((VarDecl)$1)->init==NULL)
	        {
	            $$=new FunctionDecl_($1->name,NULL,*$3,NULL);
				$$->setSourceLoc(yylineno, column); 
	            delete $1;
	        }
	        else if(((VarDecl)$1)->type!=NULL)
	        {
	            list<Type> args;
                for(auto & e:*$3)
                {
                    args.push_back(((ParmVarDecl)e)->type);
                    delete e;
                }
                delete $3;
	            FunctionType f = new FunctionType_(NULL,args);
				f->setSourceLoc(yylineno, column);  
	            $1->add2Tail(f);
	            $$=$1;
	        }
	        else{
	            assert(0);
	        }
	    }
	    else{
	        list<Type> args;
            for(auto & e:*$3)
            {
                args.push_back(((ParmVarDecl)e)->type);
                delete e;
            }
            delete $3;
	        FunctionType f = new FunctionType_(NULL,args);
			f->setSourceLoc(yylineno, column);  
	        $1->add2Tail(f);
	        $$=$1;
	    }

	}
	| direct_declarator '(' identifier_list ')'
	{
	    if($1->id==NODE_DECL_VAR && $1->name!="")
        {
            if(((VarDecl)$1)->type==NULL && ((VarDecl)$1)->init==NULL)
            {
                $$=new FunctionDecl_($1->name,NULL,*$3,NULL);
				$$->setSourceLoc(yylineno, column); 
                delete $1;
            }
            else if(((VarDecl)$1)->type!=NULL)
            {
                list<Type> args;
                for(auto & e:*$3)
                {
                    args.push_back(((ParmVarDecl)e)->type);
                }
                delete $3;
                FunctionType f = new FunctionType_(NULL,args);
				f->setSourceLoc(yylineno, column);  
                $1->add2Tail(f);
                $$=$1;
            }
            else{
                assert(0);
            }
        }
        else{
            list<Type> args;
            for(auto & e:*$3)
            {
                args.push_back(((ParmVarDecl)e)->type);
            }
            delete $3;
            FunctionType f = new FunctionType_(NULL,args);
			f->setSourceLoc(yylineno, column);  
            $1->add2Tail(f);
            $$=$1;
        }
	}
	| direct_declarator '(' ')'
	{
		
	    if($1->id==NODE_DECL_VAR && $1->name!="")
        {
            if(((VarDecl)$1)->type==NULL && ((VarDecl)$1)->init==NULL)
            {
                $$=new FunctionDecl_($1->name,NULL,NULL);
				$$->setSourceLoc(yylineno, column);
                delete $1;
            }
            else if(((VarDecl)$1)->type!=NULL)
            {
                FunctionType f = new FunctionType_(NULL);
				f->setSourceLoc(yylineno, column);  
                $1->add2Tail(f);
                $$=$1;
            }
            else{
                assert(0);
            }
        }
        else{
            FunctionType f = new FunctionType_(NULL);
			f->setSourceLoc(yylineno, column);  
            $1->add2Tail(f);
            $$=$1;
        }
		
	}
	;

pointer
	: '*' {
	    $$ = new PointerType_(NULL);
		$$->setSourceLoc(yylineno, column); 
	}
	| '*' type_qualifier_list {
	    $$ = new PointerType_(NULL);
		$$->setSourceLoc(yylineno, column); 
	}
	| '*' pointer {
	    $$ = new PointerType_($2);
		$$->setSourceLoc(yylineno, column); 
	}
	| '*' type_qualifier_list pointer {
	    $$ = new PointerType_($3);
		$$->setSourceLoc(yylineno, column); 
	}
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	{
		
	    $$=$1;
	}
	| parameter_list ',' ELLIPSIS
	{
	    $$=$1;
	}
	;

parameter_list
	: parameter_declaration
	{
	    $$=new list<Decl>();
	    $$->push_back($1);
	}
	| parameter_list ',' parameter_declaration
	{
	    $1->push_back($3);
	    $$=$1;
	}
	;

parameter_declaration
	: declaration_specifiers declarator
	{
		
	    checkType($1);
		
        if($2->id==NODE_DECL_VAR)
        {
			if( ((VarDecl)$2)->type!=NULL && ((VarDecl)$2)->type->id==CONST_TYPE_ARRAY)
			{
				PointerType p = new PointerType_(((ArrayType)((VarDecl)$2)->type)->basicType);
				p->setSourceLoc(yylineno, column);
				$$=new ParmVarDecl_($2->name, p);
				$$->setSourceLoc(yylineno, column);
				delete $2;
				$$->add2Tail($1);
			}
			else{
				
				$$=new ParmVarDecl_($2->name,((VarDecl)$2)->type);
				$$->setSourceLoc(yylineno, column);
				delete $2;
				$$->add2Tail($1);
			}
            
        }
        else if($2->id==NODE_DECL_FUNCTION)
		{
			list<Type> args;
			for(auto & e:((FunctionDecl)$2)->parameters)
			{
				args.push_back(((ParmVarDecl)e)->type);
				delete e;
			}
			FunctionType f = new FunctionType_(	((FunctionDecl)$2)->returnType, args);
			f->setSourceLoc(yylineno, column);
			PointerType p = new PointerType_(f);
			p->setSourceLoc(yylineno, column);
			$$=new ParmVarDecl_($2->name, p);
			$$->setSourceLoc(yylineno, column); 
			delete $2;
			$$->add2Tail($1);

        }
		else{
			assert(0);
		}

	}
	| declaration_specifiers abstract_declarator
	{
	    checkType($1);
	    if($2->id==NODE_DECL_VAR)
        {
			if( ((VarDecl)$2)->type!=NULL && ((VarDecl)$2)->type->id==CONST_TYPE_ARRAY)
			{
				PointerType p = new PointerType_(((ArrayType)((VarDecl)$2)->type)->basicType);
				p->setSourceLoc(yylineno, column);
				$$=new ParmVarDecl_($2->name, p);
				$$->setSourceLoc(yylineno, column); 
				delete $2;
				$$->add2Tail($1);
			}
			else{
				$$=new ParmVarDecl_($2->name,((VarDecl)$2)->type);
				$$->setSourceLoc(yylineno, column); 
				delete $2;
				$$->add2Tail($1);
			}
            
        }
        else if($2->id==NODE_DECL_FUNCTION)
		{
			list<Type> args;
			for(auto & e:((FunctionDecl)$2)->parameters)
			{
				args.push_back(((ParmVarDecl)e)->type);
				delete e;
			}

			FunctionType f = new FunctionType_(	((FunctionDecl)$2)->returnType, args);
			f->setSourceLoc(yylineno, column);
			PointerType p = new PointerType_(f);
			p->setSourceLoc(yylineno, column);
			$$=new ParmVarDecl_($2->name, p);
			$$->setSourceLoc(yylineno, column);
			delete $2;
			$$->add2Tail($1);

        }
		else{
			assert(0);
		}
	}
	| declaration_specifiers
	{
	    checkType($1);
	    $$=new ParmVarDecl_($1);
		$$->setSourceLoc(yylineno, column); 
	}
	;

identifier_list
	: IDENTIFIER
	{
	    $$=new list<Decl>();
	    auto p = new Decl_();
	    p->name=string($1);
	    free($1);
	    $$->push_back(p);
	}
	| identifier_list ',' IDENTIFIER
	{
	    auto p=new Decl_();
	    p->name=string($3);
	    $1->push_back(p);
	    $$=$1;
	}
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	{
		PointerType p = new PointerType_(NULL);
		p->setSourceLoc(yylineno, column);
	    $$=new VarDecl_(p, NULL);
		$$->setSourceLoc(yylineno, column); 
	}
	| direct_abstract_declarator
	{
	    $$=$1;
	}
	| pointer direct_abstract_declarator
	{
        if($2->id==NODE_DECL_FUNCTION)
        {
            FunctionType funcType=NULL;
            list<Type> args;
            for(auto & e:((FunctionDecl)$2)->parameters)
            {
                args.push_back(((ParmVarDecl)e)->type);
                delete e;
            }
            FunctionType f = new FunctionType_(((FunctionDecl)$2)->returnType,args);
			f->setSourceLoc(yylineno, column);  
			PointerType p = new PointerType_(f);
			p->setSourceLoc(yylineno, column);  
            $$=new VarDecl_(p, NULL);
			$$->setSourceLoc(yylineno, column);
            delete $2;
        }
        else{
			PointerType p = new PointerType_(NULL);
			p->setSourceLoc(yylineno, column);
            $2->add2Tail(new PointerType_(NULL));
            $$=$2;
        }
	}
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	{
	    $$=$2;
	}
	| '[' ']'
	{
		PointerType p = new PointerType_(NULL);
		p->setSourceLoc(yylineno, column);
	    $$=new VarDecl_(p, NULL);
	    $$->setSourceLoc(yylineno, column);
	}
	| '[' constant_expression ']'
	{
	    PointerType p = new PointerType_(NULL);
		p->setSourceLoc(yylineno, column);
	    $$=new VarDecl_(p, NULL);
	    $$->setSourceLoc(yylineno, column);
	}
	| direct_abstract_declarator '[' ']'
	{
	    $$=$1;
		ArrayType a = new ArrayType_(NULL,NULL);
	    a->setSourceLoc(yylineno, column);  
        $$->add2Tail(a);
	}
	| direct_abstract_declarator '[' constant_expression ']'
	{
	    $$=$1;
		ArrayType a = new ArrayType_(NULL,$3);
	    a->setSourceLoc(yylineno, column);  
        $$->add2Tail(a);
	}
	| '(' ')'
	{
	    $$=new FunctionDecl_("",NULL,NULL);
		$$->setSourceLoc(yylineno, column);
	}
	| '(' parameter_type_list ')'
	{
	    $$=new FunctionDecl_("",NULL,*$2,NULL);
		$$->setSourceLoc(yylineno, column);
	}
	| direct_abstract_declarator '(' ')'
	{
	    if($1->id==NODE_DECL_VAR && $1->name=="")
        {
            if(((VarDecl)$1)->type==NULL && ((VarDecl)$1)->init==NULL)
            {
                $$=new FunctionDecl_($1->name,NULL,NULL);
				$$->setSourceLoc(yylineno, column);
                delete $1;
            }
            else if(((VarDecl)$1)->type!=NULL)
            {
				FunctionType f = new FunctionType_(NULL);
				f->setSourceLoc(yylineno, column);
                $1->add2Tail(f);
                $$=$1;
            }
            else{
                assert(0);
            }
        }
        else{
            FunctionType f = new FunctionType_(NULL);
			f->setSourceLoc(yylineno, column);  
			$1->add2Tail(f);
            $$=$1;
        }
	}
	| direct_abstract_declarator '(' parameter_type_list ')'
	{
		
	    if($1->id==NODE_DECL_VAR && $1->name=="")
        {
            if(((VarDecl)$1)->type==NULL && ((VarDecl)$1)->init==NULL)
            {
                $$=new FunctionDecl_($1->name,NULL,*$3,NULL);
				$$->setSourceLoc(yylineno, column);
                delete $1;
            }
            else if(((VarDecl)$1)->type!=NULL)
            {
                list<Type> args;
                for(auto & e:*$3)
                {
                    args.push_back(((ParmVarDecl)e)->type);
                    delete e;
                }
                delete $3;
                FunctionType f = new FunctionType_(NULL,args);
				f->setSourceLoc(yylineno, column);  
                $1->add2Tail(f);$1->add2Tail(new FunctionType_(NULL,args));
                $$=$1;
            }
            else{
                assert(0);
            }
        }
        else{
            list<Type> args;
            for(auto & e:*$3)
            {
                args.push_back(((ParmVarDecl)e)->type);
                delete e;
            }
            delete $3;
            FunctionType f = new FunctionType_(NULL,args);
			f->setSourceLoc(yylineno, column);  
            $1->add2Tail(f);
            $$=$1;
        }
	}
	;

initializer
	: assignment_expression
	{
        $$=$1;
	}
	| '{' initializer_list '}'
	{
		$$=$2;
	}
	| '{' initializer_list ',' '}'
	{
		$$=$2;
	}
	;

initializer_list
	: initializer
	{
		std::list<Expr> values= std::list<Expr>();
		values.push_back($1);
		$$=new InitListExpr_(values);
		$$->setSourceLoc(yylineno, column);
	}
	| initializer_list ',' initializer
	{
		((InitListExpr)$1)->values.push_back($3);
		$$=$1;
	}
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

statement
	: labeled_statement { $$ = $1; rootNode = (Node)$$; }
	| compound_statement { $$ = $1; rootNode = (Node)$$; }
	| expression_statement { $$ = $1; rootNode = (Node)$$; }
	| selection_statement { $$ = $1; rootNode = (Node)$$; }
	| iteration_statement { $$ = $1; rootNode = (Node)$$; }
	| jump_statement { $$ = $1; rootNode = (Node)$$; }
	;

labeled_statement
	: IDENTIFIER ':' statement {
	    Label label = new Label_(std::string($1));
	    $$ = (Stmt)new LabelStmt_(label, $3);
		$$->setSourceLoc(yylineno, column);
	    free($1);
	    rootNode = (Node)$$;
	}
	| CASE constant_expression ':' statement {
        $$ = (Stmt)new CaseStmt_($2, $4);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| DEFAULT ':' statement {
	    $$ = (Stmt)new DefaultStmt_($3);
		$$->setSourceLoc(yylineno, column);
	    rootNode = (Node)$$;
	}
	;

compound_statement
	: '{' '}' {
	    $$ = (Stmt)new CompoundStmt_();
		$$->setSourceLoc(yylineno, column);
	    rootNode = (Node)$$;
	}
	| '{' statement_list '}' {
        $$ = (Stmt)new CompoundStmt_(*$2);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
        delete $2;
	}
	| '{' declaration_list '}' {
        $$ = (Stmt)new CompoundStmt_();
		$$->setSourceLoc(yylineno, column);
        std::list<std::list<struct Decl_ *> *>::iterator it;
        for(it = $2->begin(); it != $2->end(); it++){
            Stmt varDecl = (Stmt)new DeclStmt_(*(*it));
			varDecl->setSourceLoc(yylineno, column);
            ((CompoundStmt)$$)->addStatement(varDecl);
        }
        delete $2;
        rootNode = (Node)$$;
	}
	| '{' declaration_list statement_list '}' {
	    $$ = (Stmt)new CompoundStmt_();
		$$->setSourceLoc(yylineno, column);
        std::list<std::list<struct Decl_ *> *>::iterator it;
        for(it = $2->begin(); it != $2->end(); it++){
            Stmt varDecl = (Stmt)new DeclStmt_(*(*it));
			varDecl->setSourceLoc(yylineno, column);
            ((CompoundStmt)$$)->addStatement(varDecl);
        }
        delete $2;
        std::list<struct Stmt_ *>::iterator it2;
        for(it2 = $3->begin(); it2 != $3->end(); it2++){
            ((CompoundStmt)$$)->addStatement((*it2));
        }
        delete $3;
        rootNode = (Node)$$;
	}
	;

declaration_list
	: declaration {
	    $$ = new std::list<std::list<struct Decl_ *>*>();
	    $$->push_back($1);
	}
	| declaration_list declaration {
	    $1->push_back($2);
	    $$ = $1;
	}
	;

statement_list
	: statement {
	    $$ = new std::list<Stmt>;
	    $$->push_back($1);
	}
	| statement_list statement {
	    $$->push_back($2);
	}
	;

expression_statement
	: ';' {
	    $$ = (Stmt)new NullStmt_();
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| expression ';' {
	    $$ = (Stmt)new ExprStmt_($1);
		$$->setSourceLoc(yylineno, column);
	    rootNode = (Node)$$;
	}
	;

selection_statement
	: IF '(' expression ')' statement {
	    $$ = (Stmt)new IfStmt_($3, $5, NULL);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| IF '(' expression ')' statement ELSE statement {
        $$ = (Stmt)new IfStmt_($3, $5, $7);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| SWITCH '(' expression ')' statement {
        $$ = (Stmt)new SwitchStmt_($3, $5);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement {
        $$ = (Stmt)new WhileStmt_($5, $3);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| DO statement WHILE '(' expression ')' ';' {
	    $$ = (Stmt)new DoStmt_($2, $5);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| FOR '(' expression_statement expression_statement ')' statement {
        Expr expr1, expr2;
        if($3->id == NODE_STM_NULL)
            expr1 = NULL;
        else
            expr1 = ((ExprStmt)$3)->expr;
        if($4->id == NODE_STM_NULL)
            expr2 = NULL;
        else
            expr2 = ((ExprStmt)$4)->expr;
        $$ = (Stmt)new ForStmt_(expr1, expr2, NULL, $6);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| FOR '(' expression_statement expression_statement expression ')' statement {
        Expr expr1, expr2;
        if($3->id == NODE_STM_NULL)
            expr1 = NULL;
        else
            expr1 = ((ExprStmt)$3)->expr;
        if($4->id == NODE_STM_NULL)
            expr2 = NULL;
        else
            expr2 = ((ExprStmt)$4)->expr;
        $$ = (Stmt)new ForStmt_(expr1, expr2, $5, $7);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	;

jump_statement
	: GOTO IDENTIFIER ';' {
	    Label label = new Label_(std::string($2));
        $$ = (Stmt)new GoToStmt_(label);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
        free($2);
	}
	| CONTINUE ';' {
        $$ = (Stmt)new ContinueStmt_();
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| BREAK ';'{
        $$ = (Stmt)new BreakStmt_();
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| RETURN ';'{
        $$ = (Stmt)new ReturnStmt_(NULL);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	| RETURN expression ';'{
        $$ = (Stmt)new ReturnStmt_($2);
		$$->setSourceLoc(yylineno, column);
        rootNode = (Node)$$;
	}
	;

translation_unit
	: external_declaration {
	    $$ = (Decl)new TranslationUnitDecl_();
		$$->setSourceLoc(yylineno, column);
	    std::list<Decl>::iterator it;
        for(it = $1->begin(); it != $1->end(); it++){
            ((TranslationUnitDecl)$$)->addDeclaration(*it);
        }
        delete $1;
	    rootNode = (Node)$$;
	}
	| translation_unit external_declaration {
	    std::list<Decl>::iterator it;
	    for(it = $2->begin(); it != $2->end(); it++){
            ((TranslationUnitDecl)$1)->addDeclaration(*it);
        }
        delete $2;
	    $$ = (TranslationUnitDecl)$1;
	    rootNode = (Node)$$;
	}
	;

external_declaration
	: function_definition {
        $$ = new std::list<Decl>();
        $$->push_back($1);
     }
	| declaration {
	    $$ = new std::list<Decl>();
        std::list<Decl>::iterator it;
        for(it = $1->begin(); it != $1->end(); it++){
            $$->push_back(*it);
        }
        delete $1;

	}
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
        assert(0);
	}
	| declaration_specifiers declarator compound_statement {
	    checkType($1);
	    $2->add2Tail($1);
        ((FunctionDecl)$2)->stmt=$3;
        $$=$2;
	}
	| declarator declaration_list compound_statement {
        assert(0);
	}
	| declarator compound_statement {
        ((FunctionDecl)$1)->stmt=$2;
        $$=$1;
	}
	;

%%

void yyerror(char const *s)
{
	fflush(stdout);
	printf("\n%*s\n%*s\n", column, "^", column, s);
}

int main(int argc, char *argv[]) {
    yyparse();
    std::cout << std::endl << "-------------------------------------------------------" << std::endl;
    rootNode->show();
	std::cout<<"=================="<<std::endl;
    assert(rootNode->id == NODE_DECL_TRANSLATION);
    Semantic *semantic = new Semantic();
    semantic->semanticAnalysis((TranslationUnitDecl)rootNode);
    std::cout << std::endl << "-------------------------------------------------------" << std::endl;
    rootNode->show();
	std::cout<<"finish semanticAnalysis"<<std::endl;
	
    return 0;
}

