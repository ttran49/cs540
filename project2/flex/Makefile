transform:	lex.yy.c
	gcc lex.yy.c -lfl

lex.yy.c:	untitle.l
	flex untitle.l

clean:
	rm -rf lex.yy.c a.out
