

;  rdi,	rsi, rdx, rcx
section	.text
;--------------------------------------------------
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

;--------------------------------------------------
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

;--------------------------------------------------
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

;--------------------------------------------------

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

; ;--------------------------------------------------
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

;--------------------------------------------------
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

;--------------------------------------------------
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



;--------------------------------------------------
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

;--------------------------------------------------
global 	strcspn

strcspn:

	cld

	push 	rbp
	mov 	rbp, 	rsp

	sub 	rsp,	4 * 8	

	xchg 	rdi, 	rsi 	; rsi(1st arg), rdi(2nd arg)
	mov 	[rsp], 	rsi 
	mov 	[rsp + 8], 	rdi 

	mov 	al, 	0
	mov 	rcx, 	0xffffffffffffffff
	repne 	
	scasb
	dec 	rdi 
	mov 	rdx, 	rdi
	sub 	rdx, 	[rsp + 8]
	mov 	[rsp + 16], 	rdx 	; the length of 2nd arg

.1:
	mov 	rdi, 	[rsp + 8]
	lodsb

	test 	al, 	al
	je 		.2

	mov 	rcx, 	[rsp + 16]
	repne 
	scasb 
	jne 	.1

.2:
	dec 	rsi
	mov 	rdx, 	rsi
	sub 	rdx, 	[rsp]
	mov 	rax, 	rdx

	; mov 	rax, 	[rsp + 16]
	
	leave
	ret