/*
 * isrs.h
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */


#ifndef ISRS_H_
#define ISRS_H_

#include "xccompat.h"

#ifdef __XC__

void * unsafe chan_isr_ptr(void);
void set_channel_isr(chanend channel, void * unsafe func_ptr);
int read_channel_c(int channel_id);

#else

void chan_isr(void);
int read_channel(chanend channel);

#endif

#endif /* ISRS_H_ */
