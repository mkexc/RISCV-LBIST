	.section .text
	.global _sbst_boot
	.type _sbst_boot, @function

_sbst_boot:
	//add sp, sp, 16		// this creates space in the stack

	lui	a0, %hi(__TEST_DATA_START)
	addi	a0, a0, %lo(__TEST_DATA_START)
	
	// preserve all non-volatile registers 
	la 		t0, saved_regs
	sw		ra, 0(t0)
	sw		sp, 4(t0)
	sw		gp, 8(t0)
	sw		tp, 12(t0)
	sw		s0, 16(t0)
	sw		s1, 20(t0)
	sw		s2, 24(t0)
	sw		s3, 28(t0)
	sw		s4, 32(t0)
	sw		s5, 36(t0)
	sw		s6, 40(t0)
	sw		s7, 44(t0)
	sw		s8, 48(t0)
	sw		s9, 52(t0)
	sw		s10, 56(t0)
	sw		s11, 60(t0)
	
	// disable interrupts (if they were enabled)
	csrrs	t1, mstatus, x0			// read mstatus CSR
	andi	t1, t1, 0x9				// bitwise and with 1st and 4-th bit ON to get the interrupt status (if t1 becomes 0x0 interrupts were disabled, else if t1=0x9 they were both on, else if t1=0x1 only user interrupts were on, else if t1=0x8 only machine interrupts were on)
	la 		t0, interrupt_status	// load memory address to store the interrupt status
	sw 		t1, 0(t0)				// store the actual interrupt status
	csrrc	t1, mstatus, t1 		// if some or all interrupts were enabled (t1!=0x0) only those that were enabled get disabled, otherwise(t1=0x0) they stay disabled

	// signature gen
	xor		t3, t3, t3		// signature = 0
	la		t4, RF_PATTERNS
	lw		x1,	0*4(t4)
	lw		x2, 1*4(t4)
	lw		x3, 2*4(t4)
	lw		x4, 3*4(t4)
	lw		x5, 4*4(t4)
	lw		x6, 5*4(t4)
	lw		x7, 6*4(t4)
	lw		x8, 7*4(t4)
	lw		x9, 8*4(t4)
	lw		x10, 9*4(t4)
	lw		x11, 10*4(t4)
	lw		x12, 11*4(t4)
	lw		x13, 12*4(t4)
	lw		x14, 13*4(t4)
	lw		x15, 14*4(t4)

	add t3, t3, x1
	add t3, t3, x2
	add t3, t3, x3
	add t3, t3, x4
	add t3, t3, x5
	add t3, t3, x6
	add t3, t3, x7
	add t3, t3, x8
	add t3, t3, x9
	add t3, t3, x10
	add t3, t3, x11
	add t3, t3, x12
	add t3, t3, x13
	add t3, t3, x14
	add t3, t3, x15
	
	mv t0, t3	// signature move t3=>t0
	mv t1, t4	// RF_PATTERN addr move t4=>t1

	lw		x16, 15*4(t1)
	lw		x17, 16*4(t1)
	lw		x18, 17*4(t1)
	lw		x19, 18*4(t1)
	lw		x20, 19*4(t1)
	lw		x21, 20*4(t1)
	lw		x22, 21*4(t1)
	lw		x23, 22*4(t1)
	lw		x24, 23*4(t1)
	lw		x25, 24*4(t1)
	lw		x26, 25*4(t1)
	lw		x27, 26*4(t1)
	lw		x28, 27*4(t1)
	lw		x29, 28*4(t1)
	lw		x30, 29*4(t1)
	lw		x31, 30*4(t1)
	
	add t0, t0, x16
	add t0, t0, x17
	add t0, t0, x18
	add t0, t0, x19
	add t0, t0, x20
	add t0, t0, x21
	add t0, t0, x22
	add t0, t0, x23
	add t0, t0, x24
	add t0, t0, x25
	add t0, t0, x26
	add t0, t0, x27
	add t0, t0, x28
	add t0, t0, x29
	add t0, t0, x30
	add t0, t0, x31
	
	// write the result
	
	la t1, test_result
	sw t0, 0(t1)

	// restore non-volatile registers
	la 		t0, saved_regs
	lw		ra, 0(t0)
	lw		sp, 4(t0)
	lw		gp, 8(t0)
	lw		tp, 12(t0)
	lw		s0, 16(t0)
	lw		s1, 20(t0)
	lw		s2, 24(t0)
	lw		s3, 28(t0)
	lw		s4, 32(t0)
	lw		s5, 36(t0)
	lw		s6, 40(t0)
	lw		s7, 44(t0)
	lw		s8, 48(t0)
	lw		s9, 52(t0)
	lw		s10, 56(t0)
	lw		s11, 60(t0)
	// restore interrupts (if they were active before!)
	la 		t0, interrupt_status	// get address of stored interrupt status
	lw 		t1, 0(t0)				// load stored interrupt status
	csrrs	t1, mstatus, t1			// if all or some interrupts were on (t1=0x9 or t1=0x1 or t1=0x8) only those that were enabled get enabled again, otherwise if they were off (t1=0x0) they stay disabled

	ret


// -------------------------------------
	.section ".TEST_DATA", "aw"
	.global test_result

test_result:
	.space 4
saved_regs:
	.space 64
interrupt_status:
	.space 4
// Examples:
//variable1:	(4 * 4bytes)
//	.space 0x10
//variable2:
//	.space 4

// -------------------------------------
	.section ".TEST_RODATA", "a"

RF_PATTERNS:
	.long 0x12345678
	.long 0xcafecafe
	.long 0xdeadbeef
	.long 0xABADBABE 
	.long 0xBAADF00D 
	.long 0xBADDCAFE 
	.long 0xCAFEBABE  
	.long 0xDEFEC8ED 
	.long 0xFEEDFACE 
	.long 0x8BADF00D
	.long 0xB105F00D
	.long 0xBAAAAAAD
	.long 0xBAD22222
	.long 0xBEEFBABE
	.long 0xC00010FF
	.long 0xCAFED00D
	.long 0xCEFAEDFE
	.long 0xDABBAD00
	.long 0xDEAD2BAD
	.long 0xDEADBAAD
	.long 0xDEADBABE
	.long 0xDEADBEAF
	.long 0xDEADC0DE
	.long 0xDEADDEAD
	.long 0xDEADD00D
	.long 0xDEADFA11
	.long 0xDEAD10CC
	.long 0xDEADFEED
	.long 0xDECAFBAD
	.long 0xFACEFEED
	.long 0xFEE1DEAD

OTHER_PATTERNS:
	.long 0x0
	.long 0x0
