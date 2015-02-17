#include <linux/sched.h>

#define PAGE_SIZE 4096


long user_stack[PAGE_SIZE>>2];

struct
{
	long * a;
	short 	b;
} stack_start = { &user_stack[PAGE_SIZE>>2], 0x10 };


struct task_struct *current = NULL /*&(init_task.task)*/;
struct task_struct *last_task_used_math = NULL;

unsigned long startup_time=0;