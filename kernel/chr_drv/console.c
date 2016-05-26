#include <linux/sched.h>
#include <linux/tty.h>
#include <linux/kernel.h>

#include <asm/io.h>
#include <asm/system.h>
#include <asm/segment.h>

#include <string.h>
#include <errno.h>

// static int x = 0;
// static int y = 0;

// static char 	attr = 0x07;
// static int 	pos   = 0xb8000;

#define ORIG_X			(*(unsigned char *)0x90000)
#define ORIG_Y			(*(unsigned char *)0x90001)
#define ORIG_VIDEO_PAGE		(*(unsigned short *)0x90004)
#define ORIG_VIDEO_MODE		((*(unsigned short *)0x90006) & 0xff)
#define ORIG_VIDEO_COLS 	(((*(unsigned short *)0x90006) & 0xff00) >> 8)
#define ORIG_VIDEO_LINES	((*(unsigned short *)0x9000e) & 0xff)

#define VIDEO_TYPE_MDA		0x10	/* Monochrome Text Display	*/
#define VIDEO_TYPE_CGA		0x11	/* CGA Display 			*/
#define VIDEO_TYPE_EGAM		0x20	/* EGA/VGA in Monochrome Mode	*/
#define VIDEO_TYPE_EGAC		0x21	/* EGA/VGA in Color Mode	*/

int NR_CONSOLES = 0;

extern void keyboard_interrupt(void);

static unsigned char	video_type;		/* Type of display being used	*/
static unsigned long	video_num_columns;	/* Number of text columns	*/
static unsigned long	video_mem_base;		/* Base of video memory		*/
static unsigned long	video_mem_term;		/* End of video memory		*/
static unsigned long	video_size_row;		/* Bytes per row		*/
static unsigned long	video_num_lines;	/* Number of test lines		*/
static unsigned char	video_page;		/* Initial video page		*/
static unsigned short	video_port_reg;		/* Video register select port	*/
static unsigned short	video_port_val;		/* Video register value port	*/
static int can_do_colour = 0;

static struct {
	unsigned short	vc_video_erase_char;	
	unsigned char	vc_attr;
	unsigned char	vc_def_attr;
	int		vc_bold_attr;
	unsigned long	vc_ques;
	unsigned long	vc_state;
	unsigned long	vc_restate;
	unsigned long	vc_checkin;
	unsigned long	vc_origin;		/* Used for EGA/VGA fast scroll	*/
	unsigned long	vc_scr_end;		/* Used for EGA/VGA fast scroll	*/
	unsigned long	vc_pos;
	unsigned long	vc_x,vc_y;
	unsigned long	vc_top,vc_bottom;
	// unsigned long	vc_npar,vc_par[NPAR];
	unsigned long	vc_video_mem_start;	/* Start of video RAM		*/
	unsigned long	vc_video_mem_end;	/* End of video RAM (sort of)	*/
	unsigned int	vc_saved_x;
	unsigned int	vc_saved_y;
	unsigned int	vc_iscolor;
	char *		vc_translate;
} vc_cons [MAX_CONSOLES];

#define origin		(vc_cons[currcons].vc_origin)
#define scr_end		(vc_cons[currcons].vc_scr_end)
#define pos		(vc_cons[currcons].vc_pos)
#define top		(vc_cons[currcons].vc_top)
#define bottom		(vc_cons[currcons].vc_bottom)
#define x		(vc_cons[currcons].vc_x)
#define y		(vc_cons[currcons].vc_y)
#define state		(vc_cons[currcons].vc_state)
#define restate		(vc_cons[currcons].vc_restate)
#define checkin		(vc_cons[currcons].vc_checkin)
#define npar		(vc_cons[currcons].vc_npar)
#define par		(vc_cons[currcons].vc_par)
#define ques		(vc_cons[currcons].vc_ques)
#define attr		(vc_cons[currcons].vc_attr)
#define saved_x		(vc_cons[currcons].vc_saved_x)
#define saved_y		(vc_cons[currcons].vc_saved_y)
#define translate	(vc_cons[currcons].vc_translate)
#define video_mem_start	(vc_cons[currcons].vc_video_mem_start)
#define video_mem_end	(vc_cons[currcons].vc_video_mem_end)
#define def_attr	(vc_cons[currcons].vc_def_attr)
#define video_erase_char  (vc_cons[currcons].vc_video_erase_char)	
#define iscolor		(vc_cons[currcons].vc_iscolor)

