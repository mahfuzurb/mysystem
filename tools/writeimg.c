#include <stdio.h>
#include <stdlib.h>

#define SYS_POSITION 5

int write_file(FILE *out, const char * filename)
{
	FILE *in = fopen(filename, "rb");
	char buf[512];
	int rc;
	while( ( rc = fread(buf, sizeof(char), sizeof(buf), in)) )
	{
		fwrite(buf, sizeof(char), rc, out);
	}

	fclose(in);
}

int main(int argc, char const *argv[])
{
	FILE *out = fopen("a.img", "rb+");
	write_file(out, "boot/bootSect");
	write_file(out, "boot/setup");

	fseek(out, 512 *SYS_POSITION, SEEK_SET);

	write_file(out, "tools/system");

	fclose(out);
	return 0;
}