/*
 * interrupt_vectors.h
 *
 *  Created on: Aug 31, 2017
 *      Author: mbruno
 */


#ifndef INTERRUPT_VECTORS_H_
#define INTERRUPT_VECTORS_H_

enum {
    ISR1,
    //ISR2,
    //ISR3,
    ISR_COUNT
};

#ifdef __XC__
void * unsafe interrupt_vector(unsigned isr);
#else
void *interrupt_vector(unsigned isr);
#endif

#endif /* INTERRUPT_VECTORS_H_ */
