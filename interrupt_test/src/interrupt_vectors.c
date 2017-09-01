/*
 * interrupt_vectors.c
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */

#include <stdlib.h>
#include <stdio.h>
#include "lib_interrupt.h"

#include "interrupt_vectors.h"

void isr1(chanend channel, void *user_ptr);
void isr2(chanend channel, void *user_ptr);

__attribute__((fptrgroup("isr_group")))
void _isr1(chanend channel, void *user_ptr)
{
    return isr1(channel, user_ptr);
}

__attribute__((fptrgroup("isr_group")))
void _isr2(chanend channel, void *user_ptr)
{
    return isr2(channel, user_ptr);
}

static void *interrupt_vectors[] = {
        _isr1,
        _isr2,
};

void *interrupt_vector(unsigned isr)
{
    if (isr < ISR_COUNT) {
        return interrupt_vectors[isr];
    } else {
        return NULL;
    }
}
