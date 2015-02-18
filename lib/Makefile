AR	= ar
LDFLAGS	=-s -x
CC	= gcc
LD = ld

CFLAGS = -std=gnu99 -nostdinc -I../include  -fno-builtin 

OBJS = ctype.o errno.o string.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.asm
	nasm -f elf -o $@ $<


lib.a: $(OBJS)
	$(AR) rcs lib.a $(OBJS)
	sync

clean:
	rm *.o

string.o: string.asm 
ctype.o: ../include/ctype.h

