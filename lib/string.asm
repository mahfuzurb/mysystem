

;  rdi,	rsi, rdx, rcx
section	.text

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

; ;--------------------------------------------------
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