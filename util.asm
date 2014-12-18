
section .text

global 	get_seg_byte, get_fs

;------------------------------------------------------------------------------------------
;function  	get_seg_byte(seg, addr)
get_seg_byte:    
    
	push 	fs
	mov  	fs, 		di
	mov 	al, 		fs:si 

	pop 	fs

    	ret


;------------------------------------------------------------------------------------------
get_fs:

	mov 	ax, 		fs
	ret


;------------------------------------------------------------------------------------------
get_tr:

	mov 	rax, 	tr
	ret

asm_iret:

	iret

