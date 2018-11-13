/*
 * camera.c
 *
 *  Created on: Dec 4, 2014
 *      Author: theo
 */
#include "system.h"
#include "io.h"
//#include "dma_lcd.h"
#include "camera.h"

#define top 0x30
#define back 0x20
#define fps60 0x00
#define fps30 0x01
#define fps20 0x02
#define fps15 0x03
#define fps10 0x05
#define fps1  0x3B

const unsigned char camera_init[] = {
	//  0x00|0x01|0x02|0x03|0x04|0x05|0x06|0x07|0x08|0x09|0x0A|0x0B|0x0C|0x0D|0x0E|0x0F
		0x12,0x78,0x48,0x02,0x03,0x39,0x39,0x39,0x38,0x03,0x96,0x57,0x00,0x00,0x01,0x00,
		0x7b,fps15,0x63,0xEF,0x2A,0x00,0x24,0x15,0x00,0x01,0x81,0x00,0x7F,0xA2,back,0x00,
		0x80,0x80,0x80,0x80,0x3C,0x36,0x72,0x08,0x08,0x15,0x00,0x00,0x08,0x00,0x00,0x38,
		0x08,0x30,0xA4,0x00,0x3f,0x00,0x3a,0x04,0x72,0x57,0x0A,0x04,0x0C,0x99,0x02,0x83,
		0xD0,0x41,0xC0,0x0A,0xF0,0x46,0x62,0x2A,0x3C,0x48,0xEC,0xE9,0xE9,0xE9,0xE9,0x98,
		0x98,0x00,0x28,0x70,0x98,0x00,0x40,0x80,0x1A,0x85,0xA9,0x64,0x84,0x53,0x0E,0xF0,
		0xF0,0xF0,0x00,0x00,0x02,0x20,0x00,0x80,0x80,0x0A,0x00,0x4A,0x04,0x55,0x00,0x9D,
		0x06,0x78,0x11,0x01,0x10,0x10,0x01,0x02,0x28,0x00,0x12,0x08,0x16,0x30,0x5E,0x72,
		0x82,0x8E,0x9A,0xA4,0xAC,0xB8,0xC3,0xD6,0xE6,0xF2,0x24,0x04,0x80,0x00,0x00,0x00,
		0x71,0x6F,0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x80,0x00,0x00,0x00,0x02,0x02,0x6F,
		0x6D,0x40,0x9D,0x83,0x50,0x68,0x40,0x10,0xC1,0xEF,0x92,0x04,0x80,0x80,0x80,0x80,
		0x04,0x00,0xF2,0x20,0x20,0x00,0xAF,0xEE,0xEE,0x0C,0x00,0xAE,0x7C,0x7D,0x7E,0x7F,
		0xAA,0xC0,0x01,0x4E,0x00,0x2E,0x05,0x81,0x06,0xE0,0xE8,0xF0,0xD8,0x93,0xE3
};

int buffer1[CAMERA_IMAGE_SIZE_INT],buffer2[CAMERA_IMAGE_SIZE_INT],
    buffer3[CAMERA_IMAGE_SIZE_INT],buffer4[CAMERA_IMAGE_SIZE_INT];


void delayms1() {
	int i;
	for (i = 0 ; i < 100000 ; i++) asm volatile ("nop");
}

void Write_Camera(unsigned char reg,
		          unsigned char data) {
    volatile unsigned char busy;
	do {
		busy = IORD_8DIRECT(I2C_CORE_0_BASE,12);
	} while ((busy&3)!=0);
	IOWR_8DIRECT(I2C_CORE_0_BASE,0,0x60);
	IOWR_8DIRECT(I2C_CORE_0_BASE,4,reg);
	IOWR_8DIRECT(I2C_CORE_0_BASE,8,data);
	IOWR_8DIRECT(I2C_CORE_0_BASE,12,2);
}

