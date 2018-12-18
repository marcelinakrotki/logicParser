#! /bin/bash

yacc -d logic.yyac
lex logic.lex
cc lex.yy.c y.tab.c
