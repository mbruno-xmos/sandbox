/*
 * freertos_port.c
 *
 *  Created on: Jul 19, 2019
 *      Author: mbruno
 */

#include <xs1.h>

#include "freertos_port.h"

#include "xassert.h"
#include "xcore_c.h"
#include "debug_print.h"

#define CORE_COUNT_MAX 8

static chanend core_interrupt_chan[CORE_COUNT_MAX];

static lock_t freertos_kernel_lock;
static volatile int xcore_thread_init_count;

DEFINE_INTERRUPT_CALLBACK(freertos_isr, freertos_xcore_thread_isr, data)
{
    int core_id;
    int other_core_id;
    core_id = (int) get_logical_core_id();

    other_core_id = (int) _s_chan_in_byte(core_interrupt_chan[core_id]);
    _s_chan_check_ct_end(core_interrupt_chan[core_id]);

    debug_printf("Core %d interrupted by core %d\n", core_id, other_core_id);
}

void freertos_xcore_thread_interrupt(int core_id)
{
    int this_core_id;

    interrupt_mask_all();
    /*** BEGIN CRITICAL SECTION ***/
    /*
     * It is important that this runs atomically
     * and is not preempted in the middle.
     */
    this_core_id = (int) get_logical_core_id();
    chanend_set_dest(core_interrupt_chan[this_core_id], core_interrupt_chan[core_id]);
    _s_chan_out_byte(core_interrupt_chan[this_core_id], this_core_id);
    _s_chan_out_ct_end(core_interrupt_chan[this_core_id]);
    /*** END CRITICAL SECTION ***/
    interrupt_unmask_all();
}

/*
 * Spawn CORE_COUNT (up to 8) tasks within a single tile.
 *
 * Each allocates a channel end with GETR and assigns
 * its identifier to core_interrupt_chan[get_logical_core_id()].
 * Each sets it up to trigger an interrupt. This interrupt should
 * bring the core into the FreeRTOS scheduler.
 *
 * When one core needs to interrupt another, it sets the
 * destination channel of core_interrupt_chan[get_logical_core_id()]
 * to core_interrupt_chan[OTHER CORE] and sends it a token. This
 * interrupts the other core which can just discard the token, or
 * perhaps it contains which thread that needs to wake up.
 * We can figure those details out later. We just need to make sure
 * that it's possible for any thread to interrupt any other thread.
 */

int freertos_xcore_thread_init(int xcore_thread_count)
{
    int core_id;

    core_id = (int) get_logical_core_id();

    if (core_id == 0) {
        lock_alloc(&freertos_kernel_lock);
    } else {
        /*
         * xcore threads other than 0 must wait here until
         * thread 0 has initialized to guarantee that the
         * lock has been allocated.
         */
        while (xcore_thread_init_count == 0);
    }

    chanend_alloc(&core_interrupt_chan[core_id]);

    chanend_setup_interrupt_callback(core_interrupt_chan[core_id], NULL, INTERRUPT_CALLBACK(freertos_xcore_thread_isr));
    chanend_enable_trigger(core_interrupt_chan[core_id]);
    interrupt_unmask_all();

    lock_acquire(freertos_kernel_lock);
    xcore_thread_init_count++;
    lock_release(freertos_kernel_lock);

    /*
     * All threads wait here until all are initialized.
     */
    while (xcore_thread_init_count < xcore_thread_count);

    return core_id;
}

DEFINE_INTERRUPT_PERMITTED(freertos_isr, void, freertos_xcore_thread_kernel_enter, int xcore_thread_count)
{
    int core_id;

    xassert(xcore_thread_count <= CORE_COUNT_MAX);

    core_id = freertos_xcore_thread_init(xcore_thread_count);

    debug_printf("Thread %d initialized\n", core_id);

    core_id++;
    if (core_id == xcore_thread_count) {
        core_id = 0;
    }
    freertos_xcore_thread_interrupt(core_id);

    for (;;);
}
