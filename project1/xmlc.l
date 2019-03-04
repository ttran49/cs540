%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int start = 0;
int add = 0;
int sub = 0;
int call = 0;
%}
a	[Aa]
b	[Bb]
c	[Cc]
d	[Dd]
e	[Ee]
f	[Ff]
g	[Gg]
h	[Hh]
i	[Ii]
j	[Jj]
k	[Kk]
l	[Ll]
m	[Mm]
n	[Nn]
o	[Oo]
p	[Pp]
q	[Qq]
r	[Rr]
s	[Ss]
t	[Tt]
u	[Uu]
v	[Vv]
w	[Ww]
x	[Xx]
y	[Yy]
z	[Zz]
%%
"<"{f}{u}{n}{c}{t}{i}{o}{n}		{start = 1; }
"</"{f}{u}{n}{c}{t}{i}{o}{n}">"		{printf("}\n"); start = 0; }
"</"{i}{f}">"	{
				printf("}\n");
				}
"<"{a}{d}{d}		{add = 1;}
"<"{s}{u}{b}		{sub = 1;}
\"[^"]*\"				{
					  if (start == 1) {  // function name
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf("int %s(",yytext+1);
					    start = 2;
					  } else if (start == 2) {  // params
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf("int %s",yytext+1);
					    start = 3;
					  } else if (start == 3) {  // params
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf(", int %s",yytext+1);
					  }
					  if (call == 1) {  // function name
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf(" %s(",yytext+1);
					    call = 2;
					  } else if (call == 2) {  // params
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf(" %s",yytext+1);
					    call = 3;
					  } else if (call == 3) {  // params
					    int len = yyleng;
					    yytext[yyleng-1]=0;
					    printf(", %s);\n",yytext+1);
					    call=0;
					  }
					}
"/>"				{
					  if (add != 0){
					  	printf(";\n");
					  	add=0;
					  }
					  if (sub != 0){
					  	printf(";\n");
					  	sub=0;
					  }
					}
">"					{
					  if ((start==2)||(start==3)) { // finish funct
					    printf(") {\n");
					    start=0;  
					  }
					}
"<"{c}{a}{l}{l}" "{r}{e}{s}{u}{l}{t}=\"[a-z]\"	{
						printf("	%c = ",yytext[yyleng-2]);
						call = 1;
					}

{r}{e}{s}{u}{l}{t}=\"[a-z]\"	{
						printf("	%c = ",yytext[yyleng-2]);
					}

{o}{p}=\"[a-z0-9]\"	{
					if (add == 1){
						printf("%c",yytext[yyleng-2]);
						add++;
					} else if (add > 1){
						printf(" + %c",yytext[yyleng-2]);
					}else if (sub == 1){
						printf("%c",yytext[yyleng-2]);
						sub++;
					} else if (sub > 1){
						printf(" + %c",yytext[yyleng-2]);
					}
					}

"<"{r}{e}{t}{u}{r}{n}" "{o}{p}=\"[a-z0-9]\" {
					printf("	return %c;\n",yytext[yyleng-2]);
					}

"<"{i}{f}" "{c}{o}{n}{d}{i}{t}{i}{o}{n}=\"[a-zA-Z0-9<>=!]*\"	{
					char *condition;
					condition = memchr(yytext, '"', yyleng-1);
					condition[strlen(condition)-1]=0;
					condition[0] = (char) ' ' ;
					printf("if (%s ) {\n", condition);
					}

"<"{e}{l}{s}{e}"/>"	{
					printf("} else {\n");
					}

.	;
[\n]	;





%%

int
main() {
  printf("int a,b,c,d,e,f,g,h,i,j,k,l,m;\n");
  printf("int n,o,p,q,r,s,t,u,v,w,x,y,z;\n\n");
  yylex();
}