int blankinterval = 0;
int blankcount = 0;

// static void save_cur(int currcons)
// {
// 	saved_x=x;
// 	saved_y=y;
// }

// static void restore_cur(int currcons)
// {
// 	gotoxy(currcons,saved_x, saved_y);
// }

static inline void gotoxy(int currcons, int new_x,unsigned int new_y)
{
	if (new_x > video_num_columns || new_y >= video_num_lines)
		return;
	x = new_x;
	y = new_y;
	pos = origin + y*video_size_row + (x<<1);
}

static inline void set_origin(int currcons)
{
	// if (video_type != VIDEO_TYPE_EGAC && video_type != VIDEO_TYPE_EGAM)
	// 	return;
	if (currcons != fg_console)
		return;
	cli();
	outb_p(12, video_port_reg);
	outb_p(0xff&((origin-video_mem_base)>>9), video_port_val);
	outb_p(13, video_port_reg);
	outb_p(0xff&((origin-video_mem_base)>>1), video_port_val);
	sti();
}

static void scrup(int currcons)
{
	if (bottom<=top)
		return;
	if (video_type == VIDEO_TYPE_EGAC || video_type == VIDEO_TYPE_EGAM)
	{
		if (!top && bottom == video_num_lines) {
			origin += video_size_row;
			pos += video_size_row;
			scr_end += video_size_row;
			if (scr_end > video_mem_end) {
				__asm__("cld\n\t"
					"rep\n\t"
					"movsl\n\t"
					"movl video_num_columns,%1\n\t"
					"rep\n\t"
					"stosw"
					::"a" (video_erase_char),
					"c" ((video_num_lines-1)*video_num_columns>>1),
					"D" (video_mem_start),
					"S" (origin));
				scr_end -= origin-video_mem_start;
				pos -= origin-video_mem_start;
				origin = video_mem_start;
			} else {
				__asm__("cld\n\t"
					"rep\n\t"
					"stosw"
					::"a" (video_erase_char),
					"c" (video_num_columns),
					"D" (scr_end-video_size_row));
			}
			set_origin(currcons);
		} else {
			__asm__("cld\n\t"
				"rep\n\t"
				"movsl\n\t"
				"movl video_num_columns,%%ecx\n\t"
				"rep\n\t"
				"stosw"
				::"a" (video_erase_char),
				"c" ((bottom-top-1)*video_num_columns>>1),
				"D" (origin+video_size_row*top),
				"S" (origin+video_size_row*(top+1)));
		}
	}
	else		/* Not EGA/VGA */
	{
		__asm__("cld\n\t"
			"rep\n\t"
			"movsl\n\t"
			"movl video_num_columns,%%ecx\n\t"
			"rep\n\t"
			"stosw"
			::"a" (video_erase_char),
			"c" ((bottom-top-1)*video_num_columns>>1),
			"D" (origin+video_size_row*top),
			"S" (origin+video_size_row*(top+1)));
	}
}

static void scrdown(int currcons)
{
	if (bottom <= top)
		return;
	if (video_type == VIDEO_TYPE_EGAC || video_type == VIDEO_TYPE_EGAM)
	{
		__asm__("std\n\t"
			"rep\n\t"
			"movsl\n\t"
			"addl $2,%%edi\n\t"	/* %edi has been decremented by 4 */
			"movl video_num_columns,%%ecx\n\t"
			"rep\n\t"
			"stosw"
			::"a" (video_erase_char),
			"c" ((bottom-top-1)*video_num_columns>>1),
			"D" (origin+video_size_row*bottom-4),
			"S" (origin+video_size_row*(bottom-1)-4));
	}
	else		/* Not EGA/VGA */
	{
		__asm__("std\n\t"
			"rep\n\t"
			"movsl\n\t"
			"addl $2,%%edi\n\t"	/* %edi has been decremented by 4 */
			"movl video_num_columns,%%ecx\n\t"
			"rep\n\t"
			"stosw"
			::"a" (video_erase_char),
			"c" ((bottom-top-1)*video_num_columns>>1),
			"D" (origin+video_size_row*bottom-4),
			"S" (origin+video_size_row*(bottom-1)-4));
	}
}

static void lf(int currcons)
{
	if (y+1<bottom) {
		y++;
		pos += video_size_row;
		return;
	}
	scrup(currcons);
}

static void cr(int currcons)
{
	pos -= x<<1;
	x=0;
}

