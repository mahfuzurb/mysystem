SETUP_ADDR      	equ   	0x000            	;初始化程序加载处的地址
CONFARG_SEG		equ		0x9000	          	;the configure argument of the machine
SYSSEG			equ 	0x1000		  
SYS_SIZE_SECTOR		equ 	80 			   		;内核所占扇区数
SYS_POSITION		equ		5 					;内核位于硬盘的第6个逻辑扇区处
;===============================================================================
SECTION  setup

;程序入口点
start:
        
	mov     ax,     CONFARG_SEG
	mov     ds,     ax

	; mov 	ss, ax
	; mov 	sp, 0x7dff      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load confarg 
    ; get the extend memory (KB) , put it in 0x90002
	mov     ah, 0x88 
	int     0x15

	mov  word   [2], ax 

; set Video Card 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	cli                                ;中断机制尚未工作


	mov 	ax, 	0x00
	cld 
do_move:
	mov 	es, 	ax
	add 	ax, 	0x1000
	cmp 	ax, 	0x9000
	jz 	end_move
	mov 	ds, 	ax
	xor 	di, 	di
	xor 	si, 	si 
	mov 	cx, 	0x8000
	rep
	movsw

	jmp 	do_move

end_move:

	mov 	ax, 	cs 
	mov 	ds, 	ax


	lgdt  	[pgdt]

	;cpu要求进入保护模式之前必须设置idt，这里暂时设置一个空表
	lidt	[pidt]

	;设置8259A中断控制器
	mov 	al,0x11
	out 	0x20,al                        ;ICW1：边沿触发/级联方式
	mov 	al,0x20
	out 	0x21,al                        ;ICW2:起始中断向量
	mov 	al,0x04
	out 	0x21,al                        ;ICW3:从片级联到IR2
	mov 	al,0x01
	out 	0x21,al                        ;ICW4:非总线缓冲，全嵌套，正常EOI
	mov 	al, 0xff 
	out 	0x21, al 				   		;mask off all interrupts for now

	mov 	al,0x11
	out 	0xa0,al                        ;ICW1：边沿触发/级联方式
	mov 	al,0x28
	out 	0xa1,al                        ;ICW2:起始中断向量
	mov 	al,0x02
	out 	0xa1,al                        ;ICW3:从片级联到IR2
	mov 	al,0x01
	out 	0xa1,al                        ;ICW4:非总线缓冲，全嵌套，正常EOI
	mov 	al, 0xff 
	out 	0xa1, al 				   		;mask off all interrupts for now



	;判断数学协处理器是否存在
	mov 	eax, cr0
	and 	eax, 0x80000011  ;only need PG, PE, ET bit

	or 	eax, 2 			 ;set MP bit
	mov 	cr0, eax 
	call 	check_x87



	in al,0x92                         ;南桥芯片内的端口
	or al,0000_0010B
	out 0x92,al                        ;打开A20

	; mov eax,cr0
	; or eax,1
	; mov cr0,eax                        ;设置PE位

	mov 	ax, 	0x0001
	lmsw 	ax
     
	;以下进入保护模式... ...
	;清流水线并串行化处理器

	jmp  	0x0008:0


;-------------------------------------------------------------------------------
check_x87:

	fninit
	fstsw	ax
	cmp 	al, 0
	je 		.check_over

	mov 	eax, cr0 
	xor 	eax, 6				;reset MP, set EM
	mov 	cr0, eax 

.check_over:

	ret 

;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;从硬盘读取一个逻辑扇区（平坦模型） 
                                            ;EAX=逻辑扇区号
                                            ;EBX=目标缓冲区线性地址
                                            ;返回：EBX=EBX+512
         cli
         
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;读取的扇区数

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA地址7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA地址15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA地址23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                        ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
;         sti
      
         ret                               


;------------------------------------------------------------------------------- 
debug_msg	db 	"debug here", 0

pgdt	dw 		23
	dw 		512 + gdt , 0x9    			;存放GDT的物理/线性地址, 要加上段基址

gdt 	dq 	0x0000000000000000
	dq	0x00cf98000000ffff
	dq 	0x00cf92000000ffff   			;存放临时gdt,共三个

pidt 	dw 	0
	dd 	0, 0
                          
bin_hex     db '0123456789ABCDEF'		;put_hex_dword子过程用的查找表 




;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
end: