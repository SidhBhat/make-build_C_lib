#include<stdio.h>
#include"my_strings.h"
#include"str_float.h"

#define MAXLINE 300

void PrintData(char *str)
{
	long double ld;

	printf("Character string\t\t: \"%s\"\n", str);
	printf("Floating point value\t\t= %0.20Lg\n",ld = btof(str, DEC));
	printf("Reconversion to hex string\t: \"%s\"\n",ftobg(ld, str, 25,HEX));
	printf("Reconversion to decimal string\t: \"%s\"\n",ftobg(ld, str, 25,DEC));
	printf("Reconversion to octal string\t: \"%s\"\n",ftobg(ld, str, 25,OCT));
	printf("Reconversion to binary string\t: \"%s\"\n",ftobg(ld, str, 25,BIN));
}

int main(void)
{
	char str[MAXLINE];

	printf("Type a number : ");
	Getline(str, sizeof(str));
	{
		int i;
		for(i = 0; str[i] != '\n';i++)
			;
		str[i] = '\0';
	}
	PrintData(str);
	return 0;
}
