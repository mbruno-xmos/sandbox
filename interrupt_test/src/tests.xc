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

static int gdata;

void isr1(chanend channel, void * unsafe user_ptr)
{
    channel :> gdata;
}

void task1(chanend channel, int tile)
{
    int data;
    isr_data_t isr_data;

    interrupt_enable_channel(channel, interrupt_vector(ISR1), NULL, isr_data);

    do {
        data = gdata;
        printf("%d\n", data);
    } while (data < 51);
}

void task2(chanend channel, int tile)
{
    for (int i = 0; i < 10; i++) {
        delay_milliseconds(500);
        //printf("task2 to trigger interrupt in task1 now\n");
        channel <: 42 + i;
    }
}

int main()
{
    chan channel;

    par {
        on tile[0]: task1(channel, 0);
        on tile[3]: task2(channel, 1);
    }

    return 0;
}
