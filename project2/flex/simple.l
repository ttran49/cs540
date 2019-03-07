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

int follow_trigger = 0;
int follow_set = 0;
int lookahead;


struct Terminal
{
	char name;
	int first;
	int follow;
	int first_sets;
	int follow_sets;
	int follow_first_sets;
	struct Terminal *next;
}Terminal;
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

void print_sets(struct Header *header){
	struct Terminal *temp = header->start;

	while (temp != NULL){
		printf("First(%c) -> ",temp->name);

		
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
		for (i = 0; i< 26; i++)
		{
			if (temp->first_sets & (1 << i)){
				printf("First(%c), ", (i+65));
			}
		}
		printf("\n");
		printf("Follow(%c) -> $, ",temp->name);

		for (i = 0; i < 26; i++)
		{
			if (temp->follow & (1 << i)){
				if (i < 26)
					printf("%c, ", (i+97));
			}
		}

		for (i = 0; i< 26; i++)
		{
			if (temp->follow_sets & (1 << i)){
				if (i < 26)
					printf("Follow(%c), ", (i+65));
			}
		}
		for (i = 0; i< 26; i++)
		{
			if (temp->follow_first_sets & (1 << i)){
				if (i < 26)
					printf("First(%c), ", (i+65));
			}
		}
		printf("\n");
		temp=temp->next;
	}
}


