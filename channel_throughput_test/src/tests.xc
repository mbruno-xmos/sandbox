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


#define ARRAY_SIZE 2048
#define TEST_REPEAT_COUNT 2

typedef struct {
    int array[ARRAY_SIZE];
} data_t;


interface intertile_xfer_if {
    void xfer_struct(data_t &data);
    void xfer_array(int array[ARRAY_SIZE]);
};

void print_elapsed_time(uint32_t t1, uint32_t t2)
{
    t1 = t2 -= t1;
    t1 /= 100;
    t2 -= 100*t1;

    printf("%u.%02u microseconds\n", t1, t2);
}

void data_array_send_via_interface(int send_data[ARRAY_SIZE], server interface intertile_xfer_if iface, int tile, timer tmr)
{
    uint32_t t1, t2;

    tmr :> t1;
    select {
        case iface.xfer_array(int array[ARRAY_SIZE]):
            memcpy(array, send_data, sizeof(array));
            break;
        case iface.xfer_struct(data_t &data):
            printf("bad\n");
            break;
    }
    tmr :> t2;

    printf("%u bytes (array) sent over an interface to tile %d in ", sizeof(send_data), tile);
    print_elapsed_time(t1, t2);
}

void data_array_recv_via_interface(int recv_data[ARRAY_SIZE], client interface intertile_xfer_if iface)
{
    iface.xfer_array(recv_data);
}

void data_send_via_interface(data_t *send_data, server interface intertile_xfer_if iface, int tile, timer tmr)
{
    uint32_t t1, t2;

    tmr :> t1;
    select {
        case iface.xfer_struct(data_t &data):
            data = *send_data;
            break;
        case iface.xfer_array(int array[ARRAY_SIZE]):
            printf("bad\n");
            break;
    }
    tmr :> t2;

    printf("%u bytes (struct) sent over an interface to tile %d in ", sizeof(data_t), tile);
    print_elapsed_time(t1, t2);
}

void data_recv_via_interface(data_t *recv_data, client interface intertile_xfer_if iface)
{
    iface.xfer_struct(*recv_data);
}

void data_send_via_channel(data_t *send_data, chanend channel, int tile, timer tmr)
{
    uint32_t t1, t2;

    tmr :> t1;
    channel <: *send_data;
    tmr :> t2;

    printf("%u bytes sent over a channel to tile %d in ", sizeof(data_t), tile);
    print_elapsed_time(t1, t2);
}


void data_recv_via_channel(data_t *recv_data, chanend channel)
{
    channel :> *recv_data;
}

void data_send_via_streaming_channel(data_t *send_data, streaming chanend channel, int tile, timer tmr)
{
    uint32_t t1, t2;

    tmr :> t1;
    channel <: *send_data;
    tmr :> t2;

    printf("%u bytes sent over a streaming channel to tile %d in ", sizeof(data_t), tile);
    print_elapsed_time(t1, t2);
}


void data_recv_via_streaming_channel(data_t *recv_data, streaming chanend channel)
{
    channel :> *recv_data;
}

void data_sender_task(server interface intertile_xfer_if iface[2], chanend channel[2], streaming chanend streaming_channel[2])
{
    data_t send_data;
    int i;

    timer tmr;

    for (i = 0; i < ARRAY_SIZE; i++) {
        send_data.array[i] = i;
    }

    for (i = 0; i < TEST_REPEAT_COUNT; i++) {
        delay_milliseconds(500);
        data_send_via_interface(&send_data, iface[0], 1, tmr);
        delay_milliseconds(500);
        data_array_send_via_interface(send_data.array, iface[0], 1, tmr);
        delay_milliseconds(500);
        data_send_via_channel(&send_data, channel[0], 1, tmr);
        delay_milliseconds(500);
        data_send_via_streaming_channel(&send_data, streaming_channel[0], 1, tmr);
        printf("\n");

        delay_milliseconds(500);
        data_send_via_interface(&send_data, iface[1], 2, tmr);
        delay_milliseconds(500);
        data_array_send_via_interface(send_data.array, iface[1], 2, tmr);
        delay_milliseconds(500);
        data_send_via_channel(&send_data, channel[1], 2, tmr);
        delay_milliseconds(500);
        data_send_via_streaming_channel(&send_data, streaming_channel[1], 2, tmr);
        printf("\n");
    }

}

void data_receiver_task(client interface intertile_xfer_if iface, chanend channel, streaming chanend streaming_channel)
{
    int i;
    data_t recv_data;

    for (i = 0; i < TEST_REPEAT_COUNT; i++) {
        data_recv_via_interface(&recv_data, iface);
        data_array_recv_via_interface(recv_data.array, iface);
        data_recv_via_channel(&recv_data, channel);
        data_recv_via_streaming_channel(&recv_data, streaming_channel);
    }
}

int main()
{
    interface intertile_xfer_if iface[2];
    chan channel[2];
    streaming chan streaming_channel[2];

    par {
        on tile[0]: {
            par {
                data_sender_task(iface, channel, streaming_channel);
            }
        }

        on tile[1]: {
            par {
                data_receiver_task(iface[0], channel[0], streaming_channel[0]);
            }
        }

        on tile[2]: {
            par {
                data_receiver_task(iface[1], channel[1], streaming_channel[1]);
            }
        }


    }


    return 0;
}
