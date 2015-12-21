SECTIONS
{

	PROVIDE (__executable_start = 0x00000000); . = 0x00000000 + SIZEOF_HEADERS; 
	
    .text 0x000000:

    {
        *(.text)
    }

 
    .data :

    {
        *(.data)
    }

}