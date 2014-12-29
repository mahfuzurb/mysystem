

;  rdi,	rsi, rdx, rcx
section	.text
;-----------------------------------------------------------------------------------------------
global 	strcpy

strcpy:

	cld

	push 	rbp
	mov 	rbp, 	rsp

	sub 	rsp, 	8 * 4	; 	reserve 32B space 

	push	rdi 			;	store the pointer

.1:
	lodsb
	stosb

	test 	al, 	al
	jne 	.1

	pop 	rax				; 	get the pointer

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	strncpy

strncpy:

	cld

	push 	rbp
	mov 	rbp, 	rsp

	sub 	rsp, 	8 * 4	; 	reserve 32B space 

	mov 	rcx, 	rdx 	; 	3rd argument

	push	rdi 			;	store the pointer

.1:
	dec 	rcx 
	js 		.2
	lodsb
	stosb

	test 	al, 	al
	jne 	.1

	rep
	stosb

.2:
	pop 	rax				; 	get the pointer

	leave
	ret

;-----------------------------------------------------------------------------------------------
global strcat

strcat:

	push 	rbp
	mov 	rbp, 	rsp

	cld

	; push	rcx

	mov 	al, 	0
	mov 	rcx, 	0xffffffffffffffff

	repnz
	scasb

	dec		rdi
.1:
	lodsb
	stosb

	test	al, 	al

	jne		.1

	mov 	rax, 	rdi

	; pop 	rcx 

	leave
	ret

;-----------------------------------------------------------------------------------------------

global strncat

strncat:

	push 	rbp
	mov 	rbp, 	rsp

	; push	rcx

	cld

	mov 	al, 	0
	mov 	rcx, 	0xffffffffffffffff

	repnz
	scasb

	dec		rdi

	mov 	rcx, 	rdx  ;3rd argument
.1:
	lodsb
	stosb

	test	al, 	al

	je		.2

	loop 	.1

.2:
	mov 	rax, 	rdi

	; pop 	rcx 

	leave
	ret

; ;-----------------------------------------------------------------------------------------------
global 	strcmp

strcmp:

	cld
	push 	rbp
	mov 	rbp, 	rsp

.1:
	lodsb					;	es:esi -->  al
	scasb

	jne 	.2				;	if( al - [es:rdi])

	test 	al, 	al 
	jne 	.1

	xor 	rax, 	rax 	;  return 0
	jmp 	.3

.2:
	mov 	rax, 	1 		; 	return 1
	jl		.3
	neg 	rax 			; 	return -1

.3:
	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	strncmp

strncmp:

	cld
	push 	rbp
	mov 	rbp, 	rsp

	mov 	rcx, 	rdx

.1:
	dec 	rcx
	js 		.4
	lodsb					;	es:esi -->  al
	scasb

	jne 	.2				;	if( al - [es:rdi])

	test 	al, 	al 
	jne 	.1
.4:
	xor 	rax, 	rax 	;  return 0
	jmp 	.3

.2:
	mov 	rax, 	1 		; 	return 1
	jl		.3
	neg 	rax 			; 	return -1


.3:
	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	strchr 

strchr:

	cld

	push 	rbp
	mov 	rbp, 	rsp

	mov 	rax, 	rsi 
	xor 	ah, 	ah
	mov 	ah, 	al 		;	char --> ah

	mov 	rsi, 	rdi 
.1:
	lodsb

	cmp 	ah, 	al 		
	je 		.2
	test 	al, 	al
	jne		.1

	mov 	rsi, 	1 		;  return rsi - 1 = NULL(0)

.2:
	dec 	rsi 

	mov 	rax, 	rsi
.3:
	leave
	ret



;-----------------------------------------------------------------------------------------------
global 	strrchr 

strrchr:

	cld

	push 	rbp
	mov 	rbp, 	rsp

	mov 	rax, 	rsi 
	xor 	ah, 	ah
	mov 	ah, 	al 		;	char --> ah

	mov 	rsi, 	rdi 	; 	rsi = string address
	xor 	rdx, 	rdx 	; 	rdx = 0
.1:
	lodsb

	cmp 	ah, 	al 		
	jne		.2
	mov 	rdx, 	rsi
	dec 	rdx 			; 	rdx = rsi - 1
.2:
	test 	al, 	al
	jne		.1

	mov 	rax, 	rdx 

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	strcspn

strcspn:

	cld

	push 	rbp
	mov 	rbp, 		rsp

	sub 	rsp,			4 * 8	

	xchg 	rdi, 			rsi 					; rsi(1st arg), rdi(2nd arg)
	mov 	[rsp], 		rsi 
	mov 	[rsp + 8], 	rdi 

	mov 	al, 			0
	mov 	rcx, 		0xffffffffffffffff
	repne 	
	scasb
	dec 	rdi 
	mov 	rdx, 		rdi
	sub 	rdx, 		[rsp + 8]
	mov 	[rsp + 16], 	rdx 	; the length of 2nd arg

.1:
	mov 	rdi, 			[rsp + 8]
	lodsb

	test 	al, 			al
	je 		.2

	mov 	rcx, 		[rsp + 16]
	repne 
	scasb 
	jne 	.1

.2:
	dec 	rsi
	mov 	rdx, 		rsi
	sub 	rdx, 		[rsp]
	mov 	rax, 		rdx

	; mov 	rax, 	[rsp + 16]
	
	leave
	ret

;-----------------------------------------------------------------------------------------------

global 	strpbrk

