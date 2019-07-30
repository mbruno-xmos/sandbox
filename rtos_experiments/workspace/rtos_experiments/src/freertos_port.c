/*
 * freertos_port.c
 *
 *  Created on: Jul 19, 2019
 *      Author: mbruno
 */

#include <xs1.h>
#include <timer.h>

#include "freertos_port.h"
#include "freertos_interrupt.h"

#include "xassert.h"
#include "xcore_c.h"
#include "debug_print.h"

#define CORE_COUNT_MAX 8

static chanend core_interrupt_chan[CORE_COUNT_MAX];

static hwtimer_t freertos_kernel_timer;
static lock_t freertos_kernel_lock;
static volatile int xcore_thread_init_count;

static volatile uint32_t *thread_sp[CORE_COUNT_MAX];
static volatile int in_isr_count;

static volatile uint32_t freertos_tick;

void freertos_xcore_thread_interrupt_from_isr(int core_id)
{
    int this_core_id;

    this_core_id = (int) get_logical_core_id();
    chanend_set_dest(core_interrupt_chan[this_core_id], core_interrupt_chan[core_id]);
    _s_chan_out_byte(core_interrupt_chan[this_core_id], this_core_id);
    _s_chan_out_ct_end(core_interrupt_chan[this_core_id]);
}

void freertos_xcore_thread_interrupt(int core_id)
{
    interrupt_mask_all();
    /*** BEGIN CRITICAL SECTION ***/
    /*
     * It is important that this runs atomically
     * and is not preempted in the middle.
     */
    freertos_xcore_thread_interrupt_from_isr(core_id);
    /*** END CRITICAL SECTION ***/
    interrupt_unmask_all();
}

_DEFINE_FREERTOS_INTERRUPT_CALLBACK(freertos_isr, freertos_xcore_thread_isr, data, sp)
{
    int core_id;
    int other_core_id;
    int next_core_id;
    core_id = (int) get_logical_core_id();

    thread_sp[core_id] = sp;

    lock_acquire(freertos_kernel_lock);
    in_isr_count++;
    lock_release(freertos_kernel_lock);

    //other_core_id = (int) _s_chan_in_byte(core_interrupt_chan[core_id]);
    //_s_chan_check_ct_end(core_interrupt_chan[core_id]);

    next_core_id = core_id + 1;
    if (next_core_id == 3) {
        next_core_id = 0;
    }

    while (in_isr_count < 3);

    sp = (void *) thread_sp[next_core_id];

#if 1
    return sp;
#else
    return (void *) thread_sp[core_id];
#endif
}

__attribute__((fptrgroup("freertos_isr")))
void *freertos_kcall_handler(uint32_t arg, void *sp)
{
    debug_printf("In KCALL: %u\n", arg);

    return freertos_xcore_thread_isr(NULL, sp);
}

static void _hwtimer_get_trigger_time(hwtimer_t t, uint32_t *time)
{
  asm volatile("getd %0, res[%1]" : "=r" (*time): "r" (t));
}

static xcore_c_error_t hwtimer_get_trigger_time(hwtimer_t t, uint32_t *time)
{
  RETURN_EXCEPTION_OR_ERROR( _hwtimer_get_trigger_time(t, time) );
}

_DEFINE_FREERTOS_INTERRUPT_CALLBACK(freertos_isr, freertos_xcore_timer_isr, data, sp)
{
    uint32_t now;

    hwtimer_get_time(freertos_kernel_timer, &now);
    hwtimer_get_trigger_time(freertos_kernel_timer, &now);
    //debug_printf("timer isr (%u)\n", now);
    now += 10 * 100000;
    hwtimer_change_trigger_time(freertos_kernel_timer, now);

    freertos_tick++;

    if (freertos_tick % 100 == 0) {
        debug_printf("%d\n", freertos_tick);
        //in_isr_count = 0;
        for (int i = 0; i < 3; i++) {
            //freertos_xcore_thread_interrupt_from_isr(i);
        }
    }

    return sp;
}

/*
 * Spawn xcore_thread_count (up to CORE_COUNT_MAX) tasks within a single tile.
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
        hwtimer_alloc(&freertos_kernel_timer);
    } else {
        /*
         * xcore threads other than 0 must wait here until
         * thread 0 has initialized to guarantee that the
         * lock has been allocated.
         */
        while (xcore_thread_init_count == 0);
    }

    asm volatile (
            "ldap r11, kexcept\n\t"
            "set kep, r11\n\t"
            :
            :
            : "r11"
    );

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

    if (core_id == 0) {
        uint32_t now;
        hwtimer_get_time(freertos_kernel_timer, &now);
        //debug_printf("The time is now (%u)\n", now);

        now += 10 * 100000;

        hwtimer_setup_interrupt_callback(freertos_kernel_timer,
                now, NULL, INTERRUPT_CALLBACK(freertos_xcore_timer_isr));
        hwtimer_enable_trigger(freertos_kernel_timer);
    }

    return core_id;
}

#define portKCALL(X) asm volatile ("kcall %0" :: "r"(X))

void pcore(int thread_id)
{
    int core_id;

    interrupt_mask_all();
    core_id = get_logical_core_id();
    debug_printf("Thread %d on core %d\n", thread_id, core_id);
    interrupt_unmask_all();
}

_DEFINE_FREERTOS_INTERRUPT_PERMITTED(freertos_isr, void, freertos_xcore_thread_kernel_enter, int xcore_thread_count)
{
    int thread_id;

    xassert(xcore_thread_count <= CORE_COUNT_MAX);

    thread_id = freertos_xcore_thread_init(xcore_thread_count);

    debug_printf("Thread %d initialized\n", thread_id);

    for (int i = 0; i < 10; i++) {

        in_isr_count = 0;

        pcore(thread_id);

        /* delay 500 ms (50 ticks) */
        uint32_t t1 = freertos_tick;
        while ((freertos_tick - t1) < 50);
        portKCALL(thread_id);
    }

    debug_printf("Thread %d done at core %d\n", thread_id, get_logical_core_id());

    for (;;);
}
