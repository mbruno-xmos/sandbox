/*
 * freertos_interrupts.h
 *
 *  Created on: Jul 23, 2019
 *      Author: mbruno
 */


#ifndef FREERTOS_INTERRUPT_H_
#define FREERTOS_INTERRUPT_H_

#include "xcore_c_interrupt.h"

#define _DEFINE_FREERTOS_INTERRUPT_PERMITTED_DEF(grp, root_function) \
    .weak  _fptrgroup.grp.nstackwords.group; \
    .max_reduce _fptrgroup.grp.nstackwords, _fptrgroup.grp.nstackwords.group, 0; \
    .set _kstack_words, _XCORE_C_STACK_ALIGN(_fptrgroup.grp.nstackwords $M XCORE_C_KSTACK_WORDS); \
    .globl _xcore_c_interrupt_permitted_common; \
    .globl _INTERRUPT_PERMITTED(root_function); \
    .align _XCORE_C_CODE_ALIGNMENT; \
    .type  _INTERRUPT_PERMITTED(root_function),@function; \
    .cc_top _INTERRUPT_PERMITTED(root_function).function,_INTERRUPT_PERMITTED(root_function); \
    _INTERRUPT_PERMITTED(root_function):; \
      _XCORE_C_ENTSP(_XCORE_C_STACK_ALIGN(3)); \
      stw r5, sp[2]; \
      stw r4, sp[1]; \
      ldc r4, _kstack_words; \
      ldap r11, root_function; \
      add r5, r11, 0; \
      ldap r11, _xcore_c_interrupt_permitted_common; \
      bau r11; \
    .cc_bottom _INTERRUPT_PERMITTED(root_function).function; \
    /* The stack size for this function must be big enough for: */ \
    /*  - This wrapper function: _XCORE_C_STACK_ALIGN(3) + _xcore_c_interrupt_permitted_common.nstackwords  */ \
    /*  - The size of the stack required by the root function: root_function.nstackwords */ \
    /*  - The thread's context which is pushed onto the thread stack upon entering an ISR: _XCORE_C_STACK_ALIGN(FREERTOS_XCORE_THREAD_CONTEXT_WORDSIZE) */ \
    /*  - The size of the stack required by the ISR group: _kstack_words */ \
    .set   _INTERRUPT_PERMITTED(root_function).nstackwords, _XCORE_C_STACK_ALIGN(3) + _XCORE_C_STACK_ALIGN(FREERTOS_XCORE_THREAD_CONTEXT_WORDSIZE) + _kstack_words + _xcore_c_interrupt_permitted_common.nstackwords + root_function.nstackwords; \
    .globl _INTERRUPT_PERMITTED(root_function).nstackwords; \
    .set   _INTERRUPT_PERMITTED(root_function).maxcores, 1 $M _xcore_c_interrupt_permitted_common.maxcores $M root_function.maxcores; \
    .globl _INTERRUPT_PERMITTED(root_function).maxcores; \
    .set   _INTERRUPT_PERMITTED(root_function).maxtimers, 0 $M _xcore_c_interrupt_permitted_common.maxtimers $M root_function.maxtimers; \
    .globl _INTERRUPT_PERMITTED(root_function).maxtimers; \
    .set   _INTERRUPT_PERMITTED(root_function).maxchanends, 0 $M _xcore_c_select_callback_common.maxchanends $M root_function.maxchanends; \
    .globl _INTERRUPT_PERMITTED(root_function).maxchanends; \
    .size  _INTERRUPT_PERMITTED(root_function), . - _INTERRUPT_PERMITTED(root_function); \

#define _DEFINE_FREERTOS_INTERRUPT_PERMITTED(grp, ret, root_function, ...) \
    asm(_XCORE_C_STR(_DEFINE_FREERTOS_INTERRUPT_PERMITTED_DEF(grp, root_function))); \
    _DECLARE_INTERRUPT_PERMITTED(ret, root_function, __VA_ARGS__)

#define _DECLARE_FREERTOS_INTERRUPT_CALLBACK(intrpt, data, sp) \
    void _INTERRUPT_CALLBACK(intrpt)(void);\
    void *intrpt(void *data, void *sp)

#define _DEFINE_FREERTOS_INTERRUPT_CALLBACK_DEF(grp, intrpt) \
    .globl _freertos_interrupt_callback_common; \
    .weak _fptrgroup.grp.nstackwords.group; \
    .add_to_set _fptrgroup.grp.nstackwords.group, _INTERRUPT_CALLBACK(intrpt).nstackwords, _INTERRUPT_CALLBACK(intrpt); \
    .globl _INTERRUPT_CALLBACK(intrpt); \
    .align _XCORE_C_CODE_ALIGNMENT; \
    .type  _INTERRUPT_CALLBACK(intrpt),@function; \
    .cc_top _INTERRUPT_CALLBACK(intrpt).function,_INTERRUPT_CALLBACK(intrpt); \
    _INTERRUPT_CALLBACK(intrpt):; \
      /*_XCORE_C_SINGLE_ISSUE; .. Do we know what KEDI is set to? - TODO: Make sure KEDI is 0 */ \
      /* Extend the stack by enough words to store the context */ \
      extsp _XCORE_C_STACK_ALIGN(FREERTOS_XCORE_THREAD_CONTEXT_WORDSIZE); \
      stw r11, sp[19]; \
      stw r2, sp[10]; \
      ldap r11, intrpt; \
      mov r2, r11; \
      ldap r11, _freertos_interrupt_callback_common; \
      bau r11; \
    .cc_bottom _INTERRUPT_CALLBACK(intrpt).function; \
    .set   _INTERRUPT_CALLBACK(intrpt).nstackwords, intrpt.nstackwords; \
    .globl _INTERRUPT_CALLBACK(intrpt).nstackwords; \
    .set   _INTERRUPT_CALLBACK(intrpt).maxcores, 1 $M intrpt.maxcores; \
    .globl _INTERRUPT_CALLBACK(intrpt).maxcores; \
    .set   _INTERRUPT_CALLBACK(intrpt).maxtimers, 0 $M intrpt.maxtimers; \
    .globl _INTERRUPT_CALLBACK(intrpt).maxtimers; \
    .set   _INTERRUPT_CALLBACK(intrpt).maxchanends, 0 $M intrpt.maxchanends; \
    .globl _INTERRUPT_CALLBACK(intrpt).maxchanends; \
    .size  _INTERRUPT_CALLBACK(intrpt), . - _INTERRUPT_CALLBACK(intrpt); \

#define _DEFINE_FREERTOS_INTERRUPT_CALLBACK(grp, intrpt, data, sp) \
    asm(_XCORE_C_STR(_DEFINE_FREERTOS_INTERRUPT_CALLBACK_DEF(grp, intrpt))); \
    _DECLARE_FREERTOS_INTERRUPT_CALLBACK(intrpt, data, sp)

#endif /* FREERTOS_INTERRUPT_H_ */
