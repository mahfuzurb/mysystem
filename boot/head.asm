
SYS_ADDR		equ 	0x100000	
global 	gdt, idt, _start
extern 	stack_start, main
;===============================================================================
SECTION .text

	[bits 32]
pg_dir:

_start:

	;from now on, we are in the protected mode.
	;the first thing we should do is to reload all registers

	mov 	ax, 0x0010                    ;数据段选择子
	mov 	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov 	gs, ax
	lss 	esp, 	[stack_start]


	call 	setup_gdt
	call 	setup_idt

	;重新加载段寄存器，刷新它们的隐藏部分

	mov 	ax, 0x0010                    ;数据段选择子
	mov 	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov 	gs, ax
	lss 	esp, 	[stack_start]

;	sti 

    ;测试A20总线是否开启
	xor 	eax, eax 
test_a20:
	inc 	eax 
	mov 	[0x100000], eax 
	cmp 	[0x000000], eax 
	je 		test_a20
	

	jmp 	after_page_tables

;-------------------------------------------------------------------------------
setup_gdt:
	
	lgdt	[pgdt]
    
    ret

;-------------------------------------------------------------------------------
setup_idt:

	mov 	eax, ignore_int
	mov 	bx, 0x0008
	mov 	cx, 0x8e00

	call	make_gate_descriptor

	;put the dummy int_descriptor into idt 
	mov 	ecx, 256

	mov 	edi, idt

.install_idt:
	
	mov 	[edi], eax 
	mov 	[edi+4], edx 

	add 	edi, 8
	dec 	ecx

	jne		.install_idt


	lidt	[pidt]

	ret 



;-------------------------------------------------------------------------------
make_gate_descriptor:                       ;构造门的描述符（调用门等）
                                            ;输入：EAX=门代码在段内偏移地址
                                            ;       BX=门代码所在段的选择子 
                                            ;       CX=段类型及属性等（各属
                                            ;          性位都在原始位置）
                                            ;返回：EDX:EAX=完整的描述符
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;得到偏移地址高16位 
         or dx,cx                           ;组装属性部分到EDX
       
         and eax,0x0000ffff                 ;得到偏移地址低16位 
         shl ebx,16                          
         or eax,ebx                         ;组装段选择子部分
      
         pop ecx
         pop ebx
      
         ret        

;-------------------------------------------------------------------------------------
times		0x1000 - ($-$$)	db	0 			;page table 0
pg0:

times		0x1000 	db	0 			;page table 1
pg1:

times		0x1000 	db	0 			;page table 2
pg2:

times		0x1000 	db	0 			;page table 3
pg3:

times		0x1000 	db	0 			;page table 4


tmp_floppy_area:
	times 	1024 	db	0

;-------------------------------------------------------------------------------
ignore_int:

	
	push 	eax 
	push 	ecx 
	push 	edx 
	push 	ds 
	push 	es 
	push 	fs 

	mov 	eax, 	0x0010
	mov 	ds, 	eax 
	mov 	es, 	eax 
	mov 	fs, 	eax 
	
	push 	int_msg	

;	call 	printk

	pop 	eax 

	push 	fs 
	push 	es 
	push 	ds 
	push 	edx 
	push 	ecx 
	push 	eax 


	iret 


after_page_tables:
	;内核main函数参数入栈
	push 	0
	push 	0
	push 	0
	push 	L6
	push	main

	jmp 	setup_paging

L6: jmp 	L6


setup_paging:

	;5页内存清零

	mov 	ecx, 	1024 * 5
	xor 	eax, 	eax 
	mov 	edi, 	pg_dir

	cld

	rep
	stosb

	;设置页目录，此时一个5个页表
	mov dword	[pg_dir], 		pg0 + 7;
	mov dword	[pg_dir+4], 	pg1 + 7;
	mov dword	[pg_dir+8], 	pg2 + 7;
	mov dword	[pg_dir+12], 	pg3 + 7;

	mov 	edi, 	pg3 + 4092
	mov 	eax, 	0xfff007  				;16MB - 4096 + 7

	std
.1:
	stosd
	sub 	eax, 	0x1000
	jge 	.1

	
	;打开分页
	mov 	eax, 	pg_dir
	mov 	cr3, 	eax

	mov 	eax, cr0 	
	or 		eax, 0x80000000			
	mov 	cr0, eax


	ret 									;跳转到内核的main函数中去执行




;-------------------------------------------------------------------------------

;页目录从此处开始
; pg_dir: dd  0x0
; pg0 	dd 	0x1000
; pg1 	dd 	0x2000
; pg2 	dd 	0x3000
; pg3 	dd 	0x4000


pidt	dw 	256*8 - 1
		dd 	idt 

pgdt 	dw 	256*8 - 1
		dd 	gdt 



idt	times 256 dq 0

gdt	dq 	0x0000000000000000
		dq	0x00cf98000000ffff
		dq 	0x00cf92000000ffff
		dq 	0x0000000000000000

		times 	252 	dq 	0

int_msg db 	"Unknown interrupt\n"
