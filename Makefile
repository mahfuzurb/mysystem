a.out:lib/string.o main.o
	gcc -fno-builtin main.o lib/string.o

main.o:main.c include/string.h 
	gcc -fno-builtin -c main.c

lib/string.o:lib/string.asm 
	nasm -f elf64 lib/string.asm 

clean:
	rm a.out lib/string.o