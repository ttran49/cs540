%{
#define NT 1
#define T 2
#define GOES 3
#define SEMI 4
#define OR 5
#define EPSILON 6

int esl = 0;

struct Elements
{
	char* string;
	struct Elements *next;
};

struct Terminal
{
	char name;
	struct Elements *pointer;
	struct Terminal *next;
};


%}
t	[A-Z]
nt	[a-z]

%%
{t}		{	
			return T;
			}
{nt}	{	
			return NT;
			}
"-->"	{	
			return GOES;
			}

"|"[^\n]*		{	
			if (yyleng > 1){
				return OR;
			} else {
				return EPSILON;
			}
			
			}
";"		{	
			return SEMI;
			}

[\n]	;
.	;

%%

int
main() {
	
	int b = -1;
	while (b != 0){
		b = yylex();
		if (b == T)
			printf("%s\n", yytext);
		else if (b == GOES)
			printf("-->\n");
		else if (b == NT)
			printf("%s\n",yytext);
		else if (b == OR)
			printf("|\n");
		else if (b == EPSILON)
			printf("| epsilon\n");
		else if (b == SEMI)
			printf(";\n");

	}
	
  	
}
