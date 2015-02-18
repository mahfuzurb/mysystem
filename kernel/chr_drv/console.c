static int x = 0;
static int y = 0;

static char attr = 0x07;
static int 	pos   = 0xb0000;

void console_print(const char *b) {

	char c;
	while(c = *(b++)) {

		__asm__("movb %2, %%ah\n\t"
			"movw %%ax, %1\n\t"
			::"a" (c),
			"m" (*(int *)pos),
			"m" (attr)
			);
		pos += 2;
		x++;
	}

	
}