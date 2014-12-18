#include <string.h>

#include <linux/head.h>
#include <linux/sched.h>

#include <linux/kernel.h>
#include <asm/system.h>
#include <asm/segment.h>
#include <asm/io.h>

extern 	void *get_seg_byte(long 	seg, long addr);
extern  	long  get_tr(void);
extern  	long  get_fs(void);

static void die(char *str, long esp_ptr, long nr)
{
	// long 	*esp = (long *) esp_ptr;
	// int 		cur_task_id;

	// printk("%s: 	%04x\n", str, nr & 0xffff);


	// //此处，由于采用的平坦模式，调用中断处理程序， 是否会保存CS寄存器
	// //esp[1]		cs
	// //esp[0]		eip
	// //esp[2]		eflags
	// //esp[4]		ss
	// //esp[3] 	esp
	// printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n", esp[1], esp[0], esp[2], esp[4], esp[3]);

	// printk("fs: %04x\n", get_fs());

	// // current 定义在哪里？？？？
	// printk("base: %p, limit: %p\n", get_base(current->ldt[1]), get_limit(0x17));

	// // 如果为用户栈，还可打印其中的4个字节，在平坦模式下，如何判断是否为用户栈？?????????

	// str(cur_task_id);	//取当前运行的任务号  defined in include/linux/sched.h

	// printk("Pid: %d, process nr: %d\n", current->pid, 0xffff & cur_task_id);

	// for (int i = 0; i < count; ++i)
	// {
	// 	printk("%02x ", 0xff & get_seg_byte(esp[1], (i + (char*) esp[0]) ) );
	// }

	// printk("\n");
	printk("%s\n", str);
	do_exit(11);

}

void do_double_fault(long esp, long error_code)
{
	die("double fault", esp, error_code);
}

void do_general_protection(long esp, long error_code)
{
	die("general protection", esp, error_code);
}

void do_alignment_check(long esp, long error_code)
{
	die("alignment check", esp, error_code);
}

void do_divide_error(long esp, long error_code)
{
	die("divide error", esp, error_code);
}

void do_int3(long *esp, long error_code)
{
	// long 	tr;	
	// tr = get_tr();

	// printk("rax\trbx\trcx\trdx\n%16x\t%16x\t%16x\t%16x\n", )
	printk("do  int3\n");
}

void do_nmi(long esp, long error_code)
{
	die("nmi", esp, error_code);
}

void do_debug(long esp, long error_code)
{
	die("debug", esp, error_code);
}

void do_overflow(long esp, long error_code)
{
	die("overflow", esp, error_code);
}

void do_bounds(long esp, long error_code)
{
	die("bounds", esp, error_code);
}

void do_invalid_op(long esp, long error_code)
{
	die("invalid operand", esp, error_code);
}

void do_device_not_available(long esp, long error_code)
{
	die("device not available", esp, error_code);
}

void do_coprocessor_segment_overrun(long esp, long error_code)
{
	die("coprocessor segment overrun", esp, error_code);
}

void do_invalid_TSS(long esp, long error_code)
{
	die("invalid TSS", esp, error_code);
}

void do_segment_not_present(long esp, long error_code)
{
	die("segment not present", esp, error_code);
}

void do_stack_segment(long esp, long error_code)
{
	die("stack segment", esp, error_code);
}

void do_coprocessor_error(long esp, long error_code)
{
	// if (last_task_used_math != current)
	// {
	// 	return;
	// }
	die("coprocessor error", esp, error_code);
}

void do_reserved(long esp, long error_code)
{
	die("reserved (15, 17-47) error", esp, error_code);
}

void trap_init(void)
{

	//	set_trap_gate  	特权级为0
	//	set_system_gate 特权级为3

	set_trap_gate(0, &divide_error);
	set_trap_gate(1, &debug);
	set_trap_gate(2, &nmi);

	set_system_gate(3, &int3);
	set_system_gate(4, &overflow);
	set_system_gate(5, &bounds);

	set_trap_gate(6, &invalid_op);
	set_trap_gate(7, &device_not_available);
	set_trap_gate(8, &double_fault);
	set_trap_gate(9, &coprocessor_segment_overrun);
	set_trap_gate(10, &invalid_TSS);
	set_trap_gate(11, &segment_not_present);
	set_trap_gate(12, &stack_segment);
	set_trap_gate(13, &general_protection);
	set_trap_gate(14, &page_fault);
	set_trap_gate(15, &reserved);
	set_trap_gate(16, &coprocessor_error);
	set_trap_gate(17, &alignment_check);

	//int  15, 17-47 的陷阱门预先设置为reserved
	for (int i = 18; i < 48; ++i)
	{	
		set_trap_gate(i, &reserved);
	}

	set_trap_gate(45, &irq13);
	outb_p( inb_p(0x21) & 0xfb, 0x21);
	outb( inb_p(0xA1) & 0xdf, 0xA1);
	set_trap_gate(39, &parallel_interrupt);

}