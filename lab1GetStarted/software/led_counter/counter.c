/*
 * counter.c
 *
 *  Created on: Oct 10, 2018
 *      Author: andreas
 */

#include <stdio.h>
#include "io.h"
#include "system.h"

#define DELAY 1000000

int main(void)
{
	int counter = 0;
	unsigned int wait;

	printf("Lets start counting \n");
	IOWR_8DIRECT(LEDS_BASE,0,0);
	while (1) {
		counter ++;
		printf("counter = %d \n",counter);
		IOWR_8DIRECT(LEDS_BASE,0,counter);
		// s i l l y busy w a i t
		for (wait = 0; wait < DELAY; wait++) {
			asm volatile ("nop");
		}
	}
}


