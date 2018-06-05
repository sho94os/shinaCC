//
// Created by Administrator on 2018/6/4/004.
//

#include "translator.h"

int level = 0;

void Program_::appendInst(IrInst e)
{
    assert(currentBlock);
    currentBlock->insts.push_back(e);
}

BasicBlock Program_::createBasicBlock()
{
    BasicBlock bb = new BasicBlock_();
    memset(bb, 0, sizeof(BasicBlock_));
    return bb;
}

void Program_::startBasicBlock(BasicBlock bb)
{
    assert(currentBlock);
    bblocks.push_back(currentBlock);
    currentBlock = bb;
}

Program Translator_::translate(TranslationUnitDecl start)
{
    program = new Program_();
    labelNumber = 0;
    //TODO: handle var decl
    for(auto &decl: start->declarations){
        if(decl->id == NODE_DECL_VAR){
            VarDecl decl1 = (VarDecl)decl;
            Symbol symbol = table->lookUp(decl1->name);
            program->globals.push_back(symbol);
        }
        else if(decl->id == NODE_DECL_FUNCTION){
            FunctionDecl decl1 = (FunctionDecl)decl;
            if(!decl1->stmt)
                continue;

            tmpNumber = 0;
            program->currentFunc = decl1->functionSymbol;
            program->currentFunc->entryBB = program->createBasicBlock();
            program->currentFunc->exitBB = program->createBasicBlock();
            program->currentBlock = program->currentFunc->entryBB;
            translateStatement(decl1->stmt);
            program->startBasicBlock(program->currentFunc->exitBB);

            for(auto &bb: program->bblocks){
                if(bb->reference > 0){
                    bb->symbol = createLabel();
                }
            }
        }
    }
    return program;
}

Symbol Translator_::translateFunctionCall(CallExpr expr)
{

}

Symbol Translator_::translateBinaryExpr(BinaryOpExpr expr)
{
    if(expr->operator_ == OP_BINARY_COMMA)
        return translateCommaExpr(expr);
    if(expr->operator_ == OP_BINARY_LOGICAL_AND
       || expr->operator_ == OP_BINARY_LOGICAL_OR || isRelationalOp(expr->operator_))
        return translateBranchExpr(expr);
    Symbol src1, src2;
    src1 = translateBranchExpr(expr->left);
    src2 = translateBranchExpr(expr->right);
    if(expr->operator_ == OP_BINARY_OR)
        return simplify(expr->type, BOR, src1, src2);
    if(expr->operator_ == OP_BINARY_XOR)
        return simplify(expr->type, BXOR, src1, src2);
    if(expr->operator_ == OP_BINARY_AND)
        return simplify(expr->type, BAND, src1, src2);
    if(expr->operator_ == OP_BINARY_SHIFTLEFT)
        return simplify(expr->type, LSH, src1, src2);
    if(expr->operator_ == OP_BINARY_SHIFTRIGHT)
        return simplify(expr->type, RSH, src1, src2);
    if(expr->operator_ == OP_BINARY_ADD)
        return simplify(expr->type, ADD, src1, src2);
    if(expr->operator_ == OP_BINARY_MINUS)
        return simplify(expr->type, SUB, src1, src2);
    if(expr->operator_ == OP_BINARY_MULTIPLY)
        return simplify(expr->type, MUL, src1, src2);
    if(expr->operator_ == OP_BINARY_DIV)
        return simplify(expr->type, DIV, src1, src2);
    if(expr->operator_ == OP_BINARY_MOD)
        return simplify(expr->type, MOD, src1, src2);
}

Symbol Translator_::translateBranchExpr(Expr expr)
{
    BasicBlock nextBB, trueBB, falseBB;
    Symbol t;

    t = createTemp(expr->type);

    nextBB = program->createBasicBlock();
    trueBB = program->createBasicBlock();
    falseBB = program->createBasicBlock();

    translateBranch(expr, trueBB, falseBB);

    program->startBasicBlock(falseBB);
    generateMove(expr->type, t, IntConstant(0));
    generateJump(nextBB);

    program->startBasicBlock(trueBB);
    generateMove(expr->type, t, IntConstant(1));

    program->startBasicBlock(nextBB);

    return t;
}

