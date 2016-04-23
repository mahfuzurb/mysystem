#define __LIBRARY__

#include <unistd.h>
#include <time.h>

#include <linux/sched.h>
#include <linux/head.h>
#include <string.h>

#include <asm/io.h>

extern int printk(const char *fmt, ...);

#define  EXT_MEM_K (*(unsigned short *) 0x90002)

static long memory_end = 0;
static long buffer_memory_end = 0;
static long main_memory_start = 0;
static char term[32];

static char * argv_rc[] = { "/bin/sh", NULL };
static char * envp_rc[] = { "HOME=/", NULL ,NULL };

static char * argv[] = { "-/bin/sh",NULL };
static char * envp[] = { "HOME=/usr/root", NULL, NULL };

extern void console_print(const char *);

int main(int argc, char const *argv[])
{
	int i = strlen("12345");
	memory_end = (1 << 20) + (EXT_MEM_K << 10);

	buffer_memory_end = 4 * 1024 * 1024;

	main_memory_start = buffer_memory_end;

	// printk("%s\n", "now we are in the main function");
	console_print("now we are in the main function");

	return 0;
}