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
	call	chsvga


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
chsvga:	
	cld
	push	ds
	push	cs
	pop	ds
	mov 	ax,	0xc000
	mov	es,	ax
	lea	si,	msg1
	call	prtstr
nokey:	
	in	al,	0x60
	cmp	al,	0x82
	jb	nokey
	cmp	al,	0xe0
	ja	nokey
	cmp	al,	0x9c
	je	svga
	mov	ax,	0x5019
	pop	ds
	ret
svga:	
	lea 	si,	idati		; Check ATI 'clues'
	mov	di,	0x31
	mov 	cx,	0x09
	repe
	cmpsb
	jne	noati
	lea	si,	dscati
	lea	di,	moati
	lea	cx,	selmod
	jmp	cx
noati:	mov	ax,#0x200f		! Check Ahead 'clues'
	mov	dx,#0x3ce
	out	dx,ax
	inc	dx
	in	al,dx
	cmp	al,#0x20
	je	isahed
	cmp	al,#0x21
	jne	noahed
isahed:	lea	si,dscahead
	lea	di,moahead
	lea	cx,selmod
	jmp	cx
noahed:	mov	dx,#0x3c3		! Check Chips & Tech. 'clues'
	in	al,dx
	or	al,#0x10
	out	dx,al
	mov	dx,#0x104		
	in	al,dx
	mov	bl,al
	mov	dx,#0x3c3
	in	al,dx
	and	al,#0xef
	out	dx,al
	cmp	bl,[idcandt]
	jne	nocant
	lea	si,dsccandt
	lea	di,mocandt
	lea	cx,selmod
	jmp	cx
nocant:	mov	dx,#0x3d4		! Check Cirrus 'clues'
	mov	al,#0x0c
	out	dx,al
	inc	dx
	in	al,dx
	mov	bl,al
	xor	al,al
	out	dx,al
	dec	dx
	mov	al,#0x1f
	out	dx,al
	inc	dx
	in	al,dx
	mov	bh,al
	xor	ah,ah
	shl	al,#4
	mov	cx,ax
	mov	al,bh
	shr	al,#4
	add	cx,ax
	shl	cx,#8
	add	cx,#6
	mov	ax,cx
	mov	dx,#0x3c4
	out	dx,ax
	inc	dx
	in	al,dx
	and	al,al
	jnz	nocirr
	mov	al,bh
	out	dx,al
	in	al,dx
	cmp	al,#0x01
	jne	nocirr
	call	rst3d4	
	lea	si,dsccirrus
	lea	di,mocirrus
	lea	cx,selmod
	jmp	cx
rst3d4:	mov	dx,#0x3d4
	mov	al,bl
	xor	ah,ah
	shl	ax,#8
	add	ax,#0x0c
	out	dx,ax
	ret	
nocirr:	call	rst3d4			! Check Everex 'clues'
	mov	ax,#0x7000
	xor	bx,bx
	int	0x10
	cmp	al,#0x70
	jne	noevrx
	shr	dx,#4
	cmp	dx,#0x678
	je	istrid
	cmp	dx,#0x236
	je	istrid
	lea	si,dsceverex
	lea	di,moeverex
	lea	cx,selmod
	jmp	cx
istrid:	lea	cx,ev2tri
	jmp	cx
noevrx:	lea	si,idgenoa		! Check Genoa 'clues'
	xor 	ax,ax
	seg es
	mov	al,[0x37]
	mov	di,ax
	mov	cx,#0x04
	dec	si
	dec	di
l1:	inc	si
	inc	di
	mov	al,(si)
	seg es
	and	al,(di)
	cmp	al,(si)
	loope 	l1
	cmp	cx,#0x00
	jne	nogen
	lea	si,dscgenoa
	lea	di,mogenoa
	lea	cx,selmod
	jmp	cx
nogen:	lea	si,idparadise		! Check Paradise 'clues'
	mov	di,#0x7d
	mov	cx,#0x04
	repe
	cmpsb
	jne	nopara
	lea	si,dscparadise
	lea	di,moparadise
	lea	cx,selmod
	jmp	cx
nopara:	mov	dx,#0x3c4		! Check Trident 'clues'
	mov	al,#0x0e
	out	dx,al
	inc	dx
	in	al,dx
	xchg	ah,al
	mov	al,#0x00
	out	dx,al
	in	al,dx
	xchg	al,ah
	mov	bl,al		! Strange thing ... in the book this wasn't
	and	bl,#0x02	! necessary but it worked on my card which
	jz	setb2		! is a trident. Without it the screen goes
	and	al,#0xfd	! blurred ...
	jmp	clrb2		!
