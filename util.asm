
section .text

global print  

print:    
    

    mov 	eax, [ebp+8]
    add 	eax, eax

    leave 

    ret