#!/bin/bash
rm -rf a.out y.tab.c y.tab.h
echo "lex"
flex compiler.l
echo "yacc"
yacc -d compiler.y
echo "#include <iostream>
#include <list>" | cat - y.tab.h > temp.txt
mv temp.txt y.tab.h
g++ *.c *.cpp -std=c++11