Symbol Translator_::translateUnaryExpr(UnaryOpExpr expr)
{
    if(expr->operator_ == OP_UNARY_DOUBLEADD || expr->operator_ == OP_UNARY_DOUBLEMINUS)
        return translateIncrement(expr);
    if(expr->operator_ == OP_UNARY_LOGICAL_NOT)
        return translateBranchExpr(expr);
    Symbol src = translateExpression(expr->expr);
    switch (expr->operator_){
        case OP_UNARY_CAST:
            assert(0);
            return NULL;
        case OP_UNARY_POSITIVE:
            return src;
        case OP_UNARY_NEGATIVE:
            return simplify(expr->type, NEG, src, NULL);
        case OP_UNARY_STAR:
            return deReference(src);
        case OP_UNARY_AND:
            return addressOf(src);
        default:
            assert(0);
            return NULL;
    }
}

Symbol Translator_::translateIncrement(UnaryOpExpr expr)
{

}

Symbol Translator_::translateConditionalExpr(ConditionalExpr expr)
{

}

Symbol Translator_::translateAssignmentExpr(AssignExpr expr)
{
    Symbol dst, src;
    //TODO:
}

Symbol Translator_::translateCommaExpr(BinaryOpExpr expr)
{

}


Symbol Translator_::translateCastExpr(Expr expr)
{
    if(expr->id == NODE_EXP_IMPLICITCAST){
        ImplicitCastExpr expr1 = (ImplicitCastExpr)expr;
        Symbol src = translateExpression(expr1->expr);
        return translateCast(expr1->type, expr1->expr->type, src);
    }
    else{
        assert(expr->id == NODE_EXP_CSTYLECAST);
        return NULL;
    }
}

Symbol Translator_::translatePrimaryExpr(Expr expr) //id, str, int, float, parentheses
{
    if(expr->isConstant() && expr->id != NODE_EXP_STRLITERAL){
        if(expr->isIntConstant())
            return IntConstant(expr->valueUnion.i[0]);
        return DoubleConst(expr->valueUnion.d);
    }
    assert(expr->id != NODE_EXP_STRLITERAL);//TODO:
    if(expr->type->id == CONST_TYPE_FUNC || expr->type->id == CONST_TYPE_ARRAY){
        return addressOf((Symbol)(expr->valueUnion.p));
    }
    return (Symbol)expr->valueUnion.p;
}

Symbol Translator_::translateArrayIndex(ArraySubscriptExpr expr)
{

}

void Translator_::translateExprStmt(ExprStmt stmt)
{
    assert(stmt->expr);
    translateExpression(stmt->expr);
}

void Translator_::translateLabelStmt(LabelStmt stmt)
{
    //TODO: create basic block for label
    if(stmt->label){
        if(stmt->label->respBB)
            stmt->label->respBB = program->createBasicBlock();
        program->startBasicBlock(stmt->label->respBB);
    }
    translateStatement(stmt->stmt);
}

void Translator_::translateCaseStmt(CaseStmt stmt)
{
    //TODO:
    translateStatement(stmt->stmt);
}

void Translator_::translateDefaultStmt(DefaultStmt stmt)
{
    //TODO:
}

void Translator_::translateIfStmt(IfStmt stmt)
{
    BasicBlock nextBB, trueBB, falseBB;
    nextBB = program->createBasicBlock();
    trueBB = program->createBasicBlock();
    if(stmt->else_ == NULL){
        translateBranch(notExpr(stmt->condition), nextBB, trueBB);
        program->startBasicBlock(trueBB);
        translateStatement(stmt->if_);
    }
    else{
        falseBB = program->createBasicBlock();
        translateBranch(notExpr(stmt->condition), falseBB, trueBB);

        program->startBasicBlock(trueBB);
        translateStatement(stmt->if_);
        generateJump(nextBB);

        program->startBasicBlock(falseBB);
        translateStatement(stmt->else_);
    }
    program->startBasicBlock(nextBB);
}

