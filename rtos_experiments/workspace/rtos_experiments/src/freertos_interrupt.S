// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifdef __XS2A__
# define _XCORE_C_STACK_ALIGN(n)   ((n+1)/2)*2
#else
# define _XCORE_C_STACK_ALIGN(n)   n
#endif

#include "freertos_port.h"

.globl _freertos_interrupt_callback_common
.align 2  // We arrive in single issue mode.
//.type  _freertos_interrupt_callback_common,@function
//.cc_top _freertos_interrupt_callback_common.function,_freertos_interrupt_callback_common
_freertos_interrupt_callback_common:
  // This is the body of the FreeRTOS _xcore_c_interrupt_callback_XXX functions.
  // r2 = interrupt_callback_t function

  /*
   * Save the thread's context onto the thread's stack.
   * The stack was extended for this by the wrapper function.
   */
  stw   spc,    sp[1]
  stw   ssr,    sp[2]
  stw   sed,    sp[3]
  stw   et,     sp[4]
  stw   dp,     sp[5]
  stw   cp,     sp[6]
  stw   lr,     sp[7]
  stw   r0,     sp[8]
  stw   r1,     sp[9]
//stw   r2,     sp[10]           /* already saved by the wrapper function */
  stw   r3,     sp[11]
  stw   r4,     sp[12]
  stw   r5,     sp[13]
  stw   r6,     sp[14]
  stw   r7,     sp[15]
  stw   r8,     sp[16]
  stw   r9,     sp[17]
  stw   r10,    sp[18]
//stw   r11,    sp[19]           /* already saved by the wrapper function */
  ldaw  r1,     sp[0]            /* get value of current stackpointer */
  //ldw   r11,    dp[pxCurrentTCB] /* pxCurrentTCB holds pointer to TCB of process, store it in r11 */
                                 /* TODO: pxCurrentTCB needs to be array of size FREERTOS_CORE_COUNT */
  //stw r2, r11[0]                /* save current stackpointer to TCB of process */
                                 /* */

                                 /*
                                 TODO: Pass both ED and SP (in R2) to the callback.
                                 The callback can save SP into the pxCurrentTCB array. */


  kentsp 0                       /* Enter kernel mode and switch to the kernel stack. */
                                 /* The value 0 is safe to use since we don't need the SP */
                                 /* saved to KSP[0] as it will be saved by the callback. */
                                 /* */
  get r11, ed                    /* Get the event data... */
  mov r0, r11                    /* into the first argument for the callback function... */
                                 /* (the second argument is the thread's SP as set above) */
  bla r2                         /* and call the callback function */
                                 /* return value in r0 is the stack pointer for the current */
                                 /* thread which may have changed. */
  krestsp 0

  set   sp,    r0;              /* set the SP to the SP of the process we are restoring */
  ldw   spc,   sp[1];           /* restore saved program counter */
  ldw   ssr,   sp[2];           /* restore saved status register */
  ldw   sed,   sp[3];           /* restore saved exception data */
  ldw   et,    sp[4];           /* restore exception type */
  ldw   dp,    sp[5];           /* restore data pointer */
  ldw   cp,    sp[6];           /* restore constant pool pointer */
  ldw   lr,    sp[7];           /* restore link register */
  ldw   r0,    sp[8];           /* restore GP registers r0-r9 */
  ldw   r1,    sp[9];
  ldw   r2,    sp[10];
  ldw   r3,    sp[11];
  ldw   r4,    sp[12];
  ldw   r5,    sp[13];
  ldw   r6,    sp[14];
  ldw   r7,    sp[15];
  ldw   r8,    sp[16];
  ldw   r9,    sp[17];
  ldw   r10,   sp[18];
  ldw   r11,   sp[19];
  /* shrink the stack by the size of the context just restored */
  ldaw  sp,    sp[_XCORE_C_STACK_ALIGN(FREERTOS_XCORE_THREAD_CONTEXT_WORDSIZE)]

  kret
  /*
.cc_bottom _freertos_interrupt_callback_common.function
.set   _freertos_interrupt_callback_common.nstackwords, 0
.globl _freertos_interrupt_callback_common.nstackwords
.set   _freertos_interrupt_callback_common.maxcores, 1
.globl _freertos_interrupt_callback_common.maxcores
.set   _freertos_interrupt_callback_common.maxtimers, 0
.globl _freertos_interrupt_callback_common.maxtimers
.set   _freertos_interrupt_callback_common.maxchanends, 0
.globl _freertos_interrupt_callback_common.maxchanends
.size  _freertos_interrupt_callback_common, . - _freertos_interrupt_callback_common
*/
