ENOSYS		EQU  	38
CS_OFF 		EQU 	0X24
OLDSS_OFF 	EQU 	0X30
;-------------------------------------------------------------------

global sys_call

extern NR_syscalls
; extern schedule
;-------------------------------------------------------------------
align 4
bad_sys_call:
	
	push 	-ENOSYS
	jmp 	ret_from_sys_call

;-------------------------------------------------------------------
; align 4
; reschedule:
	
; 	push 	ret_from_sys_call
; 	jmp 	schedule

;-------------------------------------------------------------------
align 4
sys_call:
	
	push 	ds 
	push 	es 
	push 	fs 
	push 	eax    	;eax = function number

	push 	edx
	push 	ecx 
	push 	ebx 

	mov 	edx, 	0x10
	mov 	ds, 	dx
	mov 	es, 	dx
	mov 	edx, 	0x17
	mov 	fs, 	dx

	cmp 	eax, 	NR_syscalls
	jae 	bad_sys_call

	call 	[sys_call_table + eax * 4]

	;now eax = the return value of sys_call 
	push  	eax 

; .2:
; 	mov 	eax, 	current
; 	cmp 	[state + eax], 	0
; 	jne 	reschedule

; 	cmp 	[counter + eax], 0
; 	je 		reschedule

ret_from_sys_call:

	; mov 	eax, 	current
	; cmp 	task, 	eax 
	; je 		.3

	cmp byte	[esp + CS_OFF], 	0x0f
	jne 	.3

	cmp byte	[esp + OLDSS_OFF], 	0x0f
	jne 	.3
	

	;signal  handle
	;..........

.3:
	popl eax
	popl ebx
	popl ecx
	popl edx
	addl esp, 	4 	; skip orig_eax
	pop fs
	pop es
	pop ds
	iret

;-------------------------------------------------------------------
align 4
coprocessor_error:

	push 	ds 
	push 	es 
	push 	fs 
	push 	-1  	; not system call 

	push 	edx
	push 	ecx 
	push 	ebx 
	push 	eax 

	mov 	edx, 	0x10
	mov 	ds, 	dx
	mov 	es, 	dx
	mov 	edx, 	0x17
	mov 	fs, 	dx

	push 	ret_from_sys_call
	jmp 	math_error

;-------------------------------------------------------------------
align 4
device_not_available:

	push 	ds 
	push 	es 
	push 	fs 
	push 	-1  	; not system call 

	push 	edx
	push 	ecx 
	push 	ebx 
	push 	eax 

	mov 	edx, 	0x10
	mov 	ds, 	dx
	mov 	es, 	dx
	mov 	edx, 	0x17
	mov 	fs, 	dx

	push 	ret_from_sys_call

	ret 