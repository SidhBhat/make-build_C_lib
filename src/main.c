#include<stdio.h>
#include"bits.h"

#define MAXLINE 300

int main(void)
{
	int x = 4;

	printBits(sizeof(x), &x);
	printf(" = %d\n", x);
	printf("No of bits in x = %d\n", Bitcount(x));
	return 0;
}
