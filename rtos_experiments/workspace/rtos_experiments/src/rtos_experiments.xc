/*
 * rtos_experiments.xc
 *
 *  Created on: Jul 18, 2019
 *      Author: mbruno
 */

#include <platform.h>
#include <xs1.h>

#include "freertos_port.h"
#include "debug_print.h"

#define FREERTOS_CORE_COUNT 3

void task_print_self(chanend ?c)
{
    unsigned int core_id;
    unsigned int node_id;

    core_id = get_logical_core_id();
    node_id = get_local_tile_id();

    if (!isnull(c)) {
        debug_printf("hello from core %u on node %08X (%u)\ni has channel end %08X\n", core_id, node_id, node_id, c);
    }
}

void spawn_print_self(chanend ?c1, chanend ?c2)
{
    par {
        task_print_self(c1);

        par (int i = 0; i < 6; i++) {
            task_print_self(null);
        }

        task_print_self(c2);
    }
}

int main()
{
//    chan c1, c2, c3, c4;
    par {
//        on tile[0]: spawn_print_self(c1, c2);
//        on tile[1]: spawn_print_self(c1, c2);
//        on tile[2]: spawn_print_self(c3, c4);
//        on tile[3]: spawn_print_self(c3, c4);

        on tile[0]: freertos_xcore_kernel_enter(FREERTOS_CORE_COUNT);
    }

    return 0;
}
