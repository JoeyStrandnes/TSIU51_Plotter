//////////// RBG_SENSOR STATIC REGISTERS ///////
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

	.equ RGB_COMMAND_BIT = 0x80
	.equ RGB_AUTO_INC_BIT = 0b00100000

////////// RGB-SENSOR USER CONFIG ////
	.equ ATIME_VALUE = 0x00 // NUMBER OF INTEGRATION CYCLES = 256-ATIME_VALUE (0xFF+1 -ATIME_VALUE) WITH EACH CYCLE TAKING 2.4 ms 
////////// TWI USER CONFIG ////
	.equ TWI_BITRATE = 32  //100kHz
	.equ TWI_PRESCALAR = 0 //100kHz
////////// TWI SLAVE ADDR ///////////
	.equ RGB_SLAVE_ADDR = 0x29
	.equ MCU_SLAVE_ADDR = 0x69

//////// TWI TWSR HANDLING CODES ///	
	.equ TWSR_TWI_START = 0x08
	.equ TWSR_TWI_REP_START		= 0x10
	.equ TWSR_MT_SLA_ACK		= 0x18
	.equ TWSR_MT_SLA_NACK		= 0x20 //PROBLEM
	.equ TWSR_MT_DATA_ACK		= 0x28
	.equ TWSR_MT_DATA_NACK		= 0x30 //PROBLEM
	.equ TWSR_ARBITRATION_LOST	= 0x38 //PROBLEM

	.equ TWSR_MR_SLA_ACK		= 0x40
	.equ TWSR_MR_SLA_NACK		= 0x48 //PROBLEM
	.equ TWSR_MR_DATA_ACK		= 0x50
	.equ TWSR_MR_DATA_NACK		= 0x58

//////////// MEMORY LAYOUT ////////////
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
////////////////////////////////////////
boot:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	
	call TWI_INIT
	call RGB_INIT //Current slave is now the RGB-sensor
	jmp MAIN

///////////////////////////////////////////////////////////////////

MAIN:

	//ldi r16, 0xFF
	//out DDRA, r16 //Lågdelen
	//out DDRB, r16 //Högdelen


	
/*	ldi r18, 5
DO_FIVE_READS:
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE
	ldi r17, RGB_RDATAL | RGB_COMMAND_BIT | RGB_AUTO_INC_BIT
	call TWI_SEND_DATA
	
	call TWI_START_PULSE
	call SEND_ADDRESS_READ
	call TWI_READ_DATA_ACK //READS RDATAL
	out PORTA, r17
	//call RBG_DELAY_INTEGRATION
	call TWI_READ_DATA_NACK //READS RDATAH
	out PORTB, r17
	call RBG_DELAY_INTEGRATION
	dec r18
	brne DO_FIVE_READS
*/	call READ_ALL_6_RGB_REGISTERS
	call RGB_SHUTDOWN
DONE:
	rjmp DONE
///////////////////////////////////////////////////////////////////

TWI_ERROR_HANDLING: //HUR LÖSER VI DETTA? :D
	ret
///////////////////////////////////////////////////////////////////
RGB_INIT:
	push r17
	ldi r17, RGB_SLAVE_ADDR
	sts CURRENT_SLAVE, r17
	//
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ENABLE | RGB_COMMAND_BIT
	call TWI_SEND_DATA 

	ldi r17, 0b00000001 //PON
	call TWI_SEND_DATA
	call RGB_DELAY // MUST WAIT 2.4 ms after PON
	//
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ATIME | RGB_COMMAND_BIT
	call TWI_SEND_DATA 

	ldi r17, ATIME_VALUE //ATIME
	call TWI_SEND_DATA
	//
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ENABLE | RGB_COMMAND_BIT
	call TWI_SEND_DATA 

	ldi r17, 0b00000011 //AEN,PON
	call TWI_SEND_DATA
	//
	call TWI_STOP_PULSE
	call RBG_DELAY_INTEGRATION //WAITS SO THE RGB-REGISTERS ARE VALID
	call RBG_DELAY_INTEGRATION //
	call RBG_DELAY_INTEGRATION //EXTRA SAFETY
	pop r17
	ret
