#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

int uni_mask=0;
int flag=0;

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64 sys_trace(void)
{
  int mask;
  argint(0,&mask);
  uni_mask=mask;
  flag=1;
  return mask;
}

void restore(){
  struct proc*p=myproc();

  p->trapframe_copy->kernel_trap = p->trapframe->kernel_trap;
  p->trapframe_copy->kernel_hartid = p->trapframe->kernel_hartid;
  p->trapframe_copy->kernel_sp = p->trapframe->kernel_sp;
  p->trapframe_copy->kernel_satp = p->trapframe->kernel_satp;
  *(p->trapframe) = *(p->trapframe_copy);
}

uint64 sys_sigreturn(void){
  restore();
  myproc()->is_sigalarm = 0;

  usertrapret();
  
  return 0;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc* p = myproc();
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_set_priority(void)
{
  int new_static_priority;

  argint(0, &new_static_priority);

  if (new_static_priority < 0)
    return -1;

  int proc_pid;
  argint(1, &proc_pid);

  if (proc_pid < 0)
    return -1;

  return set_priority(new_static_priority, proc_pid);
}
