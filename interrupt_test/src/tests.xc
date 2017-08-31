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

#include "isrs.h"

static int gdata;

int read_channel(chanend channel)
{
    int data;

    channel :> data;

    return data;
}

void chan_isr(void)
{
    int channel_id;
    int from_channel;

    //printf("in isr\n");

    /* get the environment vector which holds the channel id */
    asm("get r11, ed\n mov %0, r11" : "=r"(channel_id) : : "r11");

    //printf("ISR read out %08X from ED\n", channel_id);

    from_channel = read_channel_c(channel_id);

    //printf("isr read from channel: %d\n", from_channel);

    gdata = from_channel;

    /* special "kernel mode" return */
    asm("kret");
}

void task1(chanend channel, int tile)
{
    int data;

    set_channel_isr(channel, chan_isr_ptr());

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
