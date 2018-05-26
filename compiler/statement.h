//
// Created by Administrator on 2018/5/25/025.
//

#ifndef COMPILER_STATEMENT_H
#define COMPILER_STATEMENT_H

#include <list>
#include <string>
#include "declaration.h"
#include "expression.h"
#include "constant.h"
using namespace std;

struct BreakStmt_;
struct CompoundStmt_;
struct ContinueStmt_;
struct WhileStmt_;
struct ForStmt_;
struct DoStmt_;
struct GoToStmt_;
struct IfStmt_;
struct LabelStmt_;
struct NullStmt_;
struct ReturnStmt_;
struct SwitchStmt_;
struct CaseStmt_;
struct DefaultStmt_;
struct ExprStmt_;
struct DeclStmt_;

typedef struct BreakStmt_ *BreakStmt;
typedef struct CompoundStmt_ *CompoundStmt;
typedef struct ContinueStmt_ *ContinueStmt;
typedef struct WhileStmt_ *WhileStmt;
typedef struct ForStmt_ *ForStmt;
typedef struct DoStmt_ *DoStmt;
typedef struct GoToStmt_ *GoToStmt;
typedef struct IfStmt_ *IfStmt;
typedef struct LabelStmt_ *LabelStmt;
typedef struct NullStmt_ *NullStmt;
typedef struct ReturnStmt_ *ReturnStmt;
typedef struct SwitchStmt_ *SwitchStmt;
typedef struct CaseStmt_ *CaseStmt;
typedef struct DefaultStmt_ *DefaultStmt;
typedef struct ExprStmt_ *ExprStmt;
typedef struct DeclStmt_ *DeclStmt;


struct BreakStmt_:public Stmt_
{
    BreakStmt_(){this->id = NODE_STM_BREAK;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("BreakStmt_\n");
    }
};

struct ContinueStmt_:public Stmt_
{
    ContinueStmt_(){this->id = NODE_STM_CONTINUE;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("ContinueStmt_\n");
    }
};

struct CompoundStmt_:public Stmt_
{
    list<Stmt> stmtList;
    CompoundStmt_(){this->id = NODE_STM_COMPOUND;}
    CompoundStmt_(list<Stmt> &stmtList):stmtList(stmtList){this->id = NODE_STM_COMPOUND;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("CompoundStmt_\n");
        std::list<Stmt>::iterator it;
        for(it = stmtList.begin(); it != stmtList.end(); it++){
            (*it)->show(space + 1);
        }
    }
};

struct DoStmt_:public Stmt_
{
    Stmt stmt;
    Expr expr;
    DoStmt_(Stmt stmt, Expr expr):stmt(stmt), expr(expr){this->id = NODE_STM_DO;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("DoStmt_\n");
        stmt->show(space + 1);
        expr->show(space + 1);
    }
};

struct WhileStmt_:public Stmt_
{
    Expr expr;
    Stmt stmt;
    WhileStmt_(Stmt stmt, Expr expr):stmt(stmt), expr(expr){this->id = NODE_STM_WHILE;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("WhileStmt_\n");
        expr->show(space + 1);
        stmt->show(space + 1);
    }
};

struct ForStmt_:public Stmt_
{
    Expr init, condition, next;
    Stmt stmt;
    ForStmt_(Expr init, Expr condition, Expr next, Stmt stmt):init(init), condition(condition),
                                                              next(next), stmt(stmt){this->id = NODE_STM_FOR;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("ForStmt_\n");
        if(init != NULL)
            init->show(space + 1);
        else{
            for(int i = 0; i < space + 1; i++)
                printf("-");
            printf("NULL\n");
        }
        if(condition != NULL)
            condition->show(space + 1);
        else{
            for(int i = 0; i < space + 1; i++)
                printf("-");
            printf("NULL\n");
        }
        if(next != NULL)
            next->show(space + 1);
        else{
            for(int i = 0; i < space + 1; i++)
                printf("-");
            printf("NULL\n");
        }
        stmt->show(space + 1);
    }
};

struct GoToStmt_:public Stmt_
{
    string label;
    GoToStmt_(string label):label(label){this->id = NODE_STM_GOTO;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("GoToStmt_: %s\n", label.c_str());
    }
};

struct IfStmt_:public Stmt_
{
    Expr condition;
    Stmt if_, else_;
    IfStmt_(Expr condition, Stmt if_, Stmt else_):if_(if_), else_(else_), condition(condition){this->id = NODE_STM_IF;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("IfStmt_\n");
        condition->show(space + 1);
        if_->show(space + 1);
        if(else_)
            else_->show(space + 1);
    }
};

struct LabelStmt_:public Stmt_
{
    string label;
    Stmt stmt;
    LabelStmt_(string label, Stmt stmt):label(label), stmt(stmt){this->id = NODE_STM_LABEL;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("LabelStmt_: %s\n", label.c_str());
        stmt->show(space + 1);
    }
};

struct ReturnStmt_:public Stmt_
{
    Expr result;
    ReturnStmt_(Expr result):result(result) {this->id = NODE_STM_RETURN;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("ReturnStmt_\n");
        if(result)
            result->show(space + 1);
    }
};

struct SwitchStmt_:public Stmt_
{
    Expr expr;
    Stmt stmt;
    SwitchStmt_(Expr expr, Stmt stmt):expr(expr), stmt(stmt){this->id = NODE_STM_SWITCH;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("SwitchStmt_\n");
        expr->show(space + 1);
        stmt->show(space + 1);
    }
};

struct CaseStmt_:public Stmt_
{
    Expr const_;
    Stmt stmt;
    CaseStmt_(Expr const_, Stmt stmt):const_(const_), stmt(stmt){this->id = NODE_STM_CASE;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("CaseStmt_\n");
        const_->show(space + 1);
        stmt->show(space + 1);
    }
};

struct DefaultStmt_:public Stmt_
{
    Stmt stmt;
    DefaultStmt_(Stmt stmt):stmt(stmt){this->id = NODE_STM_DEFAULT;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("DefaultStmt_\n");
        stmt->show(space + 1);
    }
};

struct ExprStmt_:public Stmt_
{
    Expr expr;
    ExprStmt_(Expr expr):expr(expr){this->id = NODE_STM_EXPR;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("ExprStmt_\n");
        expr->show(space + 1);
    }
};

struct DeclStmt_:public Stmt_
{
    list<Decl> declarations;
    DeclStmt_(){}
    DeclStmt_(list<Decl>& declarations):declarations(declarations){this->id = NODE_STM_DECL;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("DeclStmt_\n");
        std::list<Decl>::iterator it;
        for(it = declarations.begin(); it != declarations.end(); it++){
            (*it)->show(space + 1);
        }
    }
};

struct NullStmt_:public Stmt_
{
    NullStmt_(){this->id = NODE_STM_NULL;}

    void show(int space = 0)
    {
        for(int i = 0; i < space; i++)
            printf("-");
        printf("NullStmt_\n");
    }
};

#endif //COMPILER_STATEMENT_H
