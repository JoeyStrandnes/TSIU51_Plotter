	.equ RGB_ENABLE =0x00
	.equ RGB_ATIME = 0x01
	.equ RGB_WTIME = 0x03
	.equ RGB_AILTL = 0x04
	.equ RGB_AILTH = 0x05
	.equ RGB_AIHTL = 0x06
	.equ RGB_AIHTH = 0x07
	.equ RGB_PERS  = 0x0C
	.equ RGB_CONFIG = 0x0D
	.equ RGB_CONTROL = 0x0F
	.equ RGB_ID = 0x12
	.equ RGB_STATUS = 0x13
	.equ RGB_CDATAL = 0x14
	.equ RGB_CDATAH = 0x15
	.equ RGB_RDATAL = 0x16
	.equ RGB_RDATAH = 0x17
	.equ RGB_GDATAL = 0x18
	.equ RGB_GDATAH = 0x19
	.equ RGB_BDATAL = 0x1A
	.equ RGB_BDATAH = 0x1B

	.equ RGB_SLAVE_ADDR = 0x29

	.equ RGB_COMMAND_BIT = 0x80

boot:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	call TWI_INIT
	jmp MAIN

TWI_INIT:
	ldi r16, 0xFF
	out DDRA, r16
	out DDRB, r16

	ldi r16, 0x00
	out TWBR, r16
	ldi r16, 0x02
	out TWSR, r16
	ret

MAIN:
/*
	ldi r17, RGB_SLAVE_ADDR
	call START_CONNECTION

	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ID
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ
	call TWI_READ_DATA
	
	call TWI_STOP_PULSE

	out PORTA, r17
*/

	ldi r17, RGB_SLAVE_ADDR
	call START_CONNECTION // including dummy read

	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ENABLE
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	ldi r17, 0b00001011 // AEN 1, PON 1
	call TWI_SEND_DATA

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ATIME
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	ldi r17, 0xC0
	call TWI_SEND_DATA

/*	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_STATUS
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ
CHECK_AGAIN:
	call TWI_READ_DATA
	sbrs r17, 0
	jmp CHECK_AGAIN
*/
/*	call DELAY_INIT
	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ID
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA
	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ
	call TWI_READ_DATA
	out PORTB, r17*/
READ_AGAIN:
	//call RGB_WAIT_FOR_COMPLETE_CONVERSION
	//call DELAY_INIT

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_GDATAH
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ

	call TWI_READ_DATA
	out PORTA, r17 // RED HIGH
///////////////////////////////

////////////////////////////////////

/*	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_GDATAH
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ

	call TWI_READ_DATA
	out PORTB, r17
*/
	//call TWI_STOP_PULSE

DONE:
	//call DELAY_INIT
	rjmp READ_AGAIN


TWI_READ_DATA:
	ldi r16, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?//////
	in r17, TWDR
	ret

TWI_SEND_DATA:
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skjut!
	call TWI_WAIT
	/////ERROR?/////
	ret

START_CONNECTION:
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE
	call TWI_STOP_PULSE
	call TWI_START_PULSE
	ret

SEND_ADDRESS_WRITE:
	lsl r17
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?///
	ret

SEND_ADDRESS_READ:
	lsl r17
	ori r17, 1
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?/////
	ret

TWI_START_PULSE:
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start
	call TWI_WAIT
	ret

TWI_STOP_PULSE:
	ldi r16, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
	out TWCR, r16 //stop
	ret

TWI_WAIT:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp TWI_WAIT
	ret
///////////////////////////////////////////////////
RGB_WAIT_FOR_COMPLETE_CONVERSION:
	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_STATUS
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	ldi r17, RGB_SLAVE_ADDR
	call SEND_ADDRESS_READ
RGB_WAIT_FOR_COMPLETE_CONVERSION_AGAIN:
	call TWI_READ_DATA
	sbrs r17, 0
	jmp RGB_WAIT_FOR_COMPLETE_CONVERSION_AGAIN
	ret
/////////////////////////////////////////////////////
DELAY_INIT:
	ldi r16, 0xFF
	ldi r17, 0xFF
DELAY_INIT1:
	dec r16
	brne DELAY_INIT1
DELAY_INIT2:
	dec r17
	brne DELAY_INIT1
	ret