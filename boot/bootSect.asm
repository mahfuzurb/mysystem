
;SETUP_ADDR        equ   0x7e00            ;初始化程序加载处的地址
SETUP_SECTOR      equ   1                     ;初始化程序起始的逻辑扇区号
BOOTSEG     EQU     0x07c0
INITSEG         EQU     0x9000
SETUPSEG    EQU     0x9020
SYSSEG          EQU     0x1000
SYS_SIZE_SECTOR		equ 	80 			   		;内核所占扇区数
SYS_POSITION		equ		5 					;内核位于硬盘的第6个逻辑扇区处
;===============================================================================
SECTION   mbr ;整体只有一个段


    mov     ax,     BOOTSEG
    mov     ds,     ax
    mov     ax,     INITSEG
    mov     es,     ax
    mov     cx,     512
    xor       si,       si
    xor       di,       di
    rep 
    movsb          	
    jmp     INITSEG : go 

go:
    mov   ax, cs
    mov   ds, ax            ;初始化数据段和代码段指向统一地方 即0
    mov   es, ax            ;令es也指向0,即整段内存

	mov 		dx, 	0xfef4   ;	随意值，只要避免被覆盖就行
	mov 		ss, 	ax
	mov 		sp, 	dx

    ;输出字符串'Loading system......'
    mov     ah, 0x03                        ;读取光标位置
    xor         bh, bh                          ;bh为页号
    int         0x10

    mov     cx, pgdt - msg
    mov     dx, 0x1004
    mov     bx, 0x0007
    mov     bp, msg
    mov     ax, 0x1301
    int         0x10



    ;读取setup程序
    mov 		ax, 	SETUPSEG
    mov 		ds, 	ax
    mov 		eax, 1
    mov 		ebx, 0x00
    call 		read_hard_disk_0              ;以下读取程序的起始部分（一个扇区）


	;读取内核
	mov 	ax, 	SYSSEG
	mov 	ds, 	ax
	mov 	eax, 	SYS_POSITION
	mov 	ebx, 	0x00

    	mov 	ecx, 	SYS_SIZE_SECTOR

readcore:
	call 	read_hard_disk_0           
	inc 	eax
	loop 	readcore   


    ;跳转到setup程序start执行

    jmp SETUPSEG: 0

    ;hlt


;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;从硬盘读取一个逻辑扇区
                                            ;EAX=逻辑扇区号
                                            ;DS:EBX=目标缓冲区地址
                                            ;返回：EBX=EBX+512
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

         ret

;-------------------------------------------------------------------------------
         msg               db    'Loading system......'
         pgdt             dw 0
                          dd gdt     ;存放GDT的物理/线性地址

        gdt               times 24  db  0   ;存放临时gdt,共三个

;-------------------------------------------------------------------------------
         times 510-($-$$) db 0
                          db 0x55,0xaa
