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
	.equ RGB_AUTO_INC_BIT = 0b00100000
	.dseg
	.org 0x0060 //SRAM_START
CURRENT_SLAVE:
	.byte 1
RDATAL:	.byte 1
RDATAH:	.byte 1
GDATAL:	.byte 1
GDATAH:	.byte 1
BDATAL:	.byte 1
BDATAH:	.byte 1
	.cseg
boot:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	ldi r16, 0xFF
	out DDRA, r16
	ldi r16, 0x00
	out PORTA, r16

	call TWI_INIT
	jmp MAIN

TWI_INIT:
	ldi r16, 0x0F
	out TWBR, r16
	ldi r16, 0x02
	out TWSR, r16
	ret

MAIN:
	call DELAY_INIT
	ldi r17, RGB_SLAVE_ADDR
	sts CURRENT_SLAVE, r17
	call START_CONNECTION

	call SEND_ADDRESS_WRITE
	ldi r17, RGB_ENABLE
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA

	ldi r17, 0b00000011
	call TWI_SEND_DATA

	call READ_ALL_6_RGB_REGISTERS
DONE:
	rjmp DONE

///////////////////////////////////////////////////////////
READ_ALL_6_RGB_REGISTERS:
	call TWI_START_PULSE
	call SEND_ADDRESS_READ

	ldi r17, RGB_RDATAL
	ori r17, RGB_COMMAND_BIT
	ori r17, RGB_AUTO_INC_BIT
	call TWI_SEND_DATA

	call DELAY_INIT
	ldi r18, 5
	ldi YH, HIGH(RDATAL)
	ldi YL, LOW(RDATAL)
READ_NEXT_RBG_REGISTER:
	call TWI_READ_DATA
	st  Y+, r17
	call DELAY_INIT
	dec r18
	brne READ_NEXT_RBG_REGISTER
	//call TWI_READ_DATA //KANSKE DENNA?
	call TWI_READ_DATA_NACK //Last READ WITH A NACK
	st  Y, r17
	call TWI_STOP_PULSE
	ret
///////////////////////////////////////////////////////////

TWI_READ_DATA:
	ldi r16, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?//////
	in r17, TWDR
	ret

TWI_READ_DATA_NACK:
	ldi r16, (1<<TWINT) | (1<<TWEN) //| (1<<TWEA)
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
	lds r17, CURRENT_SLAVE
	lsl r17
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?///
	ret

SEND_ADDRESS_READ:
	lds r17, CURRENT_SLAVE
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