void Translator_::translateWhileStmt(WhileStmt stmt)
{
    stmt->loopBB = program->createBasicBlock();
    stmt->contBB = program->createBasicBlock();
    stmt->nextBB = program->createBasicBlock();

    generateJump(stmt->contBB);

    program->startBasicBlock(stmt->loopBB);
    translateStatement(stmt->stmt);

    program->startBasicBlock(stmt->contBB);
    translateBranch(stmt->expr, stmt->loopBB, stmt->nextBB);

    program->startBasicBlock(stmt->nextBB);
}

void Translator_::translateDoStmt(DoStmt stmt)
{
    stmt->loopBB = program->createBasicBlock();
    stmt->contBB = program->createBasicBlock();
    stmt->nextBB = program->createBasicBlock();

    program->startBasicBlock(stmt->loopBB);
    translateStatement(stmt->stmt);

    program->startBasicBlock(stmt->contBB);
    translateBranch(stmt->expr, stmt->loopBB, stmt->nextBB);

    program->startBasicBlock(stmt->nextBB);
}

void Translator_::translateForStmt(ForStmt stmt)
{
    stmt->loopBB=program->createBasicBlock();
    stmt->contBB=program->createBasicBlock();
    stmt->testBB=program->createBasicBlock();
    stmt->nextBB=program->createBasicBlock();

    if(stmt->init)
    {
        this->translateExpression(stmt->init);
    }
    this->generateJump(stmt->testBB);


    program->startBasicBlock(stmt->loopBB);
    this->translateStatement(stmt->stmt);
    program->startBasicBlock(stmt->contBB);
    if(stmt->next)
    {
        this->translateExpression(stmt->next);
    }
    program->startBasicBlock(stmt->testBB);
    if(stmt->condition)
    {
        this->translateBranch(stmt->condition,stmt->loopBB,stmt->nextBB);
    }
    else{
        this->generateJump(stmt->loopBB);
    }
    program->startBasicBlock(stmt->nextBB);


}

void Translator_::translateGotoStmt(GoToStmt stmt)
{
    if(stmt->label->respBB==NULL)
    {
        stmt->label->respBB=program->createBasicBlock();
    }
    this->generateJump(stmt->label->respBB);
    program->startBasicBlock(program->createBasicBlock());

}

void Translator_::translateBreakStmt(BreakStmt stmt)
{
    switch(stmt->target->id)
    {
        case NODE_STM_SWITCH:
        {
            this->generateJump(((SwitchStmt)(stmt->target))->nextBB);
            break;
        }
        case NODE_STM_FOR:
        {
            this->generateJump(((ForStmt)(stmt->target))->nextBB);
            break;
        }
        case NODE_STM_WHILE:
        {
            this->generateJump(((WhileStmt)(stmt->target))->nextBB);
            break;
        }
        case NODE_STM_DO:
        {
            this->generateJump(((DoStmt)(stmt->target))->nextBB);
            break;
        }
    }
    program->startBasicBlock(program->createBasicBlock());
    
}

void Translator_::translateContinueStmt(ContinueStmt stmt)
{
    switch(stmt->target->id)
    {
        case NODE_STM_FOR:
        {
            this->generateJump(reinterpret_cast<ForStmt>(stmt->target)->contBB);
            break;
        }
        case NODE_STM_WHILE:
        {
            this->generateJump(reinterpret_cast<WhileStmt>(stmt->target)->contBB);
            break;
        }
        case NODE_STM_DO:
        {
            this->generateJump(reinterpret_cast<DoStmt>(stmt->target)->contBB);
            break;
        }
    }
    program->startBasicBlock(program->createBasicBlock());

}

void Translator_::translateReturnStmt(ReturnStmt stmt)
{
    if(stmt->result)
    {
        this->generateReturn(stmt->result->type,
            this->translateExpression(stmt->result)
        );
    }
    this->generateJump(program->currentFunc->exitBB);
    program->startBasicBlock(program->createBasicBlock());

}

