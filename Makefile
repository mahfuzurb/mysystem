a.out:lib/string.o main.o
	gcc  main.o lib/string.o -g

main.o:main.c include/string.h 
	gcc  -fno-builtin -c main.c -g

lib/string.o:lib/string.asm 
	nasm -f elf64 lib/string.asm 

clean:
	rm a.out lib/string.o