///////////////////////////////////////////////////////////////////
RGB_SHUTDOWN:
	push r17
	ldi r17, RGB_SLAVE_ADDR
	sts CURRENT_SLAVE, r17

	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_ENABLE
	ori r17, RGB_COMMAND_BIT
	call TWI_SEND_DATA 

	ldi r17, 0b00000000 //TURN OFF
	call TWI_SEND_DATA
	call TWI_STOP_PULSE
	pop r17
	ret

///////////////////////////////////////////////////////////////////
TWI_INIT: //SCL FREQ = MC CPU FREQ/(16+2*TWBR *4^TWPS) 
	push r16
	ldi r16, TWI_BITRATE   
	out TWBR, r16
	ldi r16, TWI_PRESCALAR 
	out TWSR, r16
	ldi r16, (1<<TWEN) //onödigt?
	out TWCR, r16
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_READ_DATA_ACK: // READS DATA INTO R17
	push r16
	ldi r16, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?//////
	in r17, TWDR
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_READ_DATA_NACK: // READS DATA INTO R17
	push r16
	ldi r16, (1<<TWINT) | (1<<TWEN) 
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?//////
	in r17, TWDR
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_SEND_DATA: // EXPECTS DATA TO SEND IN R17
	push r16
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 
	call TWI_WAIT
	/////ERROR?/////
	pop r16
	ret
///////////////////////////////////////////////////////////////////
START_CONNECTION:
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE
	call TWI_STOP_PULSE
	call TWI_START_PULSE
	ret
///////////////////////////////////////////////////////////////////
SEND_ADDRESS_WRITE: // LOOKS IN SRAM FOR CURRENT ADDRESSED SLAVE
	push r16
	push r17
	lds r17, CURRENT_SLAVE
	lsl r17
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?///
	pop r17
	pop r16
	ret
///////////////////////////////////////////////////////////////////
SEND_ADDRESS_READ: // LOOKS IN SRAM FOR CURRENT ADDRESED SLAVE
	push r16
	push r17
	lds r17, CURRENT_SLAVE
	lsl r17
	ori r17, 1
	out TWDR, r17
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16
	call TWI_WAIT
	/////ERROR?/////
	pop r17
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_START_PULSE:
	push r16
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start
	call TWI_WAIT
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_STOP_PULSE:
	push r16
	ldi r16, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
	out TWCR, r16 //stop
	pop r16
	ret
///////////////////////////////////////////////////////////////////
TWI_WAIT:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp TWI_WAIT
	ret
///////////////////////////////////////////////////////////////////
RGB_DELAY://2.4 ms delay at 8MHz. This is the time each integration cycle of the RGB-sensor takes.
	push r16
	push r17
	ldi  r16, 25
	ldi  r17, 255 //239
RGB_DELAY_LOOP:
	dec  r17
	brne RGB_DELAY_LOOP
	dec  r16
	brne RGB_DELAY_LOOP
	pop r17
	pop r16
	ret

///////////////////////////////////////////////////////////////////
RBG_DELAY_INTEGRATION:  //NUMBER OF INTEGRATION CYCLES = 256-ATIME_VALUE (0xFF+1-ATIME_VALUE). EACH INTEGRATION CYCLE TAKES 2.4 ms		
	push r16
	call RGB_DELAY //LOOPS ONCE IN ALL CASES
	ldi r16, 0xFF-ATIME_VALUE
	cpi r16, 0 //SPECIAL CASE OF ATIME_VALUE == 0xFF
	breq RBG_DELAY_INTEGRATION_DONE

RBG_DELAY_INTEGRATION_LOOP:
	call RGB_DELAY
	dec r16
	brne RBG_DELAY_INTEGRATION_LOOP

RBG_DELAY_INTEGRATION_DONE:
	pop r16
	ret
///////////////////////////////////////////////////////////////////

READ_ALL_6_RGB_REGISTERS:
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_RDATAL
	ori r17, RGB_COMMAND_BIT
	ori r17, RGB_AUTO_INC_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	call SEND_ADDRESS_READ
	ldi r18, 5 //Number of registers -1
	ldi YH, HIGH(RDATAL)
	ldi YL, LOW(RDATAL)
READ_NEXT_RBG_REGISTER:
	call TWI_READ_DATA_ACK
	st  Y+, r17
	call RBG_DELAY_INTEGRATION
	dec r18
	brne READ_NEXT_RBG_REGISTER
	
	call TWI_READ_DATA_NACK //Last READ WITH A NACK
	st  Y, r17
	call TWI_STOP_PULSE
	ret
