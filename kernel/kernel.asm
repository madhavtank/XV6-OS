
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	b2013103          	ld	sp,-1248(sp) # 80009b20 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	b3e70713          	addi	a4,a4,-1218 # 80009b90 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	c4c78793          	addi	a5,a5,-948 # 80006cb0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb83e7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	0a878793          	addi	a5,a5,168 # 80001156 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	954080e7          	jalr	-1708(ra) # 80002a80 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	b4450513          	addi	a0,a0,-1212 # 80011cd0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	d18080e7          	jalr	-744(ra) # 80000eac <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	b3448493          	addi	s1,s1,-1228 # 80011cd0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	bc290913          	addi	s2,s2,-1086 # 80011d68 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	b5a080e7          	jalr	-1190(ra) # 80001d1e <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	6fe080e7          	jalr	1790(ra) # 800028ca <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	43c080e7          	jalr	1084(ra) # 80002616 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00003097          	auipc	ra,0x3
    8000021a:	814080e7          	jalr	-2028(ra) # 80002a2a <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00012517          	auipc	a0,0x12
    8000022e:	aa650513          	addi	a0,a0,-1370 # 80011cd0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	d2e080e7          	jalr	-722(ra) # 80000f60 <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	a9050513          	addi	a0,a0,-1392 # 80011cd0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	d18080e7          	jalr	-744(ra) # 80000f60 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00012717          	auipc	a4,0x12
    8000027c:	aef72823          	sw	a5,-1296(a4) # 80011d68 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00012517          	auipc	a0,0x12
    800002d6:	9fe50513          	addi	a0,a0,-1538 # 80011cd0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	bd2080e7          	jalr	-1070(ra) # 80000eac <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	7de080e7          	jalr	2014(ra) # 80002ad6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	9d050513          	addi	a0,a0,-1584 # 80011cd0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	c58080e7          	jalr	-936(ra) # 80000f60 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00012717          	auipc	a4,0x12
    80000328:	9ac70713          	addi	a4,a4,-1620 # 80011cd0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	98278793          	addi	a5,a5,-1662 # 80011cd0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00012797          	auipc	a5,0x12
    80000380:	9ec7a783          	lw	a5,-1556(a5) # 80011d68 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	94070713          	addi	a4,a4,-1728 # 80011cd0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	93048493          	addi	s1,s1,-1744 # 80011cd0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00012717          	auipc	a4,0x12
    800003e0:	8f470713          	addi	a4,a4,-1804 # 80011cd0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	96f72f23          	sw	a5,-1666(a4) # 80011d70 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00012797          	auipc	a5,0x12
    8000041c:	8b878793          	addi	a5,a5,-1864 # 80011cd0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00012797          	auipc	a5,0x12
    80000440:	92c7a823          	sw	a2,-1744(a5) # 80011d6c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	92450513          	addi	a0,a0,-1756 # 80011d68 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	22e080e7          	jalr	558(ra) # 8000267a <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00009597          	auipc	a1,0x9
    80000462:	bb258593          	addi	a1,a1,-1102 # 80009010 <etext+0x10>
    80000466:	00012517          	auipc	a0,0x12
    8000046a:	86a50513          	addi	a0,a0,-1942 # 80011cd0 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	9ae080e7          	jalr	-1618(ra) # 80000e1c <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00245797          	auipc	a5,0x245
    80000482:	e0278793          	addi	a5,a5,-510 # 80245280 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00009617          	auipc	a2,0x9
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80009040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00012797          	auipc	a5,0x12
    80000554:	8407a023          	sw	zero,-1984(a5) # 80011d90 <pr+0x18>
  printf("panic: ");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80009018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00009517          	auipc	a0,0x9
    80000576:	e8650513          	addi	a0,a0,-378 # 800093f8 <digits+0x3b8>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00009717          	auipc	a4,0x9
    80000588:	5af72e23          	sw	a5,1468(a4) # 80009b40 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00011d97          	auipc	s11,0x11
    800005c4:	7d0dad83          	lw	s11,2000(s11) # 80011d90 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00009b97          	auipc	s7,0x9
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80009040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00011517          	auipc	a0,0x11
    80000602:	77a50513          	addi	a0,a0,1914 # 80011d78 <pr>
    80000606:	00001097          	auipc	ra,0x1
    8000060a:	8a6080e7          	jalr	-1882(ra) # 80000eac <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00009517          	auipc	a0,0x9
    80000614:	a1850513          	addi	a0,a0,-1512 # 80009028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00009917          	auipc	s2,0x9
    80000714:	91090913          	addi	s2,s2,-1776 # 80009020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	61650513          	addi	a0,a0,1558 # 80011d78 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	7f6080e7          	jalr	2038(ra) # 80000f60 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00011497          	auipc	s1,0x11
    80000782:	5fa48493          	addi	s1,s1,1530 # 80011d78 <pr>
    80000786:	00009597          	auipc	a1,0x9
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80009038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	68c080e7          	jalr	1676(ra) # 80000e1c <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00009597          	auipc	a1,0x9
    800007da:	88258593          	addi	a1,a1,-1918 # 80009058 <digits+0x18>
    800007de:	00011517          	auipc	a0,0x11
    800007e2:	5ba50513          	addi	a0,a0,1466 # 80011d98 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	636080e7          	jalr	1590(ra) # 80000e1c <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	65e080e7          	jalr	1630(ra) # 80000e60 <push_off>

  if(panicked){
    8000080a:	00009797          	auipc	a5,0x9
    8000080e:	3367a783          	lw	a5,822(a5) # 80009b40 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	6cc080e7          	jalr	1740(ra) # 80000f00 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00009717          	auipc	a4,0x9
    8000084a:	30273703          	ld	a4,770(a4) # 80009b48 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3027b783          	ld	a5,770(a5) # 80009b50 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00011a17          	auipc	s4,0x11
    80000874:	528a0a13          	addi	s4,s4,1320 # 80011d98 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	2d048493          	addi	s1,s1,720 # 80009b48 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	2d098993          	addi	s3,s3,720 # 80009b50 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	dd4080e7          	jalr	-556(ra) # 8000267a <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00011517          	auipc	a0,0x11
    800008e6:	4b650513          	addi	a0,a0,1206 # 80011d98 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	5c2080e7          	jalr	1474(ra) # 80000eac <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	24e7a783          	lw	a5,590(a5) # 80009b40 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	2547b783          	ld	a5,596(a5) # 80009b50 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	24473703          	ld	a4,580(a4) # 80009b48 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	488a0a13          	addi	s4,s4,1160 # 80011d98 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	23048493          	addi	s1,s1,560 # 80009b48 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	23090913          	addi	s2,s2,560 # 80009b50 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	ce6080e7          	jalr	-794(ra) # 80002616 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	45248493          	addi	s1,s1,1106 # 80011d98 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	1ef73b23          	sd	a5,502(a4) # 80009b50 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	5f4080e7          	jalr	1524(ra) # 80000f60 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00011497          	auipc	s1,0x11
    800009d4:	3c848493          	addi	s1,s1,968 # 80011d98 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	4d2080e7          	jalr	1234(ra) # 80000eac <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	574080e7          	jalr	1396(ra) # 80000f60 <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <init_page_ref>:
struct {
  struct spinlock lock;
  int count[PGROUNDUP(PHYSTOP)>>12];
} page_ref;

void init_page_ref(){
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e406                	sd	ra,8(sp)
    80000a02:	e022                	sd	s0,0(sp)
    80000a04:	0800                	addi	s0,sp,16
  initlock(&page_ref.lock, "page_ref");
    80000a06:	00008597          	auipc	a1,0x8
    80000a0a:	65a58593          	addi	a1,a1,1626 # 80009060 <digits+0x20>
    80000a0e:	00011517          	auipc	a0,0x11
    80000a12:	3e250513          	addi	a0,a0,994 # 80011df0 <page_ref>
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	406080e7          	jalr	1030(ra) # 80000e1c <initlock>
  acquire(&page_ref.lock);
    80000a1e:	00011517          	auipc	a0,0x11
    80000a22:	3d250513          	addi	a0,a0,978 # 80011df0 <page_ref>
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	486080e7          	jalr	1158(ra) # 80000eac <acquire>
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000a2e:	00011797          	auipc	a5,0x11
    80000a32:	3da78793          	addi	a5,a5,986 # 80011e08 <page_ref+0x18>
    80000a36:	00231717          	auipc	a4,0x231
    80000a3a:	3d270713          	addi	a4,a4,978 # 80231e08 <pid_lock>
    page_ref.count[i]=0;
    80000a3e:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000a42:	0791                	addi	a5,a5,4
    80000a44:	fee79de3          	bne	a5,a4,80000a3e <init_page_ref+0x40>
  release(&page_ref.lock);
    80000a48:	00011517          	auipc	a0,0x11
    80000a4c:	3a850513          	addi	a0,a0,936 # 80011df0 <page_ref>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	510080e7          	jalr	1296(ra) # 80000f60 <release>
}
    80000a58:	60a2                	ld	ra,8(sp)
    80000a5a:	6402                	ld	s0,0(sp)
    80000a5c:	0141                	addi	sp,sp,16
    80000a5e:	8082                	ret

0000000080000a60 <dec_page_ref>:


void dec_page_ref(void*pa){
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	1000                	addi	s0,sp,32
    80000a6a:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000a6c:	00011517          	auipc	a0,0x11
    80000a70:	38450513          	addi	a0,a0,900 # 80011df0 <page_ref>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	438080e7          	jalr	1080(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000a7c:	00c4d793          	srli	a5,s1,0xc
    80000a80:	00478713          	addi	a4,a5,4
    80000a84:	00271693          	slli	a3,a4,0x2
    80000a88:	00011717          	auipc	a4,0x11
    80000a8c:	36870713          	addi	a4,a4,872 # 80011df0 <page_ref>
    80000a90:	9736                	add	a4,a4,a3
    80000a92:	4718                	lw	a4,8(a4)
    80000a94:	02e05463          	blez	a4,80000abc <dec_page_ref+0x5c>
    panic("dec_page_ref");
  }
  page_ref.count[(uint64)pa>>12]-=1;
    80000a98:	00011517          	auipc	a0,0x11
    80000a9c:	35850513          	addi	a0,a0,856 # 80011df0 <page_ref>
    80000aa0:	0791                	addi	a5,a5,4
    80000aa2:	078a                	slli	a5,a5,0x2
    80000aa4:	97aa                	add	a5,a5,a0
    80000aa6:	377d                	addiw	a4,a4,-1
    80000aa8:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	4b6080e7          	jalr	1206(ra) # 80000f60 <release>
}
    80000ab2:	60e2                	ld	ra,24(sp)
    80000ab4:	6442                	ld	s0,16(sp)
    80000ab6:	64a2                	ld	s1,8(sp)
    80000ab8:	6105                	addi	sp,sp,32
    80000aba:	8082                	ret
    panic("dec_page_ref");
    80000abc:	00008517          	auipc	a0,0x8
    80000ac0:	5b450513          	addi	a0,a0,1460 # 80009070 <digits+0x30>
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	a80080e7          	jalr	-1408(ra) # 80000544 <panic>

0000000080000acc <inc_page_ref>:

void inc_page_ref(void*pa){
    80000acc:	1101                	addi	sp,sp,-32
    80000ace:	ec06                	sd	ra,24(sp)
    80000ad0:	e822                	sd	s0,16(sp)
    80000ad2:	e426                	sd	s1,8(sp)
    80000ad4:	1000                	addi	s0,sp,32
    80000ad6:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000ad8:	00011517          	auipc	a0,0x11
    80000adc:	31850513          	addi	a0,a0,792 # 80011df0 <page_ref>
    80000ae0:	00000097          	auipc	ra,0x0
    80000ae4:	3cc080e7          	jalr	972(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<0){
    80000ae8:	00c4d793          	srli	a5,s1,0xc
    80000aec:	00478713          	addi	a4,a5,4
    80000af0:	00271693          	slli	a3,a4,0x2
    80000af4:	00011717          	auipc	a4,0x11
    80000af8:	2fc70713          	addi	a4,a4,764 # 80011df0 <page_ref>
    80000afc:	9736                	add	a4,a4,a3
    80000afe:	4718                	lw	a4,8(a4)
    80000b00:	02074463          	bltz	a4,80000b28 <inc_page_ref+0x5c>
    panic("inc_page_ref");
  }
  page_ref.count[(uint64)pa>>12]+=1;
    80000b04:	00011517          	auipc	a0,0x11
    80000b08:	2ec50513          	addi	a0,a0,748 # 80011df0 <page_ref>
    80000b0c:	0791                	addi	a5,a5,4
    80000b0e:	078a                	slli	a5,a5,0x2
    80000b10:	97aa                	add	a5,a5,a0
    80000b12:	2705                	addiw	a4,a4,1
    80000b14:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	44a080e7          	jalr	1098(ra) # 80000f60 <release>
}
    80000b1e:	60e2                	ld	ra,24(sp)
    80000b20:	6442                	ld	s0,16(sp)
    80000b22:	64a2                	ld	s1,8(sp)
    80000b24:	6105                	addi	sp,sp,32
    80000b26:	8082                	ret
    panic("inc_page_ref");
    80000b28:	00008517          	auipc	a0,0x8
    80000b2c:	55850513          	addi	a0,a0,1368 # 80009080 <digits+0x40>
    80000b30:	00000097          	auipc	ra,0x0
    80000b34:	a14080e7          	jalr	-1516(ra) # 80000544 <panic>

0000000080000b38 <get_page_ref>:

int get_page_ref(void*pa){
    80000b38:	1101                	addi	sp,sp,-32
    80000b3a:	ec06                	sd	ra,24(sp)
    80000b3c:	e822                	sd	s0,16(sp)
    80000b3e:	e426                	sd	s1,8(sp)
    80000b40:	1000                	addi	s0,sp,32
    80000b42:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000b44:	00011517          	auipc	a0,0x11
    80000b48:	2ac50513          	addi	a0,a0,684 # 80011df0 <page_ref>
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	360080e7          	jalr	864(ra) # 80000eac <acquire>
  int res = page_ref.count[(uint64)pa>>12];
    80000b54:	80b1                	srli	s1,s1,0xc
    80000b56:	0491                	addi	s1,s1,4
    80000b58:	048a                	slli	s1,s1,0x2
    80000b5a:	00011797          	auipc	a5,0x11
    80000b5e:	29678793          	addi	a5,a5,662 # 80011df0 <page_ref>
    80000b62:	94be                	add	s1,s1,a5
    80000b64:	4484                	lw	s1,8(s1)
  if(page_ref.count[(uint64)pa>>12]<0){
    80000b66:	0204c063          	bltz	s1,80000b86 <get_page_ref+0x4e>
    panic("get_page_ref");
  }
  release(&page_ref.lock);
    80000b6a:	00011517          	auipc	a0,0x11
    80000b6e:	28650513          	addi	a0,a0,646 # 80011df0 <page_ref>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	3ee080e7          	jalr	1006(ra) # 80000f60 <release>
  return res;
}
    80000b7a:	8526                	mv	a0,s1
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret
    panic("get_page_ref");
    80000b86:	00008517          	auipc	a0,0x8
    80000b8a:	50a50513          	addi	a0,a0,1290 # 80009090 <digits+0x50>
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	9b6080e7          	jalr	-1610(ra) # 80000544 <panic>

0000000080000b96 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b96:	1101                	addi	sp,sp,-32
    80000b98:	ec06                	sd	ra,24(sp)
    80000b9a:	e822                	sd	s0,16(sp)
    80000b9c:	e426                	sd	s1,8(sp)
    80000b9e:	e04a                	sd	s2,0(sp)
    80000ba0:	1000                	addi	s0,sp,32
    80000ba2:	84aa                	mv	s1,a0
  struct run *r;

  // if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
  //   panic("kfree");

    acquire(&page_ref.lock);
    80000ba4:	00011517          	auipc	a0,0x11
    80000ba8:	24c50513          	addi	a0,a0,588 # 80011df0 <page_ref>
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	300080e7          	jalr	768(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000bb4:	00c4d793          	srli	a5,s1,0xc
    80000bb8:	00478713          	addi	a4,a5,4
    80000bbc:	00271693          	slli	a3,a4,0x2
    80000bc0:	00011717          	auipc	a4,0x11
    80000bc4:	23070713          	addi	a4,a4,560 # 80011df0 <page_ref>
    80000bc8:	9736                	add	a4,a4,a3
    80000bca:	4718                	lw	a4,8(a4)
    80000bcc:	06e05763          	blez	a4,80000c3a <kfree+0xa4>
    panic("dec_page_ref");
  }
  page_ref.count[(uint64)pa>>12]-=1;
    80000bd0:	377d                	addiw	a4,a4,-1
    80000bd2:	0007061b          	sext.w	a2,a4
    80000bd6:	0791                	addi	a5,a5,4
    80000bd8:	078a                	slli	a5,a5,0x2
    80000bda:	00011697          	auipc	a3,0x11
    80000bde:	21668693          	addi	a3,a3,534 # 80011df0 <page_ref>
    80000be2:	97b6                	add	a5,a5,a3
    80000be4:	c798                	sw	a4,8(a5)
  if(page_ref.count[(uint64)pa>>12]>0){
    80000be6:	06c04263          	bgtz	a2,80000c4a <kfree+0xb4>
    release(&page_ref.lock);
    return;
  }
  release(&page_ref.lock);
    80000bea:	00011517          	auipc	a0,0x11
    80000bee:	20650513          	addi	a0,a0,518 # 80011df0 <page_ref>
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	36e080e7          	jalr	878(ra) # 80000f60 <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000bfa:	6605                	lui	a2,0x1
    80000bfc:	4585                	li	a1,1
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	3a8080e7          	jalr	936(ra) # 80000fa8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000c08:	00011917          	auipc	s2,0x11
    80000c0c:	1c890913          	addi	s2,s2,456 # 80011dd0 <kmem>
    80000c10:	854a                	mv	a0,s2
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	29a080e7          	jalr	666(ra) # 80000eac <acquire>
  r->next = kmem.freelist;
    80000c1a:	01893783          	ld	a5,24(s2)
    80000c1e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000c20:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000c24:	854a                	mv	a0,s2
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	33a080e7          	jalr	826(ra) # 80000f60 <release>
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6902                	ld	s2,0(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret
    panic("dec_page_ref");
    80000c3a:	00008517          	auipc	a0,0x8
    80000c3e:	43650513          	addi	a0,a0,1078 # 80009070 <digits+0x30>
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	902080e7          	jalr	-1790(ra) # 80000544 <panic>
    release(&page_ref.lock);
    80000c4a:	8536                	mv	a0,a3
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	314080e7          	jalr	788(ra) # 80000f60 <release>
    return;
    80000c54:	bfe9                	j	80000c2e <kfree+0x98>

0000000080000c56 <freerange>:
{
    80000c56:	7139                	addi	sp,sp,-64
    80000c58:	fc06                	sd	ra,56(sp)
    80000c5a:	f822                	sd	s0,48(sp)
    80000c5c:	f426                	sd	s1,40(sp)
    80000c5e:	f04a                	sd	s2,32(sp)
    80000c60:	ec4e                	sd	s3,24(sp)
    80000c62:	e852                	sd	s4,16(sp)
    80000c64:	e456                	sd	s5,8(sp)
    80000c66:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000c68:	6785                	lui	a5,0x1
    80000c6a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000c6e:	94aa                	add	s1,s1,a0
    80000c70:	757d                	lui	a0,0xfffff
    80000c72:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c74:	94be                	add	s1,s1,a5
    80000c76:	0295e463          	bltu	a1,s1,80000c9e <freerange+0x48>
    80000c7a:	89ae                	mv	s3,a1
    80000c7c:	7afd                	lui	s5,0xfffff
    80000c7e:	6a05                	lui	s4,0x1
    80000c80:	01548933          	add	s2,s1,s5
   inc_page_ref(p);
    80000c84:	854a                	mv	a0,s2
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	e46080e7          	jalr	-442(ra) # 80000acc <inc_page_ref>
     kfree(p);
    80000c8e:	854a                	mv	a0,s2
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	f06080e7          	jalr	-250(ra) # 80000b96 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c98:	94d2                	add	s1,s1,s4
    80000c9a:	fe99f3e3          	bgeu	s3,s1,80000c80 <freerange+0x2a>
}
    80000c9e:	70e2                	ld	ra,56(sp)
    80000ca0:	7442                	ld	s0,48(sp)
    80000ca2:	74a2                	ld	s1,40(sp)
    80000ca4:	7902                	ld	s2,32(sp)
    80000ca6:	69e2                	ld	s3,24(sp)
    80000ca8:	6a42                	ld	s4,16(sp)
    80000caa:	6aa2                	ld	s5,8(sp)
    80000cac:	6121                	addi	sp,sp,64
    80000cae:	8082                	ret

0000000080000cb0 <kinit>:
{
    80000cb0:	1141                	addi	sp,sp,-16
    80000cb2:	e406                	sd	ra,8(sp)
    80000cb4:	e022                	sd	s0,0(sp)
    80000cb6:	0800                	addi	s0,sp,16
  init_page_ref();
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	d46080e7          	jalr	-698(ra) # 800009fe <init_page_ref>
  initlock(&kmem.lock, "kmem");
    80000cc0:	00008597          	auipc	a1,0x8
    80000cc4:	3e058593          	addi	a1,a1,992 # 800090a0 <digits+0x60>
    80000cc8:	00011517          	auipc	a0,0x11
    80000ccc:	10850513          	addi	a0,a0,264 # 80011dd0 <kmem>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	14c080e7          	jalr	332(ra) # 80000e1c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000cd8:	45c5                	li	a1,17
    80000cda:	05ee                	slli	a1,a1,0x1b
    80000cdc:	00245517          	auipc	a0,0x245
    80000ce0:	73c50513          	addi	a0,a0,1852 # 80246418 <end>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	f72080e7          	jalr	-142(ra) # 80000c56 <freerange>
}
    80000cec:	60a2                	ld	ra,8(sp)
    80000cee:	6402                	ld	s0,0(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000cf4:	1101                	addi	sp,sp,-32
    80000cf6:	ec06                	sd	ra,24(sp)
    80000cf8:	e822                	sd	s0,16(sp)
    80000cfa:	e426                	sd	s1,8(sp)
    80000cfc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000cfe:	00011497          	auipc	s1,0x11
    80000d02:	0d248493          	addi	s1,s1,210 # 80011dd0 <kmem>
    80000d06:	8526                	mv	a0,s1
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	1a4080e7          	jalr	420(ra) # 80000eac <acquire>
  r = kmem.freelist;
    80000d10:	6c84                	ld	s1,24(s1)
  if(r)
    80000d12:	cc8d                	beqz	s1,80000d4c <kalloc+0x58>
    kmem.freelist = r->next;
    80000d14:	609c                	ld	a5,0(s1)
    80000d16:	00011517          	auipc	a0,0x11
    80000d1a:	0ba50513          	addi	a0,a0,186 # 80011dd0 <kmem>
    80000d1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	240080e7          	jalr	576(ra) # 80000f60 <release>

  // if(r)
  //   memset((char*)r, 5, PGSIZE); // fill with junk
   if(r){
     memset((char*)r, 5, PGSIZE); // fill with junk
    80000d28:	6605                	lui	a2,0x1
    80000d2a:	4595                	li	a1,5
    80000d2c:	8526                	mv	a0,s1
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	27a080e7          	jalr	634(ra) # 80000fa8 <memset>
    inc_page_ref((void*)r);
    80000d36:	8526                	mv	a0,s1
    80000d38:	00000097          	auipc	ra,0x0
    80000d3c:	d94080e7          	jalr	-620(ra) # 80000acc <inc_page_ref>
  }
  return (void*)r;
}
    80000d40:	8526                	mv	a0,s1
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	addi	sp,sp,32
    80000d4a:	8082                	ret
  release(&kmem.lock);
    80000d4c:	00011517          	auipc	a0,0x11
    80000d50:	08450513          	addi	a0,a0,132 # 80011dd0 <kmem>
    80000d54:	00000097          	auipc	ra,0x0
    80000d58:	20c080e7          	jalr	524(ra) # 80000f60 <release>
   if(r){
    80000d5c:	b7d5                	j	80000d40 <kalloc+0x4c>

0000000080000d5e <page_fault_handler>:


int page_fault_handler(void*va,pagetable_t pagetable){
    80000d5e:	7179                	addi	sp,sp,-48
    80000d60:	f406                	sd	ra,40(sp)
    80000d62:	f022                	sd	s0,32(sp)
    80000d64:	ec26                	sd	s1,24(sp)
    80000d66:	e84a                	sd	s2,16(sp)
    80000d68:	e44e                	sd	s3,8(sp)
    80000d6a:	e052                	sd	s4,0(sp)
    80000d6c:	1800                	addi	s0,sp,48
    80000d6e:	84aa                	mv	s1,a0
    80000d70:	892e                	mv	s2,a1
 
  struct proc* p = myproc();
    80000d72:	00001097          	auipc	ra,0x1
    80000d76:	fac080e7          	jalr	-84(ra) # 80001d1e <myproc>
  if((uint64)va>=MAXVA||((uint64)va>=PGROUNDDOWN(p->trapframe->sp)-PGSIZE&&(uint64)va<=PGROUNDDOWN(p->trapframe->sp))){
    80000d7a:	57fd                	li	a5,-1
    80000d7c:	83e9                	srli	a5,a5,0x1a
    80000d7e:	0897e563          	bltu	a5,s1,80000e08 <page_fault_handler+0xaa>
    80000d82:	7138                	ld	a4,96(a0)
    80000d84:	77fd                	lui	a5,0xfffff
    80000d86:	7b18                	ld	a4,48(a4)
    80000d88:	8f7d                	and	a4,a4,a5
    80000d8a:	97ba                	add	a5,a5,a4
    80000d8c:	00f4e463          	bltu	s1,a5,80000d94 <page_fault_handler+0x36>
    80000d90:	06977e63          	bgeu	a4,s1,80000e0c <page_fault_handler+0xae>

  pte_t *pte;
  uint64 pa;
  uint flags;
  va = (void*)PGROUNDDOWN((uint64)va);
  pte = walk(pagetable,(uint64)va,0);
    80000d94:	4601                	li	a2,0
    80000d96:	75fd                	lui	a1,0xfffff
    80000d98:	8de5                	and	a1,a1,s1
    80000d9a:	854a                	mv	a0,s2
    80000d9c:	00000097          	auipc	ra,0x0
    80000da0:	4f8080e7          	jalr	1272(ra) # 80001294 <walk>
    80000da4:	892a                	mv	s2,a0
  if(pte == 0){
    80000da6:	c52d                	beqz	a0,80000e10 <page_fault_handler+0xb2>
    return -1;
  }
  pa = PTE2PA(*pte);
    80000da8:	611c                	ld	a5,0(a0)
    80000daa:	00a7d993          	srli	s3,a5,0xa
    80000dae:	09b2                	slli	s3,s3,0xc
  if(pa == 0){
    80000db0:	06098263          	beqz	s3,80000e14 <page_fault_handler+0xb6>
    return -1;
  }
  flags = PTE_FLAGS(*pte);
    80000db4:	2781                	sext.w	a5,a5
  if(flags&PTE_C){
    80000db6:	0207f713          	andi	a4,a5,32
    memmove(mem,(void*)pa,PGSIZE); 
    *pte = PA2PTE(mem)|flags;
    kfree((void*)pa);
    return 0;
  }
  return 0;
    80000dba:	4501                	li	a0,0
  if(flags&PTE_C){
    80000dbc:	eb09                	bnez	a4,80000dce <page_fault_handler+0x70>
    80000dbe:	70a2                	ld	ra,40(sp)
    80000dc0:	7402                	ld	s0,32(sp)
    80000dc2:	64e2                	ld	s1,24(sp)
    80000dc4:	6942                	ld	s2,16(sp)
    80000dc6:	69a2                	ld	s3,8(sp)
    80000dc8:	6a02                	ld	s4,0(sp)
    80000dca:	6145                	addi	sp,sp,48
    80000dcc:	8082                	ret
    flags = (flags|PTE_W)&(~PTE_C);
    80000dce:	3df7f793          	andi	a5,a5,991
    80000dd2:	0047e493          	ori	s1,a5,4
    mem = kalloc();
    80000dd6:	00000097          	auipc	ra,0x0
    80000dda:	f1e080e7          	jalr	-226(ra) # 80000cf4 <kalloc>
    80000dde:	8a2a                	mv	s4,a0
    if(mem==0){
    80000de0:	cd05                	beqz	a0,80000e18 <page_fault_handler+0xba>
    memmove(mem,(void*)pa,PGSIZE); 
    80000de2:	6605                	lui	a2,0x1
    80000de4:	85ce                	mv	a1,s3
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	222080e7          	jalr	546(ra) # 80001008 <memmove>
    *pte = PA2PTE(mem)|flags;
    80000dee:	00ca5793          	srli	a5,s4,0xc
    80000df2:	07aa                	slli	a5,a5,0xa
    80000df4:	8fc5                	or	a5,a5,s1
    80000df6:	00f93023          	sd	a5,0(s2)
    kfree((void*)pa);
    80000dfa:	854e                	mv	a0,s3
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	d9a080e7          	jalr	-614(ra) # 80000b96 <kfree>
    return 0;
    80000e04:	4501                	li	a0,0
    80000e06:	bf65                	j	80000dbe <page_fault_handler+0x60>
    return -2;
    80000e08:	5579                	li	a0,-2
    80000e0a:	bf55                	j	80000dbe <page_fault_handler+0x60>
    80000e0c:	5579                	li	a0,-2
    80000e0e:	bf45                	j	80000dbe <page_fault_handler+0x60>
    return -1;
    80000e10:	557d                	li	a0,-1
    80000e12:	b775                	j	80000dbe <page_fault_handler+0x60>
    return -1;
    80000e14:	557d                	li	a0,-1
    80000e16:	b765                	j	80000dbe <page_fault_handler+0x60>
      return -1;
    80000e18:	557d                	li	a0,-1
    80000e1a:	b755                	j	80000dbe <page_fault_handler+0x60>

0000000080000e1c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  lk->name = name;
    80000e22:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e24:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e28:	00053823          	sd	zero,16(a0)
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000e32:	411c                	lw	a5,0(a0)
    80000e34:	e399                	bnez	a5,80000e3a <holding+0x8>
    80000e36:	4501                	li	a0,0
  return r;
}
    80000e38:	8082                	ret
{
    80000e3a:	1101                	addi	sp,sp,-32
    80000e3c:	ec06                	sd	ra,24(sp)
    80000e3e:	e822                	sd	s0,16(sp)
    80000e40:	e426                	sd	s1,8(sp)
    80000e42:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000e44:	6904                	ld	s1,16(a0)
    80000e46:	00001097          	auipc	ra,0x1
    80000e4a:	eb6080e7          	jalr	-330(ra) # 80001cfc <mycpu>
    80000e4e:	40a48533          	sub	a0,s1,a0
    80000e52:	00153513          	seqz	a0,a0
}
    80000e56:	60e2                	ld	ra,24(sp)
    80000e58:	6442                	ld	s0,16(sp)
    80000e5a:	64a2                	ld	s1,8(sp)
    80000e5c:	6105                	addi	sp,sp,32
    80000e5e:	8082                	ret

0000000080000e60 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000e60:	1101                	addi	sp,sp,-32
    80000e62:	ec06                	sd	ra,24(sp)
    80000e64:	e822                	sd	s0,16(sp)
    80000e66:	e426                	sd	s1,8(sp)
    80000e68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e6a:	100024f3          	csrr	s1,sstatus
    80000e6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000e72:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e74:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000e78:	00001097          	auipc	ra,0x1
    80000e7c:	e84080e7          	jalr	-380(ra) # 80001cfc <mycpu>
    80000e80:	5d3c                	lw	a5,120(a0)
    80000e82:	cf89                	beqz	a5,80000e9c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000e84:	00001097          	auipc	ra,0x1
    80000e88:	e78080e7          	jalr	-392(ra) # 80001cfc <mycpu>
    80000e8c:	5d3c                	lw	a5,120(a0)
    80000e8e:	2785                	addiw	a5,a5,1
    80000e90:	dd3c                	sw	a5,120(a0)
}
    80000e92:	60e2                	ld	ra,24(sp)
    80000e94:	6442                	ld	s0,16(sp)
    80000e96:	64a2                	ld	s1,8(sp)
    80000e98:	6105                	addi	sp,sp,32
    80000e9a:	8082                	ret
    mycpu()->intena = old;
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	e60080e7          	jalr	-416(ra) # 80001cfc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000ea4:	8085                	srli	s1,s1,0x1
    80000ea6:	8885                	andi	s1,s1,1
    80000ea8:	dd64                	sw	s1,124(a0)
    80000eaa:	bfe9                	j	80000e84 <push_off+0x24>

0000000080000eac <acquire>:
{
    80000eac:	1101                	addi	sp,sp,-32
    80000eae:	ec06                	sd	ra,24(sp)
    80000eb0:	e822                	sd	s0,16(sp)
    80000eb2:	e426                	sd	s1,8(sp)
    80000eb4:	1000                	addi	s0,sp,32
    80000eb6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000eb8:	00000097          	auipc	ra,0x0
    80000ebc:	fa8080e7          	jalr	-88(ra) # 80000e60 <push_off>
  if(holding(lk))
    80000ec0:	8526                	mv	a0,s1
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	f70080e7          	jalr	-144(ra) # 80000e32 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000eca:	4705                	li	a4,1
  if(holding(lk))
    80000ecc:	e115                	bnez	a0,80000ef0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ece:	87ba                	mv	a5,a4
    80000ed0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ed4:	2781                	sext.w	a5,a5
    80000ed6:	ffe5                	bnez	a5,80000ece <acquire+0x22>
  __sync_synchronize();
    80000ed8:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000edc:	00001097          	auipc	ra,0x1
    80000ee0:	e20080e7          	jalr	-480(ra) # 80001cfc <mycpu>
    80000ee4:	e888                	sd	a0,16(s1)
}
    80000ee6:	60e2                	ld	ra,24(sp)
    80000ee8:	6442                	ld	s0,16(sp)
    80000eea:	64a2                	ld	s1,8(sp)
    80000eec:	6105                	addi	sp,sp,32
    80000eee:	8082                	ret
    panic("acquire");
    80000ef0:	00008517          	auipc	a0,0x8
    80000ef4:	1b850513          	addi	a0,a0,440 # 800090a8 <digits+0x68>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	64c080e7          	jalr	1612(ra) # 80000544 <panic>

0000000080000f00 <pop_off>:

void
pop_off(void)
{
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e406                	sd	ra,8(sp)
    80000f04:	e022                	sd	s0,0(sp)
    80000f06:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	df4080e7          	jalr	-524(ra) # 80001cfc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000f14:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000f16:	e78d                	bnez	a5,80000f40 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000f18:	5d3c                	lw	a5,120(a0)
    80000f1a:	02f05b63          	blez	a5,80000f50 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000f1e:	37fd                	addiw	a5,a5,-1
    80000f20:	0007871b          	sext.w	a4,a5
    80000f24:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000f26:	eb09                	bnez	a4,80000f38 <pop_off+0x38>
    80000f28:	5d7c                	lw	a5,124(a0)
    80000f2a:	c799                	beqz	a5,80000f38 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000f30:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000f34:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000f38:	60a2                	ld	ra,8(sp)
    80000f3a:	6402                	ld	s0,0(sp)
    80000f3c:	0141                	addi	sp,sp,16
    80000f3e:	8082                	ret
    panic("pop_off - interruptible");
    80000f40:	00008517          	auipc	a0,0x8
    80000f44:	17050513          	addi	a0,a0,368 # 800090b0 <digits+0x70>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	5fc080e7          	jalr	1532(ra) # 80000544 <panic>
    panic("pop_off");
    80000f50:	00008517          	auipc	a0,0x8
    80000f54:	17850513          	addi	a0,a0,376 # 800090c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	5ec080e7          	jalr	1516(ra) # 80000544 <panic>

0000000080000f60 <release>:
{
    80000f60:	1101                	addi	sp,sp,-32
    80000f62:	ec06                	sd	ra,24(sp)
    80000f64:	e822                	sd	s0,16(sp)
    80000f66:	e426                	sd	s1,8(sp)
    80000f68:	1000                	addi	s0,sp,32
    80000f6a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	ec6080e7          	jalr	-314(ra) # 80000e32 <holding>
    80000f74:	c115                	beqz	a0,80000f98 <release+0x38>
  lk->cpu = 0;
    80000f76:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000f7a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000f7e:	0f50000f          	fence	iorw,ow
    80000f82:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	f7a080e7          	jalr	-134(ra) # 80000f00 <pop_off>
}
    80000f8e:	60e2                	ld	ra,24(sp)
    80000f90:	6442                	ld	s0,16(sp)
    80000f92:	64a2                	ld	s1,8(sp)
    80000f94:	6105                	addi	sp,sp,32
    80000f96:	8082                	ret
    panic("release");
    80000f98:	00008517          	auipc	a0,0x8
    80000f9c:	13850513          	addi	a0,a0,312 # 800090d0 <digits+0x90>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>

0000000080000fa8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000fae:	ce09                	beqz	a2,80000fc8 <memset+0x20>
    80000fb0:	87aa                	mv	a5,a0
    80000fb2:	fff6071b          	addiw	a4,a2,-1
    80000fb6:	1702                	slli	a4,a4,0x20
    80000fb8:	9301                	srli	a4,a4,0x20
    80000fba:	0705                	addi	a4,a4,1
    80000fbc:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000fbe:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7fdb8be8>
  for(i = 0; i < n; i++){
    80000fc2:	0785                	addi	a5,a5,1
    80000fc4:	fee79de3          	bne	a5,a4,80000fbe <memset+0x16>
  }
  return dst;
}
    80000fc8:	6422                	ld	s0,8(sp)
    80000fca:	0141                	addi	sp,sp,16
    80000fcc:	8082                	ret

0000000080000fce <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000fce:	1141                	addi	sp,sp,-16
    80000fd0:	e422                	sd	s0,8(sp)
    80000fd2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000fd4:	ca05                	beqz	a2,80001004 <memcmp+0x36>
    80000fd6:	fff6069b          	addiw	a3,a2,-1
    80000fda:	1682                	slli	a3,a3,0x20
    80000fdc:	9281                	srli	a3,a3,0x20
    80000fde:	0685                	addi	a3,a3,1
    80000fe0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000fe2:	00054783          	lbu	a5,0(a0)
    80000fe6:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0xffffffff7fdb8be8>
    80000fea:	00e79863          	bne	a5,a4,80000ffa <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000fee:	0505                	addi	a0,a0,1
    80000ff0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ff2:	fed518e3          	bne	a0,a3,80000fe2 <memcmp+0x14>
  }

  return 0;
    80000ff6:	4501                	li	a0,0
    80000ff8:	a019                	j	80000ffe <memcmp+0x30>
      return *s1 - *s2;
    80000ffa:	40e7853b          	subw	a0,a5,a4
}
    80000ffe:	6422                	ld	s0,8(sp)
    80001000:	0141                	addi	sp,sp,16
    80001002:	8082                	ret
  return 0;
    80001004:	4501                	li	a0,0
    80001006:	bfe5                	j	80000ffe <memcmp+0x30>

0000000080001008 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001008:	1141                	addi	sp,sp,-16
    8000100a:	e422                	sd	s0,8(sp)
    8000100c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000100e:	ca0d                	beqz	a2,80001040 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001010:	00a5f963          	bgeu	a1,a0,80001022 <memmove+0x1a>
    80001014:	02061693          	slli	a3,a2,0x20
    80001018:	9281                	srli	a3,a3,0x20
    8000101a:	00d58733          	add	a4,a1,a3
    8000101e:	02e56463          	bltu	a0,a4,80001046 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001022:	fff6079b          	addiw	a5,a2,-1
    80001026:	1782                	slli	a5,a5,0x20
    80001028:	9381                	srli	a5,a5,0x20
    8000102a:	0785                	addi	a5,a5,1
    8000102c:	97ae                	add	a5,a5,a1
    8000102e:	872a                	mv	a4,a0
      *d++ = *s++;
    80001030:	0585                	addi	a1,a1,1
    80001032:	0705                	addi	a4,a4,1
    80001034:	fff5c683          	lbu	a3,-1(a1)
    80001038:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    8000103c:	fef59ae3          	bne	a1,a5,80001030 <memmove+0x28>

  return dst;
}
    80001040:	6422                	ld	s0,8(sp)
    80001042:	0141                	addi	sp,sp,16
    80001044:	8082                	ret
    d += n;
    80001046:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80001048:	fff6079b          	addiw	a5,a2,-1
    8000104c:	1782                	slli	a5,a5,0x20
    8000104e:	9381                	srli	a5,a5,0x20
    80001050:	fff7c793          	not	a5,a5
    80001054:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80001056:	177d                	addi	a4,a4,-1
    80001058:	16fd                	addi	a3,a3,-1
    8000105a:	00074603          	lbu	a2,0(a4)
    8000105e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80001062:	fef71ae3          	bne	a4,a5,80001056 <memmove+0x4e>
    80001066:	bfe9                	j	80001040 <memmove+0x38>

0000000080001068 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001070:	00000097          	auipc	ra,0x0
    80001074:	f98080e7          	jalr	-104(ra) # 80001008 <memmove>
}
    80001078:	60a2                	ld	ra,8(sp)
    8000107a:	6402                	ld	s0,0(sp)
    8000107c:	0141                	addi	sp,sp,16
    8000107e:	8082                	ret

0000000080001080 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001080:	1141                	addi	sp,sp,-16
    80001082:	e422                	sd	s0,8(sp)
    80001084:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001086:	ce11                	beqz	a2,800010a2 <strncmp+0x22>
    80001088:	00054783          	lbu	a5,0(a0)
    8000108c:	cf89                	beqz	a5,800010a6 <strncmp+0x26>
    8000108e:	0005c703          	lbu	a4,0(a1)
    80001092:	00f71a63          	bne	a4,a5,800010a6 <strncmp+0x26>
    n--, p++, q++;
    80001096:	367d                	addiw	a2,a2,-1
    80001098:	0505                	addi	a0,a0,1
    8000109a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000109c:	f675                	bnez	a2,80001088 <strncmp+0x8>
  if(n == 0)
    return 0;
    8000109e:	4501                	li	a0,0
    800010a0:	a809                	j	800010b2 <strncmp+0x32>
    800010a2:	4501                	li	a0,0
    800010a4:	a039                	j	800010b2 <strncmp+0x32>
  if(n == 0)
    800010a6:	ca09                	beqz	a2,800010b8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800010a8:	00054503          	lbu	a0,0(a0)
    800010ac:	0005c783          	lbu	a5,0(a1)
    800010b0:	9d1d                	subw	a0,a0,a5
}
    800010b2:	6422                	ld	s0,8(sp)
    800010b4:	0141                	addi	sp,sp,16
    800010b6:	8082                	ret
    return 0;
    800010b8:	4501                	li	a0,0
    800010ba:	bfe5                	j	800010b2 <strncmp+0x32>

00000000800010bc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800010bc:	1141                	addi	sp,sp,-16
    800010be:	e422                	sd	s0,8(sp)
    800010c0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800010c2:	872a                	mv	a4,a0
    800010c4:	8832                	mv	a6,a2
    800010c6:	367d                	addiw	a2,a2,-1
    800010c8:	01005963          	blez	a6,800010da <strncpy+0x1e>
    800010cc:	0705                	addi	a4,a4,1
    800010ce:	0005c783          	lbu	a5,0(a1)
    800010d2:	fef70fa3          	sb	a5,-1(a4)
    800010d6:	0585                	addi	a1,a1,1
    800010d8:	f7f5                	bnez	a5,800010c4 <strncpy+0x8>
    ;
  while(n-- > 0)
    800010da:	00c05d63          	blez	a2,800010f4 <strncpy+0x38>
    800010de:	86ba                	mv	a3,a4
    *s++ = 0;
    800010e0:	0685                	addi	a3,a3,1
    800010e2:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800010e6:	fff6c793          	not	a5,a3
    800010ea:	9fb9                	addw	a5,a5,a4
    800010ec:	010787bb          	addw	a5,a5,a6
    800010f0:	fef048e3          	bgtz	a5,800010e0 <strncpy+0x24>
  return os;
}
    800010f4:	6422                	ld	s0,8(sp)
    800010f6:	0141                	addi	sp,sp,16
    800010f8:	8082                	ret

00000000800010fa <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800010fa:	1141                	addi	sp,sp,-16
    800010fc:	e422                	sd	s0,8(sp)
    800010fe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001100:	02c05363          	blez	a2,80001126 <safestrcpy+0x2c>
    80001104:	fff6069b          	addiw	a3,a2,-1
    80001108:	1682                	slli	a3,a3,0x20
    8000110a:	9281                	srli	a3,a3,0x20
    8000110c:	96ae                	add	a3,a3,a1
    8000110e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001110:	00d58963          	beq	a1,a3,80001122 <safestrcpy+0x28>
    80001114:	0585                	addi	a1,a1,1
    80001116:	0785                	addi	a5,a5,1
    80001118:	fff5c703          	lbu	a4,-1(a1)
    8000111c:	fee78fa3          	sb	a4,-1(a5)
    80001120:	fb65                	bnez	a4,80001110 <safestrcpy+0x16>
    ;
  *s = 0;
    80001122:	00078023          	sb	zero,0(a5)
  return os;
}
    80001126:	6422                	ld	s0,8(sp)
    80001128:	0141                	addi	sp,sp,16
    8000112a:	8082                	ret

000000008000112c <strlen>:

int
strlen(const char *s)
{
    8000112c:	1141                	addi	sp,sp,-16
    8000112e:	e422                	sd	s0,8(sp)
    80001130:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001132:	00054783          	lbu	a5,0(a0)
    80001136:	cf91                	beqz	a5,80001152 <strlen+0x26>
    80001138:	0505                	addi	a0,a0,1
    8000113a:	87aa                	mv	a5,a0
    8000113c:	4685                	li	a3,1
    8000113e:	9e89                	subw	a3,a3,a0
    80001140:	00f6853b          	addw	a0,a3,a5
    80001144:	0785                	addi	a5,a5,1
    80001146:	fff7c703          	lbu	a4,-1(a5)
    8000114a:	fb7d                	bnez	a4,80001140 <strlen+0x14>
    ;
  return n;
}
    8000114c:	6422                	ld	s0,8(sp)
    8000114e:	0141                	addi	sp,sp,16
    80001150:	8082                	ret
  for(n = 0; s[n]; n++)
    80001152:	4501                	li	a0,0
    80001154:	bfe5                	j	8000114c <strlen+0x20>

0000000080001156 <main>:
volatile static int started = 0;
// start() jumps here in supervisor mode on all CPUs.
extern pde_t *kpgdir;
void
main()
{
    80001156:	1141                	addi	sp,sp,-16
    80001158:	e406                	sd	ra,8(sp)
    8000115a:	e022                	sd	s0,0(sp)
    8000115c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000115e:	00001097          	auipc	ra,0x1
    80001162:	b8e080e7          	jalr	-1138(ra) # 80001cec <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001166:	00009717          	auipc	a4,0x9
    8000116a:	9f270713          	addi	a4,a4,-1550 # 80009b58 <started>
  if(cpuid() == 0){
    8000116e:	c139                	beqz	a0,800011b4 <main+0x5e>
    while(started == 0)
    80001170:	431c                	lw	a5,0(a4)
    80001172:	2781                	sext.w	a5,a5
    80001174:	dff5                	beqz	a5,80001170 <main+0x1a>
      ;
    __sync_synchronize();
    80001176:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000117a:	00001097          	auipc	ra,0x1
    8000117e:	b72080e7          	jalr	-1166(ra) # 80001cec <cpuid>
    80001182:	85aa                	mv	a1,a0
    80001184:	00008517          	auipc	a0,0x8
    80001188:	f6c50513          	addi	a0,a0,-148 # 800090f0 <digits+0xb0>
    8000118c:	fffff097          	auipc	ra,0xfffff
    80001190:	402080e7          	jalr	1026(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80001194:	00000097          	auipc	ra,0x0
    80001198:	0d8080e7          	jalr	216(ra) # 8000126c <kvminithart>
    trapinithart();   // install kernel trap vector
    8000119c:	00002097          	auipc	ra,0x2
    800011a0:	ff6080e7          	jalr	-10(ra) # 80003192 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800011a4:	00006097          	auipc	ra,0x6
    800011a8:	b4c080e7          	jalr	-1204(ra) # 80006cf0 <plicinithart>
  }

  scheduler();        
    800011ac:	00002097          	auipc	ra,0x2
    800011b0:	d9e080e7          	jalr	-610(ra) # 80002f4a <scheduler>
    consoleinit();
    800011b4:	fffff097          	auipc	ra,0xfffff
    800011b8:	2a2080e7          	jalr	674(ra) # 80000456 <consoleinit>
    printfinit();
    800011bc:	fffff097          	auipc	ra,0xfffff
    800011c0:	5b8080e7          	jalr	1464(ra) # 80000774 <printfinit>
    printf("\n");
    800011c4:	00008517          	auipc	a0,0x8
    800011c8:	23450513          	addi	a0,a0,564 # 800093f8 <digits+0x3b8>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	3c2080e7          	jalr	962(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    800011d4:	00008517          	auipc	a0,0x8
    800011d8:	f0450513          	addi	a0,a0,-252 # 800090d8 <digits+0x98>
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	3b2080e7          	jalr	946(ra) # 8000058e <printf>
    printf("\n");
    800011e4:	00008517          	auipc	a0,0x8
    800011e8:	21450513          	addi	a0,a0,532 # 800093f8 <digits+0x3b8>
    800011ec:	fffff097          	auipc	ra,0xfffff
    800011f0:	3a2080e7          	jalr	930(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	abc080e7          	jalr	-1348(ra) # 80000cb0 <kinit>
    kvminit();       // create kernel page table
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	326080e7          	jalr	806(ra) # 80001522 <kvminit>
    kvminithart();   // turn on paging
    80001204:	00000097          	auipc	ra,0x0
    80001208:	068080e7          	jalr	104(ra) # 8000126c <kvminithart>
    procinit();      // process table
    8000120c:	00001097          	auipc	ra,0x1
    80001210:	a08080e7          	jalr	-1528(ra) # 80001c14 <procinit>
    trapinit();      // trap vectors
    80001214:	00002097          	auipc	ra,0x2
    80001218:	f96080e7          	jalr	-106(ra) # 800031aa <trapinit>
    trapinithart();  // install kernel trap vector
    8000121c:	00002097          	auipc	ra,0x2
    80001220:	f76080e7          	jalr	-138(ra) # 80003192 <trapinithart>
    plicinit();      // set up interrupt controller
    80001224:	00006097          	auipc	ra,0x6
    80001228:	ab6080e7          	jalr	-1354(ra) # 80006cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000122c:	00006097          	auipc	ra,0x6
    80001230:	ac4080e7          	jalr	-1340(ra) # 80006cf0 <plicinithart>
    binit();         // buffer cache
    80001234:	00003097          	auipc	ra,0x3
    80001238:	c74080e7          	jalr	-908(ra) # 80003ea8 <binit>
    iinit();         // inode table
    8000123c:	00003097          	auipc	ra,0x3
    80001240:	318080e7          	jalr	792(ra) # 80004554 <iinit>
    fileinit();      // file table
    80001244:	00004097          	auipc	ra,0x4
    80001248:	2b6080e7          	jalr	694(ra) # 800054fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000124c:	00006097          	auipc	ra,0x6
    80001250:	bac080e7          	jalr	-1108(ra) # 80006df8 <virtio_disk_init>
    userinit();      // first user process
    80001254:	00001097          	auipc	ra,0x1
    80001258:	f6a080e7          	jalr	-150(ra) # 800021be <userinit>
    __sync_synchronize();
    8000125c:	0ff0000f          	fence
    started = 1;
    80001260:	4785                	li	a5,1
    80001262:	00009717          	auipc	a4,0x9
    80001266:	8ef72b23          	sw	a5,-1802(a4) # 80009b58 <started>
    8000126a:	b789                	j	800011ac <main+0x56>

000000008000126c <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    8000126c:	1141                	addi	sp,sp,-16
    8000126e:	e422                	sd	s0,8(sp)
    80001270:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001272:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001276:	00009797          	auipc	a5,0x9
    8000127a:	8ea7b783          	ld	a5,-1814(a5) # 80009b60 <kernel_pagetable>
    8000127e:	83b1                	srli	a5,a5,0xc
    80001280:	577d                	li	a4,-1
    80001282:	177e                	slli	a4,a4,0x3f
    80001284:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001286:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000128a:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000128e:	6422                	ld	s0,8(sp)
    80001290:	0141                	addi	sp,sp,16
    80001292:	8082                	ret

0000000080001294 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001294:	7139                	addi	sp,sp,-64
    80001296:	fc06                	sd	ra,56(sp)
    80001298:	f822                	sd	s0,48(sp)
    8000129a:	f426                	sd	s1,40(sp)
    8000129c:	f04a                	sd	s2,32(sp)
    8000129e:	ec4e                	sd	s3,24(sp)
    800012a0:	e852                	sd	s4,16(sp)
    800012a2:	e456                	sd	s5,8(sp)
    800012a4:	e05a                	sd	s6,0(sp)
    800012a6:	0080                	addi	s0,sp,64
    800012a8:	84aa                	mv	s1,a0
    800012aa:	89ae                	mv	s3,a1
    800012ac:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    800012ae:	57fd                	li	a5,-1
    800012b0:	83e9                	srli	a5,a5,0x1a
    800012b2:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    800012b4:	4b31                	li	s6,12
  if (va >= MAXVA)
    800012b6:	04b7f263          	bgeu	a5,a1,800012fa <walk+0x66>
    panic("walk");
    800012ba:	00008517          	auipc	a0,0x8
    800012be:	e4e50513          	addi	a0,a0,-434 # 80009108 <digits+0xc8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	282080e7          	jalr	642(ra) # 80000544 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800012ca:	060a8663          	beqz	s5,80001336 <walk+0xa2>
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	a26080e7          	jalr	-1498(ra) # 80000cf4 <kalloc>
    800012d6:	84aa                	mv	s1,a0
    800012d8:	c529                	beqz	a0,80001322 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800012da:	6605                	lui	a2,0x1
    800012dc:	4581                	li	a1,0
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	cca080e7          	jalr	-822(ra) # 80000fa8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800012e6:	00c4d793          	srli	a5,s1,0xc
    800012ea:	07aa                	slli	a5,a5,0xa
    800012ec:	0017e793          	ori	a5,a5,1
    800012f0:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    800012f4:	3a5d                	addiw	s4,s4,-9
    800012f6:	036a0063          	beq	s4,s6,80001316 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800012fa:	0149d933          	srl	s2,s3,s4
    800012fe:	1ff97913          	andi	s2,s2,511
    80001302:	090e                	slli	s2,s2,0x3
    80001304:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001306:	00093483          	ld	s1,0(s2)
    8000130a:	0014f793          	andi	a5,s1,1
    8000130e:	dfd5                	beqz	a5,800012ca <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001310:	80a9                	srli	s1,s1,0xa
    80001312:	04b2                	slli	s1,s1,0xc
    80001314:	b7c5                	j	800012f4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001316:	00c9d513          	srli	a0,s3,0xc
    8000131a:	1ff57513          	andi	a0,a0,511
    8000131e:	050e                	slli	a0,a0,0x3
    80001320:	9526                	add	a0,a0,s1
}
    80001322:	70e2                	ld	ra,56(sp)
    80001324:	7442                	ld	s0,48(sp)
    80001326:	74a2                	ld	s1,40(sp)
    80001328:	7902                	ld	s2,32(sp)
    8000132a:	69e2                	ld	s3,24(sp)
    8000132c:	6a42                	ld	s4,16(sp)
    8000132e:	6aa2                	ld	s5,8(sp)
    80001330:	6b02                	ld	s6,0(sp)
    80001332:	6121                	addi	sp,sp,64
    80001334:	8082                	ret
        return 0;
    80001336:	4501                	li	a0,0
    80001338:	b7ed                	j	80001322 <walk+0x8e>

000000008000133a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000133a:	57fd                	li	a5,-1
    8000133c:	83e9                	srli	a5,a5,0x1a
    8000133e:	00b7f463          	bgeu	a5,a1,80001346 <walkaddr+0xc>
    return 0;
    80001342:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001344:	8082                	ret
{
    80001346:	1141                	addi	sp,sp,-16
    80001348:	e406                	sd	ra,8(sp)
    8000134a:	e022                	sd	s0,0(sp)
    8000134c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000134e:	4601                	li	a2,0
    80001350:	00000097          	auipc	ra,0x0
    80001354:	f44080e7          	jalr	-188(ra) # 80001294 <walk>
  if (pte == 0)
    80001358:	c105                	beqz	a0,80001378 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    8000135a:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000135c:	0117f693          	andi	a3,a5,17
    80001360:	4745                	li	a4,17
    return 0;
    80001362:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001364:	00e68663          	beq	a3,a4,80001370 <walkaddr+0x36>
}
    80001368:	60a2                	ld	ra,8(sp)
    8000136a:	6402                	ld	s0,0(sp)
    8000136c:	0141                	addi	sp,sp,16
    8000136e:	8082                	ret
  pa = PTE2PA(*pte);
    80001370:	00a7d513          	srli	a0,a5,0xa
    80001374:	0532                	slli	a0,a0,0xc
  return pa;
    80001376:	bfcd                	j	80001368 <walkaddr+0x2e>
    return 0;
    80001378:	4501                	li	a0,0
    8000137a:	b7fd                	j	80001368 <walkaddr+0x2e>

000000008000137c <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000137c:	715d                	addi	sp,sp,-80
    8000137e:	e486                	sd	ra,72(sp)
    80001380:	e0a2                	sd	s0,64(sp)
    80001382:	fc26                	sd	s1,56(sp)
    80001384:	f84a                	sd	s2,48(sp)
    80001386:	f44e                	sd	s3,40(sp)
    80001388:	f052                	sd	s4,32(sp)
    8000138a:	ec56                	sd	s5,24(sp)
    8000138c:	e85a                	sd	s6,16(sp)
    8000138e:	e45e                	sd	s7,8(sp)
    80001390:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    80001392:	c205                	beqz	a2,800013b2 <mappages+0x36>
    80001394:	8aaa                	mv	s5,a0
    80001396:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001398:	77fd                	lui	a5,0xfffff
    8000139a:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000139e:	15fd                	addi	a1,a1,-1
    800013a0:	00c589b3          	add	s3,a1,a2
    800013a4:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800013a8:	8952                	mv	s2,s4
    800013aa:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800013ae:	6b85                	lui	s7,0x1
    800013b0:	a015                	j	800013d4 <mappages+0x58>
    panic("mappages: size");
    800013b2:	00008517          	auipc	a0,0x8
    800013b6:	d5e50513          	addi	a0,a0,-674 # 80009110 <digits+0xd0>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	18a080e7          	jalr	394(ra) # 80000544 <panic>
      panic("mappages: remap");
    800013c2:	00008517          	auipc	a0,0x8
    800013c6:	d5e50513          	addi	a0,a0,-674 # 80009120 <digits+0xe0>
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	17a080e7          	jalr	378(ra) # 80000544 <panic>
    a += PGSIZE;
    800013d2:	995e                	add	s2,s2,s7
  for (;;)
    800013d4:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    800013d8:	4605                	li	a2,1
    800013da:	85ca                	mv	a1,s2
    800013dc:	8556                	mv	a0,s5
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	eb6080e7          	jalr	-330(ra) # 80001294 <walk>
    800013e6:	cd19                	beqz	a0,80001404 <mappages+0x88>
    if (*pte & PTE_V)
    800013e8:	611c                	ld	a5,0(a0)
    800013ea:	8b85                	andi	a5,a5,1
    800013ec:	fbf9                	bnez	a5,800013c2 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800013ee:	80b1                	srli	s1,s1,0xc
    800013f0:	04aa                	slli	s1,s1,0xa
    800013f2:	0164e4b3          	or	s1,s1,s6
    800013f6:	0014e493          	ori	s1,s1,1
    800013fa:	e104                	sd	s1,0(a0)
    if (a == last)
    800013fc:	fd391be3          	bne	s2,s3,800013d2 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001400:	4501                	li	a0,0
    80001402:	a011                	j	80001406 <mappages+0x8a>
      return -1;
    80001404:	557d                	li	a0,-1
}
    80001406:	60a6                	ld	ra,72(sp)
    80001408:	6406                	ld	s0,64(sp)
    8000140a:	74e2                	ld	s1,56(sp)
    8000140c:	7942                	ld	s2,48(sp)
    8000140e:	79a2                	ld	s3,40(sp)
    80001410:	7a02                	ld	s4,32(sp)
    80001412:	6ae2                	ld	s5,24(sp)
    80001414:	6b42                	ld	s6,16(sp)
    80001416:	6ba2                	ld	s7,8(sp)
    80001418:	6161                	addi	sp,sp,80
    8000141a:	8082                	ret

000000008000141c <kvmmap>:
{
    8000141c:	1141                	addi	sp,sp,-16
    8000141e:	e406                	sd	ra,8(sp)
    80001420:	e022                	sd	s0,0(sp)
    80001422:	0800                	addi	s0,sp,16
    80001424:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001426:	86b2                	mv	a3,a2
    80001428:	863e                	mv	a2,a5
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	f52080e7          	jalr	-174(ra) # 8000137c <mappages>
    80001432:	e509                	bnez	a0,8000143c <kvmmap+0x20>
}
    80001434:	60a2                	ld	ra,8(sp)
    80001436:	6402                	ld	s0,0(sp)
    80001438:	0141                	addi	sp,sp,16
    8000143a:	8082                	ret
    panic("kvmmap");
    8000143c:	00008517          	auipc	a0,0x8
    80001440:	cf450513          	addi	a0,a0,-780 # 80009130 <digits+0xf0>
    80001444:	fffff097          	auipc	ra,0xfffff
    80001448:	100080e7          	jalr	256(ra) # 80000544 <panic>

000000008000144c <kvmmake>:
{
    8000144c:	1101                	addi	sp,sp,-32
    8000144e:	ec06                	sd	ra,24(sp)
    80001450:	e822                	sd	s0,16(sp)
    80001452:	e426                	sd	s1,8(sp)
    80001454:	e04a                	sd	s2,0(sp)
    80001456:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	89c080e7          	jalr	-1892(ra) # 80000cf4 <kalloc>
    80001460:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	b42080e7          	jalr	-1214(ra) # 80000fa8 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000146e:	4719                	li	a4,6
    80001470:	6685                	lui	a3,0x1
    80001472:	10000637          	lui	a2,0x10000
    80001476:	100005b7          	lui	a1,0x10000
    8000147a:	8526                	mv	a0,s1
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	fa0080e7          	jalr	-96(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001484:	4719                	li	a4,6
    80001486:	6685                	lui	a3,0x1
    80001488:	10001637          	lui	a2,0x10001
    8000148c:	100015b7          	lui	a1,0x10001
    80001490:	8526                	mv	a0,s1
    80001492:	00000097          	auipc	ra,0x0
    80001496:	f8a080e7          	jalr	-118(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000149a:	4719                	li	a4,6
    8000149c:	004006b7          	lui	a3,0x400
    800014a0:	0c000637          	lui	a2,0xc000
    800014a4:	0c0005b7          	lui	a1,0xc000
    800014a8:	8526                	mv	a0,s1
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	f72080e7          	jalr	-142(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800014b2:	00008917          	auipc	s2,0x8
    800014b6:	b4e90913          	addi	s2,s2,-1202 # 80009000 <etext>
    800014ba:	4729                	li	a4,10
    800014bc:	80008697          	auipc	a3,0x80008
    800014c0:	b4468693          	addi	a3,a3,-1212 # 9000 <_entry-0x7fff7000>
    800014c4:	4605                	li	a2,1
    800014c6:	067e                	slli	a2,a2,0x1f
    800014c8:	85b2                	mv	a1,a2
    800014ca:	8526                	mv	a0,s1
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	f50080e7          	jalr	-176(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800014d4:	4719                	li	a4,6
    800014d6:	46c5                	li	a3,17
    800014d8:	06ee                	slli	a3,a3,0x1b
    800014da:	412686b3          	sub	a3,a3,s2
    800014de:	864a                	mv	a2,s2
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8526                	mv	a0,s1
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f38080e7          	jalr	-200(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800014ec:	4729                	li	a4,10
    800014ee:	6685                	lui	a3,0x1
    800014f0:	00007617          	auipc	a2,0x7
    800014f4:	b1060613          	addi	a2,a2,-1264 # 80008000 <_trampoline>
    800014f8:	040005b7          	lui	a1,0x4000
    800014fc:	15fd                	addi	a1,a1,-1
    800014fe:	05b2                	slli	a1,a1,0xc
    80001500:	8526                	mv	a0,s1
    80001502:	00000097          	auipc	ra,0x0
    80001506:	f1a080e7          	jalr	-230(ra) # 8000141c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000150a:	8526                	mv	a0,s1
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	672080e7          	jalr	1650(ra) # 80001b7e <proc_mapstacks>
}
    80001514:	8526                	mv	a0,s1
    80001516:	60e2                	ld	ra,24(sp)
    80001518:	6442                	ld	s0,16(sp)
    8000151a:	64a2                	ld	s1,8(sp)
    8000151c:	6902                	ld	s2,0(sp)
    8000151e:	6105                	addi	sp,sp,32
    80001520:	8082                	ret

0000000080001522 <kvminit>:
{
    80001522:	1141                	addi	sp,sp,-16
    80001524:	e406                	sd	ra,8(sp)
    80001526:	e022                	sd	s0,0(sp)
    80001528:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f22080e7          	jalr	-222(ra) # 8000144c <kvmmake>
    80001532:	00008797          	auipc	a5,0x8
    80001536:	62a7b723          	sd	a0,1582(a5) # 80009b60 <kernel_pagetable>
}
    8000153a:	60a2                	ld	ra,8(sp)
    8000153c:	6402                	ld	s0,0(sp)
    8000153e:	0141                	addi	sp,sp,16
    80001540:	8082                	ret

0000000080001542 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001542:	715d                	addi	sp,sp,-80
    80001544:	e486                	sd	ra,72(sp)
    80001546:	e0a2                	sd	s0,64(sp)
    80001548:	fc26                	sd	s1,56(sp)
    8000154a:	f84a                	sd	s2,48(sp)
    8000154c:	f44e                	sd	s3,40(sp)
    8000154e:	f052                	sd	s4,32(sp)
    80001550:	ec56                	sd	s5,24(sp)
    80001552:	e85a                	sd	s6,16(sp)
    80001554:	e45e                	sd	s7,8(sp)
    80001556:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001558:	03459793          	slli	a5,a1,0x34
    8000155c:	e795                	bnez	a5,80001588 <uvmunmap+0x46>
    8000155e:	8a2a                	mv	s4,a0
    80001560:	892e                	mv	s2,a1
    80001562:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001564:	0632                	slli	a2,a2,0xc
    80001566:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    8000156a:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000156c:	6b05                	lui	s6,0x1
    8000156e:	0735e863          	bltu	a1,s3,800015de <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001572:	60a6                	ld	ra,72(sp)
    80001574:	6406                	ld	s0,64(sp)
    80001576:	74e2                	ld	s1,56(sp)
    80001578:	7942                	ld	s2,48(sp)
    8000157a:	79a2                	ld	s3,40(sp)
    8000157c:	7a02                	ld	s4,32(sp)
    8000157e:	6ae2                	ld	s5,24(sp)
    80001580:	6b42                	ld	s6,16(sp)
    80001582:	6ba2                	ld	s7,8(sp)
    80001584:	6161                	addi	sp,sp,80
    80001586:	8082                	ret
    panic("uvmunmap: not aligned");
    80001588:	00008517          	auipc	a0,0x8
    8000158c:	bb050513          	addi	a0,a0,-1104 # 80009138 <digits+0xf8>
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	fb4080e7          	jalr	-76(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    80001598:	00008517          	auipc	a0,0x8
    8000159c:	bb850513          	addi	a0,a0,-1096 # 80009150 <digits+0x110>
    800015a0:	fffff097          	auipc	ra,0xfffff
    800015a4:	fa4080e7          	jalr	-92(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800015a8:	00008517          	auipc	a0,0x8
    800015ac:	bb850513          	addi	a0,a0,-1096 # 80009160 <digits+0x120>
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800015b8:	00008517          	auipc	a0,0x8
    800015bc:	bc050513          	addi	a0,a0,-1088 # 80009178 <digits+0x138>
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	f84080e7          	jalr	-124(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800015c8:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    800015ca:	0532                	slli	a0,a0,0xc
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	5ca080e7          	jalr	1482(ra) # 80000b96 <kfree>
    *pte = 0;
    800015d4:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800015d8:	995a                	add	s2,s2,s6
    800015da:	f9397ce3          	bgeu	s2,s3,80001572 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    800015de:	4601                	li	a2,0
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8552                	mv	a0,s4
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	cb0080e7          	jalr	-848(ra) # 80001294 <walk>
    800015ec:	84aa                	mv	s1,a0
    800015ee:	d54d                	beqz	a0,80001598 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    800015f0:	6108                	ld	a0,0(a0)
    800015f2:	00157793          	andi	a5,a0,1
    800015f6:	dbcd                	beqz	a5,800015a8 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    800015f8:	3ff57793          	andi	a5,a0,1023
    800015fc:	fb778ee3          	beq	a5,s7,800015b8 <uvmunmap+0x76>
    if (do_free)
    80001600:	fc0a8ae3          	beqz	s5,800015d4 <uvmunmap+0x92>
    80001604:	b7d1                	j	800015c8 <uvmunmap+0x86>

0000000080001606 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001606:	1101                	addi	sp,sp,-32
    80001608:	ec06                	sd	ra,24(sp)
    8000160a:	e822                	sd	s0,16(sp)
    8000160c:	e426                	sd	s1,8(sp)
    8000160e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	6e4080e7          	jalr	1764(ra) # 80000cf4 <kalloc>
    80001618:	84aa                	mv	s1,a0
  if (pagetable == 0)
    8000161a:	c519                	beqz	a0,80001628 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	988080e7          	jalr	-1656(ra) # 80000fa8 <memset>
  return pagetable;
}
    80001628:	8526                	mv	a0,s1
    8000162a:	60e2                	ld	ra,24(sp)
    8000162c:	6442                	ld	s0,16(sp)
    8000162e:	64a2                	ld	s1,8(sp)
    80001630:	6105                	addi	sp,sp,32
    80001632:	8082                	ret

0000000080001634 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001634:	7179                	addi	sp,sp,-48
    80001636:	f406                	sd	ra,40(sp)
    80001638:	f022                	sd	s0,32(sp)
    8000163a:	ec26                	sd	s1,24(sp)
    8000163c:	e84a                	sd	s2,16(sp)
    8000163e:	e44e                	sd	s3,8(sp)
    80001640:	e052                	sd	s4,0(sp)
    80001642:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001644:	6785                	lui	a5,0x1
    80001646:	04f67863          	bgeu	a2,a5,80001696 <uvmfirst+0x62>
    8000164a:	8a2a                	mv	s4,a0
    8000164c:	89ae                	mv	s3,a1
    8000164e:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	6a4080e7          	jalr	1700(ra) # 80000cf4 <kalloc>
    80001658:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000165a:	6605                	lui	a2,0x1
    8000165c:	4581                	li	a1,0
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	94a080e7          	jalr	-1718(ra) # 80000fa8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001666:	4779                	li	a4,30
    80001668:	86ca                	mv	a3,s2
    8000166a:	6605                	lui	a2,0x1
    8000166c:	4581                	li	a1,0
    8000166e:	8552                	mv	a0,s4
    80001670:	00000097          	auipc	ra,0x0
    80001674:	d0c080e7          	jalr	-756(ra) # 8000137c <mappages>
  memmove(mem, src, sz);
    80001678:	8626                	mv	a2,s1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	854a                	mv	a0,s2
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	98a080e7          	jalr	-1654(ra) # 80001008 <memmove>
}
    80001686:	70a2                	ld	ra,40(sp)
    80001688:	7402                	ld	s0,32(sp)
    8000168a:	64e2                	ld	s1,24(sp)
    8000168c:	6942                	ld	s2,16(sp)
    8000168e:	69a2                	ld	s3,8(sp)
    80001690:	6a02                	ld	s4,0(sp)
    80001692:	6145                	addi	sp,sp,48
    80001694:	8082                	ret
    panic("uvmfirst: more than a page");
    80001696:	00008517          	auipc	a0,0x8
    8000169a:	afa50513          	addi	a0,a0,-1286 # 80009190 <digits+0x150>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	ea6080e7          	jalr	-346(ra) # 80000544 <panic>

00000000800016a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800016a6:	1101                	addi	sp,sp,-32
    800016a8:	ec06                	sd	ra,24(sp)
    800016aa:	e822                	sd	s0,16(sp)
    800016ac:	e426                	sd	s1,8(sp)
    800016ae:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800016b0:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800016b2:	00b67d63          	bgeu	a2,a1,800016cc <uvmdealloc+0x26>
    800016b6:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800016b8:	6785                	lui	a5,0x1
    800016ba:	17fd                	addi	a5,a5,-1
    800016bc:	00f60733          	add	a4,a2,a5
    800016c0:	767d                	lui	a2,0xfffff
    800016c2:	8f71                	and	a4,a4,a2
    800016c4:	97ae                	add	a5,a5,a1
    800016c6:	8ff1                	and	a5,a5,a2
    800016c8:	00f76863          	bltu	a4,a5,800016d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800016cc:	8526                	mv	a0,s1
    800016ce:	60e2                	ld	ra,24(sp)
    800016d0:	6442                	ld	s0,16(sp)
    800016d2:	64a2                	ld	s1,8(sp)
    800016d4:	6105                	addi	sp,sp,32
    800016d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800016d8:	8f99                	sub	a5,a5,a4
    800016da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800016dc:	4685                	li	a3,1
    800016de:	0007861b          	sext.w	a2,a5
    800016e2:	85ba                	mv	a1,a4
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	e5e080e7          	jalr	-418(ra) # 80001542 <uvmunmap>
    800016ec:	b7c5                	j	800016cc <uvmdealloc+0x26>

00000000800016ee <uvmalloc>:
  if (newsz < oldsz)
    800016ee:	0ab66563          	bltu	a2,a1,80001798 <uvmalloc+0xaa>
{
    800016f2:	7139                	addi	sp,sp,-64
    800016f4:	fc06                	sd	ra,56(sp)
    800016f6:	f822                	sd	s0,48(sp)
    800016f8:	f426                	sd	s1,40(sp)
    800016fa:	f04a                	sd	s2,32(sp)
    800016fc:	ec4e                	sd	s3,24(sp)
    800016fe:	e852                	sd	s4,16(sp)
    80001700:	e456                	sd	s5,8(sp)
    80001702:	e05a                	sd	s6,0(sp)
    80001704:	0080                	addi	s0,sp,64
    80001706:	8aaa                	mv	s5,a0
    80001708:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000170a:	6985                	lui	s3,0x1
    8000170c:	19fd                	addi	s3,s3,-1
    8000170e:	95ce                	add	a1,a1,s3
    80001710:	79fd                	lui	s3,0xfffff
    80001712:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001716:	08c9f363          	bgeu	s3,a2,8000179c <uvmalloc+0xae>
    8000171a:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000171c:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001720:	fffff097          	auipc	ra,0xfffff
    80001724:	5d4080e7          	jalr	1492(ra) # 80000cf4 <kalloc>
    80001728:	84aa                	mv	s1,a0
    if (mem == 0)
    8000172a:	c51d                	beqz	a0,80001758 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000172c:	6605                	lui	a2,0x1
    8000172e:	4581                	li	a1,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	878080e7          	jalr	-1928(ra) # 80000fa8 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001738:	875a                	mv	a4,s6
    8000173a:	86a6                	mv	a3,s1
    8000173c:	6605                	lui	a2,0x1
    8000173e:	85ca                	mv	a1,s2
    80001740:	8556                	mv	a0,s5
    80001742:	00000097          	auipc	ra,0x0
    80001746:	c3a080e7          	jalr	-966(ra) # 8000137c <mappages>
    8000174a:	e90d                	bnez	a0,8000177c <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000174c:	6785                	lui	a5,0x1
    8000174e:	993e                	add	s2,s2,a5
    80001750:	fd4968e3          	bltu	s2,s4,80001720 <uvmalloc+0x32>
  return newsz;
    80001754:	8552                	mv	a0,s4
    80001756:	a809                	j	80001768 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001758:	864e                	mv	a2,s3
    8000175a:	85ca                	mv	a1,s2
    8000175c:	8556                	mv	a0,s5
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	f48080e7          	jalr	-184(ra) # 800016a6 <uvmdealloc>
      return 0;
    80001766:	4501                	li	a0,0
}
    80001768:	70e2                	ld	ra,56(sp)
    8000176a:	7442                	ld	s0,48(sp)
    8000176c:	74a2                	ld	s1,40(sp)
    8000176e:	7902                	ld	s2,32(sp)
    80001770:	69e2                	ld	s3,24(sp)
    80001772:	6a42                	ld	s4,16(sp)
    80001774:	6aa2                	ld	s5,8(sp)
    80001776:	6b02                	ld	s6,0(sp)
    80001778:	6121                	addi	sp,sp,64
    8000177a:	8082                	ret
      kfree(mem);
    8000177c:	8526                	mv	a0,s1
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	418080e7          	jalr	1048(ra) # 80000b96 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001786:	864e                	mv	a2,s3
    80001788:	85ca                	mv	a1,s2
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	f1a080e7          	jalr	-230(ra) # 800016a6 <uvmdealloc>
      return 0;
    80001794:	4501                	li	a0,0
    80001796:	bfc9                	j	80001768 <uvmalloc+0x7a>
    return oldsz;
    80001798:	852e                	mv	a0,a1
}
    8000179a:	8082                	ret
  return newsz;
    8000179c:	8532                	mv	a0,a2
    8000179e:	b7e9                	j	80001768 <uvmalloc+0x7a>

00000000800017a0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800017a0:	7179                	addi	sp,sp,-48
    800017a2:	f406                	sd	ra,40(sp)
    800017a4:	f022                	sd	s0,32(sp)
    800017a6:	ec26                	sd	s1,24(sp)
    800017a8:	e84a                	sd	s2,16(sp)
    800017aa:	e44e                	sd	s3,8(sp)
    800017ac:	e052                	sd	s4,0(sp)
    800017ae:	1800                	addi	s0,sp,48
    800017b0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800017b2:	84aa                	mv	s1,a0
    800017b4:	6905                	lui	s2,0x1
    800017b6:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800017b8:	4985                	li	s3,1
    800017ba:	a821                	j	800017d2 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800017bc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800017be:	0532                	slli	a0,a0,0xc
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	fe0080e7          	jalr	-32(ra) # 800017a0 <freewalk>
      pagetable[i] = 0;
    800017c8:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    800017cc:	04a1                	addi	s1,s1,8
    800017ce:	03248163          	beq	s1,s2,800017f0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800017d2:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800017d4:	00f57793          	andi	a5,a0,15
    800017d8:	ff3782e3          	beq	a5,s3,800017bc <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    800017dc:	8905                	andi	a0,a0,1
    800017de:	d57d                	beqz	a0,800017cc <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    800017e0:	00008517          	auipc	a0,0x8
    800017e4:	9d050513          	addi	a0,a0,-1584 # 800091b0 <digits+0x170>
    800017e8:	fffff097          	auipc	ra,0xfffff
    800017ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>
    }
  }
  kfree((void *)pagetable);
    800017f0:	8552                	mv	a0,s4
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	3a4080e7          	jalr	932(ra) # 80000b96 <kfree>
}
    800017fa:	70a2                	ld	ra,40(sp)
    800017fc:	7402                	ld	s0,32(sp)
    800017fe:	64e2                	ld	s1,24(sp)
    80001800:	6942                	ld	s2,16(sp)
    80001802:	69a2                	ld	s3,8(sp)
    80001804:	6a02                	ld	s4,0(sp)
    80001806:	6145                	addi	sp,sp,48
    80001808:	8082                	ret

000000008000180a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000180a:	1101                	addi	sp,sp,-32
    8000180c:	ec06                	sd	ra,24(sp)
    8000180e:	e822                	sd	s0,16(sp)
    80001810:	e426                	sd	s1,8(sp)
    80001812:	1000                	addi	s0,sp,32
    80001814:	84aa                	mv	s1,a0
  if (sz > 0)
    80001816:	e999                	bnez	a1,8000182c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001818:	8526                	mv	a0,s1
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	f86080e7          	jalr	-122(ra) # 800017a0 <freewalk>
}
    80001822:	60e2                	ld	ra,24(sp)
    80001824:	6442                	ld	s0,16(sp)
    80001826:	64a2                	ld	s1,8(sp)
    80001828:	6105                	addi	sp,sp,32
    8000182a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    8000182c:	6605                	lui	a2,0x1
    8000182e:	167d                	addi	a2,a2,-1
    80001830:	962e                	add	a2,a2,a1
    80001832:	4685                	li	a3,1
    80001834:	8231                	srli	a2,a2,0xc
    80001836:	4581                	li	a1,0
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	d0a080e7          	jalr	-758(ra) # 80001542 <uvmunmap>
    80001840:	bfe1                	j	80001818 <uvmfree+0xe>

0000000080001842 <uvmcopy>:
  uint flags;
  // char *mem;

  int ok=1;

  for (i = 0; i < sz; i += PGSIZE)
    80001842:	ca69                	beqz	a2,80001914 <uvmcopy+0xd2>
{
    80001844:	7139                	addi	sp,sp,-64
    80001846:	fc06                	sd	ra,56(sp)
    80001848:	f822                	sd	s0,48(sp)
    8000184a:	f426                	sd	s1,40(sp)
    8000184c:	f04a                	sd	s2,32(sp)
    8000184e:	ec4e                	sd	s3,24(sp)
    80001850:	e852                	sd	s4,16(sp)
    80001852:	e456                	sd	s5,8(sp)
    80001854:	e05a                	sd	s6,0(sp)
    80001856:	0080                	addi	s0,sp,64
    80001858:	8aaa                	mv	s5,a0
    8000185a:	8a2e                	mv	s4,a1
    8000185c:	89b2                	mv	s3,a2
  for (i = 0; i < sz; i += PGSIZE)
    8000185e:	4481                	li	s1,0
    pa = PTE2PA(*pte);

    if (flags & PTE_W)
    {
      flags = (flags & (~PTE_W)) | PTE_C;
      *pte = PA2PTE(pa) | flags;
    80001860:	7b7d                	lui	s6,0xfffff
    80001862:	002b5b13          	srli	s6,s6,0x2
    80001866:	a099                	j	800018ac <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    80001868:	00008517          	auipc	a0,0x8
    8000186c:	95850513          	addi	a0,a0,-1704 # 800091c0 <digits+0x180>
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	cd4080e7          	jalr	-812(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    80001878:	00008517          	auipc	a0,0x8
    8000187c:	96850513          	addi	a0,a0,-1688 # 800091e0 <digits+0x1a0>
    80001880:	fffff097          	auipc	ra,0xfffff
    80001884:	cc4080e7          	jalr	-828(ra) # 80000544 <panic>
    }
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001888:	86ca                	mv	a3,s2
    8000188a:	6605                	lui	a2,0x1
    8000188c:	85a6                	mv	a1,s1
    8000188e:	8552                	mv	a0,s4
    80001890:	00000097          	auipc	ra,0x0
    80001894:	aec080e7          	jalr	-1300(ra) # 8000137c <mappages>
    80001898:	e921                	bnez	a0,800018e8 <uvmcopy+0xa6>
    {
      ok=0;
      break;
    }
    inc_page_ref((void*)pa);
    8000189a:	854a                	mv	a0,s2
    8000189c:	fffff097          	auipc	ra,0xfffff
    800018a0:	230080e7          	jalr	560(ra) # 80000acc <inc_page_ref>
  for (i = 0; i < sz; i += PGSIZE)
    800018a4:	6785                	lui	a5,0x1
    800018a6:	94be                	add	s1,s1,a5
    800018a8:	0534fb63          	bgeu	s1,s3,800018fe <uvmcopy+0xbc>
    if ((pte = walk(old, i, 0)) == 0)
    800018ac:	4601                	li	a2,0
    800018ae:	85a6                	mv	a1,s1
    800018b0:	8556                	mv	a0,s5
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	9e2080e7          	jalr	-1566(ra) # 80001294 <walk>
    800018ba:	d55d                	beqz	a0,80001868 <uvmcopy+0x26>
    if ((*pte & PTE_V) == 0)
    800018bc:	611c                	ld	a5,0(a0)
    800018be:	0017f713          	andi	a4,a5,1
    800018c2:	db5d                	beqz	a4,80001878 <uvmcopy+0x36>
    flags = PTE_FLAGS(*pte);
    800018c4:	0007869b          	sext.w	a3,a5
    800018c8:	3ff7f713          	andi	a4,a5,1023
    pa = PTE2PA(*pte);
    800018cc:	00a7d913          	srli	s2,a5,0xa
    800018d0:	0932                	slli	s2,s2,0xc
    if (flags & PTE_W)
    800018d2:	8a91                	andi	a3,a3,4
    800018d4:	dad5                	beqz	a3,80001888 <uvmcopy+0x46>
      flags = (flags & (~PTE_W)) | PTE_C;
    800018d6:	fdb77693          	andi	a3,a4,-37
    800018da:	0206e713          	ori	a4,a3,32
      *pte = PA2PTE(pa) | flags;
    800018de:	0167f7b3          	and	a5,a5,s6
    800018e2:	8fd9                	or	a5,a5,a4
    800018e4:	e11c                	sd	a5,0(a0)
    800018e6:	b74d                	j	80001888 <uvmcopy+0x46>
  }
  if(ok)
  return 0;

  uvmunmap(new, 0, i / PGSIZE, 1);
    800018e8:	4685                	li	a3,1
    800018ea:	00c4d613          	srli	a2,s1,0xc
    800018ee:	4581                	li	a1,0
    800018f0:	8552                	mv	a0,s4
    800018f2:	00000097          	auipc	ra,0x0
    800018f6:	c50080e7          	jalr	-944(ra) # 80001542 <uvmunmap>
  return -1;
    800018fa:	557d                	li	a0,-1
    800018fc:	a011                	j	80001900 <uvmcopy+0xbe>
  return 0;
    800018fe:	4501                	li	a0,0
}
    80001900:	70e2                	ld	ra,56(sp)
    80001902:	7442                	ld	s0,48(sp)
    80001904:	74a2                	ld	s1,40(sp)
    80001906:	7902                	ld	s2,32(sp)
    80001908:	69e2                	ld	s3,24(sp)
    8000190a:	6a42                	ld	s4,16(sp)
    8000190c:	6aa2                	ld	s5,8(sp)
    8000190e:	6b02                	ld	s6,0(sp)
    80001910:	6121                	addi	sp,sp,64
    80001912:	8082                	ret
  return 0;
    80001914:	4501                	li	a0,0
}
    80001916:	8082                	ret

0000000080001918 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001918:	1141                	addi	sp,sp,-16
    8000191a:	e406                	sd	ra,8(sp)
    8000191c:	e022                	sd	s0,0(sp)
    8000191e:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001920:	4601                	li	a2,0
    80001922:	00000097          	auipc	ra,0x0
    80001926:	972080e7          	jalr	-1678(ra) # 80001294 <walk>
  if (pte == 0)
    8000192a:	c901                	beqz	a0,8000193a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000192c:	611c                	ld	a5,0(a0)
    8000192e:	9bbd                	andi	a5,a5,-17
    80001930:	e11c                	sd	a5,0(a0)
}
    80001932:	60a2                	ld	ra,8(sp)
    80001934:	6402                	ld	s0,0(sp)
    80001936:	0141                	addi	sp,sp,16
    80001938:	8082                	ret
    panic("uvmclear");
    8000193a:	00008517          	auipc	a0,0x8
    8000193e:	8c650513          	addi	a0,a0,-1850 # 80009200 <digits+0x1c0>
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	c02080e7          	jalr	-1022(ra) # 80000544 <panic>

000000008000194a <copyout>:

int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0, flags;
  pte_t *pte;
  while (len > 0)
    8000194a:	c2d5                	beqz	a3,800019ee <copyout+0xa4>
{
    8000194c:	711d                	addi	sp,sp,-96
    8000194e:	ec86                	sd	ra,88(sp)
    80001950:	e8a2                	sd	s0,80(sp)
    80001952:	e4a6                	sd	s1,72(sp)
    80001954:	e0ca                	sd	s2,64(sp)
    80001956:	fc4e                	sd	s3,56(sp)
    80001958:	f852                	sd	s4,48(sp)
    8000195a:	f456                	sd	s5,40(sp)
    8000195c:	f05a                	sd	s6,32(sp)
    8000195e:	ec5e                	sd	s7,24(sp)
    80001960:	e862                	sd	s8,16(sp)
    80001962:	e466                	sd	s9,8(sp)
    80001964:	1080                	addi	s0,sp,96
    80001966:	8baa                	mv	s7,a0
    80001968:	89ae                	mv	s3,a1
    8000196a:	8b32                	mv	s6,a2
    8000196c:	8ab6                	mv	s5,a3
  {
    va0 = PGROUNDDOWN(dstva);
    8000196e:	7cfd                	lui	s9,0xfffff
    if (flags & PTE_C)
    {
      page_fault_handler((void *)va0, pagetable);
      pa0 = walkaddr(pagetable, va0);
    }
    n = PGSIZE - (dstva - va0);
    80001970:	6c05                	lui	s8,0x1
    80001972:	a081                	j	800019b2 <copyout+0x68>
      page_fault_handler((void *)va0, pagetable);
    80001974:	85de                	mv	a1,s7
    80001976:	854a                	mv	a0,s2
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	3e6080e7          	jalr	998(ra) # 80000d5e <page_fault_handler>
      pa0 = walkaddr(pagetable, va0);
    80001980:	85ca                	mv	a1,s2
    80001982:	855e                	mv	a0,s7
    80001984:	00000097          	auipc	ra,0x0
    80001988:	9b6080e7          	jalr	-1610(ra) # 8000133a <walkaddr>
    8000198c:	8a2a                	mv	s4,a0
    8000198e:	a0b9                	j	800019dc <copyout+0x92>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001990:	41298533          	sub	a0,s3,s2
    80001994:	0004861b          	sext.w	a2,s1
    80001998:	85da                	mv	a1,s6
    8000199a:	9552                	add	a0,a0,s4
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	66c080e7          	jalr	1644(ra) # 80001008 <memmove>

    len -= n;
    800019a4:	409a8ab3          	sub	s5,s5,s1
    src += n;
    800019a8:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    800019aa:	018909b3          	add	s3,s2,s8
  while (len > 0)
    800019ae:	020a8e63          	beqz	s5,800019ea <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800019b2:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    800019b6:	85ca                	mv	a1,s2
    800019b8:	855e                	mv	a0,s7
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	980080e7          	jalr	-1664(ra) # 8000133a <walkaddr>
    800019c2:	8a2a                	mv	s4,a0
    if (pa0 == 0)
    800019c4:	c51d                	beqz	a0,800019f2 <copyout+0xa8>
    pte = walk(pagetable, va0, 0);
    800019c6:	4601                	li	a2,0
    800019c8:	85ca                	mv	a1,s2
    800019ca:	855e                	mv	a0,s7
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	8c8080e7          	jalr	-1848(ra) # 80001294 <walk>
    if (flags & PTE_C)
    800019d4:	611c                	ld	a5,0(a0)
    800019d6:	0207f793          	andi	a5,a5,32
    800019da:	ffc9                	bnez	a5,80001974 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800019dc:	413904b3          	sub	s1,s2,s3
    800019e0:	94e2                	add	s1,s1,s8
    if (n > len)
    800019e2:	fa9af7e3          	bgeu	s5,s1,80001990 <copyout+0x46>
    800019e6:	84d6                	mv	s1,s5
    800019e8:	b765                	j	80001990 <copyout+0x46>
  }
  return 0;
    800019ea:	4501                	li	a0,0
    800019ec:	a021                	j	800019f4 <copyout+0xaa>
    800019ee:	4501                	li	a0,0
}
    800019f0:	8082                	ret
      return -1;
    800019f2:	557d                	li	a0,-1
}
    800019f4:	60e6                	ld	ra,88(sp)
    800019f6:	6446                	ld	s0,80(sp)
    800019f8:	64a6                	ld	s1,72(sp)
    800019fa:	6906                	ld	s2,64(sp)
    800019fc:	79e2                	ld	s3,56(sp)
    800019fe:	7a42                	ld	s4,48(sp)
    80001a00:	7aa2                	ld	s5,40(sp)
    80001a02:	7b02                	ld	s6,32(sp)
    80001a04:	6be2                	ld	s7,24(sp)
    80001a06:	6c42                	ld	s8,16(sp)
    80001a08:	6ca2                	ld	s9,8(sp)
    80001a0a:	6125                	addi	sp,sp,96
    80001a0c:	8082                	ret

0000000080001a0e <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001a0e:	c6bd                	beqz	a3,80001a7c <copyin+0x6e>
{
    80001a10:	715d                	addi	sp,sp,-80
    80001a12:	e486                	sd	ra,72(sp)
    80001a14:	e0a2                	sd	s0,64(sp)
    80001a16:	fc26                	sd	s1,56(sp)
    80001a18:	f84a                	sd	s2,48(sp)
    80001a1a:	f44e                	sd	s3,40(sp)
    80001a1c:	f052                	sd	s4,32(sp)
    80001a1e:	ec56                	sd	s5,24(sp)
    80001a20:	e85a                	sd	s6,16(sp)
    80001a22:	e45e                	sd	s7,8(sp)
    80001a24:	e062                	sd	s8,0(sp)
    80001a26:	0880                	addi	s0,sp,80
    80001a28:	8b2a                	mv	s6,a0
    80001a2a:	8a2e                	mv	s4,a1
    80001a2c:	8c32                	mv	s8,a2
    80001a2e:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001a30:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a32:	6a85                	lui	s5,0x1
    80001a34:	a015                	j	80001a58 <copyin+0x4a>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001a36:	9562                	add	a0,a0,s8
    80001a38:	0004861b          	sext.w	a2,s1
    80001a3c:	412505b3          	sub	a1,a0,s2
    80001a40:	8552                	mv	a0,s4
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	5c6080e7          	jalr	1478(ra) # 80001008 <memmove>

    len -= n;
    80001a4a:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001a4e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001a50:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001a54:	02098263          	beqz	s3,80001a78 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001a58:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a5c:	85ca                	mv	a1,s2
    80001a5e:	855a                	mv	a0,s6
    80001a60:	00000097          	auipc	ra,0x0
    80001a64:	8da080e7          	jalr	-1830(ra) # 8000133a <walkaddr>
    if (pa0 == 0)
    80001a68:	cd01                	beqz	a0,80001a80 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001a6a:	418904b3          	sub	s1,s2,s8
    80001a6e:	94d6                	add	s1,s1,s5
    if (n > len)
    80001a70:	fc99f3e3          	bgeu	s3,s1,80001a36 <copyin+0x28>
    80001a74:	84ce                	mv	s1,s3
    80001a76:	b7c1                	j	80001a36 <copyin+0x28>
  }
  return 0;
    80001a78:	4501                	li	a0,0
    80001a7a:	a021                	j	80001a82 <copyin+0x74>
    80001a7c:	4501                	li	a0,0
}
    80001a7e:	8082                	ret
      return -1;
    80001a80:	557d                	li	a0,-1
}
    80001a82:	60a6                	ld	ra,72(sp)
    80001a84:	6406                	ld	s0,64(sp)
    80001a86:	74e2                	ld	s1,56(sp)
    80001a88:	7942                	ld	s2,48(sp)
    80001a8a:	79a2                	ld	s3,40(sp)
    80001a8c:	7a02                	ld	s4,32(sp)
    80001a8e:	6ae2                	ld	s5,24(sp)
    80001a90:	6b42                	ld	s6,16(sp)
    80001a92:	6ba2                	ld	s7,8(sp)
    80001a94:	6c02                	ld	s8,0(sp)
    80001a96:	6161                	addi	sp,sp,80
    80001a98:	8082                	ret

0000000080001a9a <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001a9a:	c6c5                	beqz	a3,80001b42 <copyinstr+0xa8>
{
    80001a9c:	715d                	addi	sp,sp,-80
    80001a9e:	e486                	sd	ra,72(sp)
    80001aa0:	e0a2                	sd	s0,64(sp)
    80001aa2:	fc26                	sd	s1,56(sp)
    80001aa4:	f84a                	sd	s2,48(sp)
    80001aa6:	f44e                	sd	s3,40(sp)
    80001aa8:	f052                	sd	s4,32(sp)
    80001aaa:	ec56                	sd	s5,24(sp)
    80001aac:	e85a                	sd	s6,16(sp)
    80001aae:	e45e                	sd	s7,8(sp)
    80001ab0:	0880                	addi	s0,sp,80
    80001ab2:	8a2a                	mv	s4,a0
    80001ab4:	8b2e                	mv	s6,a1
    80001ab6:	8bb2                	mv	s7,a2
    80001ab8:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001aba:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001abc:	6985                	lui	s3,0x1
    80001abe:	a035                	j	80001aea <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001ac0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001ac4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001ac6:	0017b793          	seqz	a5,a5
    80001aca:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001ace:	60a6                	ld	ra,72(sp)
    80001ad0:	6406                	ld	s0,64(sp)
    80001ad2:	74e2                	ld	s1,56(sp)
    80001ad4:	7942                	ld	s2,48(sp)
    80001ad6:	79a2                	ld	s3,40(sp)
    80001ad8:	7a02                	ld	s4,32(sp)
    80001ada:	6ae2                	ld	s5,24(sp)
    80001adc:	6b42                	ld	s6,16(sp)
    80001ade:	6ba2                	ld	s7,8(sp)
    80001ae0:	6161                	addi	sp,sp,80
    80001ae2:	8082                	ret
    srcva = va0 + PGSIZE;
    80001ae4:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001ae8:	c8a9                	beqz	s1,80001b3a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001aea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001aee:	85ca                	mv	a1,s2
    80001af0:	8552                	mv	a0,s4
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	848080e7          	jalr	-1976(ra) # 8000133a <walkaddr>
    if (pa0 == 0)
    80001afa:	c131                	beqz	a0,80001b3e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001afc:	41790833          	sub	a6,s2,s7
    80001b00:	984e                	add	a6,a6,s3
    if (n > max)
    80001b02:	0104f363          	bgeu	s1,a6,80001b08 <copyinstr+0x6e>
    80001b06:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001b08:	955e                	add	a0,a0,s7
    80001b0a:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001b0e:	fc080be3          	beqz	a6,80001ae4 <copyinstr+0x4a>
    80001b12:	985a                	add	a6,a6,s6
    80001b14:	87da                	mv	a5,s6
      if (*p == '\0')
    80001b16:	41650633          	sub	a2,a0,s6
    80001b1a:	14fd                	addi	s1,s1,-1
    80001b1c:	9b26                	add	s6,s6,s1
    80001b1e:	00f60733          	add	a4,a2,a5
    80001b22:	00074703          	lbu	a4,0(a4)
    80001b26:	df49                	beqz	a4,80001ac0 <copyinstr+0x26>
        *dst = *p;
    80001b28:	00e78023          	sb	a4,0(a5)
      --max;
    80001b2c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001b30:	0785                	addi	a5,a5,1
    while (n > 0)
    80001b32:	ff0796e3          	bne	a5,a6,80001b1e <copyinstr+0x84>
      dst++;
    80001b36:	8b42                	mv	s6,a6
    80001b38:	b775                	j	80001ae4 <copyinstr+0x4a>
    80001b3a:	4781                	li	a5,0
    80001b3c:	b769                	j	80001ac6 <copyinstr+0x2c>
      return -1;
    80001b3e:	557d                	li	a0,-1
    80001b40:	b779                	j	80001ace <copyinstr+0x34>
  int got_null = 0;
    80001b42:	4781                	li	a5,0
  if (got_null)
    80001b44:	0017b793          	seqz	a5,a5
    80001b48:	40f00533          	neg	a0,a5
}
    80001b4c:	8082                	ret

0000000080001b4e <my_max>:
#ifdef MLFQ
struct Queue mlfq[NMLFQ];
#endif

int my_max(int a, int b)
{
    80001b4e:	1141                	addi	sp,sp,-16
    80001b50:	e422                	sd	s0,8(sp)
    80001b52:	0800                	addi	s0,sp,16
  if (a > b)
    80001b54:	87aa                	mv	a5,a0
    80001b56:	00b55363          	bge	a0,a1,80001b5c <my_max+0xe>
    80001b5a:	87ae                	mv	a5,a1
    return a;
  return b;
}
    80001b5c:	0007851b          	sext.w	a0,a5
    80001b60:	6422                	ld	s0,8(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret

0000000080001b66 <mine_min>:
int mine_min(int a, int b)
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e422                	sd	s0,8(sp)
    80001b6a:	0800                	addi	s0,sp,16
  if (a < b)
    80001b6c:	87aa                	mv	a5,a0
    80001b6e:	00a5d363          	bge	a1,a0,80001b74 <mine_min+0xe>
    80001b72:	87ae                	mv	a5,a1
    return a;
  return b;
}
    80001b74:	0007851b          	sext.w	a0,a5
    80001b78:	6422                	ld	s0,8(sp)
    80001b7a:	0141                	addi	sp,sp,16
    80001b7c:	8082                	ret

0000000080001b7e <proc_mapstacks>:
//   p->nice_pro1 = n;
//   all_tickets += p->nice_pro1;
// }

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001b7e:	7139                	addi	sp,sp,-64
    80001b80:	fc06                	sd	ra,56(sp)
    80001b82:	f822                	sd	s0,48(sp)
    80001b84:	f426                	sd	s1,40(sp)
    80001b86:	f04a                	sd	s2,32(sp)
    80001b88:	ec4e                	sd	s3,24(sp)
    80001b8a:	e852                	sd	s4,16(sp)
    80001b8c:	e456                	sd	s5,8(sp)
    80001b8e:	e05a                	sd	s6,0(sp)
    80001b90:	0080                	addi	s0,sp,64
    80001b92:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	00230497          	auipc	s1,0x230
    80001b98:	2a448493          	addi	s1,s1,676 # 80231e38 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001b9c:	8b26                	mv	s6,s1
    80001b9e:	00007a97          	auipc	s5,0x7
    80001ba2:	462a8a93          	addi	s5,s5,1122 # 80009000 <etext>
    80001ba6:	04000937          	lui	s2,0x4000
    80001baa:	197d                	addi	s2,s2,-1
    80001bac:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bae:	00238a17          	auipc	s4,0x238
    80001bb2:	e8aa0a13          	addi	s4,s4,-374 # 80239a38 <cpus>
    char *pa = kalloc();
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	13e080e7          	jalr	318(ra) # 80000cf4 <kalloc>
    80001bbe:	862a                	mv	a2,a0
    if (pa == 0)
    80001bc0:	c131                	beqz	a0,80001c04 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001bc2:	416485b3          	sub	a1,s1,s6
    80001bc6:	8591                	srai	a1,a1,0x4
    80001bc8:	000ab783          	ld	a5,0(s5)
    80001bcc:	02f585b3          	mul	a1,a1,a5
    80001bd0:	2585                	addiw	a1,a1,1
    80001bd2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bd6:	4719                	li	a4,6
    80001bd8:	6685                	lui	a3,0x1
    80001bda:	40b905b3          	sub	a1,s2,a1
    80001bde:	854e                	mv	a0,s3
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	83c080e7          	jalr	-1988(ra) # 8000141c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be8:	1f048493          	addi	s1,s1,496
    80001bec:	fd4495e3          	bne	s1,s4,80001bb6 <proc_mapstacks+0x38>
  }
}
    80001bf0:	70e2                	ld	ra,56(sp)
    80001bf2:	7442                	ld	s0,48(sp)
    80001bf4:	74a2                	ld	s1,40(sp)
    80001bf6:	7902                	ld	s2,32(sp)
    80001bf8:	69e2                	ld	s3,24(sp)
    80001bfa:	6a42                	ld	s4,16(sp)
    80001bfc:	6aa2                	ld	s5,8(sp)
    80001bfe:	6b02                	ld	s6,0(sp)
    80001c00:	6121                	addi	sp,sp,64
    80001c02:	8082                	ret
      panic("kalloc");
    80001c04:	00007517          	auipc	a0,0x7
    80001c08:	60c50513          	addi	a0,a0,1548 # 80009210 <digits+0x1d0>
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	938080e7          	jalr	-1736(ra) # 80000544 <panic>

0000000080001c14 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001c14:	7139                	addi	sp,sp,-64
    80001c16:	fc06                	sd	ra,56(sp)
    80001c18:	f822                	sd	s0,48(sp)
    80001c1a:	f426                	sd	s1,40(sp)
    80001c1c:	f04a                	sd	s2,32(sp)
    80001c1e:	ec4e                	sd	s3,24(sp)
    80001c20:	e852                	sd	s4,16(sp)
    80001c22:	e456                	sd	s5,8(sp)
    80001c24:	e05a                	sd	s6,0(sp)
    80001c26:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001c28:	00007597          	auipc	a1,0x7
    80001c2c:	5f058593          	addi	a1,a1,1520 # 80009218 <digits+0x1d8>
    80001c30:	00230517          	auipc	a0,0x230
    80001c34:	1d850513          	addi	a0,a0,472 # 80231e08 <pid_lock>
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	1e4080e7          	jalr	484(ra) # 80000e1c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c40:	00007597          	auipc	a1,0x7
    80001c44:	5e058593          	addi	a1,a1,1504 # 80009220 <digits+0x1e0>
    80001c48:	00230517          	auipc	a0,0x230
    80001c4c:	1d850513          	addi	a0,a0,472 # 80231e20 <wait_lock>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	1cc080e7          	jalr	460(ra) # 80000e1c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c58:	00230497          	auipc	s1,0x230
    80001c5c:	1e048493          	addi	s1,s1,480 # 80231e38 <proc>
  {
    initlock(&p->lock, "proc");
    80001c60:	00007b17          	auipc	s6,0x7
    80001c64:	5d0b0b13          	addi	s6,s6,1488 # 80009230 <digits+0x1f0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001c68:	8aa6                	mv	s5,s1
    80001c6a:	00007a17          	auipc	s4,0x7
    80001c6e:	396a0a13          	addi	s4,s4,918 # 80009000 <etext>
    80001c72:	04000937          	lui	s2,0x4000
    80001c76:	197d                	addi	s2,s2,-1
    80001c78:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001c7a:	00238997          	auipc	s3,0x238
    80001c7e:	dbe98993          	addi	s3,s3,-578 # 80239a38 <cpus>
    initlock(&p->lock, "proc");
    80001c82:	85da                	mv	a1,s6
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	196080e7          	jalr	406(ra) # 80000e1c <initlock>
    p->state = UNUSED;
    80001c8e:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001c92:	415487b3          	sub	a5,s1,s5
    80001c96:	8791                	srai	a5,a5,0x4
    80001c98:	000a3703          	ld	a4,0(s4)
    80001c9c:	02e787b3          	mul	a5,a5,a4
    80001ca0:	2785                	addiw	a5,a5,1
    80001ca2:	00d7979b          	slliw	a5,a5,0xd
    80001ca6:	40f907b3          	sub	a5,s2,a5
    80001caa:	e4bc                	sd	a5,72(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001cac:	1f048493          	addi	s1,s1,496
    80001cb0:	fd3499e3          	bne	s1,s3,80001c82 <procinit+0x6e>
    80001cb4:	00239797          	auipc	a5,0x239
    80001cb8:	84478793          	addi	a5,a5,-1980 # 8023a4f8 <mlfq>
    80001cbc:	00239717          	auipc	a4,0x239
    80001cc0:	2b470713          	addi	a4,a4,692 # 8023af70 <tickslock>
  }

#ifdef MLFQ
  for (int i = 0; i < NMLFQ; i++)
  {
    mlfq[i].size = 0;
    80001cc4:	2007a823          	sw	zero,528(a5)
    mlfq[i].head = 0;
    80001cc8:	0007a023          	sw	zero,0(a5)
    mlfq[i].tail = 0;
    80001ccc:	0007a223          	sw	zero,4(a5)
  for (int i = 0; i < NMLFQ; i++)
    80001cd0:	21878793          	addi	a5,a5,536
    80001cd4:	fee798e3          	bne	a5,a4,80001cc4 <procinit+0xb0>
  }
#endif
}
    80001cd8:	70e2                	ld	ra,56(sp)
    80001cda:	7442                	ld	s0,48(sp)
    80001cdc:	74a2                	ld	s1,40(sp)
    80001cde:	7902                	ld	s2,32(sp)
    80001ce0:	69e2                	ld	s3,24(sp)
    80001ce2:	6a42                	ld	s4,16(sp)
    80001ce4:	6aa2                	ld	s5,8(sp)
    80001ce6:	6b02                	ld	s6,0(sp)
    80001ce8:	6121                	addi	sp,sp,64
    80001cea:	8082                	ret

0000000080001cec <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001cec:	1141                	addi	sp,sp,-16
    80001cee:	e422                	sd	s0,8(sp)
    80001cf0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cf2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cf4:	2501                	sext.w	a0,a0
    80001cf6:	6422                	ld	s0,8(sp)
    80001cf8:	0141                	addi	sp,sp,16
    80001cfa:	8082                	ret

0000000080001cfc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001cfc:	1141                	addi	sp,sp,-16
    80001cfe:	e422                	sd	s0,8(sp)
    80001d00:	0800                	addi	s0,sp,16
    80001d02:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d04:	2781                	sext.w	a5,a5
    80001d06:	15800513          	li	a0,344
    80001d0a:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001d0e:	00238517          	auipc	a0,0x238
    80001d12:	d2a50513          	addi	a0,a0,-726 # 80239a38 <cpus>
    80001d16:	953e                	add	a0,a0,a5
    80001d18:	6422                	ld	s0,8(sp)
    80001d1a:	0141                	addi	sp,sp,16
    80001d1c:	8082                	ret

0000000080001d1e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	1000                	addi	s0,sp,32
  push_off();
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	138080e7          	jalr	312(ra) # 80000e60 <push_off>
    80001d30:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d32:	2781                	sext.w	a5,a5
    80001d34:	15800713          	li	a4,344
    80001d38:	02e787b3          	mul	a5,a5,a4
    80001d3c:	00238717          	auipc	a4,0x238
    80001d40:	cfc70713          	addi	a4,a4,-772 # 80239a38 <cpus>
    80001d44:	97ba                	add	a5,a5,a4
    80001d46:	6384                	ld	s1,0(a5)
  pop_off();
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	1b8080e7          	jalr	440(ra) # 80000f00 <pop_off>
  return p;
}
    80001d50:	8526                	mv	a0,s1
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6105                	addi	sp,sp,32
    80001d5a:	8082                	ret

0000000080001d5c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d5c:	1141                	addi	sp,sp,-16
    80001d5e:	e406                	sd	ra,8(sp)
    80001d60:	e022                	sd	s0,0(sp)
    80001d62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	fba080e7          	jalr	-70(ra) # 80001d1e <myproc>
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	1f4080e7          	jalr	500(ra) # 80000f60 <release>

  if (first)
    80001d74:	00008797          	auipc	a5,0x8
    80001d78:	d5c7a783          	lw	a5,-676(a5) # 80009ad0 <first.1880>
    80001d7c:	eb89                	bnez	a5,80001d8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d7e:	00001097          	auipc	ra,0x1
    80001d82:	454080e7          	jalr	1108(ra) # 800031d2 <usertrapret>
}
    80001d86:	60a2                	ld	ra,8(sp)
    80001d88:	6402                	ld	s0,0(sp)
    80001d8a:	0141                	addi	sp,sp,16
    80001d8c:	8082                	ret
    first = 0;
    80001d8e:	00008797          	auipc	a5,0x8
    80001d92:	d407a123          	sw	zero,-702(a5) # 80009ad0 <first.1880>
    fsinit(ROOTDEV);
    80001d96:	4505                	li	a0,1
    80001d98:	00002097          	auipc	ra,0x2
    80001d9c:	73c080e7          	jalr	1852(ra) # 800044d4 <fsinit>
    80001da0:	bff9                	j	80001d7e <forkret+0x22>

0000000080001da2 <allocpid>:
{
    80001da2:	1101                	addi	sp,sp,-32
    80001da4:	ec06                	sd	ra,24(sp)
    80001da6:	e822                	sd	s0,16(sp)
    80001da8:	e426                	sd	s1,8(sp)
    80001daa:	e04a                	sd	s2,0(sp)
    80001dac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dae:	00230917          	auipc	s2,0x230
    80001db2:	05a90913          	addi	s2,s2,90 # 80231e08 <pid_lock>
    80001db6:	854a                	mv	a0,s2
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	0f4080e7          	jalr	244(ra) # 80000eac <acquire>
  pid = nextpid;
    80001dc0:	00008797          	auipc	a5,0x8
    80001dc4:	d1478793          	addi	a5,a5,-748 # 80009ad4 <nextpid>
    80001dc8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dca:	0014871b          	addiw	a4,s1,1
    80001dce:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dd0:	854a                	mv	a0,s2
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	18e080e7          	jalr	398(ra) # 80000f60 <release>
}
    80001dda:	8526                	mv	a0,s1
    80001ddc:	60e2                	ld	ra,24(sp)
    80001dde:	6442                	ld	s0,16(sp)
    80001de0:	64a2                	ld	s1,8(sp)
    80001de2:	6902                	ld	s2,0(sp)
    80001de4:	6105                	addi	sp,sp,32
    80001de6:	8082                	ret

0000000080001de8 <proc_priority>:
{
    80001de8:	1141                	addi	sp,sp,-16
    80001dea:	e422                	sd	s0,8(sp)
    80001dec:	0800                	addi	s0,sp,16
  if (process->ticks_last_scheduled != 0) // if the process hasnt been scheduled yet before
    80001dee:	1a852703          	lw	a4,424(a0)
  int nice = 5;
    80001df2:	4795                	li	a5,5
  if (process->ticks_last_scheduled != 0) // if the process hasnt been scheduled yet before
    80001df4:	c31d                	beqz	a4,80001e1a <proc_priority+0x32>
    if (process->num_run != 0)
    80001df6:	1a452703          	lw	a4,420(a0)
    80001dfa:	c305                	beqz	a4,80001e1a <proc_priority+0x32>
      int time_diff = process->last_run + process->last_sleep;
    80001dfc:	1b052683          	lw	a3,432(a0)
    80001e00:	1ac52703          	lw	a4,428(a0)
    80001e04:	9f35                	addw	a4,a4,a3
    80001e06:	0007061b          	sext.w	a2,a4
      if (time_diff != 0)
    80001e0a:	ca01                	beqz	a2,80001e1a <proc_priority+0x32>
        nice = ((sleeping) / (time_diff)) * 10;
    80001e0c:	02e6c73b          	divw	a4,a3,a4
    80001e10:	0027179b          	slliw	a5,a4,0x2
    80001e14:	9fb9                	addw	a5,a5,a4
    80001e16:	0017979b          	slliw	a5,a5,0x1
  if (mine_min(process->priority - nice + 5, 1001) > 0)
    80001e1a:	1a052503          	lw	a0,416(a0)
    80001e1e:	2515                	addiw	a0,a0,5
    80001e20:	9d1d                	subw	a0,a0,a5
    80001e22:	0005071b          	sext.w	a4,a0
    80001e26:	06400793          	li	a5,100
    80001e2a:	00e7d463          	bge	a5,a4,80001e32 <proc_priority+0x4a>
    80001e2e:	06400513          	li	a0,100
    80001e32:	0005079b          	sext.w	a5,a0
    80001e36:	fff7c793          	not	a5,a5
    80001e3a:	97fd                	srai	a5,a5,0x3f
    80001e3c:	8d7d                	and	a0,a0,a5
}
    80001e3e:	2501                	sext.w	a0,a0
    80001e40:	6422                	ld	s0,8(sp)
    80001e42:	0141                	addi	sp,sp,16
    80001e44:	8082                	ret

0000000080001e46 <set_priority>:
{
    80001e46:	7179                	addi	sp,sp,-48
    80001e48:	f406                	sd	ra,40(sp)
    80001e4a:	f022                	sd	s0,32(sp)
    80001e4c:	ec26                	sd	s1,24(sp)
    80001e4e:	e84a                	sd	s2,16(sp)
    80001e50:	e44e                	sd	s3,8(sp)
    80001e52:	e052                	sd	s4,0(sp)
    80001e54:	1800                	addi	s0,sp,48
  if (new_static_priority < 0)
    80001e56:	04054c63          	bltz	a0,80001eae <set_priority+0x68>
    80001e5a:	8a2a                	mv	s4,a0
    80001e5c:	892e                	mv	s2,a1
  if (new_static_priority > 100)
    80001e5e:	06400793          	li	a5,100
  p = proc;
    80001e62:	00230497          	auipc	s1,0x230
    80001e66:	fd648493          	addi	s1,s1,-42 # 80231e38 <proc>
  while (p < &proc[NPROC])
    80001e6a:	00238997          	auipc	s3,0x238
    80001e6e:	bce98993          	addi	s3,s3,-1074 # 80239a38 <cpus>
  if (new_static_priority > 100)
    80001e72:	04a7c863          	blt	a5,a0,80001ec2 <set_priority+0x7c>
    acquire(&p->lock);
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	034080e7          	jalr	52(ra) # 80000eac <acquire>
    if (p->pid == proc_pid)
    80001e80:	589c                	lw	a5,48(s1)
    80001e82:	05278a63          	beq	a5,s2,80001ed6 <set_priority+0x90>
    release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	0d8080e7          	jalr	216(ra) # 80000f60 <release>
    p++;
    80001e90:	1f048493          	addi	s1,s1,496
  while (p < &proc[NPROC])
    80001e94:	ff3491e3          	bne	s1,s3,80001e76 <set_priority+0x30>
    printf("no process with pid : %d exists\n", proc_pid);
    80001e98:	85ca                	mv	a1,s2
    80001e9a:	00007517          	auipc	a0,0x7
    80001e9e:	40e50513          	addi	a0,a0,1038 # 800092a8 <digits+0x268>
    80001ea2:	ffffe097          	auipc	ra,0xffffe
    80001ea6:	6ec080e7          	jalr	1772(ra) # 8000058e <printf>
  int old_static_priority = -1;
    80001eaa:	59fd                	li	s3,-1
    80001eac:	a899                	j	80001f02 <set_priority+0xbc>
    printf("<new_static_priority> should be in range [0 - 100]\n");
    80001eae:	00007517          	auipc	a0,0x7
    80001eb2:	38a50513          	addi	a0,a0,906 # 80009238 <digits+0x1f8>
    80001eb6:	ffffe097          	auipc	ra,0xffffe
    80001eba:	6d8080e7          	jalr	1752(ra) # 8000058e <printf>
    return -1;
    80001ebe:	59fd                	li	s3,-1
    80001ec0:	a089                	j	80001f02 <set_priority+0xbc>
    printf("<new_static_priority> should be in range [0 - 100]\n");
    80001ec2:	00007517          	auipc	a0,0x7
    80001ec6:	37650513          	addi	a0,a0,886 # 80009238 <digits+0x1f8>
    80001eca:	ffffe097          	auipc	ra,0xffffe
    80001ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    return -1;
    80001ed2:	59fd                	li	s3,-1
    80001ed4:	a03d                	j	80001f02 <set_priority+0xbc>
      old_static_priority = p->priority;
    80001ed6:	1a04a983          	lw	s3,416(s1)
      p->priority = new_static_priority;
    80001eda:	1b44a023          	sw	s4,416(s1)
    printf("priority of proc wit pid : %d changed from %d to %d \n", p->pid, old_static_priority, new_static_priority);
    80001ede:	86d2                	mv	a3,s4
    80001ee0:	864e                	mv	a2,s3
    80001ee2:	85ca                	mv	a1,s2
    80001ee4:	00007517          	auipc	a0,0x7
    80001ee8:	38c50513          	addi	a0,a0,908 # 80009270 <digits+0x230>
    80001eec:	ffffe097          	auipc	ra,0xffffe
    80001ef0:	6a2080e7          	jalr	1698(ra) # 8000058e <printf>
    release(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	06a080e7          	jalr	106(ra) # 80000f60 <release>
    if (old_static_priority < new_static_priority)
    80001efe:	0149cb63          	blt	s3,s4,80001f14 <set_priority+0xce>
}
    80001f02:	854e                	mv	a0,s3
    80001f04:	70a2                	ld	ra,40(sp)
    80001f06:	7402                	ld	s0,32(sp)
    80001f08:	64e2                	ld	s1,24(sp)
    80001f0a:	6942                	ld	s2,16(sp)
    80001f0c:	69a2                	ld	s3,8(sp)
    80001f0e:	6a02                	ld	s4,0(sp)
    80001f10:	6145                	addi	sp,sp,48
    80001f12:	8082                	ret
      p->last_run = 0;
    80001f14:	1a04a623          	sw	zero,428(s1)
      p->last_sleep = 0;
    80001f18:	1a04a823          	sw	zero,432(s1)
    80001f1c:	b7dd                	j	80001f02 <set_priority+0xbc>

0000000080001f1e <proc_pagetable>:
{
    80001f1e:	1101                	addi	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	e426                	sd	s1,8(sp)
    80001f26:	e04a                	sd	s2,0(sp)
    80001f28:	1000                	addi	s0,sp,32
    80001f2a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	6da080e7          	jalr	1754(ra) # 80001606 <uvmcreate>
    80001f34:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f36:	c121                	beqz	a0,80001f76 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f38:	4729                	li	a4,10
    80001f3a:	00006697          	auipc	a3,0x6
    80001f3e:	0c668693          	addi	a3,a3,198 # 80008000 <_trampoline>
    80001f42:	6605                	lui	a2,0x1
    80001f44:	040005b7          	lui	a1,0x4000
    80001f48:	15fd                	addi	a1,a1,-1
    80001f4a:	05b2                	slli	a1,a1,0xc
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	430080e7          	jalr	1072(ra) # 8000137c <mappages>
    80001f54:	02054863          	bltz	a0,80001f84 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f58:	4719                	li	a4,6
    80001f5a:	06093683          	ld	a3,96(s2)
    80001f5e:	6605                	lui	a2,0x1
    80001f60:	020005b7          	lui	a1,0x2000
    80001f64:	15fd                	addi	a1,a1,-1
    80001f66:	05b6                	slli	a1,a1,0xd
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	412080e7          	jalr	1042(ra) # 8000137c <mappages>
    80001f72:	02054163          	bltz	a0,80001f94 <proc_pagetable+0x76>
}
    80001f76:	8526                	mv	a0,s1
    80001f78:	60e2                	ld	ra,24(sp)
    80001f7a:	6442                	ld	s0,16(sp)
    80001f7c:	64a2                	ld	s1,8(sp)
    80001f7e:	6902                	ld	s2,0(sp)
    80001f80:	6105                	addi	sp,sp,32
    80001f82:	8082                	ret
    uvmfree(pagetable, 0);
    80001f84:	4581                	li	a1,0
    80001f86:	8526                	mv	a0,s1
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	882080e7          	jalr	-1918(ra) # 8000180a <uvmfree>
    return 0;
    80001f90:	4481                	li	s1,0
    80001f92:	b7d5                	j	80001f76 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f94:	4681                	li	a3,0
    80001f96:	4605                	li	a2,1
    80001f98:	040005b7          	lui	a1,0x4000
    80001f9c:	15fd                	addi	a1,a1,-1
    80001f9e:	05b2                	slli	a1,a1,0xc
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	5a0080e7          	jalr	1440(ra) # 80001542 <uvmunmap>
    uvmfree(pagetable, 0);
    80001faa:	4581                	li	a1,0
    80001fac:	8526                	mv	a0,s1
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	85c080e7          	jalr	-1956(ra) # 8000180a <uvmfree>
    return 0;
    80001fb6:	4481                	li	s1,0
    80001fb8:	bf7d                	j	80001f76 <proc_pagetable+0x58>

0000000080001fba <proc_freepagetable>:
{
    80001fba:	1101                	addi	sp,sp,-32
    80001fbc:	ec06                	sd	ra,24(sp)
    80001fbe:	e822                	sd	s0,16(sp)
    80001fc0:	e426                	sd	s1,8(sp)
    80001fc2:	e04a                	sd	s2,0(sp)
    80001fc4:	1000                	addi	s0,sp,32
    80001fc6:	84aa                	mv	s1,a0
    80001fc8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fca:	4681                	li	a3,0
    80001fcc:	4605                	li	a2,1
    80001fce:	040005b7          	lui	a1,0x4000
    80001fd2:	15fd                	addi	a1,a1,-1
    80001fd4:	05b2                	slli	a1,a1,0xc
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	56c080e7          	jalr	1388(ra) # 80001542 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fde:	4681                	li	a3,0
    80001fe0:	4605                	li	a2,1
    80001fe2:	020005b7          	lui	a1,0x2000
    80001fe6:	15fd                	addi	a1,a1,-1
    80001fe8:	05b6                	slli	a1,a1,0xd
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	556080e7          	jalr	1366(ra) # 80001542 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ff4:	85ca                	mv	a1,s2
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	812080e7          	jalr	-2030(ra) # 8000180a <uvmfree>
}
    80002000:	60e2                	ld	ra,24(sp)
    80002002:	6442                	ld	s0,16(sp)
    80002004:	64a2                	ld	s1,8(sp)
    80002006:	6902                	ld	s2,0(sp)
    80002008:	6105                	addi	sp,sp,32
    8000200a:	8082                	ret

000000008000200c <freeproc>:
{
    8000200c:	1101                	addi	sp,sp,-32
    8000200e:	ec06                	sd	ra,24(sp)
    80002010:	e822                	sd	s0,16(sp)
    80002012:	e426                	sd	s1,8(sp)
    80002014:	1000                	addi	s0,sp,32
    80002016:	84aa                	mv	s1,a0
  if (p->trapframe)
    80002018:	7128                	ld	a0,96(a0)
    8000201a:	c509                	beqz	a0,80002024 <freeproc+0x18>
    kfree((void *)p->trapframe);
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	b7a080e7          	jalr	-1158(ra) # 80000b96 <kfree>
  if (p->trapframe_copy)
    80002024:	1884b503          	ld	a0,392(s1)
    80002028:	c509                	beqz	a0,80002032 <freeproc+0x26>
    kfree((void *)p->trapframe_copy);
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	b6c080e7          	jalr	-1172(ra) # 80000b96 <kfree>
  p->trapframe = 0;
    80002032:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80002036:	6ca8                	ld	a0,88(s1)
    80002038:	c511                	beqz	a0,80002044 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    8000203a:	68ac                	ld	a1,80(s1)
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	f7e080e7          	jalr	-130(ra) # 80001fba <proc_freepagetable>
  p->pagetable = 0;
    80002044:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80002048:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    8000204c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002050:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80002054:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80002058:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000205c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002060:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002064:	0004ac23          	sw	zero,24(s1)
}
    80002068:	60e2                	ld	ra,24(sp)
    8000206a:	6442                	ld	s0,16(sp)
    8000206c:	64a2                	ld	s1,8(sp)
    8000206e:	6105                	addi	sp,sp,32
    80002070:	8082                	ret

0000000080002072 <allocproc>:
{
    80002072:	1101                	addi	sp,sp,-32
    80002074:	ec06                	sd	ra,24(sp)
    80002076:	e822                	sd	s0,16(sp)
    80002078:	e426                	sd	s1,8(sp)
    8000207a:	e04a                	sd	s2,0(sp)
    8000207c:	1000                	addi	s0,sp,32
  p = proc;
    8000207e:	00230497          	auipc	s1,0x230
    80002082:	dba48493          	addi	s1,s1,-582 # 80231e38 <proc>
  while (p < &proc[NPROC])
    80002086:	00238917          	auipc	s2,0x238
    8000208a:	9b290913          	addi	s2,s2,-1614 # 80239a38 <cpus>
    acquire(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	e1c080e7          	jalr	-484(ra) # 80000eac <acquire>
    if (p->state == UNUSED)
    80002098:	4c9c                	lw	a5,24(s1)
    8000209a:	cbb9                	beqz	a5,800020f0 <allocproc+0x7e>
      release(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	ec2080e7          	jalr	-318(ra) # 80000f60 <release>
    p++;
    800020a6:	1f048493          	addi	s1,s1,496
  while (p < &proc[NPROC])
    800020aa:	ff2492e3          	bne	s1,s2,8000208e <allocproc+0x1c>
    return 0;
    800020ae:	4481                	li	s1,0
    800020b0:	a201                	j	800021b0 <allocproc+0x13e>
    freeproc(p);
    800020b2:	8526                	mv	a0,s1
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	f58080e7          	jalr	-168(ra) # 8000200c <freeproc>
    release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	ea2080e7          	jalr	-350(ra) # 80000f60 <release>
  return 0;
    800020c6:	84ca                	mv	s1,s2
    800020c8:	a0e5                	j	800021b0 <allocproc+0x13e>
      freeproc(p);
    800020ca:	8526                	mv	a0,s1
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	f40080e7          	jalr	-192(ra) # 8000200c <freeproc>
      release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	e8a080e7          	jalr	-374(ra) # 80000f60 <release>
      return 0;
    800020de:	84ca                	mv	s1,s2
    800020e0:	a8c1                	j	800021b0 <allocproc+0x13e>
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	e7c080e7          	jalr	-388(ra) # 80000f60 <release>
      return 0;
    800020ec:	84ca                	mv	s1,s2
    800020ee:	a0c9                	j	800021b0 <allocproc+0x13e>
  p->pid = allocpid();
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	cb2080e7          	jalr	-846(ra) # 80001da2 <allocpid>
    800020f8:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020fa:	4785                	li	a5,1
    800020fc:	cc9c                	sw	a5,24(s1)
  p->priority = 60;
    800020fe:	03c00793          	li	a5,60
    80002102:	1af4a023          	sw	a5,416(s1)
  p->tick = 0;
    80002106:	1a04ac23          	sw	zero,440(s1)
  p->ticket = InitialTickets; // initially
    8000210a:	4795                	li	a5,5
    8000210c:	1af4aa23          	sw	a5,436(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	be4080e7          	jalr	-1052(ra) # 80000cf4 <kalloc>
    80002118:	892a                	mv	s2,a0
    8000211a:	f0a8                	sd	a0,96(s1)
    8000211c:	d959                	beqz	a0,800020b2 <allocproc+0x40>
    p->pagetable = proc_pagetable(p);
    8000211e:	8526                	mv	a0,s1
    80002120:	00000097          	auipc	ra,0x0
    80002124:	dfe080e7          	jalr	-514(ra) # 80001f1e <proc_pagetable>
    80002128:	892a                	mv	s2,a0
    8000212a:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    8000212c:	dd59                	beqz	a0,800020ca <allocproc+0x58>
    if ((p->trapframe_copy = (struct trapframe *)kalloc()) == 0)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	bc6080e7          	jalr	-1082(ra) # 80000cf4 <kalloc>
    80002136:	892a                	mv	s2,a0
    80002138:	18a4b423          	sd	a0,392(s1)
    8000213c:	d15d                	beqz	a0,800020e2 <allocproc+0x70>
    p->handler = 0;
    8000213e:	1804b023          	sd	zero,384(s1)
    p->is_sigalarm = 0;
    80002142:	1604a823          	sw	zero,368(s1)
    p->now_ticks = 0;
    80002146:	1604ac23          	sw	zero,376(s1)
    p->ticks = 0;
    8000214a:	1604aa23          	sw	zero,372(s1)
    memset(&p->context, 0, sizeof(p->context));
    8000214e:	07000613          	li	a2,112
    80002152:	4581                	li	a1,0
    80002154:	06848513          	addi	a0,s1,104
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	e50080e7          	jalr	-432(ra) # 80000fa8 <memset>
    p->context.ra = (uint64)forkret;
    80002160:	00000797          	auipc	a5,0x0
    80002164:	bfc78793          	addi	a5,a5,-1028 # 80001d5c <forkret>
    80002168:	f4bc                	sd	a5,104(s1)
    p->etime = 0;
    8000216a:	1c04a423          	sw	zero,456(s1)
    p->ctime = ticks;
    8000216e:	00008717          	auipc	a4,0x8
    80002172:	a0a72703          	lw	a4,-1526(a4) # 80009b78 <ticks>
    80002176:	1ce4a223          	sw	a4,452(s1)
    p->context.sp = p->kstack + PGSIZE;
    8000217a:	64bc                	ld	a5,72(s1)
    8000217c:	6685                	lui	a3,0x1
    8000217e:	97b6                	add	a5,a5,a3
    80002180:	f8bc                	sd	a5,112(s1)
    p->rtime = 0;
    80002182:	1c04a023          	sw	zero,448(s1)
    p->priority = 0;
    80002186:	1a04a023          	sw	zero,416(s1)
    p->in_queue = 0;
    8000218a:	1c04a623          	sw	zero,460(s1)
    p->quanta = 1;
    8000218e:	4785                	li	a5,1
    80002190:	1cf4a823          	sw	a5,464(s1)
    p->nrun = 0;
    80002194:	1c04aa23          	sw	zero,468(s1)
    p->qitime = ticks;
    80002198:	1ce4ac23          	sw	a4,472(s1)
      p->qrtime[i] = 0;
    8000219c:	1c04ae23          	sw	zero,476(s1)
    800021a0:	1e04a023          	sw	zero,480(s1)
    800021a4:	1e04a223          	sw	zero,484(s1)
    800021a8:	1e04a423          	sw	zero,488(s1)
    800021ac:	1e04a623          	sw	zero,492(s1)
}
    800021b0:	8526                	mv	a0,s1
    800021b2:	60e2                	ld	ra,24(sp)
    800021b4:	6442                	ld	s0,16(sp)
    800021b6:	64a2                	ld	s1,8(sp)
    800021b8:	6902                	ld	s2,0(sp)
    800021ba:	6105                	addi	sp,sp,32
    800021bc:	8082                	ret

00000000800021be <userinit>:
{
    800021be:	1101                	addi	sp,sp,-32
    800021c0:	ec06                	sd	ra,24(sp)
    800021c2:	e822                	sd	s0,16(sp)
    800021c4:	e426                	sd	s1,8(sp)
    800021c6:	1000                	addi	s0,sp,32
  p = allocproc();
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	eaa080e7          	jalr	-342(ra) # 80002072 <allocproc>
    800021d0:	84aa                	mv	s1,a0
  initproc = p;
    800021d2:	00008797          	auipc	a5,0x8
    800021d6:	98a7bf23          	sd	a0,-1634(a5) # 80009b70 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    800021da:	03400613          	li	a2,52
    800021de:	00008597          	auipc	a1,0x8
    800021e2:	90258593          	addi	a1,a1,-1790 # 80009ae0 <initcode>
    800021e6:	6d28                	ld	a0,88(a0)
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	44c080e7          	jalr	1100(ra) # 80001634 <uvmfirst>
  p->sz = PGSIZE;
    800021f0:	6785                	lui	a5,0x1
    800021f2:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;     // user program counter
    800021f4:	70b8                	ld	a4,96(s1)
    800021f6:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    800021fa:	70b8                	ld	a4,96(s1)
    800021fc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021fe:	4641                	li	a2,16
    80002200:	00007597          	auipc	a1,0x7
    80002204:	0d058593          	addi	a1,a1,208 # 800092d0 <digits+0x290>
    80002208:	16048513          	addi	a0,s1,352
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	eee080e7          	jalr	-274(ra) # 800010fa <safestrcpy>
  p->cwd = namei("/");
    80002214:	00007517          	auipc	a0,0x7
    80002218:	0cc50513          	addi	a0,a0,204 # 800092e0 <digits+0x2a0>
    8000221c:	00003097          	auipc	ra,0x3
    80002220:	cda080e7          	jalr	-806(ra) # 80004ef6 <namei>
    80002224:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002228:	478d                	li	a5,3
    8000222a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	d32080e7          	jalr	-718(ra) # 80000f60 <release>
}
    80002236:	60e2                	ld	ra,24(sp)
    80002238:	6442                	ld	s0,16(sp)
    8000223a:	64a2                	ld	s1,8(sp)
    8000223c:	6105                	addi	sp,sp,32
    8000223e:	8082                	ret

0000000080002240 <growproc>:
{
    80002240:	1101                	addi	sp,sp,-32
    80002242:	ec06                	sd	ra,24(sp)
    80002244:	e822                	sd	s0,16(sp)
    80002246:	e426                	sd	s1,8(sp)
    80002248:	e04a                	sd	s2,0(sp)
    8000224a:	1000                	addi	s0,sp,32
    8000224c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	ad0080e7          	jalr	-1328(ra) # 80001d1e <myproc>
    80002256:	84aa                	mv	s1,a0
  sz = p->sz;
    80002258:	692c                	ld	a1,80(a0)
  if (n > 0)
    8000225a:	01204c63          	bgtz	s2,80002272 <growproc+0x32>
  else if (n < 0)
    8000225e:	02094663          	bltz	s2,8000228a <growproc+0x4a>
  p->sz = sz;
    80002262:	e8ac                	sd	a1,80(s1)
  return 0;
    80002264:	4501                	li	a0,0
}
    80002266:	60e2                	ld	ra,24(sp)
    80002268:	6442                	ld	s0,16(sp)
    8000226a:	64a2                	ld	s1,8(sp)
    8000226c:	6902                	ld	s2,0(sp)
    8000226e:	6105                	addi	sp,sp,32
    80002270:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002272:	4691                	li	a3,4
    80002274:	00b90633          	add	a2,s2,a1
    80002278:	6d28                	ld	a0,88(a0)
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	474080e7          	jalr	1140(ra) # 800016ee <uvmalloc>
    80002282:	85aa                	mv	a1,a0
    80002284:	fd79                	bnez	a0,80002262 <growproc+0x22>
      return -1;
    80002286:	557d                	li	a0,-1
    80002288:	bff9                	j	80002266 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000228a:	00b90633          	add	a2,s2,a1
    8000228e:	6d28                	ld	a0,88(a0)
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	416080e7          	jalr	1046(ra) # 800016a6 <uvmdealloc>
    80002298:	85aa                	mv	a1,a0
    8000229a:	b7e1                	j	80002262 <growproc+0x22>

000000008000229c <fork>:
{
    8000229c:	7179                	addi	sp,sp,-48
    8000229e:	f406                	sd	ra,40(sp)
    800022a0:	f022                	sd	s0,32(sp)
    800022a2:	ec26                	sd	s1,24(sp)
    800022a4:	e84a                	sd	s2,16(sp)
    800022a6:	e44e                	sd	s3,8(sp)
    800022a8:	e052                	sd	s4,0(sp)
    800022aa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	a72080e7          	jalr	-1422(ra) # 80001d1e <myproc>
    800022b4:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	dbc080e7          	jalr	-580(ra) # 80002072 <allocproc>
    800022be:	10050f63          	beqz	a0,800023dc <fork+0x140>
    800022c2:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800022c4:	05093603          	ld	a2,80(s2)
    800022c8:	6d2c                	ld	a1,88(a0)
    800022ca:	05893503          	ld	a0,88(s2)
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	574080e7          	jalr	1396(ra) # 80001842 <uvmcopy>
    800022d6:	04054a63          	bltz	a0,8000232a <fork+0x8e>
  np->sz = p->sz;
    800022da:	05093783          	ld	a5,80(s2)
    800022de:	04f9b823          	sd	a5,80(s3)
  np->ticket = p->ticket;
    800022e2:	1b492783          	lw	a5,436(s2)
    800022e6:	1af9aa23          	sw	a5,436(s3)
  *(np->trapframe) = *(p->trapframe);
    800022ea:	06093683          	ld	a3,96(s2)
    800022ee:	87b6                	mv	a5,a3
    800022f0:	0609b703          	ld	a4,96(s3)
    800022f4:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800022f8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022fc:	6788                	ld	a0,8(a5)
    800022fe:	6b8c                	ld	a1,16(a5)
    80002300:	6f90                	ld	a2,24(a5)
    80002302:	01073023          	sd	a6,0(a4)
    80002306:	e708                	sd	a0,8(a4)
    80002308:	eb0c                	sd	a1,16(a4)
    8000230a:	ef10                	sd	a2,24(a4)
    8000230c:	02078793          	addi	a5,a5,32
    80002310:	02070713          	addi	a4,a4,32
    80002314:	fed792e3          	bne	a5,a3,800022f8 <fork+0x5c>
  np->trapframe->a0 = 0;
    80002318:	0609b783          	ld	a5,96(s3)
    8000231c:	0607b823          	sd	zero,112(a5)
    80002320:	0d800493          	li	s1,216
  for (i = 0; i < NOFILE; i++)
    80002324:	15800a13          	li	s4,344
    80002328:	a03d                	j	80002356 <fork+0xba>
    freeproc(np);
    8000232a:	854e                	mv	a0,s3
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	ce0080e7          	jalr	-800(ra) # 8000200c <freeproc>
    release(&np->lock);
    80002334:	854e                	mv	a0,s3
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	c2a080e7          	jalr	-982(ra) # 80000f60 <release>
    return -1;
    8000233e:	5a7d                	li	s4,-1
    80002340:	a069                	j	800023ca <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002342:	00003097          	auipc	ra,0x3
    80002346:	24a080e7          	jalr	586(ra) # 8000558c <filedup>
    8000234a:	009987b3          	add	a5,s3,s1
    8000234e:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002350:	04a1                	addi	s1,s1,8
    80002352:	01448763          	beq	s1,s4,80002360 <fork+0xc4>
    if (p->ofile[i])
    80002356:	009907b3          	add	a5,s2,s1
    8000235a:	6388                	ld	a0,0(a5)
    8000235c:	f17d                	bnez	a0,80002342 <fork+0xa6>
    8000235e:	bfcd                	j	80002350 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002360:	15893503          	ld	a0,344(s2)
    80002364:	00002097          	auipc	ra,0x2
    80002368:	3ae080e7          	jalr	942(ra) # 80004712 <idup>
    8000236c:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002370:	4641                	li	a2,16
    80002372:	16090593          	addi	a1,s2,352
    80002376:	16098513          	addi	a0,s3,352
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	d80080e7          	jalr	-640(ra) # 800010fa <safestrcpy>
  pid = np->pid;
    80002382:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002386:	854e                	mv	a0,s3
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	bd8080e7          	jalr	-1064(ra) # 80000f60 <release>
  acquire(&wait_lock);
    80002390:	00230497          	auipc	s1,0x230
    80002394:	a9048493          	addi	s1,s1,-1392 # 80231e20 <wait_lock>
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	b12080e7          	jalr	-1262(ra) # 80000eac <acquire>
  np->parent = p;
    800023a2:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	bb8080e7          	jalr	-1096(ra) # 80000f60 <release>
  acquire(&np->lock);
    800023b0:	854e                	mv	a0,s3
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	afa080e7          	jalr	-1286(ra) # 80000eac <acquire>
  np->state = RUNNABLE;
    800023ba:	478d                	li	a5,3
    800023bc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800023c0:	854e                	mv	a0,s3
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	b9e080e7          	jalr	-1122(ra) # 80000f60 <release>
}
    800023ca:	8552                	mv	a0,s4
    800023cc:	70a2                	ld	ra,40(sp)
    800023ce:	7402                	ld	s0,32(sp)
    800023d0:	64e2                	ld	s1,24(sp)
    800023d2:	6942                	ld	s2,16(sp)
    800023d4:	69a2                	ld	s3,8(sp)
    800023d6:	6a02                	ld	s4,0(sp)
    800023d8:	6145                	addi	sp,sp,48
    800023da:	8082                	ret
    return -1;
    800023dc:	5a7d                	li	s4,-1
    800023de:	b7f5                	j	800023ca <fork+0x12e>

00000000800023e0 <getpinfo>:
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	892a                	mv	s2,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800023f0:	00230497          	auipc	s1,0x230
    800023f4:	a4848493          	addi	s1,s1,-1464 # 80231e38 <proc>
    800023f8:	00237997          	auipc	s3,0x237
    800023fc:	64098993          	addi	s3,s3,1600 # 80239a38 <cpus>
    acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	aaa080e7          	jalr	-1366(ra) # 80000eac <acquire>
    ps->pid[i] = p->pid;
    8000240a:	589c                	lw	a5,48(s1)
    8000240c:	20f92023          	sw	a5,512(s2)
    ps->inuse[i] = p->state != UNUSED;
    80002410:	4c9c                	lw	a5,24(s1)
    80002412:	00f037b3          	snez	a5,a5
    80002416:	00f92023          	sw	a5,0(s2)
    ps->ticket[i] = p->ticket;
    8000241a:	1b44a783          	lw	a5,436(s1)
    8000241e:	10f92023          	sw	a5,256(s2)
    ps->tick[i] = p->tick;
    80002422:	1b84a783          	lw	a5,440(s1)
    80002426:	30f92023          	sw	a5,768(s2)
    release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	b34080e7          	jalr	-1228(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002434:	1f048493          	addi	s1,s1,496
    80002438:	0911                	addi	s2,s2,4
    8000243a:	fd3493e3          	bne	s1,s3,80002400 <getpinfo+0x20>
}
    8000243e:	4501                	li	a0,0
    80002440:	70a2                	ld	ra,40(sp)
    80002442:	7402                	ld	s0,32(sp)
    80002444:	64e2                	ld	s1,24(sp)
    80002446:	6942                	ld	s2,16(sp)
    80002448:	69a2                	ld	s3,8(sp)
    8000244a:	6145                	addi	sp,sp,48
    8000244c:	8082                	ret

000000008000244e <getRunnableProcTickets>:
{
    8000244e:	1141                	addi	sp,sp,-16
    80002450:	e422                	sd	s0,8(sp)
    80002452:	0800                	addi	s0,sp,16
  int total = 0;
    80002454:	4501                	li	a0,0
  for (p = proc; p < &proc[NPROC]; p++)
    80002456:	00230797          	auipc	a5,0x230
    8000245a:	9e278793          	addi	a5,a5,-1566 # 80231e38 <proc>
    if (p->state == RUNNABLE)
    8000245e:	460d                	li	a2,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002460:	00237697          	auipc	a3,0x237
    80002464:	5d868693          	addi	a3,a3,1496 # 80239a38 <cpus>
    80002468:	a029                	j	80002472 <getRunnableProcTickets+0x24>
    8000246a:	1f078793          	addi	a5,a5,496
    8000246e:	00d78963          	beq	a5,a3,80002480 <getRunnableProcTickets+0x32>
    if (p->state == RUNNABLE)
    80002472:	4f98                	lw	a4,24(a5)
    80002474:	fec71be3          	bne	a4,a2,8000246a <getRunnableProcTickets+0x1c>
      total += p->ticket;
    80002478:	1b47a703          	lw	a4,436(a5)
    8000247c:	9d39                	addw	a0,a0,a4
    8000247e:	b7f5                	j	8000246a <getRunnableProcTickets+0x1c>
}
    80002480:	6422                	ld	s0,8(sp)
    80002482:	0141                	addi	sp,sp,16
    80002484:	8082                	ret

0000000080002486 <settickets>:
{
    80002486:	7179                	addi	sp,sp,-48
    80002488:	f406                	sd	ra,40(sp)
    8000248a:	f022                	sd	s0,32(sp)
    8000248c:	ec26                	sd	s1,24(sp)
    8000248e:	e84a                	sd	s2,16(sp)
    80002490:	e44e                	sd	s3,8(sp)
    80002492:	e052                	sd	s4,0(sp)
    80002494:	1800                	addi	s0,sp,48
    80002496:	8a2a                	mv	s4,a0
  struct proc *pr = myproc();
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	886080e7          	jalr	-1914(ra) # 80001d1e <myproc>
  int pid = pr->pid;
    800024a0:	03052903          	lw	s2,48(a0)
  for (p = proc; p < &proc[NPROC]; p++)
    800024a4:	00230497          	auipc	s1,0x230
    800024a8:	99448493          	addi	s1,s1,-1644 # 80231e38 <proc>
    800024ac:	00237997          	auipc	s3,0x237
    800024b0:	58c98993          	addi	s3,s3,1420 # 80239a38 <cpus>
    acquire(&p->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	9f6080e7          	jalr	-1546(ra) # 80000eac <acquire>
    if (p->pid == pid)
    800024be:	589c                	lw	a5,48(s1)
    800024c0:	01278c63          	beq	a5,s2,800024d8 <settickets+0x52>
    release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	a9a080e7          	jalr	-1382(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024ce:	1f048493          	addi	s1,s1,496
    800024d2:	ff3491e3          	bne	s1,s3,800024b4 <settickets+0x2e>
    800024d6:	a801                	j	800024e6 <settickets+0x60>
      p->ticket = number; // assigining alloted ticket for a process
    800024d8:	1b44aa23          	sw	s4,436(s1)
      release(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	a82080e7          	jalr	-1406(ra) # 80000f60 <release>
}
    800024e6:	4501                	li	a0,0
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6a02                	ld	s4,0(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret

00000000800024f8 <sched>:
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002508:	00000097          	auipc	ra,0x0
    8000250c:	816080e7          	jalr	-2026(ra) # 80001d1e <myproc>
    80002510:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	920080e7          	jalr	-1760(ra) # 80000e32 <holding>
    8000251a:	c141                	beqz	a0,8000259a <sched+0xa2>
    8000251c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000251e:	2781                	sext.w	a5,a5
    80002520:	15800713          	li	a4,344
    80002524:	02e787b3          	mul	a5,a5,a4
    80002528:	00237717          	auipc	a4,0x237
    8000252c:	51070713          	addi	a4,a4,1296 # 80239a38 <cpus>
    80002530:	97ba                	add	a5,a5,a4
    80002532:	5fb8                	lw	a4,120(a5)
    80002534:	4785                	li	a5,1
    80002536:	06f71a63          	bne	a4,a5,800025aa <sched+0xb2>
  if (p->state == RUNNING)
    8000253a:	4c98                	lw	a4,24(s1)
    8000253c:	4791                	li	a5,4
    8000253e:	06f70e63          	beq	a4,a5,800025ba <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002542:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002546:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002548:	e3c9                	bnez	a5,800025ca <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000254a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000254c:	00237917          	auipc	s2,0x237
    80002550:	4ec90913          	addi	s2,s2,1260 # 80239a38 <cpus>
    80002554:	2781                	sext.w	a5,a5
    80002556:	15800993          	li	s3,344
    8000255a:	033787b3          	mul	a5,a5,s3
    8000255e:	97ca                	add	a5,a5,s2
    80002560:	07c7aa03          	lw	s4,124(a5)
    80002564:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002566:	2581                	sext.w	a1,a1
    80002568:	033585b3          	mul	a1,a1,s3
    8000256c:	05a1                	addi	a1,a1,8
    8000256e:	95ca                	add	a1,a1,s2
    80002570:	06848513          	addi	a0,s1,104
    80002574:	00001097          	auipc	ra,0x1
    80002578:	bb4080e7          	jalr	-1100(ra) # 80003128 <swtch>
    8000257c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000257e:	2781                	sext.w	a5,a5
    80002580:	033787b3          	mul	a5,a5,s3
    80002584:	993e                	add	s2,s2,a5
    80002586:	07492e23          	sw	s4,124(s2)
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    panic("sched p->lock");
    8000259a:	00007517          	auipc	a0,0x7
    8000259e:	d4e50513          	addi	a0,a0,-690 # 800092e8 <digits+0x2a8>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fa2080e7          	jalr	-94(ra) # 80000544 <panic>
    panic("sched locks");
    800025aa:	00007517          	auipc	a0,0x7
    800025ae:	d4e50513          	addi	a0,a0,-690 # 800092f8 <digits+0x2b8>
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	f92080e7          	jalr	-110(ra) # 80000544 <panic>
    panic("sched running");
    800025ba:	00007517          	auipc	a0,0x7
    800025be:	d4e50513          	addi	a0,a0,-690 # 80009308 <digits+0x2c8>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	f82080e7          	jalr	-126(ra) # 80000544 <panic>
    panic("sched interruptible");
    800025ca:	00007517          	auipc	a0,0x7
    800025ce:	d4e50513          	addi	a0,a0,-690 # 80009318 <digits+0x2d8>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	f72080e7          	jalr	-142(ra) # 80000544 <panic>

00000000800025da <yield>:
{
    800025da:	1101                	addi	sp,sp,-32
    800025dc:	ec06                	sd	ra,24(sp)
    800025de:	e822                	sd	s0,16(sp)
    800025e0:	e426                	sd	s1,8(sp)
    800025e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	73a080e7          	jalr	1850(ra) # 80001d1e <myproc>
    800025ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	8be080e7          	jalr	-1858(ra) # 80000eac <acquire>
  p->state = RUNNABLE;
    800025f6:	478d                	li	a5,3
    800025f8:	cc9c                	sw	a5,24(s1)
  sched();
    800025fa:	00000097          	auipc	ra,0x0
    800025fe:	efe080e7          	jalr	-258(ra) # 800024f8 <sched>
  release(&p->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	95c080e7          	jalr	-1700(ra) # 80000f60 <release>
}
    8000260c:	60e2                	ld	ra,24(sp)
    8000260e:	6442                	ld	s0,16(sp)
    80002610:	64a2                	ld	s1,8(sp)
    80002612:	6105                	addi	sp,sp,32
    80002614:	8082                	ret

0000000080002616 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	1800                	addi	s0,sp,48
    80002624:	89aa                	mv	s3,a0
    80002626:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	6f6080e7          	jalr	1782(ra) # 80001d1e <myproc>
    80002630:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	87a080e7          	jalr	-1926(ra) # 80000eac <acquire>
  release(lk);
    8000263a:	854a                	mv	a0,s2
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	924080e7          	jalr	-1756(ra) # 80000f60 <release>

  // Go to sleep.
  p->chan = chan;
    80002644:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002648:	4789                	li	a5,2
    8000264a:	cc9c                	sw	a5,24(s1)

  sched();
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	eac080e7          	jalr	-340(ra) # 800024f8 <sched>

  // Tidy up.
  p->chan = 0;
    80002654:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	fffff097          	auipc	ra,0xfffff
    8000265e:	906080e7          	jalr	-1786(ra) # 80000f60 <release>
  acquire(lk);
    80002662:	854a                	mv	a0,s2
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	848080e7          	jalr	-1976(ra) # 80000eac <acquire>
}
    8000266c:	70a2                	ld	ra,40(sp)
    8000266e:	7402                	ld	s0,32(sp)
    80002670:	64e2                	ld	s1,24(sp)
    80002672:	6942                	ld	s2,16(sp)
    80002674:	69a2                	ld	s3,8(sp)
    80002676:	6145                	addi	sp,sp,48
    80002678:	8082                	ret

000000008000267a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000267a:	7139                	addi	sp,sp,-64
    8000267c:	fc06                	sd	ra,56(sp)
    8000267e:	f822                	sd	s0,48(sp)
    80002680:	f426                	sd	s1,40(sp)
    80002682:	f04a                	sd	s2,32(sp)
    80002684:	ec4e                	sd	s3,24(sp)
    80002686:	e852                	sd	s4,16(sp)
    80002688:	e456                	sd	s5,8(sp)
    8000268a:	0080                	addi	s0,sp,64
    8000268c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000268e:	0022f497          	auipc	s1,0x22f
    80002692:	7aa48493          	addi	s1,s1,1962 # 80231e38 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002696:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002698:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000269a:	00237917          	auipc	s2,0x237
    8000269e:	39e90913          	addi	s2,s2,926 # 80239a38 <cpus>
    800026a2:	a821                	j	800026ba <wakeup+0x40>
        p->state = RUNNABLE;
    800026a4:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	8b6080e7          	jalr	-1866(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026b2:	1f048493          	addi	s1,s1,496
    800026b6:	03248463          	beq	s1,s2,800026de <wakeup+0x64>
    if (p != myproc())
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	664080e7          	jalr	1636(ra) # 80001d1e <myproc>
    800026c2:	fea488e3          	beq	s1,a0,800026b2 <wakeup+0x38>
      acquire(&p->lock);
    800026c6:	8526                	mv	a0,s1
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	7e4080e7          	jalr	2020(ra) # 80000eac <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800026d0:	4c9c                	lw	a5,24(s1)
    800026d2:	fd379be3          	bne	a5,s3,800026a8 <wakeup+0x2e>
    800026d6:	709c                	ld	a5,32(s1)
    800026d8:	fd4798e3          	bne	a5,s4,800026a8 <wakeup+0x2e>
    800026dc:	b7e1                	j	800026a4 <wakeup+0x2a>
    }
  }
}
    800026de:	70e2                	ld	ra,56(sp)
    800026e0:	7442                	ld	s0,48(sp)
    800026e2:	74a2                	ld	s1,40(sp)
    800026e4:	7902                	ld	s2,32(sp)
    800026e6:	69e2                	ld	s3,24(sp)
    800026e8:	6a42                	ld	s4,16(sp)
    800026ea:	6aa2                	ld	s5,8(sp)
    800026ec:	6121                	addi	sp,sp,64
    800026ee:	8082                	ret

00000000800026f0 <reparent>:
{
    800026f0:	7179                	addi	sp,sp,-48
    800026f2:	f406                	sd	ra,40(sp)
    800026f4:	f022                	sd	s0,32(sp)
    800026f6:	ec26                	sd	s1,24(sp)
    800026f8:	e84a                	sd	s2,16(sp)
    800026fa:	e44e                	sd	s3,8(sp)
    800026fc:	e052                	sd	s4,0(sp)
    800026fe:	1800                	addi	s0,sp,48
    80002700:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002702:	0022f497          	auipc	s1,0x22f
    80002706:	73648493          	addi	s1,s1,1846 # 80231e38 <proc>
      pp->parent = initproc;
    8000270a:	00007a17          	auipc	s4,0x7
    8000270e:	466a0a13          	addi	s4,s4,1126 # 80009b70 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002712:	00237997          	auipc	s3,0x237
    80002716:	32698993          	addi	s3,s3,806 # 80239a38 <cpus>
    8000271a:	a029                	j	80002724 <reparent+0x34>
    8000271c:	1f048493          	addi	s1,s1,496
    80002720:	01348d63          	beq	s1,s3,8000273a <reparent+0x4a>
    if (pp->parent == p)
    80002724:	60bc                	ld	a5,64(s1)
    80002726:	ff279be3          	bne	a5,s2,8000271c <reparent+0x2c>
      pp->parent = initproc;
    8000272a:	000a3503          	ld	a0,0(s4)
    8000272e:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002730:	00000097          	auipc	ra,0x0
    80002734:	f4a080e7          	jalr	-182(ra) # 8000267a <wakeup>
    80002738:	b7d5                	j	8000271c <reparent+0x2c>
}
    8000273a:	70a2                	ld	ra,40(sp)
    8000273c:	7402                	ld	s0,32(sp)
    8000273e:	64e2                	ld	s1,24(sp)
    80002740:	6942                	ld	s2,16(sp)
    80002742:	69a2                	ld	s3,8(sp)
    80002744:	6a02                	ld	s4,0(sp)
    80002746:	6145                	addi	sp,sp,48
    80002748:	8082                	ret

000000008000274a <exit>:
{
    8000274a:	7179                	addi	sp,sp,-48
    8000274c:	f406                	sd	ra,40(sp)
    8000274e:	f022                	sd	s0,32(sp)
    80002750:	ec26                	sd	s1,24(sp)
    80002752:	e84a                	sd	s2,16(sp)
    80002754:	e44e                	sd	s3,8(sp)
    80002756:	e052                	sd	s4,0(sp)
    80002758:	1800                	addi	s0,sp,48
    8000275a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	5c2080e7          	jalr	1474(ra) # 80001d1e <myproc>
    80002764:	89aa                	mv	s3,a0
  if (p == initproc)
    80002766:	00007797          	auipc	a5,0x7
    8000276a:	40a7b783          	ld	a5,1034(a5) # 80009b70 <initproc>
    8000276e:	0d850493          	addi	s1,a0,216
    80002772:	15850913          	addi	s2,a0,344
    80002776:	02a79363          	bne	a5,a0,8000279c <exit+0x52>
    panic("init exiting");
    8000277a:	00007517          	auipc	a0,0x7
    8000277e:	bb650513          	addi	a0,a0,-1098 # 80009330 <digits+0x2f0>
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	dc2080e7          	jalr	-574(ra) # 80000544 <panic>
      fileclose(f);
    8000278a:	00003097          	auipc	ra,0x3
    8000278e:	e54080e7          	jalr	-428(ra) # 800055de <fileclose>
      p->ofile[fd] = 0;
    80002792:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002796:	04a1                	addi	s1,s1,8
    80002798:	01248563          	beq	s1,s2,800027a2 <exit+0x58>
    if (p->ofile[fd])
    8000279c:	6088                	ld	a0,0(s1)
    8000279e:	f575                	bnez	a0,8000278a <exit+0x40>
    800027a0:	bfdd                	j	80002796 <exit+0x4c>
  begin_op();
    800027a2:	00003097          	auipc	ra,0x3
    800027a6:	970080e7          	jalr	-1680(ra) # 80005112 <begin_op>
  iput(p->cwd);
    800027aa:	1589b503          	ld	a0,344(s3)
    800027ae:	00002097          	auipc	ra,0x2
    800027b2:	15c080e7          	jalr	348(ra) # 8000490a <iput>
  end_op();
    800027b6:	00003097          	auipc	ra,0x3
    800027ba:	9dc080e7          	jalr	-1572(ra) # 80005192 <end_op>
  p->cwd = 0;
    800027be:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800027c2:	0022f497          	auipc	s1,0x22f
    800027c6:	65e48493          	addi	s1,s1,1630 # 80231e20 <wait_lock>
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	6e0080e7          	jalr	1760(ra) # 80000eac <acquire>
  reparent(p);
    800027d4:	854e                	mv	a0,s3
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	f1a080e7          	jalr	-230(ra) # 800026f0 <reparent>
  wakeup(p->parent);
    800027de:	0409b503          	ld	a0,64(s3)
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	e98080e7          	jalr	-360(ra) # 8000267a <wakeup>
  acquire(&p->lock);
    800027ea:	854e                	mv	a0,s3
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	6c0080e7          	jalr	1728(ra) # 80000eac <acquire>
  p->xstate = status;
    800027f4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027f8:	4795                	li	a5,5
    800027fa:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800027fe:	00007797          	auipc	a5,0x7
    80002802:	37a7a783          	lw	a5,890(a5) # 80009b78 <ticks>
    80002806:	1cf9a423          	sw	a5,456(s3)
  release(&wait_lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	754080e7          	jalr	1876(ra) # 80000f60 <release>
  sched();
    80002814:	00000097          	auipc	ra,0x0
    80002818:	ce4080e7          	jalr	-796(ra) # 800024f8 <sched>
  panic("zombie exit");
    8000281c:	00007517          	auipc	a0,0x7
    80002820:	b2450513          	addi	a0,a0,-1244 # 80009340 <digits+0x300>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	d20080e7          	jalr	-736(ra) # 80000544 <panic>

000000008000282c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000282c:	7179                	addi	sp,sp,-48
    8000282e:	f406                	sd	ra,40(sp)
    80002830:	f022                	sd	s0,32(sp)
    80002832:	ec26                	sd	s1,24(sp)
    80002834:	e84a                	sd	s2,16(sp)
    80002836:	e44e                	sd	s3,8(sp)
    80002838:	1800                	addi	s0,sp,48
    8000283a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000283c:	0022f497          	auipc	s1,0x22f
    80002840:	5fc48493          	addi	s1,s1,1532 # 80231e38 <proc>
    80002844:	00237997          	auipc	s3,0x237
    80002848:	1f498993          	addi	s3,s3,500 # 80239a38 <cpus>
  {
    acquire(&p->lock);
    8000284c:	8526                	mv	a0,s1
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	65e080e7          	jalr	1630(ra) # 80000eac <acquire>
    if (p->pid == pid)
    80002856:	589c                	lw	a5,48(s1)
    80002858:	01278d63          	beq	a5,s2,80002872 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000285c:	8526                	mv	a0,s1
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	702080e7          	jalr	1794(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002866:	1f048493          	addi	s1,s1,496
    8000286a:	ff3491e3          	bne	s1,s3,8000284c <kill+0x20>
  }
  return -1;
    8000286e:	557d                	li	a0,-1
    80002870:	a829                	j	8000288a <kill+0x5e>
      p->killed = 1;
    80002872:	4785                	li	a5,1
    80002874:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002876:	4c98                	lw	a4,24(s1)
    80002878:	4789                	li	a5,2
    8000287a:	00f70f63          	beq	a4,a5,80002898 <kill+0x6c>
      release(&p->lock);
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	6e0080e7          	jalr	1760(ra) # 80000f60 <release>
      return 0;
    80002888:	4501                	li	a0,0
}
    8000288a:	70a2                	ld	ra,40(sp)
    8000288c:	7402                	ld	s0,32(sp)
    8000288e:	64e2                	ld	s1,24(sp)
    80002890:	6942                	ld	s2,16(sp)
    80002892:	69a2                	ld	s3,8(sp)
    80002894:	6145                	addi	sp,sp,48
    80002896:	8082                	ret
        p->state = RUNNABLE;
    80002898:	478d                	li	a5,3
    8000289a:	cc9c                	sw	a5,24(s1)
    8000289c:	b7cd                	j	8000287e <kill+0x52>

000000008000289e <setkilled>:

void setkilled(struct proc *p)
{
    8000289e:	1101                	addi	sp,sp,-32
    800028a0:	ec06                	sd	ra,24(sp)
    800028a2:	e822                	sd	s0,16(sp)
    800028a4:	e426                	sd	s1,8(sp)
    800028a6:	1000                	addi	s0,sp,32
    800028a8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	602080e7          	jalr	1538(ra) # 80000eac <acquire>
  p->killed = 1;
    800028b2:	4785                	li	a5,1
    800028b4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800028b6:	8526                	mv	a0,s1
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	6a8080e7          	jalr	1704(ra) # 80000f60 <release>
}
    800028c0:	60e2                	ld	ra,24(sp)
    800028c2:	6442                	ld	s0,16(sp)
    800028c4:	64a2                	ld	s1,8(sp)
    800028c6:	6105                	addi	sp,sp,32
    800028c8:	8082                	ret

00000000800028ca <killed>:

int killed(struct proc *p)
{
    800028ca:	1101                	addi	sp,sp,-32
    800028cc:	ec06                	sd	ra,24(sp)
    800028ce:	e822                	sd	s0,16(sp)
    800028d0:	e426                	sd	s1,8(sp)
    800028d2:	e04a                	sd	s2,0(sp)
    800028d4:	1000                	addi	s0,sp,32
    800028d6:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	5d4080e7          	jalr	1492(ra) # 80000eac <acquire>
  k = p->killed;
    800028e0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	67a080e7          	jalr	1658(ra) # 80000f60 <release>
  return k;
}
    800028ee:	854a                	mv	a0,s2
    800028f0:	60e2                	ld	ra,24(sp)
    800028f2:	6442                	ld	s0,16(sp)
    800028f4:	64a2                	ld	s1,8(sp)
    800028f6:	6902                	ld	s2,0(sp)
    800028f8:	6105                	addi	sp,sp,32
    800028fa:	8082                	ret

00000000800028fc <wait>:
{
    800028fc:	715d                	addi	sp,sp,-80
    800028fe:	e486                	sd	ra,72(sp)
    80002900:	e0a2                	sd	s0,64(sp)
    80002902:	fc26                	sd	s1,56(sp)
    80002904:	f84a                	sd	s2,48(sp)
    80002906:	f44e                	sd	s3,40(sp)
    80002908:	f052                	sd	s4,32(sp)
    8000290a:	ec56                	sd	s5,24(sp)
    8000290c:	e85a                	sd	s6,16(sp)
    8000290e:	e45e                	sd	s7,8(sp)
    80002910:	e062                	sd	s8,0(sp)
    80002912:	0880                	addi	s0,sp,80
    80002914:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	408080e7          	jalr	1032(ra) # 80001d1e <myproc>
    8000291e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002920:	0022f517          	auipc	a0,0x22f
    80002924:	50050513          	addi	a0,a0,1280 # 80231e20 <wait_lock>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	584080e7          	jalr	1412(ra) # 80000eac <acquire>
    havekids = 0;
    80002930:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002932:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002934:	00237997          	auipc	s3,0x237
    80002938:	10498993          	addi	s3,s3,260 # 80239a38 <cpus>
        havekids = 1;
    8000293c:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000293e:	0022fc17          	auipc	s8,0x22f
    80002942:	4e2c0c13          	addi	s8,s8,1250 # 80231e20 <wait_lock>
    havekids = 0;
    80002946:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002948:	0022f497          	auipc	s1,0x22f
    8000294c:	4f048493          	addi	s1,s1,1264 # 80231e38 <proc>
    80002950:	a0bd                	j	800029be <wait+0xc2>
          pid = pp->pid;
    80002952:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002956:	000b0e63          	beqz	s6,80002972 <wait+0x76>
    8000295a:	4691                	li	a3,4
    8000295c:	02c48613          	addi	a2,s1,44
    80002960:	85da                	mv	a1,s6
    80002962:	05893503          	ld	a0,88(s2)
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	fe4080e7          	jalr	-28(ra) # 8000194a <copyout>
    8000296e:	02054563          	bltz	a0,80002998 <wait+0x9c>
          freeproc(pp);
    80002972:	8526                	mv	a0,s1
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	698080e7          	jalr	1688(ra) # 8000200c <freeproc>
          release(&pp->lock);
    8000297c:	8526                	mv	a0,s1
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	5e2080e7          	jalr	1506(ra) # 80000f60 <release>
          release(&wait_lock);
    80002986:	0022f517          	auipc	a0,0x22f
    8000298a:	49a50513          	addi	a0,a0,1178 # 80231e20 <wait_lock>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	5d2080e7          	jalr	1490(ra) # 80000f60 <release>
          return pid;
    80002996:	a0b5                	j	80002a02 <wait+0x106>
            release(&pp->lock);
    80002998:	8526                	mv	a0,s1
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	5c6080e7          	jalr	1478(ra) # 80000f60 <release>
            release(&wait_lock);
    800029a2:	0022f517          	auipc	a0,0x22f
    800029a6:	47e50513          	addi	a0,a0,1150 # 80231e20 <wait_lock>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	5b6080e7          	jalr	1462(ra) # 80000f60 <release>
            return -1;
    800029b2:	59fd                	li	s3,-1
    800029b4:	a0b9                	j	80002a02 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800029b6:	1f048493          	addi	s1,s1,496
    800029ba:	03348463          	beq	s1,s3,800029e2 <wait+0xe6>
      if (pp->parent == p)
    800029be:	60bc                	ld	a5,64(s1)
    800029c0:	ff279be3          	bne	a5,s2,800029b6 <wait+0xba>
        acquire(&pp->lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	4e6080e7          	jalr	1254(ra) # 80000eac <acquire>
        if (pp->state == ZOMBIE)
    800029ce:	4c9c                	lw	a5,24(s1)
    800029d0:	f94781e3          	beq	a5,s4,80002952 <wait+0x56>
        release(&pp->lock);
    800029d4:	8526                	mv	a0,s1
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	58a080e7          	jalr	1418(ra) # 80000f60 <release>
        havekids = 1;
    800029de:	8756                	mv	a4,s5
    800029e0:	bfd9                	j	800029b6 <wait+0xba>
    if (!havekids || killed(p))
    800029e2:	c719                	beqz	a4,800029f0 <wait+0xf4>
    800029e4:	854a                	mv	a0,s2
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	ee4080e7          	jalr	-284(ra) # 800028ca <killed>
    800029ee:	c51d                	beqz	a0,80002a1c <wait+0x120>
      release(&wait_lock);
    800029f0:	0022f517          	auipc	a0,0x22f
    800029f4:	43050513          	addi	a0,a0,1072 # 80231e20 <wait_lock>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	568080e7          	jalr	1384(ra) # 80000f60 <release>
      return -1;
    80002a00:	59fd                	li	s3,-1
}
    80002a02:	854e                	mv	a0,s3
    80002a04:	60a6                	ld	ra,72(sp)
    80002a06:	6406                	ld	s0,64(sp)
    80002a08:	74e2                	ld	s1,56(sp)
    80002a0a:	7942                	ld	s2,48(sp)
    80002a0c:	79a2                	ld	s3,40(sp)
    80002a0e:	7a02                	ld	s4,32(sp)
    80002a10:	6ae2                	ld	s5,24(sp)
    80002a12:	6b42                	ld	s6,16(sp)
    80002a14:	6ba2                	ld	s7,8(sp)
    80002a16:	6c02                	ld	s8,0(sp)
    80002a18:	6161                	addi	sp,sp,80
    80002a1a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a1c:	85e2                	mv	a1,s8
    80002a1e:	854a                	mv	a0,s2
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	bf6080e7          	jalr	-1034(ra) # 80002616 <sleep>
    havekids = 0;
    80002a28:	bf39                	j	80002946 <wait+0x4a>

0000000080002a2a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a2a:	7179                	addi	sp,sp,-48
    80002a2c:	f406                	sd	ra,40(sp)
    80002a2e:	f022                	sd	s0,32(sp)
    80002a30:	ec26                	sd	s1,24(sp)
    80002a32:	e84a                	sd	s2,16(sp)
    80002a34:	e44e                	sd	s3,8(sp)
    80002a36:	e052                	sd	s4,0(sp)
    80002a38:	1800                	addi	s0,sp,48
    80002a3a:	84aa                	mv	s1,a0
    80002a3c:	892e                	mv	s2,a1
    80002a3e:	89b2                	mv	s3,a2
    80002a40:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	2dc080e7          	jalr	732(ra) # 80001d1e <myproc>
  if (user_dst)
    80002a4a:	c08d                	beqz	s1,80002a6c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a4c:	86d2                	mv	a3,s4
    80002a4e:	864e                	mv	a2,s3
    80002a50:	85ca                	mv	a1,s2
    80002a52:	6d28                	ld	a0,88(a0)
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	ef6080e7          	jalr	-266(ra) # 8000194a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a5c:	70a2                	ld	ra,40(sp)
    80002a5e:	7402                	ld	s0,32(sp)
    80002a60:	64e2                	ld	s1,24(sp)
    80002a62:	6942                	ld	s2,16(sp)
    80002a64:	69a2                	ld	s3,8(sp)
    80002a66:	6a02                	ld	s4,0(sp)
    80002a68:	6145                	addi	sp,sp,48
    80002a6a:	8082                	ret
    memmove((char *)dst, src, len);
    80002a6c:	000a061b          	sext.w	a2,s4
    80002a70:	85ce                	mv	a1,s3
    80002a72:	854a                	mv	a0,s2
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	594080e7          	jalr	1428(ra) # 80001008 <memmove>
    return 0;
    80002a7c:	8526                	mv	a0,s1
    80002a7e:	bff9                	j	80002a5c <either_copyout+0x32>

0000000080002a80 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a80:	7179                	addi	sp,sp,-48
    80002a82:	f406                	sd	ra,40(sp)
    80002a84:	f022                	sd	s0,32(sp)
    80002a86:	ec26                	sd	s1,24(sp)
    80002a88:	e84a                	sd	s2,16(sp)
    80002a8a:	e44e                	sd	s3,8(sp)
    80002a8c:	e052                	sd	s4,0(sp)
    80002a8e:	1800                	addi	s0,sp,48
    80002a90:	892a                	mv	s2,a0
    80002a92:	84ae                	mv	s1,a1
    80002a94:	89b2                	mv	s3,a2
    80002a96:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	286080e7          	jalr	646(ra) # 80001d1e <myproc>
  if (user_src)
    80002aa0:	c08d                	beqz	s1,80002ac2 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002aa2:	86d2                	mv	a3,s4
    80002aa4:	864e                	mv	a2,s3
    80002aa6:	85ca                	mv	a1,s2
    80002aa8:	6d28                	ld	a0,88(a0)
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	f64080e7          	jalr	-156(ra) # 80001a0e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002ab2:	70a2                	ld	ra,40(sp)
    80002ab4:	7402                	ld	s0,32(sp)
    80002ab6:	64e2                	ld	s1,24(sp)
    80002ab8:	6942                	ld	s2,16(sp)
    80002aba:	69a2                	ld	s3,8(sp)
    80002abc:	6a02                	ld	s4,0(sp)
    80002abe:	6145                	addi	sp,sp,48
    80002ac0:	8082                	ret
    memmove(dst, (char *)src, len);
    80002ac2:	000a061b          	sext.w	a2,s4
    80002ac6:	85ce                	mv	a1,s3
    80002ac8:	854a                	mv	a0,s2
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	53e080e7          	jalr	1342(ra) # 80001008 <memmove>
    return 0;
    80002ad2:	8526                	mv	a0,s1
    80002ad4:	bff9                	j	80002ab2 <either_copyin+0x32>

0000000080002ad6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002ad6:	7175                	addi	sp,sp,-144
    80002ad8:	e506                	sd	ra,136(sp)
    80002ada:	e122                	sd	s0,128(sp)
    80002adc:	fca6                	sd	s1,120(sp)
    80002ade:	f8ca                	sd	s2,112(sp)
    80002ae0:	f4ce                	sd	s3,104(sp)
    80002ae2:	f0d2                	sd	s4,96(sp)
    80002ae4:	ecd6                	sd	s5,88(sp)
    80002ae6:	e8da                	sd	s6,80(sp)
    80002ae8:	e4de                	sd	s7,72(sp)
    80002aea:	e0e2                	sd	s8,64(sp)
    80002aec:	fc66                	sd	s9,56(sp)
    80002aee:	f86a                	sd	s10,48(sp)
    80002af0:	f46e                	sd	s11,40(sp)
    80002af2:	0900                	addi	s0,sp,144
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  char *state;

  printf("\n");
    80002af4:	00007517          	auipc	a0,0x7
    80002af8:	90450513          	addi	a0,a0,-1788 # 800093f8 <digits+0x3b8>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a92080e7          	jalr	-1390(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b04:	0022f917          	auipc	s2,0x22f
    80002b08:	49490913          	addi	s2,s2,1172 # 80231f98 <proc+0x160>
    80002b0c:	00237a17          	auipc	s4,0x237
    80002b10:	08ca0a13          	addi	s4,s4,140 # 80239b98 <cpus+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b14:	4d15                	li	s10,5
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    80002b16:	00007c97          	auipc	s9,0x7
    80002b1a:	842c8c93          	addi	s9,s9,-1982 # 80009358 <digits+0x318>
#endif
#ifdef PBS
    printf("%d %d %s %d %d %d\n", p->pid, p->priority, state, p->run_time, p->total_wait_time, p->num_run);
#endif
#ifdef MLFQ
    printf("PID Priority State rtime wtime nrun q0 q1 q2 q3 q4\n");
    80002b1e:	00007c17          	auipc	s8,0x7
    80002b22:	84ac0c13          	addi	s8,s8,-1974 # 80009368 <digits+0x328>
#endif
#ifdef MLFQ
    int wtime = ticks - p->qitime;
    80002b26:	00007b97          	auipc	s7,0x7
    80002b2a:	052b8b93          	addi	s7,s7,82 # 80009b78 <ticks>
    printf("%d %d %s %d %d %d %d %d %d %d %d", p->pid, p->priority, state, p->rtime, wtime, p->nrun, p->qrtime[0], p->qrtime[1], p->qrtime[2], p->qrtime[3], p->qrtime[4]);
    80002b2e:	00007b17          	auipc	s6,0x7
    80002b32:	872b0b13          	addi	s6,s6,-1934 # 800093a0 <digits+0x360>
#endif
    printf("\n");
    80002b36:	00007a97          	auipc	s5,0x7
    80002b3a:	8c2a8a93          	addi	s5,s5,-1854 # 800093f8 <digits+0x3b8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b3e:	00007d97          	auipc	s11,0x7
    80002b42:	8ead8d93          	addi	s11,s11,-1814 # 80009428 <states.1925>
    80002b46:	a0bd                	j	80002bb4 <procdump+0xde>
    printf("%d %s %s", p->pid, state, p->name);
    80002b48:	86a6                	mv	a3,s1
    80002b4a:	864e                	mv	a2,s3
    80002b4c:	ed04a583          	lw	a1,-304(s1)
    80002b50:	8566                	mv	a0,s9
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	a3c080e7          	jalr	-1476(ra) # 8000058e <printf>
    printf("PID Priority State rtime wtime nrun q0 q1 q2 q3 q4\n");
    80002b5a:	8562                	mv	a0,s8
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	a32080e7          	jalr	-1486(ra) # 8000058e <printf>
    int wtime = ticks - p->qitime;
    80002b64:	000ba703          	lw	a4,0(s7)
    80002b68:	5cbc                	lw	a5,120(s1)
    printf("%d %d %s %d %d %d %d %d %d %d %d", p->pid, p->priority, state, p->rtime, wtime, p->nrun, p->qrtime[0], p->qrtime[1], p->qrtime[2], p->qrtime[3], p->qrtime[4]);
    80002b6a:	08c4a683          	lw	a3,140(s1)
    80002b6e:	ec36                	sd	a3,24(sp)
    80002b70:	0884a683          	lw	a3,136(s1)
    80002b74:	e836                	sd	a3,16(sp)
    80002b76:	0844a683          	lw	a3,132(s1)
    80002b7a:	e436                	sd	a3,8(sp)
    80002b7c:	0804a683          	lw	a3,128(s1)
    80002b80:	e036                	sd	a3,0(sp)
    80002b82:	07c4a883          	lw	a7,124(s1)
    80002b86:	0744a803          	lw	a6,116(s1)
    80002b8a:	40f707bb          	subw	a5,a4,a5
    80002b8e:	50b8                	lw	a4,96(s1)
    80002b90:	86ce                	mv	a3,s3
    80002b92:	40b0                	lw	a2,64(s1)
    80002b94:	ed04a583          	lw	a1,-304(s1)
    80002b98:	855a                	mv	a0,s6
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9f4080e7          	jalr	-1548(ra) # 8000058e <printf>
    printf("\n");
    80002ba2:	8556                	mv	a0,s5
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	9ea080e7          	jalr	-1558(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bac:	1f090913          	addi	s2,s2,496
    80002bb0:	03490963          	beq	s2,s4,80002be2 <procdump+0x10c>
    if (p->state == UNUSED)
    80002bb4:	84ca                	mv	s1,s2
    80002bb6:	eb892783          	lw	a5,-328(s2)
    80002bba:	dbed                	beqz	a5,80002bac <procdump+0xd6>
      state = "???";
    80002bbc:	00006997          	auipc	s3,0x6
    80002bc0:	79498993          	addi	s3,s3,1940 # 80009350 <digits+0x310>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bc4:	f8fd62e3          	bltu	s10,a5,80002b48 <procdump+0x72>
    80002bc8:	1782                	slli	a5,a5,0x20
    80002bca:	9381                	srli	a5,a5,0x20
    80002bcc:	078e                	slli	a5,a5,0x3
    80002bce:	97ee                	add	a5,a5,s11
    80002bd0:	0007b983          	ld	s3,0(a5)
    80002bd4:	f6099ae3          	bnez	s3,80002b48 <procdump+0x72>
      state = "???";
    80002bd8:	00006997          	auipc	s3,0x6
    80002bdc:	77898993          	addi	s3,s3,1912 # 80009350 <digits+0x310>
    80002be0:	b7a5                	j	80002b48 <procdump+0x72>
  }
}
    80002be2:	60aa                	ld	ra,136(sp)
    80002be4:	640a                	ld	s0,128(sp)
    80002be6:	74e6                	ld	s1,120(sp)
    80002be8:	7946                	ld	s2,112(sp)
    80002bea:	79a6                	ld	s3,104(sp)
    80002bec:	7a06                	ld	s4,96(sp)
    80002bee:	6ae6                	ld	s5,88(sp)
    80002bf0:	6b46                	ld	s6,80(sp)
    80002bf2:	6ba6                	ld	s7,72(sp)
    80002bf4:	6c06                	ld	s8,64(sp)
    80002bf6:	7ce2                	ld	s9,56(sp)
    80002bf8:	7d42                	ld	s10,48(sp)
    80002bfa:	7da2                	ld	s11,40(sp)
    80002bfc:	6149                	addi	sp,sp,144
    80002bfe:	8082                	ret

0000000080002c00 <waitx>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002c00:	711d                	addi	sp,sp,-96
    80002c02:	ec86                	sd	ra,88(sp)
    80002c04:	e8a2                	sd	s0,80(sp)
    80002c06:	e4a6                	sd	s1,72(sp)
    80002c08:	e0ca                	sd	s2,64(sp)
    80002c0a:	fc4e                	sd	s3,56(sp)
    80002c0c:	f852                	sd	s4,48(sp)
    80002c0e:	f456                	sd	s5,40(sp)
    80002c10:	f05a                	sd	s6,32(sp)
    80002c12:	ec5e                	sd	s7,24(sp)
    80002c14:	e862                	sd	s8,16(sp)
    80002c16:	e466                	sd	s9,8(sp)
    80002c18:	e06a                	sd	s10,0(sp)
    80002c1a:	1080                	addi	s0,sp,96
    80002c1c:	8b2a                	mv	s6,a0
    80002c1e:	8bae                	mv	s7,a1
    80002c20:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	0fc080e7          	jalr	252(ra) # 80001d1e <myproc>
    80002c2a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002c2c:	0022f517          	auipc	a0,0x22f
    80002c30:	1f450513          	addi	a0,a0,500 # 80231e20 <wait_lock>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	278080e7          	jalr	632(ra) # 80000eac <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002c3c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002c3e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002c40:	00237997          	auipc	s3,0x237
    80002c44:	df898993          	addi	s3,s3,-520 # 80239a38 <cpus>
        havekids = 1;
    80002c48:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c4a:	0022fd17          	auipc	s10,0x22f
    80002c4e:	1d6d0d13          	addi	s10,s10,470 # 80231e20 <wait_lock>
    havekids = 0;
    80002c52:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002c54:	0022f497          	auipc	s1,0x22f
    80002c58:	1e448493          	addi	s1,s1,484 # 80231e38 <proc>
    80002c5c:	a059                	j	80002ce2 <waitx+0xe2>
          pid = np->pid;
    80002c5e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002c62:	1c04a703          	lw	a4,448(s1)
    80002c66:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002c6a:	1c44a783          	lw	a5,452(s1)
    80002c6e:	9f3d                	addw	a4,a4,a5
    80002c70:	1c84a783          	lw	a5,456(s1)
    80002c74:	9f99                	subw	a5,a5,a4
    80002c76:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c7a:	000b0e63          	beqz	s6,80002c96 <waitx+0x96>
    80002c7e:	4691                	li	a3,4
    80002c80:	02c48613          	addi	a2,s1,44
    80002c84:	85da                	mv	a1,s6
    80002c86:	05893503          	ld	a0,88(s2)
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	cc0080e7          	jalr	-832(ra) # 8000194a <copyout>
    80002c92:	02054563          	bltz	a0,80002cbc <waitx+0xbc>
          freeproc(np);
    80002c96:	8526                	mv	a0,s1
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	374080e7          	jalr	884(ra) # 8000200c <freeproc>
          release(&np->lock);
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	2be080e7          	jalr	702(ra) # 80000f60 <release>
          release(&wait_lock);
    80002caa:	0022f517          	auipc	a0,0x22f
    80002cae:	17650513          	addi	a0,a0,374 # 80231e20 <wait_lock>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	2ae080e7          	jalr	686(ra) # 80000f60 <release>
          return pid;
    80002cba:	a09d                	j	80002d20 <waitx+0x120>
            release(&np->lock);
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	2a2080e7          	jalr	674(ra) # 80000f60 <release>
            release(&wait_lock);
    80002cc6:	0022f517          	auipc	a0,0x22f
    80002cca:	15a50513          	addi	a0,a0,346 # 80231e20 <wait_lock>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	292080e7          	jalr	658(ra) # 80000f60 <release>
            return -1;
    80002cd6:	59fd                	li	s3,-1
    80002cd8:	a0a1                	j	80002d20 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002cda:	1f048493          	addi	s1,s1,496
    80002cde:	03348463          	beq	s1,s3,80002d06 <waitx+0x106>
      if (np->parent == p)
    80002ce2:	60bc                	ld	a5,64(s1)
    80002ce4:	ff279be3          	bne	a5,s2,80002cda <waitx+0xda>
        acquire(&np->lock);
    80002ce8:	8526                	mv	a0,s1
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	1c2080e7          	jalr	450(ra) # 80000eac <acquire>
        if (np->state == ZOMBIE)
    80002cf2:	4c9c                	lw	a5,24(s1)
    80002cf4:	f74785e3          	beq	a5,s4,80002c5e <waitx+0x5e>
        release(&np->lock);
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	266080e7          	jalr	614(ra) # 80000f60 <release>
        havekids = 1;
    80002d02:	8756                	mv	a4,s5
    80002d04:	bfd9                	j	80002cda <waitx+0xda>
    if (!havekids || p->killed)
    80002d06:	c701                	beqz	a4,80002d0e <waitx+0x10e>
    80002d08:	02892783          	lw	a5,40(s2)
    80002d0c:	cb8d                	beqz	a5,80002d3e <waitx+0x13e>
      release(&wait_lock);
    80002d0e:	0022f517          	auipc	a0,0x22f
    80002d12:	11250513          	addi	a0,a0,274 # 80231e20 <wait_lock>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	24a080e7          	jalr	586(ra) # 80000f60 <release>
      return -1;
    80002d1e:	59fd                	li	s3,-1
  }
}
    80002d20:	854e                	mv	a0,s3
    80002d22:	60e6                	ld	ra,88(sp)
    80002d24:	6446                	ld	s0,80(sp)
    80002d26:	64a6                	ld	s1,72(sp)
    80002d28:	6906                	ld	s2,64(sp)
    80002d2a:	79e2                	ld	s3,56(sp)
    80002d2c:	7a42                	ld	s4,48(sp)
    80002d2e:	7aa2                	ld	s5,40(sp)
    80002d30:	7b02                	ld	s6,32(sp)
    80002d32:	6be2                	ld	s7,24(sp)
    80002d34:	6c42                	ld	s8,16(sp)
    80002d36:	6ca2                	ld	s9,8(sp)
    80002d38:	6d02                	ld	s10,0(sp)
    80002d3a:	6125                	addi	sp,sp,96
    80002d3c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d3e:	85ea                	mv	a1,s10
    80002d40:	854a                	mv	a0,s2
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	8d4080e7          	jalr	-1836(ra) # 80002616 <sleep>
    havekids = 0;
    80002d4a:	b721                	j	80002c52 <waitx+0x52>

0000000080002d4c <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handler;
  argint(0, &ticks);
    80002d54:	fec40593          	addi	a1,s0,-20
    80002d58:	4501                	li	a0,0
    80002d5a:	00001097          	auipc	ra,0x1
    80002d5e:	a5a080e7          	jalr	-1446(ra) # 800037b4 <argint>
  argaddr(1, &handler);
    80002d62:	fe040593          	addi	a1,s0,-32
    80002d66:	4505                	li	a0,1
    80002d68:	00001097          	auipc	ra,0x1
    80002d6c:	a6c080e7          	jalr	-1428(ra) # 800037d4 <argaddr>
  if (ticks < 0 || handler < 0)
    80002d70:	fec42783          	lw	a5,-20(s0)
    return -1;
    80002d74:	557d                	li	a0,-1
  if (ticks < 0 || handler < 0)
    80002d76:	0207cf63          	bltz	a5,80002db4 <sys_sigalarm+0x68>
  myproc()->handler = handler;
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	fa4080e7          	jalr	-92(ra) # 80001d1e <myproc>
    80002d82:	fe043783          	ld	a5,-32(s0)
    80002d86:	18f53023          	sd	a5,384(a0)
  myproc()->ticks = ticks;
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	f94080e7          	jalr	-108(ra) # 80001d1e <myproc>
    80002d92:	fec42783          	lw	a5,-20(s0)
    80002d96:	16f52a23          	sw	a5,372(a0)
  myproc()->is_sigalarm = 0;
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	f84080e7          	jalr	-124(ra) # 80001d1e <myproc>
    80002da2:	16052823          	sw	zero,368(a0)
  myproc()->now_ticks = 0;
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	f78080e7          	jalr	-136(ra) # 80001d1e <myproc>
    80002dae:	16052c23          	sw	zero,376(a0)
  return 0;
    80002db2:	4501                	li	a0,0
}
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <update_time>:

void update_time()
{
    80002dbc:	7179                	addi	sp,sp,-48
    80002dbe:	f406                	sd	ra,40(sp)
    80002dc0:	f022                	sd	s0,32(sp)
    80002dc2:	ec26                	sd	s1,24(sp)
    80002dc4:	e84a                	sd	s2,16(sp)
    80002dc6:	e44e                	sd	s3,8(sp)
    80002dc8:	1800                	addi	s0,sp,48
#ifdef MLFQ
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002dca:	0022f497          	auipc	s1,0x22f
    80002dce:	06e48493          	addi	s1,s1,110 # 80231e38 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002dd2:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002dd4:	00237917          	auipc	s2,0x237
    80002dd8:	c6490913          	addi	s2,s2,-924 # 80239a38 <cpus>
    80002ddc:	a811                	j	80002df0 <update_time+0x34>
#ifdef MLFQ
      p->qrtime[p->priority]++;
      p->quanta--;
#endif
    }
    release(&p->lock);
    80002dde:	8526                	mv	a0,s1
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	180080e7          	jalr	384(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002de8:	1f048493          	addi	s1,s1,496
    80002dec:	03248e63          	beq	s1,s2,80002e28 <update_time+0x6c>
    acquire(&p->lock);
    80002df0:	8526                	mv	a0,s1
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	0ba080e7          	jalr	186(ra) # 80000eac <acquire>
    if (p->state == RUNNING)
    80002dfa:	4c9c                	lw	a5,24(s1)
    80002dfc:	ff3791e3          	bne	a5,s3,80002dde <update_time+0x22>
      p->rtime++;
    80002e00:	1c04a783          	lw	a5,448(s1)
    80002e04:	2785                	addiw	a5,a5,1
    80002e06:	1cf4a023          	sw	a5,448(s1)
      p->qrtime[p->priority]++;
    80002e0a:	1a04e783          	lwu	a5,416(s1)
    80002e0e:	078a                	slli	a5,a5,0x2
    80002e10:	97a6                	add	a5,a5,s1
    80002e12:	1dc7a703          	lw	a4,476(a5)
    80002e16:	2705                	addiw	a4,a4,1
    80002e18:	1ce7ae23          	sw	a4,476(a5)
      p->quanta--;
    80002e1c:	1d04a783          	lw	a5,464(s1)
    80002e20:	37fd                	addiw	a5,a5,-1
    80002e22:	1cf4a823          	sw	a5,464(s1)
    80002e26:	bf65                	j	80002dde <update_time+0x22>
      p->rtime++;
    }
    release(&p->lock);
  }
#endif
}
    80002e28:	70a2                	ld	ra,40(sp)
    80002e2a:	7402                	ld	s0,32(sp)
    80002e2c:	64e2                	ld	s1,24(sp)
    80002e2e:	6942                	ld	s2,16(sp)
    80002e30:	69a2                	ld	s3,8(sp)
    80002e32:	6145                	addi	sp,sp,48
    80002e34:	8082                	ret

0000000080002e36 <top>:

#ifdef MLFQ
struct proc *top(struct Queue *q)
{
    80002e36:	1141                	addi	sp,sp,-16
    80002e38:	e422                	sd	s0,8(sp)
    80002e3a:	0800                	addi	s0,sp,16
  if (q->head == q->tail)
    80002e3c:	411c                	lw	a5,0(a0)
    80002e3e:	4158                	lw	a4,4(a0)
    80002e40:	00f70863          	beq	a4,a5,80002e50 <top+0x1a>
    return 0;
  return q->procs[q->head];
    80002e44:	078e                	slli	a5,a5,0x3
    80002e46:	953e                	add	a0,a0,a5
    80002e48:	6508                	ld	a0,8(a0)
}
    80002e4a:	6422                	ld	s0,8(sp)
    80002e4c:	0141                	addi	sp,sp,16
    80002e4e:	8082                	ret
    return 0;
    80002e50:	4501                	li	a0,0
    80002e52:	bfe5                	j	80002e4a <top+0x14>

0000000080002e54 <qpush>:

void qpush(struct Queue *q, struct proc *element)
{
  if (q->size == NPROC)
    80002e54:	21052703          	lw	a4,528(a0)
    80002e58:	04000793          	li	a5,64
    80002e5c:	02f70363          	beq	a4,a5,80002e82 <qpush+0x2e>
    panic("Proccess limit exceeded");
  // printf("%d %d %d\n", ticks, element->pid,q->tail );

      // printf("%d %d s%d\n",element->)

      q->procs[q->tail] = element;
    80002e60:	415c                	lw	a5,4(a0)
    80002e62:	00379693          	slli	a3,a5,0x3
    80002e66:	96aa                	add	a3,a3,a0
    80002e68:	e68c                	sd	a1,8(a3)
  q->tail++;
    80002e6a:	2785                	addiw	a5,a5,1
    80002e6c:	0007861b          	sext.w	a2,a5
  if (q->tail == NPROC + 1)
    80002e70:	04100693          	li	a3,65
    80002e74:	02d60363          	beq	a2,a3,80002e9a <qpush+0x46>
  q->tail++;
    80002e78:	c15c                	sw	a5,4(a0)
    q->tail = 0;
  q->size++;
    80002e7a:	2705                	addiw	a4,a4,1
    80002e7c:	20e52823          	sw	a4,528(a0)
    80002e80:	8082                	ret
{
    80002e82:	1141                	addi	sp,sp,-16
    80002e84:	e406                	sd	ra,8(sp)
    80002e86:	e022                	sd	s0,0(sp)
    80002e88:	0800                	addi	s0,sp,16
    panic("Proccess limit exceeded");
    80002e8a:	00006517          	auipc	a0,0x6
    80002e8e:	53e50513          	addi	a0,a0,1342 # 800093c8 <digits+0x388>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6b2080e7          	jalr	1714(ra) # 80000544 <panic>
    q->tail = 0;
    80002e9a:	00052223          	sw	zero,4(a0)
    80002e9e:	bff1                	j	80002e7a <qpush+0x26>

0000000080002ea0 <qpop>:
}

void qpop(struct Queue *q)
{
  if (q->size == 0)
    80002ea0:	21052783          	lw	a5,528(a0)
    80002ea4:	cf91                	beqz	a5,80002ec0 <qpop+0x20>
    panic("Empty queue");
  q->head++;
    80002ea6:	4118                	lw	a4,0(a0)
    80002ea8:	2705                	addiw	a4,a4,1
    80002eaa:	0007061b          	sext.w	a2,a4
  if (q->head == NPROC + 1)
    80002eae:	04100693          	li	a3,65
    80002eb2:	02d60363          	beq	a2,a3,80002ed8 <qpop+0x38>
  q->head++;
    80002eb6:	c118                	sw	a4,0(a0)
    q->head = 0;
  q->size--;
    80002eb8:	37fd                	addiw	a5,a5,-1
    80002eba:	20f52823          	sw	a5,528(a0)
    80002ebe:	8082                	ret
{
    80002ec0:	1141                	addi	sp,sp,-16
    80002ec2:	e406                	sd	ra,8(sp)
    80002ec4:	e022                	sd	s0,0(sp)
    80002ec6:	0800                	addi	s0,sp,16
    panic("Empty queue");
    80002ec8:	00006517          	auipc	a0,0x6
    80002ecc:	51850513          	addi	a0,a0,1304 # 800093e0 <digits+0x3a0>
    80002ed0:	ffffd097          	auipc	ra,0xffffd
    80002ed4:	674080e7          	jalr	1652(ra) # 80000544 <panic>
    q->head = 0;
    80002ed8:	00052023          	sw	zero,0(a0)
    80002edc:	bff1                	j	80002eb8 <qpop+0x18>

0000000080002ede <qrm>:
}

void qrm(struct Queue *q, int pid)
{
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e422                	sd	s0,8(sp)
    80002ee2:	0800                	addi	s0,sp,16
  for (int curr = q->head; curr != q->tail; curr = (curr + 1) % (NPROC + 1))
    80002ee4:	411c                	lw	a5,0(a0)
    80002ee6:	00452803          	lw	a6,4(a0)
    80002eea:	03078d63          	beq	a5,a6,80002f24 <qrm+0x46>
  {
    if (q->procs[curr]->pid == pid)
    {
      struct proc *temp = q->procs[curr];
      q->procs[curr] = q->procs[(curr + 1) % (NPROC + 1)];
    80002eee:	04100893          	li	a7,65
    80002ef2:	a031                	j	80002efe <qrm+0x20>
  for (int curr = q->head; curr != q->tail; curr = (curr + 1) % (NPROC + 1))
    80002ef4:	2785                	addiw	a5,a5,1
    80002ef6:	0317e7bb          	remw	a5,a5,a7
    80002efa:	03078563          	beq	a5,a6,80002f24 <qrm+0x46>
    if (q->procs[curr]->pid == pid)
    80002efe:	00379713          	slli	a4,a5,0x3
    80002f02:	972a                	add	a4,a4,a0
    80002f04:	6710                	ld	a2,8(a4)
    80002f06:	5a14                	lw	a3,48(a2)
    80002f08:	feb696e3          	bne	a3,a1,80002ef4 <qrm+0x16>
      q->procs[curr] = q->procs[(curr + 1) % (NPROC + 1)];
    80002f0c:	0017869b          	addiw	a3,a5,1
    80002f10:	0316e6bb          	remw	a3,a3,a7
    80002f14:	068e                	slli	a3,a3,0x3
    80002f16:	96aa                	add	a3,a3,a0
    80002f18:	0086b303          	ld	t1,8(a3)
    80002f1c:	00673423          	sd	t1,8(a4)
      q->procs[(curr + 1) % (NPROC + 1)] = temp;
    80002f20:	e690                	sd	a2,8(a3)
    80002f22:	bfc9                	j	80002ef4 <qrm+0x16>
    }
  }

  q->tail--;
    80002f24:	387d                	addiw	a6,a6,-1
    80002f26:	01052223          	sw	a6,4(a0)
  q->size--;
    80002f2a:	21052783          	lw	a5,528(a0)
    80002f2e:	37fd                	addiw	a5,a5,-1
    80002f30:	20f52823          	sw	a5,528(a0)
  if (q->tail < 0)
    80002f34:	02081793          	slli	a5,a6,0x20
    80002f38:	0007c563          	bltz	a5,80002f42 <qrm+0x64>
    q->tail = NPROC;
}
    80002f3c:	6422                	ld	s0,8(sp)
    80002f3e:	0141                	addi	sp,sp,16
    80002f40:	8082                	ret
    q->tail = NPROC;
    80002f42:	04000793          	li	a5,64
    80002f46:	c15c                	sw	a5,4(a0)
}
    80002f48:	bfd5                	j	80002f3c <qrm+0x5e>

0000000080002f4a <scheduler>:
{
    80002f4a:	7119                	addi	sp,sp,-128
    80002f4c:	fc86                	sd	ra,120(sp)
    80002f4e:	f8a2                	sd	s0,112(sp)
    80002f50:	f4a6                	sd	s1,104(sp)
    80002f52:	f0ca                	sd	s2,96(sp)
    80002f54:	ecce                	sd	s3,88(sp)
    80002f56:	e8d2                	sd	s4,80(sp)
    80002f58:	e4d6                	sd	s5,72(sp)
    80002f5a:	e0da                	sd	s6,64(sp)
    80002f5c:	fc5e                	sd	s7,56(sp)
    80002f5e:	f862                	sd	s8,48(sp)
    80002f60:	f466                	sd	s9,40(sp)
    80002f62:	f06a                	sd	s10,32(sp)
    80002f64:	ec6e                	sd	s11,24(sp)
    80002f66:	0100                	addi	s0,sp,128
    80002f68:	8792                	mv	a5,tp
  int id = r_tp();
    80002f6a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002f6c:	00237697          	auipc	a3,0x237
    80002f70:	acc68693          	addi	a3,a3,-1332 # 80239a38 <cpus>
    80002f74:	15800713          	li	a4,344
    80002f78:	02e78733          	mul	a4,a5,a4
    80002f7c:	00e68633          	add	a2,a3,a4
    80002f80:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
    swtch(&c->context, &chosen->context);
    80002f84:	0721                	addi	a4,a4,8
    80002f86:	9736                	add	a4,a4,a3
    80002f88:	f8e43423          	sd	a4,-120(s0)
        if (ticks >= OLDAGE + p->qitime)
    80002f8c:	00007b17          	auipc	s6,0x7
    80002f90:	becb0b13          	addi	s6,s6,-1044 # 80009b78 <ticks>
            qrm(&mlfq[p->priority], p->pid);
    80002f94:	00237c97          	auipc	s9,0x237
    80002f98:	564c8c93          	addi	s9,s9,1380 # 8023a4f8 <mlfq>
    c->proc = chosen;
    80002f9c:	8db2                	mv	s11,a2
    80002f9e:	aa31                	j	800030ba <scheduler+0x170>
            p->in_queue = 0;
    80002fa0:	1c04a623          	sw	zero,460(s1)
            qrm(&mlfq[p->priority], p->pid);
    80002fa4:	1a04e503          	lwu	a0,416(s1)
    80002fa8:	03850533          	mul	a0,a0,s8
    80002fac:	588c                	lw	a1,48(s1)
    80002fae:	9566                	add	a0,a0,s9
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	f2e080e7          	jalr	-210(ra) # 80002ede <qrm>
    80002fb8:	a02d                	j	80002fe2 <scheduler+0x98>
      p++;
    80002fba:	1f048493          	addi	s1,s1,496
    while (p < &proc[NPROC])
    80002fbe:	03448963          	beq	s1,s4,80002ff0 <scheduler+0xa6>
      if (p->state == RUNNABLE)
    80002fc2:	4c9c                	lw	a5,24(s1)
    80002fc4:	ff279be3          	bne	a5,s2,80002fba <scheduler+0x70>
        if (ticks >= OLDAGE + p->qitime)
    80002fc8:	000b2703          	lw	a4,0(s6)
    80002fcc:	1d84a783          	lw	a5,472(s1)
    80002fd0:	0407879b          	addiw	a5,a5,64
    80002fd4:	fef763e3          	bltu	a4,a5,80002fba <scheduler+0x70>
          p->qitime = ticks;
    80002fd8:	1ce4ac23          	sw	a4,472(s1)
          if (p->in_queue)
    80002fdc:	1cc4a783          	lw	a5,460(s1)
    80002fe0:	f3e1                	bnez	a5,80002fa0 <scheduler+0x56>
          if (p->priority != 0)
    80002fe2:	1a04a783          	lw	a5,416(s1)
    80002fe6:	dbf1                	beqz	a5,80002fba <scheduler+0x70>
            p->priority--;
    80002fe8:	37fd                	addiw	a5,a5,-1
    80002fea:	1af4a023          	sw	a5,416(s1)
    80002fee:	b7f1                	j	80002fba <scheduler+0x70>
    p = proc;
    80002ff0:	0022f497          	auipc	s1,0x22f
    80002ff4:	e4848493          	addi	s1,s1,-440 # 80231e38 <proc>
          printf("%d %d %d\n",ticks, p->pid, p->priority);
    80002ff8:	00006a97          	auipc	s5,0x6
    80002ffc:	3f8a8a93          	addi	s5,s5,1016 # 800093f0 <digits+0x3b0>
          p->in_queue = 1;
    80003000:	4985                	li	s3,1
    80003002:	a081                	j	80003042 <scheduler+0xf8>
          printf("%d %d %d\n",ticks, p->pid, p->priority);
    80003004:	1a04a683          	lw	a3,416(s1)
    80003008:	5890                	lw	a2,48(s1)
    8000300a:	000b2583          	lw	a1,0(s6)
    8000300e:	8556                	mv	a0,s5
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	57e080e7          	jalr	1406(ra) # 8000058e <printf>
          qpush(&mlfq[p->priority], p);
    80003018:	1a04e503          	lwu	a0,416(s1)
    8000301c:	03850533          	mul	a0,a0,s8
    80003020:	85a6                	mv	a1,s1
    80003022:	9566                	add	a0,a0,s9
    80003024:	00000097          	auipc	ra,0x0
    80003028:	e30080e7          	jalr	-464(ra) # 80002e54 <qpush>
          p->in_queue = 1;
    8000302c:	1d34a623          	sw	s3,460(s1)
      release(&p->lock);
    80003030:	8526                	mv	a0,s1
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	f2e080e7          	jalr	-210(ra) # 80000f60 <release>
      p++;
    8000303a:	1f048493          	addi	s1,s1,496
    while (p < &proc[NPROC])
    8000303e:	01448e63          	beq	s1,s4,8000305a <scheduler+0x110>
      acquire(&p->lock);
    80003042:	8526                	mv	a0,s1
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	e68080e7          	jalr	-408(ra) # 80000eac <acquire>
      if (p->state == RUNNABLE)
    8000304c:	4c9c                	lw	a5,24(s1)
    8000304e:	ff2791e3          	bne	a5,s2,80003030 <scheduler+0xe6>
        if (p->in_queue == 0)
    80003052:	1cc4a783          	lw	a5,460(s1)
    80003056:	ffe9                	bnez	a5,80003030 <scheduler+0xe6>
    80003058:	b775                	j	80003004 <scheduler+0xba>
    8000305a:	00237b97          	auipc	s7,0x237
    8000305e:	49eb8b93          	addi	s7,s7,1182 # 8023a4f8 <mlfq>
    80003062:	00238d17          	auipc	s10,0x238
    80003066:	f0ed0d13          	addi	s10,s10,-242 # 8023af70 <tickslock>
    8000306a:	a8b5                	j	800030e6 <scheduler+0x19c>
          p->qitime = ticks;
    8000306c:	000b2783          	lw	a5,0(s6)
    80003070:	1cf4ac23          	sw	a5,472(s1)
    chosen->state = RUNNING;
    80003074:	4791                	li	a5,4
    80003076:	cc9c                	sw	a5,24(s1)
    chosen->quanta = 1 << chosen->priority;
    80003078:	1a04a703          	lw	a4,416(s1)
    8000307c:	4785                	li	a5,1
    8000307e:	00e797bb          	sllw	a5,a5,a4
    80003082:	1cf4a823          	sw	a5,464(s1)
    chosen->nrun++;
    80003086:	1d44a783          	lw	a5,468(s1)
    8000308a:	2785                	addiw	a5,a5,1
    8000308c:	1cf4aa23          	sw	a5,468(s1)
    c->proc = chosen;
    80003090:	009db023          	sd	s1,0(s11)
    swtch(&c->context, &chosen->context);
    80003094:	06848593          	addi	a1,s1,104
    80003098:	f8843503          	ld	a0,-120(s0)
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	08c080e7          	jalr	140(ra) # 80003128 <swtch>
    c->proc = 0;
    800030a4:	000db023          	sd	zero,0(s11)
    chosen->qitime = ticks;
    800030a8:	000b2783          	lw	a5,0(s6)
    800030ac:	1cf4ac23          	sw	a5,472(s1)
    release(&chosen->lock);
    800030b0:	8526                	mv	a0,s1
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	eae080e7          	jalr	-338(ra) # 80000f60 <release>
      if (p->state == RUNNABLE)
    800030ba:	490d                	li	s2,3
            qrm(&mlfq[p->priority], p->pid);
    800030bc:	21800c13          	li	s8,536
    while (p < &proc[NPROC])
    800030c0:	00237a17          	auipc	s4,0x237
    800030c4:	978a0a13          	addi	s4,s4,-1672 # 80239a38 <cpus>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030d0:	10079073          	csrw	sstatus,a5
    p = proc;
    800030d4:	0022f497          	auipc	s1,0x22f
    800030d8:	d6448493          	addi	s1,s1,-668 # 80231e38 <proc>
    800030dc:	b5dd                	j	80002fc2 <scheduler+0x78>
    while (lvl < NMLFQ)
    800030de:	218b8b93          	addi	s7,s7,536
    800030e2:	ffab83e3          	beq	s7,s10,800030c8 <scheduler+0x17e>
      for (int i = 0; mlfq[lvl].size; i++)
    800030e6:	89de                	mv	s3,s7
    800030e8:	210ba783          	lw	a5,528(s7)
    800030ec:	dbed                	beqz	a5,800030de <scheduler+0x194>
        p = top(&mlfq[lvl]);
    800030ee:	854e                	mv	a0,s3
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	d46080e7          	jalr	-698(ra) # 80002e36 <top>
    800030f8:	84aa                	mv	s1,a0
        acquire(&p->lock);
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	db2080e7          	jalr	-590(ra) # 80000eac <acquire>
        qpop(&mlfq[lvl]);
    80003102:	854e                	mv	a0,s3
    80003104:	00000097          	auipc	ra,0x0
    80003108:	d9c080e7          	jalr	-612(ra) # 80002ea0 <qpop>
        p->in_queue = 0;
    8000310c:	1c04a623          	sw	zero,460(s1)
        if (p->state == RUNNABLE)
    80003110:	4c9c                	lw	a5,24(s1)
    80003112:	f5278de3          	beq	a5,s2,8000306c <scheduler+0x122>
        release(&p->lock);
    80003116:	8526                	mv	a0,s1
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	e48080e7          	jalr	-440(ra) # 80000f60 <release>
      for (int i = 0; mlfq[lvl].size; i++)
    80003120:	2109a783          	lw	a5,528(s3)
    80003124:	f7e9                	bnez	a5,800030ee <scheduler+0x1a4>
    80003126:	bf65                	j	800030de <scheduler+0x194>

0000000080003128 <swtch>:
    80003128:	00153023          	sd	ra,0(a0)
    8000312c:	00253423          	sd	sp,8(a0)
    80003130:	e900                	sd	s0,16(a0)
    80003132:	ed04                	sd	s1,24(a0)
    80003134:	03253023          	sd	s2,32(a0)
    80003138:	03353423          	sd	s3,40(a0)
    8000313c:	03453823          	sd	s4,48(a0)
    80003140:	03553c23          	sd	s5,56(a0)
    80003144:	05653023          	sd	s6,64(a0)
    80003148:	05753423          	sd	s7,72(a0)
    8000314c:	05853823          	sd	s8,80(a0)
    80003150:	05953c23          	sd	s9,88(a0)
    80003154:	07a53023          	sd	s10,96(a0)
    80003158:	07b53423          	sd	s11,104(a0)
    8000315c:	0005b083          	ld	ra,0(a1)
    80003160:	0085b103          	ld	sp,8(a1)
    80003164:	6980                	ld	s0,16(a1)
    80003166:	6d84                	ld	s1,24(a1)
    80003168:	0205b903          	ld	s2,32(a1)
    8000316c:	0285b983          	ld	s3,40(a1)
    80003170:	0305ba03          	ld	s4,48(a1)
    80003174:	0385ba83          	ld	s5,56(a1)
    80003178:	0405bb03          	ld	s6,64(a1)
    8000317c:	0485bb83          	ld	s7,72(a1)
    80003180:	0505bc03          	ld	s8,80(a1)
    80003184:	0585bc83          	ld	s9,88(a1)
    80003188:	0605bd03          	ld	s10,96(a1)
    8000318c:	0685bd83          	ld	s11,104(a1)
    80003190:	8082                	ret

0000000080003192 <trapinithart>:
#ifdef MLFQ
extern struct Queue mlfq[NMLFQ];
#endif

void trapinithart(void)
{
    80003192:	1141                	addi	sp,sp,-16
    80003194:	e422                	sd	s0,8(sp)
    80003196:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003198:	00004797          	auipc	a5,0x4
    8000319c:	a8878793          	addi	a5,a5,-1400 # 80006c20 <kernelvec>
    800031a0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800031a4:	6422                	ld	s0,8(sp)
    800031a6:	0141                	addi	sp,sp,16
    800031a8:	8082                	ret

00000000800031aa <trapinit>:

void trapinit(void)
{
    800031aa:	1141                	addi	sp,sp,-16
    800031ac:	e406                	sd	ra,8(sp)
    800031ae:	e022                	sd	s0,0(sp)
    800031b0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800031b2:	00006597          	auipc	a1,0x6
    800031b6:	2a658593          	addi	a1,a1,678 # 80009458 <states.1925+0x30>
    800031ba:	00238517          	auipc	a0,0x238
    800031be:	db650513          	addi	a0,a0,-586 # 8023af70 <tickslock>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	c5a080e7          	jalr	-934(ra) # 80000e1c <initlock>
}
    800031ca:	60a2                	ld	ra,8(sp)
    800031cc:	6402                	ld	s0,0(sp)
    800031ce:	0141                	addi	sp,sp,16
    800031d0:	8082                	ret

00000000800031d2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800031d2:	1141                	addi	sp,sp,-16
    800031d4:	e406                	sd	ra,8(sp)
    800031d6:	e022                	sd	s0,0(sp)
    800031d8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	b44080e7          	jalr	-1212(ra) # 80001d1e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800031e6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031e8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800031ec:	00005617          	auipc	a2,0x5
    800031f0:	e1460613          	addi	a2,a2,-492 # 80008000 <_trampoline>
    800031f4:	00005697          	auipc	a3,0x5
    800031f8:	e0c68693          	addi	a3,a3,-500 # 80008000 <_trampoline>
    800031fc:	8e91                	sub	a3,a3,a2
    800031fe:	040007b7          	lui	a5,0x4000
    80003202:	17fd                	addi	a5,a5,-1
    80003204:	07b2                	slli	a5,a5,0xc
    80003206:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003208:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000320c:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000320e:	180026f3          	csrr	a3,satp
    80003212:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003214:	7138                	ld	a4,96(a0)
    80003216:	6534                	ld	a3,72(a0)
    80003218:	6585                	lui	a1,0x1
    8000321a:	96ae                	add	a3,a3,a1
    8000321c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000321e:	7138                	ld	a4,96(a0)
    80003220:	00000697          	auipc	a3,0x0
    80003224:	13e68693          	addi	a3,a3,318 # 8000335e <usertrap>
    80003228:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000322a:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000322c:	8692                	mv	a3,tp
    8000322e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003230:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003234:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003238:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000323c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003240:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003242:	6f18                	ld	a4,24(a4)
    80003244:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003248:	6d28                	ld	a0,88(a0)
    8000324a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000324c:	00005717          	auipc	a4,0x5
    80003250:	e5070713          	addi	a4,a4,-432 # 8000809c <userret>
    80003254:	8f11                	sub	a4,a4,a2
    80003256:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80003258:	577d                	li	a4,-1
    8000325a:	177e                	slli	a4,a4,0x3f
    8000325c:	8d59                	or	a0,a0,a4
    8000325e:	9782                	jalr	a5
}
    80003260:	60a2                	ld	ra,8(sp)
    80003262:	6402                	ld	s0,0(sp)
    80003264:	0141                	addi	sp,sp,16
    80003266:	8082                	ret

0000000080003268 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	e04a                	sd	s2,0(sp)
    80003272:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003274:	00238917          	auipc	s2,0x238
    80003278:	cfc90913          	addi	s2,s2,-772 # 8023af70 <tickslock>
    8000327c:	854a                	mv	a0,s2
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	c2e080e7          	jalr	-978(ra) # 80000eac <acquire>
  ticks++;
    80003286:	00007497          	auipc	s1,0x7
    8000328a:	8f248493          	addi	s1,s1,-1806 # 80009b78 <ticks>
    8000328e:	409c                	lw	a5,0(s1)
    80003290:	2785                	addiw	a5,a5,1
    80003292:	c09c                	sw	a5,0(s1)
  update_time();
    80003294:	00000097          	auipc	ra,0x0
    80003298:	b28080e7          	jalr	-1240(ra) # 80002dbc <update_time>
  wakeup(&ticks);
    8000329c:	8526                	mv	a0,s1
    8000329e:	fffff097          	auipc	ra,0xfffff
    800032a2:	3dc080e7          	jalr	988(ra) # 8000267a <wakeup>
  release(&tickslock);
    800032a6:	854a                	mv	a0,s2
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	cb8080e7          	jalr	-840(ra) # 80000f60 <release>
}
    800032b0:	60e2                	ld	ra,24(sp)
    800032b2:	6442                	ld	s0,16(sp)
    800032b4:	64a2                	ld	s1,8(sp)
    800032b6:	6902                	ld	s2,0(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032c6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    800032ca:	00074d63          	bltz	a4,800032e4 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800032ce:	57fd                	li	a5,-1
    800032d0:	17fe                	slli	a5,a5,0x3f
    800032d2:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800032d4:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800032d6:	06f70363          	beq	a4,a5,8000333c <devintr+0x80>
  }
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret
      (scause & 0xff) == 9)
    800032e4:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    800032e8:	46a5                	li	a3,9
    800032ea:	fed792e3          	bne	a5,a3,800032ce <devintr+0x12>
    int irq = plic_claim();
    800032ee:	00004097          	auipc	ra,0x4
    800032f2:	a3a080e7          	jalr	-1478(ra) # 80006d28 <plic_claim>
    800032f6:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800032f8:	47a9                	li	a5,10
    800032fa:	02f50763          	beq	a0,a5,80003328 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800032fe:	4785                	li	a5,1
    80003300:	02f50963          	beq	a0,a5,80003332 <devintr+0x76>
    return 1;
    80003304:	4505                	li	a0,1
    else if (irq)
    80003306:	d8f1                	beqz	s1,800032da <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003308:	85a6                	mv	a1,s1
    8000330a:	00006517          	auipc	a0,0x6
    8000330e:	15650513          	addi	a0,a0,342 # 80009460 <states.1925+0x38>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	27c080e7          	jalr	636(ra) # 8000058e <printf>
      plic_complete(irq);
    8000331a:	8526                	mv	a0,s1
    8000331c:	00004097          	auipc	ra,0x4
    80003320:	a30080e7          	jalr	-1488(ra) # 80006d4c <plic_complete>
    return 1;
    80003324:	4505                	li	a0,1
    80003326:	bf55                	j	800032da <devintr+0x1e>
      uartintr();
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	686080e7          	jalr	1670(ra) # 800009ae <uartintr>
    80003330:	b7ed                	j	8000331a <devintr+0x5e>
      virtio_disk_intr();
    80003332:	00004097          	auipc	ra,0x4
    80003336:	f44080e7          	jalr	-188(ra) # 80007276 <virtio_disk_intr>
    8000333a:	b7c5                	j	8000331a <devintr+0x5e>
    if (cpuid() == 0)
    8000333c:	fffff097          	auipc	ra,0xfffff
    80003340:	9b0080e7          	jalr	-1616(ra) # 80001cec <cpuid>
    80003344:	c901                	beqz	a0,80003354 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003346:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000334a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000334c:	14479073          	csrw	sip,a5
    return 2;
    80003350:	4509                	li	a0,2
    80003352:	b761                	j	800032da <devintr+0x1e>
      clockintr();
    80003354:	00000097          	auipc	ra,0x0
    80003358:	f14080e7          	jalr	-236(ra) # 80003268 <clockintr>
    8000335c:	b7ed                	j	80003346 <devintr+0x8a>

000000008000335e <usertrap>:
{
    8000335e:	7179                	addi	sp,sp,-48
    80003360:	f406                	sd	ra,40(sp)
    80003362:	f022                	sd	s0,32(sp)
    80003364:	ec26                	sd	s1,24(sp)
    80003366:	e84a                	sd	s2,16(sp)
    80003368:	e44e                	sd	s3,8(sp)
    8000336a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000336c:	fffff097          	auipc	ra,0xfffff
    80003370:	9b2080e7          	jalr	-1614(ra) # 80001d1e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003374:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80003378:	1007f793          	andi	a5,a5,256
    8000337c:	e3bd                	bnez	a5,800033e2 <usertrap+0x84>
    8000337e:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003380:	00004797          	auipc	a5,0x4
    80003384:	8a078793          	addi	a5,a5,-1888 # 80006c20 <kernelvec>
    80003388:	10579073          	csrw	stvec,a5
  p->trapframe->epc = r_sepc();
    8000338c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000338e:	14102773          	csrr	a4,sepc
    80003392:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003394:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003398:	47a1                	li	a5,8
    8000339a:	04f70c63          	beq	a4,a5,800033f2 <usertrap+0x94>
  else if ((which_dev = devintr()) != 0)
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	f1e080e7          	jalr	-226(ra) # 800032bc <devintr>
    800033a6:	892a                	mv	s2,a0
    800033a8:	e165                	bnez	a0,80003488 <usertrap+0x12a>
    800033aa:	14202773          	csrr	a4,scause
  else if (r_scause() == 15 || r_scause() == 13)
    800033ae:	47bd                	li	a5,15
    800033b0:	00f70763          	beq	a4,a5,800033be <usertrap+0x60>
    800033b4:	14202773          	csrr	a4,scause
    800033b8:	47b5                	li	a5,13
    800033ba:	08f71a63          	bne	a4,a5,8000344e <usertrap+0xf0>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033be:	143027f3          	csrr	a5,stval
    if (r_stval() == 0)
    800033c2:	e399                	bnez	a5,800033c8 <usertrap+0x6a>
      p->killed = 1;
    800033c4:	4785                	li	a5,1
    800033c6:	d49c                	sw	a5,40(s1)
    800033c8:	14302573          	csrr	a0,stval
    int res = page_fault_handler((void *)r_stval(), p->pagetable);
    800033cc:	6cac                	ld	a1,88(s1)
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	990080e7          	jalr	-1648(ra) # 80000d5e <page_fault_handler>
    if (res == -1 || res == -2)
    800033d6:	2509                	addiw	a0,a0,2
    800033d8:	4785                	li	a5,1
    800033da:	02a7ef63          	bltu	a5,a0,80003418 <usertrap+0xba>
      p->killed = 1;
    800033de:	d49c                	sw	a5,40(s1)
    800033e0:	a825                	j	80003418 <usertrap+0xba>
    panic("usertrap: not from user mode");
    800033e2:	00006517          	auipc	a0,0x6
    800033e6:	09e50513          	addi	a0,a0,158 # 80009480 <states.1925+0x58>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	15a080e7          	jalr	346(ra) # 80000544 <panic>
    if (killed(p))
    800033f2:	fffff097          	auipc	ra,0xfffff
    800033f6:	4d8080e7          	jalr	1240(ra) # 800028ca <killed>
    800033fa:	e521                	bnez	a0,80003442 <usertrap+0xe4>
    p->trapframe->epc += 4;
    800033fc:	70b8                	ld	a4,96(s1)
    800033fe:	6f1c                	ld	a5,24(a4)
    80003400:	0791                	addi	a5,a5,4
    80003402:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003404:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003408:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000340c:	10079073          	csrw	sstatus,a5
    syscall();
    80003410:	00000097          	auipc	ra,0x0
    80003414:	41c080e7          	jalr	1052(ra) # 8000382c <syscall>
  if (killed(p))
    80003418:	8526                	mv	a0,s1
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	4b0080e7          	jalr	1200(ra) # 800028ca <killed>
    80003422:	e935                	bnez	a0,80003496 <usertrap+0x138>
  if (myproc()->state == RUNNING)
    80003424:	fffff097          	auipc	ra,0xfffff
    80003428:	8fa080e7          	jalr	-1798(ra) # 80001d1e <myproc>
  usertrapret();
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	da6080e7          	jalr	-602(ra) # 800031d2 <usertrapret>
}
    80003434:	70a2                	ld	ra,40(sp)
    80003436:	7402                	ld	s0,32(sp)
    80003438:	64e2                	ld	s1,24(sp)
    8000343a:	6942                	ld	s2,16(sp)
    8000343c:	69a2                	ld	s3,8(sp)
    8000343e:	6145                	addi	sp,sp,48
    80003440:	8082                	ret
      exit(-1);
    80003442:	557d                	li	a0,-1
    80003444:	fffff097          	auipc	ra,0xfffff
    80003448:	306080e7          	jalr	774(ra) # 8000274a <exit>
    8000344c:	bf45                	j	800033fc <usertrap+0x9e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000344e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003452:	5890                	lw	a2,48(s1)
    80003454:	00006517          	auipc	a0,0x6
    80003458:	04c50513          	addi	a0,a0,76 # 800094a0 <states.1925+0x78>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	132080e7          	jalr	306(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003464:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003468:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000346c:	00006517          	auipc	a0,0x6
    80003470:	06450513          	addi	a0,a0,100 # 800094d0 <states.1925+0xa8>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	11a080e7          	jalr	282(ra) # 8000058e <printf>
    setkilled(p);
    8000347c:	8526                	mv	a0,s1
    8000347e:	fffff097          	auipc	ra,0xfffff
    80003482:	420080e7          	jalr	1056(ra) # 8000289e <setkilled>
    80003486:	bf49                	j	80003418 <usertrap+0xba>
  if (killed(p))
    80003488:	8526                	mv	a0,s1
    8000348a:	fffff097          	auipc	ra,0xfffff
    8000348e:	440080e7          	jalr	1088(ra) # 800028ca <killed>
    80003492:	c901                	beqz	a0,800034a2 <usertrap+0x144>
    80003494:	a011                	j	80003498 <usertrap+0x13a>
    80003496:	4901                	li	s2,0
    exit(-1);
    80003498:	557d                	li	a0,-1
    8000349a:	fffff097          	auipc	ra,0xfffff
    8000349e:	2b0080e7          	jalr	688(ra) # 8000274a <exit>
  if (which_dev == 2)
    800034a2:	4789                	li	a5,2
    800034a4:	f8f910e3          	bne	s2,a5,80003424 <usertrap+0xc6>
    p->now_ticks += 1;
    800034a8:	1784a783          	lw	a5,376(s1)
    800034ac:	2785                	addiw	a5,a5,1
    800034ae:	0007871b          	sext.w	a4,a5
    800034b2:	16f4ac23          	sw	a5,376(s1)
    if (p->ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    800034b6:	1744a783          	lw	a5,372(s1)
    800034ba:	04f05663          	blez	a5,80003506 <usertrap+0x1a8>
    800034be:	04f74463          	blt	a4,a5,80003506 <usertrap+0x1a8>
    800034c2:	1704a783          	lw	a5,368(s1)
    800034c6:	e3a1                	bnez	a5,80003506 <usertrap+0x1a8>
      p->now_ticks = 0;
    800034c8:	1604ac23          	sw	zero,376(s1)
      p->is_sigalarm = 1;
    800034cc:	4785                	li	a5,1
    800034ce:	16f4a823          	sw	a5,368(s1)
      *(p->trapframe_copy) = *(p->trapframe);
    800034d2:	70b4                	ld	a3,96(s1)
    800034d4:	87b6                	mv	a5,a3
    800034d6:	1884b703          	ld	a4,392(s1)
    800034da:	12068693          	addi	a3,a3,288
    800034de:	0007b803          	ld	a6,0(a5)
    800034e2:	6788                	ld	a0,8(a5)
    800034e4:	6b8c                	ld	a1,16(a5)
    800034e6:	6f90                	ld	a2,24(a5)
    800034e8:	01073023          	sd	a6,0(a4)
    800034ec:	e708                	sd	a0,8(a4)
    800034ee:	eb0c                	sd	a1,16(a4)
    800034f0:	ef10                	sd	a2,24(a4)
    800034f2:	02078793          	addi	a5,a5,32
    800034f6:	02070713          	addi	a4,a4,32
    800034fa:	fed792e3          	bne	a5,a3,800034de <usertrap+0x180>
      p->trapframe->epc = p->handler;
    800034fe:	70bc                	ld	a5,96(s1)
    80003500:	1804b703          	ld	a4,384(s1)
    80003504:	ef98                	sd	a4,24(a5)
  if (myproc()->state == RUNNING)
    80003506:	fffff097          	auipc	ra,0xfffff
    8000350a:	818080e7          	jalr	-2024(ra) # 80001d1e <myproc>
    8000350e:	4d18                	lw	a4,24(a0)
    80003510:	4791                	li	a5,4
    80003512:	f0f71de3          	bne	a4,a5,8000342c <usertrap+0xce>
    if (which_dev == 2 && myproc())
    80003516:	fffff097          	auipc	ra,0xfffff
    8000351a:	808080e7          	jalr	-2040(ra) # 80001d1e <myproc>
    8000351e:	d519                	beqz	a0,8000342c <usertrap+0xce>
      struct proc *p = myproc();
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	7fe080e7          	jalr	2046(ra) # 80001d1e <myproc>
    80003528:	89aa                	mv	s3,a0
      if (p->quanta <= 0)
    8000352a:	1d052783          	lw	a5,464(a0)
    8000352e:	00f05c63          	blez	a5,80003546 <usertrap+0x1e8>
      while ( j< p->priority)
    80003532:	1a09a783          	lw	a5,416(s3)
    80003536:	ee078be3          	beqz	a5,8000342c <usertrap+0xce>
    8000353a:	00237497          	auipc	s1,0x237
    8000353e:	1ce48493          	addi	s1,s1,462 # 8023a708 <mlfq+0x210>
    80003542:	4901                	li	s2,0
    80003544:	a805                	j	80003574 <usertrap+0x216>
        if(p->priority + 1 != NMLFQ) p->priority++;
    80003546:	1a052783          	lw	a5,416(a0)
    8000354a:	4711                	li	a4,4
    8000354c:	00e78563          	beq	a5,a4,80003556 <usertrap+0x1f8>
    80003550:	2785                	addiw	a5,a5,1
    80003552:	1af52023          	sw	a5,416(a0)
        yield();
    80003556:	fffff097          	auipc	ra,0xfffff
    8000355a:	084080e7          	jalr	132(ra) # 800025da <yield>
    8000355e:	bfd1                	j	80003532 <usertrap+0x1d4>
        j++;
    80003560:	0019079b          	addiw	a5,s2,1
    80003564:	0007891b          	sext.w	s2,a5
      while ( j< p->priority)
    80003568:	21848493          	addi	s1,s1,536
    8000356c:	1a09a703          	lw	a4,416(s3)
    80003570:	eae97ee3          	bgeu	s2,a4,8000342c <usertrap+0xce>
        if (mlfq[j].size)
    80003574:	409c                	lw	a5,0(s1)
    80003576:	d7ed                	beqz	a5,80003560 <usertrap+0x202>
          yield();
    80003578:	fffff097          	auipc	ra,0xfffff
    8000357c:	062080e7          	jalr	98(ra) # 800025da <yield>
    80003580:	b7c5                	j	80003560 <usertrap+0x202>

0000000080003582 <kerneltrap>:
{
    80003582:	7139                	addi	sp,sp,-64
    80003584:	fc06                	sd	ra,56(sp)
    80003586:	f822                	sd	s0,48(sp)
    80003588:	f426                	sd	s1,40(sp)
    8000358a:	f04a                	sd	s2,32(sp)
    8000358c:	ec4e                	sd	s3,24(sp)
    8000358e:	e852                	sd	s4,16(sp)
    80003590:	e456                	sd	s5,8(sp)
    80003592:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003594:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003598:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000359c:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800035a0:	1004f793          	andi	a5,s1,256
    800035a4:	cb95                	beqz	a5,800035d8 <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800035aa:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800035ac:	ef95                	bnez	a5,800035e8 <kerneltrap+0x66>
  if ((which_dev = devintr()) == 0)
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	d0e080e7          	jalr	-754(ra) # 800032bc <devintr>
    800035b6:	c129                	beqz	a0,800035f8 <kerneltrap+0x76>
  if (which_dev == 2 && myproc() != 0)
    800035b8:	4789                	li	a5,2
    800035ba:	06f50c63          	beq	a0,a5,80003632 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035be:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035c2:	10049073          	csrw	sstatus,s1
}
    800035c6:	70e2                	ld	ra,56(sp)
    800035c8:	7442                	ld	s0,48(sp)
    800035ca:	74a2                	ld	s1,40(sp)
    800035cc:	7902                	ld	s2,32(sp)
    800035ce:	69e2                	ld	s3,24(sp)
    800035d0:	6a42                	ld	s4,16(sp)
    800035d2:	6aa2                	ld	s5,8(sp)
    800035d4:	6121                	addi	sp,sp,64
    800035d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035d8:	00006517          	auipc	a0,0x6
    800035dc:	f1850513          	addi	a0,a0,-232 # 800094f0 <states.1925+0xc8>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	f64080e7          	jalr	-156(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800035e8:	00006517          	auipc	a0,0x6
    800035ec:	f3050513          	addi	a0,a0,-208 # 80009518 <states.1925+0xf0>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f54080e7          	jalr	-172(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800035f8:	85ce                	mv	a1,s3
    800035fa:	00006517          	auipc	a0,0x6
    800035fe:	f3e50513          	addi	a0,a0,-194 # 80009538 <states.1925+0x110>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	f8c080e7          	jalr	-116(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000360a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000360e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003612:	00006517          	auipc	a0,0x6
    80003616:	f3650513          	addi	a0,a0,-202 # 80009548 <states.1925+0x120>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	f74080e7          	jalr	-140(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003622:	00006517          	auipc	a0,0x6
    80003626:	f3e50513          	addi	a0,a0,-194 # 80009560 <states.1925+0x138>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f1a080e7          	jalr	-230(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0)
    80003632:	ffffe097          	auipc	ra,0xffffe
    80003636:	6ec080e7          	jalr	1772(ra) # 80001d1e <myproc>
    8000363a:	d151                	beqz	a0,800035be <kerneltrap+0x3c>
    if (myproc()->state == RUNNING)
    8000363c:	ffffe097          	auipc	ra,0xffffe
    80003640:	6e2080e7          	jalr	1762(ra) # 80001d1e <myproc>
    80003644:	4d18                	lw	a4,24(a0)
    80003646:	4791                	li	a5,4
    80003648:	f6f71be3          	bne	a4,a5,800035be <kerneltrap+0x3c>
      struct proc *p = myproc();
    8000364c:	ffffe097          	auipc	ra,0xffffe
    80003650:	6d2080e7          	jalr	1746(ra) # 80001d1e <myproc>
    80003654:	8aaa                	mv	s5,a0
      if (p->quanta <= 0)
    80003656:	1d052783          	lw	a5,464(a0)
    8000365a:	00f05b63          	blez	a5,80003670 <kerneltrap+0xee>
      while (i < p->priority)
    8000365e:	1a0aa783          	lw	a5,416(s5)
    80003662:	dfb1                	beqz	a5,800035be <kerneltrap+0x3c>
    80003664:	00237997          	auipc	s3,0x237
    80003668:	0a498993          	addi	s3,s3,164 # 8023a708 <mlfq+0x210>
    8000366c:	4a01                	li	s4,0
    8000366e:	a805                	j	8000369e <kerneltrap+0x11c>
        if (p->priority + 1 != NMLFQ)
    80003670:	1a052783          	lw	a5,416(a0)
    80003674:	4711                	li	a4,4
    80003676:	00e78563          	beq	a5,a4,80003680 <kerneltrap+0xfe>
          p->priority++;
    8000367a:	2785                	addiw	a5,a5,1
    8000367c:	1af52023          	sw	a5,416(a0)
        yield();
    80003680:	fffff097          	auipc	ra,0xfffff
    80003684:	f5a080e7          	jalr	-166(ra) # 800025da <yield>
    80003688:	bfd9                	j	8000365e <kerneltrap+0xdc>
        i++;
    8000368a:	001a079b          	addiw	a5,s4,1
    8000368e:	00078a1b          	sext.w	s4,a5
      while (i < p->priority)
    80003692:	21898993          	addi	s3,s3,536
    80003696:	1a0aa703          	lw	a4,416(s5)
    8000369a:	f2ea72e3          	bgeu	s4,a4,800035be <kerneltrap+0x3c>
        if (mlfq[i].size)
    8000369e:	0009a783          	lw	a5,0(s3)
    800036a2:	d7e5                	beqz	a5,8000368a <kerneltrap+0x108>
          yield();
    800036a4:	fffff097          	auipc	ra,0xfffff
    800036a8:	f36080e7          	jalr	-202(ra) # 800025da <yield>
    800036ac:	bff9                	j	8000368a <kerneltrap+0x108>

00000000800036ae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800036ae:	1101                	addi	sp,sp,-32
    800036b0:	ec06                	sd	ra,24(sp)
    800036b2:	e822                	sd	s0,16(sp)
    800036b4:	e426                	sd	s1,8(sp)
    800036b6:	1000                	addi	s0,sp,32
    800036b8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800036ba:	ffffe097          	auipc	ra,0xffffe
    800036be:	664080e7          	jalr	1636(ra) # 80001d1e <myproc>
  switch (n) {
    800036c2:	4795                	li	a5,5
    800036c4:	0497e163          	bltu	a5,s1,80003706 <argraw+0x58>
    800036c8:	048a                	slli	s1,s1,0x2
    800036ca:	00006717          	auipc	a4,0x6
    800036ce:	fde70713          	addi	a4,a4,-34 # 800096a8 <states.1925+0x280>
    800036d2:	94ba                	add	s1,s1,a4
    800036d4:	409c                	lw	a5,0(s1)
    800036d6:	97ba                	add	a5,a5,a4
    800036d8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800036da:	713c                	ld	a5,96(a0)
    800036dc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret
    return p->trapframe->a1;
    800036e8:	713c                	ld	a5,96(a0)
    800036ea:	7fa8                	ld	a0,120(a5)
    800036ec:	bfcd                	j	800036de <argraw+0x30>
    return p->trapframe->a2;
    800036ee:	713c                	ld	a5,96(a0)
    800036f0:	63c8                	ld	a0,128(a5)
    800036f2:	b7f5                	j	800036de <argraw+0x30>
    return p->trapframe->a3;
    800036f4:	713c                	ld	a5,96(a0)
    800036f6:	67c8                	ld	a0,136(a5)
    800036f8:	b7dd                	j	800036de <argraw+0x30>
    return p->trapframe->a4;
    800036fa:	713c                	ld	a5,96(a0)
    800036fc:	6bc8                	ld	a0,144(a5)
    800036fe:	b7c5                	j	800036de <argraw+0x30>
    return p->trapframe->a5;
    80003700:	713c                	ld	a5,96(a0)
    80003702:	6fc8                	ld	a0,152(a5)
    80003704:	bfe9                	j	800036de <argraw+0x30>
  panic("argraw");
    80003706:	00006517          	auipc	a0,0x6
    8000370a:	e6a50513          	addi	a0,a0,-406 # 80009570 <states.1925+0x148>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e36080e7          	jalr	-458(ra) # 80000544 <panic>

0000000080003716 <fetchaddr>:
{
    80003716:	1101                	addi	sp,sp,-32
    80003718:	ec06                	sd	ra,24(sp)
    8000371a:	e822                	sd	s0,16(sp)
    8000371c:	e426                	sd	s1,8(sp)
    8000371e:	e04a                	sd	s2,0(sp)
    80003720:	1000                	addi	s0,sp,32
    80003722:	84aa                	mv	s1,a0
    80003724:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003726:	ffffe097          	auipc	ra,0xffffe
    8000372a:	5f8080e7          	jalr	1528(ra) # 80001d1e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000372e:	693c                	ld	a5,80(a0)
    80003730:	02f4f863          	bgeu	s1,a5,80003760 <fetchaddr+0x4a>
    80003734:	00848713          	addi	a4,s1,8
    80003738:	02e7e663          	bltu	a5,a4,80003764 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000373c:	46a1                	li	a3,8
    8000373e:	8626                	mv	a2,s1
    80003740:	85ca                	mv	a1,s2
    80003742:	6d28                	ld	a0,88(a0)
    80003744:	ffffe097          	auipc	ra,0xffffe
    80003748:	2ca080e7          	jalr	714(ra) # 80001a0e <copyin>
    8000374c:	00a03533          	snez	a0,a0
    80003750:	40a00533          	neg	a0,a0
}
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6902                	ld	s2,0(sp)
    8000375c:	6105                	addi	sp,sp,32
    8000375e:	8082                	ret
    return -1;
    80003760:	557d                	li	a0,-1
    80003762:	bfcd                	j	80003754 <fetchaddr+0x3e>
    80003764:	557d                	li	a0,-1
    80003766:	b7fd                	j	80003754 <fetchaddr+0x3e>

0000000080003768 <fetchstr>:
{
    80003768:	7179                	addi	sp,sp,-48
    8000376a:	f406                	sd	ra,40(sp)
    8000376c:	f022                	sd	s0,32(sp)
    8000376e:	ec26                	sd	s1,24(sp)
    80003770:	e84a                	sd	s2,16(sp)
    80003772:	e44e                	sd	s3,8(sp)
    80003774:	1800                	addi	s0,sp,48
    80003776:	892a                	mv	s2,a0
    80003778:	84ae                	mv	s1,a1
    8000377a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000377c:	ffffe097          	auipc	ra,0xffffe
    80003780:	5a2080e7          	jalr	1442(ra) # 80001d1e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003784:	86ce                	mv	a3,s3
    80003786:	864a                	mv	a2,s2
    80003788:	85a6                	mv	a1,s1
    8000378a:	6d28                	ld	a0,88(a0)
    8000378c:	ffffe097          	auipc	ra,0xffffe
    80003790:	30e080e7          	jalr	782(ra) # 80001a9a <copyinstr>
    80003794:	00054e63          	bltz	a0,800037b0 <fetchstr+0x48>
  return strlen(buf);
    80003798:	8526                	mv	a0,s1
    8000379a:	ffffe097          	auipc	ra,0xffffe
    8000379e:	992080e7          	jalr	-1646(ra) # 8000112c <strlen>
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
    return -1;
    800037b0:	557d                	li	a0,-1
    800037b2:	bfc5                	j	800037a2 <fetchstr+0x3a>

00000000800037b4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	1000                	addi	s0,sp,32
    800037be:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	eee080e7          	jalr	-274(ra) # 800036ae <argraw>
    800037c8:	c088                	sw	a0,0(s1)
}
    800037ca:	60e2                	ld	ra,24(sp)
    800037cc:	6442                	ld	s0,16(sp)
    800037ce:	64a2                	ld	s1,8(sp)
    800037d0:	6105                	addi	sp,sp,32
    800037d2:	8082                	ret

00000000800037d4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800037d4:	1101                	addi	sp,sp,-32
    800037d6:	ec06                	sd	ra,24(sp)
    800037d8:	e822                	sd	s0,16(sp)
    800037da:	e426                	sd	s1,8(sp)
    800037dc:	1000                	addi	s0,sp,32
    800037de:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	ece080e7          	jalr	-306(ra) # 800036ae <argraw>
    800037e8:	e088                	sd	a0,0(s1)
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret

00000000800037f4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800037f4:	7179                	addi	sp,sp,-48
    800037f6:	f406                	sd	ra,40(sp)
    800037f8:	f022                	sd	s0,32(sp)
    800037fa:	ec26                	sd	s1,24(sp)
    800037fc:	e84a                	sd	s2,16(sp)
    800037fe:	1800                	addi	s0,sp,48
    80003800:	84ae                	mv	s1,a1
    80003802:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003804:	fd840593          	addi	a1,s0,-40
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	fcc080e7          	jalr	-52(ra) # 800037d4 <argaddr>
  return fetchstr(addr, buf, max);
    80003810:	864a                	mv	a2,s2
    80003812:	85a6                	mv	a1,s1
    80003814:	fd843503          	ld	a0,-40(s0)
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	f50080e7          	jalr	-176(ra) # 80003768 <fetchstr>
}
    80003820:	70a2                	ld	ra,40(sp)
    80003822:	7402                	ld	s0,32(sp)
    80003824:	64e2                	ld	s1,24(sp)
    80003826:	6942                	ld	s2,16(sp)
    80003828:	6145                	addi	sp,sp,48
    8000382a:	8082                	ret

000000008000382c <syscall>:
[SYS_waitx] sys_waitx,
};

void
syscall(void)
{
    8000382c:	7139                	addi	sp,sp,-64
    8000382e:	fc06                	sd	ra,56(sp)
    80003830:	f822                	sd	s0,48(sp)
    80003832:	f426                	sd	s1,40(sp)
    80003834:	f04a                	sd	s2,32(sp)
    80003836:	ec4e                	sd	s3,24(sp)
    80003838:	e852                	sd	s4,16(sp)
    8000383a:	e456                	sd	s5,8(sp)
    8000383c:	e05a                	sd	s6,0(sp)
    8000383e:	0080                	addi	s0,sp,64

arguments[1]=0;
    80003840:	00237797          	auipc	a5,0x237
    80003844:	74878793          	addi	a5,a5,1864 # 8023af88 <arguments>
    80003848:	0007a223          	sw	zero,4(a5)
arguments[2]=1;
    8000384c:	4705                	li	a4,1
    8000384e:	c798                	sw	a4,8(a5)
arguments[3]=1;
    80003850:	c7d8                	sw	a4,12(a5)
arguments[4]=0;
    80003852:	0007a823          	sw	zero,16(a5)
arguments[5]=3;
    80003856:	460d                	li	a2,3
    80003858:	cbd0                	sw	a2,20(a5)
arguments[6]=2;
    8000385a:	4689                	li	a3,2
    8000385c:	cf94                	sw	a3,24(a5)
arguments[7]=2;
    8000385e:	cfd4                	sw	a3,28(a5)
arguments[8]=1;
    80003860:	d398                	sw	a4,32(a5)
arguments[9]=1;
    80003862:	d3d8                	sw	a4,36(a5)
arguments[10]=1;
    80003864:	d798                	sw	a4,40(a5)
arguments[11]=0;
    80003866:	0207a623          	sw	zero,44(a5)
arguments[12]=1;
    8000386a:	db98                	sw	a4,48(a5)
arguments[13]=1;
    8000386c:	dbd8                	sw	a4,52(a5)
arguments[14]=0;
    8000386e:	0207ac23          	sw	zero,56(a5)
arguments[15]=2;
    80003872:	dfd4                	sw	a3,60(a5)
arguments[16]=3;
    80003874:	c3b0                	sw	a2,64(a5)
arguments[17]=3;
    80003876:	c3f0                	sw	a2,68(a5)
arguments[18]=1;
    80003878:	c7b8                	sw	a4,72(a5)
arguments[19]=2;
    8000387a:	c7f4                	sw	a3,76(a5)
arguments[20]=1;
    8000387c:	cbb8                	sw	a4,80(a5)
arguments[21]=1;
    8000387e:	cbf8                	sw	a4,84(a5)
arguments[24]=1;
    80003880:	d3b8                	sw	a4,96(a5)
arguments[22]=2;
    80003882:	cfb4                	sw	a3,88(a5)
arguments[23]=2;
    80003884:	cff4                	sw	a3,92(a5)
arguments[25]=2;
    80003886:	d3f4                	sw	a3,100(a5)
arguments[26]=3;
    80003888:	d7b0                	sw	a2,104(a5)

char *temp;

  int num;
  struct proc *p = myproc();
    8000388a:	ffffe097          	auipc	ra,0xffffe
    8000388e:	494080e7          	jalr	1172(ra) # 80001d1e <myproc>
    80003892:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80003894:	713c                	ld	a5,96(a0)
    80003896:	77dc                	ld	a5,168(a5)
    80003898:	0007849b          	sext.w	s1,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000389c:	37fd                	addiw	a5,a5,-1
    8000389e:	4765                	li	a4,25
    800038a0:	22f76663          	bltu	a4,a5,80003acc <syscall+0x2a0>
    800038a4:	00349713          	slli	a4,s1,0x3
    800038a8:	00006797          	auipc	a5,0x6
    800038ac:	e1878793          	addi	a5,a5,-488 # 800096c0 <syscalls>
    800038b0:	97ba                	add	a5,a5,a4
    800038b2:	0007ba03          	ld	s4,0(a5)
    800038b6:	200a0b63          	beqz	s4,80003acc <syscall+0x2a0>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

  if(num==1) temp="fork";
  if(num==2) temp="exit";
    800038ba:	4789                	li	a5,2
    800038bc:	0ef48963          	beq	s1,a5,800039ae <syscall+0x182>
  if(num==3) temp="wait";
    800038c0:	478d                	li	a5,3
    800038c2:	00006997          	auipc	s3,0x6
    800038c6:	cc698993          	addi	s3,s3,-826 # 80009588 <states.1925+0x160>
    800038ca:	06f49463          	bne	s1,a5,80003932 <syscall+0x106>
  if(num==4) temp="pipe";
  if(num==5) temp="read";
  if(num==6) temp="kill";
    800038ce:	4799                	li	a5,6
    800038d0:	06f49863          	bne	s1,a5,80003940 <syscall+0x114>
    800038d4:	00006997          	auipc	s3,0x6
    800038d8:	cc498993          	addi	s3,s3,-828 # 80009598 <states.1925+0x170>
  if(num==7) temp="exec";
  if(num==8) temp="fstat";
  if(num==9) temp="chdir";
    800038dc:	47a5                	li	a5,9
    800038de:	06f49863          	bne	s1,a5,8000394e <syscall+0x122>
    800038e2:	00006997          	auipc	s3,0x6
    800038e6:	cce98993          	addi	s3,s3,-818 # 800095b0 <states.1925+0x188>
  if(num==10) temp="dup";
  if(num==11) temp="getpid";
  if(num==12) temp="sbrk";
    800038ea:	47b1                	li	a5,12
    800038ec:	06f49863          	bne	s1,a5,8000395c <syscall+0x130>
    800038f0:	00006997          	auipc	s3,0x6
    800038f4:	cd898993          	addi	s3,s3,-808 # 800095c8 <states.1925+0x1a0>
  if(num==13) temp="sleep";
  if(num==14) temp="uptime";
  if(num==15) temp="open";
    800038f8:	47bd                	li	a5,15
    800038fa:	06f49863          	bne	s1,a5,8000396a <syscall+0x13e>
    800038fe:	00006997          	auipc	s3,0x6
    80003902:	ce298993          	addi	s3,s3,-798 # 800095e0 <states.1925+0x1b8>
  if(num==16) temp="write";
  if(num==17) temp="mknod";
  if(num==18) temp="unlink";
    80003906:	47c9                	li	a5,18
    80003908:	06f49863          	bne	s1,a5,80003978 <syscall+0x14c>
    8000390c:	00006997          	auipc	s3,0x6
    80003910:	cec98993          	addi	s3,s3,-788 # 800095f8 <states.1925+0x1d0>
  if(num==19) temp="link";
  if(num==20) temp="mkdir";
  if(num==21) temp="close";
    80003914:	47d5                	li	a5,21
    80003916:	06f49863          	bne	s1,a5,80003986 <syscall+0x15a>
    8000391a:	00006997          	auipc	s3,0x6
    8000391e:	cf698993          	addi	s3,s3,-778 # 80009610 <states.1925+0x1e8>
  if(num==22) temp="sigalarm";
  if(num==23) temp="sigreturn";
  if(num==24) temp="trace";
    80003922:	47e1                	li	a5,24
    80003924:	06f49863          	bne	s1,a5,80003994 <syscall+0x168>
    80003928:	00006997          	auipc	s3,0x6
    8000392c:	d1098993          	addi	s3,s3,-752 # 80009638 <states.1925+0x210>
    80003930:	a8dd                	j	80003a26 <syscall+0x1fa>
  if(num==4) temp="pipe";
    80003932:	4791                	li	a5,4
    80003934:	00006997          	auipc	s3,0x6
    80003938:	c5c98993          	addi	s3,s3,-932 # 80009590 <states.1925+0x168>
    8000393c:	06f49463          	bne	s1,a5,800039a4 <syscall+0x178>
  if(num==7) temp="exec";
    80003940:	479d                	li	a5,7
    80003942:	08f49163          	bne	s1,a5,800039c4 <syscall+0x198>
    80003946:	00006997          	auipc	s3,0x6
    8000394a:	c5a98993          	addi	s3,s3,-934 # 800095a0 <states.1925+0x178>
  if(num==10) temp="dup";
    8000394e:	47a9                	li	a5,10
    80003950:	08f49163          	bne	s1,a5,800039d2 <syscall+0x1a6>
    80003954:	00006997          	auipc	s3,0x6
    80003958:	c6498993          	addi	s3,s3,-924 # 800095b8 <states.1925+0x190>
  if(num==13) temp="sleep";
    8000395c:	47b5                	li	a5,13
    8000395e:	08f49163          	bne	s1,a5,800039e0 <syscall+0x1b4>
    80003962:	00006997          	auipc	s3,0x6
    80003966:	c6e98993          	addi	s3,s3,-914 # 800095d0 <states.1925+0x1a8>
  if(num==16) temp="write";
    8000396a:	47c1                	li	a5,16
    8000396c:	08f49163          	bne	s1,a5,800039ee <syscall+0x1c2>
    80003970:	00006997          	auipc	s3,0x6
    80003974:	c7898993          	addi	s3,s3,-904 # 800095e8 <states.1925+0x1c0>
  if(num==19) temp="link";
    80003978:	47cd                	li	a5,19
    8000397a:	08f49163          	bne	s1,a5,800039fc <syscall+0x1d0>
    8000397e:	00006997          	auipc	s3,0x6
    80003982:	c8298993          	addi	s3,s3,-894 # 80009600 <states.1925+0x1d8>
  if(num==22) temp="sigalarm";
    80003986:	47d9                	li	a5,22
    80003988:	08f49163          	bne	s1,a5,80003a0a <syscall+0x1de>
    8000398c:	00006997          	auipc	s3,0x6
    80003990:	c8c98993          	addi	s3,s3,-884 # 80009618 <states.1925+0x1f0>
  if(num==25) temp="set_priority";
    80003994:	47e5                	li	a5,25
    80003996:	08f49163          	bne	s1,a5,80003a18 <syscall+0x1ec>
    8000399a:	00006997          	auipc	s3,0x6
    8000399e:	ca698993          	addi	s3,s3,-858 # 80009640 <states.1925+0x218>
    800039a2:	a051                	j	80003a26 <syscall+0x1fa>
    800039a4:	00006997          	auipc	s3,0x6
    800039a8:	bdc98993          	addi	s3,s3,-1060 # 80009580 <states.1925+0x158>
    800039ac:	a029                	j	800039b6 <syscall+0x18a>
  if(num==2) temp="exit";
    800039ae:	00006997          	auipc	s3,0x6
    800039b2:	bca98993          	addi	s3,s3,-1078 # 80009578 <states.1925+0x150>
  if(num==5) temp="read";
    800039b6:	4795                	li	a5,5
    800039b8:	f0f49be3          	bne	s1,a5,800038ce <syscall+0xa2>
    800039bc:	00006997          	auipc	s3,0x6
    800039c0:	efc98993          	addi	s3,s3,-260 # 800098b8 <syscalls+0x1f8>
  if(num==8) temp="fstat";
    800039c4:	47a1                	li	a5,8
    800039c6:	f0f49be3          	bne	s1,a5,800038dc <syscall+0xb0>
    800039ca:	00006997          	auipc	s3,0x6
    800039ce:	bde98993          	addi	s3,s3,-1058 # 800095a8 <states.1925+0x180>
  if(num==11) temp="getpid";
    800039d2:	47ad                	li	a5,11
    800039d4:	f0f49be3          	bne	s1,a5,800038ea <syscall+0xbe>
    800039d8:	00006997          	auipc	s3,0x6
    800039dc:	be898993          	addi	s3,s3,-1048 # 800095c0 <states.1925+0x198>
  if(num==14) temp="uptime";
    800039e0:	47b9                	li	a5,14
    800039e2:	f0f49be3          	bne	s1,a5,800038f8 <syscall+0xcc>
    800039e6:	00006997          	auipc	s3,0x6
    800039ea:	bf298993          	addi	s3,s3,-1038 # 800095d8 <states.1925+0x1b0>
  if(num==17) temp="mknod";
    800039ee:	47c5                	li	a5,17
    800039f0:	f0f49be3          	bne	s1,a5,80003906 <syscall+0xda>
    800039f4:	00006997          	auipc	s3,0x6
    800039f8:	bfc98993          	addi	s3,s3,-1028 # 800095f0 <states.1925+0x1c8>
  if(num==20) temp="mkdir";
    800039fc:	47d1                	li	a5,20
    800039fe:	f0f49be3          	bne	s1,a5,80003914 <syscall+0xe8>
    80003a02:	00006997          	auipc	s3,0x6
    80003a06:	c0698993          	addi	s3,s3,-1018 # 80009608 <states.1925+0x1e0>
  if(num==23) temp="sigreturn";
    80003a0a:	47dd                	li	a5,23
    80003a0c:	f0f49be3          	bne	s1,a5,80003922 <syscall+0xf6>
    80003a10:	00006997          	auipc	s3,0x6
    80003a14:	c1898993          	addi	s3,s3,-1000 # 80009628 <states.1925+0x200>
  if(num==26) temp="waitx";
    80003a18:	47e9                	li	a5,26
    80003a1a:	00f49663          	bne	s1,a5,80003a26 <syscall+0x1fa>
    80003a1e:	00006997          	auipc	s3,0x6
    80003a22:	c3298993          	addi	s3,s3,-974 # 80009650 <states.1925+0x228>
  

  if(flag==1)
    80003a26:	00006717          	auipc	a4,0x6
    80003a2a:	15672703          	lw	a4,342(a4) # 80009b7c <flag>
    80003a2e:	4785                	li	a5,1
    80003a30:	00f70863          	beq	a4,a5,80003a40 <syscall+0x214>
      for(int i=0;i<arguments[num];i++)
      printf("%d ",argraw(i));
      printf(") -> %d\n",p->trapframe->a0);
    }
  }
    p->trapframe->a0 = syscalls[num]();
    80003a34:	06093903          	ld	s2,96(s2)
    80003a38:	9a02                	jalr	s4
    80003a3a:	06a93823          	sd	a0,112(s2)
    80003a3e:	a845                	j	80003aee <syscall+0x2c2>
    if(uni_mask&(1<<num))
    80003a40:	00006797          	auipc	a5,0x6
    80003a44:	1407a783          	lw	a5,320(a5) # 80009b80 <uni_mask>
    80003a48:	4097d7bb          	sraw	a5,a5,s1
    80003a4c:	8b85                	andi	a5,a5,1
    80003a4e:	d3fd                	beqz	a5,80003a34 <syscall+0x208>
      printf("%d: syscall %s ( ",sys_getpid(),temp);
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	0ee080e7          	jalr	238(ra) # 80003b3e <sys_getpid>
    80003a58:	85aa                	mv	a1,a0
    80003a5a:	864e                	mv	a2,s3
    80003a5c:	00006517          	auipc	a0,0x6
    80003a60:	bfc50513          	addi	a0,a0,-1028 # 80009658 <states.1925+0x230>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	b2a080e7          	jalr	-1238(ra) # 8000058e <printf>
      for(int i=0;i<arguments[num];i++)
    80003a6c:	00249713          	slli	a4,s1,0x2
    80003a70:	00237797          	auipc	a5,0x237
    80003a74:	51878793          	addi	a5,a5,1304 # 8023af88 <arguments>
    80003a78:	97ba                	add	a5,a5,a4
    80003a7a:	439c                	lw	a5,0(a5)
    80003a7c:	02f05c63          	blez	a5,80003ab4 <syscall+0x288>
    80003a80:	4981                	li	s3,0
      printf("%d ",argraw(i));
    80003a82:	00006b17          	auipc	s6,0x6
    80003a86:	beeb0b13          	addi	s6,s6,-1042 # 80009670 <states.1925+0x248>
      for(int i=0;i<arguments[num];i++)
    80003a8a:	00237a97          	auipc	s5,0x237
    80003a8e:	4fea8a93          	addi	s5,s5,1278 # 8023af88 <arguments>
    80003a92:	9aba                	add	s5,s5,a4
      printf("%d ",argraw(i));
    80003a94:	854e                	mv	a0,s3
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	c18080e7          	jalr	-1000(ra) # 800036ae <argraw>
    80003a9e:	85aa                	mv	a1,a0
    80003aa0:	855a                	mv	a0,s6
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	aec080e7          	jalr	-1300(ra) # 8000058e <printf>
      for(int i=0;i<arguments[num];i++)
    80003aaa:	2985                	addiw	s3,s3,1
    80003aac:	000aa783          	lw	a5,0(s5)
    80003ab0:	fef9c2e3          	blt	s3,a5,80003a94 <syscall+0x268>
      printf(") -> %d\n",p->trapframe->a0);
    80003ab4:	06093783          	ld	a5,96(s2)
    80003ab8:	7bac                	ld	a1,112(a5)
    80003aba:	00006517          	auipc	a0,0x6
    80003abe:	bbe50513          	addi	a0,a0,-1090 # 80009678 <states.1925+0x250>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	acc080e7          	jalr	-1332(ra) # 8000058e <printf>
    80003aca:	b7ad                	j	80003a34 <syscall+0x208>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003acc:	86a6                	mv	a3,s1
    80003ace:	16090613          	addi	a2,s2,352
    80003ad2:	03092583          	lw	a1,48(s2)
    80003ad6:	00006517          	auipc	a0,0x6
    80003ada:	bb250513          	addi	a0,a0,-1102 # 80009688 <states.1925+0x260>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	ab0080e7          	jalr	-1360(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003ae6:	06093783          	ld	a5,96(s2)
    80003aea:	577d                	li	a4,-1
    80003aec:	fbb8                	sd	a4,112(a5)
  }
  if(num==3) flag=0;
    80003aee:	478d                	li	a5,3
    80003af0:	00f48c63          	beq	s1,a5,80003b08 <syscall+0x2dc>
    80003af4:	70e2                	ld	ra,56(sp)
    80003af6:	7442                	ld	s0,48(sp)
    80003af8:	74a2                	ld	s1,40(sp)
    80003afa:	7902                	ld	s2,32(sp)
    80003afc:	69e2                	ld	s3,24(sp)
    80003afe:	6a42                	ld	s4,16(sp)
    80003b00:	6aa2                	ld	s5,8(sp)
    80003b02:	6b02                	ld	s6,0(sp)
    80003b04:	6121                	addi	sp,sp,64
    80003b06:	8082                	ret
  if(num==3) flag=0;
    80003b08:	00006797          	auipc	a5,0x6
    80003b0c:	0607aa23          	sw	zero,116(a5) # 80009b7c <flag>
    80003b10:	b7d5                	j	80003af4 <syscall+0x2c8>

0000000080003b12 <sys_exit>:
int uni_mask=0;
int flag=0;

uint64
sys_exit(void)
{
    80003b12:	1101                	addi	sp,sp,-32
    80003b14:	ec06                	sd	ra,24(sp)
    80003b16:	e822                	sd	s0,16(sp)
    80003b18:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003b1a:	fec40593          	addi	a1,s0,-20
    80003b1e:	4501                	li	a0,0
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	c94080e7          	jalr	-876(ra) # 800037b4 <argint>
  exit(n);
    80003b28:	fec42503          	lw	a0,-20(s0)
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	c1e080e7          	jalr	-994(ra) # 8000274a <exit>
  return 0;  // not reached
}
    80003b34:	4501                	li	a0,0
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	6105                	addi	sp,sp,32
    80003b3c:	8082                	ret

0000000080003b3e <sys_getpid>:

uint64
sys_getpid(void)
{
    80003b3e:	1141                	addi	sp,sp,-16
    80003b40:	e406                	sd	ra,8(sp)
    80003b42:	e022                	sd	s0,0(sp)
    80003b44:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003b46:	ffffe097          	auipc	ra,0xffffe
    80003b4a:	1d8080e7          	jalr	472(ra) # 80001d1e <myproc>
}
    80003b4e:	5908                	lw	a0,48(a0)
    80003b50:	60a2                	ld	ra,8(sp)
    80003b52:	6402                	ld	s0,0(sp)
    80003b54:	0141                	addi	sp,sp,16
    80003b56:	8082                	ret

0000000080003b58 <sys_fork>:

uint64
sys_fork(void)
{
    80003b58:	1141                	addi	sp,sp,-16
    80003b5a:	e406                	sd	ra,8(sp)
    80003b5c:	e022                	sd	s0,0(sp)
    80003b5e:	0800                	addi	s0,sp,16
  return fork();
    80003b60:	ffffe097          	auipc	ra,0xffffe
    80003b64:	73c080e7          	jalr	1852(ra) # 8000229c <fork>
}
    80003b68:	60a2                	ld	ra,8(sp)
    80003b6a:	6402                	ld	s0,0(sp)
    80003b6c:	0141                	addi	sp,sp,16
    80003b6e:	8082                	ret

0000000080003b70 <sys_wait>:

uint64
sys_wait(void)
{
    80003b70:	1101                	addi	sp,sp,-32
    80003b72:	ec06                	sd	ra,24(sp)
    80003b74:	e822                	sd	s0,16(sp)
    80003b76:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003b78:	fe840593          	addi	a1,s0,-24
    80003b7c:	4501                	li	a0,0
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	c56080e7          	jalr	-938(ra) # 800037d4 <argaddr>
  return wait(p);
    80003b86:	fe843503          	ld	a0,-24(s0)
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	d72080e7          	jalr	-654(ra) # 800028fc <wait>
}
    80003b92:	60e2                	ld	ra,24(sp)
    80003b94:	6442                	ld	s0,16(sp)
    80003b96:	6105                	addi	sp,sp,32
    80003b98:	8082                	ret

0000000080003b9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003b9a:	7179                	addi	sp,sp,-48
    80003b9c:	f406                	sd	ra,40(sp)
    80003b9e:	f022                	sd	s0,32(sp)
    80003ba0:	ec26                	sd	s1,24(sp)
    80003ba2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003ba4:	fdc40593          	addi	a1,s0,-36
    80003ba8:	4501                	li	a0,0
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	c0a080e7          	jalr	-1014(ra) # 800037b4 <argint>
  addr = myproc()->sz;
    80003bb2:	ffffe097          	auipc	ra,0xffffe
    80003bb6:	16c080e7          	jalr	364(ra) # 80001d1e <myproc>
    80003bba:	6924                	ld	s1,80(a0)
  if(growproc(n) < 0)
    80003bbc:	fdc42503          	lw	a0,-36(s0)
    80003bc0:	ffffe097          	auipc	ra,0xffffe
    80003bc4:	680080e7          	jalr	1664(ra) # 80002240 <growproc>
    80003bc8:	00054863          	bltz	a0,80003bd8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003bcc:	8526                	mv	a0,s1
    80003bce:	70a2                	ld	ra,40(sp)
    80003bd0:	7402                	ld	s0,32(sp)
    80003bd2:	64e2                	ld	s1,24(sp)
    80003bd4:	6145                	addi	sp,sp,48
    80003bd6:	8082                	ret
    return -1;
    80003bd8:	54fd                	li	s1,-1
    80003bda:	bfcd                	j	80003bcc <sys_sbrk+0x32>

0000000080003bdc <sys_sleep>:

uint64
sys_sleep(void)
{
    80003bdc:	7139                	addi	sp,sp,-64
    80003bde:	fc06                	sd	ra,56(sp)
    80003be0:	f822                	sd	s0,48(sp)
    80003be2:	f426                	sd	s1,40(sp)
    80003be4:	f04a                	sd	s2,32(sp)
    80003be6:	ec4e                	sd	s3,24(sp)
    80003be8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003bea:	fcc40593          	addi	a1,s0,-52
    80003bee:	4501                	li	a0,0
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	bc4080e7          	jalr	-1084(ra) # 800037b4 <argint>
  acquire(&tickslock);
    80003bf8:	00237517          	auipc	a0,0x237
    80003bfc:	37850513          	addi	a0,a0,888 # 8023af70 <tickslock>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	2ac080e7          	jalr	684(ra) # 80000eac <acquire>
  ticks0 = ticks;
    80003c08:	00006917          	auipc	s2,0x6
    80003c0c:	f7092903          	lw	s2,-144(s2) # 80009b78 <ticks>
  while(ticks - ticks0 < n){
    80003c10:	fcc42783          	lw	a5,-52(s0)
    80003c14:	cf9d                	beqz	a5,80003c52 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003c16:	00237997          	auipc	s3,0x237
    80003c1a:	35a98993          	addi	s3,s3,858 # 8023af70 <tickslock>
    80003c1e:	00006497          	auipc	s1,0x6
    80003c22:	f5a48493          	addi	s1,s1,-166 # 80009b78 <ticks>
    if(killed(myproc())){
    80003c26:	ffffe097          	auipc	ra,0xffffe
    80003c2a:	0f8080e7          	jalr	248(ra) # 80001d1e <myproc>
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	c9c080e7          	jalr	-868(ra) # 800028ca <killed>
    80003c36:	ed15                	bnez	a0,80003c72 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003c38:	85ce                	mv	a1,s3
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	9da080e7          	jalr	-1574(ra) # 80002616 <sleep>
  while(ticks - ticks0 < n){
    80003c44:	409c                	lw	a5,0(s1)
    80003c46:	412787bb          	subw	a5,a5,s2
    80003c4a:	fcc42703          	lw	a4,-52(s0)
    80003c4e:	fce7ece3          	bltu	a5,a4,80003c26 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003c52:	00237517          	auipc	a0,0x237
    80003c56:	31e50513          	addi	a0,a0,798 # 8023af70 <tickslock>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	306080e7          	jalr	774(ra) # 80000f60 <release>
  return 0;
    80003c62:	4501                	li	a0,0
}
    80003c64:	70e2                	ld	ra,56(sp)
    80003c66:	7442                	ld	s0,48(sp)
    80003c68:	74a2                	ld	s1,40(sp)
    80003c6a:	7902                	ld	s2,32(sp)
    80003c6c:	69e2                	ld	s3,24(sp)
    80003c6e:	6121                	addi	sp,sp,64
    80003c70:	8082                	ret
      release(&tickslock);
    80003c72:	00237517          	auipc	a0,0x237
    80003c76:	2fe50513          	addi	a0,a0,766 # 8023af70 <tickslock>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	2e6080e7          	jalr	742(ra) # 80000f60 <release>
      return -1;
    80003c82:	557d                	li	a0,-1
    80003c84:	b7c5                	j	80003c64 <sys_sleep+0x88>

0000000080003c86 <sys_kill>:

uint64
sys_kill(void)
{
    80003c86:	1101                	addi	sp,sp,-32
    80003c88:	ec06                	sd	ra,24(sp)
    80003c8a:	e822                	sd	s0,16(sp)
    80003c8c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003c8e:	fec40593          	addi	a1,s0,-20
    80003c92:	4501                	li	a0,0
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	b20080e7          	jalr	-1248(ra) # 800037b4 <argint>
  return kill(pid);
    80003c9c:	fec42503          	lw	a0,-20(s0)
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	b8c080e7          	jalr	-1140(ra) # 8000282c <kill>
}
    80003ca8:	60e2                	ld	ra,24(sp)
    80003caa:	6442                	ld	s0,16(sp)
    80003cac:	6105                	addi	sp,sp,32
    80003cae:	8082                	ret

0000000080003cb0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003cba:	00237517          	auipc	a0,0x237
    80003cbe:	2b650513          	addi	a0,a0,694 # 8023af70 <tickslock>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	1ea080e7          	jalr	490(ra) # 80000eac <acquire>
  xticks = ticks;
    80003cca:	00006497          	auipc	s1,0x6
    80003cce:	eae4a483          	lw	s1,-338(s1) # 80009b78 <ticks>
  release(&tickslock);
    80003cd2:	00237517          	auipc	a0,0x237
    80003cd6:	29e50513          	addi	a0,a0,670 # 8023af70 <tickslock>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	286080e7          	jalr	646(ra) # 80000f60 <release>
  return xticks;
}
    80003ce2:	02049513          	slli	a0,s1,0x20
    80003ce6:	9101                	srli	a0,a0,0x20
    80003ce8:	60e2                	ld	ra,24(sp)
    80003cea:	6442                	ld	s0,16(sp)
    80003cec:	64a2                	ld	s1,8(sp)
    80003cee:	6105                	addi	sp,sp,32
    80003cf0:	8082                	ret

0000000080003cf2 <sys_trace>:

uint64 sys_trace(void)
{
    80003cf2:	1101                	addi	sp,sp,-32
    80003cf4:	ec06                	sd	ra,24(sp)
    80003cf6:	e822                	sd	s0,16(sp)
    80003cf8:	1000                	addi	s0,sp,32
  int mask;
  argint(0,&mask);
    80003cfa:	fec40593          	addi	a1,s0,-20
    80003cfe:	4501                	li	a0,0
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	ab4080e7          	jalr	-1356(ra) # 800037b4 <argint>
  uni_mask=mask;
    80003d08:	fec42503          	lw	a0,-20(s0)
    80003d0c:	00006797          	auipc	a5,0x6
    80003d10:	e6a7aa23          	sw	a0,-396(a5) # 80009b80 <uni_mask>
  flag=1;
    80003d14:	4785                	li	a5,1
    80003d16:	00006717          	auipc	a4,0x6
    80003d1a:	e6f72323          	sw	a5,-410(a4) # 80009b7c <flag>
  return mask;
}
    80003d1e:	60e2                	ld	ra,24(sp)
    80003d20:	6442                	ld	s0,16(sp)
    80003d22:	6105                	addi	sp,sp,32
    80003d24:	8082                	ret

0000000080003d26 <restore>:

void restore(){
    80003d26:	1141                	addi	sp,sp,-16
    80003d28:	e406                	sd	ra,8(sp)
    80003d2a:	e022                	sd	s0,0(sp)
    80003d2c:	0800                	addi	s0,sp,16
  struct proc*p=myproc();
    80003d2e:	ffffe097          	auipc	ra,0xffffe
    80003d32:	ff0080e7          	jalr	-16(ra) # 80001d1e <myproc>

  p->trapframe_copy->kernel_trap = p->trapframe->kernel_trap;
    80003d36:	18853783          	ld	a5,392(a0)
    80003d3a:	7138                	ld	a4,96(a0)
    80003d3c:	6b18                	ld	a4,16(a4)
    80003d3e:	eb98                	sd	a4,16(a5)
  p->trapframe_copy->kernel_hartid = p->trapframe->kernel_hartid;
    80003d40:	18853783          	ld	a5,392(a0)
    80003d44:	7138                	ld	a4,96(a0)
    80003d46:	7318                	ld	a4,32(a4)
    80003d48:	f398                	sd	a4,32(a5)
  p->trapframe_copy->kernel_sp = p->trapframe->kernel_sp;
    80003d4a:	18853783          	ld	a5,392(a0)
    80003d4e:	7138                	ld	a4,96(a0)
    80003d50:	6718                	ld	a4,8(a4)
    80003d52:	e798                	sd	a4,8(a5)
  p->trapframe_copy->kernel_satp = p->trapframe->kernel_satp;
    80003d54:	18853783          	ld	a5,392(a0)
    80003d58:	7138                	ld	a4,96(a0)
    80003d5a:	6318                	ld	a4,0(a4)
    80003d5c:	e398                	sd	a4,0(a5)
  *(p->trapframe) = *(p->trapframe_copy);
    80003d5e:	18853683          	ld	a3,392(a0)
    80003d62:	87b6                	mv	a5,a3
    80003d64:	7138                	ld	a4,96(a0)
    80003d66:	12068693          	addi	a3,a3,288
    80003d6a:	0007b803          	ld	a6,0(a5)
    80003d6e:	6788                	ld	a0,8(a5)
    80003d70:	6b8c                	ld	a1,16(a5)
    80003d72:	6f90                	ld	a2,24(a5)
    80003d74:	01073023          	sd	a6,0(a4)
    80003d78:	e708                	sd	a0,8(a4)
    80003d7a:	eb0c                	sd	a1,16(a4)
    80003d7c:	ef10                	sd	a2,24(a4)
    80003d7e:	02078793          	addi	a5,a5,32
    80003d82:	02070713          	addi	a4,a4,32
    80003d86:	fed792e3          	bne	a5,a3,80003d6a <restore+0x44>
}
    80003d8a:	60a2                	ld	ra,8(sp)
    80003d8c:	6402                	ld	s0,0(sp)
    80003d8e:	0141                	addi	sp,sp,16
    80003d90:	8082                	ret

0000000080003d92 <sys_sigreturn>:

uint64 sys_sigreturn(void){
    80003d92:	1141                	addi	sp,sp,-16
    80003d94:	e406                	sd	ra,8(sp)
    80003d96:	e022                	sd	s0,0(sp)
    80003d98:	0800                	addi	s0,sp,16
  restore();
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	f8c080e7          	jalr	-116(ra) # 80003d26 <restore>
  myproc()->is_sigalarm = 0;
    80003da2:	ffffe097          	auipc	ra,0xffffe
    80003da6:	f7c080e7          	jalr	-132(ra) # 80001d1e <myproc>
    80003daa:	16052823          	sw	zero,368(a0)

  usertrapret();
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	424080e7          	jalr	1060(ra) # 800031d2 <usertrapret>
  
  return 0;
}
    80003db6:	4501                	li	a0,0
    80003db8:	60a2                	ld	ra,8(sp)
    80003dba:	6402                	ld	s0,0(sp)
    80003dbc:	0141                	addi	sp,sp,16
    80003dbe:	8082                	ret

0000000080003dc0 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003dc0:	7139                	addi	sp,sp,-64
    80003dc2:	fc06                	sd	ra,56(sp)
    80003dc4:	f822                	sd	s0,48(sp)
    80003dc6:	f426                	sd	s1,40(sp)
    80003dc8:	f04a                	sd	s2,32(sp)
    80003dca:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003dcc:	fd840593          	addi	a1,s0,-40
    80003dd0:	4501                	li	a0,0
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	a02080e7          	jalr	-1534(ra) # 800037d4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003dda:	fd040593          	addi	a1,s0,-48
    80003dde:	4505                	li	a0,1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	9f4080e7          	jalr	-1548(ra) # 800037d4 <argaddr>
  argaddr(2, &addr2);
    80003de8:	fc840593          	addi	a1,s0,-56
    80003dec:	4509                	li	a0,2
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	9e6080e7          	jalr	-1562(ra) # 800037d4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003df6:	fc040613          	addi	a2,s0,-64
    80003dfa:	fc440593          	addi	a1,s0,-60
    80003dfe:	fd843503          	ld	a0,-40(s0)
    80003e02:	fffff097          	auipc	ra,0xfffff
    80003e06:	dfe080e7          	jalr	-514(ra) # 80002c00 <waitx>
    80003e0a:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003e0c:	ffffe097          	auipc	ra,0xffffe
    80003e10:	f12080e7          	jalr	-238(ra) # 80001d1e <myproc>
    80003e14:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003e16:	4691                	li	a3,4
    80003e18:	fc440613          	addi	a2,s0,-60
    80003e1c:	fd043583          	ld	a1,-48(s0)
    80003e20:	6d28                	ld	a0,88(a0)
    80003e22:	ffffe097          	auipc	ra,0xffffe
    80003e26:	b28080e7          	jalr	-1240(ra) # 8000194a <copyout>
    return -1;
    80003e2a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003e2c:	00054f63          	bltz	a0,80003e4a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003e30:	4691                	li	a3,4
    80003e32:	fc040613          	addi	a2,s0,-64
    80003e36:	fc843583          	ld	a1,-56(s0)
    80003e3a:	6ca8                	ld	a0,88(s1)
    80003e3c:	ffffe097          	auipc	ra,0xffffe
    80003e40:	b0e080e7          	jalr	-1266(ra) # 8000194a <copyout>
    80003e44:	00054a63          	bltz	a0,80003e58 <sys_waitx+0x98>
    return -1;
  return ret;
    80003e48:	87ca                	mv	a5,s2
}
    80003e4a:	853e                	mv	a0,a5
    80003e4c:	70e2                	ld	ra,56(sp)
    80003e4e:	7442                	ld	s0,48(sp)
    80003e50:	74a2                	ld	s1,40(sp)
    80003e52:	7902                	ld	s2,32(sp)
    80003e54:	6121                	addi	sp,sp,64
    80003e56:	8082                	ret
    return -1;
    80003e58:	57fd                	li	a5,-1
    80003e5a:	bfc5                	j	80003e4a <sys_waitx+0x8a>

0000000080003e5c <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003e5c:	1101                	addi	sp,sp,-32
    80003e5e:	ec06                	sd	ra,24(sp)
    80003e60:	e822                	sd	s0,16(sp)
    80003e62:	1000                	addi	s0,sp,32
  int new_static_priority;

  argint(0, &new_static_priority);
    80003e64:	fec40593          	addi	a1,s0,-20
    80003e68:	4501                	li	a0,0
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	94a080e7          	jalr	-1718(ra) # 800037b4 <argint>

  if (new_static_priority < 0)
    80003e72:	fec42783          	lw	a5,-20(s0)
    return -1;
    80003e76:	557d                	li	a0,-1
  if (new_static_priority < 0)
    80003e78:	0207c463          	bltz	a5,80003ea0 <sys_set_priority+0x44>

  int proc_pid;
  argint(1, &proc_pid);
    80003e7c:	fe840593          	addi	a1,s0,-24
    80003e80:	4505                	li	a0,1
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	932080e7          	jalr	-1742(ra) # 800037b4 <argint>

  if (proc_pid < 0)
    80003e8a:	fe842583          	lw	a1,-24(s0)
    return -1;
    80003e8e:	557d                	li	a0,-1
  if (proc_pid < 0)
    80003e90:	0005c863          	bltz	a1,80003ea0 <sys_set_priority+0x44>

  return set_priority(new_static_priority, proc_pid);
    80003e94:	fec42503          	lw	a0,-20(s0)
    80003e98:	ffffe097          	auipc	ra,0xffffe
    80003e9c:	fae080e7          	jalr	-82(ra) # 80001e46 <set_priority>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret

0000000080003ea8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003ea8:	7179                	addi	sp,sp,-48
    80003eaa:	f406                	sd	ra,40(sp)
    80003eac:	f022                	sd	s0,32(sp)
    80003eae:	ec26                	sd	s1,24(sp)
    80003eb0:	e84a                	sd	s2,16(sp)
    80003eb2:	e44e                	sd	s3,8(sp)
    80003eb4:	e052                	sd	s4,0(sp)
    80003eb6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003eb8:	00006597          	auipc	a1,0x6
    80003ebc:	8e058593          	addi	a1,a1,-1824 # 80009798 <syscalls+0xd8>
    80003ec0:	00237517          	auipc	a0,0x237
    80003ec4:	19050513          	addi	a0,a0,400 # 8023b050 <bcache>
    80003ec8:	ffffd097          	auipc	ra,0xffffd
    80003ecc:	f54080e7          	jalr	-172(ra) # 80000e1c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003ed0:	0023f797          	auipc	a5,0x23f
    80003ed4:	18078793          	addi	a5,a5,384 # 80243050 <bcache+0x8000>
    80003ed8:	0023f717          	auipc	a4,0x23f
    80003edc:	3e070713          	addi	a4,a4,992 # 802432b8 <bcache+0x8268>
    80003ee0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ee4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ee8:	00237497          	auipc	s1,0x237
    80003eec:	18048493          	addi	s1,s1,384 # 8023b068 <bcache+0x18>
    b->next = bcache.head.next;
    80003ef0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ef2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ef4:	00006a17          	auipc	s4,0x6
    80003ef8:	8aca0a13          	addi	s4,s4,-1876 # 800097a0 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003efc:	2b893783          	ld	a5,696(s2)
    80003f00:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003f02:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003f06:	85d2                	mv	a1,s4
    80003f08:	01048513          	addi	a0,s1,16
    80003f0c:	00001097          	auipc	ra,0x1
    80003f10:	4c4080e7          	jalr	1220(ra) # 800053d0 <initsleeplock>
    bcache.head.next->prev = b;
    80003f14:	2b893783          	ld	a5,696(s2)
    80003f18:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003f1a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003f1e:	45848493          	addi	s1,s1,1112
    80003f22:	fd349de3          	bne	s1,s3,80003efc <binit+0x54>
  }
}
    80003f26:	70a2                	ld	ra,40(sp)
    80003f28:	7402                	ld	s0,32(sp)
    80003f2a:	64e2                	ld	s1,24(sp)
    80003f2c:	6942                	ld	s2,16(sp)
    80003f2e:	69a2                	ld	s3,8(sp)
    80003f30:	6a02                	ld	s4,0(sp)
    80003f32:	6145                	addi	sp,sp,48
    80003f34:	8082                	ret

0000000080003f36 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003f36:	7179                	addi	sp,sp,-48
    80003f38:	f406                	sd	ra,40(sp)
    80003f3a:	f022                	sd	s0,32(sp)
    80003f3c:	ec26                	sd	s1,24(sp)
    80003f3e:	e84a                	sd	s2,16(sp)
    80003f40:	e44e                	sd	s3,8(sp)
    80003f42:	1800                	addi	s0,sp,48
    80003f44:	89aa                	mv	s3,a0
    80003f46:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003f48:	00237517          	auipc	a0,0x237
    80003f4c:	10850513          	addi	a0,a0,264 # 8023b050 <bcache>
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	f5c080e7          	jalr	-164(ra) # 80000eac <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003f58:	0023f497          	auipc	s1,0x23f
    80003f5c:	3b04b483          	ld	s1,944(s1) # 80243308 <bcache+0x82b8>
    80003f60:	0023f797          	auipc	a5,0x23f
    80003f64:	35878793          	addi	a5,a5,856 # 802432b8 <bcache+0x8268>
    80003f68:	02f48f63          	beq	s1,a5,80003fa6 <bread+0x70>
    80003f6c:	873e                	mv	a4,a5
    80003f6e:	a021                	j	80003f76 <bread+0x40>
    80003f70:	68a4                	ld	s1,80(s1)
    80003f72:	02e48a63          	beq	s1,a4,80003fa6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003f76:	449c                	lw	a5,8(s1)
    80003f78:	ff379ce3          	bne	a5,s3,80003f70 <bread+0x3a>
    80003f7c:	44dc                	lw	a5,12(s1)
    80003f7e:	ff2799e3          	bne	a5,s2,80003f70 <bread+0x3a>
      b->refcnt++;
    80003f82:	40bc                	lw	a5,64(s1)
    80003f84:	2785                	addiw	a5,a5,1
    80003f86:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003f88:	00237517          	auipc	a0,0x237
    80003f8c:	0c850513          	addi	a0,a0,200 # 8023b050 <bcache>
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	fd0080e7          	jalr	-48(ra) # 80000f60 <release>
      acquiresleep(&b->lock);
    80003f98:	01048513          	addi	a0,s1,16
    80003f9c:	00001097          	auipc	ra,0x1
    80003fa0:	46e080e7          	jalr	1134(ra) # 8000540a <acquiresleep>
      return b;
    80003fa4:	a8b9                	j	80004002 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003fa6:	0023f497          	auipc	s1,0x23f
    80003faa:	35a4b483          	ld	s1,858(s1) # 80243300 <bcache+0x82b0>
    80003fae:	0023f797          	auipc	a5,0x23f
    80003fb2:	30a78793          	addi	a5,a5,778 # 802432b8 <bcache+0x8268>
    80003fb6:	00f48863          	beq	s1,a5,80003fc6 <bread+0x90>
    80003fba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003fbc:	40bc                	lw	a5,64(s1)
    80003fbe:	cf81                	beqz	a5,80003fd6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003fc0:	64a4                	ld	s1,72(s1)
    80003fc2:	fee49de3          	bne	s1,a4,80003fbc <bread+0x86>
  panic("bget: no buffers");
    80003fc6:	00005517          	auipc	a0,0x5
    80003fca:	7e250513          	addi	a0,a0,2018 # 800097a8 <syscalls+0xe8>
    80003fce:	ffffc097          	auipc	ra,0xffffc
    80003fd2:	576080e7          	jalr	1398(ra) # 80000544 <panic>
      b->dev = dev;
    80003fd6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003fda:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003fde:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003fe2:	4785                	li	a5,1
    80003fe4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003fe6:	00237517          	auipc	a0,0x237
    80003fea:	06a50513          	addi	a0,a0,106 # 8023b050 <bcache>
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	f72080e7          	jalr	-142(ra) # 80000f60 <release>
      acquiresleep(&b->lock);
    80003ff6:	01048513          	addi	a0,s1,16
    80003ffa:	00001097          	auipc	ra,0x1
    80003ffe:	410080e7          	jalr	1040(ra) # 8000540a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80004002:	409c                	lw	a5,0(s1)
    80004004:	cb89                	beqz	a5,80004016 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80004006:	8526                	mv	a0,s1
    80004008:	70a2                	ld	ra,40(sp)
    8000400a:	7402                	ld	s0,32(sp)
    8000400c:	64e2                	ld	s1,24(sp)
    8000400e:	6942                	ld	s2,16(sp)
    80004010:	69a2                	ld	s3,8(sp)
    80004012:	6145                	addi	sp,sp,48
    80004014:	8082                	ret
    virtio_disk_rw(b, 0);
    80004016:	4581                	li	a1,0
    80004018:	8526                	mv	a0,s1
    8000401a:	00003097          	auipc	ra,0x3
    8000401e:	fce080e7          	jalr	-50(ra) # 80006fe8 <virtio_disk_rw>
    b->valid = 1;
    80004022:	4785                	li	a5,1
    80004024:	c09c                	sw	a5,0(s1)
  return b;
    80004026:	b7c5                	j	80004006 <bread+0xd0>

0000000080004028 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	1000                	addi	s0,sp,32
    80004032:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004034:	0541                	addi	a0,a0,16
    80004036:	00001097          	auipc	ra,0x1
    8000403a:	46e080e7          	jalr	1134(ra) # 800054a4 <holdingsleep>
    8000403e:	cd01                	beqz	a0,80004056 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80004040:	4585                	li	a1,1
    80004042:	8526                	mv	a0,s1
    80004044:	00003097          	auipc	ra,0x3
    80004048:	fa4080e7          	jalr	-92(ra) # 80006fe8 <virtio_disk_rw>
}
    8000404c:	60e2                	ld	ra,24(sp)
    8000404e:	6442                	ld	s0,16(sp)
    80004050:	64a2                	ld	s1,8(sp)
    80004052:	6105                	addi	sp,sp,32
    80004054:	8082                	ret
    panic("bwrite");
    80004056:	00005517          	auipc	a0,0x5
    8000405a:	76a50513          	addi	a0,a0,1898 # 800097c0 <syscalls+0x100>
    8000405e:	ffffc097          	auipc	ra,0xffffc
    80004062:	4e6080e7          	jalr	1254(ra) # 80000544 <panic>

0000000080004066 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004066:	1101                	addi	sp,sp,-32
    80004068:	ec06                	sd	ra,24(sp)
    8000406a:	e822                	sd	s0,16(sp)
    8000406c:	e426                	sd	s1,8(sp)
    8000406e:	e04a                	sd	s2,0(sp)
    80004070:	1000                	addi	s0,sp,32
    80004072:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004074:	01050913          	addi	s2,a0,16
    80004078:	854a                	mv	a0,s2
    8000407a:	00001097          	auipc	ra,0x1
    8000407e:	42a080e7          	jalr	1066(ra) # 800054a4 <holdingsleep>
    80004082:	c92d                	beqz	a0,800040f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004084:	854a                	mv	a0,s2
    80004086:	00001097          	auipc	ra,0x1
    8000408a:	3da080e7          	jalr	986(ra) # 80005460 <releasesleep>

  acquire(&bcache.lock);
    8000408e:	00237517          	auipc	a0,0x237
    80004092:	fc250513          	addi	a0,a0,-62 # 8023b050 <bcache>
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	e16080e7          	jalr	-490(ra) # 80000eac <acquire>
  b->refcnt--;
    8000409e:	40bc                	lw	a5,64(s1)
    800040a0:	37fd                	addiw	a5,a5,-1
    800040a2:	0007871b          	sext.w	a4,a5
    800040a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800040a8:	eb05                	bnez	a4,800040d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800040aa:	68bc                	ld	a5,80(s1)
    800040ac:	64b8                	ld	a4,72(s1)
    800040ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800040b0:	64bc                	ld	a5,72(s1)
    800040b2:	68b8                	ld	a4,80(s1)
    800040b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800040b6:	0023f797          	auipc	a5,0x23f
    800040ba:	f9a78793          	addi	a5,a5,-102 # 80243050 <bcache+0x8000>
    800040be:	2b87b703          	ld	a4,696(a5)
    800040c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800040c4:	0023f717          	auipc	a4,0x23f
    800040c8:	1f470713          	addi	a4,a4,500 # 802432b8 <bcache+0x8268>
    800040cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800040ce:	2b87b703          	ld	a4,696(a5)
    800040d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800040d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800040d8:	00237517          	auipc	a0,0x237
    800040dc:	f7850513          	addi	a0,a0,-136 # 8023b050 <bcache>
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	e80080e7          	jalr	-384(ra) # 80000f60 <release>
}
    800040e8:	60e2                	ld	ra,24(sp)
    800040ea:	6442                	ld	s0,16(sp)
    800040ec:	64a2                	ld	s1,8(sp)
    800040ee:	6902                	ld	s2,0(sp)
    800040f0:	6105                	addi	sp,sp,32
    800040f2:	8082                	ret
    panic("brelse");
    800040f4:	00005517          	auipc	a0,0x5
    800040f8:	6d450513          	addi	a0,a0,1748 # 800097c8 <syscalls+0x108>
    800040fc:	ffffc097          	auipc	ra,0xffffc
    80004100:	448080e7          	jalr	1096(ra) # 80000544 <panic>

0000000080004104 <bpin>:

void
bpin(struct buf *b) {
    80004104:	1101                	addi	sp,sp,-32
    80004106:	ec06                	sd	ra,24(sp)
    80004108:	e822                	sd	s0,16(sp)
    8000410a:	e426                	sd	s1,8(sp)
    8000410c:	1000                	addi	s0,sp,32
    8000410e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004110:	00237517          	auipc	a0,0x237
    80004114:	f4050513          	addi	a0,a0,-192 # 8023b050 <bcache>
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	d94080e7          	jalr	-620(ra) # 80000eac <acquire>
  b->refcnt++;
    80004120:	40bc                	lw	a5,64(s1)
    80004122:	2785                	addiw	a5,a5,1
    80004124:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004126:	00237517          	auipc	a0,0x237
    8000412a:	f2a50513          	addi	a0,a0,-214 # 8023b050 <bcache>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	e32080e7          	jalr	-462(ra) # 80000f60 <release>
}
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	64a2                	ld	s1,8(sp)
    8000413c:	6105                	addi	sp,sp,32
    8000413e:	8082                	ret

0000000080004140 <bunpin>:

void
bunpin(struct buf *b) {
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	1000                	addi	s0,sp,32
    8000414a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000414c:	00237517          	auipc	a0,0x237
    80004150:	f0450513          	addi	a0,a0,-252 # 8023b050 <bcache>
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	d58080e7          	jalr	-680(ra) # 80000eac <acquire>
  b->refcnt--;
    8000415c:	40bc                	lw	a5,64(s1)
    8000415e:	37fd                	addiw	a5,a5,-1
    80004160:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004162:	00237517          	auipc	a0,0x237
    80004166:	eee50513          	addi	a0,a0,-274 # 8023b050 <bcache>
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	df6080e7          	jalr	-522(ra) # 80000f60 <release>
}
    80004172:	60e2                	ld	ra,24(sp)
    80004174:	6442                	ld	s0,16(sp)
    80004176:	64a2                	ld	s1,8(sp)
    80004178:	6105                	addi	sp,sp,32
    8000417a:	8082                	ret

000000008000417c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000417c:	1101                	addi	sp,sp,-32
    8000417e:	ec06                	sd	ra,24(sp)
    80004180:	e822                	sd	s0,16(sp)
    80004182:	e426                	sd	s1,8(sp)
    80004184:	e04a                	sd	s2,0(sp)
    80004186:	1000                	addi	s0,sp,32
    80004188:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000418a:	00d5d59b          	srliw	a1,a1,0xd
    8000418e:	0023f797          	auipc	a5,0x23f
    80004192:	59e7a783          	lw	a5,1438(a5) # 8024372c <sb+0x1c>
    80004196:	9dbd                	addw	a1,a1,a5
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	d9e080e7          	jalr	-610(ra) # 80003f36 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800041a0:	0074f713          	andi	a4,s1,7
    800041a4:	4785                	li	a5,1
    800041a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800041aa:	14ce                	slli	s1,s1,0x33
    800041ac:	90d9                	srli	s1,s1,0x36
    800041ae:	00950733          	add	a4,a0,s1
    800041b2:	05874703          	lbu	a4,88(a4)
    800041b6:	00e7f6b3          	and	a3,a5,a4
    800041ba:	c69d                	beqz	a3,800041e8 <bfree+0x6c>
    800041bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800041be:	94aa                	add	s1,s1,a0
    800041c0:	fff7c793          	not	a5,a5
    800041c4:	8ff9                	and	a5,a5,a4
    800041c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800041ca:	00001097          	auipc	ra,0x1
    800041ce:	120080e7          	jalr	288(ra) # 800052ea <log_write>
  brelse(bp);
    800041d2:	854a                	mv	a0,s2
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	e92080e7          	jalr	-366(ra) # 80004066 <brelse>
}
    800041dc:	60e2                	ld	ra,24(sp)
    800041de:	6442                	ld	s0,16(sp)
    800041e0:	64a2                	ld	s1,8(sp)
    800041e2:	6902                	ld	s2,0(sp)
    800041e4:	6105                	addi	sp,sp,32
    800041e6:	8082                	ret
    panic("freeing free block");
    800041e8:	00005517          	auipc	a0,0x5
    800041ec:	5e850513          	addi	a0,a0,1512 # 800097d0 <syscalls+0x110>
    800041f0:	ffffc097          	auipc	ra,0xffffc
    800041f4:	354080e7          	jalr	852(ra) # 80000544 <panic>

00000000800041f8 <balloc>:
{
    800041f8:	711d                	addi	sp,sp,-96
    800041fa:	ec86                	sd	ra,88(sp)
    800041fc:	e8a2                	sd	s0,80(sp)
    800041fe:	e4a6                	sd	s1,72(sp)
    80004200:	e0ca                	sd	s2,64(sp)
    80004202:	fc4e                	sd	s3,56(sp)
    80004204:	f852                	sd	s4,48(sp)
    80004206:	f456                	sd	s5,40(sp)
    80004208:	f05a                	sd	s6,32(sp)
    8000420a:	ec5e                	sd	s7,24(sp)
    8000420c:	e862                	sd	s8,16(sp)
    8000420e:	e466                	sd	s9,8(sp)
    80004210:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80004212:	0023f797          	auipc	a5,0x23f
    80004216:	5027a783          	lw	a5,1282(a5) # 80243714 <sb+0x4>
    8000421a:	10078163          	beqz	a5,8000431c <balloc+0x124>
    8000421e:	8baa                	mv	s7,a0
    80004220:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80004222:	0023fb17          	auipc	s6,0x23f
    80004226:	4eeb0b13          	addi	s6,s6,1262 # 80243710 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000422a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000422c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000422e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80004230:	6c89                	lui	s9,0x2
    80004232:	a061                	j	800042ba <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004234:	974a                	add	a4,a4,s2
    80004236:	8fd5                	or	a5,a5,a3
    80004238:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000423c:	854a                	mv	a0,s2
    8000423e:	00001097          	auipc	ra,0x1
    80004242:	0ac080e7          	jalr	172(ra) # 800052ea <log_write>
        brelse(bp);
    80004246:	854a                	mv	a0,s2
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	e1e080e7          	jalr	-482(ra) # 80004066 <brelse>
  bp = bread(dev, bno);
    80004250:	85a6                	mv	a1,s1
    80004252:	855e                	mv	a0,s7
    80004254:	00000097          	auipc	ra,0x0
    80004258:	ce2080e7          	jalr	-798(ra) # 80003f36 <bread>
    8000425c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000425e:	40000613          	li	a2,1024
    80004262:	4581                	li	a1,0
    80004264:	05850513          	addi	a0,a0,88
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	d40080e7          	jalr	-704(ra) # 80000fa8 <memset>
  log_write(bp);
    80004270:	854a                	mv	a0,s2
    80004272:	00001097          	auipc	ra,0x1
    80004276:	078080e7          	jalr	120(ra) # 800052ea <log_write>
  brelse(bp);
    8000427a:	854a                	mv	a0,s2
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	dea080e7          	jalr	-534(ra) # 80004066 <brelse>
}
    80004284:	8526                	mv	a0,s1
    80004286:	60e6                	ld	ra,88(sp)
    80004288:	6446                	ld	s0,80(sp)
    8000428a:	64a6                	ld	s1,72(sp)
    8000428c:	6906                	ld	s2,64(sp)
    8000428e:	79e2                	ld	s3,56(sp)
    80004290:	7a42                	ld	s4,48(sp)
    80004292:	7aa2                	ld	s5,40(sp)
    80004294:	7b02                	ld	s6,32(sp)
    80004296:	6be2                	ld	s7,24(sp)
    80004298:	6c42                	ld	s8,16(sp)
    8000429a:	6ca2                	ld	s9,8(sp)
    8000429c:	6125                	addi	sp,sp,96
    8000429e:	8082                	ret
    brelse(bp);
    800042a0:	854a                	mv	a0,s2
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	dc4080e7          	jalr	-572(ra) # 80004066 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800042aa:	015c87bb          	addw	a5,s9,s5
    800042ae:	00078a9b          	sext.w	s5,a5
    800042b2:	004b2703          	lw	a4,4(s6)
    800042b6:	06eaf363          	bgeu	s5,a4,8000431c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800042ba:	41fad79b          	sraiw	a5,s5,0x1f
    800042be:	0137d79b          	srliw	a5,a5,0x13
    800042c2:	015787bb          	addw	a5,a5,s5
    800042c6:	40d7d79b          	sraiw	a5,a5,0xd
    800042ca:	01cb2583          	lw	a1,28(s6)
    800042ce:	9dbd                	addw	a1,a1,a5
    800042d0:	855e                	mv	a0,s7
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	c64080e7          	jalr	-924(ra) # 80003f36 <bread>
    800042da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800042dc:	004b2503          	lw	a0,4(s6)
    800042e0:	000a849b          	sext.w	s1,s5
    800042e4:	8662                	mv	a2,s8
    800042e6:	faa4fde3          	bgeu	s1,a0,800042a0 <balloc+0xa8>
      m = 1 << (bi % 8);
    800042ea:	41f6579b          	sraiw	a5,a2,0x1f
    800042ee:	01d7d69b          	srliw	a3,a5,0x1d
    800042f2:	00c6873b          	addw	a4,a3,a2
    800042f6:	00777793          	andi	a5,a4,7
    800042fa:	9f95                	subw	a5,a5,a3
    800042fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004300:	4037571b          	sraiw	a4,a4,0x3
    80004304:	00e906b3          	add	a3,s2,a4
    80004308:	0586c683          	lbu	a3,88(a3)
    8000430c:	00d7f5b3          	and	a1,a5,a3
    80004310:	d195                	beqz	a1,80004234 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004312:	2605                	addiw	a2,a2,1
    80004314:	2485                	addiw	s1,s1,1
    80004316:	fd4618e3          	bne	a2,s4,800042e6 <balloc+0xee>
    8000431a:	b759                	j	800042a0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000431c:	00005517          	auipc	a0,0x5
    80004320:	4cc50513          	addi	a0,a0,1228 # 800097e8 <syscalls+0x128>
    80004324:	ffffc097          	auipc	ra,0xffffc
    80004328:	26a080e7          	jalr	618(ra) # 8000058e <printf>
  return 0;
    8000432c:	4481                	li	s1,0
    8000432e:	bf99                	j	80004284 <balloc+0x8c>

0000000080004330 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80004330:	7179                	addi	sp,sp,-48
    80004332:	f406                	sd	ra,40(sp)
    80004334:	f022                	sd	s0,32(sp)
    80004336:	ec26                	sd	s1,24(sp)
    80004338:	e84a                	sd	s2,16(sp)
    8000433a:	e44e                	sd	s3,8(sp)
    8000433c:	e052                	sd	s4,0(sp)
    8000433e:	1800                	addi	s0,sp,48
    80004340:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80004342:	47ad                	li	a5,11
    80004344:	02b7e763          	bltu	a5,a1,80004372 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80004348:	02059493          	slli	s1,a1,0x20
    8000434c:	9081                	srli	s1,s1,0x20
    8000434e:	048a                	slli	s1,s1,0x2
    80004350:	94aa                	add	s1,s1,a0
    80004352:	0504a903          	lw	s2,80(s1)
    80004356:	06091e63          	bnez	s2,800043d2 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000435a:	4108                	lw	a0,0(a0)
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	e9c080e7          	jalr	-356(ra) # 800041f8 <balloc>
    80004364:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80004368:	06090563          	beqz	s2,800043d2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000436c:	0524a823          	sw	s2,80(s1)
    80004370:	a08d                	j	800043d2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004372:	ff45849b          	addiw	s1,a1,-12
    80004376:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000437a:	0ff00793          	li	a5,255
    8000437e:	08e7e563          	bltu	a5,a4,80004408 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80004382:	08052903          	lw	s2,128(a0)
    80004386:	00091d63          	bnez	s2,800043a0 <bmap+0x70>
      addr = balloc(ip->dev);
    8000438a:	4108                	lw	a0,0(a0)
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	e6c080e7          	jalr	-404(ra) # 800041f8 <balloc>
    80004394:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80004398:	02090d63          	beqz	s2,800043d2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000439c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800043a0:	85ca                	mv	a1,s2
    800043a2:	0009a503          	lw	a0,0(s3)
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	b90080e7          	jalr	-1136(ra) # 80003f36 <bread>
    800043ae:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800043b0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800043b4:	02049593          	slli	a1,s1,0x20
    800043b8:	9181                	srli	a1,a1,0x20
    800043ba:	058a                	slli	a1,a1,0x2
    800043bc:	00b784b3          	add	s1,a5,a1
    800043c0:	0004a903          	lw	s2,0(s1)
    800043c4:	02090063          	beqz	s2,800043e4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800043c8:	8552                	mv	a0,s4
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	c9c080e7          	jalr	-868(ra) # 80004066 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800043d2:	854a                	mv	a0,s2
    800043d4:	70a2                	ld	ra,40(sp)
    800043d6:	7402                	ld	s0,32(sp)
    800043d8:	64e2                	ld	s1,24(sp)
    800043da:	6942                	ld	s2,16(sp)
    800043dc:	69a2                	ld	s3,8(sp)
    800043de:	6a02                	ld	s4,0(sp)
    800043e0:	6145                	addi	sp,sp,48
    800043e2:	8082                	ret
      addr = balloc(ip->dev);
    800043e4:	0009a503          	lw	a0,0(s3)
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	e10080e7          	jalr	-496(ra) # 800041f8 <balloc>
    800043f0:	0005091b          	sext.w	s2,a0
      if(addr){
    800043f4:	fc090ae3          	beqz	s2,800043c8 <bmap+0x98>
        a[bn] = addr;
    800043f8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800043fc:	8552                	mv	a0,s4
    800043fe:	00001097          	auipc	ra,0x1
    80004402:	eec080e7          	jalr	-276(ra) # 800052ea <log_write>
    80004406:	b7c9                	j	800043c8 <bmap+0x98>
  panic("bmap: out of range");
    80004408:	00005517          	auipc	a0,0x5
    8000440c:	3f850513          	addi	a0,a0,1016 # 80009800 <syscalls+0x140>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	134080e7          	jalr	308(ra) # 80000544 <panic>

0000000080004418 <iget>:
{
    80004418:	7179                	addi	sp,sp,-48
    8000441a:	f406                	sd	ra,40(sp)
    8000441c:	f022                	sd	s0,32(sp)
    8000441e:	ec26                	sd	s1,24(sp)
    80004420:	e84a                	sd	s2,16(sp)
    80004422:	e44e                	sd	s3,8(sp)
    80004424:	e052                	sd	s4,0(sp)
    80004426:	1800                	addi	s0,sp,48
    80004428:	89aa                	mv	s3,a0
    8000442a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000442c:	0023f517          	auipc	a0,0x23f
    80004430:	30450513          	addi	a0,a0,772 # 80243730 <itable>
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	a78080e7          	jalr	-1416(ra) # 80000eac <acquire>
  empty = 0;
    8000443c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000443e:	0023f497          	auipc	s1,0x23f
    80004442:	30a48493          	addi	s1,s1,778 # 80243748 <itable+0x18>
    80004446:	00241697          	auipc	a3,0x241
    8000444a:	d9268693          	addi	a3,a3,-622 # 802451d8 <log>
    8000444e:	a039                	j	8000445c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004450:	02090b63          	beqz	s2,80004486 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004454:	08848493          	addi	s1,s1,136
    80004458:	02d48a63          	beq	s1,a3,8000448c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000445c:	449c                	lw	a5,8(s1)
    8000445e:	fef059e3          	blez	a5,80004450 <iget+0x38>
    80004462:	4098                	lw	a4,0(s1)
    80004464:	ff3716e3          	bne	a4,s3,80004450 <iget+0x38>
    80004468:	40d8                	lw	a4,4(s1)
    8000446a:	ff4713e3          	bne	a4,s4,80004450 <iget+0x38>
      ip->ref++;
    8000446e:	2785                	addiw	a5,a5,1
    80004470:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004472:	0023f517          	auipc	a0,0x23f
    80004476:	2be50513          	addi	a0,a0,702 # 80243730 <itable>
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	ae6080e7          	jalr	-1306(ra) # 80000f60 <release>
      return ip;
    80004482:	8926                	mv	s2,s1
    80004484:	a03d                	j	800044b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004486:	f7f9                	bnez	a5,80004454 <iget+0x3c>
    80004488:	8926                	mv	s2,s1
    8000448a:	b7e9                	j	80004454 <iget+0x3c>
  if(empty == 0)
    8000448c:	02090c63          	beqz	s2,800044c4 <iget+0xac>
  ip->dev = dev;
    80004490:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004494:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004498:	4785                	li	a5,1
    8000449a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000449e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800044a2:	0023f517          	auipc	a0,0x23f
    800044a6:	28e50513          	addi	a0,a0,654 # 80243730 <itable>
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	ab6080e7          	jalr	-1354(ra) # 80000f60 <release>
}
    800044b2:	854a                	mv	a0,s2
    800044b4:	70a2                	ld	ra,40(sp)
    800044b6:	7402                	ld	s0,32(sp)
    800044b8:	64e2                	ld	s1,24(sp)
    800044ba:	6942                	ld	s2,16(sp)
    800044bc:	69a2                	ld	s3,8(sp)
    800044be:	6a02                	ld	s4,0(sp)
    800044c0:	6145                	addi	sp,sp,48
    800044c2:	8082                	ret
    panic("iget: no inodes");
    800044c4:	00005517          	auipc	a0,0x5
    800044c8:	35450513          	addi	a0,a0,852 # 80009818 <syscalls+0x158>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	078080e7          	jalr	120(ra) # 80000544 <panic>

00000000800044d4 <fsinit>:
fsinit(int dev) {
    800044d4:	7179                	addi	sp,sp,-48
    800044d6:	f406                	sd	ra,40(sp)
    800044d8:	f022                	sd	s0,32(sp)
    800044da:	ec26                	sd	s1,24(sp)
    800044dc:	e84a                	sd	s2,16(sp)
    800044de:	e44e                	sd	s3,8(sp)
    800044e0:	1800                	addi	s0,sp,48
    800044e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800044e4:	4585                	li	a1,1
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	a50080e7          	jalr	-1456(ra) # 80003f36 <bread>
    800044ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800044f0:	0023f997          	auipc	s3,0x23f
    800044f4:	22098993          	addi	s3,s3,544 # 80243710 <sb>
    800044f8:	02000613          	li	a2,32
    800044fc:	05850593          	addi	a1,a0,88
    80004500:	854e                	mv	a0,s3
    80004502:	ffffd097          	auipc	ra,0xffffd
    80004506:	b06080e7          	jalr	-1274(ra) # 80001008 <memmove>
  brelse(bp);
    8000450a:	8526                	mv	a0,s1
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	b5a080e7          	jalr	-1190(ra) # 80004066 <brelse>
  if(sb.magic != FSMAGIC)
    80004514:	0009a703          	lw	a4,0(s3)
    80004518:	102037b7          	lui	a5,0x10203
    8000451c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004520:	02f71263          	bne	a4,a5,80004544 <fsinit+0x70>
  initlog(dev, &sb);
    80004524:	0023f597          	auipc	a1,0x23f
    80004528:	1ec58593          	addi	a1,a1,492 # 80243710 <sb>
    8000452c:	854a                	mv	a0,s2
    8000452e:	00001097          	auipc	ra,0x1
    80004532:	b40080e7          	jalr	-1216(ra) # 8000506e <initlog>
}
    80004536:	70a2                	ld	ra,40(sp)
    80004538:	7402                	ld	s0,32(sp)
    8000453a:	64e2                	ld	s1,24(sp)
    8000453c:	6942                	ld	s2,16(sp)
    8000453e:	69a2                	ld	s3,8(sp)
    80004540:	6145                	addi	sp,sp,48
    80004542:	8082                	ret
    panic("invalid file system");
    80004544:	00005517          	auipc	a0,0x5
    80004548:	2e450513          	addi	a0,a0,740 # 80009828 <syscalls+0x168>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	ff8080e7          	jalr	-8(ra) # 80000544 <panic>

0000000080004554 <iinit>:
{
    80004554:	7179                	addi	sp,sp,-48
    80004556:	f406                	sd	ra,40(sp)
    80004558:	f022                	sd	s0,32(sp)
    8000455a:	ec26                	sd	s1,24(sp)
    8000455c:	e84a                	sd	s2,16(sp)
    8000455e:	e44e                	sd	s3,8(sp)
    80004560:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004562:	00005597          	auipc	a1,0x5
    80004566:	2de58593          	addi	a1,a1,734 # 80009840 <syscalls+0x180>
    8000456a:	0023f517          	auipc	a0,0x23f
    8000456e:	1c650513          	addi	a0,a0,454 # 80243730 <itable>
    80004572:	ffffd097          	auipc	ra,0xffffd
    80004576:	8aa080e7          	jalr	-1878(ra) # 80000e1c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000457a:	0023f497          	auipc	s1,0x23f
    8000457e:	1de48493          	addi	s1,s1,478 # 80243758 <itable+0x28>
    80004582:	00241997          	auipc	s3,0x241
    80004586:	c6698993          	addi	s3,s3,-922 # 802451e8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000458a:	00005917          	auipc	s2,0x5
    8000458e:	2be90913          	addi	s2,s2,702 # 80009848 <syscalls+0x188>
    80004592:	85ca                	mv	a1,s2
    80004594:	8526                	mv	a0,s1
    80004596:	00001097          	auipc	ra,0x1
    8000459a:	e3a080e7          	jalr	-454(ra) # 800053d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000459e:	08848493          	addi	s1,s1,136
    800045a2:	ff3498e3          	bne	s1,s3,80004592 <iinit+0x3e>
}
    800045a6:	70a2                	ld	ra,40(sp)
    800045a8:	7402                	ld	s0,32(sp)
    800045aa:	64e2                	ld	s1,24(sp)
    800045ac:	6942                	ld	s2,16(sp)
    800045ae:	69a2                	ld	s3,8(sp)
    800045b0:	6145                	addi	sp,sp,48
    800045b2:	8082                	ret

00000000800045b4 <ialloc>:
{
    800045b4:	715d                	addi	sp,sp,-80
    800045b6:	e486                	sd	ra,72(sp)
    800045b8:	e0a2                	sd	s0,64(sp)
    800045ba:	fc26                	sd	s1,56(sp)
    800045bc:	f84a                	sd	s2,48(sp)
    800045be:	f44e                	sd	s3,40(sp)
    800045c0:	f052                	sd	s4,32(sp)
    800045c2:	ec56                	sd	s5,24(sp)
    800045c4:	e85a                	sd	s6,16(sp)
    800045c6:	e45e                	sd	s7,8(sp)
    800045c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800045ca:	0023f717          	auipc	a4,0x23f
    800045ce:	15272703          	lw	a4,338(a4) # 8024371c <sb+0xc>
    800045d2:	4785                	li	a5,1
    800045d4:	04e7fa63          	bgeu	a5,a4,80004628 <ialloc+0x74>
    800045d8:	8aaa                	mv	s5,a0
    800045da:	8bae                	mv	s7,a1
    800045dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800045de:	0023fa17          	auipc	s4,0x23f
    800045e2:	132a0a13          	addi	s4,s4,306 # 80243710 <sb>
    800045e6:	00048b1b          	sext.w	s6,s1
    800045ea:	0044d593          	srli	a1,s1,0x4
    800045ee:	018a2783          	lw	a5,24(s4)
    800045f2:	9dbd                	addw	a1,a1,a5
    800045f4:	8556                	mv	a0,s5
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	940080e7          	jalr	-1728(ra) # 80003f36 <bread>
    800045fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004600:	05850993          	addi	s3,a0,88
    80004604:	00f4f793          	andi	a5,s1,15
    80004608:	079a                	slli	a5,a5,0x6
    8000460a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000460c:	00099783          	lh	a5,0(s3)
    80004610:	c3a1                	beqz	a5,80004650 <ialloc+0x9c>
    brelse(bp);
    80004612:	00000097          	auipc	ra,0x0
    80004616:	a54080e7          	jalr	-1452(ra) # 80004066 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000461a:	0485                	addi	s1,s1,1
    8000461c:	00ca2703          	lw	a4,12(s4)
    80004620:	0004879b          	sext.w	a5,s1
    80004624:	fce7e1e3          	bltu	a5,a4,800045e6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004628:	00005517          	auipc	a0,0x5
    8000462c:	22850513          	addi	a0,a0,552 # 80009850 <syscalls+0x190>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	f5e080e7          	jalr	-162(ra) # 8000058e <printf>
  return 0;
    80004638:	4501                	li	a0,0
}
    8000463a:	60a6                	ld	ra,72(sp)
    8000463c:	6406                	ld	s0,64(sp)
    8000463e:	74e2                	ld	s1,56(sp)
    80004640:	7942                	ld	s2,48(sp)
    80004642:	79a2                	ld	s3,40(sp)
    80004644:	7a02                	ld	s4,32(sp)
    80004646:	6ae2                	ld	s5,24(sp)
    80004648:	6b42                	ld	s6,16(sp)
    8000464a:	6ba2                	ld	s7,8(sp)
    8000464c:	6161                	addi	sp,sp,80
    8000464e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004650:	04000613          	li	a2,64
    80004654:	4581                	li	a1,0
    80004656:	854e                	mv	a0,s3
    80004658:	ffffd097          	auipc	ra,0xffffd
    8000465c:	950080e7          	jalr	-1712(ra) # 80000fa8 <memset>
      dip->type = type;
    80004660:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004664:	854a                	mv	a0,s2
    80004666:	00001097          	auipc	ra,0x1
    8000466a:	c84080e7          	jalr	-892(ra) # 800052ea <log_write>
      brelse(bp);
    8000466e:	854a                	mv	a0,s2
    80004670:	00000097          	auipc	ra,0x0
    80004674:	9f6080e7          	jalr	-1546(ra) # 80004066 <brelse>
      return iget(dev, inum);
    80004678:	85da                	mv	a1,s6
    8000467a:	8556                	mv	a0,s5
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	d9c080e7          	jalr	-612(ra) # 80004418 <iget>
    80004684:	bf5d                	j	8000463a <ialloc+0x86>

0000000080004686 <iupdate>:
{
    80004686:	1101                	addi	sp,sp,-32
    80004688:	ec06                	sd	ra,24(sp)
    8000468a:	e822                	sd	s0,16(sp)
    8000468c:	e426                	sd	s1,8(sp)
    8000468e:	e04a                	sd	s2,0(sp)
    80004690:	1000                	addi	s0,sp,32
    80004692:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004694:	415c                	lw	a5,4(a0)
    80004696:	0047d79b          	srliw	a5,a5,0x4
    8000469a:	0023f597          	auipc	a1,0x23f
    8000469e:	08e5a583          	lw	a1,142(a1) # 80243728 <sb+0x18>
    800046a2:	9dbd                	addw	a1,a1,a5
    800046a4:	4108                	lw	a0,0(a0)
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	890080e7          	jalr	-1904(ra) # 80003f36 <bread>
    800046ae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800046b0:	05850793          	addi	a5,a0,88
    800046b4:	40c8                	lw	a0,4(s1)
    800046b6:	893d                	andi	a0,a0,15
    800046b8:	051a                	slli	a0,a0,0x6
    800046ba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800046bc:	04449703          	lh	a4,68(s1)
    800046c0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800046c4:	04649703          	lh	a4,70(s1)
    800046c8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800046cc:	04849703          	lh	a4,72(s1)
    800046d0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800046d4:	04a49703          	lh	a4,74(s1)
    800046d8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800046dc:	44f8                	lw	a4,76(s1)
    800046de:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800046e0:	03400613          	li	a2,52
    800046e4:	05048593          	addi	a1,s1,80
    800046e8:	0531                	addi	a0,a0,12
    800046ea:	ffffd097          	auipc	ra,0xffffd
    800046ee:	91e080e7          	jalr	-1762(ra) # 80001008 <memmove>
  log_write(bp);
    800046f2:	854a                	mv	a0,s2
    800046f4:	00001097          	auipc	ra,0x1
    800046f8:	bf6080e7          	jalr	-1034(ra) # 800052ea <log_write>
  brelse(bp);
    800046fc:	854a                	mv	a0,s2
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	968080e7          	jalr	-1688(ra) # 80004066 <brelse>
}
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6902                	ld	s2,0(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret

0000000080004712 <idup>:
{
    80004712:	1101                	addi	sp,sp,-32
    80004714:	ec06                	sd	ra,24(sp)
    80004716:	e822                	sd	s0,16(sp)
    80004718:	e426                	sd	s1,8(sp)
    8000471a:	1000                	addi	s0,sp,32
    8000471c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000471e:	0023f517          	auipc	a0,0x23f
    80004722:	01250513          	addi	a0,a0,18 # 80243730 <itable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	786080e7          	jalr	1926(ra) # 80000eac <acquire>
  ip->ref++;
    8000472e:	449c                	lw	a5,8(s1)
    80004730:	2785                	addiw	a5,a5,1
    80004732:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004734:	0023f517          	auipc	a0,0x23f
    80004738:	ffc50513          	addi	a0,a0,-4 # 80243730 <itable>
    8000473c:	ffffd097          	auipc	ra,0xffffd
    80004740:	824080e7          	jalr	-2012(ra) # 80000f60 <release>
}
    80004744:	8526                	mv	a0,s1
    80004746:	60e2                	ld	ra,24(sp)
    80004748:	6442                	ld	s0,16(sp)
    8000474a:	64a2                	ld	s1,8(sp)
    8000474c:	6105                	addi	sp,sp,32
    8000474e:	8082                	ret

0000000080004750 <ilock>:
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	e04a                	sd	s2,0(sp)
    8000475a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000475c:	c115                	beqz	a0,80004780 <ilock+0x30>
    8000475e:	84aa                	mv	s1,a0
    80004760:	451c                	lw	a5,8(a0)
    80004762:	00f05f63          	blez	a5,80004780 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004766:	0541                	addi	a0,a0,16
    80004768:	00001097          	auipc	ra,0x1
    8000476c:	ca2080e7          	jalr	-862(ra) # 8000540a <acquiresleep>
  if(ip->valid == 0){
    80004770:	40bc                	lw	a5,64(s1)
    80004772:	cf99                	beqz	a5,80004790 <ilock+0x40>
}
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6902                	ld	s2,0(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret
    panic("ilock");
    80004780:	00005517          	auipc	a0,0x5
    80004784:	0e850513          	addi	a0,a0,232 # 80009868 <syscalls+0x1a8>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	dbc080e7          	jalr	-580(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004790:	40dc                	lw	a5,4(s1)
    80004792:	0047d79b          	srliw	a5,a5,0x4
    80004796:	0023f597          	auipc	a1,0x23f
    8000479a:	f925a583          	lw	a1,-110(a1) # 80243728 <sb+0x18>
    8000479e:	9dbd                	addw	a1,a1,a5
    800047a0:	4088                	lw	a0,0(s1)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	794080e7          	jalr	1940(ra) # 80003f36 <bread>
    800047aa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800047ac:	05850593          	addi	a1,a0,88
    800047b0:	40dc                	lw	a5,4(s1)
    800047b2:	8bbd                	andi	a5,a5,15
    800047b4:	079a                	slli	a5,a5,0x6
    800047b6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800047b8:	00059783          	lh	a5,0(a1)
    800047bc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800047c0:	00259783          	lh	a5,2(a1)
    800047c4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800047c8:	00459783          	lh	a5,4(a1)
    800047cc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800047d0:	00659783          	lh	a5,6(a1)
    800047d4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800047d8:	459c                	lw	a5,8(a1)
    800047da:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800047dc:	03400613          	li	a2,52
    800047e0:	05b1                	addi	a1,a1,12
    800047e2:	05048513          	addi	a0,s1,80
    800047e6:	ffffd097          	auipc	ra,0xffffd
    800047ea:	822080e7          	jalr	-2014(ra) # 80001008 <memmove>
    brelse(bp);
    800047ee:	854a                	mv	a0,s2
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	876080e7          	jalr	-1930(ra) # 80004066 <brelse>
    ip->valid = 1;
    800047f8:	4785                	li	a5,1
    800047fa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800047fc:	04449783          	lh	a5,68(s1)
    80004800:	fbb5                	bnez	a5,80004774 <ilock+0x24>
      panic("ilock: no type");
    80004802:	00005517          	auipc	a0,0x5
    80004806:	06e50513          	addi	a0,a0,110 # 80009870 <syscalls+0x1b0>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	d3a080e7          	jalr	-710(ra) # 80000544 <panic>

0000000080004812 <iunlock>:
{
    80004812:	1101                	addi	sp,sp,-32
    80004814:	ec06                	sd	ra,24(sp)
    80004816:	e822                	sd	s0,16(sp)
    80004818:	e426                	sd	s1,8(sp)
    8000481a:	e04a                	sd	s2,0(sp)
    8000481c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000481e:	c905                	beqz	a0,8000484e <iunlock+0x3c>
    80004820:	84aa                	mv	s1,a0
    80004822:	01050913          	addi	s2,a0,16
    80004826:	854a                	mv	a0,s2
    80004828:	00001097          	auipc	ra,0x1
    8000482c:	c7c080e7          	jalr	-900(ra) # 800054a4 <holdingsleep>
    80004830:	cd19                	beqz	a0,8000484e <iunlock+0x3c>
    80004832:	449c                	lw	a5,8(s1)
    80004834:	00f05d63          	blez	a5,8000484e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004838:	854a                	mv	a0,s2
    8000483a:	00001097          	auipc	ra,0x1
    8000483e:	c26080e7          	jalr	-986(ra) # 80005460 <releasesleep>
}
    80004842:	60e2                	ld	ra,24(sp)
    80004844:	6442                	ld	s0,16(sp)
    80004846:	64a2                	ld	s1,8(sp)
    80004848:	6902                	ld	s2,0(sp)
    8000484a:	6105                	addi	sp,sp,32
    8000484c:	8082                	ret
    panic("iunlock");
    8000484e:	00005517          	auipc	a0,0x5
    80004852:	03250513          	addi	a0,a0,50 # 80009880 <syscalls+0x1c0>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	cee080e7          	jalr	-786(ra) # 80000544 <panic>

000000008000485e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000485e:	7179                	addi	sp,sp,-48
    80004860:	f406                	sd	ra,40(sp)
    80004862:	f022                	sd	s0,32(sp)
    80004864:	ec26                	sd	s1,24(sp)
    80004866:	e84a                	sd	s2,16(sp)
    80004868:	e44e                	sd	s3,8(sp)
    8000486a:	e052                	sd	s4,0(sp)
    8000486c:	1800                	addi	s0,sp,48
    8000486e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004870:	05050493          	addi	s1,a0,80
    80004874:	08050913          	addi	s2,a0,128
    80004878:	a021                	j	80004880 <itrunc+0x22>
    8000487a:	0491                	addi	s1,s1,4
    8000487c:	01248d63          	beq	s1,s2,80004896 <itrunc+0x38>
    if(ip->addrs[i]){
    80004880:	408c                	lw	a1,0(s1)
    80004882:	dde5                	beqz	a1,8000487a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004884:	0009a503          	lw	a0,0(s3)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	8f4080e7          	jalr	-1804(ra) # 8000417c <bfree>
      ip->addrs[i] = 0;
    80004890:	0004a023          	sw	zero,0(s1)
    80004894:	b7dd                	j	8000487a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004896:	0809a583          	lw	a1,128(s3)
    8000489a:	e185                	bnez	a1,800048ba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000489c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800048a0:	854e                	mv	a0,s3
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	de4080e7          	jalr	-540(ra) # 80004686 <iupdate>
}
    800048aa:	70a2                	ld	ra,40(sp)
    800048ac:	7402                	ld	s0,32(sp)
    800048ae:	64e2                	ld	s1,24(sp)
    800048b0:	6942                	ld	s2,16(sp)
    800048b2:	69a2                	ld	s3,8(sp)
    800048b4:	6a02                	ld	s4,0(sp)
    800048b6:	6145                	addi	sp,sp,48
    800048b8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800048ba:	0009a503          	lw	a0,0(s3)
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	678080e7          	jalr	1656(ra) # 80003f36 <bread>
    800048c6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800048c8:	05850493          	addi	s1,a0,88
    800048cc:	45850913          	addi	s2,a0,1112
    800048d0:	a811                	j	800048e4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800048d2:	0009a503          	lw	a0,0(s3)
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	8a6080e7          	jalr	-1882(ra) # 8000417c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800048de:	0491                	addi	s1,s1,4
    800048e0:	01248563          	beq	s1,s2,800048ea <itrunc+0x8c>
      if(a[j])
    800048e4:	408c                	lw	a1,0(s1)
    800048e6:	dde5                	beqz	a1,800048de <itrunc+0x80>
    800048e8:	b7ed                	j	800048d2 <itrunc+0x74>
    brelse(bp);
    800048ea:	8552                	mv	a0,s4
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	77a080e7          	jalr	1914(ra) # 80004066 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800048f4:	0809a583          	lw	a1,128(s3)
    800048f8:	0009a503          	lw	a0,0(s3)
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	880080e7          	jalr	-1920(ra) # 8000417c <bfree>
    ip->addrs[NDIRECT] = 0;
    80004904:	0809a023          	sw	zero,128(s3)
    80004908:	bf51                	j	8000489c <itrunc+0x3e>

000000008000490a <iput>:
{
    8000490a:	1101                	addi	sp,sp,-32
    8000490c:	ec06                	sd	ra,24(sp)
    8000490e:	e822                	sd	s0,16(sp)
    80004910:	e426                	sd	s1,8(sp)
    80004912:	e04a                	sd	s2,0(sp)
    80004914:	1000                	addi	s0,sp,32
    80004916:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004918:	0023f517          	auipc	a0,0x23f
    8000491c:	e1850513          	addi	a0,a0,-488 # 80243730 <itable>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	58c080e7          	jalr	1420(ra) # 80000eac <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004928:	4498                	lw	a4,8(s1)
    8000492a:	4785                	li	a5,1
    8000492c:	02f70363          	beq	a4,a5,80004952 <iput+0x48>
  ip->ref--;
    80004930:	449c                	lw	a5,8(s1)
    80004932:	37fd                	addiw	a5,a5,-1
    80004934:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004936:	0023f517          	auipc	a0,0x23f
    8000493a:	dfa50513          	addi	a0,a0,-518 # 80243730 <itable>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	622080e7          	jalr	1570(ra) # 80000f60 <release>
}
    80004946:	60e2                	ld	ra,24(sp)
    80004948:	6442                	ld	s0,16(sp)
    8000494a:	64a2                	ld	s1,8(sp)
    8000494c:	6902                	ld	s2,0(sp)
    8000494e:	6105                	addi	sp,sp,32
    80004950:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004952:	40bc                	lw	a5,64(s1)
    80004954:	dff1                	beqz	a5,80004930 <iput+0x26>
    80004956:	04a49783          	lh	a5,74(s1)
    8000495a:	fbf9                	bnez	a5,80004930 <iput+0x26>
    acquiresleep(&ip->lock);
    8000495c:	01048913          	addi	s2,s1,16
    80004960:	854a                	mv	a0,s2
    80004962:	00001097          	auipc	ra,0x1
    80004966:	aa8080e7          	jalr	-1368(ra) # 8000540a <acquiresleep>
    release(&itable.lock);
    8000496a:	0023f517          	auipc	a0,0x23f
    8000496e:	dc650513          	addi	a0,a0,-570 # 80243730 <itable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	5ee080e7          	jalr	1518(ra) # 80000f60 <release>
    itrunc(ip);
    8000497a:	8526                	mv	a0,s1
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	ee2080e7          	jalr	-286(ra) # 8000485e <itrunc>
    ip->type = 0;
    80004984:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004988:	8526                	mv	a0,s1
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	cfc080e7          	jalr	-772(ra) # 80004686 <iupdate>
    ip->valid = 0;
    80004992:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004996:	854a                	mv	a0,s2
    80004998:	00001097          	auipc	ra,0x1
    8000499c:	ac8080e7          	jalr	-1336(ra) # 80005460 <releasesleep>
    acquire(&itable.lock);
    800049a0:	0023f517          	auipc	a0,0x23f
    800049a4:	d9050513          	addi	a0,a0,-624 # 80243730 <itable>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	504080e7          	jalr	1284(ra) # 80000eac <acquire>
    800049b0:	b741                	j	80004930 <iput+0x26>

00000000800049b2 <iunlockput>:
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	1000                	addi	s0,sp,32
    800049bc:	84aa                	mv	s1,a0
  iunlock(ip);
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	e54080e7          	jalr	-428(ra) # 80004812 <iunlock>
  iput(ip);
    800049c6:	8526                	mv	a0,s1
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	f42080e7          	jalr	-190(ra) # 8000490a <iput>
}
    800049d0:	60e2                	ld	ra,24(sp)
    800049d2:	6442                	ld	s0,16(sp)
    800049d4:	64a2                	ld	s1,8(sp)
    800049d6:	6105                	addi	sp,sp,32
    800049d8:	8082                	ret

00000000800049da <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800049da:	1141                	addi	sp,sp,-16
    800049dc:	e422                	sd	s0,8(sp)
    800049de:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800049e0:	411c                	lw	a5,0(a0)
    800049e2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800049e4:	415c                	lw	a5,4(a0)
    800049e6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800049e8:	04451783          	lh	a5,68(a0)
    800049ec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800049f0:	04a51783          	lh	a5,74(a0)
    800049f4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800049f8:	04c56783          	lwu	a5,76(a0)
    800049fc:	e99c                	sd	a5,16(a1)
}
    800049fe:	6422                	ld	s0,8(sp)
    80004a00:	0141                	addi	sp,sp,16
    80004a02:	8082                	ret

0000000080004a04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004a04:	457c                	lw	a5,76(a0)
    80004a06:	0ed7e963          	bltu	a5,a3,80004af8 <readi+0xf4>
{
    80004a0a:	7159                	addi	sp,sp,-112
    80004a0c:	f486                	sd	ra,104(sp)
    80004a0e:	f0a2                	sd	s0,96(sp)
    80004a10:	eca6                	sd	s1,88(sp)
    80004a12:	e8ca                	sd	s2,80(sp)
    80004a14:	e4ce                	sd	s3,72(sp)
    80004a16:	e0d2                	sd	s4,64(sp)
    80004a18:	fc56                	sd	s5,56(sp)
    80004a1a:	f85a                	sd	s6,48(sp)
    80004a1c:	f45e                	sd	s7,40(sp)
    80004a1e:	f062                	sd	s8,32(sp)
    80004a20:	ec66                	sd	s9,24(sp)
    80004a22:	e86a                	sd	s10,16(sp)
    80004a24:	e46e                	sd	s11,8(sp)
    80004a26:	1880                	addi	s0,sp,112
    80004a28:	8b2a                	mv	s6,a0
    80004a2a:	8bae                	mv	s7,a1
    80004a2c:	8a32                	mv	s4,a2
    80004a2e:	84b6                	mv	s1,a3
    80004a30:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004a32:	9f35                	addw	a4,a4,a3
    return 0;
    80004a34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004a36:	0ad76063          	bltu	a4,a3,80004ad6 <readi+0xd2>
  if(off + n > ip->size)
    80004a3a:	00e7f463          	bgeu	a5,a4,80004a42 <readi+0x3e>
    n = ip->size - off;
    80004a3e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a42:	0a0a8963          	beqz	s5,80004af4 <readi+0xf0>
    80004a46:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a48:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004a4c:	5c7d                	li	s8,-1
    80004a4e:	a82d                	j	80004a88 <readi+0x84>
    80004a50:	020d1d93          	slli	s11,s10,0x20
    80004a54:	020ddd93          	srli	s11,s11,0x20
    80004a58:	05890613          	addi	a2,s2,88
    80004a5c:	86ee                	mv	a3,s11
    80004a5e:	963a                	add	a2,a2,a4
    80004a60:	85d2                	mv	a1,s4
    80004a62:	855e                	mv	a0,s7
    80004a64:	ffffe097          	auipc	ra,0xffffe
    80004a68:	fc6080e7          	jalr	-58(ra) # 80002a2a <either_copyout>
    80004a6c:	05850d63          	beq	a0,s8,80004ac6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004a70:	854a                	mv	a0,s2
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	5f4080e7          	jalr	1524(ra) # 80004066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a7a:	013d09bb          	addw	s3,s10,s3
    80004a7e:	009d04bb          	addw	s1,s10,s1
    80004a82:	9a6e                	add	s4,s4,s11
    80004a84:	0559f763          	bgeu	s3,s5,80004ad2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004a88:	00a4d59b          	srliw	a1,s1,0xa
    80004a8c:	855a                	mv	a0,s6
    80004a8e:	00000097          	auipc	ra,0x0
    80004a92:	8a2080e7          	jalr	-1886(ra) # 80004330 <bmap>
    80004a96:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004a9a:	cd85                	beqz	a1,80004ad2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004a9c:	000b2503          	lw	a0,0(s6)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	496080e7          	jalr	1174(ra) # 80003f36 <bread>
    80004aa8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004aaa:	3ff4f713          	andi	a4,s1,1023
    80004aae:	40ec87bb          	subw	a5,s9,a4
    80004ab2:	413a86bb          	subw	a3,s5,s3
    80004ab6:	8d3e                	mv	s10,a5
    80004ab8:	2781                	sext.w	a5,a5
    80004aba:	0006861b          	sext.w	a2,a3
    80004abe:	f8f679e3          	bgeu	a2,a5,80004a50 <readi+0x4c>
    80004ac2:	8d36                	mv	s10,a3
    80004ac4:	b771                	j	80004a50 <readi+0x4c>
      brelse(bp);
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	59e080e7          	jalr	1438(ra) # 80004066 <brelse>
      tot = -1;
    80004ad0:	59fd                	li	s3,-1
  }
  return tot;
    80004ad2:	0009851b          	sext.w	a0,s3
}
    80004ad6:	70a6                	ld	ra,104(sp)
    80004ad8:	7406                	ld	s0,96(sp)
    80004ada:	64e6                	ld	s1,88(sp)
    80004adc:	6946                	ld	s2,80(sp)
    80004ade:	69a6                	ld	s3,72(sp)
    80004ae0:	6a06                	ld	s4,64(sp)
    80004ae2:	7ae2                	ld	s5,56(sp)
    80004ae4:	7b42                	ld	s6,48(sp)
    80004ae6:	7ba2                	ld	s7,40(sp)
    80004ae8:	7c02                	ld	s8,32(sp)
    80004aea:	6ce2                	ld	s9,24(sp)
    80004aec:	6d42                	ld	s10,16(sp)
    80004aee:	6da2                	ld	s11,8(sp)
    80004af0:	6165                	addi	sp,sp,112
    80004af2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004af4:	89d6                	mv	s3,s5
    80004af6:	bff1                	j	80004ad2 <readi+0xce>
    return 0;
    80004af8:	4501                	li	a0,0
}
    80004afa:	8082                	ret

0000000080004afc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004afc:	457c                	lw	a5,76(a0)
    80004afe:	10d7e863          	bltu	a5,a3,80004c0e <writei+0x112>
{
    80004b02:	7159                	addi	sp,sp,-112
    80004b04:	f486                	sd	ra,104(sp)
    80004b06:	f0a2                	sd	s0,96(sp)
    80004b08:	eca6                	sd	s1,88(sp)
    80004b0a:	e8ca                	sd	s2,80(sp)
    80004b0c:	e4ce                	sd	s3,72(sp)
    80004b0e:	e0d2                	sd	s4,64(sp)
    80004b10:	fc56                	sd	s5,56(sp)
    80004b12:	f85a                	sd	s6,48(sp)
    80004b14:	f45e                	sd	s7,40(sp)
    80004b16:	f062                	sd	s8,32(sp)
    80004b18:	ec66                	sd	s9,24(sp)
    80004b1a:	e86a                	sd	s10,16(sp)
    80004b1c:	e46e                	sd	s11,8(sp)
    80004b1e:	1880                	addi	s0,sp,112
    80004b20:	8aaa                	mv	s5,a0
    80004b22:	8bae                	mv	s7,a1
    80004b24:	8a32                	mv	s4,a2
    80004b26:	8936                	mv	s2,a3
    80004b28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004b2a:	00e687bb          	addw	a5,a3,a4
    80004b2e:	0ed7e263          	bltu	a5,a3,80004c12 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004b32:	00043737          	lui	a4,0x43
    80004b36:	0ef76063          	bltu	a4,a5,80004c16 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b3a:	0c0b0863          	beqz	s6,80004c0a <writei+0x10e>
    80004b3e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004b40:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004b44:	5c7d                	li	s8,-1
    80004b46:	a091                	j	80004b8a <writei+0x8e>
    80004b48:	020d1d93          	slli	s11,s10,0x20
    80004b4c:	020ddd93          	srli	s11,s11,0x20
    80004b50:	05848513          	addi	a0,s1,88
    80004b54:	86ee                	mv	a3,s11
    80004b56:	8652                	mv	a2,s4
    80004b58:	85de                	mv	a1,s7
    80004b5a:	953a                	add	a0,a0,a4
    80004b5c:	ffffe097          	auipc	ra,0xffffe
    80004b60:	f24080e7          	jalr	-220(ra) # 80002a80 <either_copyin>
    80004b64:	07850263          	beq	a0,s8,80004bc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	780080e7          	jalr	1920(ra) # 800052ea <log_write>
    brelse(bp);
    80004b72:	8526                	mv	a0,s1
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	4f2080e7          	jalr	1266(ra) # 80004066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b7c:	013d09bb          	addw	s3,s10,s3
    80004b80:	012d093b          	addw	s2,s10,s2
    80004b84:	9a6e                	add	s4,s4,s11
    80004b86:	0569f663          	bgeu	s3,s6,80004bd2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004b8a:	00a9559b          	srliw	a1,s2,0xa
    80004b8e:	8556                	mv	a0,s5
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	7a0080e7          	jalr	1952(ra) # 80004330 <bmap>
    80004b98:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004b9c:	c99d                	beqz	a1,80004bd2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004b9e:	000aa503          	lw	a0,0(s5)
    80004ba2:	fffff097          	auipc	ra,0xfffff
    80004ba6:	394080e7          	jalr	916(ra) # 80003f36 <bread>
    80004baa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004bac:	3ff97713          	andi	a4,s2,1023
    80004bb0:	40ec87bb          	subw	a5,s9,a4
    80004bb4:	413b06bb          	subw	a3,s6,s3
    80004bb8:	8d3e                	mv	s10,a5
    80004bba:	2781                	sext.w	a5,a5
    80004bbc:	0006861b          	sext.w	a2,a3
    80004bc0:	f8f674e3          	bgeu	a2,a5,80004b48 <writei+0x4c>
    80004bc4:	8d36                	mv	s10,a3
    80004bc6:	b749                	j	80004b48 <writei+0x4c>
      brelse(bp);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	49c080e7          	jalr	1180(ra) # 80004066 <brelse>
  }

  if(off > ip->size)
    80004bd2:	04caa783          	lw	a5,76(s5)
    80004bd6:	0127f463          	bgeu	a5,s2,80004bde <writei+0xe2>
    ip->size = off;
    80004bda:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004bde:	8556                	mv	a0,s5
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	aa6080e7          	jalr	-1370(ra) # 80004686 <iupdate>

  return tot;
    80004be8:	0009851b          	sext.w	a0,s3
}
    80004bec:	70a6                	ld	ra,104(sp)
    80004bee:	7406                	ld	s0,96(sp)
    80004bf0:	64e6                	ld	s1,88(sp)
    80004bf2:	6946                	ld	s2,80(sp)
    80004bf4:	69a6                	ld	s3,72(sp)
    80004bf6:	6a06                	ld	s4,64(sp)
    80004bf8:	7ae2                	ld	s5,56(sp)
    80004bfa:	7b42                	ld	s6,48(sp)
    80004bfc:	7ba2                	ld	s7,40(sp)
    80004bfe:	7c02                	ld	s8,32(sp)
    80004c00:	6ce2                	ld	s9,24(sp)
    80004c02:	6d42                	ld	s10,16(sp)
    80004c04:	6da2                	ld	s11,8(sp)
    80004c06:	6165                	addi	sp,sp,112
    80004c08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004c0a:	89da                	mv	s3,s6
    80004c0c:	bfc9                	j	80004bde <writei+0xe2>
    return -1;
    80004c0e:	557d                	li	a0,-1
}
    80004c10:	8082                	ret
    return -1;
    80004c12:	557d                	li	a0,-1
    80004c14:	bfe1                	j	80004bec <writei+0xf0>
    return -1;
    80004c16:	557d                	li	a0,-1
    80004c18:	bfd1                	j	80004bec <writei+0xf0>

0000000080004c1a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004c1a:	1141                	addi	sp,sp,-16
    80004c1c:	e406                	sd	ra,8(sp)
    80004c1e:	e022                	sd	s0,0(sp)
    80004c20:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004c22:	4639                	li	a2,14
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	45c080e7          	jalr	1116(ra) # 80001080 <strncmp>
}
    80004c2c:	60a2                	ld	ra,8(sp)
    80004c2e:	6402                	ld	s0,0(sp)
    80004c30:	0141                	addi	sp,sp,16
    80004c32:	8082                	ret

0000000080004c34 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004c34:	7139                	addi	sp,sp,-64
    80004c36:	fc06                	sd	ra,56(sp)
    80004c38:	f822                	sd	s0,48(sp)
    80004c3a:	f426                	sd	s1,40(sp)
    80004c3c:	f04a                	sd	s2,32(sp)
    80004c3e:	ec4e                	sd	s3,24(sp)
    80004c40:	e852                	sd	s4,16(sp)
    80004c42:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004c44:	04451703          	lh	a4,68(a0)
    80004c48:	4785                	li	a5,1
    80004c4a:	00f71a63          	bne	a4,a5,80004c5e <dirlookup+0x2a>
    80004c4e:	892a                	mv	s2,a0
    80004c50:	89ae                	mv	s3,a1
    80004c52:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c54:	457c                	lw	a5,76(a0)
    80004c56:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004c58:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c5a:	e79d                	bnez	a5,80004c88 <dirlookup+0x54>
    80004c5c:	a8a5                	j	80004cd4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004c5e:	00005517          	auipc	a0,0x5
    80004c62:	c2a50513          	addi	a0,a0,-982 # 80009888 <syscalls+0x1c8>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8de080e7          	jalr	-1826(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004c6e:	00005517          	auipc	a0,0x5
    80004c72:	c3250513          	addi	a0,a0,-974 # 800098a0 <syscalls+0x1e0>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	8ce080e7          	jalr	-1842(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c7e:	24c1                	addiw	s1,s1,16
    80004c80:	04c92783          	lw	a5,76(s2)
    80004c84:	04f4f763          	bgeu	s1,a5,80004cd2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c88:	4741                	li	a4,16
    80004c8a:	86a6                	mv	a3,s1
    80004c8c:	fc040613          	addi	a2,s0,-64
    80004c90:	4581                	li	a1,0
    80004c92:	854a                	mv	a0,s2
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	d70080e7          	jalr	-656(ra) # 80004a04 <readi>
    80004c9c:	47c1                	li	a5,16
    80004c9e:	fcf518e3          	bne	a0,a5,80004c6e <dirlookup+0x3a>
    if(de.inum == 0)
    80004ca2:	fc045783          	lhu	a5,-64(s0)
    80004ca6:	dfe1                	beqz	a5,80004c7e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004ca8:	fc240593          	addi	a1,s0,-62
    80004cac:	854e                	mv	a0,s3
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	f6c080e7          	jalr	-148(ra) # 80004c1a <namecmp>
    80004cb6:	f561                	bnez	a0,80004c7e <dirlookup+0x4a>
      if(poff)
    80004cb8:	000a0463          	beqz	s4,80004cc0 <dirlookup+0x8c>
        *poff = off;
    80004cbc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004cc0:	fc045583          	lhu	a1,-64(s0)
    80004cc4:	00092503          	lw	a0,0(s2)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	750080e7          	jalr	1872(ra) # 80004418 <iget>
    80004cd0:	a011                	j	80004cd4 <dirlookup+0xa0>
  return 0;
    80004cd2:	4501                	li	a0,0
}
    80004cd4:	70e2                	ld	ra,56(sp)
    80004cd6:	7442                	ld	s0,48(sp)
    80004cd8:	74a2                	ld	s1,40(sp)
    80004cda:	7902                	ld	s2,32(sp)
    80004cdc:	69e2                	ld	s3,24(sp)
    80004cde:	6a42                	ld	s4,16(sp)
    80004ce0:	6121                	addi	sp,sp,64
    80004ce2:	8082                	ret

0000000080004ce4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004ce4:	711d                	addi	sp,sp,-96
    80004ce6:	ec86                	sd	ra,88(sp)
    80004ce8:	e8a2                	sd	s0,80(sp)
    80004cea:	e4a6                	sd	s1,72(sp)
    80004cec:	e0ca                	sd	s2,64(sp)
    80004cee:	fc4e                	sd	s3,56(sp)
    80004cf0:	f852                	sd	s4,48(sp)
    80004cf2:	f456                	sd	s5,40(sp)
    80004cf4:	f05a                	sd	s6,32(sp)
    80004cf6:	ec5e                	sd	s7,24(sp)
    80004cf8:	e862                	sd	s8,16(sp)
    80004cfa:	e466                	sd	s9,8(sp)
    80004cfc:	1080                	addi	s0,sp,96
    80004cfe:	84aa                	mv	s1,a0
    80004d00:	8b2e                	mv	s6,a1
    80004d02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004d04:	00054703          	lbu	a4,0(a0)
    80004d08:	02f00793          	li	a5,47
    80004d0c:	02f70363          	beq	a4,a5,80004d32 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	00e080e7          	jalr	14(ra) # 80001d1e <myproc>
    80004d18:	15853503          	ld	a0,344(a0)
    80004d1c:	00000097          	auipc	ra,0x0
    80004d20:	9f6080e7          	jalr	-1546(ra) # 80004712 <idup>
    80004d24:	89aa                	mv	s3,a0
  while(*path == '/')
    80004d26:	02f00913          	li	s2,47
  len = path - s;
    80004d2a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004d2c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004d2e:	4c05                	li	s8,1
    80004d30:	a865                	j	80004de8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004d32:	4585                	li	a1,1
    80004d34:	4505                	li	a0,1
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	6e2080e7          	jalr	1762(ra) # 80004418 <iget>
    80004d3e:	89aa                	mv	s3,a0
    80004d40:	b7dd                	j	80004d26 <namex+0x42>
      iunlockput(ip);
    80004d42:	854e                	mv	a0,s3
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	c6e080e7          	jalr	-914(ra) # 800049b2 <iunlockput>
      return 0;
    80004d4c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004d4e:	854e                	mv	a0,s3
    80004d50:	60e6                	ld	ra,88(sp)
    80004d52:	6446                	ld	s0,80(sp)
    80004d54:	64a6                	ld	s1,72(sp)
    80004d56:	6906                	ld	s2,64(sp)
    80004d58:	79e2                	ld	s3,56(sp)
    80004d5a:	7a42                	ld	s4,48(sp)
    80004d5c:	7aa2                	ld	s5,40(sp)
    80004d5e:	7b02                	ld	s6,32(sp)
    80004d60:	6be2                	ld	s7,24(sp)
    80004d62:	6c42                	ld	s8,16(sp)
    80004d64:	6ca2                	ld	s9,8(sp)
    80004d66:	6125                	addi	sp,sp,96
    80004d68:	8082                	ret
      iunlock(ip);
    80004d6a:	854e                	mv	a0,s3
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	aa6080e7          	jalr	-1370(ra) # 80004812 <iunlock>
      return ip;
    80004d74:	bfe9                	j	80004d4e <namex+0x6a>
      iunlockput(ip);
    80004d76:	854e                	mv	a0,s3
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	c3a080e7          	jalr	-966(ra) # 800049b2 <iunlockput>
      return 0;
    80004d80:	89d2                	mv	s3,s4
    80004d82:	b7f1                	j	80004d4e <namex+0x6a>
  len = path - s;
    80004d84:	40b48633          	sub	a2,s1,a1
    80004d88:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004d8c:	094cd463          	bge	s9,s4,80004e14 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004d90:	4639                	li	a2,14
    80004d92:	8556                	mv	a0,s5
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	274080e7          	jalr	628(ra) # 80001008 <memmove>
  while(*path == '/')
    80004d9c:	0004c783          	lbu	a5,0(s1)
    80004da0:	01279763          	bne	a5,s2,80004dae <namex+0xca>
    path++;
    80004da4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004da6:	0004c783          	lbu	a5,0(s1)
    80004daa:	ff278de3          	beq	a5,s2,80004da4 <namex+0xc0>
    ilock(ip);
    80004dae:	854e                	mv	a0,s3
    80004db0:	00000097          	auipc	ra,0x0
    80004db4:	9a0080e7          	jalr	-1632(ra) # 80004750 <ilock>
    if(ip->type != T_DIR){
    80004db8:	04499783          	lh	a5,68(s3)
    80004dbc:	f98793e3          	bne	a5,s8,80004d42 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004dc0:	000b0563          	beqz	s6,80004dca <namex+0xe6>
    80004dc4:	0004c783          	lbu	a5,0(s1)
    80004dc8:	d3cd                	beqz	a5,80004d6a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004dca:	865e                	mv	a2,s7
    80004dcc:	85d6                	mv	a1,s5
    80004dce:	854e                	mv	a0,s3
    80004dd0:	00000097          	auipc	ra,0x0
    80004dd4:	e64080e7          	jalr	-412(ra) # 80004c34 <dirlookup>
    80004dd8:	8a2a                	mv	s4,a0
    80004dda:	dd51                	beqz	a0,80004d76 <namex+0x92>
    iunlockput(ip);
    80004ddc:	854e                	mv	a0,s3
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	bd4080e7          	jalr	-1068(ra) # 800049b2 <iunlockput>
    ip = next;
    80004de6:	89d2                	mv	s3,s4
  while(*path == '/')
    80004de8:	0004c783          	lbu	a5,0(s1)
    80004dec:	05279763          	bne	a5,s2,80004e3a <namex+0x156>
    path++;
    80004df0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004df2:	0004c783          	lbu	a5,0(s1)
    80004df6:	ff278de3          	beq	a5,s2,80004df0 <namex+0x10c>
  if(*path == 0)
    80004dfa:	c79d                	beqz	a5,80004e28 <namex+0x144>
    path++;
    80004dfc:	85a6                	mv	a1,s1
  len = path - s;
    80004dfe:	8a5e                	mv	s4,s7
    80004e00:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004e02:	01278963          	beq	a5,s2,80004e14 <namex+0x130>
    80004e06:	dfbd                	beqz	a5,80004d84 <namex+0xa0>
    path++;
    80004e08:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004e0a:	0004c783          	lbu	a5,0(s1)
    80004e0e:	ff279ce3          	bne	a5,s2,80004e06 <namex+0x122>
    80004e12:	bf8d                	j	80004d84 <namex+0xa0>
    memmove(name, s, len);
    80004e14:	2601                	sext.w	a2,a2
    80004e16:	8556                	mv	a0,s5
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	1f0080e7          	jalr	496(ra) # 80001008 <memmove>
    name[len] = 0;
    80004e20:	9a56                	add	s4,s4,s5
    80004e22:	000a0023          	sb	zero,0(s4)
    80004e26:	bf9d                	j	80004d9c <namex+0xb8>
  if(nameiparent){
    80004e28:	f20b03e3          	beqz	s6,80004d4e <namex+0x6a>
    iput(ip);
    80004e2c:	854e                	mv	a0,s3
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	adc080e7          	jalr	-1316(ra) # 8000490a <iput>
    return 0;
    80004e36:	4981                	li	s3,0
    80004e38:	bf19                	j	80004d4e <namex+0x6a>
  if(*path == 0)
    80004e3a:	d7fd                	beqz	a5,80004e28 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004e3c:	0004c783          	lbu	a5,0(s1)
    80004e40:	85a6                	mv	a1,s1
    80004e42:	b7d1                	j	80004e06 <namex+0x122>

0000000080004e44 <dirlink>:
{
    80004e44:	7139                	addi	sp,sp,-64
    80004e46:	fc06                	sd	ra,56(sp)
    80004e48:	f822                	sd	s0,48(sp)
    80004e4a:	f426                	sd	s1,40(sp)
    80004e4c:	f04a                	sd	s2,32(sp)
    80004e4e:	ec4e                	sd	s3,24(sp)
    80004e50:	e852                	sd	s4,16(sp)
    80004e52:	0080                	addi	s0,sp,64
    80004e54:	892a                	mv	s2,a0
    80004e56:	8a2e                	mv	s4,a1
    80004e58:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004e5a:	4601                	li	a2,0
    80004e5c:	00000097          	auipc	ra,0x0
    80004e60:	dd8080e7          	jalr	-552(ra) # 80004c34 <dirlookup>
    80004e64:	e93d                	bnez	a0,80004eda <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004e66:	04c92483          	lw	s1,76(s2)
    80004e6a:	c49d                	beqz	s1,80004e98 <dirlink+0x54>
    80004e6c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e6e:	4741                	li	a4,16
    80004e70:	86a6                	mv	a3,s1
    80004e72:	fc040613          	addi	a2,s0,-64
    80004e76:	4581                	li	a1,0
    80004e78:	854a                	mv	a0,s2
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	b8a080e7          	jalr	-1142(ra) # 80004a04 <readi>
    80004e82:	47c1                	li	a5,16
    80004e84:	06f51163          	bne	a0,a5,80004ee6 <dirlink+0xa2>
    if(de.inum == 0)
    80004e88:	fc045783          	lhu	a5,-64(s0)
    80004e8c:	c791                	beqz	a5,80004e98 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004e8e:	24c1                	addiw	s1,s1,16
    80004e90:	04c92783          	lw	a5,76(s2)
    80004e94:	fcf4ede3          	bltu	s1,a5,80004e6e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004e98:	4639                	li	a2,14
    80004e9a:	85d2                	mv	a1,s4
    80004e9c:	fc240513          	addi	a0,s0,-62
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	21c080e7          	jalr	540(ra) # 800010bc <strncpy>
  de.inum = inum;
    80004ea8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004eac:	4741                	li	a4,16
    80004eae:	86a6                	mv	a3,s1
    80004eb0:	fc040613          	addi	a2,s0,-64
    80004eb4:	4581                	li	a1,0
    80004eb6:	854a                	mv	a0,s2
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	c44080e7          	jalr	-956(ra) # 80004afc <writei>
    80004ec0:	1541                	addi	a0,a0,-16
    80004ec2:	00a03533          	snez	a0,a0
    80004ec6:	40a00533          	neg	a0,a0
}
    80004eca:	70e2                	ld	ra,56(sp)
    80004ecc:	7442                	ld	s0,48(sp)
    80004ece:	74a2                	ld	s1,40(sp)
    80004ed0:	7902                	ld	s2,32(sp)
    80004ed2:	69e2                	ld	s3,24(sp)
    80004ed4:	6a42                	ld	s4,16(sp)
    80004ed6:	6121                	addi	sp,sp,64
    80004ed8:	8082                	ret
    iput(ip);
    80004eda:	00000097          	auipc	ra,0x0
    80004ede:	a30080e7          	jalr	-1488(ra) # 8000490a <iput>
    return -1;
    80004ee2:	557d                	li	a0,-1
    80004ee4:	b7dd                	j	80004eca <dirlink+0x86>
      panic("dirlink read");
    80004ee6:	00005517          	auipc	a0,0x5
    80004eea:	9ca50513          	addi	a0,a0,-1590 # 800098b0 <syscalls+0x1f0>
    80004eee:	ffffb097          	auipc	ra,0xffffb
    80004ef2:	656080e7          	jalr	1622(ra) # 80000544 <panic>

0000000080004ef6 <namei>:

struct inode*
namei(char *path)
{
    80004ef6:	1101                	addi	sp,sp,-32
    80004ef8:	ec06                	sd	ra,24(sp)
    80004efa:	e822                	sd	s0,16(sp)
    80004efc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004efe:	fe040613          	addi	a2,s0,-32
    80004f02:	4581                	li	a1,0
    80004f04:	00000097          	auipc	ra,0x0
    80004f08:	de0080e7          	jalr	-544(ra) # 80004ce4 <namex>
}
    80004f0c:	60e2                	ld	ra,24(sp)
    80004f0e:	6442                	ld	s0,16(sp)
    80004f10:	6105                	addi	sp,sp,32
    80004f12:	8082                	ret

0000000080004f14 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004f14:	1141                	addi	sp,sp,-16
    80004f16:	e406                	sd	ra,8(sp)
    80004f18:	e022                	sd	s0,0(sp)
    80004f1a:	0800                	addi	s0,sp,16
    80004f1c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004f1e:	4585                	li	a1,1
    80004f20:	00000097          	auipc	ra,0x0
    80004f24:	dc4080e7          	jalr	-572(ra) # 80004ce4 <namex>
}
    80004f28:	60a2                	ld	ra,8(sp)
    80004f2a:	6402                	ld	s0,0(sp)
    80004f2c:	0141                	addi	sp,sp,16
    80004f2e:	8082                	ret

0000000080004f30 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004f30:	1101                	addi	sp,sp,-32
    80004f32:	ec06                	sd	ra,24(sp)
    80004f34:	e822                	sd	s0,16(sp)
    80004f36:	e426                	sd	s1,8(sp)
    80004f38:	e04a                	sd	s2,0(sp)
    80004f3a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004f3c:	00240917          	auipc	s2,0x240
    80004f40:	29c90913          	addi	s2,s2,668 # 802451d8 <log>
    80004f44:	01892583          	lw	a1,24(s2)
    80004f48:	02892503          	lw	a0,40(s2)
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	fea080e7          	jalr	-22(ra) # 80003f36 <bread>
    80004f54:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004f56:	02c92683          	lw	a3,44(s2)
    80004f5a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004f5c:	02d05763          	blez	a3,80004f8a <write_head+0x5a>
    80004f60:	00240797          	auipc	a5,0x240
    80004f64:	2a878793          	addi	a5,a5,680 # 80245208 <log+0x30>
    80004f68:	05c50713          	addi	a4,a0,92
    80004f6c:	36fd                	addiw	a3,a3,-1
    80004f6e:	1682                	slli	a3,a3,0x20
    80004f70:	9281                	srli	a3,a3,0x20
    80004f72:	068a                	slli	a3,a3,0x2
    80004f74:	00240617          	auipc	a2,0x240
    80004f78:	29860613          	addi	a2,a2,664 # 8024520c <log+0x34>
    80004f7c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004f7e:	4390                	lw	a2,0(a5)
    80004f80:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004f82:	0791                	addi	a5,a5,4
    80004f84:	0711                	addi	a4,a4,4
    80004f86:	fed79ce3          	bne	a5,a3,80004f7e <write_head+0x4e>
  }
  bwrite(buf);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	09c080e7          	jalr	156(ra) # 80004028 <bwrite>
  brelse(buf);
    80004f94:	8526                	mv	a0,s1
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	0d0080e7          	jalr	208(ra) # 80004066 <brelse>
}
    80004f9e:	60e2                	ld	ra,24(sp)
    80004fa0:	6442                	ld	s0,16(sp)
    80004fa2:	64a2                	ld	s1,8(sp)
    80004fa4:	6902                	ld	s2,0(sp)
    80004fa6:	6105                	addi	sp,sp,32
    80004fa8:	8082                	ret

0000000080004faa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004faa:	00240797          	auipc	a5,0x240
    80004fae:	25a7a783          	lw	a5,602(a5) # 80245204 <log+0x2c>
    80004fb2:	0af05d63          	blez	a5,8000506c <install_trans+0xc2>
{
    80004fb6:	7139                	addi	sp,sp,-64
    80004fb8:	fc06                	sd	ra,56(sp)
    80004fba:	f822                	sd	s0,48(sp)
    80004fbc:	f426                	sd	s1,40(sp)
    80004fbe:	f04a                	sd	s2,32(sp)
    80004fc0:	ec4e                	sd	s3,24(sp)
    80004fc2:	e852                	sd	s4,16(sp)
    80004fc4:	e456                	sd	s5,8(sp)
    80004fc6:	e05a                	sd	s6,0(sp)
    80004fc8:	0080                	addi	s0,sp,64
    80004fca:	8b2a                	mv	s6,a0
    80004fcc:	00240a97          	auipc	s5,0x240
    80004fd0:	23ca8a93          	addi	s5,s5,572 # 80245208 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004fd4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004fd6:	00240997          	auipc	s3,0x240
    80004fda:	20298993          	addi	s3,s3,514 # 802451d8 <log>
    80004fde:	a035                	j	8000500a <install_trans+0x60>
      bunpin(dbuf);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	15e080e7          	jalr	350(ra) # 80004140 <bunpin>
    brelse(lbuf);
    80004fea:	854a                	mv	a0,s2
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	07a080e7          	jalr	122(ra) # 80004066 <brelse>
    brelse(dbuf);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	070080e7          	jalr	112(ra) # 80004066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ffe:	2a05                	addiw	s4,s4,1
    80005000:	0a91                	addi	s5,s5,4
    80005002:	02c9a783          	lw	a5,44(s3)
    80005006:	04fa5963          	bge	s4,a5,80005058 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000500a:	0189a583          	lw	a1,24(s3)
    8000500e:	014585bb          	addw	a1,a1,s4
    80005012:	2585                	addiw	a1,a1,1
    80005014:	0289a503          	lw	a0,40(s3)
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	f1e080e7          	jalr	-226(ra) # 80003f36 <bread>
    80005020:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005022:	000aa583          	lw	a1,0(s5)
    80005026:	0289a503          	lw	a0,40(s3)
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	f0c080e7          	jalr	-244(ra) # 80003f36 <bread>
    80005032:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005034:	40000613          	li	a2,1024
    80005038:	05890593          	addi	a1,s2,88
    8000503c:	05850513          	addi	a0,a0,88
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	fc8080e7          	jalr	-56(ra) # 80001008 <memmove>
    bwrite(dbuf);  // write dst to disk
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	fde080e7          	jalr	-34(ra) # 80004028 <bwrite>
    if(recovering == 0)
    80005052:	f80b1ce3          	bnez	s6,80004fea <install_trans+0x40>
    80005056:	b769                	j	80004fe0 <install_trans+0x36>
}
    80005058:	70e2                	ld	ra,56(sp)
    8000505a:	7442                	ld	s0,48(sp)
    8000505c:	74a2                	ld	s1,40(sp)
    8000505e:	7902                	ld	s2,32(sp)
    80005060:	69e2                	ld	s3,24(sp)
    80005062:	6a42                	ld	s4,16(sp)
    80005064:	6aa2                	ld	s5,8(sp)
    80005066:	6b02                	ld	s6,0(sp)
    80005068:	6121                	addi	sp,sp,64
    8000506a:	8082                	ret
    8000506c:	8082                	ret

000000008000506e <initlog>:
{
    8000506e:	7179                	addi	sp,sp,-48
    80005070:	f406                	sd	ra,40(sp)
    80005072:	f022                	sd	s0,32(sp)
    80005074:	ec26                	sd	s1,24(sp)
    80005076:	e84a                	sd	s2,16(sp)
    80005078:	e44e                	sd	s3,8(sp)
    8000507a:	1800                	addi	s0,sp,48
    8000507c:	892a                	mv	s2,a0
    8000507e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005080:	00240497          	auipc	s1,0x240
    80005084:	15848493          	addi	s1,s1,344 # 802451d8 <log>
    80005088:	00005597          	auipc	a1,0x5
    8000508c:	83858593          	addi	a1,a1,-1992 # 800098c0 <syscalls+0x200>
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	d8a080e7          	jalr	-630(ra) # 80000e1c <initlock>
  log.start = sb->logstart;
    8000509a:	0149a583          	lw	a1,20(s3)
    8000509e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800050a0:	0109a783          	lw	a5,16(s3)
    800050a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800050a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800050aa:	854a                	mv	a0,s2
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	e8a080e7          	jalr	-374(ra) # 80003f36 <bread>
  log.lh.n = lh->n;
    800050b4:	4d3c                	lw	a5,88(a0)
    800050b6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800050b8:	02f05563          	blez	a5,800050e2 <initlog+0x74>
    800050bc:	05c50713          	addi	a4,a0,92
    800050c0:	00240697          	auipc	a3,0x240
    800050c4:	14868693          	addi	a3,a3,328 # 80245208 <log+0x30>
    800050c8:	37fd                	addiw	a5,a5,-1
    800050ca:	1782                	slli	a5,a5,0x20
    800050cc:	9381                	srli	a5,a5,0x20
    800050ce:	078a                	slli	a5,a5,0x2
    800050d0:	06050613          	addi	a2,a0,96
    800050d4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800050d6:	4310                	lw	a2,0(a4)
    800050d8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800050da:	0711                	addi	a4,a4,4
    800050dc:	0691                	addi	a3,a3,4
    800050de:	fef71ce3          	bne	a4,a5,800050d6 <initlog+0x68>
  brelse(buf);
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	f84080e7          	jalr	-124(ra) # 80004066 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800050ea:	4505                	li	a0,1
    800050ec:	00000097          	auipc	ra,0x0
    800050f0:	ebe080e7          	jalr	-322(ra) # 80004faa <install_trans>
  log.lh.n = 0;
    800050f4:	00240797          	auipc	a5,0x240
    800050f8:	1007a823          	sw	zero,272(a5) # 80245204 <log+0x2c>
  write_head(); // clear the log
    800050fc:	00000097          	auipc	ra,0x0
    80005100:	e34080e7          	jalr	-460(ra) # 80004f30 <write_head>
}
    80005104:	70a2                	ld	ra,40(sp)
    80005106:	7402                	ld	s0,32(sp)
    80005108:	64e2                	ld	s1,24(sp)
    8000510a:	6942                	ld	s2,16(sp)
    8000510c:	69a2                	ld	s3,8(sp)
    8000510e:	6145                	addi	sp,sp,48
    80005110:	8082                	ret

0000000080005112 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005112:	1101                	addi	sp,sp,-32
    80005114:	ec06                	sd	ra,24(sp)
    80005116:	e822                	sd	s0,16(sp)
    80005118:	e426                	sd	s1,8(sp)
    8000511a:	e04a                	sd	s2,0(sp)
    8000511c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000511e:	00240517          	auipc	a0,0x240
    80005122:	0ba50513          	addi	a0,a0,186 # 802451d8 <log>
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	d86080e7          	jalr	-634(ra) # 80000eac <acquire>
  while(1){
    if(log.committing){
    8000512e:	00240497          	auipc	s1,0x240
    80005132:	0aa48493          	addi	s1,s1,170 # 802451d8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005136:	4979                	li	s2,30
    80005138:	a039                	j	80005146 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000513a:	85a6                	mv	a1,s1
    8000513c:	8526                	mv	a0,s1
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	4d8080e7          	jalr	1240(ra) # 80002616 <sleep>
    if(log.committing){
    80005146:	50dc                	lw	a5,36(s1)
    80005148:	fbed                	bnez	a5,8000513a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000514a:	509c                	lw	a5,32(s1)
    8000514c:	0017871b          	addiw	a4,a5,1
    80005150:	0007069b          	sext.w	a3,a4
    80005154:	0027179b          	slliw	a5,a4,0x2
    80005158:	9fb9                	addw	a5,a5,a4
    8000515a:	0017979b          	slliw	a5,a5,0x1
    8000515e:	54d8                	lw	a4,44(s1)
    80005160:	9fb9                	addw	a5,a5,a4
    80005162:	00f95963          	bge	s2,a5,80005174 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005166:	85a6                	mv	a1,s1
    80005168:	8526                	mv	a0,s1
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	4ac080e7          	jalr	1196(ra) # 80002616 <sleep>
    80005172:	bfd1                	j	80005146 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80005174:	00240517          	auipc	a0,0x240
    80005178:	06450513          	addi	a0,a0,100 # 802451d8 <log>
    8000517c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	de2080e7          	jalr	-542(ra) # 80000f60 <release>
      break;
    }
  }
}
    80005186:	60e2                	ld	ra,24(sp)
    80005188:	6442                	ld	s0,16(sp)
    8000518a:	64a2                	ld	s1,8(sp)
    8000518c:	6902                	ld	s2,0(sp)
    8000518e:	6105                	addi	sp,sp,32
    80005190:	8082                	ret

0000000080005192 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005192:	7139                	addi	sp,sp,-64
    80005194:	fc06                	sd	ra,56(sp)
    80005196:	f822                	sd	s0,48(sp)
    80005198:	f426                	sd	s1,40(sp)
    8000519a:	f04a                	sd	s2,32(sp)
    8000519c:	ec4e                	sd	s3,24(sp)
    8000519e:	e852                	sd	s4,16(sp)
    800051a0:	e456                	sd	s5,8(sp)
    800051a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800051a4:	00240497          	auipc	s1,0x240
    800051a8:	03448493          	addi	s1,s1,52 # 802451d8 <log>
    800051ac:	8526                	mv	a0,s1
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	cfe080e7          	jalr	-770(ra) # 80000eac <acquire>
  log.outstanding -= 1;
    800051b6:	509c                	lw	a5,32(s1)
    800051b8:	37fd                	addiw	a5,a5,-1
    800051ba:	0007891b          	sext.w	s2,a5
    800051be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800051c0:	50dc                	lw	a5,36(s1)
    800051c2:	efb9                	bnez	a5,80005220 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800051c4:	06091663          	bnez	s2,80005230 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800051c8:	00240497          	auipc	s1,0x240
    800051cc:	01048493          	addi	s1,s1,16 # 802451d8 <log>
    800051d0:	4785                	li	a5,1
    800051d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	d8a080e7          	jalr	-630(ra) # 80000f60 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800051de:	54dc                	lw	a5,44(s1)
    800051e0:	06f04763          	bgtz	a5,8000524e <end_op+0xbc>
    acquire(&log.lock);
    800051e4:	00240497          	auipc	s1,0x240
    800051e8:	ff448493          	addi	s1,s1,-12 # 802451d8 <log>
    800051ec:	8526                	mv	a0,s1
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	cbe080e7          	jalr	-834(ra) # 80000eac <acquire>
    log.committing = 0;
    800051f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	47e080e7          	jalr	1150(ra) # 8000267a <wakeup>
    release(&log.lock);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	d5a080e7          	jalr	-678(ra) # 80000f60 <release>
}
    8000520e:	70e2                	ld	ra,56(sp)
    80005210:	7442                	ld	s0,48(sp)
    80005212:	74a2                	ld	s1,40(sp)
    80005214:	7902                	ld	s2,32(sp)
    80005216:	69e2                	ld	s3,24(sp)
    80005218:	6a42                	ld	s4,16(sp)
    8000521a:	6aa2                	ld	s5,8(sp)
    8000521c:	6121                	addi	sp,sp,64
    8000521e:	8082                	ret
    panic("log.committing");
    80005220:	00004517          	auipc	a0,0x4
    80005224:	6a850513          	addi	a0,a0,1704 # 800098c8 <syscalls+0x208>
    80005228:	ffffb097          	auipc	ra,0xffffb
    8000522c:	31c080e7          	jalr	796(ra) # 80000544 <panic>
    wakeup(&log);
    80005230:	00240497          	auipc	s1,0x240
    80005234:	fa848493          	addi	s1,s1,-88 # 802451d8 <log>
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	440080e7          	jalr	1088(ra) # 8000267a <wakeup>
  release(&log.lock);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	d1c080e7          	jalr	-740(ra) # 80000f60 <release>
  if(do_commit){
    8000524c:	b7c9                	j	8000520e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000524e:	00240a97          	auipc	s5,0x240
    80005252:	fbaa8a93          	addi	s5,s5,-70 # 80245208 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005256:	00240a17          	auipc	s4,0x240
    8000525a:	f82a0a13          	addi	s4,s4,-126 # 802451d8 <log>
    8000525e:	018a2583          	lw	a1,24(s4)
    80005262:	012585bb          	addw	a1,a1,s2
    80005266:	2585                	addiw	a1,a1,1
    80005268:	028a2503          	lw	a0,40(s4)
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	cca080e7          	jalr	-822(ra) # 80003f36 <bread>
    80005274:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005276:	000aa583          	lw	a1,0(s5)
    8000527a:	028a2503          	lw	a0,40(s4)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	cb8080e7          	jalr	-840(ra) # 80003f36 <bread>
    80005286:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005288:	40000613          	li	a2,1024
    8000528c:	05850593          	addi	a1,a0,88
    80005290:	05848513          	addi	a0,s1,88
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	d74080e7          	jalr	-652(ra) # 80001008 <memmove>
    bwrite(to);  // write the log
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	d8a080e7          	jalr	-630(ra) # 80004028 <bwrite>
    brelse(from);
    800052a6:	854e                	mv	a0,s3
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	dbe080e7          	jalr	-578(ra) # 80004066 <brelse>
    brelse(to);
    800052b0:	8526                	mv	a0,s1
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	db4080e7          	jalr	-588(ra) # 80004066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800052ba:	2905                	addiw	s2,s2,1
    800052bc:	0a91                	addi	s5,s5,4
    800052be:	02ca2783          	lw	a5,44(s4)
    800052c2:	f8f94ee3          	blt	s2,a5,8000525e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	c6a080e7          	jalr	-918(ra) # 80004f30 <write_head>
    install_trans(0); // Now install writes to home locations
    800052ce:	4501                	li	a0,0
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	cda080e7          	jalr	-806(ra) # 80004faa <install_trans>
    log.lh.n = 0;
    800052d8:	00240797          	auipc	a5,0x240
    800052dc:	f207a623          	sw	zero,-212(a5) # 80245204 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	c50080e7          	jalr	-944(ra) # 80004f30 <write_head>
    800052e8:	bdf5                	j	800051e4 <end_op+0x52>

00000000800052ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800052ea:	1101                	addi	sp,sp,-32
    800052ec:	ec06                	sd	ra,24(sp)
    800052ee:	e822                	sd	s0,16(sp)
    800052f0:	e426                	sd	s1,8(sp)
    800052f2:	e04a                	sd	s2,0(sp)
    800052f4:	1000                	addi	s0,sp,32
    800052f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800052f8:	00240917          	auipc	s2,0x240
    800052fc:	ee090913          	addi	s2,s2,-288 # 802451d8 <log>
    80005300:	854a                	mv	a0,s2
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	baa080e7          	jalr	-1110(ra) # 80000eac <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000530a:	02c92603          	lw	a2,44(s2)
    8000530e:	47f5                	li	a5,29
    80005310:	06c7c563          	blt	a5,a2,8000537a <log_write+0x90>
    80005314:	00240797          	auipc	a5,0x240
    80005318:	ee07a783          	lw	a5,-288(a5) # 802451f4 <log+0x1c>
    8000531c:	37fd                	addiw	a5,a5,-1
    8000531e:	04f65e63          	bge	a2,a5,8000537a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005322:	00240797          	auipc	a5,0x240
    80005326:	ed67a783          	lw	a5,-298(a5) # 802451f8 <log+0x20>
    8000532a:	06f05063          	blez	a5,8000538a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000532e:	4781                	li	a5,0
    80005330:	06c05563          	blez	a2,8000539a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005334:	44cc                	lw	a1,12(s1)
    80005336:	00240717          	auipc	a4,0x240
    8000533a:	ed270713          	addi	a4,a4,-302 # 80245208 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000533e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005340:	4314                	lw	a3,0(a4)
    80005342:	04b68c63          	beq	a3,a1,8000539a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005346:	2785                	addiw	a5,a5,1
    80005348:	0711                	addi	a4,a4,4
    8000534a:	fef61be3          	bne	a2,a5,80005340 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000534e:	0621                	addi	a2,a2,8
    80005350:	060a                	slli	a2,a2,0x2
    80005352:	00240797          	auipc	a5,0x240
    80005356:	e8678793          	addi	a5,a5,-378 # 802451d8 <log>
    8000535a:	963e                	add	a2,a2,a5
    8000535c:	44dc                	lw	a5,12(s1)
    8000535e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	da2080e7          	jalr	-606(ra) # 80004104 <bpin>
    log.lh.n++;
    8000536a:	00240717          	auipc	a4,0x240
    8000536e:	e6e70713          	addi	a4,a4,-402 # 802451d8 <log>
    80005372:	575c                	lw	a5,44(a4)
    80005374:	2785                	addiw	a5,a5,1
    80005376:	d75c                	sw	a5,44(a4)
    80005378:	a835                	j	800053b4 <log_write+0xca>
    panic("too big a transaction");
    8000537a:	00004517          	auipc	a0,0x4
    8000537e:	55e50513          	addi	a0,a0,1374 # 800098d8 <syscalls+0x218>
    80005382:	ffffb097          	auipc	ra,0xffffb
    80005386:	1c2080e7          	jalr	450(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000538a:	00004517          	auipc	a0,0x4
    8000538e:	56650513          	addi	a0,a0,1382 # 800098f0 <syscalls+0x230>
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	1b2080e7          	jalr	434(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000539a:	00878713          	addi	a4,a5,8
    8000539e:	00271693          	slli	a3,a4,0x2
    800053a2:	00240717          	auipc	a4,0x240
    800053a6:	e3670713          	addi	a4,a4,-458 # 802451d8 <log>
    800053aa:	9736                	add	a4,a4,a3
    800053ac:	44d4                	lw	a3,12(s1)
    800053ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800053b0:	faf608e3          	beq	a2,a5,80005360 <log_write+0x76>
  }
  release(&log.lock);
    800053b4:	00240517          	auipc	a0,0x240
    800053b8:	e2450513          	addi	a0,a0,-476 # 802451d8 <log>
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	ba4080e7          	jalr	-1116(ra) # 80000f60 <release>
}
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	64a2                	ld	s1,8(sp)
    800053ca:	6902                	ld	s2,0(sp)
    800053cc:	6105                	addi	sp,sp,32
    800053ce:	8082                	ret

00000000800053d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800053d0:	1101                	addi	sp,sp,-32
    800053d2:	ec06                	sd	ra,24(sp)
    800053d4:	e822                	sd	s0,16(sp)
    800053d6:	e426                	sd	s1,8(sp)
    800053d8:	e04a                	sd	s2,0(sp)
    800053da:	1000                	addi	s0,sp,32
    800053dc:	84aa                	mv	s1,a0
    800053de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800053e0:	00004597          	auipc	a1,0x4
    800053e4:	53058593          	addi	a1,a1,1328 # 80009910 <syscalls+0x250>
    800053e8:	0521                	addi	a0,a0,8
    800053ea:	ffffc097          	auipc	ra,0xffffc
    800053ee:	a32080e7          	jalr	-1486(ra) # 80000e1c <initlock>
  lk->name = name;
    800053f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800053f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800053fa:	0204a423          	sw	zero,40(s1)
}
    800053fe:	60e2                	ld	ra,24(sp)
    80005400:	6442                	ld	s0,16(sp)
    80005402:	64a2                	ld	s1,8(sp)
    80005404:	6902                	ld	s2,0(sp)
    80005406:	6105                	addi	sp,sp,32
    80005408:	8082                	ret

000000008000540a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000540a:	1101                	addi	sp,sp,-32
    8000540c:	ec06                	sd	ra,24(sp)
    8000540e:	e822                	sd	s0,16(sp)
    80005410:	e426                	sd	s1,8(sp)
    80005412:	e04a                	sd	s2,0(sp)
    80005414:	1000                	addi	s0,sp,32
    80005416:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005418:	00850913          	addi	s2,a0,8
    8000541c:	854a                	mv	a0,s2
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	a8e080e7          	jalr	-1394(ra) # 80000eac <acquire>
  while (lk->locked) {
    80005426:	409c                	lw	a5,0(s1)
    80005428:	cb89                	beqz	a5,8000543a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000542a:	85ca                	mv	a1,s2
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffd097          	auipc	ra,0xffffd
    80005432:	1e8080e7          	jalr	488(ra) # 80002616 <sleep>
  while (lk->locked) {
    80005436:	409c                	lw	a5,0(s1)
    80005438:	fbed                	bnez	a5,8000542a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000543a:	4785                	li	a5,1
    8000543c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000543e:	ffffd097          	auipc	ra,0xffffd
    80005442:	8e0080e7          	jalr	-1824(ra) # 80001d1e <myproc>
    80005446:	591c                	lw	a5,48(a0)
    80005448:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000544a:	854a                	mv	a0,s2
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	b14080e7          	jalr	-1260(ra) # 80000f60 <release>
}
    80005454:	60e2                	ld	ra,24(sp)
    80005456:	6442                	ld	s0,16(sp)
    80005458:	64a2                	ld	s1,8(sp)
    8000545a:	6902                	ld	s2,0(sp)
    8000545c:	6105                	addi	sp,sp,32
    8000545e:	8082                	ret

0000000080005460 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005460:	1101                	addi	sp,sp,-32
    80005462:	ec06                	sd	ra,24(sp)
    80005464:	e822                	sd	s0,16(sp)
    80005466:	e426                	sd	s1,8(sp)
    80005468:	e04a                	sd	s2,0(sp)
    8000546a:	1000                	addi	s0,sp,32
    8000546c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000546e:	00850913          	addi	s2,a0,8
    80005472:	854a                	mv	a0,s2
    80005474:	ffffc097          	auipc	ra,0xffffc
    80005478:	a38080e7          	jalr	-1480(ra) # 80000eac <acquire>
  lk->locked = 0;
    8000547c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005480:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	1f4080e7          	jalr	500(ra) # 8000267a <wakeup>
  release(&lk->lk);
    8000548e:	854a                	mv	a0,s2
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	ad0080e7          	jalr	-1328(ra) # 80000f60 <release>
}
    80005498:	60e2                	ld	ra,24(sp)
    8000549a:	6442                	ld	s0,16(sp)
    8000549c:	64a2                	ld	s1,8(sp)
    8000549e:	6902                	ld	s2,0(sp)
    800054a0:	6105                	addi	sp,sp,32
    800054a2:	8082                	ret

00000000800054a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800054a4:	7179                	addi	sp,sp,-48
    800054a6:	f406                	sd	ra,40(sp)
    800054a8:	f022                	sd	s0,32(sp)
    800054aa:	ec26                	sd	s1,24(sp)
    800054ac:	e84a                	sd	s2,16(sp)
    800054ae:	e44e                	sd	s3,8(sp)
    800054b0:	1800                	addi	s0,sp,48
    800054b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800054b4:	00850913          	addi	s2,a0,8
    800054b8:	854a                	mv	a0,s2
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	9f2080e7          	jalr	-1550(ra) # 80000eac <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800054c2:	409c                	lw	a5,0(s1)
    800054c4:	ef99                	bnez	a5,800054e2 <holdingsleep+0x3e>
    800054c6:	4481                	li	s1,0
  release(&lk->lk);
    800054c8:	854a                	mv	a0,s2
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	a96080e7          	jalr	-1386(ra) # 80000f60 <release>
  return r;
}
    800054d2:	8526                	mv	a0,s1
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	64e2                	ld	s1,24(sp)
    800054da:	6942                	ld	s2,16(sp)
    800054dc:	69a2                	ld	s3,8(sp)
    800054de:	6145                	addi	sp,sp,48
    800054e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800054e2:	0284a983          	lw	s3,40(s1)
    800054e6:	ffffd097          	auipc	ra,0xffffd
    800054ea:	838080e7          	jalr	-1992(ra) # 80001d1e <myproc>
    800054ee:	5904                	lw	s1,48(a0)
    800054f0:	413484b3          	sub	s1,s1,s3
    800054f4:	0014b493          	seqz	s1,s1
    800054f8:	bfc1                	j	800054c8 <holdingsleep+0x24>

00000000800054fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800054fa:	1141                	addi	sp,sp,-16
    800054fc:	e406                	sd	ra,8(sp)
    800054fe:	e022                	sd	s0,0(sp)
    80005500:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005502:	00004597          	auipc	a1,0x4
    80005506:	41e58593          	addi	a1,a1,1054 # 80009920 <syscalls+0x260>
    8000550a:	00240517          	auipc	a0,0x240
    8000550e:	e1650513          	addi	a0,a0,-490 # 80245320 <ftable>
    80005512:	ffffc097          	auipc	ra,0xffffc
    80005516:	90a080e7          	jalr	-1782(ra) # 80000e1c <initlock>
}
    8000551a:	60a2                	ld	ra,8(sp)
    8000551c:	6402                	ld	s0,0(sp)
    8000551e:	0141                	addi	sp,sp,16
    80005520:	8082                	ret

0000000080005522 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005522:	1101                	addi	sp,sp,-32
    80005524:	ec06                	sd	ra,24(sp)
    80005526:	e822                	sd	s0,16(sp)
    80005528:	e426                	sd	s1,8(sp)
    8000552a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000552c:	00240517          	auipc	a0,0x240
    80005530:	df450513          	addi	a0,a0,-524 # 80245320 <ftable>
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	978080e7          	jalr	-1672(ra) # 80000eac <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000553c:	00240497          	auipc	s1,0x240
    80005540:	dfc48493          	addi	s1,s1,-516 # 80245338 <ftable+0x18>
    80005544:	00241717          	auipc	a4,0x241
    80005548:	d9470713          	addi	a4,a4,-620 # 802462d8 <disk>
    if(f->ref == 0){
    8000554c:	40dc                	lw	a5,4(s1)
    8000554e:	cf99                	beqz	a5,8000556c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005550:	02848493          	addi	s1,s1,40
    80005554:	fee49ce3          	bne	s1,a4,8000554c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005558:	00240517          	auipc	a0,0x240
    8000555c:	dc850513          	addi	a0,a0,-568 # 80245320 <ftable>
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	a00080e7          	jalr	-1536(ra) # 80000f60 <release>
  return 0;
    80005568:	4481                	li	s1,0
    8000556a:	a819                	j	80005580 <filealloc+0x5e>
      f->ref = 1;
    8000556c:	4785                	li	a5,1
    8000556e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005570:	00240517          	auipc	a0,0x240
    80005574:	db050513          	addi	a0,a0,-592 # 80245320 <ftable>
    80005578:	ffffc097          	auipc	ra,0xffffc
    8000557c:	9e8080e7          	jalr	-1560(ra) # 80000f60 <release>
}
    80005580:	8526                	mv	a0,s1
    80005582:	60e2                	ld	ra,24(sp)
    80005584:	6442                	ld	s0,16(sp)
    80005586:	64a2                	ld	s1,8(sp)
    80005588:	6105                	addi	sp,sp,32
    8000558a:	8082                	ret

000000008000558c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000558c:	1101                	addi	sp,sp,-32
    8000558e:	ec06                	sd	ra,24(sp)
    80005590:	e822                	sd	s0,16(sp)
    80005592:	e426                	sd	s1,8(sp)
    80005594:	1000                	addi	s0,sp,32
    80005596:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005598:	00240517          	auipc	a0,0x240
    8000559c:	d8850513          	addi	a0,a0,-632 # 80245320 <ftable>
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	90c080e7          	jalr	-1780(ra) # 80000eac <acquire>
  if(f->ref < 1)
    800055a8:	40dc                	lw	a5,4(s1)
    800055aa:	02f05263          	blez	a5,800055ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800055ae:	2785                	addiw	a5,a5,1
    800055b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800055b2:	00240517          	auipc	a0,0x240
    800055b6:	d6e50513          	addi	a0,a0,-658 # 80245320 <ftable>
    800055ba:	ffffc097          	auipc	ra,0xffffc
    800055be:	9a6080e7          	jalr	-1626(ra) # 80000f60 <release>
  return f;
}
    800055c2:	8526                	mv	a0,s1
    800055c4:	60e2                	ld	ra,24(sp)
    800055c6:	6442                	ld	s0,16(sp)
    800055c8:	64a2                	ld	s1,8(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret
    panic("filedup");
    800055ce:	00004517          	auipc	a0,0x4
    800055d2:	35a50513          	addi	a0,a0,858 # 80009928 <syscalls+0x268>
    800055d6:	ffffb097          	auipc	ra,0xffffb
    800055da:	f6e080e7          	jalr	-146(ra) # 80000544 <panic>

00000000800055de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800055de:	7139                	addi	sp,sp,-64
    800055e0:	fc06                	sd	ra,56(sp)
    800055e2:	f822                	sd	s0,48(sp)
    800055e4:	f426                	sd	s1,40(sp)
    800055e6:	f04a                	sd	s2,32(sp)
    800055e8:	ec4e                	sd	s3,24(sp)
    800055ea:	e852                	sd	s4,16(sp)
    800055ec:	e456                	sd	s5,8(sp)
    800055ee:	0080                	addi	s0,sp,64
    800055f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800055f2:	00240517          	auipc	a0,0x240
    800055f6:	d2e50513          	addi	a0,a0,-722 # 80245320 <ftable>
    800055fa:	ffffc097          	auipc	ra,0xffffc
    800055fe:	8b2080e7          	jalr	-1870(ra) # 80000eac <acquire>
  if(f->ref < 1)
    80005602:	40dc                	lw	a5,4(s1)
    80005604:	06f05163          	blez	a5,80005666 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005608:	37fd                	addiw	a5,a5,-1
    8000560a:	0007871b          	sext.w	a4,a5
    8000560e:	c0dc                	sw	a5,4(s1)
    80005610:	06e04363          	bgtz	a4,80005676 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005614:	0004a903          	lw	s2,0(s1)
    80005618:	0094ca83          	lbu	s5,9(s1)
    8000561c:	0104ba03          	ld	s4,16(s1)
    80005620:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005624:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005628:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000562c:	00240517          	auipc	a0,0x240
    80005630:	cf450513          	addi	a0,a0,-780 # 80245320 <ftable>
    80005634:	ffffc097          	auipc	ra,0xffffc
    80005638:	92c080e7          	jalr	-1748(ra) # 80000f60 <release>

  if(ff.type == FD_PIPE){
    8000563c:	4785                	li	a5,1
    8000563e:	04f90d63          	beq	s2,a5,80005698 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005642:	3979                	addiw	s2,s2,-2
    80005644:	4785                	li	a5,1
    80005646:	0527e063          	bltu	a5,s2,80005686 <fileclose+0xa8>
    begin_op();
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	ac8080e7          	jalr	-1336(ra) # 80005112 <begin_op>
    iput(ff.ip);
    80005652:	854e                	mv	a0,s3
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	2b6080e7          	jalr	694(ra) # 8000490a <iput>
    end_op();
    8000565c:	00000097          	auipc	ra,0x0
    80005660:	b36080e7          	jalr	-1226(ra) # 80005192 <end_op>
    80005664:	a00d                	j	80005686 <fileclose+0xa8>
    panic("fileclose");
    80005666:	00004517          	auipc	a0,0x4
    8000566a:	2ca50513          	addi	a0,a0,714 # 80009930 <syscalls+0x270>
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	ed6080e7          	jalr	-298(ra) # 80000544 <panic>
    release(&ftable.lock);
    80005676:	00240517          	auipc	a0,0x240
    8000567a:	caa50513          	addi	a0,a0,-854 # 80245320 <ftable>
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	8e2080e7          	jalr	-1822(ra) # 80000f60 <release>
  }
}
    80005686:	70e2                	ld	ra,56(sp)
    80005688:	7442                	ld	s0,48(sp)
    8000568a:	74a2                	ld	s1,40(sp)
    8000568c:	7902                	ld	s2,32(sp)
    8000568e:	69e2                	ld	s3,24(sp)
    80005690:	6a42                	ld	s4,16(sp)
    80005692:	6aa2                	ld	s5,8(sp)
    80005694:	6121                	addi	sp,sp,64
    80005696:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005698:	85d6                	mv	a1,s5
    8000569a:	8552                	mv	a0,s4
    8000569c:	00000097          	auipc	ra,0x0
    800056a0:	34c080e7          	jalr	844(ra) # 800059e8 <pipeclose>
    800056a4:	b7cd                	j	80005686 <fileclose+0xa8>

00000000800056a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800056a6:	715d                	addi	sp,sp,-80
    800056a8:	e486                	sd	ra,72(sp)
    800056aa:	e0a2                	sd	s0,64(sp)
    800056ac:	fc26                	sd	s1,56(sp)
    800056ae:	f84a                	sd	s2,48(sp)
    800056b0:	f44e                	sd	s3,40(sp)
    800056b2:	0880                	addi	s0,sp,80
    800056b4:	84aa                	mv	s1,a0
    800056b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800056b8:	ffffc097          	auipc	ra,0xffffc
    800056bc:	666080e7          	jalr	1638(ra) # 80001d1e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800056c0:	409c                	lw	a5,0(s1)
    800056c2:	37f9                	addiw	a5,a5,-2
    800056c4:	4705                	li	a4,1
    800056c6:	04f76763          	bltu	a4,a5,80005714 <filestat+0x6e>
    800056ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800056cc:	6c88                	ld	a0,24(s1)
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	082080e7          	jalr	130(ra) # 80004750 <ilock>
    stati(f->ip, &st);
    800056d6:	fb840593          	addi	a1,s0,-72
    800056da:	6c88                	ld	a0,24(s1)
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	2fe080e7          	jalr	766(ra) # 800049da <stati>
    iunlock(f->ip);
    800056e4:	6c88                	ld	a0,24(s1)
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	12c080e7          	jalr	300(ra) # 80004812 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800056ee:	46e1                	li	a3,24
    800056f0:	fb840613          	addi	a2,s0,-72
    800056f4:	85ce                	mv	a1,s3
    800056f6:	05893503          	ld	a0,88(s2)
    800056fa:	ffffc097          	auipc	ra,0xffffc
    800056fe:	250080e7          	jalr	592(ra) # 8000194a <copyout>
    80005702:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005706:	60a6                	ld	ra,72(sp)
    80005708:	6406                	ld	s0,64(sp)
    8000570a:	74e2                	ld	s1,56(sp)
    8000570c:	7942                	ld	s2,48(sp)
    8000570e:	79a2                	ld	s3,40(sp)
    80005710:	6161                	addi	sp,sp,80
    80005712:	8082                	ret
  return -1;
    80005714:	557d                	li	a0,-1
    80005716:	bfc5                	j	80005706 <filestat+0x60>

0000000080005718 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005718:	7179                	addi	sp,sp,-48
    8000571a:	f406                	sd	ra,40(sp)
    8000571c:	f022                	sd	s0,32(sp)
    8000571e:	ec26                	sd	s1,24(sp)
    80005720:	e84a                	sd	s2,16(sp)
    80005722:	e44e                	sd	s3,8(sp)
    80005724:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005726:	00854783          	lbu	a5,8(a0)
    8000572a:	c3d5                	beqz	a5,800057ce <fileread+0xb6>
    8000572c:	84aa                	mv	s1,a0
    8000572e:	89ae                	mv	s3,a1
    80005730:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005732:	411c                	lw	a5,0(a0)
    80005734:	4705                	li	a4,1
    80005736:	04e78963          	beq	a5,a4,80005788 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000573a:	470d                	li	a4,3
    8000573c:	04e78d63          	beq	a5,a4,80005796 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005740:	4709                	li	a4,2
    80005742:	06e79e63          	bne	a5,a4,800057be <fileread+0xa6>
    ilock(f->ip);
    80005746:	6d08                	ld	a0,24(a0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	008080e7          	jalr	8(ra) # 80004750 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005750:	874a                	mv	a4,s2
    80005752:	5094                	lw	a3,32(s1)
    80005754:	864e                	mv	a2,s3
    80005756:	4585                	li	a1,1
    80005758:	6c88                	ld	a0,24(s1)
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	2aa080e7          	jalr	682(ra) # 80004a04 <readi>
    80005762:	892a                	mv	s2,a0
    80005764:	00a05563          	blez	a0,8000576e <fileread+0x56>
      f->off += r;
    80005768:	509c                	lw	a5,32(s1)
    8000576a:	9fa9                	addw	a5,a5,a0
    8000576c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000576e:	6c88                	ld	a0,24(s1)
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	0a2080e7          	jalr	162(ra) # 80004812 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005778:	854a                	mv	a0,s2
    8000577a:	70a2                	ld	ra,40(sp)
    8000577c:	7402                	ld	s0,32(sp)
    8000577e:	64e2                	ld	s1,24(sp)
    80005780:	6942                	ld	s2,16(sp)
    80005782:	69a2                	ld	s3,8(sp)
    80005784:	6145                	addi	sp,sp,48
    80005786:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005788:	6908                	ld	a0,16(a0)
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	3ce080e7          	jalr	974(ra) # 80005b58 <piperead>
    80005792:	892a                	mv	s2,a0
    80005794:	b7d5                	j	80005778 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005796:	02451783          	lh	a5,36(a0)
    8000579a:	03079693          	slli	a3,a5,0x30
    8000579e:	92c1                	srli	a3,a3,0x30
    800057a0:	4725                	li	a4,9
    800057a2:	02d76863          	bltu	a4,a3,800057d2 <fileread+0xba>
    800057a6:	0792                	slli	a5,a5,0x4
    800057a8:	00240717          	auipc	a4,0x240
    800057ac:	ad870713          	addi	a4,a4,-1320 # 80245280 <devsw>
    800057b0:	97ba                	add	a5,a5,a4
    800057b2:	639c                	ld	a5,0(a5)
    800057b4:	c38d                	beqz	a5,800057d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800057b6:	4505                	li	a0,1
    800057b8:	9782                	jalr	a5
    800057ba:	892a                	mv	s2,a0
    800057bc:	bf75                	j	80005778 <fileread+0x60>
    panic("fileread");
    800057be:	00004517          	auipc	a0,0x4
    800057c2:	18250513          	addi	a0,a0,386 # 80009940 <syscalls+0x280>
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	d7e080e7          	jalr	-642(ra) # 80000544 <panic>
    return -1;
    800057ce:	597d                	li	s2,-1
    800057d0:	b765                	j	80005778 <fileread+0x60>
      return -1;
    800057d2:	597d                	li	s2,-1
    800057d4:	b755                	j	80005778 <fileread+0x60>
    800057d6:	597d                	li	s2,-1
    800057d8:	b745                	j	80005778 <fileread+0x60>

00000000800057da <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800057da:	715d                	addi	sp,sp,-80
    800057dc:	e486                	sd	ra,72(sp)
    800057de:	e0a2                	sd	s0,64(sp)
    800057e0:	fc26                	sd	s1,56(sp)
    800057e2:	f84a                	sd	s2,48(sp)
    800057e4:	f44e                	sd	s3,40(sp)
    800057e6:	f052                	sd	s4,32(sp)
    800057e8:	ec56                	sd	s5,24(sp)
    800057ea:	e85a                	sd	s6,16(sp)
    800057ec:	e45e                	sd	s7,8(sp)
    800057ee:	e062                	sd	s8,0(sp)
    800057f0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800057f2:	00954783          	lbu	a5,9(a0)
    800057f6:	10078663          	beqz	a5,80005902 <filewrite+0x128>
    800057fa:	892a                	mv	s2,a0
    800057fc:	8aae                	mv	s5,a1
    800057fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005800:	411c                	lw	a5,0(a0)
    80005802:	4705                	li	a4,1
    80005804:	02e78263          	beq	a5,a4,80005828 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005808:	470d                	li	a4,3
    8000580a:	02e78663          	beq	a5,a4,80005836 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000580e:	4709                	li	a4,2
    80005810:	0ee79163          	bne	a5,a4,800058f2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005814:	0ac05d63          	blez	a2,800058ce <filewrite+0xf4>
    int i = 0;
    80005818:	4981                	li	s3,0
    8000581a:	6b05                	lui	s6,0x1
    8000581c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005820:	6b85                	lui	s7,0x1
    80005822:	c00b8b9b          	addiw	s7,s7,-1024
    80005826:	a861                	j	800058be <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005828:	6908                	ld	a0,16(a0)
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	22e080e7          	jalr	558(ra) # 80005a58 <pipewrite>
    80005832:	8a2a                	mv	s4,a0
    80005834:	a045                	j	800058d4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005836:	02451783          	lh	a5,36(a0)
    8000583a:	03079693          	slli	a3,a5,0x30
    8000583e:	92c1                	srli	a3,a3,0x30
    80005840:	4725                	li	a4,9
    80005842:	0cd76263          	bltu	a4,a3,80005906 <filewrite+0x12c>
    80005846:	0792                	slli	a5,a5,0x4
    80005848:	00240717          	auipc	a4,0x240
    8000584c:	a3870713          	addi	a4,a4,-1480 # 80245280 <devsw>
    80005850:	97ba                	add	a5,a5,a4
    80005852:	679c                	ld	a5,8(a5)
    80005854:	cbdd                	beqz	a5,8000590a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005856:	4505                	li	a0,1
    80005858:	9782                	jalr	a5
    8000585a:	8a2a                	mv	s4,a0
    8000585c:	a8a5                	j	800058d4 <filewrite+0xfa>
    8000585e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005862:	00000097          	auipc	ra,0x0
    80005866:	8b0080e7          	jalr	-1872(ra) # 80005112 <begin_op>
      ilock(f->ip);
    8000586a:	01893503          	ld	a0,24(s2)
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	ee2080e7          	jalr	-286(ra) # 80004750 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005876:	8762                	mv	a4,s8
    80005878:	02092683          	lw	a3,32(s2)
    8000587c:	01598633          	add	a2,s3,s5
    80005880:	4585                	li	a1,1
    80005882:	01893503          	ld	a0,24(s2)
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	276080e7          	jalr	630(ra) # 80004afc <writei>
    8000588e:	84aa                	mv	s1,a0
    80005890:	00a05763          	blez	a0,8000589e <filewrite+0xc4>
        f->off += r;
    80005894:	02092783          	lw	a5,32(s2)
    80005898:	9fa9                	addw	a5,a5,a0
    8000589a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000589e:	01893503          	ld	a0,24(s2)
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	f70080e7          	jalr	-144(ra) # 80004812 <iunlock>
      end_op();
    800058aa:	00000097          	auipc	ra,0x0
    800058ae:	8e8080e7          	jalr	-1816(ra) # 80005192 <end_op>

      if(r != n1){
    800058b2:	009c1f63          	bne	s8,s1,800058d0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800058b6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800058ba:	0149db63          	bge	s3,s4,800058d0 <filewrite+0xf6>
      int n1 = n - i;
    800058be:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800058c2:	84be                	mv	s1,a5
    800058c4:	2781                	sext.w	a5,a5
    800058c6:	f8fb5ce3          	bge	s6,a5,8000585e <filewrite+0x84>
    800058ca:	84de                	mv	s1,s7
    800058cc:	bf49                	j	8000585e <filewrite+0x84>
    int i = 0;
    800058ce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800058d0:	013a1f63          	bne	s4,s3,800058ee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800058d4:	8552                	mv	a0,s4
    800058d6:	60a6                	ld	ra,72(sp)
    800058d8:	6406                	ld	s0,64(sp)
    800058da:	74e2                	ld	s1,56(sp)
    800058dc:	7942                	ld	s2,48(sp)
    800058de:	79a2                	ld	s3,40(sp)
    800058e0:	7a02                	ld	s4,32(sp)
    800058e2:	6ae2                	ld	s5,24(sp)
    800058e4:	6b42                	ld	s6,16(sp)
    800058e6:	6ba2                	ld	s7,8(sp)
    800058e8:	6c02                	ld	s8,0(sp)
    800058ea:	6161                	addi	sp,sp,80
    800058ec:	8082                	ret
    ret = (i == n ? n : -1);
    800058ee:	5a7d                	li	s4,-1
    800058f0:	b7d5                	j	800058d4 <filewrite+0xfa>
    panic("filewrite");
    800058f2:	00004517          	auipc	a0,0x4
    800058f6:	05e50513          	addi	a0,a0,94 # 80009950 <syscalls+0x290>
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	c4a080e7          	jalr	-950(ra) # 80000544 <panic>
    return -1;
    80005902:	5a7d                	li	s4,-1
    80005904:	bfc1                	j	800058d4 <filewrite+0xfa>
      return -1;
    80005906:	5a7d                	li	s4,-1
    80005908:	b7f1                	j	800058d4 <filewrite+0xfa>
    8000590a:	5a7d                	li	s4,-1
    8000590c:	b7e1                	j	800058d4 <filewrite+0xfa>

000000008000590e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000590e:	7179                	addi	sp,sp,-48
    80005910:	f406                	sd	ra,40(sp)
    80005912:	f022                	sd	s0,32(sp)
    80005914:	ec26                	sd	s1,24(sp)
    80005916:	e84a                	sd	s2,16(sp)
    80005918:	e44e                	sd	s3,8(sp)
    8000591a:	e052                	sd	s4,0(sp)
    8000591c:	1800                	addi	s0,sp,48
    8000591e:	84aa                	mv	s1,a0
    80005920:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005922:	0005b023          	sd	zero,0(a1)
    80005926:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	bf8080e7          	jalr	-1032(ra) # 80005522 <filealloc>
    80005932:	e088                	sd	a0,0(s1)
    80005934:	c551                	beqz	a0,800059c0 <pipealloc+0xb2>
    80005936:	00000097          	auipc	ra,0x0
    8000593a:	bec080e7          	jalr	-1044(ra) # 80005522 <filealloc>
    8000593e:	00aa3023          	sd	a0,0(s4)
    80005942:	c92d                	beqz	a0,800059b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005944:	ffffb097          	auipc	ra,0xffffb
    80005948:	3b0080e7          	jalr	944(ra) # 80000cf4 <kalloc>
    8000594c:	892a                	mv	s2,a0
    8000594e:	c125                	beqz	a0,800059ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005950:	4985                	li	s3,1
    80005952:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005956:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000595a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000595e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005962:	00004597          	auipc	a1,0x4
    80005966:	c2e58593          	addi	a1,a1,-978 # 80009590 <states.1925+0x168>
    8000596a:	ffffb097          	auipc	ra,0xffffb
    8000596e:	4b2080e7          	jalr	1202(ra) # 80000e1c <initlock>
  (*f0)->type = FD_PIPE;
    80005972:	609c                	ld	a5,0(s1)
    80005974:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005978:	609c                	ld	a5,0(s1)
    8000597a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000597e:	609c                	ld	a5,0(s1)
    80005980:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005984:	609c                	ld	a5,0(s1)
    80005986:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000598a:	000a3783          	ld	a5,0(s4)
    8000598e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005992:	000a3783          	ld	a5,0(s4)
    80005996:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000599a:	000a3783          	ld	a5,0(s4)
    8000599e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800059a2:	000a3783          	ld	a5,0(s4)
    800059a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800059aa:	4501                	li	a0,0
    800059ac:	a025                	j	800059d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800059ae:	6088                	ld	a0,0(s1)
    800059b0:	e501                	bnez	a0,800059b8 <pipealloc+0xaa>
    800059b2:	a039                	j	800059c0 <pipealloc+0xb2>
    800059b4:	6088                	ld	a0,0(s1)
    800059b6:	c51d                	beqz	a0,800059e4 <pipealloc+0xd6>
    fileclose(*f0);
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	c26080e7          	jalr	-986(ra) # 800055de <fileclose>
  if(*f1)
    800059c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800059c4:	557d                	li	a0,-1
  if(*f1)
    800059c6:	c799                	beqz	a5,800059d4 <pipealloc+0xc6>
    fileclose(*f1);
    800059c8:	853e                	mv	a0,a5
    800059ca:	00000097          	auipc	ra,0x0
    800059ce:	c14080e7          	jalr	-1004(ra) # 800055de <fileclose>
  return -1;
    800059d2:	557d                	li	a0,-1
}
    800059d4:	70a2                	ld	ra,40(sp)
    800059d6:	7402                	ld	s0,32(sp)
    800059d8:	64e2                	ld	s1,24(sp)
    800059da:	6942                	ld	s2,16(sp)
    800059dc:	69a2                	ld	s3,8(sp)
    800059de:	6a02                	ld	s4,0(sp)
    800059e0:	6145                	addi	sp,sp,48
    800059e2:	8082                	ret
  return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7fd                	j	800059d4 <pipealloc+0xc6>

00000000800059e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800059e8:	1101                	addi	sp,sp,-32
    800059ea:	ec06                	sd	ra,24(sp)
    800059ec:	e822                	sd	s0,16(sp)
    800059ee:	e426                	sd	s1,8(sp)
    800059f0:	e04a                	sd	s2,0(sp)
    800059f2:	1000                	addi	s0,sp,32
    800059f4:	84aa                	mv	s1,a0
    800059f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800059f8:	ffffb097          	auipc	ra,0xffffb
    800059fc:	4b4080e7          	jalr	1204(ra) # 80000eac <acquire>
  if(writable){
    80005a00:	02090d63          	beqz	s2,80005a3a <pipeclose+0x52>
    pi->writeopen = 0;
    80005a04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005a08:	21848513          	addi	a0,s1,536
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	c6e080e7          	jalr	-914(ra) # 8000267a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005a14:	2204b783          	ld	a5,544(s1)
    80005a18:	eb95                	bnez	a5,80005a4c <pipeclose+0x64>
    release(&pi->lock);
    80005a1a:	8526                	mv	a0,s1
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	544080e7          	jalr	1348(ra) # 80000f60 <release>
    kfree((char*)pi);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	170080e7          	jalr	368(ra) # 80000b96 <kfree>
  } else
    release(&pi->lock);
}
    80005a2e:	60e2                	ld	ra,24(sp)
    80005a30:	6442                	ld	s0,16(sp)
    80005a32:	64a2                	ld	s1,8(sp)
    80005a34:	6902                	ld	s2,0(sp)
    80005a36:	6105                	addi	sp,sp,32
    80005a38:	8082                	ret
    pi->readopen = 0;
    80005a3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005a3e:	21c48513          	addi	a0,s1,540
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	c38080e7          	jalr	-968(ra) # 8000267a <wakeup>
    80005a4a:	b7e9                	j	80005a14 <pipeclose+0x2c>
    release(&pi->lock);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	512080e7          	jalr	1298(ra) # 80000f60 <release>
}
    80005a56:	bfe1                	j	80005a2e <pipeclose+0x46>

0000000080005a58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005a58:	7159                	addi	sp,sp,-112
    80005a5a:	f486                	sd	ra,104(sp)
    80005a5c:	f0a2                	sd	s0,96(sp)
    80005a5e:	eca6                	sd	s1,88(sp)
    80005a60:	e8ca                	sd	s2,80(sp)
    80005a62:	e4ce                	sd	s3,72(sp)
    80005a64:	e0d2                	sd	s4,64(sp)
    80005a66:	fc56                	sd	s5,56(sp)
    80005a68:	f85a                	sd	s6,48(sp)
    80005a6a:	f45e                	sd	s7,40(sp)
    80005a6c:	f062                	sd	s8,32(sp)
    80005a6e:	ec66                	sd	s9,24(sp)
    80005a70:	1880                	addi	s0,sp,112
    80005a72:	84aa                	mv	s1,a0
    80005a74:	8aae                	mv	s5,a1
    80005a76:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005a78:	ffffc097          	auipc	ra,0xffffc
    80005a7c:	2a6080e7          	jalr	678(ra) # 80001d1e <myproc>
    80005a80:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	428080e7          	jalr	1064(ra) # 80000eac <acquire>
  while(i < n){
    80005a8c:	0d405463          	blez	s4,80005b54 <pipewrite+0xfc>
    80005a90:	8ba6                	mv	s7,s1
  int i = 0;
    80005a92:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005a94:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005a96:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005a9a:	21c48c13          	addi	s8,s1,540
    80005a9e:	a08d                	j	80005b00 <pipewrite+0xa8>
      release(&pi->lock);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	4be080e7          	jalr	1214(ra) # 80000f60 <release>
      return -1;
    80005aaa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005aac:	854a                	mv	a0,s2
    80005aae:	70a6                	ld	ra,104(sp)
    80005ab0:	7406                	ld	s0,96(sp)
    80005ab2:	64e6                	ld	s1,88(sp)
    80005ab4:	6946                	ld	s2,80(sp)
    80005ab6:	69a6                	ld	s3,72(sp)
    80005ab8:	6a06                	ld	s4,64(sp)
    80005aba:	7ae2                	ld	s5,56(sp)
    80005abc:	7b42                	ld	s6,48(sp)
    80005abe:	7ba2                	ld	s7,40(sp)
    80005ac0:	7c02                	ld	s8,32(sp)
    80005ac2:	6ce2                	ld	s9,24(sp)
    80005ac4:	6165                	addi	sp,sp,112
    80005ac6:	8082                	ret
      wakeup(&pi->nread);
    80005ac8:	8566                	mv	a0,s9
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	bb0080e7          	jalr	-1104(ra) # 8000267a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005ad2:	85de                	mv	a1,s7
    80005ad4:	8562                	mv	a0,s8
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	b40080e7          	jalr	-1216(ra) # 80002616 <sleep>
    80005ade:	a839                	j	80005afc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005ae0:	21c4a783          	lw	a5,540(s1)
    80005ae4:	0017871b          	addiw	a4,a5,1
    80005ae8:	20e4ae23          	sw	a4,540(s1)
    80005aec:	1ff7f793          	andi	a5,a5,511
    80005af0:	97a6                	add	a5,a5,s1
    80005af2:	f9f44703          	lbu	a4,-97(s0)
    80005af6:	00e78c23          	sb	a4,24(a5)
      i++;
    80005afa:	2905                	addiw	s2,s2,1
  while(i < n){
    80005afc:	05495063          	bge	s2,s4,80005b3c <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005b00:	2204a783          	lw	a5,544(s1)
    80005b04:	dfd1                	beqz	a5,80005aa0 <pipewrite+0x48>
    80005b06:	854e                	mv	a0,s3
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	dc2080e7          	jalr	-574(ra) # 800028ca <killed>
    80005b10:	f941                	bnez	a0,80005aa0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005b12:	2184a783          	lw	a5,536(s1)
    80005b16:	21c4a703          	lw	a4,540(s1)
    80005b1a:	2007879b          	addiw	a5,a5,512
    80005b1e:	faf705e3          	beq	a4,a5,80005ac8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005b22:	4685                	li	a3,1
    80005b24:	01590633          	add	a2,s2,s5
    80005b28:	f9f40593          	addi	a1,s0,-97
    80005b2c:	0589b503          	ld	a0,88(s3)
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	ede080e7          	jalr	-290(ra) # 80001a0e <copyin>
    80005b38:	fb6514e3          	bne	a0,s6,80005ae0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005b3c:	21848513          	addi	a0,s1,536
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	b3a080e7          	jalr	-1222(ra) # 8000267a <wakeup>
  release(&pi->lock);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffb097          	auipc	ra,0xffffb
    80005b4e:	416080e7          	jalr	1046(ra) # 80000f60 <release>
  return i;
    80005b52:	bfa9                	j	80005aac <pipewrite+0x54>
  int i = 0;
    80005b54:	4901                	li	s2,0
    80005b56:	b7dd                	j	80005b3c <pipewrite+0xe4>

0000000080005b58 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005b58:	715d                	addi	sp,sp,-80
    80005b5a:	e486                	sd	ra,72(sp)
    80005b5c:	e0a2                	sd	s0,64(sp)
    80005b5e:	fc26                	sd	s1,56(sp)
    80005b60:	f84a                	sd	s2,48(sp)
    80005b62:	f44e                	sd	s3,40(sp)
    80005b64:	f052                	sd	s4,32(sp)
    80005b66:	ec56                	sd	s5,24(sp)
    80005b68:	e85a                	sd	s6,16(sp)
    80005b6a:	0880                	addi	s0,sp,80
    80005b6c:	84aa                	mv	s1,a0
    80005b6e:	892e                	mv	s2,a1
    80005b70:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005b72:	ffffc097          	auipc	ra,0xffffc
    80005b76:	1ac080e7          	jalr	428(ra) # 80001d1e <myproc>
    80005b7a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005b7c:	8b26                	mv	s6,s1
    80005b7e:	8526                	mv	a0,s1
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	32c080e7          	jalr	812(ra) # 80000eac <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b88:	2184a703          	lw	a4,536(s1)
    80005b8c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005b90:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b94:	02f71763          	bne	a4,a5,80005bc2 <piperead+0x6a>
    80005b98:	2244a783          	lw	a5,548(s1)
    80005b9c:	c39d                	beqz	a5,80005bc2 <piperead+0x6a>
    if(killed(pr)){
    80005b9e:	8552                	mv	a0,s4
    80005ba0:	ffffd097          	auipc	ra,0xffffd
    80005ba4:	d2a080e7          	jalr	-726(ra) # 800028ca <killed>
    80005ba8:	e941                	bnez	a0,80005c38 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005baa:	85da                	mv	a1,s6
    80005bac:	854e                	mv	a0,s3
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	a68080e7          	jalr	-1432(ra) # 80002616 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005bb6:	2184a703          	lw	a4,536(s1)
    80005bba:	21c4a783          	lw	a5,540(s1)
    80005bbe:	fcf70de3          	beq	a4,a5,80005b98 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bc2:	09505263          	blez	s5,80005c46 <piperead+0xee>
    80005bc6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bc8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005bca:	2184a783          	lw	a5,536(s1)
    80005bce:	21c4a703          	lw	a4,540(s1)
    80005bd2:	02f70d63          	beq	a4,a5,80005c0c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005bd6:	0017871b          	addiw	a4,a5,1
    80005bda:	20e4ac23          	sw	a4,536(s1)
    80005bde:	1ff7f793          	andi	a5,a5,511
    80005be2:	97a6                	add	a5,a5,s1
    80005be4:	0187c783          	lbu	a5,24(a5)
    80005be8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bec:	4685                	li	a3,1
    80005bee:	fbf40613          	addi	a2,s0,-65
    80005bf2:	85ca                	mv	a1,s2
    80005bf4:	058a3503          	ld	a0,88(s4)
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	d52080e7          	jalr	-686(ra) # 8000194a <copyout>
    80005c00:	01650663          	beq	a0,s6,80005c0c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c04:	2985                	addiw	s3,s3,1
    80005c06:	0905                	addi	s2,s2,1
    80005c08:	fd3a91e3          	bne	s5,s3,80005bca <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005c0c:	21c48513          	addi	a0,s1,540
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	a6a080e7          	jalr	-1430(ra) # 8000267a <wakeup>
  release(&pi->lock);
    80005c18:	8526                	mv	a0,s1
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	346080e7          	jalr	838(ra) # 80000f60 <release>
  return i;
}
    80005c22:	854e                	mv	a0,s3
    80005c24:	60a6                	ld	ra,72(sp)
    80005c26:	6406                	ld	s0,64(sp)
    80005c28:	74e2                	ld	s1,56(sp)
    80005c2a:	7942                	ld	s2,48(sp)
    80005c2c:	79a2                	ld	s3,40(sp)
    80005c2e:	7a02                	ld	s4,32(sp)
    80005c30:	6ae2                	ld	s5,24(sp)
    80005c32:	6b42                	ld	s6,16(sp)
    80005c34:	6161                	addi	sp,sp,80
    80005c36:	8082                	ret
      release(&pi->lock);
    80005c38:	8526                	mv	a0,s1
    80005c3a:	ffffb097          	auipc	ra,0xffffb
    80005c3e:	326080e7          	jalr	806(ra) # 80000f60 <release>
      return -1;
    80005c42:	59fd                	li	s3,-1
    80005c44:	bff9                	j	80005c22 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c46:	4981                	li	s3,0
    80005c48:	b7d1                	j	80005c0c <piperead+0xb4>

0000000080005c4a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005c4a:	1141                	addi	sp,sp,-16
    80005c4c:	e422                	sd	s0,8(sp)
    80005c4e:	0800                	addi	s0,sp,16
    80005c50:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005c52:	8905                	andi	a0,a0,1
    80005c54:	c111                	beqz	a0,80005c58 <flags2perm+0xe>
      perm = PTE_X;
    80005c56:	4521                	li	a0,8
    if(flags & 0x2)
    80005c58:	8b89                	andi	a5,a5,2
    80005c5a:	c399                	beqz	a5,80005c60 <flags2perm+0x16>
      perm |= PTE_W;
    80005c5c:	00456513          	ori	a0,a0,4
    return perm;
}
    80005c60:	6422                	ld	s0,8(sp)
    80005c62:	0141                	addi	sp,sp,16
    80005c64:	8082                	ret

0000000080005c66 <exec>:

int
exec(char *path, char **argv)
{
    80005c66:	df010113          	addi	sp,sp,-528
    80005c6a:	20113423          	sd	ra,520(sp)
    80005c6e:	20813023          	sd	s0,512(sp)
    80005c72:	ffa6                	sd	s1,504(sp)
    80005c74:	fbca                	sd	s2,496(sp)
    80005c76:	f7ce                	sd	s3,488(sp)
    80005c78:	f3d2                	sd	s4,480(sp)
    80005c7a:	efd6                	sd	s5,472(sp)
    80005c7c:	ebda                	sd	s6,464(sp)
    80005c7e:	e7de                	sd	s7,456(sp)
    80005c80:	e3e2                	sd	s8,448(sp)
    80005c82:	ff66                	sd	s9,440(sp)
    80005c84:	fb6a                	sd	s10,432(sp)
    80005c86:	f76e                	sd	s11,424(sp)
    80005c88:	0c00                	addi	s0,sp,528
    80005c8a:	84aa                	mv	s1,a0
    80005c8c:	dea43c23          	sd	a0,-520(s0)
    80005c90:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005c94:	ffffc097          	auipc	ra,0xffffc
    80005c98:	08a080e7          	jalr	138(ra) # 80001d1e <myproc>
    80005c9c:	892a                	mv	s2,a0

  begin_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	474080e7          	jalr	1140(ra) # 80005112 <begin_op>

  if((ip = namei(path)) == 0){
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	24e080e7          	jalr	590(ra) # 80004ef6 <namei>
    80005cb0:	c92d                	beqz	a0,80005d22 <exec+0xbc>
    80005cb2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	a9c080e7          	jalr	-1380(ra) # 80004750 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005cbc:	04000713          	li	a4,64
    80005cc0:	4681                	li	a3,0
    80005cc2:	e5040613          	addi	a2,s0,-432
    80005cc6:	4581                	li	a1,0
    80005cc8:	8526                	mv	a0,s1
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	d3a080e7          	jalr	-710(ra) # 80004a04 <readi>
    80005cd2:	04000793          	li	a5,64
    80005cd6:	00f51a63          	bne	a0,a5,80005cea <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005cda:	e5042703          	lw	a4,-432(s0)
    80005cde:	464c47b7          	lui	a5,0x464c4
    80005ce2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005ce6:	04f70463          	beq	a4,a5,80005d2e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005cea:	8526                	mv	a0,s1
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	cc6080e7          	jalr	-826(ra) # 800049b2 <iunlockput>
    end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	49e080e7          	jalr	1182(ra) # 80005192 <end_op>
  }
  return -1;
    80005cfc:	557d                	li	a0,-1
}
    80005cfe:	20813083          	ld	ra,520(sp)
    80005d02:	20013403          	ld	s0,512(sp)
    80005d06:	74fe                	ld	s1,504(sp)
    80005d08:	795e                	ld	s2,496(sp)
    80005d0a:	79be                	ld	s3,488(sp)
    80005d0c:	7a1e                	ld	s4,480(sp)
    80005d0e:	6afe                	ld	s5,472(sp)
    80005d10:	6b5e                	ld	s6,464(sp)
    80005d12:	6bbe                	ld	s7,456(sp)
    80005d14:	6c1e                	ld	s8,448(sp)
    80005d16:	7cfa                	ld	s9,440(sp)
    80005d18:	7d5a                	ld	s10,432(sp)
    80005d1a:	7dba                	ld	s11,424(sp)
    80005d1c:	21010113          	addi	sp,sp,528
    80005d20:	8082                	ret
    end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	470080e7          	jalr	1136(ra) # 80005192 <end_op>
    return -1;
    80005d2a:	557d                	li	a0,-1
    80005d2c:	bfc9                	j	80005cfe <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005d2e:	854a                	mv	a0,s2
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	1ee080e7          	jalr	494(ra) # 80001f1e <proc_pagetable>
    80005d38:	8baa                	mv	s7,a0
    80005d3a:	d945                	beqz	a0,80005cea <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d3c:	e7042983          	lw	s3,-400(s0)
    80005d40:	e8845783          	lhu	a5,-376(s0)
    80005d44:	c7ad                	beqz	a5,80005dae <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005d46:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d48:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005d4a:	6c85                	lui	s9,0x1
    80005d4c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005d50:	def43823          	sd	a5,-528(s0)
    80005d54:	ac0d                	j	80005f86 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005d56:	00004517          	auipc	a0,0x4
    80005d5a:	c0a50513          	addi	a0,a0,-1014 # 80009960 <syscalls+0x2a0>
    80005d5e:	ffffa097          	auipc	ra,0xffffa
    80005d62:	7e6080e7          	jalr	2022(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005d66:	8756                	mv	a4,s5
    80005d68:	012d86bb          	addw	a3,s11,s2
    80005d6c:	4581                	li	a1,0
    80005d6e:	8526                	mv	a0,s1
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	c94080e7          	jalr	-876(ra) # 80004a04 <readi>
    80005d78:	2501                	sext.w	a0,a0
    80005d7a:	1aaa9a63          	bne	s5,a0,80005f2e <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005d7e:	6785                	lui	a5,0x1
    80005d80:	0127893b          	addw	s2,a5,s2
    80005d84:	77fd                	lui	a5,0xfffff
    80005d86:	01478a3b          	addw	s4,a5,s4
    80005d8a:	1f897563          	bgeu	s2,s8,80005f74 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005d8e:	02091593          	slli	a1,s2,0x20
    80005d92:	9181                	srli	a1,a1,0x20
    80005d94:	95ea                	add	a1,a1,s10
    80005d96:	855e                	mv	a0,s7
    80005d98:	ffffb097          	auipc	ra,0xffffb
    80005d9c:	5a2080e7          	jalr	1442(ra) # 8000133a <walkaddr>
    80005da0:	862a                	mv	a2,a0
    if(pa == 0)
    80005da2:	d955                	beqz	a0,80005d56 <exec+0xf0>
      n = PGSIZE;
    80005da4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005da6:	fd9a70e3          	bgeu	s4,s9,80005d66 <exec+0x100>
      n = sz - i;
    80005daa:	8ad2                	mv	s5,s4
    80005dac:	bf6d                	j	80005d66 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005dae:	4a01                	li	s4,0
  iunlockput(ip);
    80005db0:	8526                	mv	a0,s1
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	c00080e7          	jalr	-1024(ra) # 800049b2 <iunlockput>
  end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	3d8080e7          	jalr	984(ra) # 80005192 <end_op>
  p = myproc();
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	f5c080e7          	jalr	-164(ra) # 80001d1e <myproc>
    80005dca:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005dcc:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005dd0:	6785                	lui	a5,0x1
    80005dd2:	17fd                	addi	a5,a5,-1
    80005dd4:	9a3e                	add	s4,s4,a5
    80005dd6:	757d                	lui	a0,0xfffff
    80005dd8:	00aa77b3          	and	a5,s4,a0
    80005ddc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005de0:	4691                	li	a3,4
    80005de2:	6609                	lui	a2,0x2
    80005de4:	963e                	add	a2,a2,a5
    80005de6:	85be                	mv	a1,a5
    80005de8:	855e                	mv	a0,s7
    80005dea:	ffffc097          	auipc	ra,0xffffc
    80005dee:	904080e7          	jalr	-1788(ra) # 800016ee <uvmalloc>
    80005df2:	8b2a                	mv	s6,a0
  ip = 0;
    80005df4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005df6:	12050c63          	beqz	a0,80005f2e <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005dfa:	75f9                	lui	a1,0xffffe
    80005dfc:	95aa                	add	a1,a1,a0
    80005dfe:	855e                	mv	a0,s7
    80005e00:	ffffc097          	auipc	ra,0xffffc
    80005e04:	b18080e7          	jalr	-1256(ra) # 80001918 <uvmclear>
  stackbase = sp - PGSIZE;
    80005e08:	7c7d                	lui	s8,0xfffff
    80005e0a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005e0c:	e0043783          	ld	a5,-512(s0)
    80005e10:	6388                	ld	a0,0(a5)
    80005e12:	c535                	beqz	a0,80005e7e <exec+0x218>
    80005e14:	e9040993          	addi	s3,s0,-368
    80005e18:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005e1c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005e1e:	ffffb097          	auipc	ra,0xffffb
    80005e22:	30e080e7          	jalr	782(ra) # 8000112c <strlen>
    80005e26:	2505                	addiw	a0,a0,1
    80005e28:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005e2c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005e30:	13896663          	bltu	s2,s8,80005f5c <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005e34:	e0043d83          	ld	s11,-512(s0)
    80005e38:	000dba03          	ld	s4,0(s11)
    80005e3c:	8552                	mv	a0,s4
    80005e3e:	ffffb097          	auipc	ra,0xffffb
    80005e42:	2ee080e7          	jalr	750(ra) # 8000112c <strlen>
    80005e46:	0015069b          	addiw	a3,a0,1
    80005e4a:	8652                	mv	a2,s4
    80005e4c:	85ca                	mv	a1,s2
    80005e4e:	855e                	mv	a0,s7
    80005e50:	ffffc097          	auipc	ra,0xffffc
    80005e54:	afa080e7          	jalr	-1286(ra) # 8000194a <copyout>
    80005e58:	10054663          	bltz	a0,80005f64 <exec+0x2fe>
    ustack[argc] = sp;
    80005e5c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005e60:	0485                	addi	s1,s1,1
    80005e62:	008d8793          	addi	a5,s11,8
    80005e66:	e0f43023          	sd	a5,-512(s0)
    80005e6a:	008db503          	ld	a0,8(s11)
    80005e6e:	c911                	beqz	a0,80005e82 <exec+0x21c>
    if(argc >= MAXARG)
    80005e70:	09a1                	addi	s3,s3,8
    80005e72:	fb3c96e3          	bne	s9,s3,80005e1e <exec+0x1b8>
  sz = sz1;
    80005e76:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005e7a:	4481                	li	s1,0
    80005e7c:	a84d                	j	80005f2e <exec+0x2c8>
  sp = sz;
    80005e7e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005e80:	4481                	li	s1,0
  ustack[argc] = 0;
    80005e82:	00349793          	slli	a5,s1,0x3
    80005e86:	f9040713          	addi	a4,s0,-112
    80005e8a:	97ba                	add	a5,a5,a4
    80005e8c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005e90:	00148693          	addi	a3,s1,1
    80005e94:	068e                	slli	a3,a3,0x3
    80005e96:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005e9a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005e9e:	01897663          	bgeu	s2,s8,80005eaa <exec+0x244>
  sz = sz1;
    80005ea2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ea6:	4481                	li	s1,0
    80005ea8:	a059                	j	80005f2e <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005eaa:	e9040613          	addi	a2,s0,-368
    80005eae:	85ca                	mv	a1,s2
    80005eb0:	855e                	mv	a0,s7
    80005eb2:	ffffc097          	auipc	ra,0xffffc
    80005eb6:	a98080e7          	jalr	-1384(ra) # 8000194a <copyout>
    80005eba:	0a054963          	bltz	a0,80005f6c <exec+0x306>
  p->trapframe->a1 = sp;
    80005ebe:	060ab783          	ld	a5,96(s5)
    80005ec2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ec6:	df843783          	ld	a5,-520(s0)
    80005eca:	0007c703          	lbu	a4,0(a5)
    80005ece:	cf11                	beqz	a4,80005eea <exec+0x284>
    80005ed0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ed2:	02f00693          	li	a3,47
    80005ed6:	a039                	j	80005ee4 <exec+0x27e>
      last = s+1;
    80005ed8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005edc:	0785                	addi	a5,a5,1
    80005ede:	fff7c703          	lbu	a4,-1(a5)
    80005ee2:	c701                	beqz	a4,80005eea <exec+0x284>
    if(*s == '/')
    80005ee4:	fed71ce3          	bne	a4,a3,80005edc <exec+0x276>
    80005ee8:	bfc5                	j	80005ed8 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005eea:	4641                	li	a2,16
    80005eec:	df843583          	ld	a1,-520(s0)
    80005ef0:	160a8513          	addi	a0,s5,352
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	206080e7          	jalr	518(ra) # 800010fa <safestrcpy>
  oldpagetable = p->pagetable;
    80005efc:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005f00:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005f04:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005f08:	060ab783          	ld	a5,96(s5)
    80005f0c:	e6843703          	ld	a4,-408(s0)
    80005f10:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005f12:	060ab783          	ld	a5,96(s5)
    80005f16:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005f1a:	85ea                	mv	a1,s10
    80005f1c:	ffffc097          	auipc	ra,0xffffc
    80005f20:	09e080e7          	jalr	158(ra) # 80001fba <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005f24:	0004851b          	sext.w	a0,s1
    80005f28:	bbd9                	j	80005cfe <exec+0x98>
    80005f2a:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005f2e:	e0843583          	ld	a1,-504(s0)
    80005f32:	855e                	mv	a0,s7
    80005f34:	ffffc097          	auipc	ra,0xffffc
    80005f38:	086080e7          	jalr	134(ra) # 80001fba <proc_freepagetable>
  if(ip){
    80005f3c:	da0497e3          	bnez	s1,80005cea <exec+0x84>
  return -1;
    80005f40:	557d                	li	a0,-1
    80005f42:	bb75                	j	80005cfe <exec+0x98>
    80005f44:	e1443423          	sd	s4,-504(s0)
    80005f48:	b7dd                	j	80005f2e <exec+0x2c8>
    80005f4a:	e1443423          	sd	s4,-504(s0)
    80005f4e:	b7c5                	j	80005f2e <exec+0x2c8>
    80005f50:	e1443423          	sd	s4,-504(s0)
    80005f54:	bfe9                	j	80005f2e <exec+0x2c8>
    80005f56:	e1443423          	sd	s4,-504(s0)
    80005f5a:	bfd1                	j	80005f2e <exec+0x2c8>
  sz = sz1;
    80005f5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005f60:	4481                	li	s1,0
    80005f62:	b7f1                	j	80005f2e <exec+0x2c8>
  sz = sz1;
    80005f64:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005f68:	4481                	li	s1,0
    80005f6a:	b7d1                	j	80005f2e <exec+0x2c8>
  sz = sz1;
    80005f6c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005f70:	4481                	li	s1,0
    80005f72:	bf75                	j	80005f2e <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005f74:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005f78:	2b05                	addiw	s6,s6,1
    80005f7a:	0389899b          	addiw	s3,s3,56
    80005f7e:	e8845783          	lhu	a5,-376(s0)
    80005f82:	e2fb57e3          	bge	s6,a5,80005db0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005f86:	2981                	sext.w	s3,s3
    80005f88:	03800713          	li	a4,56
    80005f8c:	86ce                	mv	a3,s3
    80005f8e:	e1840613          	addi	a2,s0,-488
    80005f92:	4581                	li	a1,0
    80005f94:	8526                	mv	a0,s1
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	a6e080e7          	jalr	-1426(ra) # 80004a04 <readi>
    80005f9e:	03800793          	li	a5,56
    80005fa2:	f8f514e3          	bne	a0,a5,80005f2a <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005fa6:	e1842783          	lw	a5,-488(s0)
    80005faa:	4705                	li	a4,1
    80005fac:	fce796e3          	bne	a5,a4,80005f78 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005fb0:	e4043903          	ld	s2,-448(s0)
    80005fb4:	e3843783          	ld	a5,-456(s0)
    80005fb8:	f8f966e3          	bltu	s2,a5,80005f44 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005fbc:	e2843783          	ld	a5,-472(s0)
    80005fc0:	993e                	add	s2,s2,a5
    80005fc2:	f8f964e3          	bltu	s2,a5,80005f4a <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005fc6:	df043703          	ld	a4,-528(s0)
    80005fca:	8ff9                	and	a5,a5,a4
    80005fcc:	f3d1                	bnez	a5,80005f50 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005fce:	e1c42503          	lw	a0,-484(s0)
    80005fd2:	00000097          	auipc	ra,0x0
    80005fd6:	c78080e7          	jalr	-904(ra) # 80005c4a <flags2perm>
    80005fda:	86aa                	mv	a3,a0
    80005fdc:	864a                	mv	a2,s2
    80005fde:	85d2                	mv	a1,s4
    80005fe0:	855e                	mv	a0,s7
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	70c080e7          	jalr	1804(ra) # 800016ee <uvmalloc>
    80005fea:	e0a43423          	sd	a0,-504(s0)
    80005fee:	d525                	beqz	a0,80005f56 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005ff0:	e2843d03          	ld	s10,-472(s0)
    80005ff4:	e2042d83          	lw	s11,-480(s0)
    80005ff8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005ffc:	f60c0ce3          	beqz	s8,80005f74 <exec+0x30e>
    80006000:	8a62                	mv	s4,s8
    80006002:	4901                	li	s2,0
    80006004:	b369                	j	80005d8e <exec+0x128>

0000000080006006 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006006:	7179                	addi	sp,sp,-48
    80006008:	f406                	sd	ra,40(sp)
    8000600a:	f022                	sd	s0,32(sp)
    8000600c:	ec26                	sd	s1,24(sp)
    8000600e:	e84a                	sd	s2,16(sp)
    80006010:	1800                	addi	s0,sp,48
    80006012:	892e                	mv	s2,a1
    80006014:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80006016:	fdc40593          	addi	a1,s0,-36
    8000601a:	ffffd097          	auipc	ra,0xffffd
    8000601e:	79a080e7          	jalr	1946(ra) # 800037b4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006022:	fdc42703          	lw	a4,-36(s0)
    80006026:	47bd                	li	a5,15
    80006028:	02e7eb63          	bltu	a5,a4,8000605e <argfd+0x58>
    8000602c:	ffffc097          	auipc	ra,0xffffc
    80006030:	cf2080e7          	jalr	-782(ra) # 80001d1e <myproc>
    80006034:	fdc42703          	lw	a4,-36(s0)
    80006038:	01a70793          	addi	a5,a4,26
    8000603c:	078e                	slli	a5,a5,0x3
    8000603e:	953e                	add	a0,a0,a5
    80006040:	651c                	ld	a5,8(a0)
    80006042:	c385                	beqz	a5,80006062 <argfd+0x5c>
    return -1;
  if(pfd)
    80006044:	00090463          	beqz	s2,8000604c <argfd+0x46>
    *pfd = fd;
    80006048:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000604c:	4501                	li	a0,0
  if(pf)
    8000604e:	c091                	beqz	s1,80006052 <argfd+0x4c>
    *pf = f;
    80006050:	e09c                	sd	a5,0(s1)
}
    80006052:	70a2                	ld	ra,40(sp)
    80006054:	7402                	ld	s0,32(sp)
    80006056:	64e2                	ld	s1,24(sp)
    80006058:	6942                	ld	s2,16(sp)
    8000605a:	6145                	addi	sp,sp,48
    8000605c:	8082                	ret
    return -1;
    8000605e:	557d                	li	a0,-1
    80006060:	bfcd                	j	80006052 <argfd+0x4c>
    80006062:	557d                	li	a0,-1
    80006064:	b7fd                	j	80006052 <argfd+0x4c>

0000000080006066 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80006066:	1101                	addi	sp,sp,-32
    80006068:	ec06                	sd	ra,24(sp)
    8000606a:	e822                	sd	s0,16(sp)
    8000606c:	e426                	sd	s1,8(sp)
    8000606e:	1000                	addi	s0,sp,32
    80006070:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80006072:	ffffc097          	auipc	ra,0xffffc
    80006076:	cac080e7          	jalr	-852(ra) # 80001d1e <myproc>
    8000607a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000607c:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7fdb8cc0>
    80006080:	4501                	li	a0,0
    80006082:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80006084:	6398                	ld	a4,0(a5)
    80006086:	cb19                	beqz	a4,8000609c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80006088:	2505                	addiw	a0,a0,1
    8000608a:	07a1                	addi	a5,a5,8
    8000608c:	fed51ce3          	bne	a0,a3,80006084 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006090:	557d                	li	a0,-1
}
    80006092:	60e2                	ld	ra,24(sp)
    80006094:	6442                	ld	s0,16(sp)
    80006096:	64a2                	ld	s1,8(sp)
    80006098:	6105                	addi	sp,sp,32
    8000609a:	8082                	ret
      p->ofile[fd] = f;
    8000609c:	01a50793          	addi	a5,a0,26
    800060a0:	078e                	slli	a5,a5,0x3
    800060a2:	963e                	add	a2,a2,a5
    800060a4:	e604                	sd	s1,8(a2)
      return fd;
    800060a6:	b7f5                	j	80006092 <fdalloc+0x2c>

00000000800060a8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800060a8:	715d                	addi	sp,sp,-80
    800060aa:	e486                	sd	ra,72(sp)
    800060ac:	e0a2                	sd	s0,64(sp)
    800060ae:	fc26                	sd	s1,56(sp)
    800060b0:	f84a                	sd	s2,48(sp)
    800060b2:	f44e                	sd	s3,40(sp)
    800060b4:	f052                	sd	s4,32(sp)
    800060b6:	ec56                	sd	s5,24(sp)
    800060b8:	e85a                	sd	s6,16(sp)
    800060ba:	0880                	addi	s0,sp,80
    800060bc:	8b2e                	mv	s6,a1
    800060be:	89b2                	mv	s3,a2
    800060c0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800060c2:	fb040593          	addi	a1,s0,-80
    800060c6:	fffff097          	auipc	ra,0xfffff
    800060ca:	e4e080e7          	jalr	-434(ra) # 80004f14 <nameiparent>
    800060ce:	84aa                	mv	s1,a0
    800060d0:	16050063          	beqz	a0,80006230 <create+0x188>
    return 0;

  ilock(dp);
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	67c080e7          	jalr	1660(ra) # 80004750 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800060dc:	4601                	li	a2,0
    800060de:	fb040593          	addi	a1,s0,-80
    800060e2:	8526                	mv	a0,s1
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	b50080e7          	jalr	-1200(ra) # 80004c34 <dirlookup>
    800060ec:	8aaa                	mv	s5,a0
    800060ee:	c931                	beqz	a0,80006142 <create+0x9a>
    iunlockput(dp);
    800060f0:	8526                	mv	a0,s1
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	8c0080e7          	jalr	-1856(ra) # 800049b2 <iunlockput>
    ilock(ip);
    800060fa:	8556                	mv	a0,s5
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	654080e7          	jalr	1620(ra) # 80004750 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006104:	000b059b          	sext.w	a1,s6
    80006108:	4789                	li	a5,2
    8000610a:	02f59563          	bne	a1,a5,80006134 <create+0x8c>
    8000610e:	044ad783          	lhu	a5,68(s5)
    80006112:	37f9                	addiw	a5,a5,-2
    80006114:	17c2                	slli	a5,a5,0x30
    80006116:	93c1                	srli	a5,a5,0x30
    80006118:	4705                	li	a4,1
    8000611a:	00f76d63          	bltu	a4,a5,80006134 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000611e:	8556                	mv	a0,s5
    80006120:	60a6                	ld	ra,72(sp)
    80006122:	6406                	ld	s0,64(sp)
    80006124:	74e2                	ld	s1,56(sp)
    80006126:	7942                	ld	s2,48(sp)
    80006128:	79a2                	ld	s3,40(sp)
    8000612a:	7a02                	ld	s4,32(sp)
    8000612c:	6ae2                	ld	s5,24(sp)
    8000612e:	6b42                	ld	s6,16(sp)
    80006130:	6161                	addi	sp,sp,80
    80006132:	8082                	ret
    iunlockput(ip);
    80006134:	8556                	mv	a0,s5
    80006136:	fffff097          	auipc	ra,0xfffff
    8000613a:	87c080e7          	jalr	-1924(ra) # 800049b2 <iunlockput>
    return 0;
    8000613e:	4a81                	li	s5,0
    80006140:	bff9                	j	8000611e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80006142:	85da                	mv	a1,s6
    80006144:	4088                	lw	a0,0(s1)
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	46e080e7          	jalr	1134(ra) # 800045b4 <ialloc>
    8000614e:	8a2a                	mv	s4,a0
    80006150:	c921                	beqz	a0,800061a0 <create+0xf8>
  ilock(ip);
    80006152:	ffffe097          	auipc	ra,0xffffe
    80006156:	5fe080e7          	jalr	1534(ra) # 80004750 <ilock>
  ip->major = major;
    8000615a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000615e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80006162:	4785                	li	a5,1
    80006164:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80006168:	8552                	mv	a0,s4
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	51c080e7          	jalr	1308(ra) # 80004686 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006172:	000b059b          	sext.w	a1,s6
    80006176:	4785                	li	a5,1
    80006178:	02f58b63          	beq	a1,a5,800061ae <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    8000617c:	004a2603          	lw	a2,4(s4)
    80006180:	fb040593          	addi	a1,s0,-80
    80006184:	8526                	mv	a0,s1
    80006186:	fffff097          	auipc	ra,0xfffff
    8000618a:	cbe080e7          	jalr	-834(ra) # 80004e44 <dirlink>
    8000618e:	06054f63          	bltz	a0,8000620c <create+0x164>
  iunlockput(dp);
    80006192:	8526                	mv	a0,s1
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	81e080e7          	jalr	-2018(ra) # 800049b2 <iunlockput>
  return ip;
    8000619c:	8ad2                	mv	s5,s4
    8000619e:	b741                	j	8000611e <create+0x76>
    iunlockput(dp);
    800061a0:	8526                	mv	a0,s1
    800061a2:	fffff097          	auipc	ra,0xfffff
    800061a6:	810080e7          	jalr	-2032(ra) # 800049b2 <iunlockput>
    return 0;
    800061aa:	8ad2                	mv	s5,s4
    800061ac:	bf8d                	j	8000611e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800061ae:	004a2603          	lw	a2,4(s4)
    800061b2:	00003597          	auipc	a1,0x3
    800061b6:	7ce58593          	addi	a1,a1,1998 # 80009980 <syscalls+0x2c0>
    800061ba:	8552                	mv	a0,s4
    800061bc:	fffff097          	auipc	ra,0xfffff
    800061c0:	c88080e7          	jalr	-888(ra) # 80004e44 <dirlink>
    800061c4:	04054463          	bltz	a0,8000620c <create+0x164>
    800061c8:	40d0                	lw	a2,4(s1)
    800061ca:	00003597          	auipc	a1,0x3
    800061ce:	7be58593          	addi	a1,a1,1982 # 80009988 <syscalls+0x2c8>
    800061d2:	8552                	mv	a0,s4
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	c70080e7          	jalr	-912(ra) # 80004e44 <dirlink>
    800061dc:	02054863          	bltz	a0,8000620c <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800061e0:	004a2603          	lw	a2,4(s4)
    800061e4:	fb040593          	addi	a1,s0,-80
    800061e8:	8526                	mv	a0,s1
    800061ea:	fffff097          	auipc	ra,0xfffff
    800061ee:	c5a080e7          	jalr	-934(ra) # 80004e44 <dirlink>
    800061f2:	00054d63          	bltz	a0,8000620c <create+0x164>
    dp->nlink++;  // for ".."
    800061f6:	04a4d783          	lhu	a5,74(s1)
    800061fa:	2785                	addiw	a5,a5,1
    800061fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006200:	8526                	mv	a0,s1
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	484080e7          	jalr	1156(ra) # 80004686 <iupdate>
    8000620a:	b761                	j	80006192 <create+0xea>
  ip->nlink = 0;
    8000620c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80006210:	8552                	mv	a0,s4
    80006212:	ffffe097          	auipc	ra,0xffffe
    80006216:	474080e7          	jalr	1140(ra) # 80004686 <iupdate>
  iunlockput(ip);
    8000621a:	8552                	mv	a0,s4
    8000621c:	ffffe097          	auipc	ra,0xffffe
    80006220:	796080e7          	jalr	1942(ra) # 800049b2 <iunlockput>
  iunlockput(dp);
    80006224:	8526                	mv	a0,s1
    80006226:	ffffe097          	auipc	ra,0xffffe
    8000622a:	78c080e7          	jalr	1932(ra) # 800049b2 <iunlockput>
  return 0;
    8000622e:	bdc5                	j	8000611e <create+0x76>
    return 0;
    80006230:	8aaa                	mv	s5,a0
    80006232:	b5f5                	j	8000611e <create+0x76>

0000000080006234 <sys_dup>:
{
    80006234:	7179                	addi	sp,sp,-48
    80006236:	f406                	sd	ra,40(sp)
    80006238:	f022                	sd	s0,32(sp)
    8000623a:	ec26                	sd	s1,24(sp)
    8000623c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000623e:	fd840613          	addi	a2,s0,-40
    80006242:	4581                	li	a1,0
    80006244:	4501                	li	a0,0
    80006246:	00000097          	auipc	ra,0x0
    8000624a:	dc0080e7          	jalr	-576(ra) # 80006006 <argfd>
    return -1;
    8000624e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80006250:	02054363          	bltz	a0,80006276 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80006254:	fd843503          	ld	a0,-40(s0)
    80006258:	00000097          	auipc	ra,0x0
    8000625c:	e0e080e7          	jalr	-498(ra) # 80006066 <fdalloc>
    80006260:	84aa                	mv	s1,a0
    return -1;
    80006262:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80006264:	00054963          	bltz	a0,80006276 <sys_dup+0x42>
  filedup(f);
    80006268:	fd843503          	ld	a0,-40(s0)
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	320080e7          	jalr	800(ra) # 8000558c <filedup>
  return fd;
    80006274:	87a6                	mv	a5,s1
}
    80006276:	853e                	mv	a0,a5
    80006278:	70a2                	ld	ra,40(sp)
    8000627a:	7402                	ld	s0,32(sp)
    8000627c:	64e2                	ld	s1,24(sp)
    8000627e:	6145                	addi	sp,sp,48
    80006280:	8082                	ret

0000000080006282 <sys_read>:
{
    80006282:	7179                	addi	sp,sp,-48
    80006284:	f406                	sd	ra,40(sp)
    80006286:	f022                	sd	s0,32(sp)
    80006288:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000628a:	fd840593          	addi	a1,s0,-40
    8000628e:	4505                	li	a0,1
    80006290:	ffffd097          	auipc	ra,0xffffd
    80006294:	544080e7          	jalr	1348(ra) # 800037d4 <argaddr>
  argint(2, &n);
    80006298:	fe440593          	addi	a1,s0,-28
    8000629c:	4509                	li	a0,2
    8000629e:	ffffd097          	auipc	ra,0xffffd
    800062a2:	516080e7          	jalr	1302(ra) # 800037b4 <argint>
  if(argfd(0, 0, &f) < 0)
    800062a6:	fe840613          	addi	a2,s0,-24
    800062aa:	4581                	li	a1,0
    800062ac:	4501                	li	a0,0
    800062ae:	00000097          	auipc	ra,0x0
    800062b2:	d58080e7          	jalr	-680(ra) # 80006006 <argfd>
    800062b6:	87aa                	mv	a5,a0
    return -1;
    800062b8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800062ba:	0007cc63          	bltz	a5,800062d2 <sys_read+0x50>
  return fileread(f, p, n);
    800062be:	fe442603          	lw	a2,-28(s0)
    800062c2:	fd843583          	ld	a1,-40(s0)
    800062c6:	fe843503          	ld	a0,-24(s0)
    800062ca:	fffff097          	auipc	ra,0xfffff
    800062ce:	44e080e7          	jalr	1102(ra) # 80005718 <fileread>
}
    800062d2:	70a2                	ld	ra,40(sp)
    800062d4:	7402                	ld	s0,32(sp)
    800062d6:	6145                	addi	sp,sp,48
    800062d8:	8082                	ret

00000000800062da <sys_write>:
{
    800062da:	7179                	addi	sp,sp,-48
    800062dc:	f406                	sd	ra,40(sp)
    800062de:	f022                	sd	s0,32(sp)
    800062e0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800062e2:	fd840593          	addi	a1,s0,-40
    800062e6:	4505                	li	a0,1
    800062e8:	ffffd097          	auipc	ra,0xffffd
    800062ec:	4ec080e7          	jalr	1260(ra) # 800037d4 <argaddr>
  argint(2, &n);
    800062f0:	fe440593          	addi	a1,s0,-28
    800062f4:	4509                	li	a0,2
    800062f6:	ffffd097          	auipc	ra,0xffffd
    800062fa:	4be080e7          	jalr	1214(ra) # 800037b4 <argint>
  if(argfd(0, 0, &f) < 0)
    800062fe:	fe840613          	addi	a2,s0,-24
    80006302:	4581                	li	a1,0
    80006304:	4501                	li	a0,0
    80006306:	00000097          	auipc	ra,0x0
    8000630a:	d00080e7          	jalr	-768(ra) # 80006006 <argfd>
    8000630e:	87aa                	mv	a5,a0
    return -1;
    80006310:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80006312:	0007cc63          	bltz	a5,8000632a <sys_write+0x50>
  return filewrite(f, p, n);
    80006316:	fe442603          	lw	a2,-28(s0)
    8000631a:	fd843583          	ld	a1,-40(s0)
    8000631e:	fe843503          	ld	a0,-24(s0)
    80006322:	fffff097          	auipc	ra,0xfffff
    80006326:	4b8080e7          	jalr	1208(ra) # 800057da <filewrite>
}
    8000632a:	70a2                	ld	ra,40(sp)
    8000632c:	7402                	ld	s0,32(sp)
    8000632e:	6145                	addi	sp,sp,48
    80006330:	8082                	ret

0000000080006332 <sys_close>:
{
    80006332:	1101                	addi	sp,sp,-32
    80006334:	ec06                	sd	ra,24(sp)
    80006336:	e822                	sd	s0,16(sp)
    80006338:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000633a:	fe040613          	addi	a2,s0,-32
    8000633e:	fec40593          	addi	a1,s0,-20
    80006342:	4501                	li	a0,0
    80006344:	00000097          	auipc	ra,0x0
    80006348:	cc2080e7          	jalr	-830(ra) # 80006006 <argfd>
    return -1;
    8000634c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000634e:	02054463          	bltz	a0,80006376 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	9cc080e7          	jalr	-1588(ra) # 80001d1e <myproc>
    8000635a:	fec42783          	lw	a5,-20(s0)
    8000635e:	07e9                	addi	a5,a5,26
    80006360:	078e                	slli	a5,a5,0x3
    80006362:	97aa                	add	a5,a5,a0
    80006364:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80006368:	fe043503          	ld	a0,-32(s0)
    8000636c:	fffff097          	auipc	ra,0xfffff
    80006370:	272080e7          	jalr	626(ra) # 800055de <fileclose>
  return 0;
    80006374:	4781                	li	a5,0
}
    80006376:	853e                	mv	a0,a5
    80006378:	60e2                	ld	ra,24(sp)
    8000637a:	6442                	ld	s0,16(sp)
    8000637c:	6105                	addi	sp,sp,32
    8000637e:	8082                	ret

0000000080006380 <sys_fstat>:
{
    80006380:	1101                	addi	sp,sp,-32
    80006382:	ec06                	sd	ra,24(sp)
    80006384:	e822                	sd	s0,16(sp)
    80006386:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80006388:	fe040593          	addi	a1,s0,-32
    8000638c:	4505                	li	a0,1
    8000638e:	ffffd097          	auipc	ra,0xffffd
    80006392:	446080e7          	jalr	1094(ra) # 800037d4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80006396:	fe840613          	addi	a2,s0,-24
    8000639a:	4581                	li	a1,0
    8000639c:	4501                	li	a0,0
    8000639e:	00000097          	auipc	ra,0x0
    800063a2:	c68080e7          	jalr	-920(ra) # 80006006 <argfd>
    800063a6:	87aa                	mv	a5,a0
    return -1;
    800063a8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800063aa:	0007ca63          	bltz	a5,800063be <sys_fstat+0x3e>
  return filestat(f, st);
    800063ae:	fe043583          	ld	a1,-32(s0)
    800063b2:	fe843503          	ld	a0,-24(s0)
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	2f0080e7          	jalr	752(ra) # 800056a6 <filestat>
}
    800063be:	60e2                	ld	ra,24(sp)
    800063c0:	6442                	ld	s0,16(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret

00000000800063c6 <sys_link>:
{
    800063c6:	7169                	addi	sp,sp,-304
    800063c8:	f606                	sd	ra,296(sp)
    800063ca:	f222                	sd	s0,288(sp)
    800063cc:	ee26                	sd	s1,280(sp)
    800063ce:	ea4a                	sd	s2,272(sp)
    800063d0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800063d2:	08000613          	li	a2,128
    800063d6:	ed040593          	addi	a1,s0,-304
    800063da:	4501                	li	a0,0
    800063dc:	ffffd097          	auipc	ra,0xffffd
    800063e0:	418080e7          	jalr	1048(ra) # 800037f4 <argstr>
    return -1;
    800063e4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800063e6:	10054e63          	bltz	a0,80006502 <sys_link+0x13c>
    800063ea:	08000613          	li	a2,128
    800063ee:	f5040593          	addi	a1,s0,-176
    800063f2:	4505                	li	a0,1
    800063f4:	ffffd097          	auipc	ra,0xffffd
    800063f8:	400080e7          	jalr	1024(ra) # 800037f4 <argstr>
    return -1;
    800063fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800063fe:	10054263          	bltz	a0,80006502 <sys_link+0x13c>
  begin_op();
    80006402:	fffff097          	auipc	ra,0xfffff
    80006406:	d10080e7          	jalr	-752(ra) # 80005112 <begin_op>
  if((ip = namei(old)) == 0){
    8000640a:	ed040513          	addi	a0,s0,-304
    8000640e:	fffff097          	auipc	ra,0xfffff
    80006412:	ae8080e7          	jalr	-1304(ra) # 80004ef6 <namei>
    80006416:	84aa                	mv	s1,a0
    80006418:	c551                	beqz	a0,800064a4 <sys_link+0xde>
  ilock(ip);
    8000641a:	ffffe097          	auipc	ra,0xffffe
    8000641e:	336080e7          	jalr	822(ra) # 80004750 <ilock>
  if(ip->type == T_DIR){
    80006422:	04449703          	lh	a4,68(s1)
    80006426:	4785                	li	a5,1
    80006428:	08f70463          	beq	a4,a5,800064b0 <sys_link+0xea>
  ip->nlink++;
    8000642c:	04a4d783          	lhu	a5,74(s1)
    80006430:	2785                	addiw	a5,a5,1
    80006432:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006436:	8526                	mv	a0,s1
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	24e080e7          	jalr	590(ra) # 80004686 <iupdate>
  iunlock(ip);
    80006440:	8526                	mv	a0,s1
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	3d0080e7          	jalr	976(ra) # 80004812 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000644a:	fd040593          	addi	a1,s0,-48
    8000644e:	f5040513          	addi	a0,s0,-176
    80006452:	fffff097          	auipc	ra,0xfffff
    80006456:	ac2080e7          	jalr	-1342(ra) # 80004f14 <nameiparent>
    8000645a:	892a                	mv	s2,a0
    8000645c:	c935                	beqz	a0,800064d0 <sys_link+0x10a>
  ilock(dp);
    8000645e:	ffffe097          	auipc	ra,0xffffe
    80006462:	2f2080e7          	jalr	754(ra) # 80004750 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006466:	00092703          	lw	a4,0(s2)
    8000646a:	409c                	lw	a5,0(s1)
    8000646c:	04f71d63          	bne	a4,a5,800064c6 <sys_link+0x100>
    80006470:	40d0                	lw	a2,4(s1)
    80006472:	fd040593          	addi	a1,s0,-48
    80006476:	854a                	mv	a0,s2
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	9cc080e7          	jalr	-1588(ra) # 80004e44 <dirlink>
    80006480:	04054363          	bltz	a0,800064c6 <sys_link+0x100>
  iunlockput(dp);
    80006484:	854a                	mv	a0,s2
    80006486:	ffffe097          	auipc	ra,0xffffe
    8000648a:	52c080e7          	jalr	1324(ra) # 800049b2 <iunlockput>
  iput(ip);
    8000648e:	8526                	mv	a0,s1
    80006490:	ffffe097          	auipc	ra,0xffffe
    80006494:	47a080e7          	jalr	1146(ra) # 8000490a <iput>
  end_op();
    80006498:	fffff097          	auipc	ra,0xfffff
    8000649c:	cfa080e7          	jalr	-774(ra) # 80005192 <end_op>
  return 0;
    800064a0:	4781                	li	a5,0
    800064a2:	a085                	j	80006502 <sys_link+0x13c>
    end_op();
    800064a4:	fffff097          	auipc	ra,0xfffff
    800064a8:	cee080e7          	jalr	-786(ra) # 80005192 <end_op>
    return -1;
    800064ac:	57fd                	li	a5,-1
    800064ae:	a891                	j	80006502 <sys_link+0x13c>
    iunlockput(ip);
    800064b0:	8526                	mv	a0,s1
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	500080e7          	jalr	1280(ra) # 800049b2 <iunlockput>
    end_op();
    800064ba:	fffff097          	auipc	ra,0xfffff
    800064be:	cd8080e7          	jalr	-808(ra) # 80005192 <end_op>
    return -1;
    800064c2:	57fd                	li	a5,-1
    800064c4:	a83d                	j	80006502 <sys_link+0x13c>
    iunlockput(dp);
    800064c6:	854a                	mv	a0,s2
    800064c8:	ffffe097          	auipc	ra,0xffffe
    800064cc:	4ea080e7          	jalr	1258(ra) # 800049b2 <iunlockput>
  ilock(ip);
    800064d0:	8526                	mv	a0,s1
    800064d2:	ffffe097          	auipc	ra,0xffffe
    800064d6:	27e080e7          	jalr	638(ra) # 80004750 <ilock>
  ip->nlink--;
    800064da:	04a4d783          	lhu	a5,74(s1)
    800064de:	37fd                	addiw	a5,a5,-1
    800064e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800064e4:	8526                	mv	a0,s1
    800064e6:	ffffe097          	auipc	ra,0xffffe
    800064ea:	1a0080e7          	jalr	416(ra) # 80004686 <iupdate>
  iunlockput(ip);
    800064ee:	8526                	mv	a0,s1
    800064f0:	ffffe097          	auipc	ra,0xffffe
    800064f4:	4c2080e7          	jalr	1218(ra) # 800049b2 <iunlockput>
  end_op();
    800064f8:	fffff097          	auipc	ra,0xfffff
    800064fc:	c9a080e7          	jalr	-870(ra) # 80005192 <end_op>
  return -1;
    80006500:	57fd                	li	a5,-1
}
    80006502:	853e                	mv	a0,a5
    80006504:	70b2                	ld	ra,296(sp)
    80006506:	7412                	ld	s0,288(sp)
    80006508:	64f2                	ld	s1,280(sp)
    8000650a:	6952                	ld	s2,272(sp)
    8000650c:	6155                	addi	sp,sp,304
    8000650e:	8082                	ret

0000000080006510 <sys_unlink>:
{
    80006510:	7151                	addi	sp,sp,-240
    80006512:	f586                	sd	ra,232(sp)
    80006514:	f1a2                	sd	s0,224(sp)
    80006516:	eda6                	sd	s1,216(sp)
    80006518:	e9ca                	sd	s2,208(sp)
    8000651a:	e5ce                	sd	s3,200(sp)
    8000651c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000651e:	08000613          	li	a2,128
    80006522:	f3040593          	addi	a1,s0,-208
    80006526:	4501                	li	a0,0
    80006528:	ffffd097          	auipc	ra,0xffffd
    8000652c:	2cc080e7          	jalr	716(ra) # 800037f4 <argstr>
    80006530:	18054163          	bltz	a0,800066b2 <sys_unlink+0x1a2>
  begin_op();
    80006534:	fffff097          	auipc	ra,0xfffff
    80006538:	bde080e7          	jalr	-1058(ra) # 80005112 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000653c:	fb040593          	addi	a1,s0,-80
    80006540:	f3040513          	addi	a0,s0,-208
    80006544:	fffff097          	auipc	ra,0xfffff
    80006548:	9d0080e7          	jalr	-1584(ra) # 80004f14 <nameiparent>
    8000654c:	84aa                	mv	s1,a0
    8000654e:	c979                	beqz	a0,80006624 <sys_unlink+0x114>
  ilock(dp);
    80006550:	ffffe097          	auipc	ra,0xffffe
    80006554:	200080e7          	jalr	512(ra) # 80004750 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006558:	00003597          	auipc	a1,0x3
    8000655c:	42858593          	addi	a1,a1,1064 # 80009980 <syscalls+0x2c0>
    80006560:	fb040513          	addi	a0,s0,-80
    80006564:	ffffe097          	auipc	ra,0xffffe
    80006568:	6b6080e7          	jalr	1718(ra) # 80004c1a <namecmp>
    8000656c:	14050a63          	beqz	a0,800066c0 <sys_unlink+0x1b0>
    80006570:	00003597          	auipc	a1,0x3
    80006574:	41858593          	addi	a1,a1,1048 # 80009988 <syscalls+0x2c8>
    80006578:	fb040513          	addi	a0,s0,-80
    8000657c:	ffffe097          	auipc	ra,0xffffe
    80006580:	69e080e7          	jalr	1694(ra) # 80004c1a <namecmp>
    80006584:	12050e63          	beqz	a0,800066c0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006588:	f2c40613          	addi	a2,s0,-212
    8000658c:	fb040593          	addi	a1,s0,-80
    80006590:	8526                	mv	a0,s1
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	6a2080e7          	jalr	1698(ra) # 80004c34 <dirlookup>
    8000659a:	892a                	mv	s2,a0
    8000659c:	12050263          	beqz	a0,800066c0 <sys_unlink+0x1b0>
  ilock(ip);
    800065a0:	ffffe097          	auipc	ra,0xffffe
    800065a4:	1b0080e7          	jalr	432(ra) # 80004750 <ilock>
  if(ip->nlink < 1)
    800065a8:	04a91783          	lh	a5,74(s2)
    800065ac:	08f05263          	blez	a5,80006630 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800065b0:	04491703          	lh	a4,68(s2)
    800065b4:	4785                	li	a5,1
    800065b6:	08f70563          	beq	a4,a5,80006640 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800065ba:	4641                	li	a2,16
    800065bc:	4581                	li	a1,0
    800065be:	fc040513          	addi	a0,s0,-64
    800065c2:	ffffb097          	auipc	ra,0xffffb
    800065c6:	9e6080e7          	jalr	-1562(ra) # 80000fa8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800065ca:	4741                	li	a4,16
    800065cc:	f2c42683          	lw	a3,-212(s0)
    800065d0:	fc040613          	addi	a2,s0,-64
    800065d4:	4581                	li	a1,0
    800065d6:	8526                	mv	a0,s1
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	524080e7          	jalr	1316(ra) # 80004afc <writei>
    800065e0:	47c1                	li	a5,16
    800065e2:	0af51563          	bne	a0,a5,8000668c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800065e6:	04491703          	lh	a4,68(s2)
    800065ea:	4785                	li	a5,1
    800065ec:	0af70863          	beq	a4,a5,8000669c <sys_unlink+0x18c>
  iunlockput(dp);
    800065f0:	8526                	mv	a0,s1
    800065f2:	ffffe097          	auipc	ra,0xffffe
    800065f6:	3c0080e7          	jalr	960(ra) # 800049b2 <iunlockput>
  ip->nlink--;
    800065fa:	04a95783          	lhu	a5,74(s2)
    800065fe:	37fd                	addiw	a5,a5,-1
    80006600:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006604:	854a                	mv	a0,s2
    80006606:	ffffe097          	auipc	ra,0xffffe
    8000660a:	080080e7          	jalr	128(ra) # 80004686 <iupdate>
  iunlockput(ip);
    8000660e:	854a                	mv	a0,s2
    80006610:	ffffe097          	auipc	ra,0xffffe
    80006614:	3a2080e7          	jalr	930(ra) # 800049b2 <iunlockput>
  end_op();
    80006618:	fffff097          	auipc	ra,0xfffff
    8000661c:	b7a080e7          	jalr	-1158(ra) # 80005192 <end_op>
  return 0;
    80006620:	4501                	li	a0,0
    80006622:	a84d                	j	800066d4 <sys_unlink+0x1c4>
    end_op();
    80006624:	fffff097          	auipc	ra,0xfffff
    80006628:	b6e080e7          	jalr	-1170(ra) # 80005192 <end_op>
    return -1;
    8000662c:	557d                	li	a0,-1
    8000662e:	a05d                	j	800066d4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006630:	00003517          	auipc	a0,0x3
    80006634:	36050513          	addi	a0,a0,864 # 80009990 <syscalls+0x2d0>
    80006638:	ffffa097          	auipc	ra,0xffffa
    8000663c:	f0c080e7          	jalr	-244(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006640:	04c92703          	lw	a4,76(s2)
    80006644:	02000793          	li	a5,32
    80006648:	f6e7f9e3          	bgeu	a5,a4,800065ba <sys_unlink+0xaa>
    8000664c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006650:	4741                	li	a4,16
    80006652:	86ce                	mv	a3,s3
    80006654:	f1840613          	addi	a2,s0,-232
    80006658:	4581                	li	a1,0
    8000665a:	854a                	mv	a0,s2
    8000665c:	ffffe097          	auipc	ra,0xffffe
    80006660:	3a8080e7          	jalr	936(ra) # 80004a04 <readi>
    80006664:	47c1                	li	a5,16
    80006666:	00f51b63          	bne	a0,a5,8000667c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000666a:	f1845783          	lhu	a5,-232(s0)
    8000666e:	e7a1                	bnez	a5,800066b6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006670:	29c1                	addiw	s3,s3,16
    80006672:	04c92783          	lw	a5,76(s2)
    80006676:	fcf9ede3          	bltu	s3,a5,80006650 <sys_unlink+0x140>
    8000667a:	b781                	j	800065ba <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000667c:	00003517          	auipc	a0,0x3
    80006680:	32c50513          	addi	a0,a0,812 # 800099a8 <syscalls+0x2e8>
    80006684:	ffffa097          	auipc	ra,0xffffa
    80006688:	ec0080e7          	jalr	-320(ra) # 80000544 <panic>
    panic("unlink: writei");
    8000668c:	00003517          	auipc	a0,0x3
    80006690:	33450513          	addi	a0,a0,820 # 800099c0 <syscalls+0x300>
    80006694:	ffffa097          	auipc	ra,0xffffa
    80006698:	eb0080e7          	jalr	-336(ra) # 80000544 <panic>
    dp->nlink--;
    8000669c:	04a4d783          	lhu	a5,74(s1)
    800066a0:	37fd                	addiw	a5,a5,-1
    800066a2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800066a6:	8526                	mv	a0,s1
    800066a8:	ffffe097          	auipc	ra,0xffffe
    800066ac:	fde080e7          	jalr	-34(ra) # 80004686 <iupdate>
    800066b0:	b781                	j	800065f0 <sys_unlink+0xe0>
    return -1;
    800066b2:	557d                	li	a0,-1
    800066b4:	a005                	j	800066d4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800066b6:	854a                	mv	a0,s2
    800066b8:	ffffe097          	auipc	ra,0xffffe
    800066bc:	2fa080e7          	jalr	762(ra) # 800049b2 <iunlockput>
  iunlockput(dp);
    800066c0:	8526                	mv	a0,s1
    800066c2:	ffffe097          	auipc	ra,0xffffe
    800066c6:	2f0080e7          	jalr	752(ra) # 800049b2 <iunlockput>
  end_op();
    800066ca:	fffff097          	auipc	ra,0xfffff
    800066ce:	ac8080e7          	jalr	-1336(ra) # 80005192 <end_op>
  return -1;
    800066d2:	557d                	li	a0,-1
}
    800066d4:	70ae                	ld	ra,232(sp)
    800066d6:	740e                	ld	s0,224(sp)
    800066d8:	64ee                	ld	s1,216(sp)
    800066da:	694e                	ld	s2,208(sp)
    800066dc:	69ae                	ld	s3,200(sp)
    800066de:	616d                	addi	sp,sp,240
    800066e0:	8082                	ret

00000000800066e2 <sys_open>:

uint64
sys_open(void)
{
    800066e2:	7131                	addi	sp,sp,-192
    800066e4:	fd06                	sd	ra,184(sp)
    800066e6:	f922                	sd	s0,176(sp)
    800066e8:	f526                	sd	s1,168(sp)
    800066ea:	f14a                	sd	s2,160(sp)
    800066ec:	ed4e                	sd	s3,152(sp)
    800066ee:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800066f0:	f4c40593          	addi	a1,s0,-180
    800066f4:	4505                	li	a0,1
    800066f6:	ffffd097          	auipc	ra,0xffffd
    800066fa:	0be080e7          	jalr	190(ra) # 800037b4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800066fe:	08000613          	li	a2,128
    80006702:	f5040593          	addi	a1,s0,-176
    80006706:	4501                	li	a0,0
    80006708:	ffffd097          	auipc	ra,0xffffd
    8000670c:	0ec080e7          	jalr	236(ra) # 800037f4 <argstr>
    80006710:	87aa                	mv	a5,a0
    return -1;
    80006712:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006714:	0a07c963          	bltz	a5,800067c6 <sys_open+0xe4>

  begin_op();
    80006718:	fffff097          	auipc	ra,0xfffff
    8000671c:	9fa080e7          	jalr	-1542(ra) # 80005112 <begin_op>

  if(omode & O_CREATE){
    80006720:	f4c42783          	lw	a5,-180(s0)
    80006724:	2007f793          	andi	a5,a5,512
    80006728:	cfc5                	beqz	a5,800067e0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000672a:	4681                	li	a3,0
    8000672c:	4601                	li	a2,0
    8000672e:	4589                	li	a1,2
    80006730:	f5040513          	addi	a0,s0,-176
    80006734:	00000097          	auipc	ra,0x0
    80006738:	974080e7          	jalr	-1676(ra) # 800060a8 <create>
    8000673c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000673e:	c959                	beqz	a0,800067d4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006740:	04449703          	lh	a4,68(s1)
    80006744:	478d                	li	a5,3
    80006746:	00f71763          	bne	a4,a5,80006754 <sys_open+0x72>
    8000674a:	0464d703          	lhu	a4,70(s1)
    8000674e:	47a5                	li	a5,9
    80006750:	0ce7ed63          	bltu	a5,a4,8000682a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006754:	fffff097          	auipc	ra,0xfffff
    80006758:	dce080e7          	jalr	-562(ra) # 80005522 <filealloc>
    8000675c:	89aa                	mv	s3,a0
    8000675e:	10050363          	beqz	a0,80006864 <sys_open+0x182>
    80006762:	00000097          	auipc	ra,0x0
    80006766:	904080e7          	jalr	-1788(ra) # 80006066 <fdalloc>
    8000676a:	892a                	mv	s2,a0
    8000676c:	0e054763          	bltz	a0,8000685a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006770:	04449703          	lh	a4,68(s1)
    80006774:	478d                	li	a5,3
    80006776:	0cf70563          	beq	a4,a5,80006840 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000677a:	4789                	li	a5,2
    8000677c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006780:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006784:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006788:	f4c42783          	lw	a5,-180(s0)
    8000678c:	0017c713          	xori	a4,a5,1
    80006790:	8b05                	andi	a4,a4,1
    80006792:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006796:	0037f713          	andi	a4,a5,3
    8000679a:	00e03733          	snez	a4,a4
    8000679e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800067a2:	4007f793          	andi	a5,a5,1024
    800067a6:	c791                	beqz	a5,800067b2 <sys_open+0xd0>
    800067a8:	04449703          	lh	a4,68(s1)
    800067ac:	4789                	li	a5,2
    800067ae:	0af70063          	beq	a4,a5,8000684e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800067b2:	8526                	mv	a0,s1
    800067b4:	ffffe097          	auipc	ra,0xffffe
    800067b8:	05e080e7          	jalr	94(ra) # 80004812 <iunlock>
  end_op();
    800067bc:	fffff097          	auipc	ra,0xfffff
    800067c0:	9d6080e7          	jalr	-1578(ra) # 80005192 <end_op>

  return fd;
    800067c4:	854a                	mv	a0,s2
}
    800067c6:	70ea                	ld	ra,184(sp)
    800067c8:	744a                	ld	s0,176(sp)
    800067ca:	74aa                	ld	s1,168(sp)
    800067cc:	790a                	ld	s2,160(sp)
    800067ce:	69ea                	ld	s3,152(sp)
    800067d0:	6129                	addi	sp,sp,192
    800067d2:	8082                	ret
      end_op();
    800067d4:	fffff097          	auipc	ra,0xfffff
    800067d8:	9be080e7          	jalr	-1602(ra) # 80005192 <end_op>
      return -1;
    800067dc:	557d                	li	a0,-1
    800067de:	b7e5                	j	800067c6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800067e0:	f5040513          	addi	a0,s0,-176
    800067e4:	ffffe097          	auipc	ra,0xffffe
    800067e8:	712080e7          	jalr	1810(ra) # 80004ef6 <namei>
    800067ec:	84aa                	mv	s1,a0
    800067ee:	c905                	beqz	a0,8000681e <sys_open+0x13c>
    ilock(ip);
    800067f0:	ffffe097          	auipc	ra,0xffffe
    800067f4:	f60080e7          	jalr	-160(ra) # 80004750 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800067f8:	04449703          	lh	a4,68(s1)
    800067fc:	4785                	li	a5,1
    800067fe:	f4f711e3          	bne	a4,a5,80006740 <sys_open+0x5e>
    80006802:	f4c42783          	lw	a5,-180(s0)
    80006806:	d7b9                	beqz	a5,80006754 <sys_open+0x72>
      iunlockput(ip);
    80006808:	8526                	mv	a0,s1
    8000680a:	ffffe097          	auipc	ra,0xffffe
    8000680e:	1a8080e7          	jalr	424(ra) # 800049b2 <iunlockput>
      end_op();
    80006812:	fffff097          	auipc	ra,0xfffff
    80006816:	980080e7          	jalr	-1664(ra) # 80005192 <end_op>
      return -1;
    8000681a:	557d                	li	a0,-1
    8000681c:	b76d                	j	800067c6 <sys_open+0xe4>
      end_op();
    8000681e:	fffff097          	auipc	ra,0xfffff
    80006822:	974080e7          	jalr	-1676(ra) # 80005192 <end_op>
      return -1;
    80006826:	557d                	li	a0,-1
    80006828:	bf79                	j	800067c6 <sys_open+0xe4>
    iunlockput(ip);
    8000682a:	8526                	mv	a0,s1
    8000682c:	ffffe097          	auipc	ra,0xffffe
    80006830:	186080e7          	jalr	390(ra) # 800049b2 <iunlockput>
    end_op();
    80006834:	fffff097          	auipc	ra,0xfffff
    80006838:	95e080e7          	jalr	-1698(ra) # 80005192 <end_op>
    return -1;
    8000683c:	557d                	li	a0,-1
    8000683e:	b761                	j	800067c6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006840:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006844:	04649783          	lh	a5,70(s1)
    80006848:	02f99223          	sh	a5,36(s3)
    8000684c:	bf25                	j	80006784 <sys_open+0xa2>
    itrunc(ip);
    8000684e:	8526                	mv	a0,s1
    80006850:	ffffe097          	auipc	ra,0xffffe
    80006854:	00e080e7          	jalr	14(ra) # 8000485e <itrunc>
    80006858:	bfa9                	j	800067b2 <sys_open+0xd0>
      fileclose(f);
    8000685a:	854e                	mv	a0,s3
    8000685c:	fffff097          	auipc	ra,0xfffff
    80006860:	d82080e7          	jalr	-638(ra) # 800055de <fileclose>
    iunlockput(ip);
    80006864:	8526                	mv	a0,s1
    80006866:	ffffe097          	auipc	ra,0xffffe
    8000686a:	14c080e7          	jalr	332(ra) # 800049b2 <iunlockput>
    end_op();
    8000686e:	fffff097          	auipc	ra,0xfffff
    80006872:	924080e7          	jalr	-1756(ra) # 80005192 <end_op>
    return -1;
    80006876:	557d                	li	a0,-1
    80006878:	b7b9                	j	800067c6 <sys_open+0xe4>

000000008000687a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000687a:	7175                	addi	sp,sp,-144
    8000687c:	e506                	sd	ra,136(sp)
    8000687e:	e122                	sd	s0,128(sp)
    80006880:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006882:	fffff097          	auipc	ra,0xfffff
    80006886:	890080e7          	jalr	-1904(ra) # 80005112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000688a:	08000613          	li	a2,128
    8000688e:	f7040593          	addi	a1,s0,-144
    80006892:	4501                	li	a0,0
    80006894:	ffffd097          	auipc	ra,0xffffd
    80006898:	f60080e7          	jalr	-160(ra) # 800037f4 <argstr>
    8000689c:	02054963          	bltz	a0,800068ce <sys_mkdir+0x54>
    800068a0:	4681                	li	a3,0
    800068a2:	4601                	li	a2,0
    800068a4:	4585                	li	a1,1
    800068a6:	f7040513          	addi	a0,s0,-144
    800068aa:	fffff097          	auipc	ra,0xfffff
    800068ae:	7fe080e7          	jalr	2046(ra) # 800060a8 <create>
    800068b2:	cd11                	beqz	a0,800068ce <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800068b4:	ffffe097          	auipc	ra,0xffffe
    800068b8:	0fe080e7          	jalr	254(ra) # 800049b2 <iunlockput>
  end_op();
    800068bc:	fffff097          	auipc	ra,0xfffff
    800068c0:	8d6080e7          	jalr	-1834(ra) # 80005192 <end_op>
  return 0;
    800068c4:	4501                	li	a0,0
}
    800068c6:	60aa                	ld	ra,136(sp)
    800068c8:	640a                	ld	s0,128(sp)
    800068ca:	6149                	addi	sp,sp,144
    800068cc:	8082                	ret
    end_op();
    800068ce:	fffff097          	auipc	ra,0xfffff
    800068d2:	8c4080e7          	jalr	-1852(ra) # 80005192 <end_op>
    return -1;
    800068d6:	557d                	li	a0,-1
    800068d8:	b7fd                	j	800068c6 <sys_mkdir+0x4c>

00000000800068da <sys_mknod>:

uint64
sys_mknod(void)
{
    800068da:	7135                	addi	sp,sp,-160
    800068dc:	ed06                	sd	ra,152(sp)
    800068de:	e922                	sd	s0,144(sp)
    800068e0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800068e2:	fffff097          	auipc	ra,0xfffff
    800068e6:	830080e7          	jalr	-2000(ra) # 80005112 <begin_op>
  argint(1, &major);
    800068ea:	f6c40593          	addi	a1,s0,-148
    800068ee:	4505                	li	a0,1
    800068f0:	ffffd097          	auipc	ra,0xffffd
    800068f4:	ec4080e7          	jalr	-316(ra) # 800037b4 <argint>
  argint(2, &minor);
    800068f8:	f6840593          	addi	a1,s0,-152
    800068fc:	4509                	li	a0,2
    800068fe:	ffffd097          	auipc	ra,0xffffd
    80006902:	eb6080e7          	jalr	-330(ra) # 800037b4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006906:	08000613          	li	a2,128
    8000690a:	f7040593          	addi	a1,s0,-144
    8000690e:	4501                	li	a0,0
    80006910:	ffffd097          	auipc	ra,0xffffd
    80006914:	ee4080e7          	jalr	-284(ra) # 800037f4 <argstr>
    80006918:	02054b63          	bltz	a0,8000694e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000691c:	f6841683          	lh	a3,-152(s0)
    80006920:	f6c41603          	lh	a2,-148(s0)
    80006924:	458d                	li	a1,3
    80006926:	f7040513          	addi	a0,s0,-144
    8000692a:	fffff097          	auipc	ra,0xfffff
    8000692e:	77e080e7          	jalr	1918(ra) # 800060a8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006932:	cd11                	beqz	a0,8000694e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006934:	ffffe097          	auipc	ra,0xffffe
    80006938:	07e080e7          	jalr	126(ra) # 800049b2 <iunlockput>
  end_op();
    8000693c:	fffff097          	auipc	ra,0xfffff
    80006940:	856080e7          	jalr	-1962(ra) # 80005192 <end_op>
  return 0;
    80006944:	4501                	li	a0,0
}
    80006946:	60ea                	ld	ra,152(sp)
    80006948:	644a                	ld	s0,144(sp)
    8000694a:	610d                	addi	sp,sp,160
    8000694c:	8082                	ret
    end_op();
    8000694e:	fffff097          	auipc	ra,0xfffff
    80006952:	844080e7          	jalr	-1980(ra) # 80005192 <end_op>
    return -1;
    80006956:	557d                	li	a0,-1
    80006958:	b7fd                	j	80006946 <sys_mknod+0x6c>

000000008000695a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000695a:	7135                	addi	sp,sp,-160
    8000695c:	ed06                	sd	ra,152(sp)
    8000695e:	e922                	sd	s0,144(sp)
    80006960:	e526                	sd	s1,136(sp)
    80006962:	e14a                	sd	s2,128(sp)
    80006964:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006966:	ffffb097          	auipc	ra,0xffffb
    8000696a:	3b8080e7          	jalr	952(ra) # 80001d1e <myproc>
    8000696e:	892a                	mv	s2,a0
  
  begin_op();
    80006970:	ffffe097          	auipc	ra,0xffffe
    80006974:	7a2080e7          	jalr	1954(ra) # 80005112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006978:	08000613          	li	a2,128
    8000697c:	f6040593          	addi	a1,s0,-160
    80006980:	4501                	li	a0,0
    80006982:	ffffd097          	auipc	ra,0xffffd
    80006986:	e72080e7          	jalr	-398(ra) # 800037f4 <argstr>
    8000698a:	04054b63          	bltz	a0,800069e0 <sys_chdir+0x86>
    8000698e:	f6040513          	addi	a0,s0,-160
    80006992:	ffffe097          	auipc	ra,0xffffe
    80006996:	564080e7          	jalr	1380(ra) # 80004ef6 <namei>
    8000699a:	84aa                	mv	s1,a0
    8000699c:	c131                	beqz	a0,800069e0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000699e:	ffffe097          	auipc	ra,0xffffe
    800069a2:	db2080e7          	jalr	-590(ra) # 80004750 <ilock>
  if(ip->type != T_DIR){
    800069a6:	04449703          	lh	a4,68(s1)
    800069aa:	4785                	li	a5,1
    800069ac:	04f71063          	bne	a4,a5,800069ec <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800069b0:	8526                	mv	a0,s1
    800069b2:	ffffe097          	auipc	ra,0xffffe
    800069b6:	e60080e7          	jalr	-416(ra) # 80004812 <iunlock>
  iput(p->cwd);
    800069ba:	15893503          	ld	a0,344(s2)
    800069be:	ffffe097          	auipc	ra,0xffffe
    800069c2:	f4c080e7          	jalr	-180(ra) # 8000490a <iput>
  end_op();
    800069c6:	ffffe097          	auipc	ra,0xffffe
    800069ca:	7cc080e7          	jalr	1996(ra) # 80005192 <end_op>
  p->cwd = ip;
    800069ce:	14993c23          	sd	s1,344(s2)
  return 0;
    800069d2:	4501                	li	a0,0
}
    800069d4:	60ea                	ld	ra,152(sp)
    800069d6:	644a                	ld	s0,144(sp)
    800069d8:	64aa                	ld	s1,136(sp)
    800069da:	690a                	ld	s2,128(sp)
    800069dc:	610d                	addi	sp,sp,160
    800069de:	8082                	ret
    end_op();
    800069e0:	ffffe097          	auipc	ra,0xffffe
    800069e4:	7b2080e7          	jalr	1970(ra) # 80005192 <end_op>
    return -1;
    800069e8:	557d                	li	a0,-1
    800069ea:	b7ed                	j	800069d4 <sys_chdir+0x7a>
    iunlockput(ip);
    800069ec:	8526                	mv	a0,s1
    800069ee:	ffffe097          	auipc	ra,0xffffe
    800069f2:	fc4080e7          	jalr	-60(ra) # 800049b2 <iunlockput>
    end_op();
    800069f6:	ffffe097          	auipc	ra,0xffffe
    800069fa:	79c080e7          	jalr	1948(ra) # 80005192 <end_op>
    return -1;
    800069fe:	557d                	li	a0,-1
    80006a00:	bfd1                	j	800069d4 <sys_chdir+0x7a>

0000000080006a02 <sys_exec>:

uint64
sys_exec(void)
{
    80006a02:	7145                	addi	sp,sp,-464
    80006a04:	e786                	sd	ra,456(sp)
    80006a06:	e3a2                	sd	s0,448(sp)
    80006a08:	ff26                	sd	s1,440(sp)
    80006a0a:	fb4a                	sd	s2,432(sp)
    80006a0c:	f74e                	sd	s3,424(sp)
    80006a0e:	f352                	sd	s4,416(sp)
    80006a10:	ef56                	sd	s5,408(sp)
    80006a12:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006a14:	e3840593          	addi	a1,s0,-456
    80006a18:	4505                	li	a0,1
    80006a1a:	ffffd097          	auipc	ra,0xffffd
    80006a1e:	dba080e7          	jalr	-582(ra) # 800037d4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006a22:	08000613          	li	a2,128
    80006a26:	f4040593          	addi	a1,s0,-192
    80006a2a:	4501                	li	a0,0
    80006a2c:	ffffd097          	auipc	ra,0xffffd
    80006a30:	dc8080e7          	jalr	-568(ra) # 800037f4 <argstr>
    80006a34:	87aa                	mv	a5,a0
    return -1;
    80006a36:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006a38:	0c07c263          	bltz	a5,80006afc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006a3c:	10000613          	li	a2,256
    80006a40:	4581                	li	a1,0
    80006a42:	e4040513          	addi	a0,s0,-448
    80006a46:	ffffa097          	auipc	ra,0xffffa
    80006a4a:	562080e7          	jalr	1378(ra) # 80000fa8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006a4e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006a52:	89a6                	mv	s3,s1
    80006a54:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006a56:	02000a13          	li	s4,32
    80006a5a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006a5e:	00391513          	slli	a0,s2,0x3
    80006a62:	e3040593          	addi	a1,s0,-464
    80006a66:	e3843783          	ld	a5,-456(s0)
    80006a6a:	953e                	add	a0,a0,a5
    80006a6c:	ffffd097          	auipc	ra,0xffffd
    80006a70:	caa080e7          	jalr	-854(ra) # 80003716 <fetchaddr>
    80006a74:	02054a63          	bltz	a0,80006aa8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006a78:	e3043783          	ld	a5,-464(s0)
    80006a7c:	c3b9                	beqz	a5,80006ac2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	276080e7          	jalr	630(ra) # 80000cf4 <kalloc>
    80006a86:	85aa                	mv	a1,a0
    80006a88:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006a8c:	cd11                	beqz	a0,80006aa8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006a8e:	6605                	lui	a2,0x1
    80006a90:	e3043503          	ld	a0,-464(s0)
    80006a94:	ffffd097          	auipc	ra,0xffffd
    80006a98:	cd4080e7          	jalr	-812(ra) # 80003768 <fetchstr>
    80006a9c:	00054663          	bltz	a0,80006aa8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006aa0:	0905                	addi	s2,s2,1
    80006aa2:	09a1                	addi	s3,s3,8
    80006aa4:	fb491be3          	bne	s2,s4,80006a5a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006aa8:	10048913          	addi	s2,s1,256
    80006aac:	6088                	ld	a0,0(s1)
    80006aae:	c531                	beqz	a0,80006afa <sys_exec+0xf8>
    kfree(argv[i]);
    80006ab0:	ffffa097          	auipc	ra,0xffffa
    80006ab4:	0e6080e7          	jalr	230(ra) # 80000b96 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ab8:	04a1                	addi	s1,s1,8
    80006aba:	ff2499e3          	bne	s1,s2,80006aac <sys_exec+0xaa>
  return -1;
    80006abe:	557d                	li	a0,-1
    80006ac0:	a835                	j	80006afc <sys_exec+0xfa>
      argv[i] = 0;
    80006ac2:	0a8e                	slli	s5,s5,0x3
    80006ac4:	fc040793          	addi	a5,s0,-64
    80006ac8:	9abe                	add	s5,s5,a5
    80006aca:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006ace:	e4040593          	addi	a1,s0,-448
    80006ad2:	f4040513          	addi	a0,s0,-192
    80006ad6:	fffff097          	auipc	ra,0xfffff
    80006ada:	190080e7          	jalr	400(ra) # 80005c66 <exec>
    80006ade:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ae0:	10048993          	addi	s3,s1,256
    80006ae4:	6088                	ld	a0,0(s1)
    80006ae6:	c901                	beqz	a0,80006af6 <sys_exec+0xf4>
    kfree(argv[i]);
    80006ae8:	ffffa097          	auipc	ra,0xffffa
    80006aec:	0ae080e7          	jalr	174(ra) # 80000b96 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006af0:	04a1                	addi	s1,s1,8
    80006af2:	ff3499e3          	bne	s1,s3,80006ae4 <sys_exec+0xe2>
  return ret;
    80006af6:	854a                	mv	a0,s2
    80006af8:	a011                	j	80006afc <sys_exec+0xfa>
  return -1;
    80006afa:	557d                	li	a0,-1
}
    80006afc:	60be                	ld	ra,456(sp)
    80006afe:	641e                	ld	s0,448(sp)
    80006b00:	74fa                	ld	s1,440(sp)
    80006b02:	795a                	ld	s2,432(sp)
    80006b04:	79ba                	ld	s3,424(sp)
    80006b06:	7a1a                	ld	s4,416(sp)
    80006b08:	6afa                	ld	s5,408(sp)
    80006b0a:	6179                	addi	sp,sp,464
    80006b0c:	8082                	ret

0000000080006b0e <sys_pipe>:

uint64
sys_pipe(void)
{
    80006b0e:	7139                	addi	sp,sp,-64
    80006b10:	fc06                	sd	ra,56(sp)
    80006b12:	f822                	sd	s0,48(sp)
    80006b14:	f426                	sd	s1,40(sp)
    80006b16:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006b18:	ffffb097          	auipc	ra,0xffffb
    80006b1c:	206080e7          	jalr	518(ra) # 80001d1e <myproc>
    80006b20:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006b22:	fd840593          	addi	a1,s0,-40
    80006b26:	4501                	li	a0,0
    80006b28:	ffffd097          	auipc	ra,0xffffd
    80006b2c:	cac080e7          	jalr	-852(ra) # 800037d4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006b30:	fc840593          	addi	a1,s0,-56
    80006b34:	fd040513          	addi	a0,s0,-48
    80006b38:	fffff097          	auipc	ra,0xfffff
    80006b3c:	dd6080e7          	jalr	-554(ra) # 8000590e <pipealloc>
    return -1;
    80006b40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006b42:	0c054463          	bltz	a0,80006c0a <sys_pipe+0xfc>
  fd0 = -1;
    80006b46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006b4a:	fd043503          	ld	a0,-48(s0)
    80006b4e:	fffff097          	auipc	ra,0xfffff
    80006b52:	518080e7          	jalr	1304(ra) # 80006066 <fdalloc>
    80006b56:	fca42223          	sw	a0,-60(s0)
    80006b5a:	08054b63          	bltz	a0,80006bf0 <sys_pipe+0xe2>
    80006b5e:	fc843503          	ld	a0,-56(s0)
    80006b62:	fffff097          	auipc	ra,0xfffff
    80006b66:	504080e7          	jalr	1284(ra) # 80006066 <fdalloc>
    80006b6a:	fca42023          	sw	a0,-64(s0)
    80006b6e:	06054863          	bltz	a0,80006bde <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006b72:	4691                	li	a3,4
    80006b74:	fc440613          	addi	a2,s0,-60
    80006b78:	fd843583          	ld	a1,-40(s0)
    80006b7c:	6ca8                	ld	a0,88(s1)
    80006b7e:	ffffb097          	auipc	ra,0xffffb
    80006b82:	dcc080e7          	jalr	-564(ra) # 8000194a <copyout>
    80006b86:	02054063          	bltz	a0,80006ba6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006b8a:	4691                	li	a3,4
    80006b8c:	fc040613          	addi	a2,s0,-64
    80006b90:	fd843583          	ld	a1,-40(s0)
    80006b94:	0591                	addi	a1,a1,4
    80006b96:	6ca8                	ld	a0,88(s1)
    80006b98:	ffffb097          	auipc	ra,0xffffb
    80006b9c:	db2080e7          	jalr	-590(ra) # 8000194a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006ba0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006ba2:	06055463          	bgez	a0,80006c0a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006ba6:	fc442783          	lw	a5,-60(s0)
    80006baa:	07e9                	addi	a5,a5,26
    80006bac:	078e                	slli	a5,a5,0x3
    80006bae:	97a6                	add	a5,a5,s1
    80006bb0:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006bb4:	fc042503          	lw	a0,-64(s0)
    80006bb8:	0569                	addi	a0,a0,26
    80006bba:	050e                	slli	a0,a0,0x3
    80006bbc:	94aa                	add	s1,s1,a0
    80006bbe:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006bc2:	fd043503          	ld	a0,-48(s0)
    80006bc6:	fffff097          	auipc	ra,0xfffff
    80006bca:	a18080e7          	jalr	-1512(ra) # 800055de <fileclose>
    fileclose(wf);
    80006bce:	fc843503          	ld	a0,-56(s0)
    80006bd2:	fffff097          	auipc	ra,0xfffff
    80006bd6:	a0c080e7          	jalr	-1524(ra) # 800055de <fileclose>
    return -1;
    80006bda:	57fd                	li	a5,-1
    80006bdc:	a03d                	j	80006c0a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006bde:	fc442783          	lw	a5,-60(s0)
    80006be2:	0007c763          	bltz	a5,80006bf0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006be6:	07e9                	addi	a5,a5,26
    80006be8:	078e                	slli	a5,a5,0x3
    80006bea:	94be                	add	s1,s1,a5
    80006bec:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006bf0:	fd043503          	ld	a0,-48(s0)
    80006bf4:	fffff097          	auipc	ra,0xfffff
    80006bf8:	9ea080e7          	jalr	-1558(ra) # 800055de <fileclose>
    fileclose(wf);
    80006bfc:	fc843503          	ld	a0,-56(s0)
    80006c00:	fffff097          	auipc	ra,0xfffff
    80006c04:	9de080e7          	jalr	-1570(ra) # 800055de <fileclose>
    return -1;
    80006c08:	57fd                	li	a5,-1
}
    80006c0a:	853e                	mv	a0,a5
    80006c0c:	70e2                	ld	ra,56(sp)
    80006c0e:	7442                	ld	s0,48(sp)
    80006c10:	74a2                	ld	s1,40(sp)
    80006c12:	6121                	addi	sp,sp,64
    80006c14:	8082                	ret
	...

0000000080006c20 <kernelvec>:
    80006c20:	7111                	addi	sp,sp,-256
    80006c22:	e006                	sd	ra,0(sp)
    80006c24:	e40a                	sd	sp,8(sp)
    80006c26:	e80e                	sd	gp,16(sp)
    80006c28:	ec12                	sd	tp,24(sp)
    80006c2a:	f016                	sd	t0,32(sp)
    80006c2c:	f41a                	sd	t1,40(sp)
    80006c2e:	f81e                	sd	t2,48(sp)
    80006c30:	fc22                	sd	s0,56(sp)
    80006c32:	e0a6                	sd	s1,64(sp)
    80006c34:	e4aa                	sd	a0,72(sp)
    80006c36:	e8ae                	sd	a1,80(sp)
    80006c38:	ecb2                	sd	a2,88(sp)
    80006c3a:	f0b6                	sd	a3,96(sp)
    80006c3c:	f4ba                	sd	a4,104(sp)
    80006c3e:	f8be                	sd	a5,112(sp)
    80006c40:	fcc2                	sd	a6,120(sp)
    80006c42:	e146                	sd	a7,128(sp)
    80006c44:	e54a                	sd	s2,136(sp)
    80006c46:	e94e                	sd	s3,144(sp)
    80006c48:	ed52                	sd	s4,152(sp)
    80006c4a:	f156                	sd	s5,160(sp)
    80006c4c:	f55a                	sd	s6,168(sp)
    80006c4e:	f95e                	sd	s7,176(sp)
    80006c50:	fd62                	sd	s8,184(sp)
    80006c52:	e1e6                	sd	s9,192(sp)
    80006c54:	e5ea                	sd	s10,200(sp)
    80006c56:	e9ee                	sd	s11,208(sp)
    80006c58:	edf2                	sd	t3,216(sp)
    80006c5a:	f1f6                	sd	t4,224(sp)
    80006c5c:	f5fa                	sd	t5,232(sp)
    80006c5e:	f9fe                	sd	t6,240(sp)
    80006c60:	923fc0ef          	jal	ra,80003582 <kerneltrap>
    80006c64:	6082                	ld	ra,0(sp)
    80006c66:	6122                	ld	sp,8(sp)
    80006c68:	61c2                	ld	gp,16(sp)
    80006c6a:	7282                	ld	t0,32(sp)
    80006c6c:	7322                	ld	t1,40(sp)
    80006c6e:	73c2                	ld	t2,48(sp)
    80006c70:	7462                	ld	s0,56(sp)
    80006c72:	6486                	ld	s1,64(sp)
    80006c74:	6526                	ld	a0,72(sp)
    80006c76:	65c6                	ld	a1,80(sp)
    80006c78:	6666                	ld	a2,88(sp)
    80006c7a:	7686                	ld	a3,96(sp)
    80006c7c:	7726                	ld	a4,104(sp)
    80006c7e:	77c6                	ld	a5,112(sp)
    80006c80:	7866                	ld	a6,120(sp)
    80006c82:	688a                	ld	a7,128(sp)
    80006c84:	692a                	ld	s2,136(sp)
    80006c86:	69ca                	ld	s3,144(sp)
    80006c88:	6a6a                	ld	s4,152(sp)
    80006c8a:	7a8a                	ld	s5,160(sp)
    80006c8c:	7b2a                	ld	s6,168(sp)
    80006c8e:	7bca                	ld	s7,176(sp)
    80006c90:	7c6a                	ld	s8,184(sp)
    80006c92:	6c8e                	ld	s9,192(sp)
    80006c94:	6d2e                	ld	s10,200(sp)
    80006c96:	6dce                	ld	s11,208(sp)
    80006c98:	6e6e                	ld	t3,216(sp)
    80006c9a:	7e8e                	ld	t4,224(sp)
    80006c9c:	7f2e                	ld	t5,232(sp)
    80006c9e:	7fce                	ld	t6,240(sp)
    80006ca0:	6111                	addi	sp,sp,256
    80006ca2:	10200073          	sret
    80006ca6:	00000013          	nop
    80006caa:	00000013          	nop
    80006cae:	0001                	nop

0000000080006cb0 <timervec>:
    80006cb0:	34051573          	csrrw	a0,mscratch,a0
    80006cb4:	e10c                	sd	a1,0(a0)
    80006cb6:	e510                	sd	a2,8(a0)
    80006cb8:	e914                	sd	a3,16(a0)
    80006cba:	6d0c                	ld	a1,24(a0)
    80006cbc:	7110                	ld	a2,32(a0)
    80006cbe:	6194                	ld	a3,0(a1)
    80006cc0:	96b2                	add	a3,a3,a2
    80006cc2:	e194                	sd	a3,0(a1)
    80006cc4:	4589                	li	a1,2
    80006cc6:	14459073          	csrw	sip,a1
    80006cca:	6914                	ld	a3,16(a0)
    80006ccc:	6510                	ld	a2,8(a0)
    80006cce:	610c                	ld	a1,0(a0)
    80006cd0:	34051573          	csrrw	a0,mscratch,a0
    80006cd4:	30200073          	mret
	...

0000000080006cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006cda:	1141                	addi	sp,sp,-16
    80006cdc:	e422                	sd	s0,8(sp)
    80006cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006ce0:	0c0007b7          	lui	a5,0xc000
    80006ce4:	4705                	li	a4,1
    80006ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006ce8:	c3d8                	sw	a4,4(a5)
}
    80006cea:	6422                	ld	s0,8(sp)
    80006cec:	0141                	addi	sp,sp,16
    80006cee:	8082                	ret

0000000080006cf0 <plicinithart>:

void
plicinithart(void)
{
    80006cf0:	1141                	addi	sp,sp,-16
    80006cf2:	e406                	sd	ra,8(sp)
    80006cf4:	e022                	sd	s0,0(sp)
    80006cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006cf8:	ffffb097          	auipc	ra,0xffffb
    80006cfc:	ff4080e7          	jalr	-12(ra) # 80001cec <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006d00:	0085171b          	slliw	a4,a0,0x8
    80006d04:	0c0027b7          	lui	a5,0xc002
    80006d08:	97ba                	add	a5,a5,a4
    80006d0a:	40200713          	li	a4,1026
    80006d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006d12:	00d5151b          	slliw	a0,a0,0xd
    80006d16:	0c2017b7          	lui	a5,0xc201
    80006d1a:	953e                	add	a0,a0,a5
    80006d1c:	00052023          	sw	zero,0(a0)
}
    80006d20:	60a2                	ld	ra,8(sp)
    80006d22:	6402                	ld	s0,0(sp)
    80006d24:	0141                	addi	sp,sp,16
    80006d26:	8082                	ret

0000000080006d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006d28:	1141                	addi	sp,sp,-16
    80006d2a:	e406                	sd	ra,8(sp)
    80006d2c:	e022                	sd	s0,0(sp)
    80006d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d30:	ffffb097          	auipc	ra,0xffffb
    80006d34:	fbc080e7          	jalr	-68(ra) # 80001cec <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006d38:	00d5179b          	slliw	a5,a0,0xd
    80006d3c:	0c201537          	lui	a0,0xc201
    80006d40:	953e                	add	a0,a0,a5
  return irq;
}
    80006d42:	4148                	lw	a0,4(a0)
    80006d44:	60a2                	ld	ra,8(sp)
    80006d46:	6402                	ld	s0,0(sp)
    80006d48:	0141                	addi	sp,sp,16
    80006d4a:	8082                	ret

0000000080006d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006d4c:	1101                	addi	sp,sp,-32
    80006d4e:	ec06                	sd	ra,24(sp)
    80006d50:	e822                	sd	s0,16(sp)
    80006d52:	e426                	sd	s1,8(sp)
    80006d54:	1000                	addi	s0,sp,32
    80006d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006d58:	ffffb097          	auipc	ra,0xffffb
    80006d5c:	f94080e7          	jalr	-108(ra) # 80001cec <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006d60:	00d5151b          	slliw	a0,a0,0xd
    80006d64:	0c2017b7          	lui	a5,0xc201
    80006d68:	97aa                	add	a5,a5,a0
    80006d6a:	c3c4                	sw	s1,4(a5)
}
    80006d6c:	60e2                	ld	ra,24(sp)
    80006d6e:	6442                	ld	s0,16(sp)
    80006d70:	64a2                	ld	s1,8(sp)
    80006d72:	6105                	addi	sp,sp,32
    80006d74:	8082                	ret

0000000080006d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006d76:	1141                	addi	sp,sp,-16
    80006d78:	e406                	sd	ra,8(sp)
    80006d7a:	e022                	sd	s0,0(sp)
    80006d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006d7e:	479d                	li	a5,7
    80006d80:	04a7cc63          	blt	a5,a0,80006dd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006d84:	0023f797          	auipc	a5,0x23f
    80006d88:	55478793          	addi	a5,a5,1364 # 802462d8 <disk>
    80006d8c:	97aa                	add	a5,a5,a0
    80006d8e:	0187c783          	lbu	a5,24(a5)
    80006d92:	ebb9                	bnez	a5,80006de8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006d94:	00451613          	slli	a2,a0,0x4
    80006d98:	0023f797          	auipc	a5,0x23f
    80006d9c:	54078793          	addi	a5,a5,1344 # 802462d8 <disk>
    80006da0:	6394                	ld	a3,0(a5)
    80006da2:	96b2                	add	a3,a3,a2
    80006da4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006da8:	6398                	ld	a4,0(a5)
    80006daa:	9732                	add	a4,a4,a2
    80006dac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006db0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006db4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006db8:	953e                	add	a0,a0,a5
    80006dba:	4785                	li	a5,1
    80006dbc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006dc0:	0023f517          	auipc	a0,0x23f
    80006dc4:	53050513          	addi	a0,a0,1328 # 802462f0 <disk+0x18>
    80006dc8:	ffffc097          	auipc	ra,0xffffc
    80006dcc:	8b2080e7          	jalr	-1870(ra) # 8000267a <wakeup>
}
    80006dd0:	60a2                	ld	ra,8(sp)
    80006dd2:	6402                	ld	s0,0(sp)
    80006dd4:	0141                	addi	sp,sp,16
    80006dd6:	8082                	ret
    panic("free_desc 1");
    80006dd8:	00003517          	auipc	a0,0x3
    80006ddc:	bf850513          	addi	a0,a0,-1032 # 800099d0 <syscalls+0x310>
    80006de0:	ffff9097          	auipc	ra,0xffff9
    80006de4:	764080e7          	jalr	1892(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006de8:	00003517          	auipc	a0,0x3
    80006dec:	bf850513          	addi	a0,a0,-1032 # 800099e0 <syscalls+0x320>
    80006df0:	ffff9097          	auipc	ra,0xffff9
    80006df4:	754080e7          	jalr	1876(ra) # 80000544 <panic>

0000000080006df8 <virtio_disk_init>:
{
    80006df8:	1101                	addi	sp,sp,-32
    80006dfa:	ec06                	sd	ra,24(sp)
    80006dfc:	e822                	sd	s0,16(sp)
    80006dfe:	e426                	sd	s1,8(sp)
    80006e00:	e04a                	sd	s2,0(sp)
    80006e02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006e04:	00003597          	auipc	a1,0x3
    80006e08:	bec58593          	addi	a1,a1,-1044 # 800099f0 <syscalls+0x330>
    80006e0c:	0023f517          	auipc	a0,0x23f
    80006e10:	5f450513          	addi	a0,a0,1524 # 80246400 <disk+0x128>
    80006e14:	ffffa097          	auipc	ra,0xffffa
    80006e18:	008080e7          	jalr	8(ra) # 80000e1c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e1c:	100017b7          	lui	a5,0x10001
    80006e20:	4398                	lw	a4,0(a5)
    80006e22:	2701                	sext.w	a4,a4
    80006e24:	747277b7          	lui	a5,0x74727
    80006e28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006e2c:	14f71e63          	bne	a4,a5,80006f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006e30:	100017b7          	lui	a5,0x10001
    80006e34:	43dc                	lw	a5,4(a5)
    80006e36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e38:	4709                	li	a4,2
    80006e3a:	14e79763          	bne	a5,a4,80006f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e3e:	100017b7          	lui	a5,0x10001
    80006e42:	479c                	lw	a5,8(a5)
    80006e44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006e46:	14e79163          	bne	a5,a4,80006f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006e4a:	100017b7          	lui	a5,0x10001
    80006e4e:	47d8                	lw	a4,12(a5)
    80006e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e52:	554d47b7          	lui	a5,0x554d4
    80006e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006e5a:	12f71763          	bne	a4,a5,80006f88 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e5e:	100017b7          	lui	a5,0x10001
    80006e62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e66:	4705                	li	a4,1
    80006e68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e6a:	470d                	li	a4,3
    80006e6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006e6e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006e70:	c7ffe737          	lui	a4,0xc7ffe
    80006e74:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db8347>
    80006e78:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006e7a:	2701                	sext.w	a4,a4
    80006e7c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e7e:	472d                	li	a4,11
    80006e80:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006e82:	0707a903          	lw	s2,112(a5)
    80006e86:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006e88:	00897793          	andi	a5,s2,8
    80006e8c:	10078663          	beqz	a5,80006f98 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006e90:	100017b7          	lui	a5,0x10001
    80006e94:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006e98:	43fc                	lw	a5,68(a5)
    80006e9a:	2781                	sext.w	a5,a5
    80006e9c:	10079663          	bnez	a5,80006fa8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ea0:	100017b7          	lui	a5,0x10001
    80006ea4:	5bdc                	lw	a5,52(a5)
    80006ea6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ea8:	10078863          	beqz	a5,80006fb8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006eac:	471d                	li	a4,7
    80006eae:	10f77d63          	bgeu	a4,a5,80006fc8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006eb2:	ffffa097          	auipc	ra,0xffffa
    80006eb6:	e42080e7          	jalr	-446(ra) # 80000cf4 <kalloc>
    80006eba:	0023f497          	auipc	s1,0x23f
    80006ebe:	41e48493          	addi	s1,s1,1054 # 802462d8 <disk>
    80006ec2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006ec4:	ffffa097          	auipc	ra,0xffffa
    80006ec8:	e30080e7          	jalr	-464(ra) # 80000cf4 <kalloc>
    80006ecc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006ece:	ffffa097          	auipc	ra,0xffffa
    80006ed2:	e26080e7          	jalr	-474(ra) # 80000cf4 <kalloc>
    80006ed6:	87aa                	mv	a5,a0
    80006ed8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006eda:	6088                	ld	a0,0(s1)
    80006edc:	cd75                	beqz	a0,80006fd8 <virtio_disk_init+0x1e0>
    80006ede:	0023f717          	auipc	a4,0x23f
    80006ee2:	40273703          	ld	a4,1026(a4) # 802462e0 <disk+0x8>
    80006ee6:	cb6d                	beqz	a4,80006fd8 <virtio_disk_init+0x1e0>
    80006ee8:	cbe5                	beqz	a5,80006fd8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006eea:	6605                	lui	a2,0x1
    80006eec:	4581                	li	a1,0
    80006eee:	ffffa097          	auipc	ra,0xffffa
    80006ef2:	0ba080e7          	jalr	186(ra) # 80000fa8 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006ef6:	0023f497          	auipc	s1,0x23f
    80006efa:	3e248493          	addi	s1,s1,994 # 802462d8 <disk>
    80006efe:	6605                	lui	a2,0x1
    80006f00:	4581                	li	a1,0
    80006f02:	6488                	ld	a0,8(s1)
    80006f04:	ffffa097          	auipc	ra,0xffffa
    80006f08:	0a4080e7          	jalr	164(ra) # 80000fa8 <memset>
  memset(disk.used, 0, PGSIZE);
    80006f0c:	6605                	lui	a2,0x1
    80006f0e:	4581                	li	a1,0
    80006f10:	6888                	ld	a0,16(s1)
    80006f12:	ffffa097          	auipc	ra,0xffffa
    80006f16:	096080e7          	jalr	150(ra) # 80000fa8 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006f1a:	100017b7          	lui	a5,0x10001
    80006f1e:	4721                	li	a4,8
    80006f20:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006f22:	4098                	lw	a4,0(s1)
    80006f24:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006f28:	40d8                	lw	a4,4(s1)
    80006f2a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006f2e:	6498                	ld	a4,8(s1)
    80006f30:	0007069b          	sext.w	a3,a4
    80006f34:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006f38:	9701                	srai	a4,a4,0x20
    80006f3a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006f3e:	6898                	ld	a4,16(s1)
    80006f40:	0007069b          	sext.w	a3,a4
    80006f44:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006f48:	9701                	srai	a4,a4,0x20
    80006f4a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006f4e:	4685                	li	a3,1
    80006f50:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006f52:	4705                	li	a4,1
    80006f54:	00d48c23          	sb	a3,24(s1)
    80006f58:	00e48ca3          	sb	a4,25(s1)
    80006f5c:	00e48d23          	sb	a4,26(s1)
    80006f60:	00e48da3          	sb	a4,27(s1)
    80006f64:	00e48e23          	sb	a4,28(s1)
    80006f68:	00e48ea3          	sb	a4,29(s1)
    80006f6c:	00e48f23          	sb	a4,30(s1)
    80006f70:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006f74:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f78:	0727a823          	sw	s2,112(a5)
}
    80006f7c:	60e2                	ld	ra,24(sp)
    80006f7e:	6442                	ld	s0,16(sp)
    80006f80:	64a2                	ld	s1,8(sp)
    80006f82:	6902                	ld	s2,0(sp)
    80006f84:	6105                	addi	sp,sp,32
    80006f86:	8082                	ret
    panic("could not find virtio disk");
    80006f88:	00003517          	auipc	a0,0x3
    80006f8c:	a7850513          	addi	a0,a0,-1416 # 80009a00 <syscalls+0x340>
    80006f90:	ffff9097          	auipc	ra,0xffff9
    80006f94:	5b4080e7          	jalr	1460(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006f98:	00003517          	auipc	a0,0x3
    80006f9c:	a8850513          	addi	a0,a0,-1400 # 80009a20 <syscalls+0x360>
    80006fa0:	ffff9097          	auipc	ra,0xffff9
    80006fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006fa8:	00003517          	auipc	a0,0x3
    80006fac:	a9850513          	addi	a0,a0,-1384 # 80009a40 <syscalls+0x380>
    80006fb0:	ffff9097          	auipc	ra,0xffff9
    80006fb4:	594080e7          	jalr	1428(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006fb8:	00003517          	auipc	a0,0x3
    80006fbc:	aa850513          	addi	a0,a0,-1368 # 80009a60 <syscalls+0x3a0>
    80006fc0:	ffff9097          	auipc	ra,0xffff9
    80006fc4:	584080e7          	jalr	1412(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006fc8:	00003517          	auipc	a0,0x3
    80006fcc:	ab850513          	addi	a0,a0,-1352 # 80009a80 <syscalls+0x3c0>
    80006fd0:	ffff9097          	auipc	ra,0xffff9
    80006fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006fd8:	00003517          	auipc	a0,0x3
    80006fdc:	ac850513          	addi	a0,a0,-1336 # 80009aa0 <syscalls+0x3e0>
    80006fe0:	ffff9097          	auipc	ra,0xffff9
    80006fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>

0000000080006fe8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006fe8:	7159                	addi	sp,sp,-112
    80006fea:	f486                	sd	ra,104(sp)
    80006fec:	f0a2                	sd	s0,96(sp)
    80006fee:	eca6                	sd	s1,88(sp)
    80006ff0:	e8ca                	sd	s2,80(sp)
    80006ff2:	e4ce                	sd	s3,72(sp)
    80006ff4:	e0d2                	sd	s4,64(sp)
    80006ff6:	fc56                	sd	s5,56(sp)
    80006ff8:	f85a                	sd	s6,48(sp)
    80006ffa:	f45e                	sd	s7,40(sp)
    80006ffc:	f062                	sd	s8,32(sp)
    80006ffe:	ec66                	sd	s9,24(sp)
    80007000:	e86a                	sd	s10,16(sp)
    80007002:	1880                	addi	s0,sp,112
    80007004:	892a                	mv	s2,a0
    80007006:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007008:	00c52c83          	lw	s9,12(a0)
    8000700c:	001c9c9b          	slliw	s9,s9,0x1
    80007010:	1c82                	slli	s9,s9,0x20
    80007012:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007016:	0023f517          	auipc	a0,0x23f
    8000701a:	3ea50513          	addi	a0,a0,1002 # 80246400 <disk+0x128>
    8000701e:	ffffa097          	auipc	ra,0xffffa
    80007022:	e8e080e7          	jalr	-370(ra) # 80000eac <acquire>
  for(int i = 0; i < 3; i++){
    80007026:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007028:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000702a:	0023fb17          	auipc	s6,0x23f
    8000702e:	2aeb0b13          	addi	s6,s6,686 # 802462d8 <disk>
  for(int i = 0; i < 3; i++){
    80007032:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007034:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007036:	0023fc17          	auipc	s8,0x23f
    8000703a:	3cac0c13          	addi	s8,s8,970 # 80246400 <disk+0x128>
    8000703e:	a8b5                	j	800070ba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80007040:	00fb06b3          	add	a3,s6,a5
    80007044:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007048:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000704a:	0207c563          	bltz	a5,80007074 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000704e:	2485                	addiw	s1,s1,1
    80007050:	0711                	addi	a4,a4,4
    80007052:	1f548a63          	beq	s1,s5,80007246 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80007056:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007058:	0023f697          	auipc	a3,0x23f
    8000705c:	28068693          	addi	a3,a3,640 # 802462d8 <disk>
    80007060:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80007062:	0186c583          	lbu	a1,24(a3)
    80007066:	fde9                	bnez	a1,80007040 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80007068:	2785                	addiw	a5,a5,1
    8000706a:	0685                	addi	a3,a3,1
    8000706c:	ff779be3          	bne	a5,s7,80007062 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80007070:	57fd                	li	a5,-1
    80007072:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80007074:	02905a63          	blez	s1,800070a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80007078:	f9042503          	lw	a0,-112(s0)
    8000707c:	00000097          	auipc	ra,0x0
    80007080:	cfa080e7          	jalr	-774(ra) # 80006d76 <free_desc>
      for(int j = 0; j < i; j++)
    80007084:	4785                	li	a5,1
    80007086:	0297d163          	bge	a5,s1,800070a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000708a:	f9442503          	lw	a0,-108(s0)
    8000708e:	00000097          	auipc	ra,0x0
    80007092:	ce8080e7          	jalr	-792(ra) # 80006d76 <free_desc>
      for(int j = 0; j < i; j++)
    80007096:	4789                	li	a5,2
    80007098:	0097d863          	bge	a5,s1,800070a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000709c:	f9842503          	lw	a0,-104(s0)
    800070a0:	00000097          	auipc	ra,0x0
    800070a4:	cd6080e7          	jalr	-810(ra) # 80006d76 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800070a8:	85e2                	mv	a1,s8
    800070aa:	0023f517          	auipc	a0,0x23f
    800070ae:	24650513          	addi	a0,a0,582 # 802462f0 <disk+0x18>
    800070b2:	ffffb097          	auipc	ra,0xffffb
    800070b6:	564080e7          	jalr	1380(ra) # 80002616 <sleep>
  for(int i = 0; i < 3; i++){
    800070ba:	f9040713          	addi	a4,s0,-112
    800070be:	84ce                	mv	s1,s3
    800070c0:	bf59                	j	80007056 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800070c2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800070c6:	00479693          	slli	a3,a5,0x4
    800070ca:	0023f797          	auipc	a5,0x23f
    800070ce:	20e78793          	addi	a5,a5,526 # 802462d8 <disk>
    800070d2:	97b6                	add	a5,a5,a3
    800070d4:	4685                	li	a3,1
    800070d6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800070d8:	0023f597          	auipc	a1,0x23f
    800070dc:	20058593          	addi	a1,a1,512 # 802462d8 <disk>
    800070e0:	00a60793          	addi	a5,a2,10
    800070e4:	0792                	slli	a5,a5,0x4
    800070e6:	97ae                	add	a5,a5,a1
    800070e8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800070ec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800070f0:	f6070693          	addi	a3,a4,-160
    800070f4:	619c                	ld	a5,0(a1)
    800070f6:	97b6                	add	a5,a5,a3
    800070f8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800070fa:	6188                	ld	a0,0(a1)
    800070fc:	96aa                	add	a3,a3,a0
    800070fe:	47c1                	li	a5,16
    80007100:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80007102:	4785                	li	a5,1
    80007104:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80007108:	f9442783          	lw	a5,-108(s0)
    8000710c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007110:	0792                	slli	a5,a5,0x4
    80007112:	953e                	add	a0,a0,a5
    80007114:	05890693          	addi	a3,s2,88
    80007118:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000711a:	6188                	ld	a0,0(a1)
    8000711c:	97aa                	add	a5,a5,a0
    8000711e:	40000693          	li	a3,1024
    80007122:	c794                	sw	a3,8(a5)
  if(write)
    80007124:	100d0d63          	beqz	s10,8000723e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80007128:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000712c:	00c7d683          	lhu	a3,12(a5)
    80007130:	0016e693          	ori	a3,a3,1
    80007134:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80007138:	f9842583          	lw	a1,-104(s0)
    8000713c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007140:	0023f697          	auipc	a3,0x23f
    80007144:	19868693          	addi	a3,a3,408 # 802462d8 <disk>
    80007148:	00260793          	addi	a5,a2,2
    8000714c:	0792                	slli	a5,a5,0x4
    8000714e:	97b6                	add	a5,a5,a3
    80007150:	587d                	li	a6,-1
    80007152:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007156:	0592                	slli	a1,a1,0x4
    80007158:	952e                	add	a0,a0,a1
    8000715a:	f9070713          	addi	a4,a4,-112
    8000715e:	9736                	add	a4,a4,a3
    80007160:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80007162:	6298                	ld	a4,0(a3)
    80007164:	972e                	add	a4,a4,a1
    80007166:	4585                	li	a1,1
    80007168:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000716a:	4509                	li	a0,2
    8000716c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80007170:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80007174:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80007178:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000717c:	6698                	ld	a4,8(a3)
    8000717e:	00275783          	lhu	a5,2(a4)
    80007182:	8b9d                	andi	a5,a5,7
    80007184:	0786                	slli	a5,a5,0x1
    80007186:	97ba                	add	a5,a5,a4
    80007188:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000718c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80007190:	6698                	ld	a4,8(a3)
    80007192:	00275783          	lhu	a5,2(a4)
    80007196:	2785                	addiw	a5,a5,1
    80007198:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000719c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800071a0:	100017b7          	lui	a5,0x10001
    800071a4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800071a8:	00492703          	lw	a4,4(s2)
    800071ac:	4785                	li	a5,1
    800071ae:	02f71163          	bne	a4,a5,800071d0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800071b2:	0023f997          	auipc	s3,0x23f
    800071b6:	24e98993          	addi	s3,s3,590 # 80246400 <disk+0x128>
  while(b->disk == 1) {
    800071ba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800071bc:	85ce                	mv	a1,s3
    800071be:	854a                	mv	a0,s2
    800071c0:	ffffb097          	auipc	ra,0xffffb
    800071c4:	456080e7          	jalr	1110(ra) # 80002616 <sleep>
  while(b->disk == 1) {
    800071c8:	00492783          	lw	a5,4(s2)
    800071cc:	fe9788e3          	beq	a5,s1,800071bc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800071d0:	f9042903          	lw	s2,-112(s0)
    800071d4:	00290793          	addi	a5,s2,2
    800071d8:	00479713          	slli	a4,a5,0x4
    800071dc:	0023f797          	auipc	a5,0x23f
    800071e0:	0fc78793          	addi	a5,a5,252 # 802462d8 <disk>
    800071e4:	97ba                	add	a5,a5,a4
    800071e6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800071ea:	0023f997          	auipc	s3,0x23f
    800071ee:	0ee98993          	addi	s3,s3,238 # 802462d8 <disk>
    800071f2:	00491713          	slli	a4,s2,0x4
    800071f6:	0009b783          	ld	a5,0(s3)
    800071fa:	97ba                	add	a5,a5,a4
    800071fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007200:	854a                	mv	a0,s2
    80007202:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007206:	00000097          	auipc	ra,0x0
    8000720a:	b70080e7          	jalr	-1168(ra) # 80006d76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000720e:	8885                	andi	s1,s1,1
    80007210:	f0ed                	bnez	s1,800071f2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80007212:	0023f517          	auipc	a0,0x23f
    80007216:	1ee50513          	addi	a0,a0,494 # 80246400 <disk+0x128>
    8000721a:	ffffa097          	auipc	ra,0xffffa
    8000721e:	d46080e7          	jalr	-698(ra) # 80000f60 <release>
}
    80007222:	70a6                	ld	ra,104(sp)
    80007224:	7406                	ld	s0,96(sp)
    80007226:	64e6                	ld	s1,88(sp)
    80007228:	6946                	ld	s2,80(sp)
    8000722a:	69a6                	ld	s3,72(sp)
    8000722c:	6a06                	ld	s4,64(sp)
    8000722e:	7ae2                	ld	s5,56(sp)
    80007230:	7b42                	ld	s6,48(sp)
    80007232:	7ba2                	ld	s7,40(sp)
    80007234:	7c02                	ld	s8,32(sp)
    80007236:	6ce2                	ld	s9,24(sp)
    80007238:	6d42                	ld	s10,16(sp)
    8000723a:	6165                	addi	sp,sp,112
    8000723c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000723e:	4689                	li	a3,2
    80007240:	00d79623          	sh	a3,12(a5)
    80007244:	b5e5                	j	8000712c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80007246:	f9042603          	lw	a2,-112(s0)
    8000724a:	00a60713          	addi	a4,a2,10
    8000724e:	0712                	slli	a4,a4,0x4
    80007250:	0023f517          	auipc	a0,0x23f
    80007254:	09050513          	addi	a0,a0,144 # 802462e0 <disk+0x8>
    80007258:	953a                	add	a0,a0,a4
  if(write)
    8000725a:	e60d14e3          	bnez	s10,800070c2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000725e:	00a60793          	addi	a5,a2,10
    80007262:	00479693          	slli	a3,a5,0x4
    80007266:	0023f797          	auipc	a5,0x23f
    8000726a:	07278793          	addi	a5,a5,114 # 802462d8 <disk>
    8000726e:	97b6                	add	a5,a5,a3
    80007270:	0007a423          	sw	zero,8(a5)
    80007274:	b595                	j	800070d8 <virtio_disk_rw+0xf0>

0000000080007276 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80007276:	1101                	addi	sp,sp,-32
    80007278:	ec06                	sd	ra,24(sp)
    8000727a:	e822                	sd	s0,16(sp)
    8000727c:	e426                	sd	s1,8(sp)
    8000727e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80007280:	0023f497          	auipc	s1,0x23f
    80007284:	05848493          	addi	s1,s1,88 # 802462d8 <disk>
    80007288:	0023f517          	auipc	a0,0x23f
    8000728c:	17850513          	addi	a0,a0,376 # 80246400 <disk+0x128>
    80007290:	ffffa097          	auipc	ra,0xffffa
    80007294:	c1c080e7          	jalr	-996(ra) # 80000eac <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80007298:	10001737          	lui	a4,0x10001
    8000729c:	533c                	lw	a5,96(a4)
    8000729e:	8b8d                	andi	a5,a5,3
    800072a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800072a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800072a6:	689c                	ld	a5,16(s1)
    800072a8:	0204d703          	lhu	a4,32(s1)
    800072ac:	0027d783          	lhu	a5,2(a5)
    800072b0:	04f70863          	beq	a4,a5,80007300 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800072b4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800072b8:	6898                	ld	a4,16(s1)
    800072ba:	0204d783          	lhu	a5,32(s1)
    800072be:	8b9d                	andi	a5,a5,7
    800072c0:	078e                	slli	a5,a5,0x3
    800072c2:	97ba                	add	a5,a5,a4
    800072c4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800072c6:	00278713          	addi	a4,a5,2
    800072ca:	0712                	slli	a4,a4,0x4
    800072cc:	9726                	add	a4,a4,s1
    800072ce:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800072d2:	e721                	bnez	a4,8000731a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800072d4:	0789                	addi	a5,a5,2
    800072d6:	0792                	slli	a5,a5,0x4
    800072d8:	97a6                	add	a5,a5,s1
    800072da:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800072dc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800072e0:	ffffb097          	auipc	ra,0xffffb
    800072e4:	39a080e7          	jalr	922(ra) # 8000267a <wakeup>

    disk.used_idx += 1;
    800072e8:	0204d783          	lhu	a5,32(s1)
    800072ec:	2785                	addiw	a5,a5,1
    800072ee:	17c2                	slli	a5,a5,0x30
    800072f0:	93c1                	srli	a5,a5,0x30
    800072f2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800072f6:	6898                	ld	a4,16(s1)
    800072f8:	00275703          	lhu	a4,2(a4)
    800072fc:	faf71ce3          	bne	a4,a5,800072b4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80007300:	0023f517          	auipc	a0,0x23f
    80007304:	10050513          	addi	a0,a0,256 # 80246400 <disk+0x128>
    80007308:	ffffa097          	auipc	ra,0xffffa
    8000730c:	c58080e7          	jalr	-936(ra) # 80000f60 <release>
}
    80007310:	60e2                	ld	ra,24(sp)
    80007312:	6442                	ld	s0,16(sp)
    80007314:	64a2                	ld	s1,8(sp)
    80007316:	6105                	addi	sp,sp,32
    80007318:	8082                	ret
      panic("virtio_disk_intr status");
    8000731a:	00002517          	auipc	a0,0x2
    8000731e:	79e50513          	addi	a0,a0,1950 # 80009ab8 <syscalls+0x3f8>
    80007322:	ffff9097          	auipc	ra,0xffff9
    80007326:	222080e7          	jalr	546(ra) # 80000544 <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
