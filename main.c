#include <stdio.h>
#include "include/string.h"

int main(int argc, char const *argv[])
{
	char a[5]="a";
	char *b ="abc";
	

	// strncat(a, b, 2);
	printf("%d\n", strncmp(b, a, 2));
	return 0;
}
