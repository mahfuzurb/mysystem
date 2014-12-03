
SYS_ADDR		equ 	0x100000	

;===============================================================================
SECTION 	head	vstart=SYS_ADDR

	[bits 32]

start:

    ;from now on, we are in the protected mode.
	;the first thing we should do is to reload all registers

	mov 	ax, 0x0010                    ;数据段选择子
    mov 	ds, ax
    mov 	es, ax
    mov 	fs, ax
    mov 	gs, ax
    mov 	ss, ax                         ;加载堆栈段(4GB)选择子
    mov 	esp,0x7000                     ;堆栈指针


    call 	setup_gdt
    call 	setup_idt

   

    sti 

    ;测试A20总线是否开启
	xor 	eax, eax 
test_a20:
	inc 	eax 
	mov 	[0x100000], eax 
	cmp 	[0x000000], eax 
	je 		test_a20
		

	;内核main函数参数入栈
	push 	0
	push 	0
	push 	0
	push 	L6
	push	_main

	jmp 	setup_paging

L6: jmp 	L6


_pg_dir:

	times		0x1000 - ($-$$)	db	0 			;一个页目录 占用4K内存,1024个页表占用4M内存

pg:
	times		0x400000	db		0


setup_paging:

	mov 	eax, pg + 7						;7为页表的后几位，即代表页表的权限
	mov 	edi, _pg_dir
	mov 	ecx, 1024 						;一共1024个页表

.set_pg_dir:

	mov 	[edi], eax
	add 	edi, 4
	add 	eax, 0x1000
	
	loop 	.set_pg_dir


	mov 	edi, pg 
	mov 	eax, 0x0000 + 7
	mov 	ecx, 1024 * 1024 				;整个4G内存一共1024*1024个页框

.set_pg_table:

	mov 	[edi], eax
	add 	edi, 4
	add 	eax, 0x1000

	loop 	.set_pg_table
	
;打开分页
	xor 	eax, eax
	mov 	eax, cr3
	or 		eax, 0x80000000			
	mov 	cr3, eax


	ret 									;跳转到内核的main函数中去执行



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

	mov 	edi, _idt

.install_idt:
	
	mov 	[edi], eax 
	mov 	[edi+4], edx 

	add 	edi, 8
	dec 	ecs 

	jne		.install_idt


	lidt	[pidt]

	ret 


;-------------------------------------------------------------------------------
ignore_int:

	push 	ebx 

	mov 	ebx, int_msg
	call 	put_string

	pop 	ebx 

	iret 

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
      
         retf         

;-------------------------------------------------------------------------------
pidt	dw 	256*8 - 1
		dd 	_idt 

pgdt 	dw 	256*8 - 1
		dd 	_gdt 



_idt	times 256 dq 0

_gdt	dp 	0x0000000000000000
		dq	0x00cf98000000ffff
		dq 	0x00cf92000000ffff
		dp 	0x0000000000000000

		times 	252 	dq 	0
