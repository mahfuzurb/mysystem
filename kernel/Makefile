AR	= ar
LDFLAGS	=-s -x
CC	= gcc
LD = ld

CFLAGS = -std=gnu99 -nostdinc -I../include  -fno-builtin 

OBJS  = sched.o mktime.o sys.o traps.o sys_call.o asm.o segment.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.asm
	nasm -f elf -o $@ $<

	
kernel.o: $(OBJS)
	$(LD) -r -o kernel.o $(OBJS)
	sync


clean:
	rm *.o
	(cd chr_drv; make clean)


sched.o: ../include/linux/sys.h

mktime.o: mktime.c ../include/time.h

sys.o: sys.c

traps.o: traps.c ../include/string.h ../include/linux/head.h \
	../include/linux/sched.h ../include/linux/kernel.h \
	../include/asm/system.h ../include/asm/segment.h \
	../include/asm/io.h

sys_call.o: sys_call.asm 

asm.o: asm.asm