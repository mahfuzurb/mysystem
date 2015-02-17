ENOSYS		EQU  	38
SIG_CHLD	EQU		17

EAX_OFF		EQU 	0x00
EBX_OFF 	EQU 	0x04
ECX_OFF		EQU 	0x08
EDX_OFF		EQU 	0x0C
ORIG_EAX	EQU		0x10
FS_OFF		EQU		0x14
ES_OFF		EQU 	0x18
DS_OFF		EQU 	0x1C
EIP_OFF		EQU 	0x20
CS_OFF		EQU 	0x24
EFLAGS_OFF	EQU	 	0x28
OLDESP_OFF	EQU 	0x2C
OLDSS_OFF	EQU 	0x30
;-------------------------------------------------------------------

global sys_call, sys_execve, sys_fork, parallel_interrupt, device_not_available, coprocessor_error

extern NR_syscalls, sys_call_table
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
	pop eax
	pop ebx
	pop ecx
	pop edx
	add esp, 	4 	; skip orig_eax
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
	; jmp 	math_error

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

;-------------------------------------------------------------------
align 4
sys_execve:

	ret 

;-------------------------------------------------------------------
align 4
sys_fork:

	ret 

;-------------------------------------------------------------------
parallel_interrupt:

	push 	eax
	mov 	al, 	0x20
	out		0x20, 	al
	pop		eax

	iret