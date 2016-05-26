#include "errno.h"
#include "linux/tty.h"



#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

#define CON_QUEUES	(3*MAX_CONSOLES)


//控制台所需要的队列都在这里
static struct tty_queue con_queues[CON_QUEUES];

struct tty_struct con_table[MAX_CONSOLES];


int fg_console = 0;


// struct tty_queue * table_list[]={
// 	con_queues + 0, con_queues + 1
// };

int tty_write(unsigned channel, char * buf, int nr)
{
	static cr_flag=0;
	struct tty_struct * tty;
	char c, *b=buf;

	if (channel > MAX_CONSOLES)
		return -EIO;

	tty = con_table + (channel - 1);

	if (!(tty->write_q || tty->read_q || tty->secondary))
		return -EIO;

	while (nr > 0 && !FULL(tty->write_q)) {
		c=get_fs_byte(b);
		if(c == 10)  
			PUTCH(13, tty->write_q);
		PUTCH(c, tty->write_q);
		b++;
		nr--;
	}

	tty->write(tty);

	return (b-buf);
}

// void change_console(unsigned int new_console)
// {
// 	if (new_console == fg_console || new_console >= NR_CONSOLES)
// 		return;
// 	fg_console = new_console;
// 	table_list[0] = con_queues + 0 + fg_console*3;
// 	table_list[1] = con_queues + 1 + fg_console*3;
// 	update_screen();
// }

// void do_tty_interrupt(int tty)
// {
// 	copy_to_cooked(TTY_TABLE(tty));
// }

// void chr_dev_init(void)
// {
// }

void tty_init(void)
{
	int i;

	// printk("begin tty init\n");

	for (i=0 ; i < CON_QUEUES ; i++)
		con_queues[i] = (struct tty_queue) {0,0,0,0,""};
	for (i=0 ; i<MAX_CONSOLES ; i++) {
		con_table[i] =  (struct tty_struct) {
		 	{0, 0, 0, 0, 0, INIT_C_CC},
			0, 0, 0, NULL, NULL, NULL, NULL
		};
	}
	con_init();

	printk("end console init\n");

	for (i = 0 ; i<NR_CONSOLES ; i++) {
		con_table[i] = (struct tty_struct) {
		 	{ICRNL,		/* change incoming CR to NL */
			OPOST|ONLCR,	/* change outgoing NL to CRNL */
			0,
			IXON | ISIG | ICANON | ECHO | ECHOCTL | ECHOKE,
			0,		/* console termio */
			INIT_C_CC},
			0,			/* initial pgrp */
			0,			/* initial session */
			0,			/* initial stopped */
			con_write,
			con_queues+0+i*3,con_queues+1+i*3,con_queues+2+i*3
		};
	}
	printk("%d virtual consoles\n\r",NR_CONSOLES);
}