	.text
	.globl	generic_isr
	.align	4
	.type	generic_isr,@function
	.cc_top generic_isr.function,generic_isr
generic_isr:

	/*
	 * decrement the stack pointer by 14 words,
	 * enough to save all the registers.
	 */
	entsp 14

	/*
	 * now save all the registers.
	 * leave sp[0] alone since the user
	 * function will clobber it with the lr.
	 */
	stw r0, sp[1]
	stw r1, sp[2]
	stw r2, sp[3]
	stw r3, sp[4]
	stw r4, sp[5]
	stw r5, sp[6]
	stw r6, sp[7]
	stw r7, sp[8]
	stw r8, sp[9]
	stw r9, sp[10]
	stw r10, sp[11]
	stw r11, sp[12]
	stw lr, sp[13]

	get r11, ed   /* get the environment vector which holds the isr_data struct */
	mov r1, r11   /* and put it into r1 */

	ldw r2, r1[1] /* get func_ptr out of isr_data */
	ldw r0, r1[0] /* get the channel id out of isr_data */
	ldw r1, r1[2] /* get user_ptr out of isr_data */

	bla r2 /* call func_ptr with channel_id and user_ptr as arguments */

	/* restore all the registers */
	ldw r0, sp[1]
	ldw r1, sp[2]
	ldw r2, sp[3]
	ldw r3, sp[4]
	ldw r4, sp[5]
	ldw r5, sp[6]
	ldw r6, sp[7]
	ldw r7, sp[8]
	ldw r8, sp[9]
	ldw r9, sp[10]
	ldw r10, sp[11]
	ldw r11, sp[12]
	ldw  lr, sp[13]

	ldaw sp, sp[14] /* restore the sp (increment by 14) */

	kret /* return from the isr */

	.cc_bottom generic_isr.function
	.set	generic_isr.nstackwords,(_fptrgroup.isr_group.nstackwords + 14)
	.globl	generic_isr.nstackwords
	.set	generic_isr.maxcores,_fptrgroup.isr_group.maxcores $M 1
	.globl	generic_isr.maxcores
	.set	generic_isr.maxtimers,_fptrgroup.isr_group.maxtimers $M 0
	.globl	generic_isr.maxtimers
	.set	generic_isr.maxchanends,_fptrgroup.isr_group.maxchanends $M 0
	.globl	generic_isr.maxchanends
.generic_isr_end:
	.size	generic_isr, .generic_isr_end-generic_isr