void init_camera() {
	int i,busy;
	/* take modules out of sleep */
	IOWR_8DIRECT(CAMERA_BASE,12,0);
	delayms1();
	/* take module out of reset */
	IOWR_8DIRECT(CAMERA_BASE,12,1);
	delayms1();

//   /* Write device id */
//	IOWR_8DIRECT(I2C_CORE_0_BASE,0,0x60);
//	IOWR_8DIRECT(I2C_CORE_0_BASE,4,0x0A);
 //   /* Start 2 phase I2C transm. */
//	IOWR_8DIRECT(I2C_CORE_0_BASE,12,3);
//	do {
//		busy = IORD_8DIRECT(I2C_CORE_0_BASE,12);
//	} while ((busy&3)!=0);
//	delayms1();
//	IOWR_8DIRECT(I2C_CORE_0_BASE,0,0x61);
//   /* Start 2 phase I2C transm. */
//	IOWR_8DIRECT(I2C_CORE_0_BASE,12,3);
//	do {
//		busy = IORD_8DIRECT(I2C_CORE_0_BASE,12);
//	} while ((busy&3)!=0);
//	i = IORD_8DIRECT(I2C_CORE_0_BASE,8);
//	IOWR_8DIRECT(PIO_0_BASE,0,i);

	/* autodetect */
	IOWR_8DIRECT(I2C_CORE_0_BASE,12,4);
	do {
		busy = IORD_8DIRECT(I2C_CORE_0_BASE,12);
	} while ((busy&3)!=0);
	i = IORD_8DIRECT(I2C_CORE_0_BASE,4);
	IOWR_8DIRECT(PIO_0_BASE,0,i);

	/* initialize module */
    for (i=0;i<sizeof(camera_init);i++)
    	Write_Camera(i,camera_init[i]);


}

void camera_mode() {
	int buffer[CAMERA_IMAGE_SIZE_INT],i;

	IOWR_32DIRECT(CAMERA_BASE,16,(int)&buffer);
	while(1) {
		IOWR_8DIRECT(CAMERA_BASE,4,1);
		init_wait_lcd_dma();
		transfer_LCD_with_dma((unsigned char*)buffer,320,240,0);
		do {
		   i = IORD_32DIRECT(CAMERA_BASE,4);
		} while (i != 0);
		wait_lcd_dma_done();
	}
}

void camera_cont_mode_2buf() {
	int i;
	IOWR_32DIRECT(CAMERA_BASE,16,(int)&buffer3);
	IOWR_32DIRECT(CAMERA_BASE,20,(int)&buffer4);
	do {
	   i = IORD_32DIRECT(CAMERA_BASE,4);
	} while (i != 0);
	IOWR_8DIRECT(CAMERA_BASE,4,1<<3); //Enable IRQ's
	IOWR_8DIRECT(CAMERA_BASE,4,2); // Start cont mode
}

void camera_cont_mode_4buf() {
	int i;
	IOWR_32DIRECT(CAMERA_BASE,16,(int)&buffer1);
	IOWR_32DIRECT(CAMERA_BASE,20,(int)&buffer2);
	IOWR_32DIRECT(CAMERA_BASE,24,(int)&buffer3);
	IOWR_32DIRECT(CAMERA_BASE,28,(int)&buffer4);
	do {
	   i = IORD_32DIRECT(CAMERA_BASE,4);
	} while (i != 0);
	IOWR_8DIRECT(CAMERA_BASE,12,5); //Enable quad buffer
	IOWR_8DIRECT(CAMERA_BASE,4,1<<3); //Enable IRQ's
	IOWR_8DIRECT(CAMERA_BASE,4,2); // Start cont mode
}

void camera_stop_cont_mode() {
	int i;
	IOWR_32DIRECT(CAMERA_BASE,4,4);
	do {
	   i = IORD_32DIRECT(CAMERA_BASE,4);
	} while ((i&3) != 0);
}

int get_picture_addr() {
	return IORD_32DIRECT(CAMERA_BASE,8);
}