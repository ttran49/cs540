transform:	lex.yy.c
	gcc lex.yy.c -lfl

lex.yy.c:	simple.l
	flex simple.l

clean:
	rm -rf lex.yy.c a.out
