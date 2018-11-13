/*
 * main.c
 *
 *  Created on: 04.10.2018
 *      Author: gnm7
 */

// Please READ THE COMMENTS!!!

#include <stdio.h>
#include "io.h"
#include "system.h"
#include "io.h"
#include "time.h"
#include "unistd.h"
#include "tuxAnimation_1.h"
#include "tuxAnimation_2.h"
#include "tuxAnimation_3.h"

#define LCD_COMMAND_REG 0
#define LCD_DATA_REG 4
#define LCD_CONTROL_REG 8
#define LCD_IMAGE_POINTER_REG 12
#define LCD_IMAGE_SIZE_REG 16
#define LCD_NR_PIX_LINE_REG 20
#define LCD_Pict_width_reg 24

#define LCD_Sixteen_Bit 0
#define LCD_Eight_Bit 1
#define LCD_Reset 2
#define LCD_RGB565_Mode 0
#define LCD_RGB888_Mode (1<<3)
#define LCD_Color_Image 0
#define LCD_GrayScale_Image (1<<4)
#define LCD_IRQ_Disabled 0
#define LCD_IRQ_Enabled (1<<5)
#define LCD_Start_DMA (1<<8)
#define LCD_Clear_IRQ (1<<9)


void LCD_Write_Command(int command) {
	IOWR_16DIRECT(LCD_CONTROLLER_0_BASE,LCD_COMMAND_REG,command);
}

void LCD_Write_Data(int data) {
	IOWR_16DIRECT(LCD_CONTROLLER_0_BASE,LCD_DATA_REG,data);
}

void init_LCD() {

	IOWR_16DIRECT(LCD_CONTROLLER_0_BASE,LCD_CONTROL_REG,
			LCD_Sixteen_Bit|LCD_Reset|
			LCD_RGB565_Mode|LCD_Color_Image); // Set 16 bit transfer mode and reset

	LCD_Write_Command(0x0028);     //display OFF
	LCD_Write_Command(0x0011);     //exit SLEEP mode
	LCD_Write_Data(0x0000);

	LCD_Write_Command(0x00CB);     //Power Control A
	LCD_Write_Data(0x0039);        //always 0x39
	LCD_Write_Data(0x002C);        //always 0x2C
	LCD_Write_Data(0x0000);        //always 0x00
	LCD_Write_Data(0x0034);        //Vcore = 1.6V
	LCD_Write_Data(0x0002);        //DDVDH = 5.6V

	LCD_Write_Command(0x00CF);     //Power Control B
	LCD_Write_Data(0x0000);        //always 0x00
	LCD_Write_Data(0x0081);        //PCEQ off
	LCD_Write_Data(0x0030);        //ESD protection

	LCD_Write_Command(0x00E8);     //Driver timing control A
	LCD_Write_Data(0x0085);        //non - overlap
	LCD_Write_Data(0x0001);        //EQ timing
	LCD_Write_Data(0x0079);        //Pre-chargetiming
	LCD_Write_Command(0x00EA);     //Driver timing control B
	LCD_Write_Data(0x0000);        //Gate driver timing
	LCD_Write_Data(0x0000);        //always 0x00

	LCD_Write_Data(0x0064);        //soft start
	LCD_Write_Data(0x0003);        //power on sequence
	LCD_Write_Data(0x0012);        //power on sequence
	LCD_Write_Data(0x0081);        //DDVDH enhance on

	LCD_Write_Command(0x00F7);     //Pump ratio control
	LCD_Write_Data(0x0020);        //DDVDH=2xVCI

	LCD_Write_Command(0x00C0);     //power control 1
	LCD_Write_Data(0x0026);
	LCD_Write_Data(0x0004);        //second parameter for ILI9340 (ignored by ILI9341)

	LCD_Write_Command(0x00C1);     //power control 2
	LCD_Write_Data(0x0011);

	LCD_Write_Command(0x00C5);     //VCOM control 1
	LCD_Write_Data(0x0035);
	LCD_Write_Data(0x003E);

	LCD_Write_Command(0x00C7);     //VCOM control 2
	LCD_Write_Data(0x00BE);

	LCD_Write_Command(0x00B1);     //frame rate control
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0010);

	LCD_Write_Command(0x003A);     //pixel format = 16 bit per pixel
	LCD_Write_Data(0x0055);

	LCD_Write_Command(0x00B6);     //display function control
	LCD_Write_Data(0x000A);
	LCD_Write_Data(0x00A2);

	LCD_Write_Command(0x00F2);     //3G Gamma control
	LCD_Write_Data(0x0002);         //off

	LCD_Write_Command(0x0026);     //Gamma curve 3
	LCD_Write_Data(0x0001);

	LCD_Write_Command(0x0036);     //memory access control = BGR
	LCD_Write_Data(0x0000);

	LCD_Write_Command(0x002A);     //column address set
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0000);        //start 0x0000
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x00EF);        //end 0x00EF

	LCD_Write_Command(0x002B);     //page address set
	LCD_Write_Data(0x0000);
	LCD_Write_Data(0x0000);        //start 0x0000
	LCD_Write_Data(0x0001);
	LCD_Write_Data(0x003F);        //end 0x013F

	LCD_Write_Command(0x0029);

}

int main(){
	// Initialize the LCD-Panel
	init_LCD();

	// Init 2
	LCD_Write_Command(0x0029);

	while(1){
		for(int k = 1; k<=3; k++){
			printf("New Image %d\n", k);
			LCD_Write_Command(0x002C);

			for(int i = 0; i < 320; i++){
				for(int j = 0; j < 240; j++){
					if(k==1){
						LCD_Write_Data(picture_array_tuxAnimation_1[319-i][239-j]);
					}
					if(k==2){
						LCD_Write_Data(picture_array_tuxAnimation_2[319-i][239-j]);
					}
					if(k==3){
						LCD_Write_Data(picture_array_tuxAnimation_3[319-i][239-j]);
					}
				}
			}


		}
	}
}
