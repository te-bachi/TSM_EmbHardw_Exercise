/**
 * main_simple_pio.c
 */

#include <stdio.h>
#include <stdbool.h>
#include "io.h"
#include "system.h"
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "priv/alt_legacy_irq.h"
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_performance_counter.h"

#define DELAY 1000000
#define CLEAR_IRQ 0x0000

#define SIMPLE_PIO_RegDir   0x00
#define SIMPLE_PIO_RegPin   0x01
#define SIMPLE_PIO_RegPort  0x02
#define SIMPLE_PIO_RegSet   0x03
#define SIMPLE_PIO_RegClr   0x04

static void handle_timerIRQ(void* context, alt_u32 id);


int main(void) {
	alt_irq_context statusISR;

	/*** INTERRUPT SETUP *****************************************************/

	/*
	puts("Disable IRQs");
	statusISR = alt_irq_disable_all();

	puts("Register timer IRQ handler...");
	alt_irq_register(TIMER_IRQ, NULL, (alt_isr_func)handle_timerIRQ);

	puts("Clear pending timer IRQs...");
	IOWR_16DIRECT(TIMER_BASE, ALTERA_AVALON_TIMER_STATUS_REG, CLEAR_IRQ);

	puts("Configure Timer");
	IOWR_16DIRECT(TIMER_BASE, ALTERA_AVALON_TIMER_CONTROL_REG,
			ALTERA_AVALON_TIMER_CONTROL_ITO_MSK  |
			ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
			ALTERA_AVALON_TIMER_CONTROL_START_MSK);

	puts("Enabled all IRQs\n");
	alt_irq_enable_all(statusISR);
	*/

	/*** LED *****************************************************************/
	int counter = 0;
	unsigned int wait;

	printf("Lets start counting \n");
	IOWR_8DIRECT(SIMPLE_PIO_BASE, SIMPLE_PIO_RegDir, 0xff);
	while (1) {
		counter++;
		printf("counter = %d \n",counter);
		IOWR_8DIRECT(SIMPLE_PIO_BASE, SIMPLE_PIO_RegPort, counter);

		// s i l l y busy w a i t
		for (wait = 0; wait < DELAY; wait++) {
			asm volatile ("nop");
		}
	}
}


static void handle_timerIRQ(void* context, alt_u32 id) {
	/* Clear IRQ Pending */
	IOWR_16DIRECT(TIMER_BASE, ALTERA_AVALON_TIMER_STATUS_REG, CLEAR_IRQ);
}