void Translator_::translateCompoundStmt(CompoundStmt stmt)
{
    level++;
    for(auto &s: stmt->stmtList){
        if(s->id == NODE_STM_DECL){
            VarDecl decl = (VarDecl)s;
            //TODO: initialize
        }
        else{
            translateStatement(s);
        }
    }
    level--;
}

void Translator_::translateSwitchStmt(SwitchStmt stmt)
{

}

void Translator_::translateBranch(Expr expr, BasicBlock trueBlock, BasicBlock falseBlock)
{
    BasicBlock testBlock;
    Symbol src1, src2;
    int map[6] ={
         JGE, JL, JG, JLE, JE, JNE
    };
    if(expr->id == NODE_EXP_BINARY){
        BinaryOpExpr expr1 = (BinaryOpExpr)expr;
        switch (expr1->operator_){
            case OP_BINARY_LOGICAL_AND:
                testBlock = program->createBasicBlock();
                translateBranch(notExpr(expr1->left), falseBlock, testBlock);
                program->startBasicBlock(testBlock);
                translateBranch(expr1->right, trueBlock, falseBlock);
                break;
            case OP_BINARY_LOGICAL_OR:
                testBlock = program->createBasicBlock();
                translateBranch(expr1->left, trueBlock, testBlock);
                program->startBasicBlock(testBlock);
                translateBranch(expr1->right, trueBlock, falseBlock);
                break;
            case OP_BINARY_BE: // >=
            case OP_BINARY_ST: // <
            case OP_BINARY_GT: // >
            case OP_BINARY_SE: // <=
            case OP_BINARY_EQ:
            case OP_BINARY_NEQ:
                src1 = translateExpression(expr1->left);
                src2 = translateExpression(expr1->right);
                generateBranch(expr1->left->type, trueBlock, map[expr1->operator_ - OP_BINARY_GT], src1, src2);
                break;
            default: assert(0); break;
        }
    }
    else if(expr->id == NODE_EXP_UNARY){ //!a
        UnaryOpExpr expr1 = (UnaryOpExpr)expr;
        if(expr1->operator_ == OP_UNARY_LOGICAL_NOT){
            src1 = translateExpression(expr1->expr);
            Type type = expr1->expr->type;
            if(type->id < CONST_TYPE_BUILTIN_INT){
                src1 = translateCast(BuiltinType_::intType, expr1->expr->type, src1);
                type = BuiltinType_::intType;
            }
            generateBranch(type, trueBlock, JZ, src1, NULL);
        }
    }
    else if(expr->isConstant()){ //1
        if(!(expr->valueUnion.i[0] == 0 && expr->valueUnion.i[1] == 0))
            generateJump(trueBlock);
    }
    else{ //a
        src1 = translateExpression(expr);
        if (src1->kind  == SK_Constant) {
            if (!(src1->valueUnion.i[0] == 0 && src1->valueUnion.i[1] == 0))
                generateJump(trueBlock);
        }
        else{
            Type type = expr->type;
            if(type->id < CONST_TYPE_BUILTIN_INT){
                src1 = translateCast(BuiltinType_::intType, type, src1);
                type = BuiltinType_::intType;
            }
            generateBranch(type, trueBlock, JNZ, src1, NULL);
        }
    }
}

