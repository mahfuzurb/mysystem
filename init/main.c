#define __LIBRARY__

#include <unistd.h>
#include <time.h>

static inline _syscall0(int, fork);

static inline _syscall0(int, pause);

// static inline _syscall1(int, setup, void *, BIOS);

#include <linux/sched.h>
#include <linux/head.h>

#include <asm/io.h>

extern long kernel_mktime(struct tm * tm);



#define  EXT_MEM_K (*(unsigned short *) 0x90002)

#define CMOS_READ(addr) ({ \
outb_p(addr,0x70); \
inb_p(0x71); \
})

#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

static void time_init(void)
{
	struct tm time;

	do {
		time.tm_sec = CMOS_READ(0);
		time.tm_min = CMOS_READ(2);
		time.tm_hour = CMOS_READ(4);
		time.tm_mday = CMOS_READ(7);
		time.tm_mon = CMOS_READ(8);
		time.tm_year = CMOS_READ(9);
	} while (time.tm_sec != CMOS_READ(0));
	BCD_TO_BIN(time.tm_sec);
	BCD_TO_BIN(time.tm_min);
	BCD_TO_BIN(time.tm_hour);
	BCD_TO_BIN(time.tm_mday);
	BCD_TO_BIN(time.tm_mon);
	BCD_TO_BIN(time.tm_year);
	time.tm_mon--;
	startup_time = kernel_mktime(&time);
}


static long memory_end = 0;
static long buffer_memory_end = 0;
static long main_memory_start = 0;
static char term[32];

static char * argv_rc[] = { "/bin/sh", NULL };
static char * envp_rc[] = { "HOME=/", NULL ,NULL };

static char * argv[] = { "-/bin/sh",NULL };
static char * envp[] = { "HOME=/usr/root", NULL, NULL };

void main(void)
{
	memory_end = (1 << 20) + (EXT_MEM_K << 10);

	buffer_memory_end = 4 * 1024 * 1024;

	main_memory_start = buffer_memory_end;

	// mem_init(main_memory_start,memory_end);
	// trap_init();
	// blk_dev_init();
	// chr_dev_init();
	// tty_init();
	time_init();
	// sched_init();
	// buffer_init(buffer_memory_end);
	// hd_init();
	// floppy_init();
	// sti();
	// move_to_user_mode();
	// if (!fork()) {		/* we count on this going ok */
	// 	init();
	// }

	for(;;);
	
}
