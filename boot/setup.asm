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

; 检测EGA/VGA参数

; check for EGA/VGA and some config parameters

	mov	ah,	0x12
	mov	bl,	0x10
	int	0x10
	mov	[8],	ax
	mov	[10],	bx
	mov	[12],	cx
	mov	ax,	0x5019
	cmp	bl,	0x10
	je	novga
	; call	chsvga


;DH=光标行号，DL=光标列号
novga:	
	mov	[14],	ax
	mov	ah,	0x03	; read cursor pos
	xor	bh,	bh
	int	0x10		; save it in known place, con_init fetches
	mov	[0],	dx		; it from 0x90000.

; Get video-card data:
	
	mov	ah,	0x0f
	int	0x10
	mov	[4],	bx		; bh = display page
	mov	[6],	ax		; al = video mode, ah = window width
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


;--------------------------------------------------------------------------------------------------------
	

;------------------------------------------------------------------------------- 
debug_msg	db 	"debug here", 0

pgdt		dw 		23
		dw 		512 + gdt , 0x9    			;存放GDT的物理/线性地址, 要加上段基址

gdt 		dq 	0x0000000000000000
		dq	0x00cf98000000ffff
		dq 	0x00cf92000000ffff   			;存放临时gdt,共三个

pidt 		dw 	0
		dd 	0, 0
                          
bin_hex     	db '0123456789ABCDEF'		;put_hex_dword子过程用的查找表 


msg1		db	"Press <RETURN> to see SVGA-modes available or any other key to continue."
		db	0x0d, 0x0a, 0x0a, 0x00
msg2		db	"Mode:  COLSxROWS:"
		db	0x0d, 0x0a, 0x0a, 0x00
msg3		db	"Choose mode by pressing the corresponding number."
		db	0x0d, 0x0a, 0x00


		
idati		db	"761295520"
idcandt		db	0xa5
idgenoa		db	0x77, 0x00, 0x66, 0x99
idparadise	db	"VGA="

; Manufacturer:	  Numofmodes:	Mode:

moati		db	0x02,	0x23, 0x33 
moahead	db	0x05,	0x22, 0x23, 0x24, 0x2f, 0x34
mocandt	db	0x02,	0x60, 0x61
mocirrus	db	0x04,	0x1f, 0x20, 0x22, 0x31
moeverex	db	0x0a,	0x03, 0x04, 0x07, 0x08, 0x0a, 0x0b, 0x16, 0x18, 0x21, 0x40
mogenoa	db	0x0a,	0x58, 0x5a, 0x60, 0x61, 0x62, 0x63, 0x64, 0x72, 0x74, 0x78
moparadise	db	0x02,	0x55, 0x54
motrident	db	0x07,	0x50, 0x51, 0x52, 0x57, 0x58, 0x59, 0x5a
motseng	db	0x05,	0x26, 0x2a, 0x23, 0x24, 0x22
movideo7	db	0x06,	0x40, 0x43, 0x44, 0x41, 0x42, 0x45

;			msb = Cols lsb = Rows:

dscati		dw	0x8419, 0x842c
dscahead	dw	0x842c, 0x8419, 0x841c, 0xa032, 0x5042
dsccandt	dw	0x8419, 0x8432
dsccirrus	dw	0x8419, 0x842c, 0x841e, 0x6425
dsceverex	dw	0x5022, 0x503c, 0x642b, 0x644b, 0x8419, 0x842c, 0x501e, 0x641b, 0xa040, 0x841e
dscgenoa	dw	0x5020, 0x642a, 0x8419, 0x841d, 0x8420, 0x842c, 0x843c, 0x503c, 0x5042, 0x644b
dscparadise	dw	0x8419, 0x842b
dsctrident	dw	0x501e, 0x502b, 0x503c, 0x8419, 0x841e, 0x842b, 0x843c
dsctseng	dw	0x503c, 0x6428, 0x8419, 0x841c, 0x842c
dscvideo7	dw	0x502b, 0x503c, 0x643c, 0x8419, 0x842c, 0x841c
;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
end: