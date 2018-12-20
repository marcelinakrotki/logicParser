#! /bin/bash

yacc -d logic.y
lex logic.l
cc lex.yy.c y.tab.c

