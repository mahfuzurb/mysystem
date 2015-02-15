IMG_HEADER_LEN = 0x1000

TEXT_OFF = 0x101000

LDFLAGS	=-s -x -M -T tools/system.lds

a.img: boot/bootSect boot/setup tools/system tools/makeimg
	tools/makeimg $(IMG_HEADER_LEN)
	sync

tools/makeimg: tools/makeimg.cpp boot/bootSect boot/setup tools/system
	g++ tools/makeimg.cpp -o tools/makeimg

boot/head.o: boot/head.asm
	nasm -f elf boot/head.asm -o boot/head.o

tools/system: boot/head.o init/main.o kernel/shed.o
	ld $(LDFLAGS) boot/head.o init/main.o kernel/shed.o \
		-o tools/system > System.map



boot/bootSect: boot/bootSect.asm
	nasm -f bin boot/bootSect.asm

boot/setup: boot/setup.asm
	nasm -f bin boot/setup.asm



init/main.o:init/main.c include/string.h 
	gcc   -c init/main.c -o init/main.o



lib/string.o:lib/string.asm 
	nasm -f elf lib/string.asm 

kernel/shed.o:kernel/shed.c 
	gcc -c kernel/shed.c -o kernel/shed.o

clean:
	rm a.img System.map tools/system tools/makeimg boot/bootSect boot/setup
	rm init/*.o boot/*.o 


