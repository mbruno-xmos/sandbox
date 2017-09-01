/*
 * lib_isr.c
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */

#include <stdio.h>
#include <stdint.h>

#include "lib_interrupt.h"

/* generic_isr is found in lib_interrupt.S */
void generic_isr(void);

void interrupt_enable_channel(chanend channel_id, void *func_ptr, void *user_ptr, REFERENCE_PARAM(isr_data_t, isr_data))
{
    isr_data->channel_id = channel_id;
    isr_data->func_ptr = func_ptr;
    isr_data->user_ptr = user_ptr;

    asm(
        "mov r11, %2\n"
        "setv res[%0], r11\n"    /* set the interrupt vector for the channel end to generic_isr */
        "mov r11, %1\n"
        "setev res[%0], r11\n"   /* set the "environment vector" to the isr_data struct */
        "setc res[%0], 0x000A\n" /* put the channel end resource into interrupt mode */
        "eeu res[%0]\n"          /* enable interrupts from the channel resource */
        "setsr 0x02\n"           /* enable interrupts on the core */

        :                        /* no outputs */
        : "r"(channel_id),       /* channel_id is input 0 */
          "r"(isr_data),         /* isr_data is input 1 */
          "r"(generic_isr)       /* generic_isr is input 2 */
        : "r11"                  /* clobbers r11 */
    );
}