setb2:	or	al,#0x02	!
clrb2:	out	dx,al
	and	ah,#0x0f
	cmp	ah,#0x02
	jne	notrid
ev2tri:	lea	si,dsctrident
	lea	di,motrident
	lea	cx,selmod
	jmp	cx
notrid:	mov	dx,#0x3cd		! Check Tseng 'clues'
	in	al,dx			! Could things be this simple ! :-)
	mov	bl,al
	mov	al,#0x55
	out	dx,al
	in	al,dx
	mov	ah,al
	mov	al,bl
	out	dx,al
	cmp	ah,#0x55
 	jne	notsen
	lea	si,dsctseng
	lea	di,motseng
	lea	cx,selmod
	jmp	cx
notsen:	mov	dx,#0x3cc		! Check Video7 'clues'
	in	al,dx
	mov	dx,#0x3b4
	and	al,#0x01
	jz	even7
	mov	dx,#0x3d4
even7:	mov	al,#0x0c
	out	dx,al
	inc	dx
	in	al,dx
	mov	bl,al
	mov	al,#0x55
	out	dx,al
	in	al,dx
	dec	dx
	mov	al,#0x1f
	out	dx,al
	inc	dx
	in	al,dx
	mov	bh,al
	dec	dx
	mov	al,#0x0c
	out	dx,al
	inc	dx
	mov	al,bl
	out	dx,al
	mov	al,#0x55
	xor	al,#0xea
	cmp	al,bh
	jne	novid7
	lea	si,dscvideo7
	lea	di,movideo7
selmod:	
	push	si
	lea	si,	msg2
	call	prtstr
	xor	cx,	cx
	mov	cl,	[di]
	pop	si
	push	si
	push	cx
tbl:	
	pop	bx
	push	bx
	mov	al,	bl
	sub	al,	cl
	call	dprnt
	call	spcing
	lodsw
	xchg	al,	ah
	call	dprnt
	xchg	ah,	al
	push	ax
	mov	al,	0x78
	call	prnt1
	pop	ax
	call	dprnt
	call	docr
	loop	tbl
	pop	cx
	call	docr
	lea	si,	msg3
	call	prtstr
	pop	si
	add	cl,	0x80
nonum:	
	in	al,	0x60	; Quick and dirty...
	cmp	al,	0x82
	jb	nonum
	cmp	al,	0x8b
	je	zero
	cmp	al,	cl
	ja	nonum
	jmp	nozero
zero:	sub	al,#0x0a
nozero:	sub	al,#0x80
	dec	al
	xor	ah,ah
	add	di,ax
	inc	di
	push	ax
	mov	al,(di)
	int 	0x10
	pop	ax
	shl	ax,#1
	add	si,ax
	lodsw
	pop	ds
	ret
novid7:	pop	ds	! Here could be code to support standard 80x50,80x30
	mov	ax,#0x5019	
	ret

! Routine that 'tabs' to next col.

spcing:	mov	al,#0x2e
	call	prnt1
	mov	al,#0x20
	call	prnt1	
	mov	al,#0x20
	call	prnt1	
	mov	al,#0x20
	call	prnt1	
	mov	al,#0x20
	call	prnt1
	ret	

;---------------------------------------------------------------------------------------------------------
; Routine to print asciiz-string at DS:SI

prtstr:	lodsb
	and	al,al
	jz	fin
	call	prnt1
	jmp	prtstr
fin:	ret

;---------------------------------------------------------------------------------------------------------
; Routine to print a decimal value on screen, the value to be
; printed is put in al (i.e 0-255). 

dprnt:	push	ax
	push	cx
	mov	ah,#0x00		
	mov	cl,#0x0a
	idiv	cl
	cmp	al,#0x09
	jbe	lt100
	call	dprnt
	jmp	skip10
lt100:	add	al,#0x30
	call	prnt1
skip10:	mov	al,ah
	add	al,#0x30
	call	prnt1	
	pop	cx
	pop	ax
	ret

;---------------------------------------------------------------------------------------------------------
; Part of above routine, this one just prints ascii al

prnt1:	push	ax
	push	cx
	mov	bh,	0x00
	mov	cx,	0x01
	mov	ah,	0x0e
	int	0x10
	pop	cx
	pop	ax
	ret

;---------------------------------------------------------------------------------------------------------
; Prints <CR> + <LF>

docr:	push	ax
	push	cx
	mov	bh,	0x00
	mov	ah,	0x0e
	mov	al,	0x0a
	mov	cx,	0x01
	int	0x10
	mov	al,	0x0d
	int	0x10
	pop	cx
	pop	ax
	ret	

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