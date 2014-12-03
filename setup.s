SETUP_ADDR      	equ   	0x7e00            	;初始化程序加载处的地址
CONFARG_ADDR		equ		0x9000	          	;the configure argument of the machine
SYS_ADDR			equ 	0x100000		  
SYS_SIZE_SECTOR		equ 	1 			   		;内核所占扇区数
SYS_POSITION		equ		5 					;内核位于硬盘的第10个逻辑扇区处
;===============================================================================
SECTION  setup  vstart=SETUP_ADDR

	length      dd end       ;程序总长度#00

    entry       dd start     ;入口点#04


;-------------------------------------------------------------------------------

;程序入口点
start:

	mov 	ax, cs 
	mov 	ds, ax
	mov 	ss, ax

	mov 	sp, 0x7dff      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load confarg 

; set Video Card 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    cli                                ;中断机制尚未工作

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

	or 		eax, 2 			 ;set MP bit
	mov 	cr0, eax 
	call 	check_x87


    lgdt  	[pgdt]

    ;cpu要求进入保护模式之前必须设置idt，这里暂时设置一个空表
    lidt	[pidt]


    in al,0x92                         ;南桥芯片内的端口
    or al,0000_0010B
    out 0x92,al                        ;打开A20

    mov eax,cr0
    or eax,1
    mov cr0,eax                        ;设置PE位

     

	;以下进入保护模式... ...
	;清流水线并串行化处理器
	
	jmp  dword 0x0008:flush

	[bits 32]

flush:

	mov 	ax, 0x0010                    ;数据段选择子
    mov 	ds, ax
    mov 	es, ax
    mov 	fs, ax
    mov 	gs, ax
    mov 	ss, ax                         ;加载堆栈段(4GB)选择子
    mov 	esp,0x7000                     ;堆栈指针


	;load system core

	mov 	eax, SYS_POSITION
	mov 	ebx, SYS_ADDR
	mov 	ecx, SYS_SIZE_SECTOR

.read_core:
	call 	read_hard_disk_0
	inc 	eax 
	loop 	.read_core

	mov 	ebx, debug_msg
	call 	put_string

	jmp  	0x0008:SYS_ADDR


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
         ;字符串显示例程（适用于平坦内存模型） 
put_string:                                 ;显示0终止的字符串并移动光标 
                                            ;输入：EBX=字符串的线性地址

         push ebx
         push ecx

         cli                                ;硬件操作期间，关中断

  .getc:
         mov cl,[ebx]
         or cl,cl                           ;检测串结束标志（0） 
         jz .exit                           ;显示完毕，返回 
         call put_char
         inc ebx
         jmp .getc

  .exit:

         sti                                ;硬件操作完毕，开放中断

         pop ecx
         pop ebx

         ret                               ;段间返回

;-------------------------------------------------------------------------------
put_char:                                   ;在当前光标处显示一个字符,并推进
                                            ;光标。仅用于段内调用 
                                            ;输入：CL=字符ASCII码 
         pushad

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;高字
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;低字
         mov bx,ax                          ;BX=代表光标位置的16位数
         and ebx,0x0000ffff                 ;准备使用32位寻址方式访问显存 
         
         cmp cl,0x0d                        ;回车符？
         jnz .put_0a                         
         
         mov ax,bx                          ;以下按回车符处理 
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;换行符？
         jnz .put_other
         add bx,80                          ;增加一行 
         jmp .roll_screen

  .put_other:                               ;正常显示字符
         shl bx,1
         mov [0x800b8000+ebx],cl            ;在光标位置处显示字符 

         ;以下将光标位置推进一个字符
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;光标超出屏幕？滚屏
         jl .set_cursor

         cld
         mov esi,0x800b80a0                 ;小心！32位模式下movsb/w/d 
         mov edi,0x800b8000                 ;使用的是esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;清除屏幕最底一行
         mov ecx,80                         ;32位程序应该使用ECX
  .cls:
         mov word [0x800b8000+ebx],0x0720
         add bx,2
         loop .cls

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al
         
         popad
         
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
      
         sti
      
         ret                               


;------------------------------------------------------------------------------- 
debug_msg	db 	"debug here", 0

pgdt        dw 		23
            dd 		gdt     			;存放GDT的物理/线性地址

gdt 		dq 	0x0000000000000000
			dq	0x00cf98000000ffff
			dq 	0x00cf92000000ffff   			;存放临时gdt,共三个

pidt 		dw 	0
			dd 	0, 0
                          
bin_hex     db '0123456789ABCDEF'		;put_hex_dword子过程用的查找表 




;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
end: