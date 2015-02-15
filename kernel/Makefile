AR	= ar
LDFLAGS	=-s -x
CC	= gcc
LD = ld



OBJS  = sched.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
	
kernel.o: $(OBJS)
	$(LD) -r -o kernel.o $(OBJS)
	sync


clean:
	rm *.o
	(cd chr_drv; make clean)