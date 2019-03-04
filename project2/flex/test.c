#include <stdlib.h>



void main(int argc,char* argv[])
{
	int a = 0;

	a = a | (1 << ('a' - 97));
	a = a | (1 << ('b' - 97));
	a = a | (1 << ('e' - 97));
	a = a | (1 << ('y' - 97));
	a = a | (1 << ('g' - 97));
	a = a | (1 << ('p' - 97));

	printf("----->  %d\n", a);
	printf("-> %d\n", ('a' - 97));
	printf("-> %d\n", ('b' - 97));
	printf("-> %d\n", ('e' - 97));
	printf("-> %d\n", ('y' - 97));
	printf("-> %d\n", ('g' - 97));
	printf("-> %d\n", ('p' - 97));

	printf("%d\n", a & (1 << 3));


	int i;
	for (i = 0; i < 26; i++)
	{
		if (a & (1 << i)){

			if (i < 26)
				printf("%c, ", (i+97));
			else 
				printf(" epsilon, ");
		}
	}

	return;
}