static void del(int currcons)
{
	if (x) {
		pos -= 2;
		x--;
		*(unsigned short *)pos = video_erase_char;
	}
}


static inline void set_cursor(int currcons)
{
	blankcount = blankinterval;
	if (currcons != fg_console)
		return;
	cli();
	outb_p(14, video_port_reg);
	outb_p(0xff&((pos-video_mem_base)>>9), video_port_val);
	outb_p(15, video_port_reg);
	outb_p(0xff&((pos-video_mem_base)>>1), video_port_val);
	sti();
}
void update_screen(void)
{
	set_origin(fg_console);
	set_cursor(fg_console);
}



//控制台初始化，读取显示参数设置当前控制台及显存地址
void con_init()
{
	register unsigned char a;
	char *display_desc = "????";
	char *display_ptr;
	int currcons = 0;
	long base, term;
	long video_memory;

	video_num_columns = ORIG_VIDEO_COLS;
	video_size_row = video_num_columns * 2;
	video_num_lines = ORIG_VIDEO_LINES;
	video_page = ORIG_VIDEO_PAGE;
	video_erase_char = 0x0720;
	blankcount = blankinterval;

	//bochs is color
	can_do_colour = 1;
	video_mem_base = 0xb8000;
	video_port_reg	= 0x3d4;
	video_port_val	= 0x3d5;
	video_type = VIDEO_TYPE_EGAC;

	// just for test !!!!!
	video_mem_term = 0xba000;

	video_memory = video_mem_term - video_mem_base;
	NR_CONSOLES = video_memory / (video_num_lines * video_size_row);
	if (NR_CONSOLES > MAX_CONSOLES)
		NR_CONSOLES = MAX_CONSOLES;
	if (!NR_CONSOLES)
		NR_CONSOLES = 1;
	video_memory /= NR_CONSOLES;

	base = origin = video_mem_start = video_mem_base;
	term = video_mem_end = base + video_memory;
	scr_end	= video_mem_start + video_num_lines * video_size_row;
	top	= 0;
	bottom	= video_num_lines;
  	attr = 0x07;
  	def_attr = 0x07;

  	// restate = state = ESnormal;
	checkin = 0;
	ques = 0;
	iscolor = 0;
	// translate = NORM_TRANS;
	vc_cons[0].vc_bold_attr = -1;
  	// translate = NORM_TRANS;

  	// gotoxy(currcons,ORIG_X,ORIG_Y);
  	gotoxy(currcons,0,0);
  	for (currcons = 1; currcons<NR_CONSOLES; currcons++) {
		vc_cons[currcons] = vc_cons[0];
		origin = video_mem_start = (base += video_memory);
		scr_end = origin + video_num_lines * video_size_row;
		video_mem_end = (term += video_memory);
		gotoxy(currcons,0,0);
	}

	update_screen();

	//键盘初始化应该在这里!!!!!!!!!!
}


void con_write(struct tty_struct * tty)
{
	int nr;
	char c;
	int currcons;
     
	currcons = tty - con_table;
	if ((currcons>=MAX_CONSOLES) || (currcons<0))
		panic("con_write: illegal tty");
 	   
	nr = CHARS(tty->write_q);
	while (nr--) {
		GETCH(tty->write_q,c);

		if (c>31 && c<127) {
			if (x>=video_num_columns) {
				x -= video_num_columns;
				pos -= video_size_row;
				lf(currcons);
			}
			__asm__("movb %2,%%ah\n\t"
				"movw %%ax,%1\n\t"
				::"a" (c),
				"m" (*(short *)pos),
				"m" (attr));
			pos += 2;
			x++;
		} else if (c==10 || c==11 || c==12)
			lf(currcons);
		else if (c==13)
			cr(currcons);
	}
	set_cursor(currcons);

}


void console_print(const char *b) {

	int currcons = fg_console;
	char c;
	while(c = *(b++)) {
		if (c == 10) {
			cr(currcons);
			lf(currcons);
			continue;
		}
		if (c == 13) {
			cr(currcons);
			continue;
		}
		if (x>=video_num_columns) {
			x -= video_num_columns;
			pos -= video_size_row;
			lf(currcons);
		}
		asm("movb %2, %%ah\n\t"
			"movw %%ax, %1\n\t"
			::"a" (c),
			"m" (*(short *)pos),
			"m" (attr)
			);
		pos += 2;
		x++;
	}

	set_cursor(currcons);
}
