%macro interrupt_proc 1

	global 	%1
	extern do_%+%1

%1:
	push 	do_%+%1

%endmacro


	interrupt_proc	divide_error
	jmp 	no_error_code


no_error_code:

	xchg	rax, [esp]		;the address of do_**_error -> eax, eax -> stack 





