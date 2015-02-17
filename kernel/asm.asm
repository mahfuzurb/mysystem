extern coprocessor_error
global irq13

%macro interrupt_proc 1

	global 	%1
	extern do_%+%1

%1:
	push 	do_%+%1

%endmacro


	interrupt_proc	divide_error	;divide  error interrupt_proc
	jmp 	no_error_code


	interrupt_proc	debug		;debug 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	nmi		;int2 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	int3		;int3 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	overflow	;int4 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	bounds		;int5 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	invalid_op	;int6	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	double_fault	;int8	interrupt_proc
	jmp 	error_code


	interrupt_proc	coprocessor_segment_overrun	;int9 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	invalid_TSS	;int10	interrupt_proc
	jmp 	error_code


	interrupt_proc	segment_not_present			;int11	interrupt_proc
	jmp 	error_code


	interrupt_proc	stack_segment				;int12	interrupt_proc
	jmp 	error_code


	interrupt_proc	general_protection			;int13	interrupt_proc
	jmp 	error_code


	interrupt_proc	reserved	;int15 	interrupt_proc
	jmp 	no_error_code


	interrupt_proc	alignment_check			;int17	interrupt_proc
	jmp 	error_code

;------------------------------------------------------------------------------------------------------------------------------
;coprocessor   error    irq13

irq13:							;int45 	interrupt_proc
	push	eax
	xor		al, 	al
	out		0xf0, 	al

	mov 	al, 	0x20
	out 	0x20, 	al

	jmp 	.1
.1	jmp 	.2
.2	out 	0xa0, 	al
	pop	eax
	jmp 	coprocessor_error

;------------------------------------------------------------------------------------------------------------------------------

no_error_code:

	xchg	eax, 	[esp]		;the address of do_**_error -> eax, eax -> stack 

	push 	ebx
	push 	ecx
	push 	edx

	push 	edi
	push 	esi
	push 	ebp
	push 	ds
	push 	es
	push 	fs

	

	lea 	edx, 	[esp+44]

	mov 	edi, 	edx 			;the back address is the first argument

	mov 	esi, 	0			;the error code 0  is  the second argument 

	mov 	dx, 	0x10			; the data segment selector
	mov 	ds,		dx
	mov		es,		dx
	mov 	fs,		dx 

	mov 	ebx, 	eax
	call	ebx

	pop	fs
	pop	es
	pop	ds
	pop	ebp
	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	iret


;------------------------------------------------------------------------------------------------------------------------------
error_code:

	xchg	[esp+4],		eax
	xchg	[esp], 		ebx

	push 	ecx
	push 	edx

	push 	edi
	push 	esi
	push 	ebp
	push 	ds
	push 	es
	push 	fs

	mov		esi, 	eax   		;the second argument
	lea 	eax, 	[esp+44]
	mov 	edi, 	eax 		;the first argument


	mov 	dx, 	0x10			; the data segment selector
	mov 	ds,		dx
	mov		es,		dx
	mov 	fs,		dx 

	call	ebx

	pop	fs
	pop	es
	pop	ds
	pop	ebp
	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	iret