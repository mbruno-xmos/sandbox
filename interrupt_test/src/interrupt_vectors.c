/*
 * interrupt_vectors.c
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */

#include <stdlib.h>
#include "lib_interrupt.h"

#include "interrupt_vectors.h"

void isr1(chanend channel, void *user_ptr);
//void isr2(chanend channel, void *user_ptr);
//void isr3(chanend channel, void *user_ptr);

static void *interrupt_vectors[] = {
        isr1,
        //isr2,
        //isr3,
};

void *interrupt_vector(unsigned isr)
{
    if (isr < ISR_COUNT) {
        return interrupt_vectors[isr];
    } else {
        return NULL;
    }
}