Expr Translator_::notExpr(Expr expr)
{
    if(expr->id == NODE_EXP_BINARY){
        BinaryOpExpr expr1 = (BinaryOpExpr)expr;
        switch (expr1->operator_){
            case OP_BINARY_LOGICAL_AND:
                expr1->operator_ = OP_BINARY_LOGICAL_OR;
                expr1->left = notExpr(expr1->left);
                expr1->right = notExpr(expr1->right);
                return expr;
            case OP_BINARY_LOGICAL_OR:
                expr1->operator_ = OP_BINARY_LOGICAL_AND;
                expr1->left = notExpr(expr1->left);
                expr1->right = notExpr(expr1->right);
                return expr;
            case OP_BINARY_BE: // >=
                expr1->operator_ = OP_BINARY_ST;
                return expr;
            case OP_BINARY_ST: // <
                expr1->operator_ = OP_BINARY_BE;
                return expr;
            case OP_BINARY_GT: // >
                expr1->operator_ = OP_BINARY_SE;
                return expr;
            case OP_BINARY_SE: // <=
                expr1->operator_ = OP_BINARY_GT;
                return expr;
            case OP_BINARY_EQ:
                expr1->operator_ = OP_BINARY_NEQ;
                return expr;
            case OP_BINARY_NEQ:
                expr1->operator_ = OP_BINARY_EQ;
                return expr;
            default: break;
        }
    }
    else if(expr->id == NODE_EXP_UNARY){
        UnaryOpExpr expr1 = (UnaryOpExpr)expr;
        if(expr1->operator_ == OP_UNARY_LOGICAL_NOT)
            return expr1->expr;
    }
    UnaryOpExpr expr2 = new UnaryOpExpr_(expr, OP_UNARY_LOGICAL_NOT, false);
    expr2->type = BuiltinType_::intType;
    return expr2;
}


void Translator_::translateStatement(Stmt stmt)
{
    switch (stmt->id){
        case NODE_STM_COMPOUND:
            translateCompoundStmt((CompoundStmt)stmt);
            break;
        case NODE_STM_EXPR:
            translateExprStmt((ExprStmt)stmt);
            break;
        case NODE_STM_DECL:
            //TODO
            break;
        case NODE_STM_SWITCH:
            translateSwitchStmt((SwitchStmt)stmt);
            break;
        case NODE_STM_CASE:
            translateCaseStmt((CaseStmt)stmt);
            break;
        case NODE_STM_DEFAULT:
            translateDefaultStmt((DefaultStmt)stmt);
            break;
        case NODE_STM_RETURN:
            translateReturnStmt((ReturnStmt)stmt);
            break;
        case NODE_STM_IF:
            translateIfStmt((IfStmt)stmt);
            break;
        case NODE_STM_WHILE:
            translateWhileStmt((WhileStmt)stmt);
            break;
        case NODE_STM_DO:
            translateDoStmt((DoStmt)stmt);
            break;
        case NODE_STM_FOR:
            translateForStmt((ForStmt)stmt);
            break;
        case NODE_STM_LABEL:
            translateLabelStmt((LabelStmt)stmt);
            break;
        case NODE_STM_CONTINUE:
            translateContinueStmt((ContinueStmt)stmt);
            break;
        case NODE_STM_BREAK:
            translateBreakStmt((BreakStmt)stmt);
            break;
        case NODE_STM_NULL:
            break;
        case NODE_STM_GOTO:
            translateGotoStmt((GoToStmt)stmt);
            break;
        default:
            break;
    }
}

Symbol Translator_::translateExpression(Expr expr)
{
    switch (expr->id){
        case NODE_EXP_PAREN:
            return translateExpression(((ParenExpr)expr)->expr);
        case NODE_EXP_INTLITERAL:
        case NODE_EXP_FLOATLITERAL: case NODE_EXP_STRLITERAL:
        case NODE_EXP_DECLREF: case NODE_EXP_CHARLITERAL:
            return translatePrimaryExpr(expr);
        case NODE_EXP_BINARY:
            return translateBinaryExpr((BinaryOpExpr)expr);
        case NODE_EXP_UNARY:
            return translateUnaryExpr((UnaryOpExpr)expr);
        case NODE_EXP_CONDITIONAL:
            return translateConditionalExpr((ConditionalExpr)expr);
        case NODE_EXP_ASSIGN:
            return translateAssignmentExpr((AssignExpr)expr);
        case NODE_EXP_CALL:
            return translateFunctionCall((CallExpr)expr);
        case NODE_EXP_ARRAYSUBSCRIPT:
            return translateArrayIndex((ArraySubscriptExpr)expr);
        case NODE_EXP_IMPLICITCAST: case NODE_EXP_CSTYLECAST:
            return translateCastExpr(expr);
        default:
            return NULL;
    }
}
