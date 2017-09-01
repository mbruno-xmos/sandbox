/*
 * isrs.h
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */


#ifndef ISRS_H_
#define ISRS_H_

#include <stdint.h>
#include "xccompat.h"

#define ISR_STACK_MIN_SIZE 14

typedef struct {
    unsigned channel_id;
#ifdef __XC__
    void * unsafe func_ptr;
    void * unsafe user_ptr;
    uint32_t * unsafe stack;
#else
    __attribute__((fptrgroup("isr_group")))
    void (*func_ptr)(chanend channel, void *user_ptr);
    void *user_ptr;
    uint32_t *stack;
#endif
} isr_data_t;

#ifdef __XC__
void interrupt_enable_channel(chanend channel_id, void * unsafe func_ptr, void * unsafe user_ptr, REFERENCE_PARAM(isr_data_t, isr_data));
#else
void interrupt_enable_channel(chanend channel_id, void *func_ptr, void *user_ptr, REFERENCE_PARAM(isr_data_t, isr_data));
#endif

#endif /* ISRS_H_ */
