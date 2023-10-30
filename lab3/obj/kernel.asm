
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	00a50513          	addi	a0,a0,10 # ffffffffc020a040 <edata>
ffffffffc020003e:	00011617          	auipc	a2,0x11
ffffffffc0200042:	55a60613          	addi	a2,a2,1370 # ffffffffc0211598 <end>
{
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
{
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	2ee040ef          	jal	ra,ffffffffc020433c <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	31658593          	addi	a1,a1,790 # ffffffffc0204368 <etext+0x2>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	32e50513          	addi	a0,a0,814 # ffffffffc0204388 <etext+0x22>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	0a0000ef          	jal	ra,ffffffffc0200106 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc020006a:	2ad010ef          	jal	ra,ffffffffc0201b16 <pmm_init>
                // 我们加入了多级页表的接口和测试

    idt_init(); // init interrupt descriptor table
ffffffffc020006e:	504000ef          	jal	ra,ffffffffc0200572 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200072:	5e0030ef          	jal	ra,ffffffffc0203652 <vmm_init>
                // 新增函数, 初始化虚拟内存管理并测试

    ide_init();  // init ide devices. 新增函数, 初始化"硬盘".
ffffffffc0200076:	426000ef          	jal	ra,ffffffffc020049c <ide_init>
                 // 这个函数啥也没做, 属于"历史遗留"
    swap_init(); // init swap. 新增函数, 初始化页面置换机制并测试
ffffffffc020007a:	792020ef          	jal	ra,ffffffffc020280c <swap_init>

    clock_init(); // init clock interrupt
ffffffffc020007e:	356000ef          	jal	ra,ffffffffc02003d4 <clock_init>
    // intr_enable();              // enable irq interrupt

    /* do nothing */
    while (1)
        ;
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	39e000ef          	jal	ra,ffffffffc020042a <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	5a3030ef          	jal	ra,ffffffffc0203e54 <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	56f030ef          	jal	ra,ffffffffc0203e54 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	3380006f          	j	ffffffffc020042a <cons_putc>

ffffffffc02000f6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000fa:	366000ef          	jal	ra,ffffffffc0200460 <cons_getc>
ffffffffc02000fe:	dd75                	beqz	a0,ffffffffc02000fa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200100:	60a2                	ld	ra,8(sp)
ffffffffc0200102:	0141                	addi	sp,sp,16
ffffffffc0200104:	8082                	ret

ffffffffc0200106 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200106:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200108:	00004517          	auipc	a0,0x4
ffffffffc020010c:	2b850513          	addi	a0,a0,696 # ffffffffc02043c0 <etext+0x5a>
void print_kerninfo(void) {
ffffffffc0200110:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200112:	fadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200116:	00000597          	auipc	a1,0x0
ffffffffc020011a:	f2058593          	addi	a1,a1,-224 # ffffffffc0200036 <kern_init>
ffffffffc020011e:	00004517          	auipc	a0,0x4
ffffffffc0200122:	2c250513          	addi	a0,a0,706 # ffffffffc02043e0 <etext+0x7a>
ffffffffc0200126:	f99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020012a:	00004597          	auipc	a1,0x4
ffffffffc020012e:	23c58593          	addi	a1,a1,572 # ffffffffc0204366 <etext>
ffffffffc0200132:	00004517          	auipc	a0,0x4
ffffffffc0200136:	2ce50513          	addi	a0,a0,718 # ffffffffc0204400 <etext+0x9a>
ffffffffc020013a:	f85ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020013e:	0000a597          	auipc	a1,0xa
ffffffffc0200142:	f0258593          	addi	a1,a1,-254 # ffffffffc020a040 <edata>
ffffffffc0200146:	00004517          	auipc	a0,0x4
ffffffffc020014a:	2da50513          	addi	a0,a0,730 # ffffffffc0204420 <etext+0xba>
ffffffffc020014e:	f71ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200152:	00011597          	auipc	a1,0x11
ffffffffc0200156:	44658593          	addi	a1,a1,1094 # ffffffffc0211598 <end>
ffffffffc020015a:	00004517          	auipc	a0,0x4
ffffffffc020015e:	2e650513          	addi	a0,a0,742 # ffffffffc0204440 <etext+0xda>
ffffffffc0200162:	f5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200166:	00012597          	auipc	a1,0x12
ffffffffc020016a:	83158593          	addi	a1,a1,-1999 # ffffffffc0211997 <end+0x3ff>
ffffffffc020016e:	00000797          	auipc	a5,0x0
ffffffffc0200172:	ec878793          	addi	a5,a5,-312 # ffffffffc0200036 <kern_init>
ffffffffc0200176:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020017a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020017e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200180:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200184:	95be                	add	a1,a1,a5
ffffffffc0200186:	85a9                	srai	a1,a1,0xa
ffffffffc0200188:	00004517          	auipc	a0,0x4
ffffffffc020018c:	2d850513          	addi	a0,a0,728 # ffffffffc0204460 <etext+0xfa>
}
ffffffffc0200190:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200192:	f2dff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200196 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200196:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200198:	00004617          	auipc	a2,0x4
ffffffffc020019c:	1f860613          	addi	a2,a2,504 # ffffffffc0204390 <etext+0x2a>
ffffffffc02001a0:	04e00593          	li	a1,78
ffffffffc02001a4:	00004517          	auipc	a0,0x4
ffffffffc02001a8:	20450513          	addi	a0,a0,516 # ffffffffc02043a8 <etext+0x42>
void print_stackframe(void) {
ffffffffc02001ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ae:	1c6000ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02001b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001b4:	00004617          	auipc	a2,0x4
ffffffffc02001b8:	3b460613          	addi	a2,a2,948 # ffffffffc0204568 <commands+0xd8>
ffffffffc02001bc:	00004597          	auipc	a1,0x4
ffffffffc02001c0:	3cc58593          	addi	a1,a1,972 # ffffffffc0204588 <commands+0xf8>
ffffffffc02001c4:	00004517          	auipc	a0,0x4
ffffffffc02001c8:	3cc50513          	addi	a0,a0,972 # ffffffffc0204590 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ce:	ef1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001d2:	00004617          	auipc	a2,0x4
ffffffffc02001d6:	3ce60613          	addi	a2,a2,974 # ffffffffc02045a0 <commands+0x110>
ffffffffc02001da:	00004597          	auipc	a1,0x4
ffffffffc02001de:	3ee58593          	addi	a1,a1,1006 # ffffffffc02045c8 <commands+0x138>
ffffffffc02001e2:	00004517          	auipc	a0,0x4
ffffffffc02001e6:	3ae50513          	addi	a0,a0,942 # ffffffffc0204590 <commands+0x100>
ffffffffc02001ea:	ed5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001ee:	00004617          	auipc	a2,0x4
ffffffffc02001f2:	3ea60613          	addi	a2,a2,1002 # ffffffffc02045d8 <commands+0x148>
ffffffffc02001f6:	00004597          	auipc	a1,0x4
ffffffffc02001fa:	40258593          	addi	a1,a1,1026 # ffffffffc02045f8 <commands+0x168>
ffffffffc02001fe:	00004517          	auipc	a0,0x4
ffffffffc0200202:	39250513          	addi	a0,a0,914 # ffffffffc0204590 <commands+0x100>
ffffffffc0200206:	eb9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc020020a:	60a2                	ld	ra,8(sp)
ffffffffc020020c:	4501                	li	a0,0
ffffffffc020020e:	0141                	addi	sp,sp,16
ffffffffc0200210:	8082                	ret

ffffffffc0200212 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
ffffffffc0200214:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200216:	ef1ff0ef          	jal	ra,ffffffffc0200106 <print_kerninfo>
    return 0;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	0141                	addi	sp,sp,16
ffffffffc0200220:	8082                	ret

ffffffffc0200222 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	1141                	addi	sp,sp,-16
ffffffffc0200224:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200226:	f71ff0ef          	jal	ra,ffffffffc0200196 <print_stackframe>
    return 0;
}
ffffffffc020022a:	60a2                	ld	ra,8(sp)
ffffffffc020022c:	4501                	li	a0,0
ffffffffc020022e:	0141                	addi	sp,sp,16
ffffffffc0200230:	8082                	ret

ffffffffc0200232 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200232:	7115                	addi	sp,sp,-224
ffffffffc0200234:	e962                	sd	s8,144(sp)
ffffffffc0200236:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200238:	00004517          	auipc	a0,0x4
ffffffffc020023c:	2a050513          	addi	a0,a0,672 # ffffffffc02044d8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200240:	ed86                	sd	ra,216(sp)
ffffffffc0200242:	e9a2                	sd	s0,208(sp)
ffffffffc0200244:	e5a6                	sd	s1,200(sp)
ffffffffc0200246:	e1ca                	sd	s2,192(sp)
ffffffffc0200248:	fd4e                	sd	s3,184(sp)
ffffffffc020024a:	f952                	sd	s4,176(sp)
ffffffffc020024c:	f556                	sd	s5,168(sp)
ffffffffc020024e:	f15a                	sd	s6,160(sp)
ffffffffc0200250:	ed5e                	sd	s7,152(sp)
ffffffffc0200252:	e566                	sd	s9,136(sp)
ffffffffc0200254:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200256:	e69ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	2a650513          	addi	a0,a0,678 # ffffffffc0204500 <commands+0x70>
ffffffffc0200262:	e5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc0200266:	000c0563          	beqz	s8,ffffffffc0200270 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020026a:	8562                	mv	a0,s8
ffffffffc020026c:	4f2000ef          	jal	ra,ffffffffc020075e <print_trapframe>
ffffffffc0200270:	00004c97          	auipc	s9,0x4
ffffffffc0200274:	220c8c93          	addi	s9,s9,544 # ffffffffc0204490 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc0200278:	00005997          	auipc	s3,0x5
ffffffffc020027c:	7e098993          	addi	s3,s3,2016 # ffffffffc0205a58 <default_pmm_manager+0x9c0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200280:	00004917          	auipc	s2,0x4
ffffffffc0200284:	2a890913          	addi	s2,s2,680 # ffffffffc0204528 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc0200288:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020028a:	00004b17          	auipc	s6,0x4
ffffffffc020028e:	2a6b0b13          	addi	s6,s6,678 # ffffffffc0204530 <commands+0xa0>
    if (argc == 0) {
ffffffffc0200292:	00004a97          	auipc	s5,0x4
ffffffffc0200296:	2f6a8a93          	addi	s5,s5,758 # ffffffffc0204588 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020029a:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc020029c:	854e                	mv	a0,s3
ffffffffc020029e:	743030ef          	jal	ra,ffffffffc02041e0 <readline>
ffffffffc02002a2:	842a                	mv	s0,a0
ffffffffc02002a4:	dd65                	beqz	a0,ffffffffc020029c <kmonitor+0x6a>
ffffffffc02002a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002aa:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002ac:	c999                	beqz	a1,ffffffffc02002c2 <kmonitor+0x90>
ffffffffc02002ae:	854a                	mv	a0,s2
ffffffffc02002b0:	06e040ef          	jal	ra,ffffffffc020431e <strchr>
ffffffffc02002b4:	c925                	beqz	a0,ffffffffc0200324 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002b6:	00144583          	lbu	a1,1(s0)
ffffffffc02002ba:	00040023          	sb	zero,0(s0)
ffffffffc02002be:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002c0:	f5fd                	bnez	a1,ffffffffc02002ae <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002c2:	dce9                	beqz	s1,ffffffffc020029c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002c4:	6582                	ld	a1,0(sp)
ffffffffc02002c6:	00004d17          	auipc	s10,0x4
ffffffffc02002ca:	1cad0d13          	addi	s10,s10,458 # ffffffffc0204490 <commands>
    if (argc == 0) {
ffffffffc02002ce:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002d2:	0d61                	addi	s10,s10,24
ffffffffc02002d4:	020040ef          	jal	ra,ffffffffc02042f4 <strcmp>
ffffffffc02002d8:	c919                	beqz	a0,ffffffffc02002ee <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002da:	2405                	addiw	s0,s0,1
ffffffffc02002dc:	09740463          	beq	s0,s7,ffffffffc0200364 <kmonitor+0x132>
ffffffffc02002e0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	0d61                	addi	s10,s10,24
ffffffffc02002e8:	00c040ef          	jal	ra,ffffffffc02042f4 <strcmp>
ffffffffc02002ec:	f57d                	bnez	a0,ffffffffc02002da <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02002ee:	00141793          	slli	a5,s0,0x1
ffffffffc02002f2:	97a2                	add	a5,a5,s0
ffffffffc02002f4:	078e                	slli	a5,a5,0x3
ffffffffc02002f6:	97e6                	add	a5,a5,s9
ffffffffc02002f8:	6b9c                	ld	a5,16(a5)
ffffffffc02002fa:	8662                	mv	a2,s8
ffffffffc02002fc:	002c                	addi	a1,sp,8
ffffffffc02002fe:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200302:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200304:	f8055ce3          	bgez	a0,ffffffffc020029c <kmonitor+0x6a>
}
ffffffffc0200308:	60ee                	ld	ra,216(sp)
ffffffffc020030a:	644e                	ld	s0,208(sp)
ffffffffc020030c:	64ae                	ld	s1,200(sp)
ffffffffc020030e:	690e                	ld	s2,192(sp)
ffffffffc0200310:	79ea                	ld	s3,184(sp)
ffffffffc0200312:	7a4a                	ld	s4,176(sp)
ffffffffc0200314:	7aaa                	ld	s5,168(sp)
ffffffffc0200316:	7b0a                	ld	s6,160(sp)
ffffffffc0200318:	6bea                	ld	s7,152(sp)
ffffffffc020031a:	6c4a                	ld	s8,144(sp)
ffffffffc020031c:	6caa                	ld	s9,136(sp)
ffffffffc020031e:	6d0a                	ld	s10,128(sp)
ffffffffc0200320:	612d                	addi	sp,sp,224
ffffffffc0200322:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200324:	00044783          	lbu	a5,0(s0)
ffffffffc0200328:	dfc9                	beqz	a5,ffffffffc02002c2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020032a:	03448863          	beq	s1,s4,ffffffffc020035a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020032e:	00349793          	slli	a5,s1,0x3
ffffffffc0200332:	0118                	addi	a4,sp,128
ffffffffc0200334:	97ba                	add	a5,a5,a4
ffffffffc0200336:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020033a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020033e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200340:	e591                	bnez	a1,ffffffffc020034c <kmonitor+0x11a>
ffffffffc0200342:	b749                	j	ffffffffc02002c4 <kmonitor+0x92>
            buf ++;
ffffffffc0200344:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200346:	00044583          	lbu	a1,0(s0)
ffffffffc020034a:	ddad                	beqz	a1,ffffffffc02002c4 <kmonitor+0x92>
ffffffffc020034c:	854a                	mv	a0,s2
ffffffffc020034e:	7d1030ef          	jal	ra,ffffffffc020431e <strchr>
ffffffffc0200352:	d96d                	beqz	a0,ffffffffc0200344 <kmonitor+0x112>
ffffffffc0200354:	00044583          	lbu	a1,0(s0)
ffffffffc0200358:	bf91                	j	ffffffffc02002ac <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020035a:	45c1                	li	a1,16
ffffffffc020035c:	855a                	mv	a0,s6
ffffffffc020035e:	d61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0200362:	b7f1                	j	ffffffffc020032e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200364:	6582                	ld	a1,0(sp)
ffffffffc0200366:	00004517          	auipc	a0,0x4
ffffffffc020036a:	1ea50513          	addi	a0,a0,490 # ffffffffc0204550 <commands+0xc0>
ffffffffc020036e:	d51ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc0200372:	b72d                	j	ffffffffc020029c <kmonitor+0x6a>

ffffffffc0200374 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200374:	00011317          	auipc	t1,0x11
ffffffffc0200378:	0cc30313          	addi	t1,t1,204 # ffffffffc0211440 <is_panic>
ffffffffc020037c:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200380:	715d                	addi	sp,sp,-80
ffffffffc0200382:	ec06                	sd	ra,24(sp)
ffffffffc0200384:	e822                	sd	s0,16(sp)
ffffffffc0200386:	f436                	sd	a3,40(sp)
ffffffffc0200388:	f83a                	sd	a4,48(sp)
ffffffffc020038a:	fc3e                	sd	a5,56(sp)
ffffffffc020038c:	e0c2                	sd	a6,64(sp)
ffffffffc020038e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200390:	02031c63          	bnez	t1,ffffffffc02003c8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200394:	4785                	li	a5,1
ffffffffc0200396:	8432                	mv	s0,a2
ffffffffc0200398:	00011717          	auipc	a4,0x11
ffffffffc020039c:	0af72423          	sw	a5,168(a4) # ffffffffc0211440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a4:	85aa                	mv	a1,a0
ffffffffc02003a6:	00004517          	auipc	a0,0x4
ffffffffc02003aa:	26250513          	addi	a0,a0,610 # ffffffffc0204608 <commands+0x178>
    va_start(ap, fmt);
ffffffffc02003ae:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003b0:	d0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003b4:	65a2                	ld	a1,8(sp)
ffffffffc02003b6:	8522                	mv	a0,s0
ffffffffc02003b8:	ce7ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc02003bc:	00005517          	auipc	a0,0x5
ffffffffc02003c0:	1cc50513          	addi	a0,a0,460 # ffffffffc0205588 <default_pmm_manager+0x4f0>
ffffffffc02003c4:	cfbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003c8:	132000ef          	jal	ra,ffffffffc02004fa <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003cc:	4501                	li	a0,0
ffffffffc02003ce:	e65ff0ef          	jal	ra,ffffffffc0200232 <kmonitor>
ffffffffc02003d2:	bfed                	j	ffffffffc02003cc <__panic+0x58>

ffffffffc02003d4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02003d4:	67e1                	lui	a5,0x18
ffffffffc02003d6:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc02003da:	00011717          	auipc	a4,0x11
ffffffffc02003de:	06f73723          	sd	a5,110(a4) # ffffffffc0211448 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003e2:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02003e6:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003e8:	953e                	add	a0,a0,a5
ffffffffc02003ea:	4601                	li	a2,0
ffffffffc02003ec:	4881                	li	a7,0
ffffffffc02003ee:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02003f2:	02000793          	li	a5,32
ffffffffc02003f6:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02003fa:	00004517          	auipc	a0,0x4
ffffffffc02003fe:	22e50513          	addi	a0,a0,558 # ffffffffc0204628 <commands+0x198>
    ticks = 0;
ffffffffc0200402:	00011797          	auipc	a5,0x11
ffffffffc0200406:	0607b723          	sd	zero,110(a5) # ffffffffc0211470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020040a:	cb5ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020040e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020040e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200412:	00011797          	auipc	a5,0x11
ffffffffc0200416:	03678793          	addi	a5,a5,54 # ffffffffc0211448 <timebase>
ffffffffc020041a:	639c                	ld	a5,0(a5)
ffffffffc020041c:	4581                	li	a1,0
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	953e                	add	a0,a0,a5
ffffffffc0200422:	4881                	li	a7,0
ffffffffc0200424:	00000073          	ecall
ffffffffc0200428:	8082                	ret

ffffffffc020042a <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020042a:	100027f3          	csrr	a5,sstatus
ffffffffc020042e:	8b89                	andi	a5,a5,2
ffffffffc0200430:	0ff57513          	andi	a0,a0,255
ffffffffc0200434:	e799                	bnez	a5,ffffffffc0200442 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200436:	4581                	li	a1,0
ffffffffc0200438:	4601                	li	a2,0
ffffffffc020043a:	4885                	li	a7,1
ffffffffc020043c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200440:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200442:	1101                	addi	sp,sp,-32
ffffffffc0200444:	ec06                	sd	ra,24(sp)
ffffffffc0200446:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200448:	0b2000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc020044c:	6522                	ld	a0,8(sp)
ffffffffc020044e:	4581                	li	a1,0
ffffffffc0200450:	4601                	li	a2,0
ffffffffc0200452:	4885                	li	a7,1
ffffffffc0200454:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200458:	60e2                	ld	ra,24(sp)
ffffffffc020045a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020045c:	0980006f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc0200460 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200460:	100027f3          	csrr	a5,sstatus
ffffffffc0200464:	8b89                	andi	a5,a5,2
ffffffffc0200466:	eb89                	bnez	a5,ffffffffc0200478 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200468:	4501                	li	a0,0
ffffffffc020046a:	4581                	li	a1,0
ffffffffc020046c:	4601                	li	a2,0
ffffffffc020046e:	4889                	li	a7,2
ffffffffc0200470:	00000073          	ecall
ffffffffc0200474:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200476:	8082                	ret
int cons_getc(void) {
ffffffffc0200478:	1101                	addi	sp,sp,-32
ffffffffc020047a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020047c:	07e000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc0200480:	4501                	li	a0,0
ffffffffc0200482:	4581                	li	a1,0
ffffffffc0200484:	4601                	li	a2,0
ffffffffc0200486:	4889                	li	a7,2
ffffffffc0200488:	00000073          	ecall
ffffffffc020048c:	2501                	sext.w	a0,a0
ffffffffc020048e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200490:	064000ef          	jal	ra,ffffffffc02004f4 <intr_enable>
}
ffffffffc0200494:	60e2                	ld	ra,24(sp)
ffffffffc0200496:	6522                	ld	a0,8(sp)
ffffffffc0200498:	6105                	addi	sp,sp,32
ffffffffc020049a:	8082                	ret

ffffffffc020049c <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc020049c:	8082                	ret

ffffffffc020049e <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc020049e:	00253513          	sltiu	a0,a0,2
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004a4:	03800513          	li	a0,56
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_read_secs>:
int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs)
{
    // ideno: 假设挂载了多块磁盘，选择哪一块磁盘 这里我们其实只有一块“磁盘”，这个参数就没用到
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004aa:	0000a797          	auipc	a5,0xa
ffffffffc02004ae:	b9678793          	addi	a5,a5,-1130 # ffffffffc020a040 <edata>
ffffffffc02004b2:	0095959b          	slliw	a1,a1,0x9
{
ffffffffc02004b6:	1141                	addi	sp,sp,-16
ffffffffc02004b8:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004ba:	95be                	add	a1,a1,a5
ffffffffc02004bc:	00969613          	slli	a2,a3,0x9
{
ffffffffc02004c0:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c2:	68d030ef          	jal	ra,ffffffffc020434e <memcpy>
    return 0;
}
ffffffffc02004c6:	60a2                	ld	ra,8(sp)
ffffffffc02004c8:	4501                	li	a0,0
ffffffffc02004ca:	0141                	addi	sp,sp,16
ffffffffc02004cc:	8082                	ret

ffffffffc02004ce <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs)
{
ffffffffc02004ce:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d0:	0095979b          	slliw	a5,a1,0x9
ffffffffc02004d4:	0000a517          	auipc	a0,0xa
ffffffffc02004d8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc020a040 <edata>
{
ffffffffc02004dc:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004de:	00969613          	slli	a2,a3,0x9
ffffffffc02004e2:	85ba                	mv	a1,a4
ffffffffc02004e4:	953e                	add	a0,a0,a5
{
ffffffffc02004e6:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e8:	667030ef          	jal	ra,ffffffffc020434e <memcpy>
    return 0;
}
ffffffffc02004ec:	60a2                	ld	ra,8(sp)
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	0141                	addi	sp,sp,16
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004f4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004f8:	8082                	ret

ffffffffc02004fa <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004fa:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004fe:	8082                	ret

ffffffffc0200500 <pgfault_handler>:
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf)
{
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200500:	10053783          	ld	a5,256(a0)
            trap_in_kernel(tf) ? 'K' : 'U',                   // 打印是用户态的trap还是内核态的trap
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R'); // 读还是写
}

static int pgfault_handler(struct trapframe *tf)
{
ffffffffc0200504:	1141                	addi	sp,sp,-16
ffffffffc0200506:	e022                	sd	s0,0(sp)
ffffffffc0200508:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020050a:	1007f793          	andi	a5,a5,256
{
ffffffffc020050e:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200510:	11053583          	ld	a1,272(a0)
ffffffffc0200514:	05500613          	li	a2,85
ffffffffc0200518:	c399                	beqz	a5,ffffffffc020051e <pgfault_handler+0x1e>
ffffffffc020051a:	04b00613          	li	a2,75
ffffffffc020051e:	11843703          	ld	a4,280(s0)
ffffffffc0200522:	47bd                	li	a5,15
ffffffffc0200524:	05700693          	li	a3,87
ffffffffc0200528:	00f70463          	beq	a4,a5,ffffffffc0200530 <pgfault_handler+0x30>
ffffffffc020052c:	05200693          	li	a3,82
ffffffffc0200530:	00004517          	auipc	a0,0x4
ffffffffc0200534:	3f050513          	addi	a0,a0,1008 # ffffffffc0204920 <commands+0x490>
ffffffffc0200538:	b87ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL)
ffffffffc020053c:	00011797          	auipc	a5,0x11
ffffffffc0200540:	05478793          	addi	a5,a5,84 # ffffffffc0211590 <check_mm_struct>
ffffffffc0200544:	6388                	ld	a0,0(a5)
ffffffffc0200546:	c911                	beqz	a0,ffffffffc020055a <pgfault_handler+0x5a>
    {
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200548:	11043603          	ld	a2,272(s0)
ffffffffc020054c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200550:	6402                	ld	s0,0(sp)
ffffffffc0200552:	60a2                	ld	ra,8(sp)
ffffffffc0200554:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200556:	63a0306f          	j	ffffffffc0203b90 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020055a:	00004617          	auipc	a2,0x4
ffffffffc020055e:	3e660613          	addi	a2,a2,998 # ffffffffc0204940 <commands+0x4b0>
ffffffffc0200562:	08000593          	li	a1,128
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	3f250513          	addi	a0,a0,1010 # ffffffffc0204958 <commands+0x4c8>
ffffffffc020056e:	e07ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0200572 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200572:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200576:	00000797          	auipc	a5,0x0
ffffffffc020057a:	49a78793          	addi	a5,a5,1178 # ffffffffc0200a10 <__alltraps>
ffffffffc020057e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200582:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200586:	000407b7          	lui	a5,0x40
ffffffffc020058a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020058e:	8082                	ret

ffffffffc0200590 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200590:	610c                	ld	a1,0(a0)
{
ffffffffc0200592:	1141                	addi	sp,sp,-16
ffffffffc0200594:	e022                	sd	s0,0(sp)
ffffffffc0200596:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200598:	00004517          	auipc	a0,0x4
ffffffffc020059c:	3d850513          	addi	a0,a0,984 # ffffffffc0204970 <commands+0x4e0>
{
ffffffffc02005a0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02005a2:	b1dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02005a6:	640c                	ld	a1,8(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	3e050513          	addi	a0,a0,992 # ffffffffc0204988 <commands+0x4f8>
ffffffffc02005b0:	b0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005b4:	680c                	ld	a1,16(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	3ea50513          	addi	a0,a0,1002 # ffffffffc02049a0 <commands+0x510>
ffffffffc02005be:	b01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005c2:	6c0c                	ld	a1,24(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	3f450513          	addi	a0,a0,1012 # ffffffffc02049b8 <commands+0x528>
ffffffffc02005cc:	af3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005d0:	700c                	ld	a1,32(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	3fe50513          	addi	a0,a0,1022 # ffffffffc02049d0 <commands+0x540>
ffffffffc02005da:	ae5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005de:	740c                	ld	a1,40(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	40850513          	addi	a0,a0,1032 # ffffffffc02049e8 <commands+0x558>
ffffffffc02005e8:	ad7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005ec:	780c                	ld	a1,48(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	41250513          	addi	a0,a0,1042 # ffffffffc0204a00 <commands+0x570>
ffffffffc02005f6:	ac9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005fa:	7c0c                	ld	a1,56(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	41c50513          	addi	a0,a0,1052 # ffffffffc0204a18 <commands+0x588>
ffffffffc0200604:	abbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200608:	602c                	ld	a1,64(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	42650513          	addi	a0,a0,1062 # ffffffffc0204a30 <commands+0x5a0>
ffffffffc0200612:	aadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200616:	642c                	ld	a1,72(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	43050513          	addi	a0,a0,1072 # ffffffffc0204a48 <commands+0x5b8>
ffffffffc0200620:	a9fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200624:	682c                	ld	a1,80(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	43a50513          	addi	a0,a0,1082 # ffffffffc0204a60 <commands+0x5d0>
ffffffffc020062e:	a91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200632:	6c2c                	ld	a1,88(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	44450513          	addi	a0,a0,1092 # ffffffffc0204a78 <commands+0x5e8>
ffffffffc020063c:	a83ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200640:	702c                	ld	a1,96(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	44e50513          	addi	a0,a0,1102 # ffffffffc0204a90 <commands+0x600>
ffffffffc020064a:	a75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020064e:	742c                	ld	a1,104(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	45850513          	addi	a0,a0,1112 # ffffffffc0204aa8 <commands+0x618>
ffffffffc0200658:	a67ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020065c:	782c                	ld	a1,112(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	46250513          	addi	a0,a0,1122 # ffffffffc0204ac0 <commands+0x630>
ffffffffc0200666:	a59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020066a:	7c2c                	ld	a1,120(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	46c50513          	addi	a0,a0,1132 # ffffffffc0204ad8 <commands+0x648>
ffffffffc0200674:	a4bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200678:	604c                	ld	a1,128(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	47650513          	addi	a0,a0,1142 # ffffffffc0204af0 <commands+0x660>
ffffffffc0200682:	a3dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200686:	644c                	ld	a1,136(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	48050513          	addi	a0,a0,1152 # ffffffffc0204b08 <commands+0x678>
ffffffffc0200690:	a2fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200694:	684c                	ld	a1,144(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	48a50513          	addi	a0,a0,1162 # ffffffffc0204b20 <commands+0x690>
ffffffffc020069e:	a21ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02006a2:	6c4c                	ld	a1,152(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	49450513          	addi	a0,a0,1172 # ffffffffc0204b38 <commands+0x6a8>
ffffffffc02006ac:	a13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006b0:	704c                	ld	a1,160(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	49e50513          	addi	a0,a0,1182 # ffffffffc0204b50 <commands+0x6c0>
ffffffffc02006ba:	a05ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006be:	744c                	ld	a1,168(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	4a850513          	addi	a0,a0,1192 # ffffffffc0204b68 <commands+0x6d8>
ffffffffc02006c8:	9f7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006cc:	784c                	ld	a1,176(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	4b250513          	addi	a0,a0,1202 # ffffffffc0204b80 <commands+0x6f0>
ffffffffc02006d6:	9e9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006da:	7c4c                	ld	a1,184(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204b98 <commands+0x708>
ffffffffc02006e4:	9dbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e8:	606c                	ld	a1,192(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	4c650513          	addi	a0,a0,1222 # ffffffffc0204bb0 <commands+0x720>
ffffffffc02006f2:	9cdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006f6:	646c                	ld	a1,200(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	4d050513          	addi	a0,a0,1232 # ffffffffc0204bc8 <commands+0x738>
ffffffffc0200700:	9bfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200704:	686c                	ld	a1,208(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	4da50513          	addi	a0,a0,1242 # ffffffffc0204be0 <commands+0x750>
ffffffffc020070e:	9b1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200712:	6c6c                	ld	a1,216(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	4e450513          	addi	a0,a0,1252 # ffffffffc0204bf8 <commands+0x768>
ffffffffc020071c:	9a3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200720:	706c                	ld	a1,224(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	4ee50513          	addi	a0,a0,1262 # ffffffffc0204c10 <commands+0x780>
ffffffffc020072a:	995ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020072e:	746c                	ld	a1,232(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	4f850513          	addi	a0,a0,1272 # ffffffffc0204c28 <commands+0x798>
ffffffffc0200738:	987ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020073c:	786c                	ld	a1,240(s0)
ffffffffc020073e:	00004517          	auipc	a0,0x4
ffffffffc0200742:	50250513          	addi	a0,a0,1282 # ffffffffc0204c40 <commands+0x7b0>
ffffffffc0200746:	979ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020074c:	6402                	ld	s0,0(sp)
ffffffffc020074e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200750:	00004517          	auipc	a0,0x4
ffffffffc0200754:	50850513          	addi	a0,a0,1288 # ffffffffc0204c58 <commands+0x7c8>
}
ffffffffc0200758:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020075a:	965ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020075e <print_trapframe>:
{
ffffffffc020075e:	1141                	addi	sp,sp,-16
ffffffffc0200760:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200762:	85aa                	mv	a1,a0
{
ffffffffc0200764:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200766:	00004517          	auipc	a0,0x4
ffffffffc020076a:	50a50513          	addi	a0,a0,1290 # ffffffffc0204c70 <commands+0x7e0>
{
ffffffffc020076e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200770:	94fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200774:	8522                	mv	a0,s0
ffffffffc0200776:	e1bff0ef          	jal	ra,ffffffffc0200590 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020077a:	10043583          	ld	a1,256(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	50a50513          	addi	a0,a0,1290 # ffffffffc0204c88 <commands+0x7f8>
ffffffffc0200786:	939ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020078a:	10843583          	ld	a1,264(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	51250513          	addi	a0,a0,1298 # ffffffffc0204ca0 <commands+0x810>
ffffffffc0200796:	929ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020079a:	11043583          	ld	a1,272(s0)
ffffffffc020079e:	00004517          	auipc	a0,0x4
ffffffffc02007a2:	51a50513          	addi	a0,a0,1306 # ffffffffc0204cb8 <commands+0x828>
ffffffffc02007a6:	919ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007aa:	11843583          	ld	a1,280(s0)
}
ffffffffc02007ae:	6402                	ld	s0,0(sp)
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007b2:	00004517          	auipc	a0,0x4
ffffffffc02007b6:	51e50513          	addi	a0,a0,1310 # ffffffffc0204cd0 <commands+0x840>
}
ffffffffc02007ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007bc:	903ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02007c0 <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007c0:	11853783          	ld	a5,280(a0)
ffffffffc02007c4:	577d                	li	a4,-1
ffffffffc02007c6:	8305                	srli	a4,a4,0x1
ffffffffc02007c8:	8ff9                	and	a5,a5,a4
    switch (cause)
ffffffffc02007ca:	472d                	li	a4,11
ffffffffc02007cc:	06f76f63          	bltu	a4,a5,ffffffffc020084a <interrupt_handler+0x8a>
ffffffffc02007d0:	00004717          	auipc	a4,0x4
ffffffffc02007d4:	e7470713          	addi	a4,a4,-396 # ffffffffc0204644 <commands+0x1b4>
ffffffffc02007d8:	078a                	slli	a5,a5,0x2
ffffffffc02007da:	97ba                	add	a5,a5,a4
ffffffffc02007dc:	439c                	lw	a5,0(a5)
ffffffffc02007de:	97ba                	add	a5,a5,a4
ffffffffc02007e0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	0ee50513          	addi	a0,a0,238 # ffffffffc02048d0 <commands+0x440>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	0c250513          	addi	a0,a0,194 # ffffffffc02048b0 <commands+0x420>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	07650513          	addi	a0,a0,118 # ffffffffc0204870 <commands+0x3e0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	08a50513          	addi	a0,a0,138 # ffffffffc0204890 <commands+0x400>
ffffffffc020080e:	8b1ff06f          	j	ffffffffc02000be <cprintf>
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
ffffffffc0200812:	00004517          	auipc	a0,0x4
ffffffffc0200816:	0ee50513          	addi	a0,a0,238 # ffffffffc0204900 <commands+0x470>
ffffffffc020081a:	8a5ff06f          	j	ffffffffc02000be <cprintf>
{
ffffffffc020081e:	1141                	addi	sp,sp,-16
ffffffffc0200820:	e406                	sd	ra,8(sp)
        clock_set_next_event();
ffffffffc0200822:	bedff0ef          	jal	ra,ffffffffc020040e <clock_set_next_event>
        if (++ticks % TICK_NUM == 0)
ffffffffc0200826:	00011797          	auipc	a5,0x11
ffffffffc020082a:	c4a78793          	addi	a5,a5,-950 # ffffffffc0211470 <ticks>
ffffffffc020082e:	639c                	ld	a5,0(a5)
ffffffffc0200830:	06400713          	li	a4,100
ffffffffc0200834:	0785                	addi	a5,a5,1
ffffffffc0200836:	02e7f733          	remu	a4,a5,a4
ffffffffc020083a:	00011697          	auipc	a3,0x11
ffffffffc020083e:	c2f6bb23          	sd	a5,-970(a3) # ffffffffc0211470 <ticks>
ffffffffc0200842:	c711                	beqz	a4,ffffffffc020084e <interrupt_handler+0x8e>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200844:	60a2                	ld	ra,8(sp)
ffffffffc0200846:	0141                	addi	sp,sp,16
ffffffffc0200848:	8082                	ret
        print_trapframe(tf);
ffffffffc020084a:	f15ff06f          	j	ffffffffc020075e <print_trapframe>
}
ffffffffc020084e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200850:	06400593          	li	a1,100
ffffffffc0200854:	00004517          	auipc	a0,0x4
ffffffffc0200858:	09c50513          	addi	a0,a0,156 # ffffffffc02048f0 <commands+0x460>
}
ffffffffc020085c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020085e:	861ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200862 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200862:	11853783          	ld	a5,280(a0)
ffffffffc0200866:	473d                	li	a4,15
ffffffffc0200868:	16f76563          	bltu	a4,a5,ffffffffc02009d2 <exception_handler+0x170>
ffffffffc020086c:	00004717          	auipc	a4,0x4
ffffffffc0200870:	e0870713          	addi	a4,a4,-504 # ffffffffc0204674 <commands+0x1e4>
ffffffffc0200874:	078a                	slli	a5,a5,0x2
ffffffffc0200876:	97ba                	add	a5,a5,a4
ffffffffc0200878:	439c                	lw	a5,0(a5)
{
ffffffffc020087a:	1101                	addi	sp,sp,-32
ffffffffc020087c:	e822                	sd	s0,16(sp)
ffffffffc020087e:	ec06                	sd	ra,24(sp)
ffffffffc0200880:	e426                	sd	s1,8(sp)
    switch (tf->cause)
ffffffffc0200882:	97ba                	add	a5,a5,a4
ffffffffc0200884:	842a                	mv	s0,a0
ffffffffc0200886:	8782                	jr	a5
            print_trapframe(tf);
            panic("handle pgfault failed. %e\n", ret);
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200888:	00004517          	auipc	a0,0x4
ffffffffc020088c:	fd050513          	addi	a0,a0,-48 # ffffffffc0204858 <commands+0x3c8>
ffffffffc0200890:	82fff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200894:	8522                	mv	a0,s0
ffffffffc0200896:	c6bff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc020089a:	84aa                	mv	s1,a0
ffffffffc020089c:	12051d63          	bnez	a0,ffffffffc02009d6 <exception_handler+0x174>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc02008a0:	60e2                	ld	ra,24(sp)
ffffffffc02008a2:	6442                	ld	s0,16(sp)
ffffffffc02008a4:	64a2                	ld	s1,8(sp)
ffffffffc02008a6:	6105                	addi	sp,sp,32
ffffffffc02008a8:	8082                	ret
        cprintf("Instruction address misaligned\n");
ffffffffc02008aa:	00004517          	auipc	a0,0x4
ffffffffc02008ae:	e0e50513          	addi	a0,a0,-498 # ffffffffc02046b8 <commands+0x228>
}
ffffffffc02008b2:	6442                	ld	s0,16(sp)
ffffffffc02008b4:	60e2                	ld	ra,24(sp)
ffffffffc02008b6:	64a2                	ld	s1,8(sp)
ffffffffc02008b8:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc02008ba:	805ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008be:	00004517          	auipc	a0,0x4
ffffffffc02008c2:	e1a50513          	addi	a0,a0,-486 # ffffffffc02046d8 <commands+0x248>
ffffffffc02008c6:	b7f5                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Illegal instruction\n");
ffffffffc02008c8:	00004517          	auipc	a0,0x4
ffffffffc02008cc:	e3050513          	addi	a0,a0,-464 # ffffffffc02046f8 <commands+0x268>
ffffffffc02008d0:	b7cd                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Breakpoint\n");
ffffffffc02008d2:	00004517          	auipc	a0,0x4
ffffffffc02008d6:	e3e50513          	addi	a0,a0,-450 # ffffffffc0204710 <commands+0x280>
ffffffffc02008da:	bfe1                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Load address misaligned\n");
ffffffffc02008dc:	00004517          	auipc	a0,0x4
ffffffffc02008e0:	e4450513          	addi	a0,a0,-444 # ffffffffc0204720 <commands+0x290>
ffffffffc02008e4:	b7f9                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Load access fault\n");
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	e5a50513          	addi	a0,a0,-422 # ffffffffc0204740 <commands+0x2b0>
ffffffffc02008ee:	fd0ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc02008f2:	8522                	mv	a0,s0
ffffffffc02008f4:	c0dff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02008f8:	84aa                	mv	s1,a0
ffffffffc02008fa:	d15d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc02008fc:	8522                	mv	a0,s0
ffffffffc02008fe:	e61ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200902:	86a6                	mv	a3,s1
ffffffffc0200904:	00004617          	auipc	a2,0x4
ffffffffc0200908:	e5460613          	addi	a2,a2,-428 # ffffffffc0204758 <commands+0x2c8>
ffffffffc020090c:	0d700593          	li	a1,215
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	04850513          	addi	a0,a0,72 # ffffffffc0204958 <commands+0x4c8>
ffffffffc0200918:	a5dff0ef          	jal	ra,ffffffffc0200374 <__panic>
        cprintf("AMO address misaligned\n");
ffffffffc020091c:	00004517          	auipc	a0,0x4
ffffffffc0200920:	e5c50513          	addi	a0,a0,-420 # ffffffffc0204778 <commands+0x2e8>
ffffffffc0200924:	b779                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Store/AMO access fault\n");
ffffffffc0200926:	00004517          	auipc	a0,0x4
ffffffffc020092a:	e6a50513          	addi	a0,a0,-406 # ffffffffc0204790 <commands+0x300>
ffffffffc020092e:	f90ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200932:	8522                	mv	a0,s0
ffffffffc0200934:	bcdff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc0200938:	84aa                	mv	s1,a0
ffffffffc020093a:	d13d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc020093c:	8522                	mv	a0,s0
ffffffffc020093e:	e21ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200942:	86a6                	mv	a3,s1
ffffffffc0200944:	00004617          	auipc	a2,0x4
ffffffffc0200948:	e1460613          	addi	a2,a2,-492 # ffffffffc0204758 <commands+0x2c8>
ffffffffc020094c:	0e200593          	li	a1,226
ffffffffc0200950:	00004517          	auipc	a0,0x4
ffffffffc0200954:	00850513          	addi	a0,a0,8 # ffffffffc0204958 <commands+0x4c8>
ffffffffc0200958:	a1dff0ef          	jal	ra,ffffffffc0200374 <__panic>
        cprintf("Environment call from U-mode\n");
ffffffffc020095c:	00004517          	auipc	a0,0x4
ffffffffc0200960:	e4c50513          	addi	a0,a0,-436 # ffffffffc02047a8 <commands+0x318>
ffffffffc0200964:	b7b9                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Environment call from S-mode\n");
ffffffffc0200966:	00004517          	auipc	a0,0x4
ffffffffc020096a:	e6250513          	addi	a0,a0,-414 # ffffffffc02047c8 <commands+0x338>
ffffffffc020096e:	b791                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Environment call from H-mode\n");
ffffffffc0200970:	00004517          	auipc	a0,0x4
ffffffffc0200974:	e7850513          	addi	a0,a0,-392 # ffffffffc02047e8 <commands+0x358>
ffffffffc0200978:	bf2d                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Environment call from M-mode\n");
ffffffffc020097a:	00004517          	auipc	a0,0x4
ffffffffc020097e:	e8e50513          	addi	a0,a0,-370 # ffffffffc0204808 <commands+0x378>
ffffffffc0200982:	bf05                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Instruction page fault\n");
ffffffffc0200984:	00004517          	auipc	a0,0x4
ffffffffc0200988:	ea450513          	addi	a0,a0,-348 # ffffffffc0204828 <commands+0x398>
ffffffffc020098c:	b71d                	j	ffffffffc02008b2 <exception_handler+0x50>
        cprintf("Load page fault\n");
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	eb250513          	addi	a0,a0,-334 # ffffffffc0204840 <commands+0x3b0>
ffffffffc0200996:	f28ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc020099a:	8522                	mv	a0,s0
ffffffffc020099c:	b65ff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02009a0:	84aa                	mv	s1,a0
ffffffffc02009a2:	ee050fe3          	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc02009a6:	8522                	mv	a0,s0
ffffffffc02009a8:	db7ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ac:	86a6                	mv	a3,s1
ffffffffc02009ae:	00004617          	auipc	a2,0x4
ffffffffc02009b2:	daa60613          	addi	a2,a2,-598 # ffffffffc0204758 <commands+0x2c8>
ffffffffc02009b6:	0fa00593          	li	a1,250
ffffffffc02009ba:	00004517          	auipc	a0,0x4
ffffffffc02009be:	f9e50513          	addi	a0,a0,-98 # ffffffffc0204958 <commands+0x4c8>
ffffffffc02009c2:	9b3ff0ef          	jal	ra,ffffffffc0200374 <__panic>
}
ffffffffc02009c6:	6442                	ld	s0,16(sp)
ffffffffc02009c8:	60e2                	ld	ra,24(sp)
ffffffffc02009ca:	64a2                	ld	s1,8(sp)
ffffffffc02009cc:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc02009ce:	d91ff06f          	j	ffffffffc020075e <print_trapframe>
ffffffffc02009d2:	d8dff06f          	j	ffffffffc020075e <print_trapframe>
            print_trapframe(tf);
ffffffffc02009d6:	8522                	mv	a0,s0
ffffffffc02009d8:	d87ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc02009dc:	86a6                	mv	a3,s1
ffffffffc02009de:	00004617          	auipc	a2,0x4
ffffffffc02009e2:	d7a60613          	addi	a2,a2,-646 # ffffffffc0204758 <commands+0x2c8>
ffffffffc02009e6:	10200593          	li	a1,258
ffffffffc02009ea:	00004517          	auipc	a0,0x4
ffffffffc02009ee:	f6e50513          	addi	a0,a0,-146 # ffffffffc0204958 <commands+0x4c8>
ffffffffc02009f2:	983ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02009f6 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc02009f6:	11853783          	ld	a5,280(a0)
ffffffffc02009fa:	0007c463          	bltz	a5,ffffffffc0200a02 <trap+0xc>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc02009fe:	e65ff06f          	j	ffffffffc0200862 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200a02:	dbfff06f          	j	ffffffffc02007c0 <interrupt_handler>
	...

ffffffffc0200a10 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200a10:	14011073          	csrw	sscratch,sp
ffffffffc0200a14:	712d                	addi	sp,sp,-288
ffffffffc0200a16:	e406                	sd	ra,8(sp)
ffffffffc0200a18:	ec0e                	sd	gp,24(sp)
ffffffffc0200a1a:	f012                	sd	tp,32(sp)
ffffffffc0200a1c:	f416                	sd	t0,40(sp)
ffffffffc0200a1e:	f81a                	sd	t1,48(sp)
ffffffffc0200a20:	fc1e                	sd	t2,56(sp)
ffffffffc0200a22:	e0a2                	sd	s0,64(sp)
ffffffffc0200a24:	e4a6                	sd	s1,72(sp)
ffffffffc0200a26:	e8aa                	sd	a0,80(sp)
ffffffffc0200a28:	ecae                	sd	a1,88(sp)
ffffffffc0200a2a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a2c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a2e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a30:	fcbe                	sd	a5,120(sp)
ffffffffc0200a32:	e142                	sd	a6,128(sp)
ffffffffc0200a34:	e546                	sd	a7,136(sp)
ffffffffc0200a36:	e94a                	sd	s2,144(sp)
ffffffffc0200a38:	ed4e                	sd	s3,152(sp)
ffffffffc0200a3a:	f152                	sd	s4,160(sp)
ffffffffc0200a3c:	f556                	sd	s5,168(sp)
ffffffffc0200a3e:	f95a                	sd	s6,176(sp)
ffffffffc0200a40:	fd5e                	sd	s7,184(sp)
ffffffffc0200a42:	e1e2                	sd	s8,192(sp)
ffffffffc0200a44:	e5e6                	sd	s9,200(sp)
ffffffffc0200a46:	e9ea                	sd	s10,208(sp)
ffffffffc0200a48:	edee                	sd	s11,216(sp)
ffffffffc0200a4a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a4c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a4e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a50:	fdfe                	sd	t6,248(sp)
ffffffffc0200a52:	14002473          	csrr	s0,sscratch
ffffffffc0200a56:	100024f3          	csrr	s1,sstatus
ffffffffc0200a5a:	14102973          	csrr	s2,sepc
ffffffffc0200a5e:	143029f3          	csrr	s3,stval
ffffffffc0200a62:	14202a73          	csrr	s4,scause
ffffffffc0200a66:	e822                	sd	s0,16(sp)
ffffffffc0200a68:	e226                	sd	s1,256(sp)
ffffffffc0200a6a:	e64a                	sd	s2,264(sp)
ffffffffc0200a6c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a6e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a70:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a72:	f85ff0ef          	jal	ra,ffffffffc02009f6 <trap>

ffffffffc0200a76 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a76:	6492                	ld	s1,256(sp)
ffffffffc0200a78:	6932                	ld	s2,264(sp)
ffffffffc0200a7a:	10049073          	csrw	sstatus,s1
ffffffffc0200a7e:	14191073          	csrw	sepc,s2
ffffffffc0200a82:	60a2                	ld	ra,8(sp)
ffffffffc0200a84:	61e2                	ld	gp,24(sp)
ffffffffc0200a86:	7202                	ld	tp,32(sp)
ffffffffc0200a88:	72a2                	ld	t0,40(sp)
ffffffffc0200a8a:	7342                	ld	t1,48(sp)
ffffffffc0200a8c:	73e2                	ld	t2,56(sp)
ffffffffc0200a8e:	6406                	ld	s0,64(sp)
ffffffffc0200a90:	64a6                	ld	s1,72(sp)
ffffffffc0200a92:	6546                	ld	a0,80(sp)
ffffffffc0200a94:	65e6                	ld	a1,88(sp)
ffffffffc0200a96:	7606                	ld	a2,96(sp)
ffffffffc0200a98:	76a6                	ld	a3,104(sp)
ffffffffc0200a9a:	7746                	ld	a4,112(sp)
ffffffffc0200a9c:	77e6                	ld	a5,120(sp)
ffffffffc0200a9e:	680a                	ld	a6,128(sp)
ffffffffc0200aa0:	68aa                	ld	a7,136(sp)
ffffffffc0200aa2:	694a                	ld	s2,144(sp)
ffffffffc0200aa4:	69ea                	ld	s3,152(sp)
ffffffffc0200aa6:	7a0a                	ld	s4,160(sp)
ffffffffc0200aa8:	7aaa                	ld	s5,168(sp)
ffffffffc0200aaa:	7b4a                	ld	s6,176(sp)
ffffffffc0200aac:	7bea                	ld	s7,184(sp)
ffffffffc0200aae:	6c0e                	ld	s8,192(sp)
ffffffffc0200ab0:	6cae                	ld	s9,200(sp)
ffffffffc0200ab2:	6d4e                	ld	s10,208(sp)
ffffffffc0200ab4:	6dee                	ld	s11,216(sp)
ffffffffc0200ab6:	7e0e                	ld	t3,224(sp)
ffffffffc0200ab8:	7eae                	ld	t4,232(sp)
ffffffffc0200aba:	7f4e                	ld	t5,240(sp)
ffffffffc0200abc:	7fee                	ld	t6,248(sp)
ffffffffc0200abe:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200ac0:	10200073          	sret
	...

ffffffffc0200ad0 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ad0:	00011797          	auipc	a5,0x11
ffffffffc0200ad4:	9a878793          	addi	a5,a5,-1624 # ffffffffc0211478 <free_area>
ffffffffc0200ad8:	e79c                	sd	a5,8(a5)
ffffffffc0200ada:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200adc:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ae0:	8082                	ret

ffffffffc0200ae2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ae2:	00011517          	auipc	a0,0x11
ffffffffc0200ae6:	9a656503          	lwu	a0,-1626(a0) # ffffffffc0211488 <free_area+0x10>
ffffffffc0200aea:	8082                	ret

ffffffffc0200aec <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200aec:	715d                	addi	sp,sp,-80
ffffffffc0200aee:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200af0:	00011917          	auipc	s2,0x11
ffffffffc0200af4:	98890913          	addi	s2,s2,-1656 # ffffffffc0211478 <free_area>
ffffffffc0200af8:	00893783          	ld	a5,8(s2)
ffffffffc0200afc:	e486                	sd	ra,72(sp)
ffffffffc0200afe:	e0a2                	sd	s0,64(sp)
ffffffffc0200b00:	fc26                	sd	s1,56(sp)
ffffffffc0200b02:	f44e                	sd	s3,40(sp)
ffffffffc0200b04:	f052                	sd	s4,32(sp)
ffffffffc0200b06:	ec56                	sd	s5,24(sp)
ffffffffc0200b08:	e85a                	sd	s6,16(sp)
ffffffffc0200b0a:	e45e                	sd	s7,8(sp)
ffffffffc0200b0c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b0e:	31278f63          	beq	a5,s2,ffffffffc0200e2c <default_check+0x340>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b12:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200b16:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200b18:	8b05                	andi	a4,a4,1
ffffffffc0200b1a:	30070d63          	beqz	a4,ffffffffc0200e34 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0200b1e:	4401                	li	s0,0
ffffffffc0200b20:	4481                	li	s1,0
ffffffffc0200b22:	a031                	j	ffffffffc0200b2e <default_check+0x42>
ffffffffc0200b24:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0200b28:	8b09                	andi	a4,a4,2
ffffffffc0200b2a:	30070563          	beqz	a4,ffffffffc0200e34 <default_check+0x348>
        count ++, total += p->property;
ffffffffc0200b2e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b32:	679c                	ld	a5,8(a5)
ffffffffc0200b34:	2485                	addiw	s1,s1,1
ffffffffc0200b36:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b38:	ff2796e3          	bne	a5,s2,ffffffffc0200b24 <default_check+0x38>
ffffffffc0200b3c:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200b3e:	3ef000ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0200b42:	75351963          	bne	a0,s3,ffffffffc0201294 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b46:	4505                	li	a0,1
ffffffffc0200b48:	317000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b4c:	8a2a                	mv	s4,a0
ffffffffc0200b4e:	48050363          	beqz	a0,ffffffffc0200fd4 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b52:	4505                	li	a0,1
ffffffffc0200b54:	30b000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b58:	89aa                	mv	s3,a0
ffffffffc0200b5a:	74050d63          	beqz	a0,ffffffffc02012b4 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b5e:	4505                	li	a0,1
ffffffffc0200b60:	2ff000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b64:	8aaa                	mv	s5,a0
ffffffffc0200b66:	4e050763          	beqz	a0,ffffffffc0201054 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b6a:	2f3a0563          	beq	s4,s3,ffffffffc0200e54 <default_check+0x368>
ffffffffc0200b6e:	2eaa0363          	beq	s4,a0,ffffffffc0200e54 <default_check+0x368>
ffffffffc0200b72:	2ea98163          	beq	s3,a0,ffffffffc0200e54 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b76:	000a2783          	lw	a5,0(s4)
ffffffffc0200b7a:	2e079d63          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
ffffffffc0200b7e:	0009a783          	lw	a5,0(s3)
ffffffffc0200b82:	2e079963          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
ffffffffc0200b86:	411c                	lw	a5,0(a0)
ffffffffc0200b88:	2e079663          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
/*
我们曾经在内存里分配了一堆连续的Page结构体，来管理物理页面。可以把它们看作一个结构体数组。
pages指针是这个数组的起始地址，减一下，加上一个基准值nbase, 就可以得到正确的物理页号。
pages指针和nbase基准值我们都在其他地方做了正确的初始化
*/
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b8c:	00011797          	auipc	a5,0x11
ffffffffc0200b90:	91c78793          	addi	a5,a5,-1764 # ffffffffc02114a8 <pages>
ffffffffc0200b94:	639c                	ld	a5,0(a5)
ffffffffc0200b96:	00004717          	auipc	a4,0x4
ffffffffc0200b9a:	15270713          	addi	a4,a4,338 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0200b9e:	630c                	ld	a1,0(a4)
ffffffffc0200ba0:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ba4:	870d                	srai	a4,a4,0x3
ffffffffc0200ba6:	02b70733          	mul	a4,a4,a1
ffffffffc0200baa:	00005697          	auipc	a3,0x5
ffffffffc0200bae:	72e68693          	addi	a3,a3,1838 # ffffffffc02062d8 <nbase>
ffffffffc0200bb2:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bb4:	00011697          	auipc	a3,0x11
ffffffffc0200bb8:	8a468693          	addi	a3,a3,-1884 # ffffffffc0211458 <npage>
ffffffffc0200bbc:	6294                	ld	a3,0(a3)
ffffffffc0200bbe:	06b2                	slli	a3,a3,0xc
ffffffffc0200bc0:	9732                	add	a4,a4,a2
指向某个Page结构体的指针，对应一个物理页面，也对应一个起始的物理地址。
左移若干位就可以从物理页号得到页面的起始物理地址。
*/
static inline uintptr_t page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bc2:	0732                	slli	a4,a4,0xc
ffffffffc0200bc4:	2cd77863          	bleu	a3,a4,ffffffffc0200e94 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bc8:	40f98733          	sub	a4,s3,a5
ffffffffc0200bcc:	870d                	srai	a4,a4,0x3
ffffffffc0200bce:	02b70733          	mul	a4,a4,a1
ffffffffc0200bd2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bd4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200bd6:	4ed77f63          	bleu	a3,a4,ffffffffc02010d4 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bda:	40f507b3          	sub	a5,a0,a5
ffffffffc0200bde:	878d                	srai	a5,a5,0x3
ffffffffc0200be0:	02b787b3          	mul	a5,a5,a1
ffffffffc0200be4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200be6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200be8:	34d7f663          	bleu	a3,a5,ffffffffc0200f34 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0200bec:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200bee:	00093c03          	ld	s8,0(s2)
ffffffffc0200bf2:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200bf6:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200bfa:	00011797          	auipc	a5,0x11
ffffffffc0200bfe:	8927b323          	sd	s2,-1914(a5) # ffffffffc0211480 <free_area+0x8>
ffffffffc0200c02:	00011797          	auipc	a5,0x11
ffffffffc0200c06:	8727bb23          	sd	s2,-1930(a5) # ffffffffc0211478 <free_area>
    nr_free = 0;
ffffffffc0200c0a:	00011797          	auipc	a5,0x11
ffffffffc0200c0e:	8607af23          	sw	zero,-1922(a5) # ffffffffc0211488 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c12:	24d000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c16:	2e051f63          	bnez	a0,ffffffffc0200f14 <default_check+0x428>
    free_page(p0);
ffffffffc0200c1a:	4585                	li	a1,1
ffffffffc0200c1c:	8552                	mv	a0,s4
ffffffffc0200c1e:	2c9000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p1);
ffffffffc0200c22:	4585                	li	a1,1
ffffffffc0200c24:	854e                	mv	a0,s3
ffffffffc0200c26:	2c1000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200c2a:	4585                	li	a1,1
ffffffffc0200c2c:	8556                	mv	a0,s5
ffffffffc0200c2e:	2b9000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c32:	01092703          	lw	a4,16(s2)
ffffffffc0200c36:	478d                	li	a5,3
ffffffffc0200c38:	2af71e63          	bne	a4,a5,ffffffffc0200ef4 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c3c:	4505                	li	a0,1
ffffffffc0200c3e:	221000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c42:	89aa                	mv	s3,a0
ffffffffc0200c44:	28050863          	beqz	a0,ffffffffc0200ed4 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c48:	4505                	li	a0,1
ffffffffc0200c4a:	215000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c4e:	8aaa                	mv	s5,a0
ffffffffc0200c50:	3e050263          	beqz	a0,ffffffffc0201034 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c54:	4505                	li	a0,1
ffffffffc0200c56:	209000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c5a:	8a2a                	mv	s4,a0
ffffffffc0200c5c:	3a050c63          	beqz	a0,ffffffffc0201014 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0200c60:	4505                	li	a0,1
ffffffffc0200c62:	1fd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c66:	38051763          	bnez	a0,ffffffffc0200ff4 <default_check+0x508>
    free_page(p0);
ffffffffc0200c6a:	4585                	li	a1,1
ffffffffc0200c6c:	854e                	mv	a0,s3
ffffffffc0200c6e:	279000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200c72:	00893783          	ld	a5,8(s2)
ffffffffc0200c76:	23278f63          	beq	a5,s2,ffffffffc0200eb4 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0200c7a:	4505                	li	a0,1
ffffffffc0200c7c:	1e3000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c80:	32a99a63          	bne	s3,a0,ffffffffc0200fb4 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0200c84:	4505                	li	a0,1
ffffffffc0200c86:	1d9000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c8a:	30051563          	bnez	a0,ffffffffc0200f94 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0200c8e:	01092783          	lw	a5,16(s2)
ffffffffc0200c92:	2e079163          	bnez	a5,ffffffffc0200f74 <default_check+0x488>
    free_page(p);
ffffffffc0200c96:	854e                	mv	a0,s3
ffffffffc0200c98:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200c9a:	00010797          	auipc	a5,0x10
ffffffffc0200c9e:	7d87bf23          	sd	s8,2014(a5) # ffffffffc0211478 <free_area>
ffffffffc0200ca2:	00010797          	auipc	a5,0x10
ffffffffc0200ca6:	7d77bf23          	sd	s7,2014(a5) # ffffffffc0211480 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200caa:	00010797          	auipc	a5,0x10
ffffffffc0200cae:	7d67af23          	sw	s6,2014(a5) # ffffffffc0211488 <free_area+0x10>
    free_page(p);
ffffffffc0200cb2:	235000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p1);
ffffffffc0200cb6:	4585                	li	a1,1
ffffffffc0200cb8:	8556                	mv	a0,s5
ffffffffc0200cba:	22d000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200cbe:	4585                	li	a1,1
ffffffffc0200cc0:	8552                	mv	a0,s4
ffffffffc0200cc2:	225000ef          	jal	ra,ffffffffc02016e6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200cc6:	4515                	li	a0,5
ffffffffc0200cc8:	197000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200ccc:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200cce:	28050363          	beqz	a0,ffffffffc0200f54 <default_check+0x468>
ffffffffc0200cd2:	651c                	ld	a5,8(a0)
ffffffffc0200cd4:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200cd6:	8b85                	andi	a5,a5,1
ffffffffc0200cd8:	54079e63          	bnez	a5,ffffffffc0201234 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200cdc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cde:	00093b03          	ld	s6,0(s2)
ffffffffc0200ce2:	00893a83          	ld	s5,8(s2)
ffffffffc0200ce6:	00010797          	auipc	a5,0x10
ffffffffc0200cea:	7927b923          	sd	s2,1938(a5) # ffffffffc0211478 <free_area>
ffffffffc0200cee:	00010797          	auipc	a5,0x10
ffffffffc0200cf2:	7927b923          	sd	s2,1938(a5) # ffffffffc0211480 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200cf6:	169000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200cfa:	50051d63          	bnez	a0,ffffffffc0201214 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200cfe:	09098a13          	addi	s4,s3,144
ffffffffc0200d02:	8552                	mv	a0,s4
ffffffffc0200d04:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d06:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200d0a:	00010797          	auipc	a5,0x10
ffffffffc0200d0e:	7607af23          	sw	zero,1918(a5) # ffffffffc0211488 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d12:	1d5000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d16:	4511                	li	a0,4
ffffffffc0200d18:	147000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d1c:	4c051c63          	bnez	a0,ffffffffc02011f4 <default_check+0x708>
ffffffffc0200d20:	0989b783          	ld	a5,152(s3)
ffffffffc0200d24:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d26:	8b85                	andi	a5,a5,1
ffffffffc0200d28:	4a078663          	beqz	a5,ffffffffc02011d4 <default_check+0x6e8>
ffffffffc0200d2c:	0a89a703          	lw	a4,168(s3)
ffffffffc0200d30:	478d                	li	a5,3
ffffffffc0200d32:	4af71163          	bne	a4,a5,ffffffffc02011d4 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d36:	450d                	li	a0,3
ffffffffc0200d38:	127000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d3c:	8c2a                	mv	s8,a0
ffffffffc0200d3e:	46050b63          	beqz	a0,ffffffffc02011b4 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0200d42:	4505                	li	a0,1
ffffffffc0200d44:	11b000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d48:	44051663          	bnez	a0,ffffffffc0201194 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0200d4c:	438a1463          	bne	s4,s8,ffffffffc0201174 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d50:	4585                	li	a1,1
ffffffffc0200d52:	854e                	mv	a0,s3
ffffffffc0200d54:	193000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_pages(p1, 3);
ffffffffc0200d58:	458d                	li	a1,3
ffffffffc0200d5a:	8552                	mv	a0,s4
ffffffffc0200d5c:	18b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0200d60:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200d64:	04898c13          	addi	s8,s3,72
ffffffffc0200d68:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200d6a:	8b85                	andi	a5,a5,1
ffffffffc0200d6c:	3e078463          	beqz	a5,ffffffffc0201154 <default_check+0x668>
ffffffffc0200d70:	0189a703          	lw	a4,24(s3)
ffffffffc0200d74:	4785                	li	a5,1
ffffffffc0200d76:	3cf71f63          	bne	a4,a5,ffffffffc0201154 <default_check+0x668>
ffffffffc0200d7a:	008a3783          	ld	a5,8(s4)
ffffffffc0200d7e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200d80:	8b85                	andi	a5,a5,1
ffffffffc0200d82:	3a078963          	beqz	a5,ffffffffc0201134 <default_check+0x648>
ffffffffc0200d86:	018a2703          	lw	a4,24(s4)
ffffffffc0200d8a:	478d                	li	a5,3
ffffffffc0200d8c:	3af71463          	bne	a4,a5,ffffffffc0201134 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200d90:	4505                	li	a0,1
ffffffffc0200d92:	0cd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d96:	36a99f63          	bne	s3,a0,ffffffffc0201114 <default_check+0x628>
    free_page(p0);
ffffffffc0200d9a:	4585                	li	a1,1
ffffffffc0200d9c:	14b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200da0:	4509                	li	a0,2
ffffffffc0200da2:	0bd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200da6:	34aa1763          	bne	s4,a0,ffffffffc02010f4 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0200daa:	4589                	li	a1,2
ffffffffc0200dac:	13b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200db0:	4585                	li	a1,1
ffffffffc0200db2:	8562                	mv	a0,s8
ffffffffc0200db4:	133000ef          	jal	ra,ffffffffc02016e6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200db8:	4515                	li	a0,5
ffffffffc0200dba:	0a5000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200dbe:	89aa                	mv	s3,a0
ffffffffc0200dc0:	48050a63          	beqz	a0,ffffffffc0201254 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0200dc4:	4505                	li	a0,1
ffffffffc0200dc6:	099000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200dca:	2e051563          	bnez	a0,ffffffffc02010b4 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0200dce:	01092783          	lw	a5,16(s2)
ffffffffc0200dd2:	2c079163          	bnez	a5,ffffffffc0201094 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200dd6:	4595                	li	a1,5
ffffffffc0200dd8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200dda:	00010797          	auipc	a5,0x10
ffffffffc0200dde:	6b77a723          	sw	s7,1710(a5) # ffffffffc0211488 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200de2:	00010797          	auipc	a5,0x10
ffffffffc0200de6:	6967bb23          	sd	s6,1686(a5) # ffffffffc0211478 <free_area>
ffffffffc0200dea:	00010797          	auipc	a5,0x10
ffffffffc0200dee:	6957bb23          	sd	s5,1686(a5) # ffffffffc0211480 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200df2:	0f5000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return listelm->next;
ffffffffc0200df6:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dfa:	01278963          	beq	a5,s2,ffffffffc0200e0c <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200dfe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e02:	679c                	ld	a5,8(a5)
ffffffffc0200e04:	34fd                	addiw	s1,s1,-1
ffffffffc0200e06:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e08:	ff279be3          	bne	a5,s2,ffffffffc0200dfe <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0200e0c:	26049463          	bnez	s1,ffffffffc0201074 <default_check+0x588>
    assert(total == 0);
ffffffffc0200e10:	46041263          	bnez	s0,ffffffffc0201274 <default_check+0x788>
}
ffffffffc0200e14:	60a6                	ld	ra,72(sp)
ffffffffc0200e16:	6406                	ld	s0,64(sp)
ffffffffc0200e18:	74e2                	ld	s1,56(sp)
ffffffffc0200e1a:	7942                	ld	s2,48(sp)
ffffffffc0200e1c:	79a2                	ld	s3,40(sp)
ffffffffc0200e1e:	7a02                	ld	s4,32(sp)
ffffffffc0200e20:	6ae2                	ld	s5,24(sp)
ffffffffc0200e22:	6b42                	ld	s6,16(sp)
ffffffffc0200e24:	6ba2                	ld	s7,8(sp)
ffffffffc0200e26:	6c02                	ld	s8,0(sp)
ffffffffc0200e28:	6161                	addi	sp,sp,80
ffffffffc0200e2a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e2c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e2e:	4401                	li	s0,0
ffffffffc0200e30:	4481                	li	s1,0
ffffffffc0200e32:	b331                	j	ffffffffc0200b3e <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200e34:	00004697          	auipc	a3,0x4
ffffffffc0200e38:	ebc68693          	addi	a3,a3,-324 # ffffffffc0204cf0 <commands+0x860>
ffffffffc0200e3c:	00004617          	auipc	a2,0x4
ffffffffc0200e40:	ec460613          	addi	a2,a2,-316 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200e44:	0f000593          	li	a1,240
ffffffffc0200e48:	00004517          	auipc	a0,0x4
ffffffffc0200e4c:	ed050513          	addi	a0,a0,-304 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200e50:	d24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e54:	00004697          	auipc	a3,0x4
ffffffffc0200e58:	f5c68693          	addi	a3,a3,-164 # ffffffffc0204db0 <commands+0x920>
ffffffffc0200e5c:	00004617          	auipc	a2,0x4
ffffffffc0200e60:	ea460613          	addi	a2,a2,-348 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200e64:	0bd00593          	li	a1,189
ffffffffc0200e68:	00004517          	auipc	a0,0x4
ffffffffc0200e6c:	eb050513          	addi	a0,a0,-336 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200e70:	d04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e74:	00004697          	auipc	a3,0x4
ffffffffc0200e78:	f6468693          	addi	a3,a3,-156 # ffffffffc0204dd8 <commands+0x948>
ffffffffc0200e7c:	00004617          	auipc	a2,0x4
ffffffffc0200e80:	e8460613          	addi	a2,a2,-380 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200e84:	0be00593          	li	a1,190
ffffffffc0200e88:	00004517          	auipc	a0,0x4
ffffffffc0200e8c:	e9050513          	addi	a0,a0,-368 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200e90:	ce4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e94:	00004697          	auipc	a3,0x4
ffffffffc0200e98:	f8468693          	addi	a3,a3,-124 # ffffffffc0204e18 <commands+0x988>
ffffffffc0200e9c:	00004617          	auipc	a2,0x4
ffffffffc0200ea0:	e6460613          	addi	a2,a2,-412 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200ea4:	0c000593          	li	a1,192
ffffffffc0200ea8:	00004517          	auipc	a0,0x4
ffffffffc0200eac:	e7050513          	addi	a0,a0,-400 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200eb0:	cc4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200eb4:	00004697          	auipc	a3,0x4
ffffffffc0200eb8:	fec68693          	addi	a3,a3,-20 # ffffffffc0204ea0 <commands+0xa10>
ffffffffc0200ebc:	00004617          	auipc	a2,0x4
ffffffffc0200ec0:	e4460613          	addi	a2,a2,-444 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200ec4:	0d900593          	li	a1,217
ffffffffc0200ec8:	00004517          	auipc	a0,0x4
ffffffffc0200ecc:	e5050513          	addi	a0,a0,-432 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200ed0:	ca4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ed4:	00004697          	auipc	a3,0x4
ffffffffc0200ed8:	e7c68693          	addi	a3,a3,-388 # ffffffffc0204d50 <commands+0x8c0>
ffffffffc0200edc:	00004617          	auipc	a2,0x4
ffffffffc0200ee0:	e2460613          	addi	a2,a2,-476 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200ee4:	0d200593          	li	a1,210
ffffffffc0200ee8:	00004517          	auipc	a0,0x4
ffffffffc0200eec:	e3050513          	addi	a0,a0,-464 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200ef0:	c84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 3);
ffffffffc0200ef4:	00004697          	auipc	a3,0x4
ffffffffc0200ef8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0204e90 <commands+0xa00>
ffffffffc0200efc:	00004617          	auipc	a2,0x4
ffffffffc0200f00:	e0460613          	addi	a2,a2,-508 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200f04:	0d000593          	li	a1,208
ffffffffc0200f08:	00004517          	auipc	a0,0x4
ffffffffc0200f0c:	e1050513          	addi	a0,a0,-496 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200f10:	c64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f14:	00004697          	auipc	a3,0x4
ffffffffc0200f18:	f6468693          	addi	a3,a3,-156 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc0200f1c:	00004617          	auipc	a2,0x4
ffffffffc0200f20:	de460613          	addi	a2,a2,-540 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200f24:	0cb00593          	li	a1,203
ffffffffc0200f28:	00004517          	auipc	a0,0x4
ffffffffc0200f2c:	df050513          	addi	a0,a0,-528 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200f30:	c44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f34:	00004697          	auipc	a3,0x4
ffffffffc0200f38:	f2468693          	addi	a3,a3,-220 # ffffffffc0204e58 <commands+0x9c8>
ffffffffc0200f3c:	00004617          	auipc	a2,0x4
ffffffffc0200f40:	dc460613          	addi	a2,a2,-572 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200f44:	0c200593          	li	a1,194
ffffffffc0200f48:	00004517          	auipc	a0,0x4
ffffffffc0200f4c:	dd050513          	addi	a0,a0,-560 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200f50:	c24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != NULL);
ffffffffc0200f54:	00004697          	auipc	a3,0x4
ffffffffc0200f58:	f9468693          	addi	a3,a3,-108 # ffffffffc0204ee8 <commands+0xa58>
ffffffffc0200f5c:	00004617          	auipc	a2,0x4
ffffffffc0200f60:	da460613          	addi	a2,a2,-604 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200f64:	0f800593          	li	a1,248
ffffffffc0200f68:	00004517          	auipc	a0,0x4
ffffffffc0200f6c:	db050513          	addi	a0,a0,-592 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200f70:	c04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc0200f74:	00004697          	auipc	a3,0x4
ffffffffc0200f78:	f6468693          	addi	a3,a3,-156 # ffffffffc0204ed8 <commands+0xa48>
ffffffffc0200f7c:	00004617          	auipc	a2,0x4
ffffffffc0200f80:	d8460613          	addi	a2,a2,-636 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200f84:	0df00593          	li	a1,223
ffffffffc0200f88:	00004517          	auipc	a0,0x4
ffffffffc0200f8c:	d9050513          	addi	a0,a0,-624 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200f90:	be4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f94:	00004697          	auipc	a3,0x4
ffffffffc0200f98:	ee468693          	addi	a3,a3,-284 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc0200f9c:	00004617          	auipc	a2,0x4
ffffffffc0200fa0:	d6460613          	addi	a2,a2,-668 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200fa4:	0dd00593          	li	a1,221
ffffffffc0200fa8:	00004517          	auipc	a0,0x4
ffffffffc0200fac:	d7050513          	addi	a0,a0,-656 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200fb0:	bc4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200fb4:	00004697          	auipc	a3,0x4
ffffffffc0200fb8:	f0468693          	addi	a3,a3,-252 # ffffffffc0204eb8 <commands+0xa28>
ffffffffc0200fbc:	00004617          	auipc	a2,0x4
ffffffffc0200fc0:	d4460613          	addi	a2,a2,-700 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200fc4:	0dc00593          	li	a1,220
ffffffffc0200fc8:	00004517          	auipc	a0,0x4
ffffffffc0200fcc:	d5050513          	addi	a0,a0,-688 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200fd0:	ba4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fd4:	00004697          	auipc	a3,0x4
ffffffffc0200fd8:	d7c68693          	addi	a3,a3,-644 # ffffffffc0204d50 <commands+0x8c0>
ffffffffc0200fdc:	00004617          	auipc	a2,0x4
ffffffffc0200fe0:	d2460613          	addi	a2,a2,-732 # ffffffffc0204d00 <commands+0x870>
ffffffffc0200fe4:	0b900593          	li	a1,185
ffffffffc0200fe8:	00004517          	auipc	a0,0x4
ffffffffc0200fec:	d3050513          	addi	a0,a0,-720 # ffffffffc0204d18 <commands+0x888>
ffffffffc0200ff0:	b84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	00004697          	auipc	a3,0x4
ffffffffc0200ff8:	e8468693          	addi	a3,a3,-380 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc0200ffc:	00004617          	auipc	a2,0x4
ffffffffc0201000:	d0460613          	addi	a2,a2,-764 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201004:	0d600593          	li	a1,214
ffffffffc0201008:	00004517          	auipc	a0,0x4
ffffffffc020100c:	d1050513          	addi	a0,a0,-752 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201010:	b64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201014:	00004697          	auipc	a3,0x4
ffffffffc0201018:	d7c68693          	addi	a3,a3,-644 # ffffffffc0204d90 <commands+0x900>
ffffffffc020101c:	00004617          	auipc	a2,0x4
ffffffffc0201020:	ce460613          	addi	a2,a2,-796 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201024:	0d400593          	li	a1,212
ffffffffc0201028:	00004517          	auipc	a0,0x4
ffffffffc020102c:	cf050513          	addi	a0,a0,-784 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201030:	b44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201034:	00004697          	auipc	a3,0x4
ffffffffc0201038:	d3c68693          	addi	a3,a3,-708 # ffffffffc0204d70 <commands+0x8e0>
ffffffffc020103c:	00004617          	auipc	a2,0x4
ffffffffc0201040:	cc460613          	addi	a2,a2,-828 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201044:	0d300593          	li	a1,211
ffffffffc0201048:	00004517          	auipc	a0,0x4
ffffffffc020104c:	cd050513          	addi	a0,a0,-816 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201050:	b24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201054:	00004697          	auipc	a3,0x4
ffffffffc0201058:	d3c68693          	addi	a3,a3,-708 # ffffffffc0204d90 <commands+0x900>
ffffffffc020105c:	00004617          	auipc	a2,0x4
ffffffffc0201060:	ca460613          	addi	a2,a2,-860 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201064:	0bb00593          	li	a1,187
ffffffffc0201068:	00004517          	auipc	a0,0x4
ffffffffc020106c:	cb050513          	addi	a0,a0,-848 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201070:	b04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(count == 0);
ffffffffc0201074:	00004697          	auipc	a3,0x4
ffffffffc0201078:	fc468693          	addi	a3,a3,-60 # ffffffffc0205038 <commands+0xba8>
ffffffffc020107c:	00004617          	auipc	a2,0x4
ffffffffc0201080:	c8460613          	addi	a2,a2,-892 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201084:	12500593          	li	a1,293
ffffffffc0201088:	00004517          	auipc	a0,0x4
ffffffffc020108c:	c9050513          	addi	a0,a0,-880 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201090:	ae4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc0201094:	00004697          	auipc	a3,0x4
ffffffffc0201098:	e4468693          	addi	a3,a3,-444 # ffffffffc0204ed8 <commands+0xa48>
ffffffffc020109c:	00004617          	auipc	a2,0x4
ffffffffc02010a0:	c6460613          	addi	a2,a2,-924 # ffffffffc0204d00 <commands+0x870>
ffffffffc02010a4:	11a00593          	li	a1,282
ffffffffc02010a8:	00004517          	auipc	a0,0x4
ffffffffc02010ac:	c7050513          	addi	a0,a0,-912 # ffffffffc0204d18 <commands+0x888>
ffffffffc02010b0:	ac4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010b4:	00004697          	auipc	a3,0x4
ffffffffc02010b8:	dc468693          	addi	a3,a3,-572 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc02010bc:	00004617          	auipc	a2,0x4
ffffffffc02010c0:	c4460613          	addi	a2,a2,-956 # ffffffffc0204d00 <commands+0x870>
ffffffffc02010c4:	11800593          	li	a1,280
ffffffffc02010c8:	00004517          	auipc	a0,0x4
ffffffffc02010cc:	c5050513          	addi	a0,a0,-944 # ffffffffc0204d18 <commands+0x888>
ffffffffc02010d0:	aa4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010d4:	00004697          	auipc	a3,0x4
ffffffffc02010d8:	d6468693          	addi	a3,a3,-668 # ffffffffc0204e38 <commands+0x9a8>
ffffffffc02010dc:	00004617          	auipc	a2,0x4
ffffffffc02010e0:	c2460613          	addi	a2,a2,-988 # ffffffffc0204d00 <commands+0x870>
ffffffffc02010e4:	0c100593          	li	a1,193
ffffffffc02010e8:	00004517          	auipc	a0,0x4
ffffffffc02010ec:	c3050513          	addi	a0,a0,-976 # ffffffffc0204d18 <commands+0x888>
ffffffffc02010f0:	a84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02010f4:	00004697          	auipc	a3,0x4
ffffffffc02010f8:	f0468693          	addi	a3,a3,-252 # ffffffffc0204ff8 <commands+0xb68>
ffffffffc02010fc:	00004617          	auipc	a2,0x4
ffffffffc0201100:	c0460613          	addi	a2,a2,-1020 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201104:	11200593          	li	a1,274
ffffffffc0201108:	00004517          	auipc	a0,0x4
ffffffffc020110c:	c1050513          	addi	a0,a0,-1008 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201110:	a64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201114:	00004697          	auipc	a3,0x4
ffffffffc0201118:	ec468693          	addi	a3,a3,-316 # ffffffffc0204fd8 <commands+0xb48>
ffffffffc020111c:	00004617          	auipc	a2,0x4
ffffffffc0201120:	be460613          	addi	a2,a2,-1052 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201124:	11000593          	li	a1,272
ffffffffc0201128:	00004517          	auipc	a0,0x4
ffffffffc020112c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201130:	a44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201134:	00004697          	auipc	a3,0x4
ffffffffc0201138:	e7c68693          	addi	a3,a3,-388 # ffffffffc0204fb0 <commands+0xb20>
ffffffffc020113c:	00004617          	auipc	a2,0x4
ffffffffc0201140:	bc460613          	addi	a2,a2,-1084 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201144:	10e00593          	li	a1,270
ffffffffc0201148:	00004517          	auipc	a0,0x4
ffffffffc020114c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201150:	a24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201154:	00004697          	auipc	a3,0x4
ffffffffc0201158:	e3468693          	addi	a3,a3,-460 # ffffffffc0204f88 <commands+0xaf8>
ffffffffc020115c:	00004617          	auipc	a2,0x4
ffffffffc0201160:	ba460613          	addi	a2,a2,-1116 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201164:	10d00593          	li	a1,269
ffffffffc0201168:	00004517          	auipc	a0,0x4
ffffffffc020116c:	bb050513          	addi	a0,a0,-1104 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201170:	a04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201174:	00004697          	auipc	a3,0x4
ffffffffc0201178:	e0468693          	addi	a3,a3,-508 # ffffffffc0204f78 <commands+0xae8>
ffffffffc020117c:	00004617          	auipc	a2,0x4
ffffffffc0201180:	b8460613          	addi	a2,a2,-1148 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201184:	10800593          	li	a1,264
ffffffffc0201188:	00004517          	auipc	a0,0x4
ffffffffc020118c:	b9050513          	addi	a0,a0,-1136 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201190:	9e4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201194:	00004697          	auipc	a3,0x4
ffffffffc0201198:	ce468693          	addi	a3,a3,-796 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc020119c:	00004617          	auipc	a2,0x4
ffffffffc02011a0:	b6460613          	addi	a2,a2,-1180 # ffffffffc0204d00 <commands+0x870>
ffffffffc02011a4:	10700593          	li	a1,263
ffffffffc02011a8:	00004517          	auipc	a0,0x4
ffffffffc02011ac:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204d18 <commands+0x888>
ffffffffc02011b0:	9c4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011b4:	00004697          	auipc	a3,0x4
ffffffffc02011b8:	da468693          	addi	a3,a3,-604 # ffffffffc0204f58 <commands+0xac8>
ffffffffc02011bc:	00004617          	auipc	a2,0x4
ffffffffc02011c0:	b4460613          	addi	a2,a2,-1212 # ffffffffc0204d00 <commands+0x870>
ffffffffc02011c4:	10600593          	li	a1,262
ffffffffc02011c8:	00004517          	auipc	a0,0x4
ffffffffc02011cc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0204d18 <commands+0x888>
ffffffffc02011d0:	9a4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011d4:	00004697          	auipc	a3,0x4
ffffffffc02011d8:	d5468693          	addi	a3,a3,-684 # ffffffffc0204f28 <commands+0xa98>
ffffffffc02011dc:	00004617          	auipc	a2,0x4
ffffffffc02011e0:	b2460613          	addi	a2,a2,-1244 # ffffffffc0204d00 <commands+0x870>
ffffffffc02011e4:	10500593          	li	a1,261
ffffffffc02011e8:	00004517          	auipc	a0,0x4
ffffffffc02011ec:	b3050513          	addi	a0,a0,-1232 # ffffffffc0204d18 <commands+0x888>
ffffffffc02011f0:	984ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02011f4:	00004697          	auipc	a3,0x4
ffffffffc02011f8:	d1c68693          	addi	a3,a3,-740 # ffffffffc0204f10 <commands+0xa80>
ffffffffc02011fc:	00004617          	auipc	a2,0x4
ffffffffc0201200:	b0460613          	addi	a2,a2,-1276 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201204:	10400593          	li	a1,260
ffffffffc0201208:	00004517          	auipc	a0,0x4
ffffffffc020120c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201210:	964ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201214:	00004697          	auipc	a3,0x4
ffffffffc0201218:	c6468693          	addi	a3,a3,-924 # ffffffffc0204e78 <commands+0x9e8>
ffffffffc020121c:	00004617          	auipc	a2,0x4
ffffffffc0201220:	ae460613          	addi	a2,a2,-1308 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201224:	0fe00593          	li	a1,254
ffffffffc0201228:	00004517          	auipc	a0,0x4
ffffffffc020122c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201230:	944ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201234:	00004697          	auipc	a3,0x4
ffffffffc0201238:	cc468693          	addi	a3,a3,-828 # ffffffffc0204ef8 <commands+0xa68>
ffffffffc020123c:	00004617          	auipc	a2,0x4
ffffffffc0201240:	ac460613          	addi	a2,a2,-1340 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201244:	0f900593          	li	a1,249
ffffffffc0201248:	00004517          	auipc	a0,0x4
ffffffffc020124c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201250:	924ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201254:	00004697          	auipc	a3,0x4
ffffffffc0201258:	dc468693          	addi	a3,a3,-572 # ffffffffc0205018 <commands+0xb88>
ffffffffc020125c:	00004617          	auipc	a2,0x4
ffffffffc0201260:	aa460613          	addi	a2,a2,-1372 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201264:	11700593          	li	a1,279
ffffffffc0201268:	00004517          	auipc	a0,0x4
ffffffffc020126c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201270:	904ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == 0);
ffffffffc0201274:	00004697          	auipc	a3,0x4
ffffffffc0201278:	dd468693          	addi	a3,a3,-556 # ffffffffc0205048 <commands+0xbb8>
ffffffffc020127c:	00004617          	auipc	a2,0x4
ffffffffc0201280:	a8460613          	addi	a2,a2,-1404 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201284:	12600593          	li	a1,294
ffffffffc0201288:	00004517          	auipc	a0,0x4
ffffffffc020128c:	a9050513          	addi	a0,a0,-1392 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201290:	8e4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201294:	00004697          	auipc	a3,0x4
ffffffffc0201298:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0204d30 <commands+0x8a0>
ffffffffc020129c:	00004617          	auipc	a2,0x4
ffffffffc02012a0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0204d00 <commands+0x870>
ffffffffc02012a4:	0f300593          	li	a1,243
ffffffffc02012a8:	00004517          	auipc	a0,0x4
ffffffffc02012ac:	a7050513          	addi	a0,a0,-1424 # ffffffffc0204d18 <commands+0x888>
ffffffffc02012b0:	8c4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012b4:	00004697          	auipc	a3,0x4
ffffffffc02012b8:	abc68693          	addi	a3,a3,-1348 # ffffffffc0204d70 <commands+0x8e0>
ffffffffc02012bc:	00004617          	auipc	a2,0x4
ffffffffc02012c0:	a4460613          	addi	a2,a2,-1468 # ffffffffc0204d00 <commands+0x870>
ffffffffc02012c4:	0ba00593          	li	a1,186
ffffffffc02012c8:	00004517          	auipc	a0,0x4
ffffffffc02012cc:	a5050513          	addi	a0,a0,-1456 # ffffffffc0204d18 <commands+0x888>
ffffffffc02012d0:	8a4ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02012d4 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02012d4:	1141                	addi	sp,sp,-16
ffffffffc02012d6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02012d8:	18058063          	beqz	a1,ffffffffc0201458 <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc02012dc:	00359693          	slli	a3,a1,0x3
ffffffffc02012e0:	96ae                	add	a3,a3,a1
ffffffffc02012e2:	068e                	slli	a3,a3,0x3
ffffffffc02012e4:	96aa                	add	a3,a3,a0
ffffffffc02012e6:	02d50d63          	beq	a0,a3,ffffffffc0201320 <default_free_pages+0x4c>
ffffffffc02012ea:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02012ec:	8b85                	andi	a5,a5,1
ffffffffc02012ee:	14079563          	bnez	a5,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc02012f2:	651c                	ld	a5,8(a0)
ffffffffc02012f4:	8385                	srli	a5,a5,0x1
ffffffffc02012f6:	8b85                	andi	a5,a5,1
ffffffffc02012f8:	14079063          	bnez	a5,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc02012fc:	87aa                	mv	a5,a0
ffffffffc02012fe:	a809                	j	ffffffffc0201310 <default_free_pages+0x3c>
ffffffffc0201300:	6798                	ld	a4,8(a5)
ffffffffc0201302:	8b05                	andi	a4,a4,1
ffffffffc0201304:	12071a63          	bnez	a4,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc0201308:	6798                	ld	a4,8(a5)
ffffffffc020130a:	8b09                	andi	a4,a4,2
ffffffffc020130c:	12071663          	bnez	a4,ffffffffc0201438 <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0201310:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201314:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201318:	04878793          	addi	a5,a5,72
ffffffffc020131c:	fed792e3          	bne	a5,a3,ffffffffc0201300 <default_free_pages+0x2c>
    base->property = n;
ffffffffc0201320:	2581                	sext.w	a1,a1
ffffffffc0201322:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0201324:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201328:	4789                	li	a5,2
ffffffffc020132a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020132e:	00010697          	auipc	a3,0x10
ffffffffc0201332:	14a68693          	addi	a3,a3,330 # ffffffffc0211478 <free_area>
ffffffffc0201336:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201338:	669c                	ld	a5,8(a3)
ffffffffc020133a:	9db9                	addw	a1,a1,a4
ffffffffc020133c:	00010717          	auipc	a4,0x10
ffffffffc0201340:	14b72623          	sw	a1,332(a4) # ffffffffc0211488 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201344:	08d78f63          	beq	a5,a3,ffffffffc02013e2 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201348:	fe078713          	addi	a4,a5,-32
ffffffffc020134c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020134e:	4801                	li	a6,0
ffffffffc0201350:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201354:	00e56a63          	bltu	a0,a4,ffffffffc0201368 <default_free_pages+0x94>
    return listelm->next;
ffffffffc0201358:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020135a:	02d70563          	beq	a4,a3,ffffffffc0201384 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020135e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201360:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201364:	fee57ae3          	bleu	a4,a0,ffffffffc0201358 <default_free_pages+0x84>
ffffffffc0201368:	00080663          	beqz	a6,ffffffffc0201374 <default_free_pages+0xa0>
ffffffffc020136c:	00010817          	auipc	a6,0x10
ffffffffc0201370:	10b83623          	sd	a1,268(a6) # ffffffffc0211478 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201374:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201376:	e390                	sd	a2,0(a5)
ffffffffc0201378:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020137a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020137c:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc020137e:	02d59163          	bne	a1,a3,ffffffffc02013a0 <default_free_pages+0xcc>
ffffffffc0201382:	a091                	j	ffffffffc02013c6 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201384:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201386:	f514                	sd	a3,40(a0)
ffffffffc0201388:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020138a:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020138c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020138e:	00d70563          	beq	a4,a3,ffffffffc0201398 <default_free_pages+0xc4>
ffffffffc0201392:	4805                	li	a6,1
ffffffffc0201394:	87ba                	mv	a5,a4
ffffffffc0201396:	b7e9                	j	ffffffffc0201360 <default_free_pages+0x8c>
ffffffffc0201398:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020139a:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020139c:	02d78163          	beq	a5,a3,ffffffffc02013be <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc02013a0:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc02013a4:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc02013a8:	02081713          	slli	a4,a6,0x20
ffffffffc02013ac:	9301                	srli	a4,a4,0x20
ffffffffc02013ae:	00371793          	slli	a5,a4,0x3
ffffffffc02013b2:	97ba                	add	a5,a5,a4
ffffffffc02013b4:	078e                	slli	a5,a5,0x3
ffffffffc02013b6:	97b2                	add	a5,a5,a2
ffffffffc02013b8:	02f50e63          	beq	a0,a5,ffffffffc02013f4 <default_free_pages+0x120>
ffffffffc02013bc:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc02013be:	fe078713          	addi	a4,a5,-32
ffffffffc02013c2:	00d78d63          	beq	a5,a3,ffffffffc02013dc <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc02013c6:	4d0c                	lw	a1,24(a0)
ffffffffc02013c8:	02059613          	slli	a2,a1,0x20
ffffffffc02013cc:	9201                	srli	a2,a2,0x20
ffffffffc02013ce:	00361693          	slli	a3,a2,0x3
ffffffffc02013d2:	96b2                	add	a3,a3,a2
ffffffffc02013d4:	068e                	slli	a3,a3,0x3
ffffffffc02013d6:	96aa                	add	a3,a3,a0
ffffffffc02013d8:	04d70063          	beq	a4,a3,ffffffffc0201418 <default_free_pages+0x144>
}
ffffffffc02013dc:	60a2                	ld	ra,8(sp)
ffffffffc02013de:	0141                	addi	sp,sp,16
ffffffffc02013e0:	8082                	ret
ffffffffc02013e2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02013e4:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02013e8:	e398                	sd	a4,0(a5)
ffffffffc02013ea:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02013ec:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02013ee:	f11c                	sd	a5,32(a0)
}
ffffffffc02013f0:	0141                	addi	sp,sp,16
ffffffffc02013f2:	8082                	ret
            p->property += base->property;
ffffffffc02013f4:	4d1c                	lw	a5,24(a0)
ffffffffc02013f6:	0107883b          	addw	a6,a5,a6
ffffffffc02013fa:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013fe:	57f5                	li	a5,-3
ffffffffc0201400:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201404:	02053803          	ld	a6,32(a0)
ffffffffc0201408:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc020140a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020140c:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201410:	659c                	ld	a5,8(a1)
ffffffffc0201412:	01073023          	sd	a6,0(a4)
ffffffffc0201416:	b765                	j	ffffffffc02013be <default_free_pages+0xea>
            base->property += p->property;
ffffffffc0201418:	ff87a703          	lw	a4,-8(a5)
ffffffffc020141c:	fe878693          	addi	a3,a5,-24
ffffffffc0201420:	9db9                	addw	a1,a1,a4
ffffffffc0201422:	cd0c                	sw	a1,24(a0)
ffffffffc0201424:	5775                	li	a4,-3
ffffffffc0201426:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020142a:	6398                	ld	a4,0(a5)
ffffffffc020142c:	679c                	ld	a5,8(a5)
}
ffffffffc020142e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201430:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201432:	e398                	sd	a4,0(a5)
ffffffffc0201434:	0141                	addi	sp,sp,16
ffffffffc0201436:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201438:	00004697          	auipc	a3,0x4
ffffffffc020143c:	c2068693          	addi	a3,a3,-992 # ffffffffc0205058 <commands+0xbc8>
ffffffffc0201440:	00004617          	auipc	a2,0x4
ffffffffc0201444:	8c060613          	addi	a2,a2,-1856 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201448:	08300593          	li	a1,131
ffffffffc020144c:	00004517          	auipc	a0,0x4
ffffffffc0201450:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201454:	f21fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201458:	00004697          	auipc	a3,0x4
ffffffffc020145c:	c2868693          	addi	a3,a3,-984 # ffffffffc0205080 <commands+0xbf0>
ffffffffc0201460:	00004617          	auipc	a2,0x4
ffffffffc0201464:	8a060613          	addi	a2,a2,-1888 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201468:	08000593          	li	a1,128
ffffffffc020146c:	00004517          	auipc	a0,0x4
ffffffffc0201470:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0204d18 <commands+0x888>
ffffffffc0201474:	f01fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201478 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201478:	cd51                	beqz	a0,ffffffffc0201514 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc020147a:	00010597          	auipc	a1,0x10
ffffffffc020147e:	ffe58593          	addi	a1,a1,-2 # ffffffffc0211478 <free_area>
ffffffffc0201482:	0105a803          	lw	a6,16(a1)
ffffffffc0201486:	862a                	mv	a2,a0
ffffffffc0201488:	02081793          	slli	a5,a6,0x20
ffffffffc020148c:	9381                	srli	a5,a5,0x20
ffffffffc020148e:	00a7ee63          	bltu	a5,a0,ffffffffc02014aa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201492:	87ae                	mv	a5,a1
ffffffffc0201494:	a801                	j	ffffffffc02014a4 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201496:	ff87a703          	lw	a4,-8(a5)
ffffffffc020149a:	02071693          	slli	a3,a4,0x20
ffffffffc020149e:	9281                	srli	a3,a3,0x20
ffffffffc02014a0:	00c6f763          	bleu	a2,a3,ffffffffc02014ae <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02014a4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014a6:	feb798e3          	bne	a5,a1,ffffffffc0201496 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02014aa:	4501                	li	a0,0
}
ffffffffc02014ac:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc02014ae:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc02014b2:	dd6d                	beqz	a0,ffffffffc02014ac <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc02014b4:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014b8:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc02014bc:	00060e1b          	sext.w	t3,a2
ffffffffc02014c0:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02014c4:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02014c8:	02d67b63          	bleu	a3,a2,ffffffffc02014fe <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02014cc:	00361693          	slli	a3,a2,0x3
ffffffffc02014d0:	96b2                	add	a3,a3,a2
ffffffffc02014d2:	068e                	slli	a3,a3,0x3
ffffffffc02014d4:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02014d6:	41c7073b          	subw	a4,a4,t3
ffffffffc02014da:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014dc:	00868613          	addi	a2,a3,8
ffffffffc02014e0:	4709                	li	a4,2
ffffffffc02014e2:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014e6:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02014ea:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc02014ee:	0105a803          	lw	a6,16(a1)
ffffffffc02014f2:	e310                	sd	a2,0(a4)
ffffffffc02014f4:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02014f8:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02014fa:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc02014fe:	41c8083b          	subw	a6,a6,t3
ffffffffc0201502:	00010717          	auipc	a4,0x10
ffffffffc0201506:	f9072323          	sw	a6,-122(a4) # ffffffffc0211488 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020150a:	5775                	li	a4,-3
ffffffffc020150c:	17a1                	addi	a5,a5,-24
ffffffffc020150e:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201512:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201514:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201516:	00004697          	auipc	a3,0x4
ffffffffc020151a:	b6a68693          	addi	a3,a3,-1174 # ffffffffc0205080 <commands+0xbf0>
ffffffffc020151e:	00003617          	auipc	a2,0x3
ffffffffc0201522:	7e260613          	addi	a2,a2,2018 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201526:	06200593          	li	a1,98
ffffffffc020152a:	00003517          	auipc	a0,0x3
ffffffffc020152e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0204d18 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201532:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201534:	e41fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201538 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201538:	1141                	addi	sp,sp,-16
ffffffffc020153a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020153c:	c1fd                	beqz	a1,ffffffffc0201622 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc020153e:	00359693          	slli	a3,a1,0x3
ffffffffc0201542:	96ae                	add	a3,a3,a1
ffffffffc0201544:	068e                	slli	a3,a3,0x3
ffffffffc0201546:	96aa                	add	a3,a3,a0
ffffffffc0201548:	02d50463          	beq	a0,a3,ffffffffc0201570 <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020154c:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc020154e:	87aa                	mv	a5,a0
ffffffffc0201550:	8b05                	andi	a4,a4,1
ffffffffc0201552:	e709                	bnez	a4,ffffffffc020155c <default_init_memmap+0x24>
ffffffffc0201554:	a07d                	j	ffffffffc0201602 <default_init_memmap+0xca>
ffffffffc0201556:	6798                	ld	a4,8(a5)
ffffffffc0201558:	8b05                	andi	a4,a4,1
ffffffffc020155a:	c745                	beqz	a4,ffffffffc0201602 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc020155c:	0007ac23          	sw	zero,24(a5)
ffffffffc0201560:	0007b423          	sd	zero,8(a5)
ffffffffc0201564:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201568:	04878793          	addi	a5,a5,72
ffffffffc020156c:	fed795e3          	bne	a5,a3,ffffffffc0201556 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc0201570:	2581                	sext.w	a1,a1
ffffffffc0201572:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201574:	4789                	li	a5,2
ffffffffc0201576:	00850713          	addi	a4,a0,8
ffffffffc020157a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020157e:	00010697          	auipc	a3,0x10
ffffffffc0201582:	efa68693          	addi	a3,a3,-262 # ffffffffc0211478 <free_area>
ffffffffc0201586:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201588:	669c                	ld	a5,8(a3)
ffffffffc020158a:	9db9                	addw	a1,a1,a4
ffffffffc020158c:	00010717          	auipc	a4,0x10
ffffffffc0201590:	eeb72e23          	sw	a1,-260(a4) # ffffffffc0211488 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201594:	04d78a63          	beq	a5,a3,ffffffffc02015e8 <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0201598:	fe078713          	addi	a4,a5,-32
ffffffffc020159c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020159e:	4801                	li	a6,0
ffffffffc02015a0:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc02015a4:	00e56a63          	bltu	a0,a4,ffffffffc02015b8 <default_init_memmap+0x80>
    return listelm->next;
ffffffffc02015a8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015aa:	02d70563          	beq	a4,a3,ffffffffc02015d4 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ae:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015b0:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02015b4:	fee57ae3          	bleu	a4,a0,ffffffffc02015a8 <default_init_memmap+0x70>
ffffffffc02015b8:	00080663          	beqz	a6,ffffffffc02015c4 <default_init_memmap+0x8c>
ffffffffc02015bc:	00010717          	auipc	a4,0x10
ffffffffc02015c0:	eab73e23          	sd	a1,-324(a4) # ffffffffc0211478 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015c4:	6398                	ld	a4,0(a5)
}
ffffffffc02015c6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015c8:	e390                	sd	a2,0(a5)
ffffffffc02015ca:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015cc:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02015ce:	f118                	sd	a4,32(a0)
ffffffffc02015d0:	0141                	addi	sp,sp,16
ffffffffc02015d2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015d6:	f514                	sd	a3,40(a0)
ffffffffc02015d8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015da:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc02015dc:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015de:	00d70e63          	beq	a4,a3,ffffffffc02015fa <default_init_memmap+0xc2>
ffffffffc02015e2:	4805                	li	a6,1
ffffffffc02015e4:	87ba                	mv	a5,a4
ffffffffc02015e6:	b7e9                	j	ffffffffc02015b0 <default_init_memmap+0x78>
}
ffffffffc02015e8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015ea:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02015ee:	e398                	sd	a4,0(a5)
ffffffffc02015f0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02015f2:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02015f4:	f11c                	sd	a5,32(a0)
}
ffffffffc02015f6:	0141                	addi	sp,sp,16
ffffffffc02015f8:	8082                	ret
ffffffffc02015fa:	60a2                	ld	ra,8(sp)
ffffffffc02015fc:	e290                	sd	a2,0(a3)
ffffffffc02015fe:	0141                	addi	sp,sp,16
ffffffffc0201600:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201602:	00004697          	auipc	a3,0x4
ffffffffc0201606:	a8668693          	addi	a3,a3,-1402 # ffffffffc0205088 <commands+0xbf8>
ffffffffc020160a:	00003617          	auipc	a2,0x3
ffffffffc020160e:	6f660613          	addi	a2,a2,1782 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201612:	04900593          	li	a1,73
ffffffffc0201616:	00003517          	auipc	a0,0x3
ffffffffc020161a:	70250513          	addi	a0,a0,1794 # ffffffffc0204d18 <commands+0x888>
ffffffffc020161e:	d57fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201622:	00004697          	auipc	a3,0x4
ffffffffc0201626:	a5e68693          	addi	a3,a3,-1442 # ffffffffc0205080 <commands+0xbf0>
ffffffffc020162a:	00003617          	auipc	a2,0x3
ffffffffc020162e:	6d660613          	addi	a2,a2,1750 # ffffffffc0204d00 <commands+0x870>
ffffffffc0201632:	04600593          	li	a1,70
ffffffffc0201636:	00003517          	auipc	a0,0x3
ffffffffc020163a:	6e250513          	addi	a0,a0,1762 # ffffffffc0204d18 <commands+0x888>
ffffffffc020163e:	d37fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201642 <pa2page.part.4>:
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0201642:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201644:	00004617          	auipc	a2,0x4
ffffffffc0201648:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0205160 <default_pmm_manager+0xc8>
ffffffffc020164c:	07b00593          	li	a1,123
ffffffffc0201650:	00004517          	auipc	a0,0x4
ffffffffc0201654:	b3050513          	addi	a0,a0,-1232 # ffffffffc0205180 <default_pmm_manager+0xe8>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0201658:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020165a:	d1bfe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020165e <alloc_pages>:

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
// 分配n页
struct Page *alloc_pages(size_t n)
{
ffffffffc020165e:	715d                	addi	sp,sp,-80
ffffffffc0201660:	e0a2                	sd	s0,64(sp)
ffffffffc0201662:	fc26                	sd	s1,56(sp)
ffffffffc0201664:	f84a                	sd	s2,48(sp)
ffffffffc0201666:	f44e                	sd	s3,40(sp)
ffffffffc0201668:	f052                	sd	s4,32(sp)
ffffffffc020166a:	ec56                	sd	s5,24(sp)
ffffffffc020166c:	e486                	sd	ra,72(sp)
ffffffffc020166e:	842a                	mv	s0,a0
ffffffffc0201670:	00010497          	auipc	s1,0x10
ffffffffc0201674:	e2048493          	addi	s1,s1,-480 # ffffffffc0211490 <pmm_manager>
        local_intr_restore(intr_flag);

        // 如果有足够的物理页面，就不必换出其他页面
        // 如果n>1, 说明希望分配多个连续的页面，但是我们换出页面的时候并不能换出连续的页面，这一点是暂时不支持的
        // swap_init_ok标志是否成功初始化了，如果还没初始化成功那还是别换了
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc0201678:	4985                	li	s3,1
ffffffffc020167a:	00010a17          	auipc	s4,0x10
ffffffffc020167e:	deea0a13          	addi	s4,s4,-530 # ffffffffc0211468 <swap_init_ok>
            break;

        // 现在需要换出页面
        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0); // 调用页面置换的”换出页面“接口。这里必有n=1
ffffffffc0201682:	0005091b          	sext.w	s2,a0
ffffffffc0201686:	00010a97          	auipc	s5,0x10
ffffffffc020168a:	f0aa8a93          	addi	s5,s5,-246 # ffffffffc0211590 <check_mm_struct>
ffffffffc020168e:	a00d                	j	ffffffffc02016b0 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201690:	609c                	ld	a5,0(s1)
ffffffffc0201692:	6f9c                	ld	a5,24(a5)
ffffffffc0201694:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0); // 调用页面置换的”换出页面“接口。这里必有n=1
ffffffffc0201696:	4601                	li	a2,0
ffffffffc0201698:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc020169a:	ed0d                	bnez	a0,ffffffffc02016d4 <alloc_pages+0x76>
ffffffffc020169c:	0289ec63          	bltu	s3,s0,ffffffffc02016d4 <alloc_pages+0x76>
ffffffffc02016a0:	000a2783          	lw	a5,0(s4)
ffffffffc02016a4:	2781                	sext.w	a5,a5
ffffffffc02016a6:	c79d                	beqz	a5,ffffffffc02016d4 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0); // 调用页面置换的”换出页面“接口。这里必有n=1
ffffffffc02016a8:	000ab503          	ld	a0,0(s5)
ffffffffc02016ac:	021010ef          	jal	ra,ffffffffc0202ecc <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016b0:	100027f3          	csrr	a5,sstatus
ffffffffc02016b4:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc02016b6:	8522                	mv	a0,s0
ffffffffc02016b8:	dfe1                	beqz	a5,ffffffffc0201690 <alloc_pages+0x32>
        intr_disable();
ffffffffc02016ba:	e41fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc02016be:	609c                	ld	a5,0(s1)
ffffffffc02016c0:	8522                	mv	a0,s0
ffffffffc02016c2:	6f9c                	ld	a5,24(a5)
ffffffffc02016c4:	9782                	jalr	a5
ffffffffc02016c6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02016c8:	e2dfe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
ffffffffc02016cc:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0); // 调用页面置换的”换出页面“接口。这里必有n=1
ffffffffc02016ce:	4601                	li	a2,0
ffffffffc02016d0:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc02016d2:	d569                	beqz	a0,ffffffffc020169c <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc02016d4:	60a6                	ld	ra,72(sp)
ffffffffc02016d6:	6406                	ld	s0,64(sp)
ffffffffc02016d8:	74e2                	ld	s1,56(sp)
ffffffffc02016da:	7942                	ld	s2,48(sp)
ffffffffc02016dc:	79a2                	ld	s3,40(sp)
ffffffffc02016de:	7a02                	ld	s4,32(sp)
ffffffffc02016e0:	6ae2                	ld	s5,24(sp)
ffffffffc02016e2:	6161                	addi	sp,sp,80
ffffffffc02016e4:	8082                	ret

ffffffffc02016e6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016e6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ea:	8b89                	andi	a5,a5,2
ffffffffc02016ec:	eb89                	bnez	a5,ffffffffc02016fe <free_pages+0x18>
{
    bool intr_flag;

    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016ee:	00010797          	auipc	a5,0x10
ffffffffc02016f2:	da278793          	addi	a5,a5,-606 # ffffffffc0211490 <pmm_manager>
ffffffffc02016f6:	639c                	ld	a5,0(a5)
ffffffffc02016f8:	0207b303          	ld	t1,32(a5)
ffffffffc02016fc:	8302                	jr	t1
{
ffffffffc02016fe:	1101                	addi	sp,sp,-32
ffffffffc0201700:	ec06                	sd	ra,24(sp)
ffffffffc0201702:	e822                	sd	s0,16(sp)
ffffffffc0201704:	e426                	sd	s1,8(sp)
ffffffffc0201706:	842a                	mv	s0,a0
ffffffffc0201708:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020170a:	df1fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020170e:	00010797          	auipc	a5,0x10
ffffffffc0201712:	d8278793          	addi	a5,a5,-638 # ffffffffc0211490 <pmm_manager>
ffffffffc0201716:	639c                	ld	a5,0(a5)
ffffffffc0201718:	85a6                	mv	a1,s1
ffffffffc020171a:	8522                	mv	a0,s0
ffffffffc020171c:	739c                	ld	a5,32(a5)
ffffffffc020171e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201720:	6442                	ld	s0,16(sp)
ffffffffc0201722:	60e2                	ld	ra,24(sp)
ffffffffc0201724:	64a2                	ld	s1,8(sp)
ffffffffc0201726:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201728:	dcdfe06f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc020172c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020172c:	100027f3          	csrr	a5,sstatus
ffffffffc0201730:	8b89                	andi	a5,a5,2
ffffffffc0201732:	eb89                	bnez	a5,ffffffffc0201744 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201734:	00010797          	auipc	a5,0x10
ffffffffc0201738:	d5c78793          	addi	a5,a5,-676 # ffffffffc0211490 <pmm_manager>
ffffffffc020173c:	639c                	ld	a5,0(a5)
ffffffffc020173e:	0287b303          	ld	t1,40(a5)
ffffffffc0201742:	8302                	jr	t1
{
ffffffffc0201744:	1141                	addi	sp,sp,-16
ffffffffc0201746:	e406                	sd	ra,8(sp)
ffffffffc0201748:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020174a:	db1fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020174e:	00010797          	auipc	a5,0x10
ffffffffc0201752:	d4278793          	addi	a5,a5,-702 # ffffffffc0211490 <pmm_manager>
ffffffffc0201756:	639c                	ld	a5,0(a5)
ffffffffc0201758:	779c                	ld	a5,40(a5)
ffffffffc020175a:	9782                	jalr	a5
ffffffffc020175c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020175e:	d97fe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201762:	8522                	mv	a0,s0
ffffffffc0201764:	60a2                	ld	ra,8(sp)
ffffffffc0201766:	6402                	ld	s0,0(sp)
ffffffffc0201768:	0141                	addi	sp,sp,16
ffffffffc020176a:	8082                	ret

ffffffffc020176c <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
ffffffffc020176c:	715d                	addi	sp,sp,-80
ffffffffc020176e:	fc26                	sd	s1,56(sp)
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    // 找到对应的Giga Page
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201770:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201774:	1ff4f493          	andi	s1,s1,511
ffffffffc0201778:	048e                	slli	s1,s1,0x3
ffffffffc020177a:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V))
ffffffffc020177c:	6094                	ld	a3,0(s1)
{
ffffffffc020177e:	f84a                	sd	s2,48(sp)
ffffffffc0201780:	f44e                	sd	s3,40(sp)
ffffffffc0201782:	f052                	sd	s4,32(sp)
ffffffffc0201784:	e486                	sd	ra,72(sp)
ffffffffc0201786:	e0a2                	sd	s0,64(sp)
ffffffffc0201788:	ec56                	sd	s5,24(sp)
ffffffffc020178a:	e85a                	sd	s6,16(sp)
ffffffffc020178c:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc020178e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201792:	892e                	mv	s2,a1
ffffffffc0201794:	8a32                	mv	s4,a2
ffffffffc0201796:	00010997          	auipc	s3,0x10
ffffffffc020179a:	cc298993          	addi	s3,s3,-830 # ffffffffc0211458 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc020179e:	e3c9                	bnez	a5,ffffffffc0201820 <get_pte+0xb4>
    { // 如果下一级页表不存在，那就给它分配一页，创造新页表
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02017a0:	16060163          	beqz	a2,ffffffffc0201902 <get_pte+0x196>
ffffffffc02017a4:	4505                	li	a0,1
ffffffffc02017a6:	eb9ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc02017aa:	842a                	mv	s0,a0
ffffffffc02017ac:	14050b63          	beqz	a0,ffffffffc0201902 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017b0:	00010b97          	auipc	s7,0x10
ffffffffc02017b4:	cf8b8b93          	addi	s7,s7,-776 # ffffffffc02114a8 <pages>
ffffffffc02017b8:	000bb503          	ld	a0,0(s7)
ffffffffc02017bc:	00003797          	auipc	a5,0x3
ffffffffc02017c0:	52c78793          	addi	a5,a5,1324 # ffffffffc0204ce8 <commands+0x858>
ffffffffc02017c4:	0007bb03          	ld	s6,0(a5)
ffffffffc02017c8:	40a40533          	sub	a0,s0,a0
ffffffffc02017cc:	850d                	srai	a0,a0,0x3
ffffffffc02017ce:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017d2:	4785                	li	a5,1
        }
        set_page_ref(page, 1);
        // 我们现在在虚拟地址空间中，所以要转化为KADDR再memset.
        // 不管页表怎么构造，我们确保物理地址和虚拟地址的偏移量始终相同，那么就可以用这种方式完成对物理内存的访问。
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02017d4:	00010997          	auipc	s3,0x10
ffffffffc02017d8:	c8498993          	addi	s3,s3,-892 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017dc:	00080ab7          	lui	s5,0x80
ffffffffc02017e0:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017e4:	c01c                	sw	a5,0(s0)
ffffffffc02017e6:	57fd                	li	a5,-1
ffffffffc02017e8:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017ea:	9556                	add	a0,a0,s5
ffffffffc02017ec:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02017ee:	0532                	slli	a0,a0,0xc
ffffffffc02017f0:	16e7f063          	bleu	a4,a5,ffffffffc0201950 <get_pte+0x1e4>
ffffffffc02017f4:	00010797          	auipc	a5,0x10
ffffffffc02017f8:	ca478793          	addi	a5,a5,-860 # ffffffffc0211498 <va_pa_offset>
ffffffffc02017fc:	639c                	ld	a5,0(a5)
ffffffffc02017fe:	6605                	lui	a2,0x1
ffffffffc0201800:	4581                	li	a1,0
ffffffffc0201802:	953e                	add	a0,a0,a5
ffffffffc0201804:	339020ef          	jal	ra,ffffffffc020433c <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201808:	000bb683          	ld	a3,0(s7)
ffffffffc020180c:	40d406b3          	sub	a3,s0,a3
ffffffffc0201810:	868d                	srai	a3,a3,0x3
ffffffffc0201812:	036686b3          	mul	a3,a3,s6
ffffffffc0201816:	96d6                	add	a3,a3,s5
static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201818:	06aa                	slli	a3,a3,0xa
ffffffffc020181a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 注意这里R,W,X全零
ffffffffc020181e:	e094                	sd	a3,0(s1)
    }
    // 再下一级页表的页表项地址，从二级页表中查
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201820:	77fd                	lui	a5,0xfffff
ffffffffc0201822:	068a                	slli	a3,a3,0x2
ffffffffc0201824:	0009b703          	ld	a4,0(s3)
ffffffffc0201828:	8efd                	and	a3,a3,a5
ffffffffc020182a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020182e:	0ce7fc63          	bleu	a4,a5,ffffffffc0201906 <get_pte+0x19a>
ffffffffc0201832:	00010a97          	auipc	s5,0x10
ffffffffc0201836:	c66a8a93          	addi	s5,s5,-922 # ffffffffc0211498 <va_pa_offset>
ffffffffc020183a:	000ab403          	ld	s0,0(s5)
ffffffffc020183e:	01595793          	srli	a5,s2,0x15
ffffffffc0201842:	1ff7f793          	andi	a5,a5,511
ffffffffc0201846:	96a2                	add	a3,a3,s0
ffffffffc0201848:	00379413          	slli	s0,a5,0x3
ffffffffc020184c:	9436                	add	s0,s0,a3
    //    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    // 这里的逻辑和前面完全一致，页表不存在就现在分配一个
    if (!(*pdep0 & PTE_V))
ffffffffc020184e:	6014                	ld	a3,0(s0)
ffffffffc0201850:	0016f793          	andi	a5,a3,1
ffffffffc0201854:	ebbd                	bnez	a5,ffffffffc02018ca <get_pte+0x15e>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201856:	0a0a0663          	beqz	s4,ffffffffc0201902 <get_pte+0x196>
ffffffffc020185a:	4505                	li	a0,1
ffffffffc020185c:	e03ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201860:	84aa                	mv	s1,a0
ffffffffc0201862:	c145                	beqz	a0,ffffffffc0201902 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201864:	00010b97          	auipc	s7,0x10
ffffffffc0201868:	c44b8b93          	addi	s7,s7,-956 # ffffffffc02114a8 <pages>
ffffffffc020186c:	000bb503          	ld	a0,0(s7)
ffffffffc0201870:	00003797          	auipc	a5,0x3
ffffffffc0201874:	47878793          	addi	a5,a5,1144 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0201878:	0007bb03          	ld	s6,0(a5)
ffffffffc020187c:	40a48533          	sub	a0,s1,a0
ffffffffc0201880:	850d                	srai	a0,a0,0x3
ffffffffc0201882:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201886:	4785                	li	a5,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201888:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020188c:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201890:	c09c                	sw	a5,0(s1)
ffffffffc0201892:	57fd                	li	a5,-1
ffffffffc0201894:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201896:	9552                	add	a0,a0,s4
ffffffffc0201898:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020189a:	0532                	slli	a0,a0,0xc
ffffffffc020189c:	08e7fd63          	bleu	a4,a5,ffffffffc0201936 <get_pte+0x1ca>
ffffffffc02018a0:	000ab783          	ld	a5,0(s5)
ffffffffc02018a4:	6605                	lui	a2,0x1
ffffffffc02018a6:	4581                	li	a1,0
ffffffffc02018a8:	953e                	add	a0,a0,a5
ffffffffc02018aa:	293020ef          	jal	ra,ffffffffc020433c <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02018ae:	000bb683          	ld	a3,0(s7)
ffffffffc02018b2:	40d486b3          	sub	a3,s1,a3
ffffffffc02018b6:	868d                	srai	a3,a3,0x3
ffffffffc02018b8:	036686b3          	mul	a3,a3,s6
ffffffffc02018bc:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02018be:	06aa                	slli	a3,a3,0xa
ffffffffc02018c0:	0116e693          	ori	a3,a3,17
        //   	memset(pa, 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02018c4:	e014                	sd	a3,0(s0)
ffffffffc02018c6:	0009b703          	ld	a4,0(s3)
    }
    // 找到输入的虚拟地址la对应的页表项的地址(可能是刚刚分配的)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02018ca:	068a                	slli	a3,a3,0x2
ffffffffc02018cc:	757d                	lui	a0,0xfffff
ffffffffc02018ce:	8ee9                	and	a3,a3,a0
ffffffffc02018d0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018d4:	04e7f563          	bleu	a4,a5,ffffffffc020191e <get_pte+0x1b2>
ffffffffc02018d8:	000ab503          	ld	a0,0(s5)
ffffffffc02018dc:	00c95793          	srli	a5,s2,0xc
ffffffffc02018e0:	1ff7f793          	andi	a5,a5,511
ffffffffc02018e4:	96aa                	add	a3,a3,a0
ffffffffc02018e6:	00379513          	slli	a0,a5,0x3
ffffffffc02018ea:	9536                	add	a0,a0,a3
}
ffffffffc02018ec:	60a6                	ld	ra,72(sp)
ffffffffc02018ee:	6406                	ld	s0,64(sp)
ffffffffc02018f0:	74e2                	ld	s1,56(sp)
ffffffffc02018f2:	7942                	ld	s2,48(sp)
ffffffffc02018f4:	79a2                	ld	s3,40(sp)
ffffffffc02018f6:	7a02                	ld	s4,32(sp)
ffffffffc02018f8:	6ae2                	ld	s5,24(sp)
ffffffffc02018fa:	6b42                	ld	s6,16(sp)
ffffffffc02018fc:	6ba2                	ld	s7,8(sp)
ffffffffc02018fe:	6161                	addi	sp,sp,80
ffffffffc0201900:	8082                	ret
            return NULL;
ffffffffc0201902:	4501                	li	a0,0
ffffffffc0201904:	b7e5                	j	ffffffffc02018ec <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201906:	00003617          	auipc	a2,0x3
ffffffffc020190a:	7e260613          	addi	a2,a2,2018 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc020190e:	12400593          	li	a1,292
ffffffffc0201912:	00003517          	auipc	a0,0x3
ffffffffc0201916:	7fe50513          	addi	a0,a0,2046 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020191a:	a5bfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020191e:	00003617          	auipc	a2,0x3
ffffffffc0201922:	7ca60613          	addi	a2,a2,1994 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0201926:	13500593          	li	a1,309
ffffffffc020192a:	00003517          	auipc	a0,0x3
ffffffffc020192e:	7e650513          	addi	a0,a0,2022 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0201932:	a43fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201936:	86aa                	mv	a3,a0
ffffffffc0201938:	00003617          	auipc	a2,0x3
ffffffffc020193c:	7b060613          	addi	a2,a2,1968 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0201940:	13000593          	li	a1,304
ffffffffc0201944:	00003517          	auipc	a0,0x3
ffffffffc0201948:	7cc50513          	addi	a0,a0,1996 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020194c:	a29fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201950:	86aa                	mv	a3,a0
ffffffffc0201952:	00003617          	auipc	a2,0x3
ffffffffc0201956:	79660613          	addi	a2,a2,1942 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc020195a:	12000593          	li	a1,288
ffffffffc020195e:	00003517          	auipc	a0,0x3
ffffffffc0201962:	7b250513          	addi	a0,a0,1970 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0201966:	a0ffe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020196a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020196a:	1141                	addi	sp,sp,-16
ffffffffc020196c:	e022                	sd	s0,0(sp)
ffffffffc020196e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201970:	4601                	li	a2,0
{
ffffffffc0201972:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201974:	df9ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep_store != NULL)
ffffffffc0201978:	c011                	beqz	s0,ffffffffc020197c <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020197a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020197c:	c521                	beqz	a0,ffffffffc02019c4 <get_page+0x5a>
ffffffffc020197e:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201980:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201982:	0017f713          	andi	a4,a5,1
ffffffffc0201986:	e709                	bnez	a4,ffffffffc0201990 <get_page+0x26>
}
ffffffffc0201988:	60a2                	ld	ra,8(sp)
ffffffffc020198a:	6402                	ld	s0,0(sp)
ffffffffc020198c:	0141                	addi	sp,sp,16
ffffffffc020198e:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201990:	00010717          	auipc	a4,0x10
ffffffffc0201994:	ac870713          	addi	a4,a4,-1336 # ffffffffc0211458 <npage>
ffffffffc0201998:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020199a:	078a                	slli	a5,a5,0x2
ffffffffc020199c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020199e:	02e7f863          	bleu	a4,a5,ffffffffc02019ce <get_page+0x64>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc02019a2:	fff80537          	lui	a0,0xfff80
ffffffffc02019a6:	97aa                	add	a5,a5,a0
ffffffffc02019a8:	00010697          	auipc	a3,0x10
ffffffffc02019ac:	b0068693          	addi	a3,a3,-1280 # ffffffffc02114a8 <pages>
ffffffffc02019b0:	6288                	ld	a0,0(a3)
ffffffffc02019b2:	60a2                	ld	ra,8(sp)
ffffffffc02019b4:	6402                	ld	s0,0(sp)
ffffffffc02019b6:	00379713          	slli	a4,a5,0x3
ffffffffc02019ba:	97ba                	add	a5,a5,a4
ffffffffc02019bc:	078e                	slli	a5,a5,0x3
ffffffffc02019be:	953e                	add	a0,a0,a5
ffffffffc02019c0:	0141                	addi	sp,sp,16
ffffffffc02019c2:	8082                	ret
ffffffffc02019c4:	60a2                	ld	ra,8(sp)
ffffffffc02019c6:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02019c8:	4501                	li	a0,0
}
ffffffffc02019ca:	0141                	addi	sp,sp,16
ffffffffc02019cc:	8082                	ret
ffffffffc02019ce:	c75ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc02019d2 <page_remove>:

// page_remove - free an Page which is related linear address la and has an
// validated pte
// 删除la对应的映射
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc02019d2:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019d4:	4601                	li	a2,0
{
ffffffffc02019d6:	e406                	sd	ra,8(sp)
ffffffffc02019d8:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019da:	d93ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep != NULL)
ffffffffc02019de:	c511                	beqz	a0,ffffffffc02019ea <page_remove+0x18>
    if (*ptep & PTE_V)
ffffffffc02019e0:	611c                	ld	a5,0(a0)
ffffffffc02019e2:	842a                	mv	s0,a0
ffffffffc02019e4:	0017f713          	andi	a4,a5,1
ffffffffc02019e8:	e709                	bnez	a4,ffffffffc02019f2 <page_remove+0x20>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc02019ea:	60a2                	ld	ra,8(sp)
ffffffffc02019ec:	6402                	ld	s0,0(sp)
ffffffffc02019ee:	0141                	addi	sp,sp,16
ffffffffc02019f0:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02019f2:	00010717          	auipc	a4,0x10
ffffffffc02019f6:	a6670713          	addi	a4,a4,-1434 # ffffffffc0211458 <npage>
ffffffffc02019fa:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02019fc:	078a                	slli	a5,a5,0x2
ffffffffc02019fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201a00:	04e7f063          	bleu	a4,a5,ffffffffc0201a40 <page_remove+0x6e>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201a04:	fff80737          	lui	a4,0xfff80
ffffffffc0201a08:	97ba                	add	a5,a5,a4
ffffffffc0201a0a:	00010717          	auipc	a4,0x10
ffffffffc0201a0e:	a9e70713          	addi	a4,a4,-1378 # ffffffffc02114a8 <pages>
ffffffffc0201a12:	6308                	ld	a0,0(a4)
ffffffffc0201a14:	00379713          	slli	a4,a5,0x3
ffffffffc0201a18:	97ba                	add	a5,a5,a4
ffffffffc0201a1a:	078e                	slli	a5,a5,0x3
ffffffffc0201a1c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201a1e:	411c                	lw	a5,0(a0)
ffffffffc0201a20:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201a24:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201a26:	cb09                	beqz	a4,ffffffffc0201a38 <page_remove+0x66>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201a28:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a2c:	12000073          	sfence.vma
}
ffffffffc0201a30:	60a2                	ld	ra,8(sp)
ffffffffc0201a32:	6402                	ld	s0,0(sp)
ffffffffc0201a34:	0141                	addi	sp,sp,16
ffffffffc0201a36:	8082                	ret
            free_page(page);
ffffffffc0201a38:	4585                	li	a1,1
ffffffffc0201a3a:	cadff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0201a3e:	b7ed                	j	ffffffffc0201a28 <page_remove+0x56>
ffffffffc0201a40:	c03ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc0201a44 <page_insert>:
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
// pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
// 建立page和la的映射关系
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)
{
ffffffffc0201a44:	7179                	addi	sp,sp,-48
ffffffffc0201a46:	87b2                	mv	a5,a2
ffffffffc0201a48:	f022                	sd	s0,32(sp)
    // 先找到虚拟地址la对应页表项的位置，如果原先不存在，get_pte()会分配页表项的内存
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a4a:	4605                	li	a2,1
{
ffffffffc0201a4c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a4e:	85be                	mv	a1,a5
{
ffffffffc0201a50:	ec26                	sd	s1,24(sp)
ffffffffc0201a52:	f406                	sd	ra,40(sp)
ffffffffc0201a54:	e84a                	sd	s2,16(sp)
ffffffffc0201a56:	e44e                	sd	s3,8(sp)
ffffffffc0201a58:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a5a:	d13ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep == NULL)
ffffffffc0201a5e:	c945                	beqz	a0,ffffffffc0201b0e <page_insert+0xca>
    page->ref += 1;
ffffffffc0201a60:	4014                	lw	a3,0(s0)
    {
        return -E_NO_MEM;
    }
    page_ref_inc(page); // 指向这个物理页面的虚拟地址增加了一个
    // 如果原先存在映射
    if (*ptep & PTE_V)
ffffffffc0201a62:	611c                	ld	a5,0(a0)
ffffffffc0201a64:	892a                	mv	s2,a0
ffffffffc0201a66:	0016871b          	addiw	a4,a3,1
ffffffffc0201a6a:	c018                	sw	a4,0(s0)
ffffffffc0201a6c:	0017f713          	andi	a4,a5,1
ffffffffc0201a70:	e339                	bnez	a4,ffffffffc0201ab6 <page_insert+0x72>
ffffffffc0201a72:	00010797          	auipc	a5,0x10
ffffffffc0201a76:	a3678793          	addi	a5,a5,-1482 # ffffffffc02114a8 <pages>
ffffffffc0201a7a:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a7c:	00003717          	auipc	a4,0x3
ffffffffc0201a80:	26c70713          	addi	a4,a4,620 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0201a84:	40f407b3          	sub	a5,s0,a5
ffffffffc0201a88:	6300                	ld	s0,0(a4)
ffffffffc0201a8a:	878d                	srai	a5,a5,0x3
ffffffffc0201a8c:	000806b7          	lui	a3,0x80
ffffffffc0201a90:	028787b3          	mul	a5,a5,s0
ffffffffc0201a94:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201a96:	07aa                	slli	a5,a5,0xa
ffffffffc0201a98:	8fc5                	or	a5,a5,s1
ffffffffc0201a9a:	0017e793          	ori	a5,a5,1
        else
        { // 如果原先这个虚拟地址映射到其他物理页面，那么需要删除映射
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 构造页表项
ffffffffc0201a9e:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201aa2:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);                        // 页表改变之后要刷新TLB
    return 0;
ffffffffc0201aa6:	4501                	li	a0,0
}
ffffffffc0201aa8:	70a2                	ld	ra,40(sp)
ffffffffc0201aaa:	7402                	ld	s0,32(sp)
ffffffffc0201aac:	64e2                	ld	s1,24(sp)
ffffffffc0201aae:	6942                	ld	s2,16(sp)
ffffffffc0201ab0:	69a2                	ld	s3,8(sp)
ffffffffc0201ab2:	6145                	addi	sp,sp,48
ffffffffc0201ab4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201ab6:	00010717          	auipc	a4,0x10
ffffffffc0201aba:	9a270713          	addi	a4,a4,-1630 # ffffffffc0211458 <npage>
ffffffffc0201abe:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ac0:	00279513          	slli	a0,a5,0x2
ffffffffc0201ac4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage)
ffffffffc0201ac6:	04e57663          	bleu	a4,a0,ffffffffc0201b12 <page_insert+0xce>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201aca:	fff807b7          	lui	a5,0xfff80
ffffffffc0201ace:	953e                	add	a0,a0,a5
ffffffffc0201ad0:	00010997          	auipc	s3,0x10
ffffffffc0201ad4:	9d898993          	addi	s3,s3,-1576 # ffffffffc02114a8 <pages>
ffffffffc0201ad8:	0009b783          	ld	a5,0(s3)
ffffffffc0201adc:	00351713          	slli	a4,a0,0x3
ffffffffc0201ae0:	953a                	add	a0,a0,a4
ffffffffc0201ae2:	050e                	slli	a0,a0,0x3
ffffffffc0201ae4:	953e                	add	a0,a0,a5
        if (p == page)
ffffffffc0201ae6:	00a40e63          	beq	s0,a0,ffffffffc0201b02 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0201aea:	411c                	lw	a5,0(a0)
ffffffffc0201aec:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201af0:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201af2:	cb11                	beqz	a4,ffffffffc0201b06 <page_insert+0xc2>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201af4:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201af8:	12000073          	sfence.vma
ffffffffc0201afc:	0009b783          	ld	a5,0(s3)
ffffffffc0201b00:	bfb5                	j	ffffffffc0201a7c <page_insert+0x38>
    page->ref -= 1;
ffffffffc0201b02:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201b04:	bfa5                	j	ffffffffc0201a7c <page_insert+0x38>
            free_page(page);
ffffffffc0201b06:	4585                	li	a1,1
ffffffffc0201b08:	bdfff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0201b0c:	b7e5                	j	ffffffffc0201af4 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0201b0e:	5571                	li	a0,-4
ffffffffc0201b10:	bf61                	j	ffffffffc0201aa8 <page_insert+0x64>
ffffffffc0201b12:	b31ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc0201b16 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201b16:	00003797          	auipc	a5,0x3
ffffffffc0201b1a:	58278793          	addi	a5,a5,1410 # ffffffffc0205098 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b1e:	638c                	ld	a1,0(a5)
{
ffffffffc0201b20:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b22:	00003517          	auipc	a0,0x3
ffffffffc0201b26:	68650513          	addi	a0,a0,1670 # ffffffffc02051a8 <default_pmm_manager+0x110>
{
ffffffffc0201b2a:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b2c:	00010717          	auipc	a4,0x10
ffffffffc0201b30:	96f73223          	sd	a5,-1692(a4) # ffffffffc0211490 <pmm_manager>
{
ffffffffc0201b34:	e8a2                	sd	s0,80(sp)
ffffffffc0201b36:	e4a6                	sd	s1,72(sp)
ffffffffc0201b38:	e0ca                	sd	s2,64(sp)
ffffffffc0201b3a:	fc4e                	sd	s3,56(sp)
ffffffffc0201b3c:	f852                	sd	s4,48(sp)
ffffffffc0201b3e:	f456                	sd	s5,40(sp)
ffffffffc0201b40:	f05a                	sd	s6,32(sp)
ffffffffc0201b42:	ec5e                	sd	s7,24(sp)
ffffffffc0201b44:	e862                	sd	s8,16(sp)
ffffffffc0201b46:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b48:	00010417          	auipc	s0,0x10
ffffffffc0201b4c:	94840413          	addi	s0,s0,-1720 # ffffffffc0211490 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b50:	d6efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0201b54:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201b56:	49c5                	li	s3,17
ffffffffc0201b58:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0201b5c:	679c                	ld	a5,8(a5)
ffffffffc0201b5e:	00010497          	auipc	s1,0x10
ffffffffc0201b62:	8fa48493          	addi	s1,s1,-1798 # ffffffffc0211458 <npage>
ffffffffc0201b66:	00010917          	auipc	s2,0x10
ffffffffc0201b6a:	94290913          	addi	s2,s2,-1726 # ffffffffc02114a8 <pages>
ffffffffc0201b6e:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b70:	57f5                	li	a5,-3
ffffffffc0201b72:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201b74:	07e006b7          	lui	a3,0x7e00
ffffffffc0201b78:	01b99613          	slli	a2,s3,0x1b
ffffffffc0201b7c:	015a1593          	slli	a1,s4,0x15
ffffffffc0201b80:	00003517          	auipc	a0,0x3
ffffffffc0201b84:	64050513          	addi	a0,a0,1600 # ffffffffc02051c0 <default_pmm_manager+0x128>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b88:	00010717          	auipc	a4,0x10
ffffffffc0201b8c:	90f73823          	sd	a5,-1776(a4) # ffffffffc0211498 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201b90:	d2efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201b94:	00003517          	auipc	a0,0x3
ffffffffc0201b98:	65c50513          	addi	a0,a0,1628 # ffffffffc02051f0 <default_pmm_manager+0x158>
ffffffffc0201b9c:	d22fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201ba0:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201ba4:	16fd                	addi	a3,a3,-1
ffffffffc0201ba6:	015a1613          	slli	a2,s4,0x15
ffffffffc0201baa:	07e005b7          	lui	a1,0x7e00
ffffffffc0201bae:	00003517          	auipc	a0,0x3
ffffffffc0201bb2:	65a50513          	addi	a0,a0,1626 # ffffffffc0205208 <default_pmm_manager+0x170>
ffffffffc0201bb6:	d08fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bba:	777d                	lui	a4,0xfffff
ffffffffc0201bbc:	00011797          	auipc	a5,0x11
ffffffffc0201bc0:	9db78793          	addi	a5,a5,-1573 # ffffffffc0212597 <end+0xfff>
ffffffffc0201bc4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201bc6:	00088737          	lui	a4,0x88
ffffffffc0201bca:	00010697          	auipc	a3,0x10
ffffffffc0201bce:	88e6b723          	sd	a4,-1906(a3) # ffffffffc0211458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bd2:	00010717          	auipc	a4,0x10
ffffffffc0201bd6:	8cf73b23          	sd	a5,-1834(a4) # ffffffffc02114a8 <pages>
ffffffffc0201bda:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201bdc:	4701                	li	a4,0
ffffffffc0201bde:	4585                	li	a1,1
ffffffffc0201be0:	fff80637          	lui	a2,0xfff80
ffffffffc0201be4:	a019                	j	ffffffffc0201bea <pmm_init+0xd4>
ffffffffc0201be6:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201bea:	97b6                	add	a5,a5,a3
ffffffffc0201bec:	07a1                	addi	a5,a5,8
ffffffffc0201bee:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201bf2:	609c                	ld	a5,0(s1)
ffffffffc0201bf4:	0705                	addi	a4,a4,1
ffffffffc0201bf6:	04868693          	addi	a3,a3,72
ffffffffc0201bfa:	00c78533          	add	a0,a5,a2
ffffffffc0201bfe:	fea764e3          	bltu	a4,a0,ffffffffc0201be6 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c02:	00093503          	ld	a0,0(s2)
ffffffffc0201c06:	00379693          	slli	a3,a5,0x3
ffffffffc0201c0a:	96be                	add	a3,a3,a5
ffffffffc0201c0c:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201c10:	972a                	add	a4,a4,a0
ffffffffc0201c12:	068e                	slli	a3,a3,0x3
ffffffffc0201c14:	96ba                	add	a3,a3,a4
ffffffffc0201c16:	c0200737          	lui	a4,0xc0200
ffffffffc0201c1a:	58e6ea63          	bltu	a3,a4,ffffffffc02021ae <pmm_init+0x698>
ffffffffc0201c1e:	00010997          	auipc	s3,0x10
ffffffffc0201c22:	87a98993          	addi	s3,s3,-1926 # ffffffffc0211498 <va_pa_offset>
ffffffffc0201c26:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end)
ffffffffc0201c2a:	45c5                	li	a1,17
ffffffffc0201c2c:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c2e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end)
ffffffffc0201c30:	44b6ef63          	bltu	a3,a1,ffffffffc020208e <pmm_init+0x578>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201c34:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc0201c36:	00010417          	auipc	s0,0x10
ffffffffc0201c3a:	81a40413          	addi	s0,s0,-2022 # ffffffffc0211450 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201c3e:	7b9c                	ld	a5,48(a5)
ffffffffc0201c40:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201c42:	00003517          	auipc	a0,0x3
ffffffffc0201c46:	61650513          	addi	a0,a0,1558 # ffffffffc0205258 <default_pmm_manager+0x1c0>
ffffffffc0201c4a:	c74fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc0201c4e:	00007697          	auipc	a3,0x7
ffffffffc0201c52:	3b268693          	addi	a3,a3,946 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201c56:	0000f797          	auipc	a5,0xf
ffffffffc0201c5a:	7ed7bd23          	sd	a3,2042(a5) # ffffffffc0211450 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201c5e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c62:	0ef6ece3          	bltu	a3,a5,ffffffffc020255a <pmm_init+0xa44>
ffffffffc0201c66:	0009b783          	ld	a5,0(s3)
ffffffffc0201c6a:	8e9d                	sub	a3,a3,a5
ffffffffc0201c6c:	00010797          	auipc	a5,0x10
ffffffffc0201c70:	82d7ba23          	sd	a3,-1996(a5) # ffffffffc02114a0 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();
ffffffffc0201c74:	ab9ff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c78:	6098                	ld	a4,0(s1)
ffffffffc0201c7a:	c80007b7          	lui	a5,0xc8000
ffffffffc0201c7e:	83b1                	srli	a5,a5,0xc
    nr_free_store = nr_free_pages();
ffffffffc0201c80:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c82:	0ae7ece3          	bltu	a5,a4,ffffffffc020253a <pmm_init+0xa24>
    // boot_pgdir是页表的虚拟地址
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c86:	6008                	ld	a0,0(s0)
ffffffffc0201c88:	4c050363          	beqz	a0,ffffffffc020214e <pmm_init+0x638>
ffffffffc0201c8c:	6785                	lui	a5,0x1
ffffffffc0201c8e:	17fd                	addi	a5,a5,-1
ffffffffc0201c90:	8fe9                	and	a5,a5,a0
ffffffffc0201c92:	2781                	sext.w	a5,a5
ffffffffc0201c94:	4a079d63          	bnez	a5,ffffffffc020214e <pmm_init+0x638>
    // get_page()尝试找到虚拟内存0x0对应的页，现在当然是没有的，返回NULL
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201c98:	4601                	li	a2,0
ffffffffc0201c9a:	4581                	li	a1,0
ffffffffc0201c9c:	ccfff0ef          	jal	ra,ffffffffc020196a <get_page>
ffffffffc0201ca0:	4c051763          	bnez	a0,ffffffffc020216e <pmm_init+0x658>

    struct Page *p1, *p2;
    p1 = alloc_page();                                // 拿过来一个物理页面
ffffffffc0201ca4:	4505                	li	a0,1
ffffffffc0201ca6:	9b9ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201caa:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0); // 把这个物理页面通过多级页表映射到0x0
ffffffffc0201cac:	6008                	ld	a0,0(s0)
ffffffffc0201cae:	4681                	li	a3,0
ffffffffc0201cb0:	4601                	li	a2,0
ffffffffc0201cb2:	85d6                	mv	a1,s5
ffffffffc0201cb4:	d91ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201cb8:	52051763          	bnez	a0,ffffffffc02021e6 <pmm_init+0x6d0>
    // 64位地址的指针，指向pte
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201cbc:	6008                	ld	a0,0(s0)
ffffffffc0201cbe:	4601                	li	a2,0
ffffffffc0201cc0:	4581                	li	a1,0
ffffffffc0201cc2:	aabff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201cc6:	50050063          	beqz	a0,ffffffffc02021c6 <pmm_init+0x6b0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201cca:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201ccc:	0017f713          	andi	a4,a5,1
ffffffffc0201cd0:	46070363          	beqz	a4,ffffffffc0202136 <pmm_init+0x620>
    if (PPN(pa) >= npage)
ffffffffc0201cd4:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201cd6:	078a                	slli	a5,a5,0x2
ffffffffc0201cd8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201cda:	44c7f063          	bleu	a2,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201cde:	fff80737          	lui	a4,0xfff80
ffffffffc0201ce2:	97ba                	add	a5,a5,a4
ffffffffc0201ce4:	00379713          	slli	a4,a5,0x3
ffffffffc0201ce8:	00093683          	ld	a3,0(s2)
ffffffffc0201cec:	97ba                	add	a5,a5,a4
ffffffffc0201cee:	078e                	slli	a5,a5,0x3
ffffffffc0201cf0:	97b6                	add	a5,a5,a3
ffffffffc0201cf2:	5efa9463          	bne	s5,a5,ffffffffc02022da <pmm_init+0x7c4>
    // page_ref用来检查映射关系是否实现，返回值是当前物理页的引用次数
    assert(page_ref(p1) == 1);
ffffffffc0201cf6:	000aab83          	lw	s7,0(s5)
ffffffffc0201cfa:	4785                	li	a5,1
ffffffffc0201cfc:	5afb9f63          	bne	s7,a5,ffffffffc02022ba <pmm_init+0x7a4>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201d00:	6008                	ld	a0,0(s0)
ffffffffc0201d02:	76fd                	lui	a3,0xfffff
ffffffffc0201d04:	611c                	ld	a5,0(a0)
ffffffffc0201d06:	078a                	slli	a5,a5,0x2
ffffffffc0201d08:	8ff5                	and	a5,a5,a3
ffffffffc0201d0a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201d0e:	58c77963          	bleu	a2,a4,ffffffffc02022a0 <pmm_init+0x78a>
ffffffffc0201d12:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d16:	97e2                	add	a5,a5,s8
ffffffffc0201d18:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201d1c:	0b0a                	slli	s6,s6,0x2
ffffffffc0201d1e:	00db7b33          	and	s6,s6,a3
ffffffffc0201d22:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201d26:	56c7f063          	bleu	a2,a5,ffffffffc0202286 <pmm_init+0x770>
    // get_pte查找某个虚拟地址对应的页表项，如果不存在这个页表项，会为它分配各级的页表
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d2a:	4601                	li	a2,0
ffffffffc0201d2c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d2e:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d30:	a3dff0ef          	jal	ra,ffffffffc020176c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d34:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d36:	53651863          	bne	a0,s6,ffffffffc0202266 <pmm_init+0x750>

    p2 = alloc_page();
ffffffffc0201d3a:	4505                	li	a0,1
ffffffffc0201d3c:	923ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201d40:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d42:	6008                	ld	a0,0(s0)
ffffffffc0201d44:	46d1                	li	a3,20
ffffffffc0201d46:	6605                	lui	a2,0x1
ffffffffc0201d48:	85da                	mv	a1,s6
ffffffffc0201d4a:	cfbff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201d4e:	4e051c63          	bnez	a0,ffffffffc0202246 <pmm_init+0x730>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d52:	6008                	ld	a0,0(s0)
ffffffffc0201d54:	4601                	li	a2,0
ffffffffc0201d56:	6585                	lui	a1,0x1
ffffffffc0201d58:	a15ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201d5c:	4c050563          	beqz	a0,ffffffffc0202226 <pmm_init+0x710>
    assert(*ptep & PTE_U);
ffffffffc0201d60:	611c                	ld	a5,0(a0)
ffffffffc0201d62:	0107f713          	andi	a4,a5,16
ffffffffc0201d66:	4a070063          	beqz	a4,ffffffffc0202206 <pmm_init+0x6f0>
    assert(*ptep & PTE_W);
ffffffffc0201d6a:	8b91                	andi	a5,a5,4
ffffffffc0201d6c:	66078763          	beqz	a5,ffffffffc02023da <pmm_init+0x8c4>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d70:	6008                	ld	a0,0(s0)
ffffffffc0201d72:	611c                	ld	a5,0(a0)
ffffffffc0201d74:	8bc1                	andi	a5,a5,16
ffffffffc0201d76:	64078263          	beqz	a5,ffffffffc02023ba <pmm_init+0x8a4>
    assert(page_ref(p2) == 1);
ffffffffc0201d7a:	000b2783          	lw	a5,0(s6)
ffffffffc0201d7e:	61779e63          	bne	a5,s7,ffffffffc020239a <pmm_init+0x884>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201d82:	4681                	li	a3,0
ffffffffc0201d84:	6605                	lui	a2,0x1
ffffffffc0201d86:	85d6                	mv	a1,s5
ffffffffc0201d88:	cbdff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201d8c:	5e051763          	bnez	a0,ffffffffc020237a <pmm_init+0x864>
    assert(page_ref(p1) == 2);
ffffffffc0201d90:	000aa703          	lw	a4,0(s5)
ffffffffc0201d94:	4789                	li	a5,2
ffffffffc0201d96:	5cf71263          	bne	a4,a5,ffffffffc020235a <pmm_init+0x844>
    assert(page_ref(p2) == 0);
ffffffffc0201d9a:	000b2783          	lw	a5,0(s6)
ffffffffc0201d9e:	58079e63          	bnez	a5,ffffffffc020233a <pmm_init+0x824>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201da2:	6008                	ld	a0,0(s0)
ffffffffc0201da4:	4601                	li	a2,0
ffffffffc0201da6:	6585                	lui	a1,0x1
ffffffffc0201da8:	9c5ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201dac:	56050763          	beqz	a0,ffffffffc020231a <pmm_init+0x804>
    assert(pte2page(*ptep) == p1);
ffffffffc0201db0:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201db2:	0016f793          	andi	a5,a3,1
ffffffffc0201db6:	38078063          	beqz	a5,ffffffffc0202136 <pmm_init+0x620>
    if (PPN(pa) >= npage)
ffffffffc0201dba:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201dbc:	00269793          	slli	a5,a3,0x2
ffffffffc0201dc0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201dc2:	34e7fc63          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201dc6:	fff80737          	lui	a4,0xfff80
ffffffffc0201dca:	97ba                	add	a5,a5,a4
ffffffffc0201dcc:	00379713          	slli	a4,a5,0x3
ffffffffc0201dd0:	00093603          	ld	a2,0(s2)
ffffffffc0201dd4:	97ba                	add	a5,a5,a4
ffffffffc0201dd6:	078e                	slli	a5,a5,0x3
ffffffffc0201dd8:	97b2                	add	a5,a5,a2
ffffffffc0201dda:	52fa9063          	bne	s5,a5,ffffffffc02022fa <pmm_init+0x7e4>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201dde:	8ac1                	andi	a3,a3,16
ffffffffc0201de0:	6e069d63          	bnez	a3,ffffffffc02024da <pmm_init+0x9c4>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201de4:	6008                	ld	a0,0(s0)
ffffffffc0201de6:	4581                	li	a1,0
ffffffffc0201de8:	bebff0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201dec:	000aa703          	lw	a4,0(s5)
ffffffffc0201df0:	4785                	li	a5,1
ffffffffc0201df2:	6cf71463          	bne	a4,a5,ffffffffc02024ba <pmm_init+0x9a4>
    assert(page_ref(p2) == 0);
ffffffffc0201df6:	000b2783          	lw	a5,0(s6)
ffffffffc0201dfa:	6a079063          	bnez	a5,ffffffffc020249a <pmm_init+0x984>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201dfe:	6008                	ld	a0,0(s0)
ffffffffc0201e00:	6585                	lui	a1,0x1
ffffffffc0201e02:	bd1ff0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201e06:	000aa783          	lw	a5,0(s5)
ffffffffc0201e0a:	66079863          	bnez	a5,ffffffffc020247a <pmm_init+0x964>
    assert(page_ref(p2) == 0);
ffffffffc0201e0e:	000b2783          	lw	a5,0(s6)
ffffffffc0201e12:	70079463          	bnez	a5,ffffffffc020251a <pmm_init+0xa04>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e16:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0201e1a:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e1c:	000b3783          	ld	a5,0(s6)
ffffffffc0201e20:	078a                	slli	a5,a5,0x2
ffffffffc0201e22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201e24:	2eb7fb63          	bleu	a1,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201e28:	fff80737          	lui	a4,0xfff80
ffffffffc0201e2c:	973e                	add	a4,a4,a5
ffffffffc0201e2e:	00371793          	slli	a5,a4,0x3
ffffffffc0201e32:	00093603          	ld	a2,0(s2)
ffffffffc0201e36:	97ba                	add	a5,a5,a4
ffffffffc0201e38:	078e                	slli	a5,a5,0x3
ffffffffc0201e3a:	00f60733          	add	a4,a2,a5
ffffffffc0201e3e:	4314                	lw	a3,0(a4)
ffffffffc0201e40:	4705                	li	a4,1
ffffffffc0201e42:	6ae69c63          	bne	a3,a4,ffffffffc02024fa <pmm_init+0x9e4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e46:	00003a97          	auipc	s5,0x3
ffffffffc0201e4a:	ea2a8a93          	addi	s5,s5,-350 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0201e4e:	000ab703          	ld	a4,0(s5)
ffffffffc0201e52:	4037d693          	srai	a3,a5,0x3
ffffffffc0201e56:	00080bb7          	lui	s7,0x80
ffffffffc0201e5a:	02e686b3          	mul	a3,a3,a4
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e5e:	577d                	li	a4,-1
ffffffffc0201e60:	8331                	srli	a4,a4,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e62:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e64:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e66:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e68:	2ab77b63          	bleu	a1,a4,ffffffffc020211e <pmm_init+0x608>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201e6c:	0009b783          	ld	a5,0(s3)
ffffffffc0201e70:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e72:	629c                	ld	a5,0(a3)
ffffffffc0201e74:	078a                	slli	a5,a5,0x2
ffffffffc0201e76:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201e78:	2ab7f163          	bleu	a1,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201e7c:	417787b3          	sub	a5,a5,s7
ffffffffc0201e80:	00379513          	slli	a0,a5,0x3
ffffffffc0201e84:	97aa                	add	a5,a5,a0
ffffffffc0201e86:	00379513          	slli	a0,a5,0x3
ffffffffc0201e8a:	9532                	add	a0,a0,a2
ffffffffc0201e8c:	4585                	li	a1,1
ffffffffc0201e8e:	859ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e92:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage)
ffffffffc0201e96:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e98:	050a                	slli	a0,a0,0x2
ffffffffc0201e9a:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage)
ffffffffc0201e9c:	26f57f63          	bleu	a5,a0,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201ea0:	417507b3          	sub	a5,a0,s7
ffffffffc0201ea4:	00379513          	slli	a0,a5,0x3
ffffffffc0201ea8:	00093703          	ld	a4,0(s2)
ffffffffc0201eac:	953e                	add	a0,a0,a5
ffffffffc0201eae:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0201eb0:	4585                	li	a1,1
ffffffffc0201eb2:	953a                	add	a0,a0,a4
ffffffffc0201eb4:	833ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    boot_pgdir[0] = 0; // 清除测试的痕迹
ffffffffc0201eb8:	601c                	ld	a5,0(s0)
ffffffffc0201eba:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store == nr_free_pages());
ffffffffc0201ebe:	86fff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0201ec2:	2caa1663          	bne	s4,a0,ffffffffc020218e <pmm_init+0x678>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201ec6:	00003517          	auipc	a0,0x3
ffffffffc0201eca:	6aa50513          	addi	a0,a0,1706 # ffffffffc0205570 <default_pmm_manager+0x4d8>
ffffffffc0201ece:	9f0fe0ef          	jal	ra,ffffffffc02000be <cprintf>
{
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();
ffffffffc0201ed2:	85bff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201ed6:	6098                	ld	a4,0(s1)
ffffffffc0201ed8:	c02007b7          	lui	a5,0xc0200
    nr_free_store = nr_free_pages();
ffffffffc0201edc:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201ede:	00c71693          	slli	a3,a4,0xc
ffffffffc0201ee2:	1cd7fd63          	bleu	a3,a5,ffffffffc02020bc <pmm_init+0x5a6>
    {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ee6:	83b1                	srli	a5,a5,0xc
ffffffffc0201ee8:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201eea:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201eee:	1ce7f963          	bleu	a4,a5,ffffffffc02020c0 <pmm_init+0x5aa>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201ef2:	7c7d                	lui	s8,0xfffff
ffffffffc0201ef4:	6b85                	lui	s7,0x1
ffffffffc0201ef6:	a029                	j	ffffffffc0201f00 <pmm_init+0x3ea>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ef8:	00ca5713          	srli	a4,s4,0xc
ffffffffc0201efc:	1cf77263          	bleu	a5,a4,ffffffffc02020c0 <pmm_init+0x5aa>
ffffffffc0201f00:	0009b583          	ld	a1,0(s3)
ffffffffc0201f04:	4601                	li	a2,0
ffffffffc0201f06:	95d2                	add	a1,a1,s4
ffffffffc0201f08:	865ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201f0c:	1c050763          	beqz	a0,ffffffffc02020da <pmm_init+0x5c4>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f10:	611c                	ld	a5,0(a0)
ffffffffc0201f12:	078a                	slli	a5,a5,0x2
ffffffffc0201f14:	0187f7b3          	and	a5,a5,s8
ffffffffc0201f18:	1f479163          	bne	a5,s4,ffffffffc02020fa <pmm_init+0x5e4>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201f1c:	609c                	ld	a5,0(s1)
ffffffffc0201f1e:	9a5e                	add	s4,s4,s7
ffffffffc0201f20:	6008                	ld	a0,0(s0)
ffffffffc0201f22:	00c79713          	slli	a4,a5,0xc
ffffffffc0201f26:	fcea69e3          	bltu	s4,a4,ffffffffc0201ef8 <pmm_init+0x3e2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0201f2a:	611c                	ld	a5,0(a0)
ffffffffc0201f2c:	6a079363          	bnez	a5,ffffffffc02025d2 <pmm_init+0xabc>

    struct Page *p;
    p = alloc_page();
ffffffffc0201f30:	4505                	li	a0,1
ffffffffc0201f32:	f2cff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201f36:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201f38:	6008                	ld	a0,0(s0)
ffffffffc0201f3a:	4699                	li	a3,6
ffffffffc0201f3c:	10000613          	li	a2,256
ffffffffc0201f40:	85d2                	mv	a1,s4
ffffffffc0201f42:	b03ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201f46:	66051663          	bnez	a0,ffffffffc02025b2 <pmm_init+0xa9c>
    assert(page_ref(p) == 1);
ffffffffc0201f4a:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc0201f4e:	4785                	li	a5,1
ffffffffc0201f50:	64f71163          	bne	a4,a5,ffffffffc0202592 <pmm_init+0xa7c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201f54:	6008                	ld	a0,0(s0)
ffffffffc0201f56:	6b85                	lui	s7,0x1
ffffffffc0201f58:	4699                	li	a3,6
ffffffffc0201f5a:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc0201f5e:	85d2                	mv	a1,s4
ffffffffc0201f60:	ae5ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201f64:	60051763          	bnez	a0,ffffffffc0202572 <pmm_init+0xa5c>
    assert(page_ref(p) == 2);
ffffffffc0201f68:	000a2703          	lw	a4,0(s4)
ffffffffc0201f6c:	4789                	li	a5,2
ffffffffc0201f6e:	4ef71663          	bne	a4,a5,ffffffffc020245a <pmm_init+0x944>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201f72:	00003597          	auipc	a1,0x3
ffffffffc0201f76:	73658593          	addi	a1,a1,1846 # ffffffffc02056a8 <default_pmm_manager+0x610>
ffffffffc0201f7a:	10000513          	li	a0,256
ffffffffc0201f7e:	364020ef          	jal	ra,ffffffffc02042e2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201f82:	100b8593          	addi	a1,s7,256
ffffffffc0201f86:	10000513          	li	a0,256
ffffffffc0201f8a:	36a020ef          	jal	ra,ffffffffc02042f4 <strcmp>
ffffffffc0201f8e:	4a051663          	bnez	a0,ffffffffc020243a <pmm_init+0x924>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201f92:	00093683          	ld	a3,0(s2)
ffffffffc0201f96:	000abc83          	ld	s9,0(s5)
ffffffffc0201f9a:	00080c37          	lui	s8,0x80
ffffffffc0201f9e:	40da06b3          	sub	a3,s4,a3
ffffffffc0201fa2:	868d                	srai	a3,a3,0x3
ffffffffc0201fa4:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fa8:	5afd                	li	s5,-1
ffffffffc0201faa:	609c                	ld	a5,0(s1)
ffffffffc0201fac:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fb0:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fb2:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fb6:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fb8:	16f77363          	bleu	a5,a4,ffffffffc020211e <pmm_init+0x608>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fbc:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fc0:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fc4:	96be                	add	a3,a3,a5
ffffffffc0201fc6:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb68>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fca:	2d4020ef          	jal	ra,ffffffffc020429e <strlen>
ffffffffc0201fce:	44051663          	bnez	a0,ffffffffc020241a <pmm_init+0x904>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201fd2:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0201fd6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201fd8:	000bb783          	ld	a5,0(s7)
ffffffffc0201fdc:	078a                	slli	a5,a5,0x2
ffffffffc0201fde:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fe0:	12e7fd63          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0201fe4:	418787b3          	sub	a5,a5,s8
ffffffffc0201fe8:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fec:	96be                	add	a3,a3,a5
ffffffffc0201fee:	039686b3          	mul	a3,a3,s9
ffffffffc0201ff2:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ff4:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ff8:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ffa:	12eaf263          	bleu	a4,s5,ffffffffc020211e <pmm_init+0x608>
ffffffffc0201ffe:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202002:	4585                	li	a1,1
ffffffffc0202004:	8552                	mv	a0,s4
ffffffffc0202006:	99b6                	add	s3,s3,a3
ffffffffc0202008:	edeff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020200c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202010:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202012:	078a                	slli	a5,a5,0x2
ffffffffc0202014:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202016:	10e7f263          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc020201a:	fff809b7          	lui	s3,0xfff80
ffffffffc020201e:	97ce                	add	a5,a5,s3
ffffffffc0202020:	00379513          	slli	a0,a5,0x3
ffffffffc0202024:	00093703          	ld	a4,0(s2)
ffffffffc0202028:	97aa                	add	a5,a5,a0
ffffffffc020202a:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc020202e:	953a                	add	a0,a0,a4
ffffffffc0202030:	4585                	li	a1,1
ffffffffc0202032:	eb4ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202036:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage)
ffffffffc020203a:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020203c:	050a                	slli	a0,a0,0x2
ffffffffc020203e:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage)
ffffffffc0202040:	0cf57d63          	bleu	a5,a0,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0202044:	013507b3          	add	a5,a0,s3
ffffffffc0202048:	00379513          	slli	a0,a5,0x3
ffffffffc020204c:	00093703          	ld	a4,0(s2)
ffffffffc0202050:	953e                	add	a0,a0,a5
ffffffffc0202052:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0202054:	4585                	li	a1,1
ffffffffc0202056:	953a                	add	a0,a0,a4
ffffffffc0202058:	e8eff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc020205c:	601c                	ld	a5,0(s0)
ffffffffc020205e:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store == nr_free_pages());
ffffffffc0202062:	ecaff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0202066:	38ab1a63          	bne	s6,a0,ffffffffc02023fa <pmm_init+0x8e4>
}
ffffffffc020206a:	6446                	ld	s0,80(sp)
ffffffffc020206c:	60e6                	ld	ra,88(sp)
ffffffffc020206e:	64a6                	ld	s1,72(sp)
ffffffffc0202070:	6906                	ld	s2,64(sp)
ffffffffc0202072:	79e2                	ld	s3,56(sp)
ffffffffc0202074:	7a42                	ld	s4,48(sp)
ffffffffc0202076:	7aa2                	ld	s5,40(sp)
ffffffffc0202078:	7b02                	ld	s6,32(sp)
ffffffffc020207a:	6be2                	ld	s7,24(sp)
ffffffffc020207c:	6c42                	ld	s8,16(sp)
ffffffffc020207e:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202080:	00003517          	auipc	a0,0x3
ffffffffc0202084:	6a050513          	addi	a0,a0,1696 # ffffffffc0205720 <default_pmm_manager+0x688>
}
ffffffffc0202088:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020208a:	834fe06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020208e:	6705                	lui	a4,0x1
ffffffffc0202090:	177d                	addi	a4,a4,-1
ffffffffc0202092:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0202094:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202098:	08f77163          	bleu	a5,a4,ffffffffc020211a <pmm_init+0x604>
    pmm_manager->init_memmap(base, n);
ffffffffc020209c:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc02020a0:	9732                	add	a4,a4,a2
ffffffffc02020a2:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02020a6:	767d                	lui	a2,0xfffff
ffffffffc02020a8:	8ef1                	and	a3,a3,a2
ffffffffc02020aa:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc02020ac:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02020b0:	8d95                	sub	a1,a1,a3
ffffffffc02020b2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02020b4:	81b1                	srli	a1,a1,0xc
ffffffffc02020b6:	953e                	add	a0,a0,a5
ffffffffc02020b8:	9702                	jalr	a4
ffffffffc02020ba:	bead                	j	ffffffffc0201c34 <pmm_init+0x11e>
ffffffffc02020bc:	6008                	ld	a0,0(s0)
ffffffffc02020be:	b5b5                	j	ffffffffc0201f2a <pmm_init+0x414>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02020c0:	86d2                	mv	a3,s4
ffffffffc02020c2:	00003617          	auipc	a2,0x3
ffffffffc02020c6:	02660613          	addi	a2,a2,38 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc02020ca:	21400593          	li	a1,532
ffffffffc02020ce:	00003517          	auipc	a0,0x3
ffffffffc02020d2:	04250513          	addi	a0,a0,66 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02020d6:	a9efe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02020da:	00003697          	auipc	a3,0x3
ffffffffc02020de:	4b668693          	addi	a3,a3,1206 # ffffffffc0205590 <default_pmm_manager+0x4f8>
ffffffffc02020e2:	00003617          	auipc	a2,0x3
ffffffffc02020e6:	c1e60613          	addi	a2,a2,-994 # ffffffffc0204d00 <commands+0x870>
ffffffffc02020ea:	21400593          	li	a1,532
ffffffffc02020ee:	00003517          	auipc	a0,0x3
ffffffffc02020f2:	02250513          	addi	a0,a0,34 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02020f6:	a7efe0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02020fa:	00003697          	auipc	a3,0x3
ffffffffc02020fe:	4d668693          	addi	a3,a3,1238 # ffffffffc02055d0 <default_pmm_manager+0x538>
ffffffffc0202102:	00003617          	auipc	a2,0x3
ffffffffc0202106:	bfe60613          	addi	a2,a2,-1026 # ffffffffc0204d00 <commands+0x870>
ffffffffc020210a:	21500593          	li	a1,533
ffffffffc020210e:	00003517          	auipc	a0,0x3
ffffffffc0202112:	00250513          	addi	a0,a0,2 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202116:	a5efe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc020211a:	d28ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020211e:	00003617          	auipc	a2,0x3
ffffffffc0202122:	fca60613          	addi	a2,a2,-54 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0202126:	08000593          	li	a1,128
ffffffffc020212a:	00003517          	auipc	a0,0x3
ffffffffc020212e:	05650513          	addi	a0,a0,86 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0202132:	a42fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202136:	00003617          	auipc	a2,0x3
ffffffffc020213a:	22260613          	addi	a2,a2,546 # ffffffffc0205358 <default_pmm_manager+0x2c0>
ffffffffc020213e:	08900593          	li	a1,137
ffffffffc0202142:	00003517          	auipc	a0,0x3
ffffffffc0202146:	03e50513          	addi	a0,a0,62 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc020214a:	a2afe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020214e:	00003697          	auipc	a3,0x3
ffffffffc0202152:	14a68693          	addi	a3,a3,330 # ffffffffc0205298 <default_pmm_manager+0x200>
ffffffffc0202156:	00003617          	auipc	a2,0x3
ffffffffc020215a:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204d00 <commands+0x870>
ffffffffc020215e:	1d400593          	li	a1,468
ffffffffc0202162:	00003517          	auipc	a0,0x3
ffffffffc0202166:	fae50513          	addi	a0,a0,-82 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020216a:	a0afe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc020216e:	00003697          	auipc	a3,0x3
ffffffffc0202172:	16268693          	addi	a3,a3,354 # ffffffffc02052d0 <default_pmm_manager+0x238>
ffffffffc0202176:	00003617          	auipc	a2,0x3
ffffffffc020217a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0204d00 <commands+0x870>
ffffffffc020217e:	1d600593          	li	a1,470
ffffffffc0202182:	00003517          	auipc	a0,0x3
ffffffffc0202186:	f8e50513          	addi	a0,a0,-114 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020218a:	9eafe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020218e:	00003697          	auipc	a3,0x3
ffffffffc0202192:	3ba68693          	addi	a3,a3,954 # ffffffffc0205548 <default_pmm_manager+0x4b0>
ffffffffc0202196:	00003617          	auipc	a2,0x3
ffffffffc020219a:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0204d00 <commands+0x870>
ffffffffc020219e:	20500593          	li	a1,517
ffffffffc02021a2:	00003517          	auipc	a0,0x3
ffffffffc02021a6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02021aa:	9cafe0ef          	jal	ra,ffffffffc0200374 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021ae:	00003617          	auipc	a2,0x3
ffffffffc02021b2:	08260613          	addi	a2,a2,130 # ffffffffc0205230 <default_pmm_manager+0x198>
ffffffffc02021b6:	08c00593          	li	a1,140
ffffffffc02021ba:	00003517          	auipc	a0,0x3
ffffffffc02021be:	f5650513          	addi	a0,a0,-170 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02021c2:	9b2fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02021c6:	00003697          	auipc	a3,0x3
ffffffffc02021ca:	16268693          	addi	a3,a3,354 # ffffffffc0205328 <default_pmm_manager+0x290>
ffffffffc02021ce:	00003617          	auipc	a2,0x3
ffffffffc02021d2:	b3260613          	addi	a2,a2,-1230 # ffffffffc0204d00 <commands+0x870>
ffffffffc02021d6:	1dd00593          	li	a1,477
ffffffffc02021da:	00003517          	auipc	a0,0x3
ffffffffc02021de:	f3650513          	addi	a0,a0,-202 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02021e2:	992fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0); // 把这个物理页面通过多级页表映射到0x0
ffffffffc02021e6:	00003697          	auipc	a3,0x3
ffffffffc02021ea:	11268693          	addi	a3,a3,274 # ffffffffc02052f8 <default_pmm_manager+0x260>
ffffffffc02021ee:	00003617          	auipc	a2,0x3
ffffffffc02021f2:	b1260613          	addi	a2,a2,-1262 # ffffffffc0204d00 <commands+0x870>
ffffffffc02021f6:	1da00593          	li	a1,474
ffffffffc02021fa:	00003517          	auipc	a0,0x3
ffffffffc02021fe:	f1650513          	addi	a0,a0,-234 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202202:	972fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202206:	00003697          	auipc	a3,0x3
ffffffffc020220a:	23a68693          	addi	a3,a3,570 # ffffffffc0205440 <default_pmm_manager+0x3a8>
ffffffffc020220e:	00003617          	auipc	a2,0x3
ffffffffc0202212:	af260613          	addi	a2,a2,-1294 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202216:	1ea00593          	li	a1,490
ffffffffc020221a:	00003517          	auipc	a0,0x3
ffffffffc020221e:	ef650513          	addi	a0,a0,-266 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202222:	952fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202226:	00003697          	auipc	a3,0x3
ffffffffc020222a:	1ea68693          	addi	a3,a3,490 # ffffffffc0205410 <default_pmm_manager+0x378>
ffffffffc020222e:	00003617          	auipc	a2,0x3
ffffffffc0202232:	ad260613          	addi	a2,a2,-1326 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202236:	1e900593          	li	a1,489
ffffffffc020223a:	00003517          	auipc	a0,0x3
ffffffffc020223e:	ed650513          	addi	a0,a0,-298 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202242:	932fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202246:	00003697          	auipc	a3,0x3
ffffffffc020224a:	19268693          	addi	a3,a3,402 # ffffffffc02053d8 <default_pmm_manager+0x340>
ffffffffc020224e:	00003617          	auipc	a2,0x3
ffffffffc0202252:	ab260613          	addi	a2,a2,-1358 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202256:	1e800593          	li	a1,488
ffffffffc020225a:	00003517          	auipc	a0,0x3
ffffffffc020225e:	eb650513          	addi	a0,a0,-330 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202262:	912fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202266:	00003697          	auipc	a3,0x3
ffffffffc020226a:	14a68693          	addi	a3,a3,330 # ffffffffc02053b0 <default_pmm_manager+0x318>
ffffffffc020226e:	00003617          	auipc	a2,0x3
ffffffffc0202272:	a9260613          	addi	a2,a2,-1390 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202276:	1e500593          	li	a1,485
ffffffffc020227a:	00003517          	auipc	a0,0x3
ffffffffc020227e:	e9650513          	addi	a0,a0,-362 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202282:	8f2fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202286:	86da                	mv	a3,s6
ffffffffc0202288:	00003617          	auipc	a2,0x3
ffffffffc020228c:	e6060613          	addi	a2,a2,-416 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0202290:	1e300593          	li	a1,483
ffffffffc0202294:	00003517          	auipc	a0,0x3
ffffffffc0202298:	e7c50513          	addi	a0,a0,-388 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020229c:	8d8fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02022a0:	86be                	mv	a3,a5
ffffffffc02022a2:	00003617          	auipc	a2,0x3
ffffffffc02022a6:	e4660613          	addi	a2,a2,-442 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc02022aa:	1e200593          	li	a1,482
ffffffffc02022ae:	00003517          	auipc	a0,0x3
ffffffffc02022b2:	e6250513          	addi	a0,a0,-414 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02022b6:	8befe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02022ba:	00003697          	auipc	a3,0x3
ffffffffc02022be:	0de68693          	addi	a3,a3,222 # ffffffffc0205398 <default_pmm_manager+0x300>
ffffffffc02022c2:	00003617          	auipc	a2,0x3
ffffffffc02022c6:	a3e60613          	addi	a2,a2,-1474 # ffffffffc0204d00 <commands+0x870>
ffffffffc02022ca:	1e000593          	li	a1,480
ffffffffc02022ce:	00003517          	auipc	a0,0x3
ffffffffc02022d2:	e4250513          	addi	a0,a0,-446 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02022d6:	89efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02022da:	00003697          	auipc	a3,0x3
ffffffffc02022de:	0a668693          	addi	a3,a3,166 # ffffffffc0205380 <default_pmm_manager+0x2e8>
ffffffffc02022e2:	00003617          	auipc	a2,0x3
ffffffffc02022e6:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0204d00 <commands+0x870>
ffffffffc02022ea:	1de00593          	li	a1,478
ffffffffc02022ee:	00003517          	auipc	a0,0x3
ffffffffc02022f2:	e2250513          	addi	a0,a0,-478 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02022f6:	87efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02022fa:	00003697          	auipc	a3,0x3
ffffffffc02022fe:	08668693          	addi	a3,a3,134 # ffffffffc0205380 <default_pmm_manager+0x2e8>
ffffffffc0202302:	00003617          	auipc	a2,0x3
ffffffffc0202306:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0204d00 <commands+0x870>
ffffffffc020230a:	1f300593          	li	a1,499
ffffffffc020230e:	00003517          	auipc	a0,0x3
ffffffffc0202312:	e0250513          	addi	a0,a0,-510 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202316:	85efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020231a:	00003697          	auipc	a3,0x3
ffffffffc020231e:	0f668693          	addi	a3,a3,246 # ffffffffc0205410 <default_pmm_manager+0x378>
ffffffffc0202322:	00003617          	auipc	a2,0x3
ffffffffc0202326:	9de60613          	addi	a2,a2,-1570 # ffffffffc0204d00 <commands+0x870>
ffffffffc020232a:	1f200593          	li	a1,498
ffffffffc020232e:	00003517          	auipc	a0,0x3
ffffffffc0202332:	de250513          	addi	a0,a0,-542 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202336:	83efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020233a:	00003697          	auipc	a3,0x3
ffffffffc020233e:	19e68693          	addi	a3,a3,414 # ffffffffc02054d8 <default_pmm_manager+0x440>
ffffffffc0202342:	00003617          	auipc	a2,0x3
ffffffffc0202346:	9be60613          	addi	a2,a2,-1602 # ffffffffc0204d00 <commands+0x870>
ffffffffc020234a:	1f100593          	li	a1,497
ffffffffc020234e:	00003517          	auipc	a0,0x3
ffffffffc0202352:	dc250513          	addi	a0,a0,-574 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202356:	81efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020235a:	00003697          	auipc	a3,0x3
ffffffffc020235e:	16668693          	addi	a3,a3,358 # ffffffffc02054c0 <default_pmm_manager+0x428>
ffffffffc0202362:	00003617          	auipc	a2,0x3
ffffffffc0202366:	99e60613          	addi	a2,a2,-1634 # ffffffffc0204d00 <commands+0x870>
ffffffffc020236a:	1f000593          	li	a1,496
ffffffffc020236e:	00003517          	auipc	a0,0x3
ffffffffc0202372:	da250513          	addi	a0,a0,-606 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202376:	ffffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc020237a:	00003697          	auipc	a3,0x3
ffffffffc020237e:	11668693          	addi	a3,a3,278 # ffffffffc0205490 <default_pmm_manager+0x3f8>
ffffffffc0202382:	00003617          	auipc	a2,0x3
ffffffffc0202386:	97e60613          	addi	a2,a2,-1666 # ffffffffc0204d00 <commands+0x870>
ffffffffc020238a:	1ef00593          	li	a1,495
ffffffffc020238e:	00003517          	auipc	a0,0x3
ffffffffc0202392:	d8250513          	addi	a0,a0,-638 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202396:	fdffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020239a:	00003697          	auipc	a3,0x3
ffffffffc020239e:	0de68693          	addi	a3,a3,222 # ffffffffc0205478 <default_pmm_manager+0x3e0>
ffffffffc02023a2:	00003617          	auipc	a2,0x3
ffffffffc02023a6:	95e60613          	addi	a2,a2,-1698 # ffffffffc0204d00 <commands+0x870>
ffffffffc02023aa:	1ed00593          	li	a1,493
ffffffffc02023ae:	00003517          	auipc	a0,0x3
ffffffffc02023b2:	d6250513          	addi	a0,a0,-670 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02023b6:	fbffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02023ba:	00003697          	auipc	a3,0x3
ffffffffc02023be:	0a668693          	addi	a3,a3,166 # ffffffffc0205460 <default_pmm_manager+0x3c8>
ffffffffc02023c2:	00003617          	auipc	a2,0x3
ffffffffc02023c6:	93e60613          	addi	a2,a2,-1730 # ffffffffc0204d00 <commands+0x870>
ffffffffc02023ca:	1ec00593          	li	a1,492
ffffffffc02023ce:	00003517          	auipc	a0,0x3
ffffffffc02023d2:	d4250513          	addi	a0,a0,-702 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02023d6:	f9ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02023da:	00003697          	auipc	a3,0x3
ffffffffc02023de:	07668693          	addi	a3,a3,118 # ffffffffc0205450 <default_pmm_manager+0x3b8>
ffffffffc02023e2:	00003617          	auipc	a2,0x3
ffffffffc02023e6:	91e60613          	addi	a2,a2,-1762 # ffffffffc0204d00 <commands+0x870>
ffffffffc02023ea:	1eb00593          	li	a1,491
ffffffffc02023ee:	00003517          	auipc	a0,0x3
ffffffffc02023f2:	d2250513          	addi	a0,a0,-734 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02023f6:	f7ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02023fa:	00003697          	auipc	a3,0x3
ffffffffc02023fe:	14e68693          	addi	a3,a3,334 # ffffffffc0205548 <default_pmm_manager+0x4b0>
ffffffffc0202402:	00003617          	auipc	a2,0x3
ffffffffc0202406:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0204d00 <commands+0x870>
ffffffffc020240a:	22e00593          	li	a1,558
ffffffffc020240e:	00003517          	auipc	a0,0x3
ffffffffc0202412:	d0250513          	addi	a0,a0,-766 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202416:	f5ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020241a:	00003697          	auipc	a3,0x3
ffffffffc020241e:	2de68693          	addi	a3,a3,734 # ffffffffc02056f8 <default_pmm_manager+0x660>
ffffffffc0202422:	00003617          	auipc	a2,0x3
ffffffffc0202426:	8de60613          	addi	a2,a2,-1826 # ffffffffc0204d00 <commands+0x870>
ffffffffc020242a:	22600593          	li	a1,550
ffffffffc020242e:	00003517          	auipc	a0,0x3
ffffffffc0202432:	ce250513          	addi	a0,a0,-798 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202436:	f3ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020243a:	00003697          	auipc	a3,0x3
ffffffffc020243e:	28668693          	addi	a3,a3,646 # ffffffffc02056c0 <default_pmm_manager+0x628>
ffffffffc0202442:	00003617          	auipc	a2,0x3
ffffffffc0202446:	8be60613          	addi	a2,a2,-1858 # ffffffffc0204d00 <commands+0x870>
ffffffffc020244a:	22300593          	li	a1,547
ffffffffc020244e:	00003517          	auipc	a0,0x3
ffffffffc0202452:	cc250513          	addi	a0,a0,-830 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202456:	f1ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020245a:	00003697          	auipc	a3,0x3
ffffffffc020245e:	23668693          	addi	a3,a3,566 # ffffffffc0205690 <default_pmm_manager+0x5f8>
ffffffffc0202462:	00003617          	auipc	a2,0x3
ffffffffc0202466:	89e60613          	addi	a2,a2,-1890 # ffffffffc0204d00 <commands+0x870>
ffffffffc020246a:	21f00593          	li	a1,543
ffffffffc020246e:	00003517          	auipc	a0,0x3
ffffffffc0202472:	ca250513          	addi	a0,a0,-862 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202476:	efffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020247a:	00003697          	auipc	a3,0x3
ffffffffc020247e:	08e68693          	addi	a3,a3,142 # ffffffffc0205508 <default_pmm_manager+0x470>
ffffffffc0202482:	00003617          	auipc	a2,0x3
ffffffffc0202486:	87e60613          	addi	a2,a2,-1922 # ffffffffc0204d00 <commands+0x870>
ffffffffc020248a:	1fb00593          	li	a1,507
ffffffffc020248e:	00003517          	auipc	a0,0x3
ffffffffc0202492:	c8250513          	addi	a0,a0,-894 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202496:	edffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020249a:	00003697          	auipc	a3,0x3
ffffffffc020249e:	03e68693          	addi	a3,a3,62 # ffffffffc02054d8 <default_pmm_manager+0x440>
ffffffffc02024a2:	00003617          	auipc	a2,0x3
ffffffffc02024a6:	85e60613          	addi	a2,a2,-1954 # ffffffffc0204d00 <commands+0x870>
ffffffffc02024aa:	1f800593          	li	a1,504
ffffffffc02024ae:	00003517          	auipc	a0,0x3
ffffffffc02024b2:	c6250513          	addi	a0,a0,-926 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02024b6:	ebffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02024ba:	00003697          	auipc	a3,0x3
ffffffffc02024be:	ede68693          	addi	a3,a3,-290 # ffffffffc0205398 <default_pmm_manager+0x300>
ffffffffc02024c2:	00003617          	auipc	a2,0x3
ffffffffc02024c6:	83e60613          	addi	a2,a2,-1986 # ffffffffc0204d00 <commands+0x870>
ffffffffc02024ca:	1f700593          	li	a1,503
ffffffffc02024ce:	00003517          	auipc	a0,0x3
ffffffffc02024d2:	c4250513          	addi	a0,a0,-958 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02024d6:	e9ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02024da:	00003697          	auipc	a3,0x3
ffffffffc02024de:	01668693          	addi	a3,a3,22 # ffffffffc02054f0 <default_pmm_manager+0x458>
ffffffffc02024e2:	00003617          	auipc	a2,0x3
ffffffffc02024e6:	81e60613          	addi	a2,a2,-2018 # ffffffffc0204d00 <commands+0x870>
ffffffffc02024ea:	1f400593          	li	a1,500
ffffffffc02024ee:	00003517          	auipc	a0,0x3
ffffffffc02024f2:	c2250513          	addi	a0,a0,-990 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02024f6:	e7ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02024fa:	00003697          	auipc	a3,0x3
ffffffffc02024fe:	02668693          	addi	a3,a3,38 # ffffffffc0205520 <default_pmm_manager+0x488>
ffffffffc0202502:	00002617          	auipc	a2,0x2
ffffffffc0202506:	7fe60613          	addi	a2,a2,2046 # ffffffffc0204d00 <commands+0x870>
ffffffffc020250a:	1fe00593          	li	a1,510
ffffffffc020250e:	00003517          	auipc	a0,0x3
ffffffffc0202512:	c0250513          	addi	a0,a0,-1022 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202516:	e5ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020251a:	00003697          	auipc	a3,0x3
ffffffffc020251e:	fbe68693          	addi	a3,a3,-66 # ffffffffc02054d8 <default_pmm_manager+0x440>
ffffffffc0202522:	00002617          	auipc	a2,0x2
ffffffffc0202526:	7de60613          	addi	a2,a2,2014 # ffffffffc0204d00 <commands+0x870>
ffffffffc020252a:	1fc00593          	li	a1,508
ffffffffc020252e:	00003517          	auipc	a0,0x3
ffffffffc0202532:	be250513          	addi	a0,a0,-1054 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202536:	e3ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020253a:	00003697          	auipc	a3,0x3
ffffffffc020253e:	d3e68693          	addi	a3,a3,-706 # ffffffffc0205278 <default_pmm_manager+0x1e0>
ffffffffc0202542:	00002617          	auipc	a2,0x2
ffffffffc0202546:	7be60613          	addi	a2,a2,1982 # ffffffffc0204d00 <commands+0x870>
ffffffffc020254a:	1d200593          	li	a1,466
ffffffffc020254e:	00003517          	auipc	a0,0x3
ffffffffc0202552:	bc250513          	addi	a0,a0,-1086 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202556:	e1ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020255a:	00003617          	auipc	a2,0x3
ffffffffc020255e:	cd660613          	addi	a2,a2,-810 # ffffffffc0205230 <default_pmm_manager+0x198>
ffffffffc0202562:	0d900593          	li	a1,217
ffffffffc0202566:	00003517          	auipc	a0,0x3
ffffffffc020256a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020256e:	e07fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202572:	00003697          	auipc	a3,0x3
ffffffffc0202576:	0de68693          	addi	a3,a3,222 # ffffffffc0205650 <default_pmm_manager+0x5b8>
ffffffffc020257a:	00002617          	auipc	a2,0x2
ffffffffc020257e:	78660613          	addi	a2,a2,1926 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202582:	21e00593          	li	a1,542
ffffffffc0202586:	00003517          	auipc	a0,0x3
ffffffffc020258a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020258e:	de7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202592:	00003697          	auipc	a3,0x3
ffffffffc0202596:	0a668693          	addi	a3,a3,166 # ffffffffc0205638 <default_pmm_manager+0x5a0>
ffffffffc020259a:	00002617          	auipc	a2,0x2
ffffffffc020259e:	76660613          	addi	a2,a2,1894 # ffffffffc0204d00 <commands+0x870>
ffffffffc02025a2:	21d00593          	li	a1,541
ffffffffc02025a6:	00003517          	auipc	a0,0x3
ffffffffc02025aa:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02025ae:	dc7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025b2:	00003697          	auipc	a3,0x3
ffffffffc02025b6:	04e68693          	addi	a3,a3,78 # ffffffffc0205600 <default_pmm_manager+0x568>
ffffffffc02025ba:	00002617          	auipc	a2,0x2
ffffffffc02025be:	74660613          	addi	a2,a2,1862 # ffffffffc0204d00 <commands+0x870>
ffffffffc02025c2:	21c00593          	li	a1,540
ffffffffc02025c6:	00003517          	auipc	a0,0x3
ffffffffc02025ca:	b4a50513          	addi	a0,a0,-1206 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02025ce:	da7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02025d2:	00003697          	auipc	a3,0x3
ffffffffc02025d6:	01668693          	addi	a3,a3,22 # ffffffffc02055e8 <default_pmm_manager+0x550>
ffffffffc02025da:	00002617          	auipc	a2,0x2
ffffffffc02025de:	72660613          	addi	a2,a2,1830 # ffffffffc0204d00 <commands+0x870>
ffffffffc02025e2:	21800593          	li	a1,536
ffffffffc02025e6:	00003517          	auipc	a0,0x3
ffffffffc02025ea:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02025ee:	d87fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02025f2 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc02025f2:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc02025f6:	8082                	ret

ffffffffc02025f8 <pgdir_alloc_page>:
{
ffffffffc02025f8:	7179                	addi	sp,sp,-48
ffffffffc02025fa:	e84a                	sd	s2,16(sp)
ffffffffc02025fc:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02025fe:	4505                	li	a0,1
{
ffffffffc0202600:	f022                	sd	s0,32(sp)
ffffffffc0202602:	ec26                	sd	s1,24(sp)
ffffffffc0202604:	e44e                	sd	s3,8(sp)
ffffffffc0202606:	f406                	sd	ra,40(sp)
ffffffffc0202608:	84ae                	mv	s1,a1
ffffffffc020260a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020260c:	852ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0202610:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0202612:	cd19                	beqz	a0,ffffffffc0202630 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0202614:	85aa                	mv	a1,a0
ffffffffc0202616:	86ce                	mv	a3,s3
ffffffffc0202618:	8626                	mv	a2,s1
ffffffffc020261a:	854a                	mv	a0,s2
ffffffffc020261c:	c28ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0202620:	ed39                	bnez	a0,ffffffffc020267e <pgdir_alloc_page+0x86>
        if (swap_init_ok)
ffffffffc0202622:	0000f797          	auipc	a5,0xf
ffffffffc0202626:	e4678793          	addi	a5,a5,-442 # ffffffffc0211468 <swap_init_ok>
ffffffffc020262a:	439c                	lw	a5,0(a5)
ffffffffc020262c:	2781                	sext.w	a5,a5
ffffffffc020262e:	eb89                	bnez	a5,ffffffffc0202640 <pgdir_alloc_page+0x48>
}
ffffffffc0202630:	8522                	mv	a0,s0
ffffffffc0202632:	70a2                	ld	ra,40(sp)
ffffffffc0202634:	7402                	ld	s0,32(sp)
ffffffffc0202636:	64e2                	ld	s1,24(sp)
ffffffffc0202638:	6942                	ld	s2,16(sp)
ffffffffc020263a:	69a2                	ld	s3,8(sp)
ffffffffc020263c:	6145                	addi	sp,sp,48
ffffffffc020263e:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202640:	0000f797          	auipc	a5,0xf
ffffffffc0202644:	f5078793          	addi	a5,a5,-176 # ffffffffc0211590 <check_mm_struct>
ffffffffc0202648:	6388                	ld	a0,0(a5)
ffffffffc020264a:	4681                	li	a3,0
ffffffffc020264c:	8622                	mv	a2,s0
ffffffffc020264e:	85a6                	mv	a1,s1
ffffffffc0202650:	06d000ef          	jal	ra,ffffffffc0202ebc <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202654:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202656:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0202658:	4785                	li	a5,1
ffffffffc020265a:	fcf70be3          	beq	a4,a5,ffffffffc0202630 <pgdir_alloc_page+0x38>
ffffffffc020265e:	00003697          	auipc	a3,0x3
ffffffffc0202662:	b3268693          	addi	a3,a3,-1230 # ffffffffc0205190 <default_pmm_manager+0xf8>
ffffffffc0202666:	00002617          	auipc	a2,0x2
ffffffffc020266a:	69a60613          	addi	a2,a2,1690 # ffffffffc0204d00 <commands+0x870>
ffffffffc020266e:	1b800593          	li	a1,440
ffffffffc0202672:	00003517          	auipc	a0,0x3
ffffffffc0202676:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020267a:	cfbfd0ef          	jal	ra,ffffffffc0200374 <__panic>
            free_page(page);
ffffffffc020267e:	8522                	mv	a0,s0
ffffffffc0202680:	4585                	li	a1,1
ffffffffc0202682:	864ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
            return NULL;
ffffffffc0202686:	4401                	li	s0,0
ffffffffc0202688:	b765                	j	ffffffffc0202630 <pgdir_alloc_page+0x38>

ffffffffc020268a <kmalloc>:
}

// 分配至少n个连续的字节，这里实现得不精细，占用的只能是整数个页。
void *kmalloc(size_t n)
{
ffffffffc020268a:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020268c:	67d5                	lui	a5,0x15
{
ffffffffc020268e:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202690:	fff50713          	addi	a4,a0,-1
ffffffffc0202694:	17f9                	addi	a5,a5,-2
ffffffffc0202696:	04e7ee63          	bltu	a5,a4,ffffffffc02026f2 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 向上取整到整数个页
ffffffffc020269a:	6785                	lui	a5,0x1
ffffffffc020269c:	17fd                	addi	a5,a5,-1
ffffffffc020269e:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc02026a0:	8131                	srli	a0,a0,0xc
ffffffffc02026a2:	fbdfe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
    assert(base != NULL); // 如果分配失败就直接panic
ffffffffc02026a6:	c159                	beqz	a0,ffffffffc020272c <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026a8:	0000f797          	auipc	a5,0xf
ffffffffc02026ac:	e0078793          	addi	a5,a5,-512 # ffffffffc02114a8 <pages>
ffffffffc02026b0:	639c                	ld	a5,0(a5)
ffffffffc02026b2:	8d1d                	sub	a0,a0,a5
ffffffffc02026b4:	00002797          	auipc	a5,0x2
ffffffffc02026b8:	63478793          	addi	a5,a5,1588 # ffffffffc0204ce8 <commands+0x858>
ffffffffc02026bc:	6394                	ld	a3,0(a5)
ffffffffc02026be:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026c0:	0000f797          	auipc	a5,0xf
ffffffffc02026c4:	d9878793          	addi	a5,a5,-616 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026c8:	02d50533          	mul	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026cc:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026ce:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026d2:	57fd                	li	a5,-1
ffffffffc02026d4:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026d6:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026d8:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02026da:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026dc:	02e7fb63          	bleu	a4,a5,ffffffffc0202712 <kmalloc+0x88>
ffffffffc02026e0:	0000f797          	auipc	a5,0xf
ffffffffc02026e4:	db878793          	addi	a5,a5,-584 # ffffffffc0211498 <va_pa_offset>
ffffffffc02026e8:	639c                	ld	a5,0(a5)
    ptr = page2kva(base); // 分配的内存的起始位置（虚拟地址），page2kva, 就是page_to_kernel_virtual_address
    return ptr;
}
ffffffffc02026ea:	60a2                	ld	ra,8(sp)
ffffffffc02026ec:	953e                	add	a0,a0,a5
ffffffffc02026ee:	0141                	addi	sp,sp,16
ffffffffc02026f0:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02026f2:	00003697          	auipc	a3,0x3
ffffffffc02026f6:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0205130 <default_pmm_manager+0x98>
ffffffffc02026fa:	00002617          	auipc	a2,0x2
ffffffffc02026fe:	60660613          	addi	a2,a2,1542 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202702:	23800593          	li	a1,568
ffffffffc0202706:	00003517          	auipc	a0,0x3
ffffffffc020270a:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc020270e:	c67fd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0202712:	86aa                	mv	a3,a0
ffffffffc0202714:	00003617          	auipc	a2,0x3
ffffffffc0202718:	9d460613          	addi	a2,a2,-1580 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc020271c:	08000593          	li	a1,128
ffffffffc0202720:	00003517          	auipc	a0,0x3
ffffffffc0202724:	a6050513          	addi	a0,a0,-1440 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0202728:	c4dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(base != NULL); // 如果分配失败就直接panic
ffffffffc020272c:	00003697          	auipc	a3,0x3
ffffffffc0202730:	a2468693          	addi	a3,a3,-1500 # ffffffffc0205150 <default_pmm_manager+0xb8>
ffffffffc0202734:	00002617          	auipc	a2,0x2
ffffffffc0202738:	5cc60613          	addi	a2,a2,1484 # ffffffffc0204d00 <commands+0x870>
ffffffffc020273c:	23b00593          	li	a1,571
ffffffffc0202740:	00003517          	auipc	a0,0x3
ffffffffc0202744:	9d050513          	addi	a0,a0,-1584 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202748:	c2dfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020274c <kfree>:

// 从某个位置开始释放n个字节
void kfree(void *ptr, size_t n)
{
ffffffffc020274c:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020274e:	67d5                	lui	a5,0x15
{
ffffffffc0202750:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202752:	fff58713          	addi	a4,a1,-1
ffffffffc0202756:	17f9                	addi	a5,a5,-2
ffffffffc0202758:	04e7eb63          	bltu	a5,a4,ffffffffc02027ae <kfree+0x62>
    assert(ptr != NULL);
ffffffffc020275c:	c941                	beqz	a0,ffffffffc02027ec <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc020275e:	6785                	lui	a5,0x1
ffffffffc0202760:	17fd                	addi	a5,a5,-1
ffffffffc0202762:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202764:	c02007b7          	lui	a5,0xc0200
ffffffffc0202768:	81b1                	srli	a1,a1,0xc
ffffffffc020276a:	06f56463          	bltu	a0,a5,ffffffffc02027d2 <kfree+0x86>
ffffffffc020276e:	0000f797          	auipc	a5,0xf
ffffffffc0202772:	d2a78793          	addi	a5,a5,-726 # ffffffffc0211498 <va_pa_offset>
ffffffffc0202776:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage)
ffffffffc0202778:	0000f717          	auipc	a4,0xf
ffffffffc020277c:	ce070713          	addi	a4,a4,-800 # ffffffffc0211458 <npage>
ffffffffc0202780:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202782:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0202786:	83b1                	srli	a5,a5,0xc
ffffffffc0202788:	04e7f363          	bleu	a4,a5,ffffffffc02027ce <kfree+0x82>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc020278c:	fff80537          	lui	a0,0xfff80
ffffffffc0202790:	97aa                	add	a5,a5,a0
ffffffffc0202792:	0000f697          	auipc	a3,0xf
ffffffffc0202796:	d1668693          	addi	a3,a3,-746 # ffffffffc02114a8 <pages>
ffffffffc020279a:	6288                	ld	a0,0(a3)
ffffffffc020279c:	00379713          	slli	a4,a5,0x3
    但是如果程序员写错了呢？调用kfree的时候传入的n和调用kmalloc传入的n不一样？
    就像你平时在windows/linux写C语言一样，会出各种奇奇怪怪的bug。
    */
    base = kva2page(ptr); // kernel_virtual_address_to_page
    free_pages(base, num_pages);
}
ffffffffc02027a0:	60a2                	ld	ra,8(sp)
ffffffffc02027a2:	97ba                	add	a5,a5,a4
ffffffffc02027a4:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc02027a6:	953e                	add	a0,a0,a5
}
ffffffffc02027a8:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc02027aa:	f3dfe06f          	j	ffffffffc02016e6 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027ae:	00003697          	auipc	a3,0x3
ffffffffc02027b2:	98268693          	addi	a3,a3,-1662 # ffffffffc0205130 <default_pmm_manager+0x98>
ffffffffc02027b6:	00002617          	auipc	a2,0x2
ffffffffc02027ba:	54a60613          	addi	a2,a2,1354 # ffffffffc0204d00 <commands+0x870>
ffffffffc02027be:	24300593          	li	a1,579
ffffffffc02027c2:	00003517          	auipc	a0,0x3
ffffffffc02027c6:	94e50513          	addi	a0,a0,-1714 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc02027ca:	babfd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02027ce:	e75fe0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02027d2:	86aa                	mv	a3,a0
ffffffffc02027d4:	00003617          	auipc	a2,0x3
ffffffffc02027d8:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0205230 <default_pmm_manager+0x198>
ffffffffc02027dc:	08200593          	li	a1,130
ffffffffc02027e0:	00003517          	auipc	a0,0x3
ffffffffc02027e4:	9a050513          	addi	a0,a0,-1632 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc02027e8:	b8dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(ptr != NULL);
ffffffffc02027ec:	00003697          	auipc	a3,0x3
ffffffffc02027f0:	93468693          	addi	a3,a3,-1740 # ffffffffc0205120 <default_pmm_manager+0x88>
ffffffffc02027f4:	00002617          	auipc	a2,0x2
ffffffffc02027f8:	50c60613          	addi	a2,a2,1292 # ffffffffc0204d00 <commands+0x870>
ffffffffc02027fc:	24400593          	li	a1,580
ffffffffc0202800:	00003517          	auipc	a0,0x3
ffffffffc0202804:	91050513          	addi	a0,a0,-1776 # ffffffffc0205110 <default_pmm_manager+0x78>
ffffffffc0202808:	b6dfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020280c <swap_init>:
unsigned int swap_in_seq_no[MAX_SEQ_NO], swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);

int swap_init(void)
{
ffffffffc020280c:	7135                	addi	sp,sp,-160
ffffffffc020280e:	ed06                	sd	ra,152(sp)
ffffffffc0202810:	e922                	sd	s0,144(sp)
ffffffffc0202812:	e526                	sd	s1,136(sp)
ffffffffc0202814:	e14a                	sd	s2,128(sp)
ffffffffc0202816:	fcce                	sd	s3,120(sp)
ffffffffc0202818:	f8d2                	sd	s4,112(sp)
ffffffffc020281a:	f4d6                	sd	s5,104(sp)
ffffffffc020281c:	f0da                	sd	s6,96(sp)
ffffffffc020281e:	ecde                	sd	s7,88(sp)
ffffffffc0202820:	e8e2                	sd	s8,80(sp)
ffffffffc0202822:	e4e6                	sd	s9,72(sp)
ffffffffc0202824:	e0ea                	sd	s10,64(sp)
ffffffffc0202826:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202828:	43c010ef          	jal	ra,ffffffffc0203c64 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     // 实际上max_swap_offset=7
     if (!(7 <= max_swap_offset &&
ffffffffc020282c:	0000f797          	auipc	a5,0xf
ffffffffc0202830:	d0c78793          	addi	a5,a5,-756 # ffffffffc0211538 <max_swap_offset>
ffffffffc0202834:	6394                	ld	a3,0(a5)
ffffffffc0202836:	010007b7          	lui	a5,0x1000
ffffffffc020283a:	17e1                	addi	a5,a5,-8
ffffffffc020283c:	ff968713          	addi	a4,a3,-7
ffffffffc0202840:	42e7ea63          	bltu	a5,a4,ffffffffc0202c74 <swap_init+0x468>
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     // 测试的时候使用时钟置换算法
     sm = &swap_manager_lru; // use first in first out Page Replacement Algorithm
ffffffffc0202844:	00007797          	auipc	a5,0x7
ffffffffc0202848:	7bc78793          	addi	a5,a5,1980 # ffffffffc020a000 <swap_manager_lru>
     int r = sm->init();
ffffffffc020284c:	6798                	ld	a4,8(a5)
     sm = &swap_manager_lru; // use first in first out Page Replacement Algorithm
ffffffffc020284e:	0000f697          	auipc	a3,0xf
ffffffffc0202852:	c0f6b923          	sd	a5,-1006(a3) # ffffffffc0211460 <sm>
     int r = sm->init();
ffffffffc0202856:	9702                	jalr	a4
ffffffffc0202858:	8b2a                	mv	s6,a0

     if (r == 0)
ffffffffc020285a:	c10d                	beqz	a0,ffffffffc020287c <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc020285c:	60ea                	ld	ra,152(sp)
ffffffffc020285e:	644a                	ld	s0,144(sp)
ffffffffc0202860:	855a                	mv	a0,s6
ffffffffc0202862:	64aa                	ld	s1,136(sp)
ffffffffc0202864:	690a                	ld	s2,128(sp)
ffffffffc0202866:	79e6                	ld	s3,120(sp)
ffffffffc0202868:	7a46                	ld	s4,112(sp)
ffffffffc020286a:	7aa6                	ld	s5,104(sp)
ffffffffc020286c:	7b06                	ld	s6,96(sp)
ffffffffc020286e:	6be6                	ld	s7,88(sp)
ffffffffc0202870:	6c46                	ld	s8,80(sp)
ffffffffc0202872:	6ca6                	ld	s9,72(sp)
ffffffffc0202874:	6d06                	ld	s10,64(sp)
ffffffffc0202876:	7de2                	ld	s11,56(sp)
ffffffffc0202878:	610d                	addi	sp,sp,160
ffffffffc020287a:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc020287c:	0000f797          	auipc	a5,0xf
ffffffffc0202880:	be478793          	addi	a5,a5,-1052 # ffffffffc0211460 <sm>
ffffffffc0202884:	639c                	ld	a5,0(a5)
ffffffffc0202886:	00003517          	auipc	a0,0x3
ffffffffc020288a:	f3a50513          	addi	a0,a0,-198 # ffffffffc02057c0 <default_pmm_manager+0x728>
    return listelm->next;
ffffffffc020288e:	0000f417          	auipc	s0,0xf
ffffffffc0202892:	bea40413          	addi	s0,s0,-1046 # ffffffffc0211478 <free_area>
ffffffffc0202896:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202898:	4785                	li	a5,1
ffffffffc020289a:	0000f717          	auipc	a4,0xf
ffffffffc020289e:	bcf72723          	sw	a5,-1074(a4) # ffffffffc0211468 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02028a2:	81dfd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02028a6:	641c                	ld	a5,8(s0)
check_swap(void)
{
     // backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc02028a8:	2e878a63          	beq	a5,s0,ffffffffc0202b9c <swap_init+0x390>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02028ac:	fe87b703          	ld	a4,-24(a5)
ffffffffc02028b0:	8305                	srli	a4,a4,0x1
     {
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p)); // 空闲
ffffffffc02028b2:	8b05                	andi	a4,a4,1
ffffffffc02028b4:	2e070863          	beqz	a4,ffffffffc0202ba4 <swap_init+0x398>
     int ret, count = 0, total = 0, i;
ffffffffc02028b8:	4481                	li	s1,0
ffffffffc02028ba:	4901                	li	s2,0
ffffffffc02028bc:	a031                	j	ffffffffc02028c8 <swap_init+0xbc>
ffffffffc02028be:	fe87b703          	ld	a4,-24(a5)
          assert(PageProperty(p)); // 空闲
ffffffffc02028c2:	8b09                	andi	a4,a4,2
ffffffffc02028c4:	2e070063          	beqz	a4,ffffffffc0202ba4 <swap_init+0x398>
          count++, total += p->property;
ffffffffc02028c8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02028cc:	679c                	ld	a5,8(a5)
ffffffffc02028ce:	2905                	addiw	s2,s2,1
ffffffffc02028d0:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list)
ffffffffc02028d2:	fe8796e3          	bne	a5,s0,ffffffffc02028be <swap_init+0xb2>
ffffffffc02028d6:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc02028d8:	e55fe0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc02028dc:	5b351863          	bne	a0,s3,ffffffffc0202e8c <swap_init+0x680>
     cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc02028e0:	8626                	mv	a2,s1
ffffffffc02028e2:	85ca                	mv	a1,s2
ffffffffc02028e4:	00003517          	auipc	a0,0x3
ffffffffc02028e8:	ef450513          	addi	a0,a0,-268 # ffffffffc02057d8 <default_pmm_manager+0x740>
ffffffffc02028ec:	fd2fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     // now we set the phy pages env
     // 一样，初始化mm然后初始化vma
     struct mm_struct *mm = mm_create();
ffffffffc02028f0:	3a7000ef          	jal	ra,ffffffffc0203496 <mm_create>
ffffffffc02028f4:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc02028f6:	50050b63          	beqz	a0,ffffffffc0202e0c <swap_init+0x600>

     extern struct mm_struct *check_mm_struct;
     // 当前没有其他函数使用check_mm_struct
     assert(check_mm_struct == NULL);
ffffffffc02028fa:	0000f797          	auipc	a5,0xf
ffffffffc02028fe:	c9678793          	addi	a5,a5,-874 # ffffffffc0211590 <check_mm_struct>
ffffffffc0202902:	639c                	ld	a5,0(a5)
ffffffffc0202904:	52079463          	bnez	a5,ffffffffc0202e2c <swap_init+0x620>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202908:	0000f797          	auipc	a5,0xf
ffffffffc020290c:	b4878793          	addi	a5,a5,-1208 # ffffffffc0211450 <boot_pgdir>
ffffffffc0202910:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0202912:	0000f797          	auipc	a5,0xf
ffffffffc0202916:	c6a7bf23          	sd	a0,-898(a5) # ffffffffc0211590 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020291a:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020291c:	ec3a                	sd	a4,24(sp)
ffffffffc020291e:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202920:	52079663          	bnez	a5,ffffffffc0202e4c <swap_init+0x640>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202924:	6599                	lui	a1,0x6
ffffffffc0202926:	460d                	li	a2,3
ffffffffc0202928:	6505                	lui	a0,0x1
ffffffffc020292a:	3b9000ef          	jal	ra,ffffffffc02034e2 <vma_create>
ffffffffc020292e:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202930:	52050e63          	beqz	a0,ffffffffc0202e6c <swap_init+0x660>

     insert_vma_struct(mm, vma);
ffffffffc0202934:	855e                	mv	a0,s7
ffffffffc0202936:	419000ef          	jal	ra,ffffffffc020354e <insert_vma_struct>

     // setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020293a:	00003517          	auipc	a0,0x3
ffffffffc020293e:	f0e50513          	addi	a0,a0,-242 # ffffffffc0205848 <default_pmm_manager+0x7b0>
ffffffffc0202942:	f7cfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep = NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202946:	018bb503          	ld	a0,24(s7)
ffffffffc020294a:	4605                	li	a2,1
ffffffffc020294c:	6585                	lui	a1,0x1
ffffffffc020294e:	e1ffe0ef          	jal	ra,ffffffffc020176c <get_pte>
     assert(temp_ptep != NULL);
ffffffffc0202952:	40050d63          	beqz	a0,ffffffffc0202d6c <swap_init+0x560>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202956:	00003517          	auipc	a0,0x3
ffffffffc020295a:	f4250513          	addi	a0,a0,-190 # ffffffffc0205898 <default_pmm_manager+0x800>
ffffffffc020295e:	0000fa17          	auipc	s4,0xf
ffffffffc0202962:	b52a0a13          	addi	s4,s4,-1198 # ffffffffc02114b0 <check_rp>
ffffffffc0202966:	f58fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     // 准备物理页面
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc020296a:	0000fa97          	auipc	s5,0xf
ffffffffc020296e:	b66a8a93          	addi	s5,s5,-1178 # ffffffffc02114d0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202972:	89d2                	mv	s3,s4
     {
          check_rp[i] = alloc_page();
ffffffffc0202974:	4505                	li	a0,1
ffffffffc0202976:	ce9fe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc020297a:	00a9b023          	sd	a0,0(s3) # fffffffffff80000 <end+0x3fd6ea68>
          assert(check_rp[i] != NULL);
ffffffffc020297e:	2a050b63          	beqz	a0,ffffffffc0202c34 <swap_init+0x428>
ffffffffc0202982:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i])); // 不是空页面了
ffffffffc0202984:	8b89                	andi	a5,a5,2
ffffffffc0202986:	28079763          	bnez	a5,ffffffffc0202c14 <swap_init+0x408>
ffffffffc020298a:	09a1                	addi	s3,s3,8
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc020298c:	ff5994e3          	bne	s3,s5,ffffffffc0202974 <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202990:	601c                	ld	a5,0(s0)
ffffffffc0202992:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));

     // assert(alloc_page() == NULL);

     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202996:	0000fd17          	auipc	s10,0xf
ffffffffc020299a:	b1ad0d13          	addi	s10,s10,-1254 # ffffffffc02114b0 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc020299e:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02029a0:	481c                	lw	a5,16(s0)
ffffffffc02029a2:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc02029a4:	0000f797          	auipc	a5,0xf
ffffffffc02029a8:	ac87be23          	sd	s0,-1316(a5) # ffffffffc0211480 <free_area+0x8>
ffffffffc02029ac:	0000f797          	auipc	a5,0xf
ffffffffc02029b0:	ac87b623          	sd	s0,-1332(a5) # ffffffffc0211478 <free_area>
     nr_free = 0;
ffffffffc02029b4:	0000f797          	auipc	a5,0xf
ffffffffc02029b8:	ac07aa23          	sw	zero,-1324(a5) # ffffffffc0211488 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc02029bc:	000d3503          	ld	a0,0(s10)
ffffffffc02029c0:	4585                	li	a1,1
ffffffffc02029c2:	0d21                	addi	s10,s10,8
ffffffffc02029c4:	d23fe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02029c8:	ff5d1ae3          	bne	s10,s5,ffffffffc02029bc <swap_init+0x1b0>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // nr_free是全局的，free_pages会改变它的值
ffffffffc02029cc:	01042d03          	lw	s10,16(s0)
ffffffffc02029d0:	4791                	li	a5,4
ffffffffc02029d2:	36fd1d63          	bne	s10,a5,ffffffffc0202d4c <swap_init+0x540>

     cprintf("set up init env for check_swap begin!\n");
ffffffffc02029d6:	00003517          	auipc	a0,0x3
ffffffffc02029da:	f4a50513          	addi	a0,a0,-182 # ffffffffc0205920 <default_pmm_manager+0x888>
ffffffffc02029de:	ee0fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02029e2:	6685                	lui	a3,0x1
     // setup initial vir_page<->phy_page environment for page relpacement algorithm

     pgfault_num = 0;
ffffffffc02029e4:	0000f797          	auipc	a5,0xf
ffffffffc02029e8:	a807a423          	sw	zero,-1400(a5) # ffffffffc021146c <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02029ec:	4629                	li	a2,10
     pgfault_num = 0;
ffffffffc02029ee:	0000f797          	auipc	a5,0xf
ffffffffc02029f2:	a7e78793          	addi	a5,a5,-1410 # ffffffffc021146c <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02029f6:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num == 1);
ffffffffc02029fa:	4398                	lw	a4,0(a5)
ffffffffc02029fc:	4585                	li	a1,1
ffffffffc02029fe:	2701                	sext.w	a4,a4
ffffffffc0202a00:	30b71663          	bne	a4,a1,ffffffffc0202d0c <swap_init+0x500>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202a04:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 1);
ffffffffc0202a08:	4394                	lw	a3,0(a5)
ffffffffc0202a0a:	2681                	sext.w	a3,a3
ffffffffc0202a0c:	32e69063          	bne	a3,a4,ffffffffc0202d2c <swap_init+0x520>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202a10:	6689                	lui	a3,0x2
ffffffffc0202a12:	462d                	li	a2,11
ffffffffc0202a14:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num == 2);
ffffffffc0202a18:	4398                	lw	a4,0(a5)
ffffffffc0202a1a:	4589                	li	a1,2
ffffffffc0202a1c:	2701                	sext.w	a4,a4
ffffffffc0202a1e:	26b71763          	bne	a4,a1,ffffffffc0202c8c <swap_init+0x480>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202a22:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 2);
ffffffffc0202a26:	4394                	lw	a3,0(a5)
ffffffffc0202a28:	2681                	sext.w	a3,a3
ffffffffc0202a2a:	28e69163          	bne	a3,a4,ffffffffc0202cac <swap_init+0x4a0>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202a2e:	668d                	lui	a3,0x3
ffffffffc0202a30:	4631                	li	a2,12
ffffffffc0202a32:	00c68023          	sb	a2,0(a3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num == 3);
ffffffffc0202a36:	4398                	lw	a4,0(a5)
ffffffffc0202a38:	458d                	li	a1,3
ffffffffc0202a3a:	2701                	sext.w	a4,a4
ffffffffc0202a3c:	28b71863          	bne	a4,a1,ffffffffc0202ccc <swap_init+0x4c0>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202a40:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 3);
ffffffffc0202a44:	4394                	lw	a3,0(a5)
ffffffffc0202a46:	2681                	sext.w	a3,a3
ffffffffc0202a48:	2ae69263          	bne	a3,a4,ffffffffc0202cec <swap_init+0x4e0>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202a4c:	6691                	lui	a3,0x4
ffffffffc0202a4e:	4635                	li	a2,13
ffffffffc0202a50:	00c68023          	sb	a2,0(a3) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num == 4);
ffffffffc0202a54:	4398                	lw	a4,0(a5)
ffffffffc0202a56:	2701                	sext.w	a4,a4
ffffffffc0202a58:	33a71a63          	bne	a4,s10,ffffffffc0202d8c <swap_init+0x580>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202a5c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num == 4);
ffffffffc0202a60:	439c                	lw	a5,0(a5)
ffffffffc0202a62:	2781                	sext.w	a5,a5
ffffffffc0202a64:	34e79463          	bne	a5,a4,ffffffffc0202dac <swap_init+0x5a0>

     // check_content_set函数会进行访存，也就会导致缺页异常
     check_content_set();
     assert(nr_free == 0);
ffffffffc0202a68:	481c                	lw	a5,16(s0)
ffffffffc0202a6a:	36079163          	bnez	a5,ffffffffc0202dcc <swap_init+0x5c0>
ffffffffc0202a6e:	0000f797          	auipc	a5,0xf
ffffffffc0202a72:	a6278793          	addi	a5,a5,-1438 # ffffffffc02114d0 <swap_in_seq_no>
ffffffffc0202a76:	0000f717          	auipc	a4,0xf
ffffffffc0202a7a:	a8270713          	addi	a4,a4,-1406 # ffffffffc02114f8 <swap_out_seq_no>
ffffffffc0202a7e:	0000f617          	auipc	a2,0xf
ffffffffc0202a82:	a7a60613          	addi	a2,a2,-1414 # ffffffffc02114f8 <swap_out_seq_no>
     for (i = 0; i < MAX_SEQ_NO; i++)
          swap_out_seq_no[i] = swap_in_seq_no[i] = -1; // 这两个也是全局变量
ffffffffc0202a86:	56fd                	li	a3,-1
ffffffffc0202a88:	c394                	sw	a3,0(a5)
ffffffffc0202a8a:	c314                	sw	a3,0(a4)
ffffffffc0202a8c:	0791                	addi	a5,a5,4
ffffffffc0202a8e:	0711                	addi	a4,a4,4
     for (i = 0; i < MAX_SEQ_NO; i++)
ffffffffc0202a90:	fec79ce3          	bne	a5,a2,ffffffffc0202a88 <swap_init+0x27c>
ffffffffc0202a94:	0000f697          	auipc	a3,0xf
ffffffffc0202a98:	ac468693          	addi	a3,a3,-1340 # ffffffffc0211558 <check_ptep>
ffffffffc0202a9c:	0000f817          	auipc	a6,0xf
ffffffffc0202aa0:	a1480813          	addi	a6,a6,-1516 # ffffffffc02114b0 <check_rp>
ffffffffc0202aa4:	6c05                	lui	s8,0x1
    if (PPN(pa) >= npage)
ffffffffc0202aa6:	0000fc97          	auipc	s9,0xf
ffffffffc0202aaa:	9b2c8c93          	addi	s9,s9,-1614 # ffffffffc0211458 <npage>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0202aae:	0000fd97          	auipc	s11,0xf
ffffffffc0202ab2:	9fad8d93          	addi	s11,s11,-1542 # ffffffffc02114a8 <pages>
ffffffffc0202ab6:	00004d17          	auipc	s10,0x4
ffffffffc0202aba:	822d0d13          	addi	s10,s10,-2014 # ffffffffc02062d8 <nbase>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          check_ptep[i] = 0;
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202abe:	6562                	ld	a0,24(sp)
          check_ptep[i] = 0;
ffffffffc0202ac0:	0006b023          	sd	zero,0(a3)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202ac4:	4601                	li	a2,0
ffffffffc0202ac6:	85e2                	mv	a1,s8
ffffffffc0202ac8:	e842                	sd	a6,16(sp)
          check_ptep[i] = 0;
ffffffffc0202aca:	e436                	sd	a3,8(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202acc:	ca1fe0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0202ad0:	66a2                	ld	a3,8(sp)
          // cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
          assert(check_ptep[i] != NULL);
ffffffffc0202ad2:	6842                	ld	a6,16(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202ad4:	e288                	sd	a0,0(a3)
          assert(check_ptep[i] != NULL);
ffffffffc0202ad6:	16050f63          	beqz	a0,ffffffffc0202c54 <swap_init+0x448>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202ada:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202adc:	0017f613          	andi	a2,a5,1
ffffffffc0202ae0:	10060263          	beqz	a2,ffffffffc0202be4 <swap_init+0x3d8>
    if (PPN(pa) >= npage)
ffffffffc0202ae4:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202ae8:	078a                	slli	a5,a5,0x2
ffffffffc0202aea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aec:	10c7f863          	bleu	a2,a5,ffffffffc0202bfc <swap_init+0x3f0>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc0202af0:	000d3603          	ld	a2,0(s10)
ffffffffc0202af4:	000db583          	ld	a1,0(s11)
ffffffffc0202af8:	00083503          	ld	a0,0(a6)
ffffffffc0202afc:	8f91                	sub	a5,a5,a2
ffffffffc0202afe:	00379613          	slli	a2,a5,0x3
ffffffffc0202b02:	97b2                	add	a5,a5,a2
ffffffffc0202b04:	078e                	slli	a5,a5,0x3
ffffffffc0202b06:	97ae                	add	a5,a5,a1
ffffffffc0202b08:	0af51e63          	bne	a0,a5,ffffffffc0202bc4 <swap_init+0x3b8>
ffffffffc0202b0c:	6785                	lui	a5,0x1
ffffffffc0202b0e:	9c3e                	add	s8,s8,a5
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202b10:	6795                	lui	a5,0x5
ffffffffc0202b12:	06a1                	addi	a3,a3,8
ffffffffc0202b14:	0821                	addi	a6,a6,8
ffffffffc0202b16:	fafc14e3          	bne	s8,a5,ffffffffc0202abe <swap_init+0x2b2>
          assert((*check_ptep[i] & PTE_V));
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202b1a:	00003517          	auipc	a0,0x3
ffffffffc0202b1e:	ece50513          	addi	a0,a0,-306 # ffffffffc02059e8 <default_pmm_manager+0x950>
ffffffffc0202b22:	d9cfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     int ret = sm->check_swap();
ffffffffc0202b26:	0000f797          	auipc	a5,0xf
ffffffffc0202b2a:	93a78793          	addi	a5,a5,-1734 # ffffffffc0211460 <sm>
ffffffffc0202b2e:	639c                	ld	a5,0(a5)
ffffffffc0202b30:	7f9c                	ld	a5,56(a5)
ffffffffc0202b32:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm
     // ! 初始化完成，调用核心测试函数，实际上是swap_manager的成员函数check_swap
     ret = check_content_access();
     assert(ret == 0);
ffffffffc0202b34:	2a051c63          	bnez	a0,ffffffffc0202dec <swap_init+0x5e0>

     // 下面都是释放操作了
     // restore kernel mem env
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc0202b38:	000a3503          	ld	a0,0(s4)
ffffffffc0202b3c:	4585                	li	a1,1
ffffffffc0202b3e:	0a21                	addi	s4,s4,8
ffffffffc0202b40:	ba7fe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202b44:	ff5a1ae3          	bne	s4,s5,ffffffffc0202b38 <swap_init+0x32c>
     }

     // free_page(pte2page(*temp_ptep));

     mm_destroy(mm);
ffffffffc0202b48:	855e                	mv	a0,s7
ffffffffc0202b4a:	2d3000ef          	jal	ra,ffffffffc020361c <mm_destroy>

     nr_free = nr_free_store;
ffffffffc0202b4e:	77a2                	ld	a5,40(sp)
ffffffffc0202b50:	0000f717          	auipc	a4,0xf
ffffffffc0202b54:	92f72c23          	sw	a5,-1736(a4) # ffffffffc0211488 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202b58:	7782                	ld	a5,32(sp)
ffffffffc0202b5a:	0000f717          	auipc	a4,0xf
ffffffffc0202b5e:	90f73f23          	sd	a5,-1762(a4) # ffffffffc0211478 <free_area>
ffffffffc0202b62:	0000f797          	auipc	a5,0xf
ffffffffc0202b66:	9137bf23          	sd	s3,-1762(a5) # ffffffffc0211480 <free_area+0x8>

     le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc0202b6a:	00898a63          	beq	s3,s0,ffffffffc0202b7e <swap_init+0x372>
     {
          struct Page *p = le2page(le, page_link);
          count--, total -= p->property;
ffffffffc0202b6e:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc0202b72:	0089b983          	ld	s3,8(s3)
ffffffffc0202b76:	397d                	addiw	s2,s2,-1
ffffffffc0202b78:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list)
ffffffffc0202b7a:	fe899ae3          	bne	s3,s0,ffffffffc0202b6e <swap_init+0x362>
     }
     cprintf("count is %d, total is %d\n", count, total);
ffffffffc0202b7e:	8626                	mv	a2,s1
ffffffffc0202b80:	85ca                	mv	a1,s2
ffffffffc0202b82:	00003517          	auipc	a0,0x3
ffffffffc0202b86:	e9e50513          	addi	a0,a0,-354 # ffffffffc0205a20 <default_pmm_manager+0x988>
ffffffffc0202b8a:	d34fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     // assert(count == 0);

     cprintf("check_swap() succeeded!\n");
ffffffffc0202b8e:	00003517          	auipc	a0,0x3
ffffffffc0202b92:	eb250513          	addi	a0,a0,-334 # ffffffffc0205a40 <default_pmm_manager+0x9a8>
ffffffffc0202b96:	d28fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202b9a:	b1c9                	j	ffffffffc020285c <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202b9c:	4481                	li	s1,0
ffffffffc0202b9e:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list)
ffffffffc0202ba0:	4981                	li	s3,0
ffffffffc0202ba2:	bb1d                	j	ffffffffc02028d8 <swap_init+0xcc>
          assert(PageProperty(p)); // 空闲
ffffffffc0202ba4:	00002697          	auipc	a3,0x2
ffffffffc0202ba8:	14c68693          	addi	a3,a3,332 # ffffffffc0204cf0 <commands+0x860>
ffffffffc0202bac:	00002617          	auipc	a2,0x2
ffffffffc0202bb0:	15460613          	addi	a2,a2,340 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202bb4:	0c300593          	li	a1,195
ffffffffc0202bb8:	00003517          	auipc	a0,0x3
ffffffffc0202bbc:	bf850513          	addi	a0,a0,-1032 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202bc0:	fb4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202bc4:	00003697          	auipc	a3,0x3
ffffffffc0202bc8:	dfc68693          	addi	a3,a3,-516 # ffffffffc02059c0 <default_pmm_manager+0x928>
ffffffffc0202bcc:	00002617          	auipc	a2,0x2
ffffffffc0202bd0:	13460613          	addi	a2,a2,308 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202bd4:	10900593          	li	a1,265
ffffffffc0202bd8:	00003517          	auipc	a0,0x3
ffffffffc0202bdc:	bd850513          	addi	a0,a0,-1064 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202be0:	f94fd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202be4:	00002617          	auipc	a2,0x2
ffffffffc0202be8:	77460613          	addi	a2,a2,1908 # ffffffffc0205358 <default_pmm_manager+0x2c0>
ffffffffc0202bec:	08900593          	li	a1,137
ffffffffc0202bf0:	00002517          	auipc	a0,0x2
ffffffffc0202bf4:	59050513          	addi	a0,a0,1424 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0202bf8:	f7cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202bfc:	00002617          	auipc	a2,0x2
ffffffffc0202c00:	56460613          	addi	a2,a2,1380 # ffffffffc0205160 <default_pmm_manager+0xc8>
ffffffffc0202c04:	07b00593          	li	a1,123
ffffffffc0202c08:	00002517          	auipc	a0,0x2
ffffffffc0202c0c:	57850513          	addi	a0,a0,1400 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0202c10:	f64fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(!PageProperty(check_rp[i])); // 不是空页面了
ffffffffc0202c14:	00003697          	auipc	a3,0x3
ffffffffc0202c18:	cc468693          	addi	a3,a3,-828 # ffffffffc02058d8 <default_pmm_manager+0x840>
ffffffffc0202c1c:	00002617          	auipc	a2,0x2
ffffffffc0202c20:	0e460613          	addi	a2,a2,228 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202c24:	0e800593          	li	a1,232
ffffffffc0202c28:	00003517          	auipc	a0,0x3
ffffffffc0202c2c:	b8850513          	addi	a0,a0,-1144 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202c30:	f44fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(check_rp[i] != NULL);
ffffffffc0202c34:	00003697          	auipc	a3,0x3
ffffffffc0202c38:	c8c68693          	addi	a3,a3,-884 # ffffffffc02058c0 <default_pmm_manager+0x828>
ffffffffc0202c3c:	00002617          	auipc	a2,0x2
ffffffffc0202c40:	0c460613          	addi	a2,a2,196 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202c44:	0e700593          	li	a1,231
ffffffffc0202c48:	00003517          	auipc	a0,0x3
ffffffffc0202c4c:	b6850513          	addi	a0,a0,-1176 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202c50:	f24fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(check_ptep[i] != NULL);
ffffffffc0202c54:	00003697          	auipc	a3,0x3
ffffffffc0202c58:	d5468693          	addi	a3,a3,-684 # ffffffffc02059a8 <default_pmm_manager+0x910>
ffffffffc0202c5c:	00002617          	auipc	a2,0x2
ffffffffc0202c60:	0a460613          	addi	a2,a2,164 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202c64:	10800593          	li	a1,264
ffffffffc0202c68:	00003517          	auipc	a0,0x3
ffffffffc0202c6c:	b4850513          	addi	a0,a0,-1208 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202c70:	f04fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202c74:	00003617          	auipc	a2,0x3
ffffffffc0202c78:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0205790 <default_pmm_manager+0x6f8>
ffffffffc0202c7c:	02900593          	li	a1,41
ffffffffc0202c80:	00003517          	auipc	a0,0x3
ffffffffc0202c84:	b3050513          	addi	a0,a0,-1232 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202c88:	eecfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202c8c:	00003697          	auipc	a3,0x3
ffffffffc0202c90:	cd468693          	addi	a3,a3,-812 # ffffffffc0205960 <default_pmm_manager+0x8c8>
ffffffffc0202c94:	00002617          	auipc	a2,0x2
ffffffffc0202c98:	06c60613          	addi	a2,a2,108 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202c9c:	09d00593          	li	a1,157
ffffffffc0202ca0:	00003517          	auipc	a0,0x3
ffffffffc0202ca4:	b1050513          	addi	a0,a0,-1264 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202ca8:	eccfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202cac:	00003697          	auipc	a3,0x3
ffffffffc0202cb0:	cb468693          	addi	a3,a3,-844 # ffffffffc0205960 <default_pmm_manager+0x8c8>
ffffffffc0202cb4:	00002617          	auipc	a2,0x2
ffffffffc0202cb8:	04c60613          	addi	a2,a2,76 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202cbc:	09f00593          	li	a1,159
ffffffffc0202cc0:	00003517          	auipc	a0,0x3
ffffffffc0202cc4:	af050513          	addi	a0,a0,-1296 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202cc8:	eacfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202ccc:	00003697          	auipc	a3,0x3
ffffffffc0202cd0:	cac68693          	addi	a3,a3,-852 # ffffffffc0205978 <default_pmm_manager+0x8e0>
ffffffffc0202cd4:	00002617          	auipc	a2,0x2
ffffffffc0202cd8:	02c60613          	addi	a2,a2,44 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202cdc:	0a100593          	li	a1,161
ffffffffc0202ce0:	00003517          	auipc	a0,0x3
ffffffffc0202ce4:	ad050513          	addi	a0,a0,-1328 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202ce8:	e8cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202cec:	00003697          	auipc	a3,0x3
ffffffffc0202cf0:	c8c68693          	addi	a3,a3,-884 # ffffffffc0205978 <default_pmm_manager+0x8e0>
ffffffffc0202cf4:	00002617          	auipc	a2,0x2
ffffffffc0202cf8:	00c60613          	addi	a2,a2,12 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202cfc:	0a300593          	li	a1,163
ffffffffc0202d00:	00003517          	auipc	a0,0x3
ffffffffc0202d04:	ab050513          	addi	a0,a0,-1360 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202d08:	e6cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202d0c:	00003697          	auipc	a3,0x3
ffffffffc0202d10:	c3c68693          	addi	a3,a3,-964 # ffffffffc0205948 <default_pmm_manager+0x8b0>
ffffffffc0202d14:	00002617          	auipc	a2,0x2
ffffffffc0202d18:	fec60613          	addi	a2,a2,-20 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202d1c:	09900593          	li	a1,153
ffffffffc0202d20:	00003517          	auipc	a0,0x3
ffffffffc0202d24:	a9050513          	addi	a0,a0,-1392 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202d28:	e4cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202d2c:	00003697          	auipc	a3,0x3
ffffffffc0202d30:	c1c68693          	addi	a3,a3,-996 # ffffffffc0205948 <default_pmm_manager+0x8b0>
ffffffffc0202d34:	00002617          	auipc	a2,0x2
ffffffffc0202d38:	fcc60613          	addi	a2,a2,-52 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202d3c:	09b00593          	li	a1,155
ffffffffc0202d40:	00003517          	auipc	a0,0x3
ffffffffc0202d44:	a7050513          	addi	a0,a0,-1424 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202d48:	e2cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // nr_free是全局的，free_pages会改变它的值
ffffffffc0202d4c:	00003697          	auipc	a3,0x3
ffffffffc0202d50:	bac68693          	addi	a3,a3,-1108 # ffffffffc02058f8 <default_pmm_manager+0x860>
ffffffffc0202d54:	00002617          	auipc	a2,0x2
ffffffffc0202d58:	fac60613          	addi	a2,a2,-84 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202d5c:	0f600593          	li	a1,246
ffffffffc0202d60:	00003517          	auipc	a0,0x3
ffffffffc0202d64:	a5050513          	addi	a0,a0,-1456 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202d68:	e0cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(temp_ptep != NULL);
ffffffffc0202d6c:	00003697          	auipc	a3,0x3
ffffffffc0202d70:	b1468693          	addi	a3,a3,-1260 # ffffffffc0205880 <default_pmm_manager+0x7e8>
ffffffffc0202d74:	00002617          	auipc	a2,0x2
ffffffffc0202d78:	f8c60613          	addi	a2,a2,-116 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202d7c:	0e000593          	li	a1,224
ffffffffc0202d80:	00003517          	auipc	a0,0x3
ffffffffc0202d84:	a3050513          	addi	a0,a0,-1488 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202d88:	decfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202d8c:	00003697          	auipc	a3,0x3
ffffffffc0202d90:	c0468693          	addi	a3,a3,-1020 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0202d94:	00002617          	auipc	a2,0x2
ffffffffc0202d98:	f6c60613          	addi	a2,a2,-148 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202d9c:	0a500593          	li	a1,165
ffffffffc0202da0:	00003517          	auipc	a0,0x3
ffffffffc0202da4:	a1050513          	addi	a0,a0,-1520 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202da8:	dccfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202dac:	00003697          	auipc	a3,0x3
ffffffffc0202db0:	be468693          	addi	a3,a3,-1052 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0202db4:	00002617          	auipc	a2,0x2
ffffffffc0202db8:	f4c60613          	addi	a2,a2,-180 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202dbc:	0a700593          	li	a1,167
ffffffffc0202dc0:	00003517          	auipc	a0,0x3
ffffffffc0202dc4:	9f050513          	addi	a0,a0,-1552 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202dc8:	dacfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(nr_free == 0);
ffffffffc0202dcc:	00002697          	auipc	a3,0x2
ffffffffc0202dd0:	10c68693          	addi	a3,a3,268 # ffffffffc0204ed8 <commands+0xa48>
ffffffffc0202dd4:	00002617          	auipc	a2,0x2
ffffffffc0202dd8:	f2c60613          	addi	a2,a2,-212 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202ddc:	0ff00593          	li	a1,255
ffffffffc0202de0:	00003517          	auipc	a0,0x3
ffffffffc0202de4:	9d050513          	addi	a0,a0,-1584 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202de8:	d8cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(ret == 0);
ffffffffc0202dec:	00003697          	auipc	a3,0x3
ffffffffc0202df0:	c2468693          	addi	a3,a3,-988 # ffffffffc0205a10 <default_pmm_manager+0x978>
ffffffffc0202df4:	00002617          	auipc	a2,0x2
ffffffffc0202df8:	f0c60613          	addi	a2,a2,-244 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202dfc:	11000593          	li	a1,272
ffffffffc0202e00:	00003517          	auipc	a0,0x3
ffffffffc0202e04:	9b050513          	addi	a0,a0,-1616 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202e08:	d6cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(mm != NULL);
ffffffffc0202e0c:	00003697          	auipc	a3,0x3
ffffffffc0202e10:	9f468693          	addi	a3,a3,-1548 # ffffffffc0205800 <default_pmm_manager+0x768>
ffffffffc0202e14:	00002617          	auipc	a2,0x2
ffffffffc0202e18:	eec60613          	addi	a2,a2,-276 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202e1c:	0cc00593          	li	a1,204
ffffffffc0202e20:	00003517          	auipc	a0,0x3
ffffffffc0202e24:	99050513          	addi	a0,a0,-1648 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202e28:	d4cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202e2c:	00003697          	auipc	a3,0x3
ffffffffc0202e30:	9e468693          	addi	a3,a3,-1564 # ffffffffc0205810 <default_pmm_manager+0x778>
ffffffffc0202e34:	00002617          	auipc	a2,0x2
ffffffffc0202e38:	ecc60613          	addi	a2,a2,-308 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202e3c:	0d000593          	li	a1,208
ffffffffc0202e40:	00003517          	auipc	a0,0x3
ffffffffc0202e44:	97050513          	addi	a0,a0,-1680 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202e48:	d2cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202e4c:	00003697          	auipc	a3,0x3
ffffffffc0202e50:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0205828 <default_pmm_manager+0x790>
ffffffffc0202e54:	00002617          	auipc	a2,0x2
ffffffffc0202e58:	eac60613          	addi	a2,a2,-340 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202e5c:	0d500593          	li	a1,213
ffffffffc0202e60:	00003517          	auipc	a0,0x3
ffffffffc0202e64:	95050513          	addi	a0,a0,-1712 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202e68:	d0cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(vma != NULL);
ffffffffc0202e6c:	00003697          	auipc	a3,0x3
ffffffffc0202e70:	9cc68693          	addi	a3,a3,-1588 # ffffffffc0205838 <default_pmm_manager+0x7a0>
ffffffffc0202e74:	00002617          	auipc	a2,0x2
ffffffffc0202e78:	e8c60613          	addi	a2,a2,-372 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202e7c:	0d800593          	li	a1,216
ffffffffc0202e80:	00003517          	auipc	a0,0x3
ffffffffc0202e84:	93050513          	addi	a0,a0,-1744 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202e88:	cecfd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202e8c:	00002697          	auipc	a3,0x2
ffffffffc0202e90:	ea468693          	addi	a3,a3,-348 # ffffffffc0204d30 <commands+0x8a0>
ffffffffc0202e94:	00002617          	auipc	a2,0x2
ffffffffc0202e98:	e6c60613          	addi	a2,a2,-404 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202e9c:	0c600593          	li	a1,198
ffffffffc0202ea0:	00003517          	auipc	a0,0x3
ffffffffc0202ea4:	91050513          	addi	a0,a0,-1776 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202ea8:	cccfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202eac <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202eac:	0000e797          	auipc	a5,0xe
ffffffffc0202eb0:	5b478793          	addi	a5,a5,1460 # ffffffffc0211460 <sm>
ffffffffc0202eb4:	639c                	ld	a5,0(a5)
ffffffffc0202eb6:	0107b303          	ld	t1,16(a5)
ffffffffc0202eba:	8302                	jr	t1

ffffffffc0202ebc <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202ebc:	0000e797          	auipc	a5,0xe
ffffffffc0202ec0:	5a478793          	addi	a5,a5,1444 # ffffffffc0211460 <sm>
ffffffffc0202ec4:	639c                	ld	a5,0(a5)
ffffffffc0202ec6:	0207b303          	ld	t1,32(a5)
ffffffffc0202eca:	8302                	jr	t1

ffffffffc0202ecc <swap_out>:
{
ffffffffc0202ecc:	711d                	addi	sp,sp,-96
ffffffffc0202ece:	ec86                	sd	ra,88(sp)
ffffffffc0202ed0:	e8a2                	sd	s0,80(sp)
ffffffffc0202ed2:	e4a6                	sd	s1,72(sp)
ffffffffc0202ed4:	e0ca                	sd	s2,64(sp)
ffffffffc0202ed6:	fc4e                	sd	s3,56(sp)
ffffffffc0202ed8:	f852                	sd	s4,48(sp)
ffffffffc0202eda:	f456                	sd	s5,40(sp)
ffffffffc0202edc:	f05a                	sd	s6,32(sp)
ffffffffc0202ede:	ec5e                	sd	s7,24(sp)
ffffffffc0202ee0:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++i)
ffffffffc0202ee2:	cde9                	beqz	a1,ffffffffc0202fbc <swap_out+0xf0>
ffffffffc0202ee4:	8ab2                	mv	s5,a2
ffffffffc0202ee6:	892a                	mv	s2,a0
ffffffffc0202ee8:	8a2e                	mv	s4,a1
ffffffffc0202eea:	4401                	li	s0,0
ffffffffc0202eec:	0000e997          	auipc	s3,0xe
ffffffffc0202ef0:	57498993          	addi	s3,s3,1396 # ffffffffc0211460 <sm>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202ef4:	00003b17          	auipc	s6,0x3
ffffffffc0202ef8:	bccb0b13          	addi	s6,s6,-1076 # ffffffffc0205ac0 <default_pmm_manager+0xa28>
               cprintf("SWAP: failed to save\n");
ffffffffc0202efc:	00003b97          	auipc	s7,0x3
ffffffffc0202f00:	bacb8b93          	addi	s7,s7,-1108 # ffffffffc0205aa8 <default_pmm_manager+0xa10>
ffffffffc0202f04:	a825                	j	ffffffffc0202f3c <swap_out+0x70>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f06:	67a2                	ld	a5,8(sp)
ffffffffc0202f08:	8626                	mv	a2,s1
ffffffffc0202f0a:	85a2                	mv	a1,s0
ffffffffc0202f0c:	63b4                	ld	a3,64(a5)
ffffffffc0202f0e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++i)
ffffffffc0202f10:	2405                	addiw	s0,s0,1
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f12:	82b1                	srli	a3,a3,0xc
ffffffffc0202f14:	0685                	addi	a3,a3,1
ffffffffc0202f16:	9a8fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f1a:	6522                	ld	a0,8(sp)
               free_page(page);
ffffffffc0202f1c:	4585                	li	a1,1
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f1e:	613c                	ld	a5,64(a0)
ffffffffc0202f20:	83b1                	srli	a5,a5,0xc
ffffffffc0202f22:	0785                	addi	a5,a5,1
ffffffffc0202f24:	07a2                	slli	a5,a5,0x8
ffffffffc0202f26:	00fc3023          	sd	a5,0(s8) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
               free_page(page);
ffffffffc0202f2a:	fbcfe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0202f2e:	01893503          	ld	a0,24(s2)
ffffffffc0202f32:	85a6                	mv	a1,s1
ffffffffc0202f34:	ebeff0ef          	jal	ra,ffffffffc02025f2 <tlb_invalidate>
     for (i = 0; i != n; ++i)
ffffffffc0202f38:	048a0d63          	beq	s4,s0,ffffffffc0202f92 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick); // 调用页面置换算法的接口
ffffffffc0202f3c:	0009b783          	ld	a5,0(s3)
ffffffffc0202f40:	8656                	mv	a2,s5
ffffffffc0202f42:	002c                	addi	a1,sp,8
ffffffffc0202f44:	7b9c                	ld	a5,48(a5)
ffffffffc0202f46:	854a                	mv	a0,s2
ffffffffc0202f48:	9782                	jalr	a5
          if (r != 0)
ffffffffc0202f4a:	e12d                	bnez	a0,ffffffffc0202fac <swap_out+0xe0>
          v = page->pra_vaddr; // 可以获取物理页面对应的虚拟地址
ffffffffc0202f4c:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202f4e:	01893503          	ld	a0,24(s2)
ffffffffc0202f52:	4601                	li	a2,0
          v = page->pra_vaddr; // 可以获取物理页面对应的虚拟地址
ffffffffc0202f54:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202f56:	85a6                	mv	a1,s1
ffffffffc0202f58:	815fe0ef          	jal	ra,ffffffffc020176c <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202f5c:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202f5e:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0202f60:	8b85                	andi	a5,a5,1
ffffffffc0202f62:	cfb9                	beqz	a5,ffffffffc0202fc0 <swap_out+0xf4>
          if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0)
ffffffffc0202f64:	65a2                	ld	a1,8(sp)
ffffffffc0202f66:	61bc                	ld	a5,64(a1)
ffffffffc0202f68:	83b1                	srli	a5,a5,0xc
ffffffffc0202f6a:	00178513          	addi	a0,a5,1
ffffffffc0202f6e:	0522                	slli	a0,a0,0x8
ffffffffc0202f70:	5d3000ef          	jal	ra,ffffffffc0203d42 <swapfs_write>
ffffffffc0202f74:	d949                	beqz	a0,ffffffffc0202f06 <swap_out+0x3a>
               cprintf("SWAP: failed to save\n");
ffffffffc0202f76:	855e                	mv	a0,s7
ffffffffc0202f78:	946fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202f7c:	0009b783          	ld	a5,0(s3)
ffffffffc0202f80:	6622                	ld	a2,8(sp)
ffffffffc0202f82:	4681                	li	a3,0
ffffffffc0202f84:	739c                	ld	a5,32(a5)
ffffffffc0202f86:	85a6                	mv	a1,s1
ffffffffc0202f88:	854a                	mv	a0,s2
     for (i = 0; i != n; ++i)
ffffffffc0202f8a:	2405                	addiw	s0,s0,1
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202f8c:	9782                	jalr	a5
     for (i = 0; i != n; ++i)
ffffffffc0202f8e:	fa8a17e3          	bne	s4,s0,ffffffffc0202f3c <swap_out+0x70>
}
ffffffffc0202f92:	8522                	mv	a0,s0
ffffffffc0202f94:	60e6                	ld	ra,88(sp)
ffffffffc0202f96:	6446                	ld	s0,80(sp)
ffffffffc0202f98:	64a6                	ld	s1,72(sp)
ffffffffc0202f9a:	6906                	ld	s2,64(sp)
ffffffffc0202f9c:	79e2                	ld	s3,56(sp)
ffffffffc0202f9e:	7a42                	ld	s4,48(sp)
ffffffffc0202fa0:	7aa2                	ld	s5,40(sp)
ffffffffc0202fa2:	7b02                	ld	s6,32(sp)
ffffffffc0202fa4:	6be2                	ld	s7,24(sp)
ffffffffc0202fa6:	6c42                	ld	s8,16(sp)
ffffffffc0202fa8:	6125                	addi	sp,sp,96
ffffffffc0202faa:	8082                	ret
               cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0202fac:	85a2                	mv	a1,s0
ffffffffc0202fae:	00003517          	auipc	a0,0x3
ffffffffc0202fb2:	ab250513          	addi	a0,a0,-1358 # ffffffffc0205a60 <default_pmm_manager+0x9c8>
ffffffffc0202fb6:	908fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               break;
ffffffffc0202fba:	bfe1                	j	ffffffffc0202f92 <swap_out+0xc6>
     for (i = 0; i != n; ++i)
ffffffffc0202fbc:	4401                	li	s0,0
ffffffffc0202fbe:	bfd1                	j	ffffffffc0202f92 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202fc0:	00003697          	auipc	a3,0x3
ffffffffc0202fc4:	ad068693          	addi	a3,a3,-1328 # ffffffffc0205a90 <default_pmm_manager+0x9f8>
ffffffffc0202fc8:	00002617          	auipc	a2,0x2
ffffffffc0202fcc:	d3860613          	addi	a2,a2,-712 # ffffffffc0204d00 <commands+0x870>
ffffffffc0202fd0:	06700593          	li	a1,103
ffffffffc0202fd4:	00002517          	auipc	a0,0x2
ffffffffc0202fd8:	7dc50513          	addi	a0,a0,2012 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0202fdc:	b98fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202fe0 <swap_in>:
{
ffffffffc0202fe0:	7179                	addi	sp,sp,-48
ffffffffc0202fe2:	e84a                	sd	s2,16(sp)
ffffffffc0202fe4:	892a                	mv	s2,a0
     struct Page *result = alloc_page(); // 这里alloc_page()内部可能调用swap_out()
ffffffffc0202fe6:	4505                	li	a0,1
{
ffffffffc0202fe8:	ec26                	sd	s1,24(sp)
ffffffffc0202fea:	e44e                	sd	s3,8(sp)
ffffffffc0202fec:	f406                	sd	ra,40(sp)
ffffffffc0202fee:	f022                	sd	s0,32(sp)
ffffffffc0202ff0:	84ae                	mv	s1,a1
ffffffffc0202ff2:	89b2                	mv	s3,a2
     struct Page *result = alloc_page(); // 这里alloc_page()内部可能调用swap_out()
ffffffffc0202ff4:	e6afe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
     assert(result != NULL);
ffffffffc0202ff8:	c129                	beqz	a0,ffffffffc020303a <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 找到/构建对应的页表项
ffffffffc0202ffa:	842a                	mv	s0,a0
ffffffffc0202ffc:	01893503          	ld	a0,24(s2)
ffffffffc0203000:	4601                	li	a2,0
ffffffffc0203002:	85a6                	mv	a1,s1
ffffffffc0203004:	f68fe0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0203008:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0) // 将数据从硬盘读到内存
ffffffffc020300a:	6108                	ld	a0,0(a0)
ffffffffc020300c:	85a2                	mv	a1,s0
ffffffffc020300e:	48f000ef          	jal	ra,ffffffffc0203c9c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc0203012:	00093583          	ld	a1,0(s2)
ffffffffc0203016:	8626                	mv	a2,s1
ffffffffc0203018:	00002517          	auipc	a0,0x2
ffffffffc020301c:	73850513          	addi	a0,a0,1848 # ffffffffc0205750 <default_pmm_manager+0x6b8>
ffffffffc0203020:	81a1                	srli	a1,a1,0x8
ffffffffc0203022:	89cfd0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc0203026:	70a2                	ld	ra,40(sp)
     *ptr_result = result;
ffffffffc0203028:	0089b023          	sd	s0,0(s3)
}
ffffffffc020302c:	7402                	ld	s0,32(sp)
ffffffffc020302e:	64e2                	ld	s1,24(sp)
ffffffffc0203030:	6942                	ld	s2,16(sp)
ffffffffc0203032:	69a2                	ld	s3,8(sp)
ffffffffc0203034:	4501                	li	a0,0
ffffffffc0203036:	6145                	addi	sp,sp,48
ffffffffc0203038:	8082                	ret
     assert(result != NULL);
ffffffffc020303a:	00002697          	auipc	a3,0x2
ffffffffc020303e:	70668693          	addi	a3,a3,1798 # ffffffffc0205740 <default_pmm_manager+0x6a8>
ffffffffc0203042:	00002617          	auipc	a2,0x2
ffffffffc0203046:	cbe60613          	addi	a2,a2,-834 # ffffffffc0204d00 <commands+0x870>
ffffffffc020304a:	08500593          	li	a1,133
ffffffffc020304e:	00002517          	auipc	a0,0x2
ffffffffc0203052:	76250513          	addi	a0,a0,1890 # ffffffffc02057b0 <default_pmm_manager+0x718>
ffffffffc0203056:	b1efd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020305a <_lru_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc020305a:	0000e797          	auipc	a5,0xe
ffffffffc020305e:	51e78793          	addi	a5,a5,1310 # ffffffffc0211578 <pra_list_head>

static int
_lru_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
ffffffffc0203062:	f51c                	sd	a5,40(a0)
ffffffffc0203064:	e79c                	sd	a5,8(a5)
ffffffffc0203066:	e39c                	sd	a5,0(a5)
    return 0;
}
ffffffffc0203068:	4501                	li	a0,0
ffffffffc020306a:	8082                	ret

ffffffffc020306c <_lru_init>:
    list_del(bottom);
    return 0;
}

// other functions similar to FIFO
static int _lru_init() { return 0; }
ffffffffc020306c:	4501                	li	a0,0
ffffffffc020306e:	8082                	ret

ffffffffc0203070 <_lru_check_swap>:
static int _lru_tick_event() { return 0; }
static int _lru_set_unswappable() { return 0; }
static int _lru_check_swap()
{
ffffffffc0203070:	711d                	addi	sp,sp,-96
ffffffffc0203072:	fc4e                	sd	s3,56(sp)
ffffffffc0203074:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc0203076:	00003517          	auipc	a0,0x3
ffffffffc020307a:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0205b00 <default_pmm_manager+0xa68>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020307e:	698d                	lui	s3,0x3
ffffffffc0203080:	4a31                	li	s4,12
{
ffffffffc0203082:	e8a2                	sd	s0,80(sp)
ffffffffc0203084:	e4a6                	sd	s1,72(sp)
ffffffffc0203086:	ec86                	sd	ra,88(sp)
ffffffffc0203088:	e0ca                	sd	s2,64(sp)
ffffffffc020308a:	f456                	sd	s5,40(sp)
ffffffffc020308c:	f05a                	sd	s6,32(sp)
ffffffffc020308e:	ec5e                	sd	s7,24(sp)
ffffffffc0203090:	e862                	sd	s8,16(sp)
ffffffffc0203092:	e466                	sd	s9,8(sp)
    assert(pgfault_num == 4);
ffffffffc0203094:	0000e417          	auipc	s0,0xe
ffffffffc0203098:	3d840413          	addi	s0,s0,984 # ffffffffc021146c <pgfault_num>
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc020309c:	822fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02030a0:	01498023          	sb	s4,0(s3) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num == 4);
ffffffffc02030a4:	4004                	lw	s1,0(s0)
ffffffffc02030a6:	4791                	li	a5,4
ffffffffc02030a8:	2481                	sext.w	s1,s1
ffffffffc02030aa:	14f49963          	bne	s1,a5,ffffffffc02031fc <_lru_check_swap+0x18c>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc02030ae:	00003517          	auipc	a0,0x3
ffffffffc02030b2:	a9250513          	addi	a0,a0,-1390 # ffffffffc0205b40 <default_pmm_manager+0xaa8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02030b6:	6a85                	lui	s5,0x1
ffffffffc02030b8:	4b29                	li	s6,10
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc02030ba:	804fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02030be:	016a8023          	sb	s6,0(s5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num == 4);
ffffffffc02030c2:	00042903          	lw	s2,0(s0)
ffffffffc02030c6:	2901                	sext.w	s2,s2
ffffffffc02030c8:	2a991a63          	bne	s2,s1,ffffffffc020337c <_lru_check_swap+0x30c>
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc02030cc:	00003517          	auipc	a0,0x3
ffffffffc02030d0:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0205b68 <default_pmm_manager+0xad0>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02030d4:	6b91                	lui	s7,0x4
ffffffffc02030d6:	4c35                	li	s8,13
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc02030d8:	fe7fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02030dc:	018b8023          	sb	s8,0(s7) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num == 4);
ffffffffc02030e0:	4004                	lw	s1,0(s0)
ffffffffc02030e2:	2481                	sext.w	s1,s1
ffffffffc02030e4:	27249c63          	bne	s1,s2,ffffffffc020335c <_lru_check_swap+0x2ec>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc02030e8:	00003517          	auipc	a0,0x3
ffffffffc02030ec:	aa850513          	addi	a0,a0,-1368 # ffffffffc0205b90 <default_pmm_manager+0xaf8>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02030f0:	6909                	lui	s2,0x2
ffffffffc02030f2:	4cad                	li	s9,11
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc02030f4:	fcbfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02030f8:	01990023          	sb	s9,0(s2) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num == 4);
ffffffffc02030fc:	401c                	lw	a5,0(s0)
ffffffffc02030fe:	2781                	sext.w	a5,a5
ffffffffc0203100:	22979e63          	bne	a5,s1,ffffffffc020333c <_lru_check_swap+0x2cc>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc0203104:	00003517          	auipc	a0,0x3
ffffffffc0203108:	ab450513          	addi	a0,a0,-1356 # ffffffffc0205bb8 <default_pmm_manager+0xb20>
ffffffffc020310c:	fb3fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203110:	6795                	lui	a5,0x5
ffffffffc0203112:	4739                	li	a4,14
ffffffffc0203114:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc0203118:	4004                	lw	s1,0(s0)
ffffffffc020311a:	4795                	li	a5,5
ffffffffc020311c:	2481                	sext.w	s1,s1
ffffffffc020311e:	1ef49f63          	bne	s1,a5,ffffffffc020331c <_lru_check_swap+0x2ac>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0205b90 <default_pmm_manager+0xaf8>
ffffffffc020312a:	f95fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020312e:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 5);
ffffffffc0203132:	401c                	lw	a5,0(s0)
ffffffffc0203134:	2781                	sext.w	a5,a5
ffffffffc0203136:	1c979363          	bne	a5,s1,ffffffffc02032fc <_lru_check_swap+0x28c>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc020313a:	00003517          	auipc	a0,0x3
ffffffffc020313e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0205b40 <default_pmm_manager+0xaa8>
ffffffffc0203142:	f7dfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203146:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num == 6);
ffffffffc020314a:	401c                	lw	a5,0(s0)
ffffffffc020314c:	4719                	li	a4,6
ffffffffc020314e:	2781                	sext.w	a5,a5
ffffffffc0203150:	18e79663          	bne	a5,a4,ffffffffc02032dc <_lru_check_swap+0x26c>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0203154:	00003517          	auipc	a0,0x3
ffffffffc0203158:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0205b90 <default_pmm_manager+0xaf8>
ffffffffc020315c:	f63fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203160:	01990023          	sb	s9,0(s2)
    assert(pgfault_num == 7);
ffffffffc0203164:	401c                	lw	a5,0(s0)
ffffffffc0203166:	471d                	li	a4,7
ffffffffc0203168:	2781                	sext.w	a5,a5
ffffffffc020316a:	14e79963          	bne	a5,a4,ffffffffc02032bc <_lru_check_swap+0x24c>
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc020316e:	00003517          	auipc	a0,0x3
ffffffffc0203172:	99250513          	addi	a0,a0,-1646 # ffffffffc0205b00 <default_pmm_manager+0xa68>
ffffffffc0203176:	f49fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020317a:	01498023          	sb	s4,0(s3)
    assert(pgfault_num == 8);
ffffffffc020317e:	401c                	lw	a5,0(s0)
ffffffffc0203180:	4721                	li	a4,8
ffffffffc0203182:	2781                	sext.w	a5,a5
ffffffffc0203184:	10e79c63          	bne	a5,a4,ffffffffc020329c <_lru_check_swap+0x22c>
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc0203188:	00003517          	auipc	a0,0x3
ffffffffc020318c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0205b68 <default_pmm_manager+0xad0>
ffffffffc0203190:	f2ffc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203194:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num == 9);
ffffffffc0203198:	401c                	lw	a5,0(s0)
ffffffffc020319a:	4725                	li	a4,9
ffffffffc020319c:	2781                	sext.w	a5,a5
ffffffffc020319e:	0ce79f63          	bne	a5,a4,ffffffffc020327c <_lru_check_swap+0x20c>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc02031a2:	00003517          	auipc	a0,0x3
ffffffffc02031a6:	a1650513          	addi	a0,a0,-1514 # ffffffffc0205bb8 <default_pmm_manager+0xb20>
ffffffffc02031aa:	f15fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02031ae:	6795                	lui	a5,0x5
ffffffffc02031b0:	4739                	li	a4,14
ffffffffc02031b2:	00e78023          	sb	a4,0(a5) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 10);
ffffffffc02031b6:	4004                	lw	s1,0(s0)
ffffffffc02031b8:	47a9                	li	a5,10
ffffffffc02031ba:	2481                	sext.w	s1,s1
ffffffffc02031bc:	0af49063          	bne	s1,a5,ffffffffc020325c <_lru_check_swap+0x1ec>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc02031c0:	00003517          	auipc	a0,0x3
ffffffffc02031c4:	98050513          	addi	a0,a0,-1664 # ffffffffc0205b40 <default_pmm_manager+0xaa8>
ffffffffc02031c8:	ef7fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02031cc:	6785                	lui	a5,0x1
ffffffffc02031ce:	0007c783          	lbu	a5,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc02031d2:	06979563          	bne	a5,s1,ffffffffc020323c <_lru_check_swap+0x1cc>
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 11);
ffffffffc02031d6:	401c                	lw	a5,0(s0)
ffffffffc02031d8:	472d                	li	a4,11
ffffffffc02031da:	2781                	sext.w	a5,a5
ffffffffc02031dc:	04e79063          	bne	a5,a4,ffffffffc020321c <_lru_check_swap+0x1ac>
    return 0;
}
ffffffffc02031e0:	60e6                	ld	ra,88(sp)
ffffffffc02031e2:	6446                	ld	s0,80(sp)
ffffffffc02031e4:	64a6                	ld	s1,72(sp)
ffffffffc02031e6:	6906                	ld	s2,64(sp)
ffffffffc02031e8:	79e2                	ld	s3,56(sp)
ffffffffc02031ea:	7a42                	ld	s4,48(sp)
ffffffffc02031ec:	7aa2                	ld	s5,40(sp)
ffffffffc02031ee:	7b02                	ld	s6,32(sp)
ffffffffc02031f0:	6be2                	ld	s7,24(sp)
ffffffffc02031f2:	6c42                	ld	s8,16(sp)
ffffffffc02031f4:	6ca2                	ld	s9,8(sp)
ffffffffc02031f6:	4501                	li	a0,0
ffffffffc02031f8:	6125                	addi	sp,sp,96
ffffffffc02031fa:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc02031fc:	00002697          	auipc	a3,0x2
ffffffffc0203200:	79468693          	addi	a3,a3,1940 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0203204:	00002617          	auipc	a2,0x2
ffffffffc0203208:	afc60613          	addi	a2,a2,-1284 # ffffffffc0204d00 <commands+0x870>
ffffffffc020320c:	03a00593          	li	a1,58
ffffffffc0203210:	00003517          	auipc	a0,0x3
ffffffffc0203214:	91850513          	addi	a0,a0,-1768 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203218:	95cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 11);
ffffffffc020321c:	00003697          	auipc	a3,0x3
ffffffffc0203220:	a7c68693          	addi	a3,a3,-1412 # ffffffffc0205c98 <default_pmm_manager+0xc00>
ffffffffc0203224:	00002617          	auipc	a2,0x2
ffffffffc0203228:	adc60613          	addi	a2,a2,-1316 # ffffffffc0204d00 <commands+0x870>
ffffffffc020322c:	05c00593          	li	a1,92
ffffffffc0203230:	00003517          	auipc	a0,0x3
ffffffffc0203234:	8f850513          	addi	a0,a0,-1800 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203238:	93cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020323c:	00003697          	auipc	a3,0x3
ffffffffc0203240:	a3468693          	addi	a3,a3,-1484 # ffffffffc0205c70 <default_pmm_manager+0xbd8>
ffffffffc0203244:	00002617          	auipc	a2,0x2
ffffffffc0203248:	abc60613          	addi	a2,a2,-1348 # ffffffffc0204d00 <commands+0x870>
ffffffffc020324c:	05a00593          	li	a1,90
ffffffffc0203250:	00003517          	auipc	a0,0x3
ffffffffc0203254:	8d850513          	addi	a0,a0,-1832 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203258:	91cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 10);
ffffffffc020325c:	00003697          	auipc	a3,0x3
ffffffffc0203260:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0205c58 <default_pmm_manager+0xbc0>
ffffffffc0203264:	00002617          	auipc	a2,0x2
ffffffffc0203268:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0204d00 <commands+0x870>
ffffffffc020326c:	05800593          	li	a1,88
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	8b850513          	addi	a0,a0,-1864 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203278:	8fcfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 9);
ffffffffc020327c:	00003697          	auipc	a3,0x3
ffffffffc0203280:	9c468693          	addi	a3,a3,-1596 # ffffffffc0205c40 <default_pmm_manager+0xba8>
ffffffffc0203284:	00002617          	auipc	a2,0x2
ffffffffc0203288:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0204d00 <commands+0x870>
ffffffffc020328c:	05500593          	li	a1,85
ffffffffc0203290:	00003517          	auipc	a0,0x3
ffffffffc0203294:	89850513          	addi	a0,a0,-1896 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203298:	8dcfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 8);
ffffffffc020329c:	00003697          	auipc	a3,0x3
ffffffffc02032a0:	98c68693          	addi	a3,a3,-1652 # ffffffffc0205c28 <default_pmm_manager+0xb90>
ffffffffc02032a4:	00002617          	auipc	a2,0x2
ffffffffc02032a8:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0204d00 <commands+0x870>
ffffffffc02032ac:	05200593          	li	a1,82
ffffffffc02032b0:	00003517          	auipc	a0,0x3
ffffffffc02032b4:	87850513          	addi	a0,a0,-1928 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc02032b8:	8bcfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 7);
ffffffffc02032bc:	00003697          	auipc	a3,0x3
ffffffffc02032c0:	95468693          	addi	a3,a3,-1708 # ffffffffc0205c10 <default_pmm_manager+0xb78>
ffffffffc02032c4:	00002617          	auipc	a2,0x2
ffffffffc02032c8:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0204d00 <commands+0x870>
ffffffffc02032cc:	04f00593          	li	a1,79
ffffffffc02032d0:	00003517          	auipc	a0,0x3
ffffffffc02032d4:	85850513          	addi	a0,a0,-1960 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc02032d8:	89cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 6);
ffffffffc02032dc:	00003697          	auipc	a3,0x3
ffffffffc02032e0:	91c68693          	addi	a3,a3,-1764 # ffffffffc0205bf8 <default_pmm_manager+0xb60>
ffffffffc02032e4:	00002617          	auipc	a2,0x2
ffffffffc02032e8:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0204d00 <commands+0x870>
ffffffffc02032ec:	04c00593          	li	a1,76
ffffffffc02032f0:	00003517          	auipc	a0,0x3
ffffffffc02032f4:	83850513          	addi	a0,a0,-1992 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc02032f8:	87cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc02032fc:	00003697          	auipc	a3,0x3
ffffffffc0203300:	8e468693          	addi	a3,a3,-1820 # ffffffffc0205be0 <default_pmm_manager+0xb48>
ffffffffc0203304:	00002617          	auipc	a2,0x2
ffffffffc0203308:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0204d00 <commands+0x870>
ffffffffc020330c:	04900593          	li	a1,73
ffffffffc0203310:	00003517          	auipc	a0,0x3
ffffffffc0203314:	81850513          	addi	a0,a0,-2024 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203318:	85cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc020331c:	00003697          	auipc	a3,0x3
ffffffffc0203320:	8c468693          	addi	a3,a3,-1852 # ffffffffc0205be0 <default_pmm_manager+0xb48>
ffffffffc0203324:	00002617          	auipc	a2,0x2
ffffffffc0203328:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0204d00 <commands+0x870>
ffffffffc020332c:	04600593          	li	a1,70
ffffffffc0203330:	00002517          	auipc	a0,0x2
ffffffffc0203334:	7f850513          	addi	a0,a0,2040 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203338:	83cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc020333c:	00002697          	auipc	a3,0x2
ffffffffc0203340:	65468693          	addi	a3,a3,1620 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0203344:	00002617          	auipc	a2,0x2
ffffffffc0203348:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0204d00 <commands+0x870>
ffffffffc020334c:	04300593          	li	a1,67
ffffffffc0203350:	00002517          	auipc	a0,0x2
ffffffffc0203354:	7d850513          	addi	a0,a0,2008 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203358:	81cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc020335c:	00002697          	auipc	a3,0x2
ffffffffc0203360:	63468693          	addi	a3,a3,1588 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0203364:	00002617          	auipc	a2,0x2
ffffffffc0203368:	99c60613          	addi	a2,a2,-1636 # ffffffffc0204d00 <commands+0x870>
ffffffffc020336c:	04000593          	li	a1,64
ffffffffc0203370:	00002517          	auipc	a0,0x2
ffffffffc0203374:	7b850513          	addi	a0,a0,1976 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203378:	ffdfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc020337c:	00002697          	auipc	a3,0x2
ffffffffc0203380:	61468693          	addi	a3,a3,1556 # ffffffffc0205990 <default_pmm_manager+0x8f8>
ffffffffc0203384:	00002617          	auipc	a2,0x2
ffffffffc0203388:	97c60613          	addi	a2,a2,-1668 # ffffffffc0204d00 <commands+0x870>
ffffffffc020338c:	03d00593          	li	a1,61
ffffffffc0203390:	00002517          	auipc	a0,0x2
ffffffffc0203394:	79850513          	addi	a0,a0,1944 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203398:	fddfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020339c <_lru_swap_out_victim>:
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc020339c:	751c                	ld	a5,40(a0)
{
ffffffffc020339e:	1101                	addi	sp,sp,-32
ffffffffc02033a0:	ec06                	sd	ra,24(sp)
ffffffffc02033a2:	e822                	sd	s0,16(sp)
ffffffffc02033a4:	e426                	sd	s1,8(sp)
    assert(head != NULL);
ffffffffc02033a6:	cb85                	beqz	a5,ffffffffc02033d6 <_lru_swap_out_victim+0x3a>
    assert(in_tick == 0);
ffffffffc02033a8:	e639                	bnez	a2,ffffffffc02033f6 <_lru_swap_out_victim+0x5a>
    list_entry_t *bottom = head->prev;
ffffffffc02033aa:	6380                	ld	s0,0(a5)
ffffffffc02033ac:	84ae                	mv	s1,a1
    cprintf("curr_ptr 0xffffffff%x\n", bottom);
ffffffffc02033ae:	00003517          	auipc	a0,0x3
ffffffffc02033b2:	94250513          	addi	a0,a0,-1726 # ffffffffc0205cf0 <default_pmm_manager+0xc58>
ffffffffc02033b6:	85a2                	mv	a1,s0
ffffffffc02033b8:	d07fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc02033bc:	6018                	ld	a4,0(s0)
ffffffffc02033be:	641c                	ld	a5,8(s0)
    struct Page *page = le2page(bottom, pra_page_link);
ffffffffc02033c0:	fd040413          	addi	s0,s0,-48
    *ptr_page = page;
ffffffffc02033c4:	e080                	sd	s0,0(s1)
}
ffffffffc02033c6:	60e2                	ld	ra,24(sp)
ffffffffc02033c8:	6442                	ld	s0,16(sp)
    prev->next = next;
ffffffffc02033ca:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02033cc:	e398                	sd	a4,0(a5)
ffffffffc02033ce:	64a2                	ld	s1,8(sp)
ffffffffc02033d0:	4501                	li	a0,0
ffffffffc02033d2:	6105                	addi	sp,sp,32
ffffffffc02033d4:	8082                	ret
    assert(head != NULL);
ffffffffc02033d6:	00003697          	auipc	a3,0x3
ffffffffc02033da:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0205cd0 <default_pmm_manager+0xc38>
ffffffffc02033de:	00002617          	auipc	a2,0x2
ffffffffc02033e2:	92260613          	addi	a2,a2,-1758 # ffffffffc0204d00 <commands+0x870>
ffffffffc02033e6:	02800593          	li	a1,40
ffffffffc02033ea:	00002517          	auipc	a0,0x2
ffffffffc02033ee:	73e50513          	addi	a0,a0,1854 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc02033f2:	f83fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(in_tick == 0);
ffffffffc02033f6:	00003697          	auipc	a3,0x3
ffffffffc02033fa:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0205ce0 <default_pmm_manager+0xc48>
ffffffffc02033fe:	00002617          	auipc	a2,0x2
ffffffffc0203402:	90260613          	addi	a2,a2,-1790 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203406:	02900593          	li	a1,41
ffffffffc020340a:	00002517          	auipc	a0,0x2
ffffffffc020340e:	71e50513          	addi	a0,a0,1822 # ffffffffc0205b28 <default_pmm_manager+0xa90>
ffffffffc0203412:	f63fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203416 <_lru_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc0203416:	03060693          	addi	a3,a2,48
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
ffffffffc020341a:	7518                	ld	a4,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc020341c:	c695                	beqz	a3,ffffffffc0203448 <_lru_map_swappable+0x32>
ffffffffc020341e:	c70d                	beqz	a4,ffffffffc0203448 <_lru_map_swappable+0x32>
    list_entry_t *top = head->next;
ffffffffc0203420:	671c                	ld	a5,8(a4)
    prev->next = next->prev = elm;
ffffffffc0203422:	e394                	sd	a3,0(a5)
ffffffffc0203424:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0203426:	fe1c                	sd	a5,56(a2)
    elm->prev = prev;
ffffffffc0203428:	fa18                	sd	a4,48(a2)
    while (top != head)
ffffffffc020342a:	00f70763          	beq	a4,a5,ffffffffc0203438 <_lru_map_swappable+0x22>
        if (entry == top)
ffffffffc020342e:	00f68763          	beq	a3,a5,ffffffffc020343c <_lru_map_swappable+0x26>
        top = top->next;
ffffffffc0203432:	679c                	ld	a5,8(a5)
    while (top != head)
ffffffffc0203434:	fef71de3          	bne	a4,a5,ffffffffc020342e <_lru_map_swappable+0x18>
}
ffffffffc0203438:	4501                	li	a0,0
ffffffffc020343a:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020343c:	6398                	ld	a4,0(a5)
ffffffffc020343e:	679c                	ld	a5,8(a5)
ffffffffc0203440:	4501                	li	a0,0
    prev->next = next;
ffffffffc0203442:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203444:	e398                	sd	a4,0(a5)
ffffffffc0203446:	8082                	ret
{
ffffffffc0203448:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc020344a:	00003697          	auipc	a3,0x3
ffffffffc020344e:	86668693          	addi	a3,a3,-1946 # ffffffffc0205cb0 <default_pmm_manager+0xc18>
ffffffffc0203452:	00002617          	auipc	a2,0x2
ffffffffc0203456:	8ae60613          	addi	a2,a2,-1874 # ffffffffc0204d00 <commands+0x870>
ffffffffc020345a:	45d1                	li	a1,20
ffffffffc020345c:	00002517          	auipc	a0,0x2
ffffffffc0203460:	6cc50513          	addi	a0,a0,1740 # ffffffffc0205b28 <default_pmm_manager+0xa90>
{
ffffffffc0203464:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203466:	f0ffc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020346a <_lru_set_unswappable>:
ffffffffc020346a:	4501                	li	a0,0
ffffffffc020346c:	8082                	ret

ffffffffc020346e <_lru_tick_event>:
ffffffffc020346e:	4501                	li	a0,0
ffffffffc0203470:	8082                	ret

ffffffffc0203472 <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203472:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203474:	00003697          	auipc	a3,0x3
ffffffffc0203478:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0205d20 <default_pmm_manager+0xc88>
ffffffffc020347c:	00002617          	auipc	a2,0x2
ffffffffc0203480:	88460613          	addi	a2,a2,-1916 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203484:	09600593          	li	a1,150
ffffffffc0203488:	00003517          	auipc	a0,0x3
ffffffffc020348c:	8b850513          	addi	a0,a0,-1864 # ffffffffc0205d40 <default_pmm_manager+0xca8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203490:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203492:	ee3fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203496 <mm_create>:
{
ffffffffc0203496:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203498:	03000513          	li	a0,48
{
ffffffffc020349c:	e022                	sd	s0,0(sp)
ffffffffc020349e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02034a0:	9eaff0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc02034a4:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc02034a6:	c115                	beqz	a0,ffffffffc02034ca <mm_create+0x34>
        if (swap_init_ok)
ffffffffc02034a8:	0000e797          	auipc	a5,0xe
ffffffffc02034ac:	fc078793          	addi	a5,a5,-64 # ffffffffc0211468 <swap_init_ok>
ffffffffc02034b0:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02034b2:	e408                	sd	a0,8(s0)
ffffffffc02034b4:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02034b6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02034ba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02034be:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc02034c2:	2781                	sext.w	a5,a5
ffffffffc02034c4:	eb81                	bnez	a5,ffffffffc02034d4 <mm_create+0x3e>
            mm->sm_priv = NULL;
ffffffffc02034c6:	02053423          	sd	zero,40(a0)
}
ffffffffc02034ca:	8522                	mv	a0,s0
ffffffffc02034cc:	60a2                	ld	ra,8(sp)
ffffffffc02034ce:	6402                	ld	s0,0(sp)
ffffffffc02034d0:	0141                	addi	sp,sp,16
ffffffffc02034d2:	8082                	ret
            swap_init_mm(mm);
ffffffffc02034d4:	9d9ff0ef          	jal	ra,ffffffffc0202eac <swap_init_mm>
}
ffffffffc02034d8:	8522                	mv	a0,s0
ffffffffc02034da:	60a2                	ld	ra,8(sp)
ffffffffc02034dc:	6402                	ld	s0,0(sp)
ffffffffc02034de:	0141                	addi	sp,sp,16
ffffffffc02034e0:	8082                	ret

ffffffffc02034e2 <vma_create>:
{
ffffffffc02034e2:	1101                	addi	sp,sp,-32
ffffffffc02034e4:	e04a                	sd	s2,0(sp)
ffffffffc02034e6:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02034e8:	03000513          	li	a0,48
{
ffffffffc02034ec:	e822                	sd	s0,16(sp)
ffffffffc02034ee:	e426                	sd	s1,8(sp)
ffffffffc02034f0:	ec06                	sd	ra,24(sp)
ffffffffc02034f2:	84ae                	mv	s1,a1
ffffffffc02034f4:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02034f6:	994ff0ef          	jal	ra,ffffffffc020268a <kmalloc>
    if (vma != NULL)
ffffffffc02034fa:	c509                	beqz	a0,ffffffffc0203504 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02034fc:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203500:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203502:	ed00                	sd	s0,24(a0)
}
ffffffffc0203504:	60e2                	ld	ra,24(sp)
ffffffffc0203506:	6442                	ld	s0,16(sp)
ffffffffc0203508:	64a2                	ld	s1,8(sp)
ffffffffc020350a:	6902                	ld	s2,0(sp)
ffffffffc020350c:	6105                	addi	sp,sp,32
ffffffffc020350e:	8082                	ret

ffffffffc0203510 <find_vma>:
    if (mm != NULL)
ffffffffc0203510:	c51d                	beqz	a0,ffffffffc020353e <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0203512:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203514:	c781                	beqz	a5,ffffffffc020351c <find_vma+0xc>
ffffffffc0203516:	6798                	ld	a4,8(a5)
ffffffffc0203518:	02e5f663          	bleu	a4,a1,ffffffffc0203544 <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc020351c:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc020351e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203520:	00f50f63          	beq	a0,a5,ffffffffc020353e <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203524:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203528:	fee5ebe3          	bltu	a1,a4,ffffffffc020351e <find_vma+0xe>
ffffffffc020352c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203530:	fee5f7e3          	bleu	a4,a1,ffffffffc020351e <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc0203534:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc0203536:	c781                	beqz	a5,ffffffffc020353e <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0203538:	e91c                	sd	a5,16(a0)
}
ffffffffc020353a:	853e                	mv	a0,a5
ffffffffc020353c:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc020353e:	4781                	li	a5,0
}
ffffffffc0203540:	853e                	mv	a0,a5
ffffffffc0203542:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203544:	6b98                	ld	a4,16(a5)
ffffffffc0203546:	fce5fbe3          	bleu	a4,a1,ffffffffc020351c <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020354a:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc020354c:	b7fd                	j	ffffffffc020353a <find_vma+0x2a>

ffffffffc020354e <insert_vma_struct>:

// insert_vma_struct -insert vma in mm's list link
// 把新的vma_struct插入到mm_struct对应的链表
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020354e:	6590                	ld	a2,8(a1)
ffffffffc0203550:	0105b803          	ld	a6,16(a1) # 1010 <BASE_ADDRESS-0xffffffffc01feff0>
{
ffffffffc0203554:	1141                	addi	sp,sp,-16
ffffffffc0203556:	e406                	sd	ra,8(sp)
ffffffffc0203558:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020355a:	01066863          	bltu	a2,a6,ffffffffc020356a <insert_vma_struct+0x1c>
ffffffffc020355e:	a8b9                	j	ffffffffc02035bc <insert_vma_struct+0x6e>
    // 保证插入后所有vma_struct按照区间左端点有序排列
    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203560:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203564:	04d66763          	bltu	a2,a3,ffffffffc02035b2 <insert_vma_struct+0x64>
ffffffffc0203568:	873e                	mv	a4,a5
ffffffffc020356a:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc020356c:	fef51ae3          	bne	a0,a5,ffffffffc0203560 <insert_vma_struct+0x12>
    // le_prev <-> now <-> le_next
    le_next = list_next(le_prev);

    /* check overlap */
    // 虚拟内存块之间不能有重叠
    if (le_prev != list)
ffffffffc0203570:	02a70463          	beq	a4,a0,ffffffffc0203598 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203574:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203578:	fe873883          	ld	a7,-24(a4)
ffffffffc020357c:	08d8f063          	bleu	a3,a7,ffffffffc02035fc <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203580:	04d66e63          	bltu	a2,a3,ffffffffc02035dc <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0203584:	00f50a63          	beq	a0,a5,ffffffffc0203598 <insert_vma_struct+0x4a>
ffffffffc0203588:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020358c:	0506e863          	bltu	a3,a6,ffffffffc02035dc <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203590:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203594:	02c6f263          	bleu	a2,a3,ffffffffc02035b8 <insert_vma_struct+0x6a>
    vma->vm_mm = mm;
    // 插入
    list_add_after(le_prev, &(vma->list_link));

    // 更新map_count
    mm->map_count++;
ffffffffc0203598:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc020359a:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020359c:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02035a0:	e390                	sd	a2,0(a5)
ffffffffc02035a2:	e710                	sd	a2,8(a4)
}
ffffffffc02035a4:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02035a6:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02035a8:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc02035aa:	2685                	addiw	a3,a3,1
ffffffffc02035ac:	d114                	sw	a3,32(a0)
}
ffffffffc02035ae:	0141                	addi	sp,sp,16
ffffffffc02035b0:	8082                	ret
    if (le_prev != list)
ffffffffc02035b2:	fca711e3          	bne	a4,a0,ffffffffc0203574 <insert_vma_struct+0x26>
ffffffffc02035b6:	bfd9                	j	ffffffffc020358c <insert_vma_struct+0x3e>
ffffffffc02035b8:	ebbff0ef          	jal	ra,ffffffffc0203472 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035bc:	00003697          	auipc	a3,0x3
ffffffffc02035c0:	81468693          	addi	a3,a3,-2028 # ffffffffc0205dd0 <default_pmm_manager+0xd38>
ffffffffc02035c4:	00001617          	auipc	a2,0x1
ffffffffc02035c8:	73c60613          	addi	a2,a2,1852 # ffffffffc0204d00 <commands+0x870>
ffffffffc02035cc:	09d00593          	li	a1,157
ffffffffc02035d0:	00002517          	auipc	a0,0x2
ffffffffc02035d4:	77050513          	addi	a0,a0,1904 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02035d8:	d9dfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02035dc:	00003697          	auipc	a3,0x3
ffffffffc02035e0:	83468693          	addi	a3,a3,-1996 # ffffffffc0205e10 <default_pmm_manager+0xd78>
ffffffffc02035e4:	00001617          	auipc	a2,0x1
ffffffffc02035e8:	71c60613          	addi	a2,a2,1820 # ffffffffc0204d00 <commands+0x870>
ffffffffc02035ec:	09500593          	li	a1,149
ffffffffc02035f0:	00002517          	auipc	a0,0x2
ffffffffc02035f4:	75050513          	addi	a0,a0,1872 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02035f8:	d7dfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02035fc:	00002697          	auipc	a3,0x2
ffffffffc0203600:	7f468693          	addi	a3,a3,2036 # ffffffffc0205df0 <default_pmm_manager+0xd58>
ffffffffc0203604:	00001617          	auipc	a2,0x1
ffffffffc0203608:	6fc60613          	addi	a2,a2,1788 # ffffffffc0204d00 <commands+0x870>
ffffffffc020360c:	09400593          	li	a1,148
ffffffffc0203610:	00002517          	auipc	a0,0x2
ffffffffc0203614:	73050513          	addi	a0,a0,1840 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203618:	d5dfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020361c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
ffffffffc020361c:	1141                	addi	sp,sp,-16
ffffffffc020361e:	e022                	sd	s0,0(sp)
ffffffffc0203620:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203622:	6508                	ld	a0,8(a0)
ffffffffc0203624:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203626:	00a40e63          	beq	s0,a0,ffffffffc0203642 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020362a:	6118                	ld	a4,0(a0)
ffffffffc020362c:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link), sizeof(struct vma_struct)); // kfree vma
ffffffffc020362e:	03000593          	li	a1,48
ffffffffc0203632:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203634:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203636:	e398                	sd	a4,0(a5)
ffffffffc0203638:	914ff0ef          	jal	ra,ffffffffc020274c <kfree>
    return listelm->next;
ffffffffc020363c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020363e:	fea416e3          	bne	s0,a0,ffffffffc020362a <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0203642:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203644:	6402                	ld	s0,0(sp)
ffffffffc0203646:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0203648:	03000593          	li	a1,48
}
ffffffffc020364c:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc020364e:	8feff06f          	j	ffffffffc020274c <kfree>

ffffffffc0203652 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203652:	715d                	addi	sp,sp,-80
ffffffffc0203654:	e486                	sd	ra,72(sp)
ffffffffc0203656:	e0a2                	sd	s0,64(sp)
ffffffffc0203658:	fc26                	sd	s1,56(sp)
ffffffffc020365a:	f84a                	sd	s2,48(sp)
ffffffffc020365c:	f052                	sd	s4,32(sp)
ffffffffc020365e:	f44e                	sd	s3,40(sp)
ffffffffc0203660:	ec56                	sd	s5,24(sp)
ffffffffc0203662:	e85a                	sd	s6,16(sp)
ffffffffc0203664:	e45e                	sd	s7,8(sp)

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203666:	8c6fe0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc020366a:	892a                	mv	s2,a0
}

static void
check_vma_struct(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020366c:	8c0fe0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203670:	8a2a                	mv	s4,a0

    // 创建mm
    struct mm_struct *mm = mm_create();
ffffffffc0203672:	e25ff0ef          	jal	ra,ffffffffc0203496 <mm_create>
    assert(mm != NULL);
ffffffffc0203676:	842a                	mv	s0,a0
ffffffffc0203678:	03200493          	li	s1,50
ffffffffc020367c:	e919                	bnez	a0,ffffffffc0203692 <vmm_init+0x40>
ffffffffc020367e:	aeed                	j	ffffffffc0203a78 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc0203680:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203682:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203684:	00053c23          	sd	zero,24(a0)
    // 1-step1倒序
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203688:	14ed                	addi	s1,s1,-5
ffffffffc020368a:	8522                	mv	a0,s0
ffffffffc020368c:	ec3ff0ef          	jal	ra,ffffffffc020354e <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203690:	c88d                	beqz	s1,ffffffffc02036c2 <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203692:	03000513          	li	a0,48
ffffffffc0203696:	ff5fe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc020369a:	85aa                	mv	a1,a0
ffffffffc020369c:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc02036a0:	f165                	bnez	a0,ffffffffc0203680 <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc02036a2:	00002697          	auipc	a3,0x2
ffffffffc02036a6:	19668693          	addi	a3,a3,406 # ffffffffc0205838 <default_pmm_manager+0x7a0>
ffffffffc02036aa:	00001617          	auipc	a2,0x1
ffffffffc02036ae:	65660613          	addi	a2,a2,1622 # ffffffffc0204d00 <commands+0x870>
ffffffffc02036b2:	0f800593          	li	a1,248
ffffffffc02036b6:	00002517          	auipc	a0,0x2
ffffffffc02036ba:	68a50513          	addi	a0,a0,1674 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02036be:	cb7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc02036c2:	03700493          	li	s1,55
    }

    // step1-step2顺序
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02036c6:	1f900993          	li	s3,505
ffffffffc02036ca:	a819                	j	ffffffffc02036e0 <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc02036cc:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02036ce:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02036d0:	00053c23          	sd	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02036d4:	0495                	addi	s1,s1,5
ffffffffc02036d6:	8522                	mv	a0,s0
ffffffffc02036d8:	e77ff0ef          	jal	ra,ffffffffc020354e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02036dc:	03348a63          	beq	s1,s3,ffffffffc0203710 <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02036e0:	03000513          	li	a0,48
ffffffffc02036e4:	fa7fe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc02036e8:	85aa                	mv	a1,a0
ffffffffc02036ea:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc02036ee:	fd79                	bnez	a0,ffffffffc02036cc <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc02036f0:	00002697          	auipc	a3,0x2
ffffffffc02036f4:	14868693          	addi	a3,a3,328 # ffffffffc0205838 <default_pmm_manager+0x7a0>
ffffffffc02036f8:	00001617          	auipc	a2,0x1
ffffffffc02036fc:	60860613          	addi	a2,a2,1544 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203700:	10000593          	li	a1,256
ffffffffc0203704:	00002517          	auipc	a0,0x2
ffffffffc0203708:	63c50513          	addi	a0,a0,1596 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc020370c:	c69fc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203710:	6418                	ld	a4,8(s0)
ffffffffc0203712:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    // 现在能够按顺序查到
    for (i = 1; i <= step2; i++)
ffffffffc0203714:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203718:	2ae40063          	beq	s0,a4,ffffffffc02039b8 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020371c:	fe873603          	ld	a2,-24(a4)
ffffffffc0203720:	ffe78693          	addi	a3,a5,-2
ffffffffc0203724:	20d61a63          	bne	a2,a3,ffffffffc0203938 <vmm_init+0x2e6>
ffffffffc0203728:	ff073683          	ld	a3,-16(a4)
ffffffffc020372c:	20d79663          	bne	a5,a3,ffffffffc0203938 <vmm_init+0x2e6>
ffffffffc0203730:	0795                	addi	a5,a5,5
ffffffffc0203732:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc0203734:	feb792e3          	bne	a5,a1,ffffffffc0203718 <vmm_init+0xc6>
ffffffffc0203738:	499d                	li	s3,7
ffffffffc020373a:	4495                	li	s1,5
        le = list_next(le);
    }

    // 也能find到
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020373c:	1f900b93          	li	s7,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203740:	85a6                	mv	a1,s1
ffffffffc0203742:	8522                	mv	a0,s0
ffffffffc0203744:	dcdff0ef          	jal	ra,ffffffffc0203510 <find_vma>
ffffffffc0203748:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc020374a:	2e050763          	beqz	a0,ffffffffc0203a38 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc020374e:	00148593          	addi	a1,s1,1
ffffffffc0203752:	8522                	mv	a0,s0
ffffffffc0203754:	dbdff0ef          	jal	ra,ffffffffc0203510 <find_vma>
ffffffffc0203758:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc020375a:	2a050f63          	beqz	a0,ffffffffc0203a18 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc020375e:	85ce                	mv	a1,s3
ffffffffc0203760:	8522                	mv	a0,s0
ffffffffc0203762:	dafff0ef          	jal	ra,ffffffffc0203510 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203766:	28051963          	bnez	a0,ffffffffc02039f8 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc020376a:	00348593          	addi	a1,s1,3
ffffffffc020376e:	8522                	mv	a0,s0
ffffffffc0203770:	da1ff0ef          	jal	ra,ffffffffc0203510 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203774:	26051263          	bnez	a0,ffffffffc02039d8 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203778:	00448593          	addi	a1,s1,4
ffffffffc020377c:	8522                	mv	a0,s0
ffffffffc020377e:	d93ff0ef          	jal	ra,ffffffffc0203510 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203782:	2c051b63          	bnez	a0,ffffffffc0203a58 <vmm_init+0x406>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203786:	008b3783          	ld	a5,8(s6)
ffffffffc020378a:	1c979763          	bne	a5,s1,ffffffffc0203958 <vmm_init+0x306>
ffffffffc020378e:	010b3783          	ld	a5,16(s6)
ffffffffc0203792:	1d379363          	bne	a5,s3,ffffffffc0203958 <vmm_init+0x306>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203796:	008ab783          	ld	a5,8(s5)
ffffffffc020379a:	1c979f63          	bne	a5,s1,ffffffffc0203978 <vmm_init+0x326>
ffffffffc020379e:	010ab783          	ld	a5,16(s5)
ffffffffc02037a2:	1d379b63          	bne	a5,s3,ffffffffc0203978 <vmm_init+0x326>
ffffffffc02037a6:	0495                	addi	s1,s1,5
ffffffffc02037a8:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02037aa:	f9749be3          	bne	s1,s7,ffffffffc0203740 <vmm_init+0xee>
ffffffffc02037ae:	4491                	li	s1,4
    }

    // 由于之前都是5i，所以小于5的应该都查不到
    for (i = 4; i >= 0; i--)
ffffffffc02037b0:	59fd                	li	s3,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02037b2:	85a6                	mv	a1,s1
ffffffffc02037b4:	8522                	mv	a0,s0
ffffffffc02037b6:	d5bff0ef          	jal	ra,ffffffffc0203510 <find_vma>
ffffffffc02037ba:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc02037be:	c90d                	beqz	a0,ffffffffc02037f0 <vmm_init+0x19e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02037c0:	6914                	ld	a3,16(a0)
ffffffffc02037c2:	6510                	ld	a2,8(a0)
ffffffffc02037c4:	00002517          	auipc	a0,0x2
ffffffffc02037c8:	76c50513          	addi	a0,a0,1900 # ffffffffc0205f30 <default_pmm_manager+0xe98>
ffffffffc02037cc:	8f3fc0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02037d0:	00002697          	auipc	a3,0x2
ffffffffc02037d4:	78868693          	addi	a3,a3,1928 # ffffffffc0205f58 <default_pmm_manager+0xec0>
ffffffffc02037d8:	00001617          	auipc	a2,0x1
ffffffffc02037dc:	52860613          	addi	a2,a2,1320 # ffffffffc0204d00 <commands+0x870>
ffffffffc02037e0:	12900593          	li	a1,297
ffffffffc02037e4:	00002517          	auipc	a0,0x2
ffffffffc02037e8:	55c50513          	addi	a0,a0,1372 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02037ec:	b89fc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02037f0:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc02037f2:	fd3490e3          	bne	s1,s3,ffffffffc02037b2 <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc02037f6:	8522                	mv	a0,s0
ffffffffc02037f8:	e25ff0ef          	jal	ra,ffffffffc020361c <mm_destroy>

    // 结束
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02037fc:	f31fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203800:	28aa1c63          	bne	s4,a0,ffffffffc0203a98 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203804:	00002517          	auipc	a0,0x2
ffffffffc0203808:	79450513          	addi	a0,a0,1940 # ffffffffc0205f98 <default_pmm_manager+0xf00>
ffffffffc020380c:	8b3fc0ef          	jal	ra,ffffffffc02000be <cprintf>
// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    // char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203810:	f1dfd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203814:	89aa                	mv	s3,a0

    // 创建mm
    check_mm_struct = mm_create();
ffffffffc0203816:	c81ff0ef          	jal	ra,ffffffffc0203496 <mm_create>
ffffffffc020381a:	0000e797          	auipc	a5,0xe
ffffffffc020381e:	d6a7bb23          	sd	a0,-650(a5) # ffffffffc0211590 <check_mm_struct>
ffffffffc0203822:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc0203824:	2a050a63          	beqz	a0,ffffffffc0203ad8 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir; // boot_pgdir在pmm.c pmm_init()中初始化为boot_page_table_sv39（entry.S中定义）
ffffffffc0203828:	0000e797          	auipc	a5,0xe
ffffffffc020382c:	c2878793          	addi	a5,a5,-984 # ffffffffc0211450 <boot_pgdir>
ffffffffc0203830:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0203832:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir; // boot_pgdir在pmm.c pmm_init()中初始化为boot_page_table_sv39（entry.S中定义）
ffffffffc0203834:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0203836:	32079d63          	bnez	a5,ffffffffc0203b70 <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020383a:	03000513          	li	a0,48
ffffffffc020383e:	e4dfe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc0203842:	8a2a                	mv	s4,a0
    if (vma != NULL)
ffffffffc0203844:	14050a63          	beqz	a0,ffffffffc0203998 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0203848:	002007b7          	lui	a5,0x200
ffffffffc020384c:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0203850:	4789                	li	a5,2
    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    // vma插入mm
    insert_vma_struct(mm, vma);
ffffffffc0203852:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0203854:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0203858:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc020385a:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc020385e:	cf1ff0ef          	jal	ra,ffffffffc020354e <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203862:	10000593          	li	a1,256
ffffffffc0203866:	8522                	mv	a0,s0
ffffffffc0203868:	ca9ff0ef          	jal	ra,ffffffffc0203510 <find_vma>
ffffffffc020386c:	10000793          	li	a5,256

    // 将100个字节写入地址0x100处，又挨个读出
    int i, sum = 0;
    for (i = 0; i < 100; i++)
ffffffffc0203870:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203874:	2aaa1263          	bne	s4,a0,ffffffffc0203b18 <vmm_init+0x4c6>
    {
        // ! 第一次到这里的时候产生缺页异常
        *(char *)(addr + i) = i;
ffffffffc0203878:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc020387c:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc020387e:	fee79de3          	bne	a5,a4,ffffffffc0203878 <vmm_init+0x226>
        sum += i;
ffffffffc0203882:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc0203884:	10000793          	li	a5,256
        sum += i;
ffffffffc0203888:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i++)
ffffffffc020388c:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc0203890:	0007c683          	lbu	a3,0(a5)
ffffffffc0203894:	0785                	addi	a5,a5,1
ffffffffc0203896:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc0203898:	fec79ce3          	bne	a5,a2,ffffffffc0203890 <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc020389c:	2a071a63          	bnez	a4,ffffffffc0203b50 <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02038a0:	4581                	li	a1,0
ffffffffc02038a2:	8526                	mv	a0,s1
ffffffffc02038a4:	92efe0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02038a8:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage)
ffffffffc02038aa:	0000e717          	auipc	a4,0xe
ffffffffc02038ae:	bae70713          	addi	a4,a4,-1106 # ffffffffc0211458 <npage>
ffffffffc02038b2:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc02038b4:	078a                	slli	a5,a5,0x2
ffffffffc02038b6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02038b8:	28e7f063          	bleu	a4,a5,ffffffffc0203b38 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase]; // 把pages指针当作数组使用
ffffffffc02038bc:	00003717          	auipc	a4,0x3
ffffffffc02038c0:	a1c70713          	addi	a4,a4,-1508 # ffffffffc02062d8 <nbase>
ffffffffc02038c4:	6318                	ld	a4,0(a4)
ffffffffc02038c6:	0000e697          	auipc	a3,0xe
ffffffffc02038ca:	be268693          	addi	a3,a3,-1054 # ffffffffc02114a8 <pages>
ffffffffc02038ce:	6288                	ld	a0,0(a3)
ffffffffc02038d0:	8f99                	sub	a5,a5,a4
ffffffffc02038d2:	00379713          	slli	a4,a5,0x3
ffffffffc02038d6:	97ba                	add	a5,a5,a4
ffffffffc02038d8:	078e                	slli	a5,a5,0x3

    // 把这一个pde对应的页释放掉
    free_page(pde2page(pgdir[0]));
ffffffffc02038da:	953e                	add	a0,a0,a5
ffffffffc02038dc:	4585                	li	a1,1
ffffffffc02038de:	e09fd0ef          	jal	ra,ffffffffc02016e6 <free_pages>

    pgdir[0] = 0;
ffffffffc02038e2:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02038e6:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02038e8:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02038ec:	d31ff0ef          	jal	ra,ffffffffc020361c <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--; // szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc02038f0:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc02038f2:	0000e797          	auipc	a5,0xe
ffffffffc02038f6:	c807bf23          	sd	zero,-866(a5) # ffffffffc0211590 <check_mm_struct>

    // 刚刚会多分配一个二级页表，所以这里空闲页数变少了1页
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02038fa:	e33fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc02038fe:	1aa99d63          	bne	s3,a0,ffffffffc0203ab8 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203902:	00002517          	auipc	a0,0x2
ffffffffc0203906:	6fe50513          	addi	a0,a0,1790 # ffffffffc0206000 <default_pmm_manager+0xf68>
ffffffffc020390a:	fb4fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020390e:	e1ffd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
    nr_free_pages_store--; // szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0203912:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203914:	1ea91263          	bne	s2,a0,ffffffffc0203af8 <vmm_init+0x4a6>
}
ffffffffc0203918:	6406                	ld	s0,64(sp)
ffffffffc020391a:	60a6                	ld	ra,72(sp)
ffffffffc020391c:	74e2                	ld	s1,56(sp)
ffffffffc020391e:	7942                	ld	s2,48(sp)
ffffffffc0203920:	79a2                	ld	s3,40(sp)
ffffffffc0203922:	7a02                	ld	s4,32(sp)
ffffffffc0203924:	6ae2                	ld	s5,24(sp)
ffffffffc0203926:	6b42                	ld	s6,16(sp)
ffffffffc0203928:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020392a:	00002517          	auipc	a0,0x2
ffffffffc020392e:	6f650513          	addi	a0,a0,1782 # ffffffffc0206020 <default_pmm_manager+0xf88>
}
ffffffffc0203932:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203934:	f8afc06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203938:	00002697          	auipc	a3,0x2
ffffffffc020393c:	51068693          	addi	a3,a3,1296 # ffffffffc0205e48 <default_pmm_manager+0xdb0>
ffffffffc0203940:	00001617          	auipc	a2,0x1
ffffffffc0203944:	3c060613          	addi	a2,a2,960 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203948:	10b00593          	li	a1,267
ffffffffc020394c:	00002517          	auipc	a0,0x2
ffffffffc0203950:	3f450513          	addi	a0,a0,1012 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203954:	a21fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203958:	00002697          	auipc	a3,0x2
ffffffffc020395c:	57868693          	addi	a3,a3,1400 # ffffffffc0205ed0 <default_pmm_manager+0xe38>
ffffffffc0203960:	00001617          	auipc	a2,0x1
ffffffffc0203964:	3a060613          	addi	a2,a2,928 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203968:	11d00593          	li	a1,285
ffffffffc020396c:	00002517          	auipc	a0,0x2
ffffffffc0203970:	3d450513          	addi	a0,a0,980 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203974:	a01fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203978:	00002697          	auipc	a3,0x2
ffffffffc020397c:	58868693          	addi	a3,a3,1416 # ffffffffc0205f00 <default_pmm_manager+0xe68>
ffffffffc0203980:	00001617          	auipc	a2,0x1
ffffffffc0203984:	38060613          	addi	a2,a2,896 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203988:	11e00593          	li	a1,286
ffffffffc020398c:	00002517          	auipc	a0,0x2
ffffffffc0203990:	3b450513          	addi	a0,a0,948 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203994:	9e1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(vma != NULL);
ffffffffc0203998:	00002697          	auipc	a3,0x2
ffffffffc020399c:	ea068693          	addi	a3,a3,-352 # ffffffffc0205838 <default_pmm_manager+0x7a0>
ffffffffc02039a0:	00001617          	auipc	a2,0x1
ffffffffc02039a4:	36060613          	addi	a2,a2,864 # ffffffffc0204d00 <commands+0x870>
ffffffffc02039a8:	14800593          	li	a1,328
ffffffffc02039ac:	00002517          	auipc	a0,0x2
ffffffffc02039b0:	39450513          	addi	a0,a0,916 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02039b4:	9c1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02039b8:	00002697          	auipc	a3,0x2
ffffffffc02039bc:	47868693          	addi	a3,a3,1144 # ffffffffc0205e30 <default_pmm_manager+0xd98>
ffffffffc02039c0:	00001617          	auipc	a2,0x1
ffffffffc02039c4:	34060613          	addi	a2,a2,832 # ffffffffc0204d00 <commands+0x870>
ffffffffc02039c8:	10900593          	li	a1,265
ffffffffc02039cc:	00002517          	auipc	a0,0x2
ffffffffc02039d0:	37450513          	addi	a0,a0,884 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02039d4:	9a1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma4 == NULL);
ffffffffc02039d8:	00002697          	auipc	a3,0x2
ffffffffc02039dc:	4d868693          	addi	a3,a3,1240 # ffffffffc0205eb0 <default_pmm_manager+0xe18>
ffffffffc02039e0:	00001617          	auipc	a2,0x1
ffffffffc02039e4:	32060613          	addi	a2,a2,800 # ffffffffc0204d00 <commands+0x870>
ffffffffc02039e8:	11900593          	li	a1,281
ffffffffc02039ec:	00002517          	auipc	a0,0x2
ffffffffc02039f0:	35450513          	addi	a0,a0,852 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc02039f4:	981fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma3 == NULL);
ffffffffc02039f8:	00002697          	auipc	a3,0x2
ffffffffc02039fc:	4a868693          	addi	a3,a3,1192 # ffffffffc0205ea0 <default_pmm_manager+0xe08>
ffffffffc0203a00:	00001617          	auipc	a2,0x1
ffffffffc0203a04:	30060613          	addi	a2,a2,768 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203a08:	11700593          	li	a1,279
ffffffffc0203a0c:	00002517          	auipc	a0,0x2
ffffffffc0203a10:	33450513          	addi	a0,a0,820 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203a14:	961fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2 != NULL);
ffffffffc0203a18:	00002697          	auipc	a3,0x2
ffffffffc0203a1c:	47868693          	addi	a3,a3,1144 # ffffffffc0205e90 <default_pmm_manager+0xdf8>
ffffffffc0203a20:	00001617          	auipc	a2,0x1
ffffffffc0203a24:	2e060613          	addi	a2,a2,736 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203a28:	11500593          	li	a1,277
ffffffffc0203a2c:	00002517          	auipc	a0,0x2
ffffffffc0203a30:	31450513          	addi	a0,a0,788 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203a34:	941fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1 != NULL);
ffffffffc0203a38:	00002697          	auipc	a3,0x2
ffffffffc0203a3c:	44868693          	addi	a3,a3,1096 # ffffffffc0205e80 <default_pmm_manager+0xde8>
ffffffffc0203a40:	00001617          	auipc	a2,0x1
ffffffffc0203a44:	2c060613          	addi	a2,a2,704 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203a48:	11300593          	li	a1,275
ffffffffc0203a4c:	00002517          	auipc	a0,0x2
ffffffffc0203a50:	2f450513          	addi	a0,a0,756 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203a54:	921fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma5 == NULL);
ffffffffc0203a58:	00002697          	auipc	a3,0x2
ffffffffc0203a5c:	46868693          	addi	a3,a3,1128 # ffffffffc0205ec0 <default_pmm_manager+0xe28>
ffffffffc0203a60:	00001617          	auipc	a2,0x1
ffffffffc0203a64:	2a060613          	addi	a2,a2,672 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203a68:	11b00593          	li	a1,283
ffffffffc0203a6c:	00002517          	auipc	a0,0x2
ffffffffc0203a70:	2d450513          	addi	a0,a0,724 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203a74:	901fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(mm != NULL);
ffffffffc0203a78:	00002697          	auipc	a3,0x2
ffffffffc0203a7c:	d8868693          	addi	a3,a3,-632 # ffffffffc0205800 <default_pmm_manager+0x768>
ffffffffc0203a80:	00001617          	auipc	a2,0x1
ffffffffc0203a84:	28060613          	addi	a2,a2,640 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203a88:	0ee00593          	li	a1,238
ffffffffc0203a8c:	00002517          	auipc	a0,0x2
ffffffffc0203a90:	2b450513          	addi	a0,a0,692 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203a94:	8e1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a98:	00002697          	auipc	a3,0x2
ffffffffc0203a9c:	4d868693          	addi	a3,a3,1240 # ffffffffc0205f70 <default_pmm_manager+0xed8>
ffffffffc0203aa0:	00001617          	auipc	a2,0x1
ffffffffc0203aa4:	26060613          	addi	a2,a2,608 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203aa8:	12f00593          	li	a1,303
ffffffffc0203aac:	00002517          	auipc	a0,0x2
ffffffffc0203ab0:	29450513          	addi	a0,a0,660 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203ab4:	8c1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203ab8:	00002697          	auipc	a3,0x2
ffffffffc0203abc:	4b868693          	addi	a3,a3,1208 # ffffffffc0205f70 <default_pmm_manager+0xed8>
ffffffffc0203ac0:	00001617          	auipc	a2,0x1
ffffffffc0203ac4:	24060613          	addi	a2,a2,576 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203ac8:	16c00593          	li	a1,364
ffffffffc0203acc:	00002517          	auipc	a0,0x2
ffffffffc0203ad0:	27450513          	addi	a0,a0,628 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203ad4:	8a1fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203ad8:	00002697          	auipc	a3,0x2
ffffffffc0203adc:	4e068693          	addi	a3,a3,1248 # ffffffffc0205fb8 <default_pmm_manager+0xf20>
ffffffffc0203ae0:	00001617          	auipc	a2,0x1
ffffffffc0203ae4:	22060613          	addi	a2,a2,544 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203ae8:	14000593          	li	a1,320
ffffffffc0203aec:	00002517          	auipc	a0,0x2
ffffffffc0203af0:	25450513          	addi	a0,a0,596 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203af4:	881fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203af8:	00002697          	auipc	a3,0x2
ffffffffc0203afc:	47868693          	addi	a3,a3,1144 # ffffffffc0205f70 <default_pmm_manager+0xed8>
ffffffffc0203b00:	00001617          	auipc	a2,0x1
ffffffffc0203b04:	20060613          	addi	a2,a2,512 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203b08:	0e200593          	li	a1,226
ffffffffc0203b0c:	00002517          	auipc	a0,0x2
ffffffffc0203b10:	23450513          	addi	a0,a0,564 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203b14:	861fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203b18:	00002697          	auipc	a3,0x2
ffffffffc0203b1c:	4b868693          	addi	a3,a3,1208 # ffffffffc0205fd0 <default_pmm_manager+0xf38>
ffffffffc0203b20:	00001617          	auipc	a2,0x1
ffffffffc0203b24:	1e060613          	addi	a2,a2,480 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203b28:	14e00593          	li	a1,334
ffffffffc0203b2c:	00002517          	auipc	a0,0x2
ffffffffc0203b30:	21450513          	addi	a0,a0,532 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203b34:	841fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203b38:	00001617          	auipc	a2,0x1
ffffffffc0203b3c:	62860613          	addi	a2,a2,1576 # ffffffffc0205160 <default_pmm_manager+0xc8>
ffffffffc0203b40:	07b00593          	li	a1,123
ffffffffc0203b44:	00001517          	auipc	a0,0x1
ffffffffc0203b48:	63c50513          	addi	a0,a0,1596 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0203b4c:	829fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(sum == 0);
ffffffffc0203b50:	00002697          	auipc	a3,0x2
ffffffffc0203b54:	4a068693          	addi	a3,a3,1184 # ffffffffc0205ff0 <default_pmm_manager+0xf58>
ffffffffc0203b58:	00001617          	auipc	a2,0x1
ffffffffc0203b5c:	1a860613          	addi	a2,a2,424 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203b60:	15c00593          	li	a1,348
ffffffffc0203b64:	00002517          	auipc	a0,0x2
ffffffffc0203b68:	1dc50513          	addi	a0,a0,476 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203b6c:	809fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203b70:	00002697          	auipc	a3,0x2
ffffffffc0203b74:	cb868693          	addi	a3,a3,-840 # ffffffffc0205828 <default_pmm_manager+0x790>
ffffffffc0203b78:	00001617          	auipc	a2,0x1
ffffffffc0203b7c:	18860613          	addi	a2,a2,392 # ffffffffc0204d00 <commands+0x870>
ffffffffc0203b80:	14300593          	li	a1,323
ffffffffc0203b84:	00002517          	auipc	a0,0x2
ffffffffc0203b88:	1bc50513          	addi	a0,a0,444 # ffffffffc0205d40 <default_pmm_manager+0xca8>
ffffffffc0203b8c:	fe8fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203b90 <do_pgfault>:
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
// 处理addr地址上的缺页异常
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
ffffffffc0203b90:	7179                	addi	sp,sp,-48
    // 1. 首先声明一个整数变量ret并初始化为-E_INVAL（错误代码）
    int ret = -E_INVAL;
    // 2. 调用find_vma函数在给定的mm_struct中查找包含给定虚拟地址addr的vma（虚拟内存区域）
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203b92:	85b2                	mv	a1,a2
{
ffffffffc0203b94:	f022                	sd	s0,32(sp)
ffffffffc0203b96:	ec26                	sd	s1,24(sp)
ffffffffc0203b98:	f406                	sd	ra,40(sp)
ffffffffc0203b9a:	e84a                	sd	s2,16(sp)
ffffffffc0203b9c:	8432                	mv	s0,a2
ffffffffc0203b9e:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203ba0:	971ff0ef          	jal	ra,ffffffffc0203510 <find_vma>

    // 3. 增加页面错误计数器pgfault_num
    pgfault_num++;
ffffffffc0203ba4:	0000e797          	auipc	a5,0xe
ffffffffc0203ba8:	8c878793          	addi	a5,a5,-1848 # ffffffffc021146c <pgfault_num>
ffffffffc0203bac:	439c                	lw	a5,0(a5)
ffffffffc0203bae:	2785                	addiw	a5,a5,1
ffffffffc0203bb0:	0000e717          	auipc	a4,0xe
ffffffffc0203bb4:	8af72e23          	sw	a5,-1860(a4) # ffffffffc021146c <pgfault_num>
    // 4. 如果找不到包含给定地址的vma，或者找到的vma的起始地址大于给定地址（不在范围内），则打印错误信息并跳转到标签failed
    if (vma == NULL || vma->vm_start > addr)
ffffffffc0203bb8:	c549                	beqz	a0,ffffffffc0203c42 <do_pgfault+0xb2>
ffffffffc0203bba:	651c                	ld	a5,8(a0)
ffffffffc0203bbc:	08f46363          	bltu	s0,a5,ffffffffc0203c42 <do_pgfault+0xb2>
     * THEN
     *    continue process
     */
    // 5. 根据vma的属性确定要设置的页表项权限perm。如果vma的vm_flags中包含VM_WRITE标志，则设置写权限（PTE_W）
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE)
ffffffffc0203bc0:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0203bc2:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE)
ffffffffc0203bc4:	8b89                	andi	a5,a5,2
ffffffffc0203bc6:	efa9                	bnez	a5,ffffffffc0203c20 <do_pgfault+0x90>
    {
        perm |= (PTE_R | PTE_W);
    }
    // 6. 使用页面大小（PGSIZE）对齐给定地址
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203bc8:	767d                	lui	a2,0xfffff
     * VARIABLES:
     *   mm->pgdir : the PDT of these vma
     *
     */

    ptep = get_pte(mm->pgdir, addr, 1); //(1) try to find a pte, if pte's
ffffffffc0203bca:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203bcc:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1); //(1) try to find a pte, if pte's
ffffffffc0203bce:	85a2                	mv	a1,s0
ffffffffc0203bd0:	4605                	li	a2,1
ffffffffc0203bd2:	b9bfd0ef          	jal	ra,ffffffffc020176c <get_pte>
                                        // PT(Page Table) isn't existed, then
                                        // create a PT.
    // 9. 如果获取到的页表项的值为0，表示该页表项不存在，需要分配一个物理页面，并建立页表项与线性地址之间的映射关系
    if (*ptep == 0)
ffffffffc0203bd6:	610c                	ld	a1,0(a0)
ffffffffc0203bd8:	c5b1                	beqz	a1,ffffffffc0203c24 <do_pgfault+0x94>
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        // 11. 如果交换管理器已初始化（swap_init_ok为真），则调用swap_in函数从磁盘中加载数据到内存中的页面，并将页面插入到页表中
        if (swap_init_ok)
ffffffffc0203bda:	0000e797          	auipc	a5,0xe
ffffffffc0203bde:	88e78793          	addi	a5,a5,-1906 # ffffffffc0211468 <swap_init_ok>
ffffffffc0203be2:	439c                	lw	a5,0(a5)
ffffffffc0203be4:	2781                	sext.w	a5,a5
ffffffffc0203be6:	c7bd                	beqz	a5,ffffffffc0203c54 <do_pgfault+0xc4>
        {
            struct Page *page = NULL;
            // 在swap_in()函数执行完之后，page保存换入的物理页面。
            // swap_in()函数里面可能把内存里原有的页面换出去
            swap_in(mm, addr, &page);                 //(1）According to the mm AND addr, try
ffffffffc0203be8:	85a2                	mv	a1,s0
ffffffffc0203bea:	0030                	addi	a2,sp,8
ffffffffc0203bec:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0203bee:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);                 //(1）According to the mm AND addr, try
ffffffffc0203bf0:	bf0ff0ef          	jal	ra,ffffffffc0202fe0 <swap_in>
                                                      // to load the content of right disk page
                                                      // into the memory which page managed.
            page_insert(mm->pgdir, page, addr, perm); // 更新页表，插入新的页表项
ffffffffc0203bf4:	65a2                	ld	a1,8(sp)
ffffffffc0203bf6:	6c88                	ld	a0,24(s1)
ffffffffc0203bf8:	86ca                	mv	a3,s2
ffffffffc0203bfa:	8622                	mv	a2,s0
ffffffffc0203bfc:	e49fd0ef          	jal	ra,ffffffffc0201a44 <page_insert>
            //(2) According to the mm, addr AND page,
            // setup the map of phy addr <---> virtual addr
            swap_map_swappable(mm, addr, page, 1); //(3) make the page swappable.
ffffffffc0203c00:	6622                	ld	a2,8(sp)
ffffffffc0203c02:	4685                	li	a3,1
ffffffffc0203c04:	85a2                	mv	a1,s0
ffffffffc0203c06:	8526                	mv	a0,s1
ffffffffc0203c08:	ab4ff0ef          	jal	ra,ffffffffc0202ebc <swap_map_swappable>
            // 标记这个页面将来是可以再换出的
            page->pra_vaddr = addr;
ffffffffc0203c0c:	6722                	ld	a4,8(sp)
            goto failed;
        }
    }

    // 13. 将返回值ret设置为0，表示处理页面错误成功
    ret = 0;
ffffffffc0203c0e:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc0203c10:	e320                	sd	s0,64(a4)
failed:
    return ret;
}
ffffffffc0203c12:	70a2                	ld	ra,40(sp)
ffffffffc0203c14:	7402                	ld	s0,32(sp)
ffffffffc0203c16:	64e2                	ld	s1,24(sp)
ffffffffc0203c18:	6942                	ld	s2,16(sp)
ffffffffc0203c1a:	853e                	mv	a0,a5
ffffffffc0203c1c:	6145                	addi	sp,sp,48
ffffffffc0203c1e:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0203c20:	4959                	li	s2,22
ffffffffc0203c22:	b75d                	j	ffffffffc0203bc8 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0203c24:	6c88                	ld	a0,24(s1)
ffffffffc0203c26:	864a                	mv	a2,s2
ffffffffc0203c28:	85a2                	mv	a1,s0
ffffffffc0203c2a:	9cffe0ef          	jal	ra,ffffffffc02025f8 <pgdir_alloc_page>
    ret = 0;
ffffffffc0203c2e:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
ffffffffc0203c30:	f16d                	bnez	a0,ffffffffc0203c12 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203c32:	00002517          	auipc	a0,0x2
ffffffffc0203c36:	14e50513          	addi	a0,a0,334 # ffffffffc0205d80 <default_pmm_manager+0xce8>
ffffffffc0203c3a:	c84fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203c3e:	57f1                	li	a5,-4
            goto failed;
ffffffffc0203c40:	bfc9                	j	ffffffffc0203c12 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203c42:	85a2                	mv	a1,s0
ffffffffc0203c44:	00002517          	auipc	a0,0x2
ffffffffc0203c48:	10c50513          	addi	a0,a0,268 # ffffffffc0205d50 <default_pmm_manager+0xcb8>
ffffffffc0203c4c:	c72fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc0203c50:	57f5                	li	a5,-3
        goto failed;
ffffffffc0203c52:	b7c1                	j	ffffffffc0203c12 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203c54:	00002517          	auipc	a0,0x2
ffffffffc0203c58:	15450513          	addi	a0,a0,340 # ffffffffc0205da8 <default_pmm_manager+0xd10>
ffffffffc0203c5c:	c62fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203c60:	57f1                	li	a5,-4
            goto failed;
ffffffffc0203c62:	bf45                	j	ffffffffc0203c12 <do_pgfault+0x82>

ffffffffc0203c64 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void swapfs_init(void)
{                                            // 做一些检查
ffffffffc0203c64:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0); // 静态断言是在编译时进行的断言检查
    if (!ide_device_valid(SWAP_DEV_NO))      // 检查交换设备的有效性
ffffffffc0203c66:	4505                	li	a0,1
{                                            // 做一些检查
ffffffffc0203c68:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO))      // 检查交换设备的有效性
ffffffffc0203c6a:	835fc0ef          	jal	ra,ffffffffc020049e <ide_device_valid>
ffffffffc0203c6e:	cd01                	beqz	a0,ffffffffc0203c86 <swapfs_init+0x22>
    {
        panic("swap fs isn't available.\n");
    }
    // swap.c/swap.h里的全局变量
    // 交换分区的最大偏移量，是常量
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c70:	4505                	li	a0,1
ffffffffc0203c72:	833fc0ef          	jal	ra,ffffffffc02004a4 <ide_device_size>
}
ffffffffc0203c76:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c78:	810d                	srli	a0,a0,0x3
ffffffffc0203c7a:	0000e797          	auipc	a5,0xe
ffffffffc0203c7e:	8aa7bf23          	sd	a0,-1858(a5) # ffffffffc0211538 <max_swap_offset>
}
ffffffffc0203c82:	0141                	addi	sp,sp,16
ffffffffc0203c84:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203c86:	00002617          	auipc	a2,0x2
ffffffffc0203c8a:	3b260613          	addi	a2,a2,946 # ffffffffc0206038 <default_pmm_manager+0xfa0>
ffffffffc0203c8e:	45b9                	li	a1,14
ffffffffc0203c90:	00002517          	auipc	a0,0x2
ffffffffc0203c94:	3c850513          	addi	a0,a0,968 # ffffffffc0206058 <default_pmm_manager+0xfc0>
ffffffffc0203c98:	edcfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203c9c <swapfs_read>:

int swapfs_read(swap_entry_t entry, struct Page *page)
{
ffffffffc0203c9c:	1141                	addi	sp,sp,-16
ffffffffc0203c9e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203ca0:	00855793          	srli	a5,a0,0x8
ffffffffc0203ca4:	c7b5                	beqz	a5,ffffffffc0203d10 <swapfs_read+0x74>
ffffffffc0203ca6:	0000e717          	auipc	a4,0xe
ffffffffc0203caa:	89270713          	addi	a4,a4,-1902 # ffffffffc0211538 <max_swap_offset>
ffffffffc0203cae:	6318                	ld	a4,0(a4)
ffffffffc0203cb0:	06e7f063          	bleu	a4,a5,ffffffffc0203d10 <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cb4:	0000d717          	auipc	a4,0xd
ffffffffc0203cb8:	7f470713          	addi	a4,a4,2036 # ffffffffc02114a8 <pages>
ffffffffc0203cbc:	6310                	ld	a2,0(a4)
ffffffffc0203cbe:	00001717          	auipc	a4,0x1
ffffffffc0203cc2:	02a70713          	addi	a4,a4,42 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0203cc6:	00002697          	auipc	a3,0x2
ffffffffc0203cca:	61268693          	addi	a3,a3,1554 # ffffffffc02062d8 <nbase>
ffffffffc0203cce:	40c58633          	sub	a2,a1,a2
ffffffffc0203cd2:	630c                	ld	a1,0(a4)
ffffffffc0203cd4:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cd6:	0000d717          	auipc	a4,0xd
ffffffffc0203cda:	78270713          	addi	a4,a4,1922 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cde:	02b60633          	mul	a2,a2,a1
ffffffffc0203ce2:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203ce6:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203ce8:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cea:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cec:	57fd                	li	a5,-1
ffffffffc0203cee:	83b1                	srli	a5,a5,0xc
ffffffffc0203cf0:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203cf2:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cf4:	02e7fa63          	bleu	a4,a5,ffffffffc0203d28 <swapfs_read+0x8c>
ffffffffc0203cf8:	0000d797          	auipc	a5,0xd
ffffffffc0203cfc:	7a078793          	addi	a5,a5,1952 # ffffffffc0211498 <va_pa_offset>
ffffffffc0203d00:	639c                	ld	a5,0(a5)
}
ffffffffc0203d02:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d04:	46a1                	li	a3,8
ffffffffc0203d06:	963e                	add	a2,a2,a5
ffffffffc0203d08:	4505                	li	a0,1
}
ffffffffc0203d0a:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d0c:	f9efc06f          	j	ffffffffc02004aa <ide_read_secs>
ffffffffc0203d10:	86aa                	mv	a3,a0
ffffffffc0203d12:	00002617          	auipc	a2,0x2
ffffffffc0203d16:	35e60613          	addi	a2,a2,862 # ffffffffc0206070 <default_pmm_manager+0xfd8>
ffffffffc0203d1a:	45dd                	li	a1,23
ffffffffc0203d1c:	00002517          	auipc	a0,0x2
ffffffffc0203d20:	33c50513          	addi	a0,a0,828 # ffffffffc0206058 <default_pmm_manager+0xfc0>
ffffffffc0203d24:	e50fc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203d28:	86b2                	mv	a3,a2
ffffffffc0203d2a:	08000593          	li	a1,128
ffffffffc0203d2e:	00001617          	auipc	a2,0x1
ffffffffc0203d32:	3ba60613          	addi	a2,a2,954 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0203d36:	00001517          	auipc	a0,0x1
ffffffffc0203d3a:	44a50513          	addi	a0,a0,1098 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0203d3e:	e36fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203d42 <swapfs_write>:

int swapfs_write(swap_entry_t entry, struct Page *page)
{
ffffffffc0203d42:	1141                	addi	sp,sp,-16
ffffffffc0203d44:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d46:	00855793          	srli	a5,a0,0x8
ffffffffc0203d4a:	c7b5                	beqz	a5,ffffffffc0203db6 <swapfs_write+0x74>
ffffffffc0203d4c:	0000d717          	auipc	a4,0xd
ffffffffc0203d50:	7ec70713          	addi	a4,a4,2028 # ffffffffc0211538 <max_swap_offset>
ffffffffc0203d54:	6318                	ld	a4,0(a4)
ffffffffc0203d56:	06e7f063          	bleu	a4,a5,ffffffffc0203db6 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d5a:	0000d717          	auipc	a4,0xd
ffffffffc0203d5e:	74e70713          	addi	a4,a4,1870 # ffffffffc02114a8 <pages>
ffffffffc0203d62:	6310                	ld	a2,0(a4)
ffffffffc0203d64:	00001717          	auipc	a4,0x1
ffffffffc0203d68:	f8470713          	addi	a4,a4,-124 # ffffffffc0204ce8 <commands+0x858>
ffffffffc0203d6c:	00002697          	auipc	a3,0x2
ffffffffc0203d70:	56c68693          	addi	a3,a3,1388 # ffffffffc02062d8 <nbase>
ffffffffc0203d74:	40c58633          	sub	a2,a1,a2
ffffffffc0203d78:	630c                	ld	a1,0(a4)
ffffffffc0203d7a:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d7c:	0000d717          	auipc	a4,0xd
ffffffffc0203d80:	6dc70713          	addi	a4,a4,1756 # ffffffffc0211458 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d84:	02b60633          	mul	a2,a2,a1
ffffffffc0203d88:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d8c:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d8e:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d90:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d92:	57fd                	li	a5,-1
ffffffffc0203d94:	83b1                	srli	a5,a5,0xc
ffffffffc0203d96:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d98:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d9a:	02e7fa63          	bleu	a4,a5,ffffffffc0203dce <swapfs_write+0x8c>
ffffffffc0203d9e:	0000d797          	auipc	a5,0xd
ffffffffc0203da2:	6fa78793          	addi	a5,a5,1786 # ffffffffc0211498 <va_pa_offset>
ffffffffc0203da6:	639c                	ld	a5,0(a5)
}
ffffffffc0203da8:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203daa:	46a1                	li	a3,8
ffffffffc0203dac:	963e                	add	a2,a2,a5
ffffffffc0203dae:	4505                	li	a0,1
}
ffffffffc0203db0:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203db2:	f1cfc06f          	j	ffffffffc02004ce <ide_write_secs>
ffffffffc0203db6:	86aa                	mv	a3,a0
ffffffffc0203db8:	00002617          	auipc	a2,0x2
ffffffffc0203dbc:	2b860613          	addi	a2,a2,696 # ffffffffc0206070 <default_pmm_manager+0xfd8>
ffffffffc0203dc0:	45f1                	li	a1,28
ffffffffc0203dc2:	00002517          	auipc	a0,0x2
ffffffffc0203dc6:	29650513          	addi	a0,a0,662 # ffffffffc0206058 <default_pmm_manager+0xfc0>
ffffffffc0203dca:	daafc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203dce:	86b2                	mv	a3,a2
ffffffffc0203dd0:	08000593          	li	a1,128
ffffffffc0203dd4:	00001617          	auipc	a2,0x1
ffffffffc0203dd8:	31460613          	addi	a2,a2,788 # ffffffffc02050e8 <default_pmm_manager+0x50>
ffffffffc0203ddc:	00001517          	auipc	a0,0x1
ffffffffc0203de0:	3a450513          	addi	a0,a0,932 # ffffffffc0205180 <default_pmm_manager+0xe8>
ffffffffc0203de4:	d90fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203de8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203de8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203dec:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203dee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203df2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203df4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203df8:	f022                	sd	s0,32(sp)
ffffffffc0203dfa:	ec26                	sd	s1,24(sp)
ffffffffc0203dfc:	e84a                	sd	s2,16(sp)
ffffffffc0203dfe:	f406                	sd	ra,40(sp)
ffffffffc0203e00:	e44e                	sd	s3,8(sp)
ffffffffc0203e02:	84aa                	mv	s1,a0
ffffffffc0203e04:	892e                	mv	s2,a1
ffffffffc0203e06:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203e0a:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203e0c:	03067e63          	bleu	a6,a2,ffffffffc0203e48 <printnum+0x60>
ffffffffc0203e10:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203e12:	00805763          	blez	s0,ffffffffc0203e20 <printnum+0x38>
ffffffffc0203e16:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203e18:	85ca                	mv	a1,s2
ffffffffc0203e1a:	854e                	mv	a0,s3
ffffffffc0203e1c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203e1e:	fc65                	bnez	s0,ffffffffc0203e16 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e20:	1a02                	slli	s4,s4,0x20
ffffffffc0203e22:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203e26:	00002797          	auipc	a5,0x2
ffffffffc0203e2a:	3fa78793          	addi	a5,a5,1018 # ffffffffc0206220 <error_string+0x38>
ffffffffc0203e2e:	9a3e                	add	s4,s4,a5
}
ffffffffc0203e30:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e32:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203e36:	70a2                	ld	ra,40(sp)
ffffffffc0203e38:	69a2                	ld	s3,8(sp)
ffffffffc0203e3a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e3c:	85ca                	mv	a1,s2
ffffffffc0203e3e:	8326                	mv	t1,s1
}
ffffffffc0203e40:	6942                	ld	s2,16(sp)
ffffffffc0203e42:	64e2                	ld	s1,24(sp)
ffffffffc0203e44:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e46:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203e48:	03065633          	divu	a2,a2,a6
ffffffffc0203e4c:	8722                	mv	a4,s0
ffffffffc0203e4e:	f9bff0ef          	jal	ra,ffffffffc0203de8 <printnum>
ffffffffc0203e52:	b7f9                	j	ffffffffc0203e20 <printnum+0x38>

ffffffffc0203e54 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203e54:	7119                	addi	sp,sp,-128
ffffffffc0203e56:	f4a6                	sd	s1,104(sp)
ffffffffc0203e58:	f0ca                	sd	s2,96(sp)
ffffffffc0203e5a:	e8d2                	sd	s4,80(sp)
ffffffffc0203e5c:	e4d6                	sd	s5,72(sp)
ffffffffc0203e5e:	e0da                	sd	s6,64(sp)
ffffffffc0203e60:	fc5e                	sd	s7,56(sp)
ffffffffc0203e62:	f862                	sd	s8,48(sp)
ffffffffc0203e64:	f06a                	sd	s10,32(sp)
ffffffffc0203e66:	fc86                	sd	ra,120(sp)
ffffffffc0203e68:	f8a2                	sd	s0,112(sp)
ffffffffc0203e6a:	ecce                	sd	s3,88(sp)
ffffffffc0203e6c:	f466                	sd	s9,40(sp)
ffffffffc0203e6e:	ec6e                	sd	s11,24(sp)
ffffffffc0203e70:	892a                	mv	s2,a0
ffffffffc0203e72:	84ae                	mv	s1,a1
ffffffffc0203e74:	8d32                	mv	s10,a2
ffffffffc0203e76:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203e78:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203e7a:	00002a17          	auipc	s4,0x2
ffffffffc0203e7e:	216a0a13          	addi	s4,s4,534 # ffffffffc0206090 <default_pmm_manager+0xff8>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203e82:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203e86:	00002c17          	auipc	s8,0x2
ffffffffc0203e8a:	362c0c13          	addi	s8,s8,866 # ffffffffc02061e8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203e8e:	000d4503          	lbu	a0,0(s10)
ffffffffc0203e92:	02500793          	li	a5,37
ffffffffc0203e96:	001d0413          	addi	s0,s10,1
ffffffffc0203e9a:	00f50e63          	beq	a0,a5,ffffffffc0203eb6 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203e9e:	c521                	beqz	a0,ffffffffc0203ee6 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ea0:	02500993          	li	s3,37
ffffffffc0203ea4:	a011                	j	ffffffffc0203ea8 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203ea6:	c121                	beqz	a0,ffffffffc0203ee6 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203ea8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eaa:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203eac:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eae:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203eb2:	ff351ae3          	bne	a0,s3,ffffffffc0203ea6 <vprintfmt+0x52>
ffffffffc0203eb6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203eba:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203ebe:	4981                	li	s3,0
ffffffffc0203ec0:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0203ec2:	5cfd                	li	s9,-1
ffffffffc0203ec4:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ec6:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0203eca:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ecc:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0203ed0:	0ff6f693          	andi	a3,a3,255
ffffffffc0203ed4:	00140d13          	addi	s10,s0,1
ffffffffc0203ed8:	20d5e563          	bltu	a1,a3,ffffffffc02040e2 <vprintfmt+0x28e>
ffffffffc0203edc:	068a                	slli	a3,a3,0x2
ffffffffc0203ede:	96d2                	add	a3,a3,s4
ffffffffc0203ee0:	4294                	lw	a3,0(a3)
ffffffffc0203ee2:	96d2                	add	a3,a3,s4
ffffffffc0203ee4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203ee6:	70e6                	ld	ra,120(sp)
ffffffffc0203ee8:	7446                	ld	s0,112(sp)
ffffffffc0203eea:	74a6                	ld	s1,104(sp)
ffffffffc0203eec:	7906                	ld	s2,96(sp)
ffffffffc0203eee:	69e6                	ld	s3,88(sp)
ffffffffc0203ef0:	6a46                	ld	s4,80(sp)
ffffffffc0203ef2:	6aa6                	ld	s5,72(sp)
ffffffffc0203ef4:	6b06                	ld	s6,64(sp)
ffffffffc0203ef6:	7be2                	ld	s7,56(sp)
ffffffffc0203ef8:	7c42                	ld	s8,48(sp)
ffffffffc0203efa:	7ca2                	ld	s9,40(sp)
ffffffffc0203efc:	7d02                	ld	s10,32(sp)
ffffffffc0203efe:	6de2                	ld	s11,24(sp)
ffffffffc0203f00:	6109                	addi	sp,sp,128
ffffffffc0203f02:	8082                	ret
    if (lflag >= 2) {
ffffffffc0203f04:	4705                	li	a4,1
ffffffffc0203f06:	008a8593          	addi	a1,s5,8
ffffffffc0203f0a:	01074463          	blt	a4,a6,ffffffffc0203f12 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0203f0e:	26080363          	beqz	a6,ffffffffc0204174 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0203f12:	000ab603          	ld	a2,0(s5)
ffffffffc0203f16:	46c1                	li	a3,16
ffffffffc0203f18:	8aae                	mv	s5,a1
ffffffffc0203f1a:	a06d                	j	ffffffffc0203fc4 <vprintfmt+0x170>
            goto reswitch;
ffffffffc0203f1c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203f20:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f22:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203f24:	b765                	j	ffffffffc0203ecc <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0203f26:	000aa503          	lw	a0,0(s5)
ffffffffc0203f2a:	85a6                	mv	a1,s1
ffffffffc0203f2c:	0aa1                	addi	s5,s5,8
ffffffffc0203f2e:	9902                	jalr	s2
            break;
ffffffffc0203f30:	bfb9                	j	ffffffffc0203e8e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203f32:	4705                	li	a4,1
ffffffffc0203f34:	008a8993          	addi	s3,s5,8
ffffffffc0203f38:	01074463          	blt	a4,a6,ffffffffc0203f40 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0203f3c:	22080463          	beqz	a6,ffffffffc0204164 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0203f40:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0203f44:	24044463          	bltz	s0,ffffffffc020418c <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0203f48:	8622                	mv	a2,s0
ffffffffc0203f4a:	8ace                	mv	s5,s3
ffffffffc0203f4c:	46a9                	li	a3,10
ffffffffc0203f4e:	a89d                	j	ffffffffc0203fc4 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0203f50:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f54:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203f56:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0203f58:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203f5c:	8fb5                	xor	a5,a5,a3
ffffffffc0203f5e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f62:	1ad74363          	blt	a4,a3,ffffffffc0204108 <vprintfmt+0x2b4>
ffffffffc0203f66:	00369793          	slli	a5,a3,0x3
ffffffffc0203f6a:	97e2                	add	a5,a5,s8
ffffffffc0203f6c:	639c                	ld	a5,0(a5)
ffffffffc0203f6e:	18078d63          	beqz	a5,ffffffffc0204108 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203f72:	86be                	mv	a3,a5
ffffffffc0203f74:	00002617          	auipc	a2,0x2
ffffffffc0203f78:	35c60613          	addi	a2,a2,860 # ffffffffc02062d0 <error_string+0xe8>
ffffffffc0203f7c:	85a6                	mv	a1,s1
ffffffffc0203f7e:	854a                	mv	a0,s2
ffffffffc0203f80:	240000ef          	jal	ra,ffffffffc02041c0 <printfmt>
ffffffffc0203f84:	b729                	j	ffffffffc0203e8e <vprintfmt+0x3a>
            lflag ++;
ffffffffc0203f86:	00144603          	lbu	a2,1(s0)
ffffffffc0203f8a:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f8c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203f8e:	bf3d                	j	ffffffffc0203ecc <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0203f90:	4705                	li	a4,1
ffffffffc0203f92:	008a8593          	addi	a1,s5,8
ffffffffc0203f96:	01074463          	blt	a4,a6,ffffffffc0203f9e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203f9a:	1e080263          	beqz	a6,ffffffffc020417e <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0203f9e:	000ab603          	ld	a2,0(s5)
ffffffffc0203fa2:	46a1                	li	a3,8
ffffffffc0203fa4:	8aae                	mv	s5,a1
ffffffffc0203fa6:	a839                	j	ffffffffc0203fc4 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0203fa8:	03000513          	li	a0,48
ffffffffc0203fac:	85a6                	mv	a1,s1
ffffffffc0203fae:	e03e                	sd	a5,0(sp)
ffffffffc0203fb0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203fb2:	85a6                	mv	a1,s1
ffffffffc0203fb4:	07800513          	li	a0,120
ffffffffc0203fb8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203fba:	0aa1                	addi	s5,s5,8
ffffffffc0203fbc:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0203fc0:	6782                	ld	a5,0(sp)
ffffffffc0203fc2:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203fc4:	876e                	mv	a4,s11
ffffffffc0203fc6:	85a6                	mv	a1,s1
ffffffffc0203fc8:	854a                	mv	a0,s2
ffffffffc0203fca:	e1fff0ef          	jal	ra,ffffffffc0203de8 <printnum>
            break;
ffffffffc0203fce:	b5c1                	j	ffffffffc0203e8e <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203fd0:	000ab603          	ld	a2,0(s5)
ffffffffc0203fd4:	0aa1                	addi	s5,s5,8
ffffffffc0203fd6:	1c060663          	beqz	a2,ffffffffc02041a2 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0203fda:	00160413          	addi	s0,a2,1
ffffffffc0203fde:	17b05c63          	blez	s11,ffffffffc0204156 <vprintfmt+0x302>
ffffffffc0203fe2:	02d00593          	li	a1,45
ffffffffc0203fe6:	14b79263          	bne	a5,a1,ffffffffc020412a <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203fea:	00064783          	lbu	a5,0(a2)
ffffffffc0203fee:	0007851b          	sext.w	a0,a5
ffffffffc0203ff2:	c905                	beqz	a0,ffffffffc0204022 <vprintfmt+0x1ce>
ffffffffc0203ff4:	000cc563          	bltz	s9,ffffffffc0203ffe <vprintfmt+0x1aa>
ffffffffc0203ff8:	3cfd                	addiw	s9,s9,-1
ffffffffc0203ffa:	036c8263          	beq	s9,s6,ffffffffc020401e <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0203ffe:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204000:	18098463          	beqz	s3,ffffffffc0204188 <vprintfmt+0x334>
ffffffffc0204004:	3781                	addiw	a5,a5,-32
ffffffffc0204006:	18fbf163          	bleu	a5,s7,ffffffffc0204188 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc020400a:	03f00513          	li	a0,63
ffffffffc020400e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204010:	0405                	addi	s0,s0,1
ffffffffc0204012:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204016:	3dfd                	addiw	s11,s11,-1
ffffffffc0204018:	0007851b          	sext.w	a0,a5
ffffffffc020401c:	fd61                	bnez	a0,ffffffffc0203ff4 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020401e:	e7b058e3          	blez	s11,ffffffffc0203e8e <vprintfmt+0x3a>
ffffffffc0204022:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204024:	85a6                	mv	a1,s1
ffffffffc0204026:	02000513          	li	a0,32
ffffffffc020402a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020402c:	e60d81e3          	beqz	s11,ffffffffc0203e8e <vprintfmt+0x3a>
ffffffffc0204030:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204032:	85a6                	mv	a1,s1
ffffffffc0204034:	02000513          	li	a0,32
ffffffffc0204038:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020403a:	fe0d94e3          	bnez	s11,ffffffffc0204022 <vprintfmt+0x1ce>
ffffffffc020403e:	bd81                	j	ffffffffc0203e8e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204040:	4705                	li	a4,1
ffffffffc0204042:	008a8593          	addi	a1,s5,8
ffffffffc0204046:	01074463          	blt	a4,a6,ffffffffc020404e <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020404a:	12080063          	beqz	a6,ffffffffc020416a <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020404e:	000ab603          	ld	a2,0(s5)
ffffffffc0204052:	46a9                	li	a3,10
ffffffffc0204054:	8aae                	mv	s5,a1
ffffffffc0204056:	b7bd                	j	ffffffffc0203fc4 <vprintfmt+0x170>
ffffffffc0204058:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020405c:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204060:	846a                	mv	s0,s10
ffffffffc0204062:	b5ad                	j	ffffffffc0203ecc <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0204064:	85a6                	mv	a1,s1
ffffffffc0204066:	02500513          	li	a0,37
ffffffffc020406a:	9902                	jalr	s2
            break;
ffffffffc020406c:	b50d                	j	ffffffffc0203e8e <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020406e:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0204072:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204076:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204078:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020407a:	e40dd9e3          	bgez	s11,ffffffffc0203ecc <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020407e:	8de6                	mv	s11,s9
ffffffffc0204080:	5cfd                	li	s9,-1
ffffffffc0204082:	b5a9                	j	ffffffffc0203ecc <vprintfmt+0x78>
            goto reswitch;
ffffffffc0204084:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0204088:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020408c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020408e:	bd3d                	j	ffffffffc0203ecc <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0204090:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0204094:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204098:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020409a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020409e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02040a2:	fcd56ce3          	bltu	a0,a3,ffffffffc020407a <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02040a6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02040a8:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02040ac:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02040b0:	0196873b          	addw	a4,a3,s9
ffffffffc02040b4:	0017171b          	slliw	a4,a4,0x1
ffffffffc02040b8:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02040bc:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02040c0:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02040c4:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02040c8:	fcd57fe3          	bleu	a3,a0,ffffffffc02040a6 <vprintfmt+0x252>
ffffffffc02040cc:	b77d                	j	ffffffffc020407a <vprintfmt+0x226>
            if (width < 0)
ffffffffc02040ce:	fffdc693          	not	a3,s11
ffffffffc02040d2:	96fd                	srai	a3,a3,0x3f
ffffffffc02040d4:	00ddfdb3          	and	s11,s11,a3
ffffffffc02040d8:	00144603          	lbu	a2,1(s0)
ffffffffc02040dc:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040de:	846a                	mv	s0,s10
ffffffffc02040e0:	b3f5                	j	ffffffffc0203ecc <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02040e2:	85a6                	mv	a1,s1
ffffffffc02040e4:	02500513          	li	a0,37
ffffffffc02040e8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02040ea:	fff44703          	lbu	a4,-1(s0)
ffffffffc02040ee:	02500793          	li	a5,37
ffffffffc02040f2:	8d22                	mv	s10,s0
ffffffffc02040f4:	d8f70de3          	beq	a4,a5,ffffffffc0203e8e <vprintfmt+0x3a>
ffffffffc02040f8:	02500713          	li	a4,37
ffffffffc02040fc:	1d7d                	addi	s10,s10,-1
ffffffffc02040fe:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204102:	fee79de3          	bne	a5,a4,ffffffffc02040fc <vprintfmt+0x2a8>
ffffffffc0204106:	b361                	j	ffffffffc0203e8e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204108:	00002617          	auipc	a2,0x2
ffffffffc020410c:	1b860613          	addi	a2,a2,440 # ffffffffc02062c0 <error_string+0xd8>
ffffffffc0204110:	85a6                	mv	a1,s1
ffffffffc0204112:	854a                	mv	a0,s2
ffffffffc0204114:	0ac000ef          	jal	ra,ffffffffc02041c0 <printfmt>
ffffffffc0204118:	bb9d                	j	ffffffffc0203e8e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020411a:	00002617          	auipc	a2,0x2
ffffffffc020411e:	19e60613          	addi	a2,a2,414 # ffffffffc02062b8 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0204122:	00002417          	auipc	s0,0x2
ffffffffc0204126:	19740413          	addi	s0,s0,407 # ffffffffc02062b9 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020412a:	8532                	mv	a0,a2
ffffffffc020412c:	85e6                	mv	a1,s9
ffffffffc020412e:	e032                	sd	a2,0(sp)
ffffffffc0204130:	e43e                	sd	a5,8(sp)
ffffffffc0204132:	18a000ef          	jal	ra,ffffffffc02042bc <strnlen>
ffffffffc0204136:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020413a:	6602                	ld	a2,0(sp)
ffffffffc020413c:	01b05d63          	blez	s11,ffffffffc0204156 <vprintfmt+0x302>
ffffffffc0204140:	67a2                	ld	a5,8(sp)
ffffffffc0204142:	2781                	sext.w	a5,a5
ffffffffc0204144:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204146:	6522                	ld	a0,8(sp)
ffffffffc0204148:	85a6                	mv	a1,s1
ffffffffc020414a:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020414c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020414e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204150:	6602                	ld	a2,0(sp)
ffffffffc0204152:	fe0d9ae3          	bnez	s11,ffffffffc0204146 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204156:	00064783          	lbu	a5,0(a2)
ffffffffc020415a:	0007851b          	sext.w	a0,a5
ffffffffc020415e:	e8051be3          	bnez	a0,ffffffffc0203ff4 <vprintfmt+0x1a0>
ffffffffc0204162:	b335                	j	ffffffffc0203e8e <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0204164:	000aa403          	lw	s0,0(s5)
ffffffffc0204168:	bbf1                	j	ffffffffc0203f44 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc020416a:	000ae603          	lwu	a2,0(s5)
ffffffffc020416e:	46a9                	li	a3,10
ffffffffc0204170:	8aae                	mv	s5,a1
ffffffffc0204172:	bd89                	j	ffffffffc0203fc4 <vprintfmt+0x170>
ffffffffc0204174:	000ae603          	lwu	a2,0(s5)
ffffffffc0204178:	46c1                	li	a3,16
ffffffffc020417a:	8aae                	mv	s5,a1
ffffffffc020417c:	b5a1                	j	ffffffffc0203fc4 <vprintfmt+0x170>
ffffffffc020417e:	000ae603          	lwu	a2,0(s5)
ffffffffc0204182:	46a1                	li	a3,8
ffffffffc0204184:	8aae                	mv	s5,a1
ffffffffc0204186:	bd3d                	j	ffffffffc0203fc4 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0204188:	9902                	jalr	s2
ffffffffc020418a:	b559                	j	ffffffffc0204010 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc020418c:	85a6                	mv	a1,s1
ffffffffc020418e:	02d00513          	li	a0,45
ffffffffc0204192:	e03e                	sd	a5,0(sp)
ffffffffc0204194:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204196:	8ace                	mv	s5,s3
ffffffffc0204198:	40800633          	neg	a2,s0
ffffffffc020419c:	46a9                	li	a3,10
ffffffffc020419e:	6782                	ld	a5,0(sp)
ffffffffc02041a0:	b515                	j	ffffffffc0203fc4 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02041a2:	01b05663          	blez	s11,ffffffffc02041ae <vprintfmt+0x35a>
ffffffffc02041a6:	02d00693          	li	a3,45
ffffffffc02041aa:	f6d798e3          	bne	a5,a3,ffffffffc020411a <vprintfmt+0x2c6>
ffffffffc02041ae:	00002417          	auipc	s0,0x2
ffffffffc02041b2:	10b40413          	addi	s0,s0,267 # ffffffffc02062b9 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041b6:	02800513          	li	a0,40
ffffffffc02041ba:	02800793          	li	a5,40
ffffffffc02041be:	bd1d                	j	ffffffffc0203ff4 <vprintfmt+0x1a0>

ffffffffc02041c0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041c0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02041c2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041c6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041c8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041ca:	ec06                	sd	ra,24(sp)
ffffffffc02041cc:	f83a                	sd	a4,48(sp)
ffffffffc02041ce:	fc3e                	sd	a5,56(sp)
ffffffffc02041d0:	e0c2                	sd	a6,64(sp)
ffffffffc02041d2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02041d4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041d6:	c7fff0ef          	jal	ra,ffffffffc0203e54 <vprintfmt>
}
ffffffffc02041da:	60e2                	ld	ra,24(sp)
ffffffffc02041dc:	6161                	addi	sp,sp,80
ffffffffc02041de:	8082                	ret

ffffffffc02041e0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02041e0:	715d                	addi	sp,sp,-80
ffffffffc02041e2:	e486                	sd	ra,72(sp)
ffffffffc02041e4:	e0a2                	sd	s0,64(sp)
ffffffffc02041e6:	fc26                	sd	s1,56(sp)
ffffffffc02041e8:	f84a                	sd	s2,48(sp)
ffffffffc02041ea:	f44e                	sd	s3,40(sp)
ffffffffc02041ec:	f052                	sd	s4,32(sp)
ffffffffc02041ee:	ec56                	sd	s5,24(sp)
ffffffffc02041f0:	e85a                	sd	s6,16(sp)
ffffffffc02041f2:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02041f4:	c901                	beqz	a0,ffffffffc0204204 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02041f6:	85aa                	mv	a1,a0
ffffffffc02041f8:	00002517          	auipc	a0,0x2
ffffffffc02041fc:	0d850513          	addi	a0,a0,216 # ffffffffc02062d0 <error_string+0xe8>
ffffffffc0204200:	ebffb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc0204204:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204206:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204208:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020420a:	4aa9                	li	s5,10
ffffffffc020420c:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020420e:	0000db97          	auipc	s7,0xd
ffffffffc0204212:	e32b8b93          	addi	s7,s7,-462 # ffffffffc0211040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204216:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020421a:	eddfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020421e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204220:	00054b63          	bltz	a0,ffffffffc0204236 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204224:	00a95b63          	ble	a0,s2,ffffffffc020423a <readline+0x5a>
ffffffffc0204228:	029a5463          	ble	s1,s4,ffffffffc0204250 <readline+0x70>
        c = getchar();
ffffffffc020422c:	ecbfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204230:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204232:	fe0559e3          	bgez	a0,ffffffffc0204224 <readline+0x44>
            return NULL;
ffffffffc0204236:	4501                	li	a0,0
ffffffffc0204238:	a099                	j	ffffffffc020427e <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc020423a:	03341463          	bne	s0,s3,ffffffffc0204262 <readline+0x82>
ffffffffc020423e:	e8b9                	bnez	s1,ffffffffc0204294 <readline+0xb4>
        c = getchar();
ffffffffc0204240:	eb7fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204244:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204246:	fe0548e3          	bltz	a0,ffffffffc0204236 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020424a:	fea958e3          	ble	a0,s2,ffffffffc020423a <readline+0x5a>
ffffffffc020424e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0204250:	8522                	mv	a0,s0
ffffffffc0204252:	ea1fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc0204256:	009b87b3          	add	a5,s7,s1
ffffffffc020425a:	00878023          	sb	s0,0(a5)
ffffffffc020425e:	2485                	addiw	s1,s1,1
ffffffffc0204260:	bf6d                	j	ffffffffc020421a <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0204262:	01540463          	beq	s0,s5,ffffffffc020426a <readline+0x8a>
ffffffffc0204266:	fb641ae3          	bne	s0,s6,ffffffffc020421a <readline+0x3a>
            cputchar(c);
ffffffffc020426a:	8522                	mv	a0,s0
ffffffffc020426c:	e87fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc0204270:	0000d517          	auipc	a0,0xd
ffffffffc0204274:	dd050513          	addi	a0,a0,-560 # ffffffffc0211040 <buf>
ffffffffc0204278:	94aa                	add	s1,s1,a0
ffffffffc020427a:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020427e:	60a6                	ld	ra,72(sp)
ffffffffc0204280:	6406                	ld	s0,64(sp)
ffffffffc0204282:	74e2                	ld	s1,56(sp)
ffffffffc0204284:	7942                	ld	s2,48(sp)
ffffffffc0204286:	79a2                	ld	s3,40(sp)
ffffffffc0204288:	7a02                	ld	s4,32(sp)
ffffffffc020428a:	6ae2                	ld	s5,24(sp)
ffffffffc020428c:	6b42                	ld	s6,16(sp)
ffffffffc020428e:	6ba2                	ld	s7,8(sp)
ffffffffc0204290:	6161                	addi	sp,sp,80
ffffffffc0204292:	8082                	ret
            cputchar(c);
ffffffffc0204294:	4521                	li	a0,8
ffffffffc0204296:	e5dfb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc020429a:	34fd                	addiw	s1,s1,-1
ffffffffc020429c:	bfbd                	j	ffffffffc020421a <readline+0x3a>

ffffffffc020429e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020429e:	00054783          	lbu	a5,0(a0)
ffffffffc02042a2:	cb91                	beqz	a5,ffffffffc02042b6 <strlen+0x18>
    size_t cnt = 0;
ffffffffc02042a4:	4781                	li	a5,0
        cnt ++;
ffffffffc02042a6:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02042a8:	00f50733          	add	a4,a0,a5
ffffffffc02042ac:	00074703          	lbu	a4,0(a4)
ffffffffc02042b0:	fb7d                	bnez	a4,ffffffffc02042a6 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02042b2:	853e                	mv	a0,a5
ffffffffc02042b4:	8082                	ret
    size_t cnt = 0;
ffffffffc02042b6:	4781                	li	a5,0
}
ffffffffc02042b8:	853e                	mv	a0,a5
ffffffffc02042ba:	8082                	ret

ffffffffc02042bc <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042bc:	c185                	beqz	a1,ffffffffc02042dc <strnlen+0x20>
ffffffffc02042be:	00054783          	lbu	a5,0(a0)
ffffffffc02042c2:	cf89                	beqz	a5,ffffffffc02042dc <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02042c4:	4781                	li	a5,0
ffffffffc02042c6:	a021                	j	ffffffffc02042ce <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042c8:	00074703          	lbu	a4,0(a4)
ffffffffc02042cc:	c711                	beqz	a4,ffffffffc02042d8 <strnlen+0x1c>
        cnt ++;
ffffffffc02042ce:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042d0:	00f50733          	add	a4,a0,a5
ffffffffc02042d4:	fef59ae3          	bne	a1,a5,ffffffffc02042c8 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02042d8:	853e                	mv	a0,a5
ffffffffc02042da:	8082                	ret
    size_t cnt = 0;
ffffffffc02042dc:	4781                	li	a5,0
}
ffffffffc02042de:	853e                	mv	a0,a5
ffffffffc02042e0:	8082                	ret

ffffffffc02042e2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02042e2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02042e4:	0585                	addi	a1,a1,1
ffffffffc02042e6:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02042ea:	0785                	addi	a5,a5,1
ffffffffc02042ec:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02042f0:	fb75                	bnez	a4,ffffffffc02042e4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02042f2:	8082                	ret

ffffffffc02042f4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02042f4:	00054783          	lbu	a5,0(a0)
ffffffffc02042f8:	0005c703          	lbu	a4,0(a1)
ffffffffc02042fc:	cb91                	beqz	a5,ffffffffc0204310 <strcmp+0x1c>
ffffffffc02042fe:	00e79c63          	bne	a5,a4,ffffffffc0204316 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0204302:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204304:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0204308:	0585                	addi	a1,a1,1
ffffffffc020430a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020430e:	fbe5                	bnez	a5,ffffffffc02042fe <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204310:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204312:	9d19                	subw	a0,a0,a4
ffffffffc0204314:	8082                	ret
ffffffffc0204316:	0007851b          	sext.w	a0,a5
ffffffffc020431a:	9d19                	subw	a0,a0,a4
ffffffffc020431c:	8082                	ret

ffffffffc020431e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020431e:	00054783          	lbu	a5,0(a0)
ffffffffc0204322:	cb91                	beqz	a5,ffffffffc0204336 <strchr+0x18>
        if (*s == c) {
ffffffffc0204324:	00b79563          	bne	a5,a1,ffffffffc020432e <strchr+0x10>
ffffffffc0204328:	a809                	j	ffffffffc020433a <strchr+0x1c>
ffffffffc020432a:	00b78763          	beq	a5,a1,ffffffffc0204338 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc020432e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204330:	00054783          	lbu	a5,0(a0)
ffffffffc0204334:	fbfd                	bnez	a5,ffffffffc020432a <strchr+0xc>
    }
    return NULL;
ffffffffc0204336:	4501                	li	a0,0
}
ffffffffc0204338:	8082                	ret
ffffffffc020433a:	8082                	ret

ffffffffc020433c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020433c:	ca01                	beqz	a2,ffffffffc020434c <memset+0x10>
ffffffffc020433e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204340:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204342:	0785                	addi	a5,a5,1
ffffffffc0204344:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204348:	fec79de3          	bne	a5,a2,ffffffffc0204342 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020434c:	8082                	ret

ffffffffc020434e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020434e:	ca19                	beqz	a2,ffffffffc0204364 <memcpy+0x16>
ffffffffc0204350:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204352:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204354:	0585                	addi	a1,a1,1
ffffffffc0204356:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020435a:	0785                	addi	a5,a5,1
ffffffffc020435c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204360:	fec59ae3          	bne	a1,a2,ffffffffc0204354 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204364:	8082                	ret
