extern unsigned char get_fs_byte(const char * addr);

extern unsigned short get_fs_word(const unsigned short *addr);

extern unsigned long get_fs_long(const unsigned long *addr);

extern void put_fs_byte(char val,char *addr);

extern void put_fs_word(short val,short * addr);

extern void put_fs_long(unsigned long val,unsigned long * addr);

/*
 * Someone who knows GNU asm better than I should double check the followig.
 * It seems to work, but I don't know if I'm doing something subtly wrong.
 * --- TYT, 11/24/91
 * [ nothing wrong here, Linus ]
 */

extern unsigned long get_fs();

extern unsigned long get_ds();

extern void set_fs(unsigned long val);