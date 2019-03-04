%{
#define NT 1
#define T 2
#define GOES 3
#define SEMI 4
#define OR 5
#define EPSILON 6
#define EOL 7

int character=0;
int esl = 0;
int esl_trigger = 0;
int first_trigger=0;
int lookahead;

struct Terminal
{
	char name;
	int first;
	int follow;
	struct Terminal *next;
};
struct Header
{
	struct Terminal *start;
};

struct Header *header = NULL;


%}
nt	[A-Z]
t	[a-z]

%%
{t}		{	
			esl=0;
			character = *yytext;
			return T;
			}
{nt}	{	
			esl= 0;
			character = *yytext;
			return NT;
			}
"-->"	{	
			return GOES;
			}

"|"		{	
			esl = 1;
			return OR;
			
			}
";"		{return SEMI;}

[\n]	{	if (esl){
				esl = 0;
				return EPSILON;
			}else
				return EOL;}
.	;

%%

/*

RIGHT RECURSION
prod_list : production prod_list_prime
prod_list_prime : production prod_list_prime
| ret
production : NT GOES production_body ending
production_body : rule production_body_prime
production_body_prime : OR rule production_body_prime
| ret
rule : NT rule
| T rule
| EOL
ending : EPSILON SEMI EOL
|	SEMI EOL

*/

int find(char letter,int first){
	struct Terminal *temp= header->start;
	while(temp != NULL){
		if (letter == temp->name && first)
			return temp->first;
		else if (letter == temp->name && !first)
			return temp->follow;
		temp = temp->next;
	}
	return 0;
}



void error(char *where) {
  printf("\nSyntax error line: %s\n", where);
  printf("Token seen: %d\n",lookahead);
  printf("Text: %c\n",yytext);
  exit(42);
}

void match(int token) {
	printf("%d", token);
	if (token == lookahead){
		if ((lookahead == GOES) || (lookahead == OR))
			first_trigger =1;
		lookahead = yylex();
	}
	else{ 
		error("match");
	}
}

//rule : NT rule
//	| T rule
//	| EOL
void rule(struct Terminal *out)
{
	if (lookahead == NT){
		// captital aka set
		if (first_trigger){
			int a = find(character, 1);
			out->first = out->first | a;
			first_trigger = 0;
			if (a & (1 << 26))
				esl_trigger = 1;
			else
				esl_trigger = 0;
		} 
		match(NT);
		rule(out);
	} else if (lookahead == T){

		//find first set
		if (first_trigger || esl_trigger){
			out->first = out->first | (1 << (character - 97));
			first_trigger = 0;
			esl_trigger = 0;
		}
		match(T);
		rule(out);
	} else if (lookahead == EOL){		
		match(EOL);
		return;
	} else if (lookahead == EPSILON){
		if (first_trigger){
			out->first = out->first | (1 << 26);
			first_trigger = 0;
			esl_trigger = 0;
		}
		return;
	}
	else{
		error("rule");
	}
}

//production_body_prime : OR rule production_body_prime
//	****				| ret
void production_body_prime(struct Terminal *out)
{
	if (lookahead == OR){
		match(OR);
		rule(out);
		production_body_prime(out);
	} else if ((lookahead == 0) || (lookahead == SEMI) ||(lookahead == EPSILON)){
		return;
	} 
	else{
		error("production_body_prime");
	}
}


//production_body : rule production_body_prime
void production_body(struct Terminal *out)
{
	if ((lookahead == NT )|| (lookahead == T)){
		rule(out);
		production_body_prime(out);
	} else{
		error("production_body");
	}
}

//ending : EPSILON SEMI EOL
//		|	SEMI EOL
void ending(struct Terminal *out)
{
	if (lookahead == EPSILON){
		match(EPSILON);
		match(SEMI);
		match(EOL);
		return;
	} else if (lookahead == SEMI){
		match(SEMI);
		match(EOL);
		return;
	} else{
		error("ending");
	}
}


//###############
// GOOD FOR SET CREATION

//production : NT GOES production_body ending
void production(struct Terminal *out)
{
	if (lookahead == NT){
		//check if a set is create for the production
		struct Terminal *temp = out;
		while (temp->next != NULL){
			if(temp->name == character)
				break;
			temp=temp->next;
		}

		if (temp->name != character){
			struct Terminal *a = malloc(sizeof(struct Terminal));
			a->name = character;
			a->first = 0;
			a->follow = 0;
			a->next = NULL;
			temp-> next = a;

			temp = temp->next;

		}

		match(NT);				// 	1
		match(GOES);			//	3
		first_trigger = 1;
		production_body(temp);
		ending(out);
	} else{
		error("production");
	}
}

//prod_list_prime : production prod_list_prime
//	****			| ret
void prod_list_prime(struct Header *header){
	printf("\nprod_list_p: ");


	if (lookahead == NT){
		production(header->start);
		prod_list_prime(header);
	} else if (lookahead == 0){
		return;
	}
	else{
		error("prod_list_prime");
	}
}

//prod_list : production prod_list_prime
void prod_list(struct Header *header)
{
	printf("prod_list: ");
	if (lookahead == NT){
		//create init set name
		header->start->name = character;

		production(header->start);
		prod_list_prime(header);
	}else{
		error("prod_list");
	}
}

void start()
{
	
	// first sets
	if (header->start ==  NULL){
		struct Terminal *temp =  malloc(sizeof(struct Terminal));
		temp->name = 0;
		temp->first = 0;
		temp->follow = 0;
		temp->next = NULL;

		//assgin
		header->start = temp;
	}

	lookahead = yylex();
	prod_list(header);
	if (lookahead == 0){
		printf("DONE\n");
	}
	else{
		printf("rejected\n");
	}
}


void print_sets(struct Header *header){
	struct Terminal *temp = header->start;

	while (temp != NULL){
		printf("%c -> ",temp->name);

		
		int i;
		for (i = 0; i < 27; i++)
		{
			if (temp->first & (1 << i)){
				if (i < 26)
					printf("%c, ", (i+97));
				else 
					printf("epsilon, ");
			}
		}
		printf("\n");
		temp=temp->next;
	}
}

void main(){
	header=malloc(sizeof(struct Header));
	header->start = NULL;
	start();
	print_sets(header);
}

