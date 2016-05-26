AR = ar

OBJS = console.o tty_io.o
CC	= gcc
CFLAGS = -nostdinc -I../../include -m32 -fomit-frame-pointer -fno-builtin

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

chr_drv.a: $(OBJS)
	$(AR) rcs chr_drv.a $(OBJS)
	sync

clean:
	rm *.o
	rm *.a
# console.c: 