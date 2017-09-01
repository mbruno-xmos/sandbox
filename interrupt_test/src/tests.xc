/*
 * tests.xc
 *
 *  Created on: Aug 8, 2017
 *      Author: mbruno
 */

#include <platform.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <timer.h>
#include "lib_interrupt.h"

#include "interrupt_vectors.h"

static int gdata[2];

void isr1(chanend channel, void * unsafe user_ptr)
{
    channel :> gdata[0];
}

void isr2(chanend channel, void * unsafe user_ptr)
{
    channel :> gdata[1];
}

unsafe {
void task1(chanend channel, int tile)
{
    uint32_t stack_for_isr[ISR_STACK_MIN_SIZE + 10];
    int data, last_data;
    int change_count = 0;
    volatile int * unsafe data_ptr;
    isr_data_t isr_data;

    isr_data.stack = stack_for_isr;

    if (tile == 0) {
        interrupt_enable_channel(channel, interrupt_vector(ISR1), NULL, isr_data);
        data_ptr = &gdata[0];
    } else if (tile == 2) {
        interrupt_enable_channel(channel, interrupt_vector(ISR2), NULL, isr_data);
        data_ptr = &gdata[1];
    }

    last_data = *data_ptr;
    do {
        data = *data_ptr;
        if (data != last_data) {
            change_count++;
            printf("tile %d received new value %d\n", tile, data);
            last_data = data;
        }

    } while (change_count < 10);
    printf("task1 on tile %d is done\n", tile);
}
}

void task2(chanend channel, int tile)
{
    for (int i = 0; i < 10; i++) {
        delay_milliseconds(500);
        channel <: tile*42 + i;
    }
}

int main()
{
    chan channel1, channel2;

    par {
        on tile[0]: task1(channel1, 0);
        on tile[1]: task2(channel2, 1);
        on tile[2]: task1(channel2, 2);
        on tile[3]: task2(channel1, 3);
    }

    return 0;
}
