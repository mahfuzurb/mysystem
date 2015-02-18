AR = ar

OBJS = console.o
CC	= gcc
CFLAGS = -nostdinc -I../../include

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

chr_drv.a: $(OBJS)
	$(AR) rcs chr_drv.a $(OBJS)
	sync

clean:
	rm *.o
	rm *.a
# console.c: 