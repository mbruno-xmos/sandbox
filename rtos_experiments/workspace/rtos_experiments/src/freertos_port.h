/*
 * freertos_port.h
 *
 *  Created on: Jul 19, 2019
 *      Author: mbruno
 */


#ifndef FREERTOS_PORT_H_
#define FREERTOS_PORT_H_

#include "xcore_c.h"

#if defined(__XC__)

DECLARE_INTERRUPT_PERMITTED(void, freertos_xcore_thread_kernel_enter, int xcore_thread_count);

/**
 * To be run by main(). Specify the number of cores
 * that should be used by the FreeRTOS scheduler.
 */
void freertos_xcore_kernel_enter(int num_cores);
#define freertos_xcore_kernel_enter(num_cores) \
    par (int i = 0; i < num_cores; i++) { \
        INTERRUPT_PERMITTED(freertos_xcore_thread_kernel_enter)(num_cores); \
    }

#endif // defined(__XC__)

#endif /* FREERTOS_PORT_H_ */
