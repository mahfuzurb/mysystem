 
#include <errno.h>

#include <linux/sched.h>
// #include <linux/tty.h>
#include <linux/kernel.h>
// #include <linux/config.h>
#include <asm/segment.h>
// #include <sys/times.h>
// #include <sys/utsname.h>
// #include <sys/param.h>
// #include <sys/resource.h>
// #include <string.h>

 int sys_setup(){}
 int sys_exit(){}

 int sys_read(){}
 int sys_write(){}
 int sys_open(){}
 int sys_close(){}
 int sys_waitpid(){}
 int sys_creat(){}
 int sys_link(){}
 int sys_unlink(){}

 int sys_chdir(){}
 int sys_time(){}
 int sys_mknod(){}
 int sys_chmod(){}
 int sys_chown(){}
 int sys_break(){}
 int sys_stat(){}
 int sys_lseek(){}
 int sys_getpid(){}
 int sys_mount(){}
 int sys_umount(){}
 int sys_setuid(){}
 int sys_getuid(){}
 int sys_stime(){}
 int sys_ptrace(){}
 int sys_alarm(){}
 int sys_fstat(){}
 int sys_pause(){}
 int sys_utime(){}
 int sys_stty(){}
 int sys_gtty(){}
 int sys_access(){}
 int sys_nice(){}
 int sys_ftime(){}
 int sys_sync(){}
 int sys_kill(){}
 int sys_rename(){}
 int sys_mkdir(){}
 int sys_rmdir(){}
 int sys_dup(){}
 int sys_pipe(){}
 int sys_times(){}
 int sys_prof(){}
 int sys_brk(){}
 int sys_setgid(){}
 int sys_getgid(){}
 int sys_signal(){}
 int sys_geteuid(){}
 int sys_getegid(){}
 int sys_acct(){}
 int sys_phys(){}
 int sys_lock(){}
 int sys_ioctl(){}
 int sys_fcntl(){}
 int sys_mpx(){}
 int sys_setpgid(){}
 int sys_ulimit(){}
 int sys_uname(){}
 int sys_umask(){}
 int sys_chroot(){}
 int sys_ustat(){}
 int sys_dup2(){}
 int sys_getppid(){}
 int sys_getpgrp(){}
 int sys_setsid(){}
 int sys_sigaction(){}
 int sys_sgetmask(){}
 int sys_ssetmask(){}
 int sys_setreuid(){}
 int sys_setregid(){}
 int sys_sigpending(){}
 int sys_sigsuspend(){}
 int sys_sethostname(){}
 int sys_setrlimit(){}
 int sys_getrlimit(){}
 int sys_getrusage(){}
 int sys_gettimeofday(){}
 int sys_settimeofday(){}
 int sys_getgroups(){}
 int sys_setgroups(){}
 int sys_select(){}
 int sys_symlink(){}
 int sys_lstat(){}
 int sys_readlink(){}
 int sys_uselib(){}


extern int sys_fork();
extern int sys_execve();


fn_ptr sys_call_table[] = { sys_setup, sys_exit, sys_fork, sys_read,
sys_write, sys_open, sys_close, sys_waitpid, sys_creat, sys_link,
sys_unlink, sys_execve, sys_chdir, sys_time, sys_mknod, sys_chmod,
sys_chown, sys_break, sys_stat, sys_lseek, sys_getpid, sys_mount,
sys_umount, sys_setuid, sys_getuid, sys_stime, sys_ptrace, sys_alarm,
sys_fstat, sys_pause, sys_utime, sys_stty, sys_gtty, sys_access,
sys_nice, sys_ftime, sys_sync, sys_kill, sys_rename, sys_mkdir,
sys_rmdir, sys_dup, sys_pipe, sys_times, sys_prof, sys_brk, sys_setgid,
sys_getgid, sys_signal, sys_geteuid, sys_getegid, sys_acct, sys_phys,
sys_lock, sys_ioctl, sys_fcntl, sys_mpx, sys_setpgid, sys_ulimit,
sys_uname, sys_umask, sys_chroot, sys_ustat, sys_dup2, sys_getppid,
sys_getpgrp, sys_setsid, sys_sigaction, sys_sgetmask, sys_ssetmask,
sys_setreuid,sys_setregid, sys_sigsuspend, sys_sigpending, sys_sethostname,
sys_setrlimit, sys_getrlimit, sys_getrusage, sys_gettimeofday, 
sys_settimeofday, sys_getgroups, sys_setgroups, sys_select, sys_symlink,
sys_lstat, sys_readlink, sys_uselib };

/* So we don't have to do any more manual updating.... */
int NR_syscalls = sizeof(sys_call_table)/sizeof(fn_ptr);