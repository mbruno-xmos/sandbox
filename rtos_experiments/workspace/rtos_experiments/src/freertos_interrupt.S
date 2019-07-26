// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifdef __XS2A__
# define _XCORE_C_STACK_ALIGN(n)   ((n+1)/2)*2
#else
# define _XCORE_C_STACK_ALIGN(n)   n
#endif

#include "freertos_port.h"

.globl _freertos_interrupt_callback_common
.align 2  // We arrive in single issue mode.
.type  _freertos_interrupt_callback_common,@function
_freertos_interrupt_callback_common:
  // This is the body of the FreeRTOS _xcore_c_interrupt_callback_XXX functions.
  // r2 = interrupt_callback_t function

  /*
   * Save the thread's context onto the thread's stack.
   * The stack was extended for this by the wrapper function.
   */
  stw    spc,    sp[1]
  stw    ssr,    sp[2]
  stw    sed,    sp[3]
  stw    et,     sp[4]
  stw    dp,     sp[5]
  stw    cp,     sp[6]
  stw    lr,     sp[7]
  stw    r0,     sp[8]
  stw    r1,     sp[9]
//stw    r2,     sp[10]  /* already saved by the wrapper function. */
  stw    r3,     sp[11]
  stw    r4,     sp[12]
  stw    r5,     sp[13]
  stw    r6,     sp[14]
  stw    r7,     sp[15]
  stw    r8,     sp[16]
  stw    r9,     sp[17]
  stw    r10,    sp[18]
//stw    r11,    sp[19]  /* already saved by the wrapper function. */

  ldaw   r1,     sp[0]   /* get value of current stackpointer. */
                         /* this will be the second argument to the callback. */

  kentsp 0               /* switch to the kernel stack. */
                         /* The value 0 is safe to use since we don't need the SP */
                         /* saved to KSP[0] as it will be saved by the callback. */

  get    r11,    ed      /* Get the event data... */
  mov    r0,     r11     /* into the first argument for the callback function... */
                         /* (the second argument is the thread's SP as set above) */
  bla    r2              /* and call the callback function. */
                         /* return value in r0 is the stack pointer for the current */
                         /* thread which may have changed. */
//krestsp 0              /* actually uncessary since KSP is already set and the SP */
                         /* is being restored next from R0 */

  set    sp,     r0;     /* set the SP to the stack of the process we are restoring. */

  /* Restore the state */
  ldw    spc,    sp[1];
  ldw    ssr,    sp[2];
  ldw    sed,    sp[3];
  ldw    et,     sp[4];
  ldw    dp,     sp[5];
  ldw    cp,     sp[6];
  ldw    lr,     sp[7];
  ldw    r0,     sp[8];
  ldw    r1,     sp[9];
  ldw    r2,     sp[10];
  ldw    r3,     sp[11];
  ldw    r4,     sp[12];
  ldw    r5,     sp[13];
  ldw    r6,     sp[14];
  ldw    r7,     sp[15];
  ldw    r8,     sp[16];
  ldw    r9,     sp[17];
  ldw    r10,    sp[18];
  ldw    r11,    sp[19];

  /* shrink the stack by the size of the context just restored */
  ldaw   sp,     sp[_XCORE_C_STACK_ALIGN(FREERTOS_XCORE_THREAD_CONTEXT_WORDSIZE)]

  kret                   /* exit kernel mode and return to the thread */