int find(char letter, int first){
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

struct Terminal *get_follow(int set){
	//printf("finding %c\n", set);
	struct Terminal *temp= header->start;
	while(temp->next != NULL){
		if (set == temp->name)
			return temp;
		temp = temp->next;
	}
	// not exist if reach this point

	//printf("%c\n", temp->name);
	//printf("---- %c\n", temp->name);
	if (temp->name == set)
		return temp;
	struct Terminal *new = malloc(sizeof(struct Terminal));
	new->name = set;
	new->first=0;
	new->follow = 0;
	new->first_sets = 0;
	new->follow_sets = 0;
	new->follow_first_sets = 0;
	new->next = NULL;
	temp->next = new;

	return new;
}


void error(char *where) {
  printf("\nSyntax error line: %s\n", where);
  printf("Token seen: %d\n",lookahead);
  printf("Text: %c\n",yytext);
  exit(42);
}

void match(int token) {
	//printf("%d-%c\n", token, character);

	if (token == lookahead){
		if ((lookahead == GOES) || (lookahead == OR))
			first_trigger = 1;
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
	//printf("| rule |");
	if (lookahead == NT){
		// FIRST SET
		if (first_trigger){
			int a = find(character,1);
			out->first = out->first | a;
			//first_trigger = 0;
			if (a & (1 << 26))
				esl_trigger = 1;
			else
				esl_trigger = 0;

			//printf("First(%c) contains First(%c)\n", out->name, character);
			out->first_sets = out->first_sets | (1 << (character - 65));
		}

		//third rule and second rule ishh
		if (follow_trigger){
			int a = find(character,1);
			// A -> B C
			// C -> epsilon => follow(B) = follow(B) U follow(A) U first(C)
			//printf("follow_set %c \n",follow_set);

			struct Terminal *temp = get_follow(follow_set);

			//printf("rule\n");
			if (a & (1 << 27)){
				temp->follow = temp->follow | out->follow | out->first;
			} else if (!(a & (1 << 27))){
				temp->follow = temp->follow | out->first;
			}
			

			//printf("Follow(%c) = Follow(%c) U First(%c)\n",follow_set,follow_set, character);
			temp->follow_first_sets = temp->follow_first_sets | (1 << (character - 65));
		}


		follow_trigger = 1;
		follow_set = character;
		match(NT);
		rule(out);
	} else if (lookahead == T){
		//find first set
		if (first_trigger || esl_trigger){
			out->first = out->first | (1 << (character - 97));
			first_trigger = 0;
			esl_trigger = 0;
			//printf("First(%c) contains %c\n", out->name, character);
		}
		//follow set
		// FIRST RULE OF FOLLOW
		if (follow_trigger){
			struct Terminal *temp = get_follow(follow_set);
			temp->follow = temp->follow | (1 << (character - 97));
		
			//printf("Follow(%c) contains %c\n", follow_set,character);
			follow_trigger =0;
			follow_set = 0;
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
			//printf("First(%c) contains epsilon\n", out->name);
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
	//printf("| production_body_prime | ");
	if (lookahead == OR){
		//rule 3
		if (follow_trigger){
			if (follow_trigger){
			struct Terminal *temp = get_follow(follow_set);
			temp->follow = temp->follow | out->follow;
				
			//printf("Follow(%c) = Follow(%c) U Follow(%c)\n",follow_set,follow_set, out->name);
			temp->follow_sets = temp->follow_sets | (1 << (out->name - 65));
			}
		}

		match(OR);
		follow_trigger = 0;
		follow_set = 0;
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
	//printf("| production_body |");
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
	//printf("| ending |");
	if (lookahead == EPSILON){
		match(EPSILON);
		match(SEMI);
		match(EOL);
		return;
	} else if (lookahead == SEMI){
		if (follow_trigger){
			struct Terminal *temp = get_follow(follow_set);
			temp->follow = temp->follow | out->follow;
			
			//printf("Follow(%c) = Follow(%c) U Follow(%c)\n",follow_set,follow_set, out->name);
			temp->follow_sets = temp->follow_sets | (1 << (out->name - 65));
			follow_trigger =0;
			follow_set = 0;
		}
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
	//printf("| production |");
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
			a->first_sets = 0;
			a->follow_sets = 0;
			a->follow_first_sets = 0;
			a->next = NULL;
			temp-> next = a;

			temp = temp->next;

		}

		match(NT);				// 	1
		match(GOES);			//	3
		first_trigger = 1;
		follow_trigger = 0;
		follow_set = 0;
		production_body(temp);
		ending(temp);
		//printf("\n");
	} else{
		error("production");
	}
}

//prod_list_prime : production prod_list_prime
//	****			| ret
void prod_list_prime(struct Header *header){
	//printf("| prod_list_prime |");
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
	//printf("| prod_list |");
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
		temp->first_sets = 0;
		temp->follow_sets = 0;
		temp->follow_first_sets= 0;
		temp->next = NULL;

		//assgin
		header->start = temp;
	}

	lookahead = yylex();
	prod_list(header);
	if (lookahead == 0){
		printf("DONE PARSING\n");
	}
	else{
		printf("rejected\n");
	}
}

//process the first and follow sets data
void process(struct Header *header){
	struct Terminal *temp = header->start;

	while (temp!= NULL){
		
		int i;
		for (i = 0 ; i <26 ; i++){
			//	int first_sets;
			//	int follow_sets;
			//	int follow_first_sets;

			//process first set
			if (temp->first_sets & (1 << i)){
				temp->first = temp->first | (find(i+65,1));
				//printf("First(%c) += first(%c)\n", temp->name, (i+65));
			}

			//process follow_sets
			if (temp->follow_sets & (1 << i)){
				temp->follow = temp->follow | (find(i+65,0));
				//printf("Follow(%c) += follow(%c)\n", temp->name, (i+65));
			}
			if (temp->follow_first_sets & (1 << i)){
				temp->follow = temp->follow | (find(i+65,1));
				//printf("Follow(%c) += first(%c)\n", temp->name, (i+65));
			}
		}


		temp=temp->next;

	}
}
void print_final(struct Header *header){
	struct Terminal *temp = header->start;

	while (temp != NULL){
		printf("First(%c) -> ",temp->name);

		
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
		printf("\nFollow(%c) -> $, ",temp->name);
		for (i = 0; i < 26; i++)
		{
			if (temp->follow & (1 << i)){
				printf("%c, ", (i+97));

			}
		}
		printf("\n");
		temp= temp->next;
	}
}	

void main(){
	header=malloc(sizeof(struct Header));
	header->start = NULL;


	start();
//	print_sets(header);
	int i;
	for (i = 0; i< 4; i++){
		process(header);
	}
	print_final(header);

}
