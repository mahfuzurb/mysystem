IMG_HEADER_LEN = 0x1000

TEXT_OFF = 0x101000

LDFLAGS	=-s -x -M -T tools/system.lds
CC = gcc

DRIVERS = 
ARCHIVES=kernel/kernel.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<


all: a.img

a.img: boot/bootSect boot/setup tools/system tools/makeimg
	tools/makeimg $(IMG_HEADER_LEN)
	sync

tools/makeimg: tools/makeimg.cpp boot/bootSect boot/setup tools/system
	g++ tools/makeimg.cpp -o tools/makeimg

boot/head.o: boot/head.asm
	nasm -f elf boot/head.asm -o boot/head.o

tools/system: boot/head.o init/main.o $(DRIVERS) $(ARCHIVES)
	ld $(LDFLAGS) boot/head.o init/main.o \
		$(ARCHIVES) \
		$(DRIVERS) \
		-o tools/system > System.map



boot/bootSect: boot/bootSect.asm
	nasm -f bin boot/bootSect.asm

boot/setup: boot/setup.asm
	nasm -f bin boot/setup.asm


kernel/kernel.o:
	cd kernel; make


kernel/chr_drv/chr_drv.a:
	cd kernel/chr_drv; make



clean:
	rm a.img System.map tools/system tools/makeimg boot/bootSect boot/setup
	rm init/*.o boot/*.o 
	(cd kernel;make clean)


