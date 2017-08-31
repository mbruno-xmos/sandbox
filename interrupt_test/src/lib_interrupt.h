/*
 * isrs.h
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */


#ifndef ISRS_H_
#define ISRS_H_

#include "xccompat.h"

typedef struct {
    unsigned channel_id;
#ifdef __XC__
    void * unsafe func_ptr;
    void * unsafe user_ptr;
#else
    void (*func_ptr)(chanend channel, void *user_ptr);
    void *user_ptr;
#endif
} isr_data_t;

#ifdef __XC__
void interrupt_enable_channel(chanend channel_id, void * unsafe func_ptr, void * unsafe user_ptr, REFERENCE_PARAM(isr_data_t, isr_data));
#else
void interrupt_enable_channel(chanend channel_id, void *func_ptr, void *user_ptr, REFERENCE_PARAM(isr_data_t, isr_data));
#endif

#endif /* ISRS_H_ */
