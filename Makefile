IMG_HEADER_LEN = 0x1000

TEXT_OFF = 0x101000

LDFLAGS	= -m elf_i386 -s -x -M -T tools/system.lds
# LDFLAGS	= –Ttext 0x0 –e main
# LDFLAGS = –Ttext 0x0

# -nostdinc 不在标准系统目录中搜索头文件,只在-I指定的目录中搜索
# -fno-builtin 不包含c标准库，使用自己编写的标准库
# -fno-stack-protector  防止出现错误   “ 对‘__stack_chk_fail’未定义的引用 ”
CFLAGS = -nostdinc -Iinclude -m32 -fno-builtin -fno-stack-protector
CC = gcc

DRIVERS = kernel/chr_drv/chr_drv.a
ARCHIVES=kernel/kernel.o
LIBS	=lib/lib.a

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<


all: a.img

a.img: boot/bootSect boot/setup tools/systemtest tools/writeimg
	objcopy -R .note -R .comment -S -O binary tools/systemtest tools/system
	tools/writeimg
	sync

tools/makeimg: tools/makeimg.cpp boot/bootSect boot/setup tools/system
	g++ tools/makeimg.cpp -o tools/makeimg

tools/writeimg: tools/writeimg.c boot/bootSect boot/setup
	gcc tools/writeimg.c -o tools/writeimg


boot/head.o: boot/head.asm
	nasm -f elf32 boot/head.asm -o boot/head.o

tools/systemtest: boot/head.o init/testmain.o $(ARCHIVES) $(DRIVERS) $(LIBS)
	ld  $(LDFLAGS) boot/head.o init/testmain.o  \
		$(ARCHIVES) \
		$(DRIVERS) \
		$(LIBS) \
		-o tools/systemtest > System.map

tools/system: boot/head.o init/main.o $(DRIVERS) $(ARCHIVES) $(LIBS)
	ld $(LDFLAGS) boot/head.o init/main.o \
		$(ARCHIVES) \
		$(DRIVERS) \
		$(LIBS) \
		-o tools/system > System.map



boot/bootSect: boot/bootSect.asm
	nasm -f bin boot/bootSect.asm

boot/setup: boot/setup.asm
	nasm -f bin boot/setup.asm

boot/head: boot/head.asm
	nasm -f bin boot/head.asm

kernel/kernel.o:
	(cd kernel; make)


kernel/chr_drv/chr_drv.a:
	cd kernel/chr_drv; make

lib/lib.a:
	(cd lib; make)

clean:
	-rm a.img System.map tools/system tools/systemtest tools/writeimg boot/bootSect boot/setup
	-rm init/*.o boot/*.o 
	(cd kernel;make clean)
	(cd lib;make clean)
	


