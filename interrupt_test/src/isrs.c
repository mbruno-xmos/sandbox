/*
 * isrs.c
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */

#include <stdio.h>

#include "isrs.h"

void *chan_isr_ptr(void)
{
    return (void *) chan_isr;
}

int read_channel_c(int channel_id)
{
    return read_channel(channel_id);
}

void set_channel_isr(chanend channel, void *func_ptr)
{
    asm(
        "mov r11, %1\n"
        "setv res[%0], r11\n"    /* set the interrupt vector for the channel end to func_ptr */
        "mov r11, %0\n"
        "setev res[%0], r11\n"   /* set the "environment vector" to the channel id */
        "setc res[%0], 0x000A\n" /* put the channel end resource into interrupt mode */
        "eeu res[%0]\n"          /* enable interrupts from the channel resource */
        "setsr 0x02\n"           /* enable interrupts on the core */

        :                        /* no outputs */
        : "r"(channel),          /* channel is input 0 */
          "r"(func_ptr)          /* func_ptr is input 1 */
        : "r11"                  /* clobbers r11 */
    );

    //printf("setting ISR, channel id is %08X\n", channel);
}