strpbrk:

	cld

	push 	rbp
	mov 	rbp, 		rsp

	sub 	rsp,		4 * 8		
	xchg 	rdi, 			rsi 					; rsi(1st arg), rdi(2nd arg)

	mov 	[rsp], 		rdi

	xor 	al, 			al

	mov 	rcx, 		0xffffffffffffffff

	repne
	scasb

	not 	rcx
	dec 	rcx 								;get the length of 2nd arg
	mov 	rdx, 		rcx


.1:
	lodsb
	test		al, 			al
	je 		.2

	mov 	rdi, 			[rsp]
	mov 	rcx, 		rdx

	repne
	scasb
	jne 		.1

	dec 	rsi
	mov 	rax, 		rsi
	jmp		.3

.2:	xor 		rax, 		rax					; return NULL

.3:
	leave
	ret


;-----------------------------------------------------------------------------------------------

global 	strstr:

strstr:

	cld

	push 	rbp
	mov 	rbp, 		rsp

	push 	rbx 							; strore the value of rbx

	sub 	rsp,		4 * 8	

	xchg 	rdi, 		rsi 					; rsi(1st arg), rdi(2nd arg)
	mov 	[rsp], 		rdi

	xor 	al, 		al

	mov 	rcx, 		0xffffffffffffffff

	repne
	scasb

	not 	rcx
	dec 	rcx 								;get the length of 2nd arg
	mov 	rdx, 		rcx

.1:
	mov 	rbx, 		rsi
	mov 	rdi,			[rsp]
	mov 	rcx, 		rdx

	repe 
	cmpsb
	je 		.2

	xchg	rbx, 		rsi
	inc 		rsi 

	mov 	al, 			[rbx - 1]
	test 	al, 			al
	jne 		.1
	xor 	rax, 		rax
	jmp 	.3

.2:
	mov 	rax, 		rbx
.3:
	pop 	rbx
	leave
	ret

;-----------------------------------------------------------------------------------------------

global 	strlen

strlen:

	cld

	push 	rbp
	mov 	rbp, 		rsp


	xor 	al, 			al

	mov 	rcx, 		0xffffffffffffffff

	repne
	scasb

	not 	rcx
	dec 	rcx 

	mov 	rax, 		rcx

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	strtok, ___strtok

strtok:

	push 	rbp
	mov 	rbp, 		rsp

	sub 	rsp, 		4 * 8

	cld

	mov 	[rsp], 		rdi
	mov 	[rsp + 8], 	rsi

	test 	rdi, 		rdi 
	je 		.3
	;rdi != NULL
	mov 	[___strtok],rdi

	;compute the length of delimeter
	mov 	rcx, 		-1
	mov 	rdi, 		[rsp + 8]
	xor 	al, 		al
	repne
	scasb
	not 	rcx
	dec 	rcx

	; the length of delimeter == 0  ? 
	test 	rcx, 		rcx
	je 		.end

	; the length of delimeter  --->  rdx
	mov 	rdx, 		rcx  			 

.1:
	; search the delimeter in the source string
	mov 	rdi, 		[rsp]
	mov 	rsi, 		[rsp + 8]

	call	strstr

	test 	rax, 		rax		; return value == NULL ?
	je 		.2

	;subscribe the delimeter in the source string to \0
	xor 	al, 		al
	mov 	rdi, 		rax
	mov 	rcx, 		rdx
	stosb
	jmp 	.1
.2:
	
	jmp 	.end

.3:;source string == NULL
	xor 	al, 		al


.end

	mov 	rax, 		___strtok


	leave
	ret

___strtok	dq			0	
;-----------------------------------------------------------------------------------------------
global 	memcpy

memcpy:

	cld

	push 	rbp
	mov 	rbp, 		rsp

	mov 	rcx, 		rdx
	mov 	rax, 		rdi

	rep
	movsb 	

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	memmove

memmove:

	push 	rbp
	mov 	rbp, 		rsp

	sub 	rsp, 		4*8

	mov 	[rsp],  	rdi
	mov 	rcx, 		rdx

	cmp 	rsi, 		rdi						; compare rsi,  rdi
	jl 		.1 									; if rsi < rdi  jump  to table 1

	cld

	rep
	movsb

	jmp 	.2
.1:

	std


	sub 	rdx, 		1
	add 	rdi, 		rdx
	add 	rsi, 		rdx

.3:
	lodsb
	stosb
	loop 	.3

.2:
	mov 	rax, 		[rsp]

	cld						;why should this instructor must be used here?

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	memcmp

memcmp:

	push 	rbp
	mov 	rbp, 		rsp

	cld

	mov 	rcx, 		rdx
	xor 	rax,  		rax

	repe
	cmpsb
	je 		.1
	mov 	rax, 		1
	jl		.1
	neg 	rax

.1:
	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	memchr

memchr:

	push 	rbp
	mov 	rbp, 		rsp

	cld

	mov 	rax, 		rsi 	; 2nd -->> al
	mov 	rcx, 		rdx

	repne
	scasb

	je  	.1
	mov 	rdi, 		1 		; return rdi - 1 = NULL

.1:
	dec 	rdi

	mov 	rax, 		rdi

	leave
	ret

;-----------------------------------------------------------------------------------------------
global 	memset

memset:

	push 	rbp
	mov 	rbp, 		rsp

	cld

	mov 	rcx,		rdx
	mov 	rax, 		rsi 

	mov 	rdx, 		rdi

	rep
	stosb

	mov 	rax, 		rdx

	leave
	ret