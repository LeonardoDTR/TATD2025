.section .text
.globl start 
.globl blinker
.globl put_hello

test:
    li   sp, 0x1000

loopT:
    la   a0, test_msg
    call putstring

putstring:
    addi sp, sp, -4
    sw   ra, 0(sp)
    mv   t2, a0

.L1:
    lbu  t1, 0(t2)
    beqz t1, .L2
    mv   a0, t1
    call putchar
    addi t2, t2, 1
    j .L1

.L2:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

.section .data
test_msg:
    .asciz "\n\r- test -\n\r"

