/*
 * freertos_port.h
 *
 *  Created on: Jul 19, 2019
 *      Author: mbruno
 */


#ifndef FREERTOS_PORT_H_
#define FREERTOS_PORT_H_

#include "xcore_c.h"

DECLARE_INTERRUPT_PERMITTED(void, freertos_xcore_thread_kernel_enter, void);

#endif /* FREERTOS_PORT_H_ */
