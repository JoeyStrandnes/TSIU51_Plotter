

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
	.equ ATIME_VALUE = 0xF6 // NUMBER OF INTEGRATION CYCLES = 256-ATIME_VALUE (0xFF+1 -ATIME_VALUE) WITH EACH CYCLE TAKING 2.4 ms 
	.equ GAIN_VALUE  = 0x01 //00=1X, 01=4X, 10=16X, 11=60X
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
//////////// LCD CONSTANTS ////////////
	.equ RS = 0
	.equ RW = 1
	.equ E = 2
	.equ Clear_Display = 0b00000001
	.equ Return_Home   = 0b00000010
	.equ Second_Line_Address = 0b11000000
//////////// MEMORY LAYOUT ////////////
	.dseg
	.org 0x0060 //SRAM_START
// LATEST RGB-VALUES 
CDATAL:	.byte 1
CDATAH:	.byte 1
RDATAL:	.byte 1
RDATAH:	.byte 1
GDATAL:	.byte 1
GDATAH:	.byte 1
BDATAL:	.byte 1
BDATAH:	.byte 1
// CURRENT SLAVE //////////
CURRENT_SLAVE:
	.byte 1
//LATEST COLOR_DIFFERENCES ///
RED_DIFF:
	.byte 1
GREEN_DIFF:
	.byte 1
ORANGE_DIFF:
	.byte 1
PURPLE_DIFF:
	.byte 1
YELLOW_DIFF:
	.byte 1
//LAST MATCHING SKITTLE SORTED 0-4 /// 
LATEST_SKITTLE_COLOR:
	.byte 1
//NUMBER OF SKITTLES SORTED ///
RED_N:
	.byte 1
GREEN_N:
	.byte 1
ORANGE_N:
	.byte 1
PURPLE_N:
	.byte 1
YELLOW_N:
	.byte 1
	.cseg
////////////////////////////////////////
// Reset/Interupt Vectors //////////////
.org 0
jmp BOOT
.org INT0ADDR
jmp ISR_INT0

.org 0x02A
BOOT:

	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	///////////////
	//ldi r16, 0xFF
	//out DDRD, r16
	///////////////
	call INIT_CLEAR_SRAM // puts zeroes in the first N bytes
	call TWI_INIT
	call RGB_INIT //Current slave is now the RGB-sensor
	call INT0_INIT
	call LCD_INIT
	call UPDATE_DISPLAY
	//sei 

	clr r22 // TEST MED KNAPP
	jmp MAIN

///////////////////////////////////////////////////////////////////

MAIN:	
	//ldi r16, 0
	//out PORTD, r16
DONE:
	

	/*ldi r16, 200
	sts RDATAL, r16
	sts GDATAL, r16
	sts BDATAL, r16
	ldi r16, 0x69
	sts CURRENT_SLAVE, r16*/

	call READ_ALL_8_RGB_REGISTERS_INTO_SRAM
	call NORMALIZE
	//call COMPARE
	//call COLOR_MATCH
	//call INIT_CLEAR_SRAM
	rjmp DONE



///////////////////////////////////////////////////////////////////
NORMALIZE:
/*
*TA VÄRDEN
*LSL TÄLJARE
*DIVIDERA TÄLJARE MED NÄMNARE
*KLART
*/

/*
lds dd16uL, RDATAL
lds dd16uH, RDATAH
lsl 

lds dv16uL, CDATAL
lds dv16uH, CDATAH

call div16u
*/
ret


///////////////////////////////////////////////////////////////////
	.equ OFFSET = 5
RED:
	.equ RED_CLEAR = 631
	.equ RED_RED = 222
	.equ RED_GREEN = 202
	.equ RED_BLUE = 184

GREEN:
	.equ GREEN_CLEAR = 666
	.equ GREEN_RED = 203
	.equ GREEN_GREEN = 242
	.equ GREEN_BLUE = 195

YELLOW:
	.equ YELLOW_CLEAR = 731
	.equ YELLOW_RED = 255
	.equ YELLOW_GREEN = 249
	.equ YELLOW_BLUE = 204

ORANGE:
	.equ ORANGE_CLEAR = 673
	.equ ORANGE_RED = 244
	.equ ORANGE_GREEN = 215
	.equ ORANGE_BLUE = 190

PURPLE:
	.equ PURPLE_CLEAR = 591
	.equ PURPLE_RED = 185
	.equ PURPLE_GREEN = 198
	.equ PURPLE_BLUE = 182

///////////////////////////////////////////////////////////////////
COMPARE:
	ldi ZH, HIGH(REF_VALUES*2)
	ldi ZL, LOW(REF_VALUES*2)
	ldi XH, HIGH(RED_DIFF)
	ldi XL, LOW(RED_DIFF)

	ldi r16, 5 //LOOP COUNTER: NUMBER OF DIFFERENT COLORS
COMPUTE_NEXT_SKITTLE_DIFFERENCE:
	
	ldi YH, HIGH(RDATAL)
	ldi YL, LOW(RDATAL)
	call COMPUTE_REF_DIFF //COMPUTE RED DIFFERENCE FROM RED SKITTLE
	call SAVE_DIFFERENCE

	adiw YH:YL, 2
	call COMPUTE_REF_DIFF //COMPUTE GREEN DIFFERENCE FROM RED SKITTLE
	call SAVE_DIFFERENCE

	adiw YH:YL, 2
	call COMPUTE_REF_DIFF //COMPUTE BLUE DIFFERENCE FROM RED SKITTLE
	call SAVE_DIFFERENCE

	adiw XH:XL, 1
	dec r16
	brne COMPUTE_NEXT_SKITTLE_DIFFERENCE
	ret

///////////////////////////////////////////////////////////////////
COLOR_MATCH:
	ldi XH, HIGH(RED_DIFF) //X PEKAR PÅ MINSTA VÄRDET
	ldi XL, LOW(RED_DIFF)
	ldi YH, HIGH(GREEN_DIFF)
	ldi YL, LOW(GREEN_DIFF)
	ldi r18, 4 //LOOP COUNTER: 5-1
	clr r19 // 0 = RED, osv...
COLOR_MATCH_NEXT_SKITTLE:
	ld r16, X
	ld r17, Y
	// X < Y ?
	cp r16, r17
	brmi X_POINTER_STAYS
	brlo X_POINTER_STAYS
	mov XH, YH
	mov XL, YL
	//inc r19
X_POINTER_STAYS:
	adiw YH:YL, 1
	dec r18
	brne COLOR_MATCH_NEXT_SKITTLE
	subi XL, LOW(RED_DIFF) // GET OFFSET FOR COLOR 
	sts LATEST_SKITTLE_COLOR, XL
	ret


///////////////////////////////////////////////////////////////////

SAVE_DIFFERENCE:
	push r16
	ld r16, X // GET PREVIOUS VALUE IN SRAM
	cpi r25, 0 //DIFF BIGGER THAN 255 ??
	brne BOGUS_VALUE
	add r16, r24
	brcs BOGUS_VALUE
	jmp SAVE_DIFFERENCE_DONE
BOGUS_VALUE:
	ldi r24, 0xFF

SAVE_DIFFERENCE_DONE:
	st X, r16
	pop r16
	ret
///////////////////////////////////////////////////////////////////
COMPUTE_REF_DIFF:	
	push YH
	push YL
	push r16
	push r17

	lpm r16, Z+ //LOW BYTE
	lpm r17, Z+ //HIGH BYTE

	ld r24, Y+
	ld r25, Y
	sub r24, r16 //COMPARE TO CONSTANTS
	sbc r25, r17	//COMPARE TO CONSTANTS
	brcc NO_UNDERFLOW
	neg r24
	com r25
NO_UNDERFLOW:
	pop r17
	pop r16
	pop YL
	pop YH
	ret
	


///////////////////////////////////////////////////////////////////
//I den färdiga produkten ska denna interupten triggas på att trumman är tillbaka i utgångsläge från 
// MC-Slaven på något sätt. Då ska den göra följande:
// 1. Vänta en hel RGB-cykel för att få rätt färgdata. Skittlen trillar ju inte ner framför sensorn förrän trumman är tillbaka
// 2. Läsa av färg-data på Skittlen.
// 3. Konvertera det till en av de 5 olika färgerna eller en felkod för: "ingen skittle framför sensorn" 
// 4. Uppdatera skärmen med nya antalet Skittles - Eventuellt vänta med uppdateringen till nästa gång trumman är tillbaka.
// Det ger uppräkning efter att Skittlen trillat ner i sin ränna. Då ska detta steget utföras först.
// 5. Skicka vilken färg på Skittle till MC-Slaven för sortering.
ISR_INT0:
	push r16
	in r16, SREG
	push r16
	push r17
	call READ_ALL_8_RGB_REGISTERS_INTO_SRAM
	sts RED_N, r22 // TEST
	call UPDATE_DISPLAY

	ldi r16, MCU_SLAVE_ADDR
	sts CURRENT_SLAVE, r16
	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	mov r17, r22 //TESTGREJ
	call TWI_SEND_DATA
	call TWI_STOP_PULSE

	inc r22
	cpi r22, 5
	brne TEST_RESET_REG
	clr r22
TEST_RESET_REG:
	
	pop r17
	pop r16
	out SREG, r16
	pop r16
	reti
///////////////////////////////////////////////////////////////////
INT0_INIT:
	push r16
	ldi r16, (1<<ISC01) | (1<<ISC00)
	out MCUCR, r16
	ldi r16, (1<<INT0)
	out GICR, r16
	pop r16
	ret
///////////////////////////////////////////////////////////////////
INIT_CLEAR_SRAM:
	ldi r17, 20 //NUMBER OF BYTES TO CLEAR
	ldi r16, 0 //SHOULD BE 0 but for debug purpse atm
	ldi YH,HIGH(SRAM_START)
	ldi YL,LOW(SRAM_START)
INIT_CLEAR_SRAM_LOOP:
	st Y+, r16
	dec r17
	brne INIT_CLEAR_SRAM_LOOP
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

	ldi r17, RGB_CONTROL | RGB_COMMAND_BIT
	call TWI_SEND_DATA 

	ldi r17, GAIN_VALUE
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
	ldi r16, (1<<TWEN)
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

READ_ALL_8_RGB_REGISTERS_INTO_SRAM:
	push YH
	push YL
	push r16
	push r17
	ldi r16, RGB_SLAVE_ADDR
	sts CURRENT_SLAVE, r16

	call TWI_START_PULSE
	call SEND_ADDRESS_WRITE

	ldi r17, RGB_CDATAL |  RGB_COMMAND_BIT | RGB_AUTO_INC_BIT
	call TWI_SEND_DATA

	call TWI_START_PULSE
	call SEND_ADDRESS_READ
	ldi r16, 7 //Number of registers -1
	ldi YH, HIGH(CDATAL)
	ldi YL, LOW(CDATAL)

READ_NEXT_RBG_REGISTER:
	call TWI_READ_DATA_ACK
	st  Y+, r17
	//call RBG_DELAY_INTEGRATION onödig!!
	dec r16
	brne READ_NEXT_RBG_REGISTER
	
	call TWI_READ_DATA_NACK //Last READ WITH A NACK
	st  Y, r17
	call TWI_STOP_PULSE

	pop r17
	pop r16
	pop YL
	pop YH
	ret
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_INIT:	
	ldi r16, 0x00
	out DDRA, r16 // DB0-DB7 set to READMODE as default, will change briefly when writing.
	ldi r16, 0x07 
	out DDRB, r16 // PIN0 - RS, PIN1- R/W, PIN2 - E set to WRITEMODE, will not change.

	ldi r20, 0b00111100 // 2_line_5x8_mode 
	call LCD_INSTRUCTION_WRITE

	call RGB_DELAY //REUSING DELAY FUNCTION

	ldi r20, 0b00001100 // DISPLAY ON, CURSOR ON, BLINK OFF
	call LCD_INSTRUCTION_WRITE
	
	call RGB_DELAY //REUSING DELAY FUNCTION

	ldi r20, Clear_Display 
	call LCD_INSTRUCTION_WRITE

	call RGB_DELAY //REUSING DELAY FUNCTION

	ldi r20, 0b00000110 // INCREMENT MODE, ENTIRE SHIFT OFF
	call LCD_INSTRUCTION_WRITE 
	// INIT DONE
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
UPDATE_DISPLAY:
	push r20
	push YH
	push YL

	ldi r20, 'R'
	call LCD_DATA_WRITE
	ldi r20, ':'
	call LCD_DATA_WRITE
	ldi YH, HIGH(RED_N)
	ldi YL, LOW(RED_N)
	call OUTPUT_DISPLAY_BYTE_TO_BCD

	ldi r20, ' '
	call LCD_DATA_WRITE

	ldi r20, 'G'
	call LCD_DATA_WRITE
	ldi r20, ':'
	call LCD_DATA_WRITE
	ldi YH, HIGH(GREEN_N)
	ldi YL, LOW(GREEN_N)
	call OUTPUT_DISPLAY_BYTE_TO_BCD
	
	ldi r20, Second_Line_Address
	call LCD_INSTRUCTION_WRITE

	ldi r20, 'O'
	call LCD_DATA_WRITE
	ldi r20, ':'
	call LCD_DATA_WRITE
	ldi YH, HIGH(ORANGE_N)
	ldi YL, LOW(ORANGE_N)
	call OUTPUT_DISPLAY_BYTE_TO_BCD

	ldi r20, ' '
	call LCD_DATA_WRITE

	ldi r20, 'P'
	call LCD_DATA_WRITE
	ldi r20, ':'
	call LCD_DATA_WRITE
	ldi YH, HIGH(PURPLE_N)
	ldi YL, LOW(PURPLE_N)
	call OUTPUT_DISPLAY_BYTE_TO_BCD

	
	ldi r20, ' '
	call LCD_DATA_WRITE

	ldi r20, 'Y'
	call LCD_DATA_WRITE
	ldi r20, ':'
	call LCD_DATA_WRITE
	ldi YH, HIGH(YELLOW_N)
	ldi YL, LOW(YELLOW_N)
	call OUTPUT_DISPLAY_BYTE_TO_BCD

	ldi r20, Return_Home //SETS CURSOR BACK AT START OF LINE 1
	call LCD_INSTRUCTION_WRITE
	
	pop YL
	pop YH
	pop r20
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
OUTPUT_DISPLAY_BYTE_TO_BCD:
	push r16
	push r17
	push r20
	clr r17 
	ld r16, Y
LOOP_AGAIN:
	subi r16, 10 //LESS THAN 10?
	brmi DIGITS_DONE
	inc r17
	jmp LOOP_AGAIN
	
DIGITS_DONE:
	subi r16, -10 //RESTORE ONE'S POSITION

	mov r20, r17 //MOVE TEN'S POSITION INTO LCD-REGISTER
	subi r20, -48 //ADD ASCII OFFSET
	call LCD_DATA_WRITE //WRITE TEN'S POSITION

	mov r20, r16 //MOVE ONE'S POSITION INTO LCD-REGISTER
	subi r20, -48 //ADD ASCII OFFSET
	call LCD_DATA_WRITE //WRITE ONE'S POSITION 

	pop r20
	pop r17
	pop r16
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_INSTRUCTION_WRITE:
	push r19
	ldi r19, (0<<E)|(0<<RW)|(0<<RS) 
	out PORTB, r19 
	call LCD_WRITE
	pop r19
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_DATA_WRITE:
	push r19
	ldi r19, (0<<E)|(0<<RW)|(1<<RS) 
	out PORTB, r19 
	call LCD_WRITE
	pop r19
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_WRITE: //RS = 1 IS DATA, RS = 0 IS INSTRUCTION.  FINDS IF INSTR OR DATA IN r19...change?
	push r16
	push r19
	ldi r16, 0xFF
	out DDRA, r16 // PORTA NOW IN WRITE MODE
	out PORTA, r20 // DATA/INSTRUCTION TO BE WRITTEN IS IN R20, MIGHT CHANGE TO STACK ARGUMENT?

	ori r19, (1<<E)
	out PORTB, r19 //E PULSE STARTS
	nop
	andi r19, 0xFB //FILTER OUT E 
	out PORTB, r19 //E PULSE STOPS

	ldi r16, 0x00
	out DDRA, r16 // PORTA NOW IN READ MODE

	ldi r16, (1<<RW)
	out PORTB, r16 // LCD PUT INTO READMODE
	call LCD_WAIT_IF_BUSY
	pop r19
	pop r16
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_WAIT_IF_BUSY:
	ldi r16, (1<<E)|(1<<RW)|(0<<RS)
	out PORTB, r16 //E PULSE STARTS
	andi r16, 0xFB //FILTER OUT E 
	out PORTB, r16 //E PULSE STOPS
	sbic PINA, 7
	rjmp LCD_WAIT_IF_BUSY
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:196 + return
;* Number of cycles	:148/173/196 (Min/Avg/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :4 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem16uL=r14
.def	drem16uH=r15
.def	dres16uL=r16
.def	dres16uH=r17
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19

;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry

	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_1		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_2		;else
d16u_1:	sec			;    set carry to be shifted into result

d16u_2:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_4		;else
d16u_3:	sec			;    set carry to be shifted into result

d16u_4:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_5		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_6		;else
d16u_5:	sec			;    set carry to be shifted into result

d16u_6:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_7		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_8		;else
d16u_7:	sec			;    set carry to be shifted into result

d16u_8:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_9		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_10		;else
d16u_9:	sec			;    set carry to be shifted into result

d16u_10:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_11		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_12		;else
d16u_11:sec			;    set carry to be shifted into result

d16u_12:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_13		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_14		;else
d16u_13:sec			;    set carry to be shifted into result

d16u_14:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_15		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_16		;else
d16u_15:sec			;    set carry to be shifted into result

d16u_16:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_17		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_18		;else
d16u_17:	sec			;    set carry to be shifted into result

d16u_18:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_19		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_20		;else
d16u_19:sec			;    set carry to be shifted into result

d16u_20:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_21		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_22		;else
d16u_21:sec			;    set carry to be shifted into result

d16u_22:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_23		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_24		;else
d16u_23:sec			;    set carry to be shifted into result

d16u_24:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_25		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_26		;else
d16u_25:sec			;    set carry to be shifted into result

d16u_26:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_27		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_28		;else
d16u_27:sec			;    set carry to be shifted into result

d16u_28:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_29		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_30		;else
d16u_29:sec			;    set carry to be shifted into result

d16u_30:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_31		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_32		;else
d16u_31:sec			;    set carry to be shifted into result

d16u_32:rol	dd16uL		;shift left dividend
	rol	dd16uH
	ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
.org 0x1900 //LÅNGT IFRÅN ALLT BYTEL, BYTEH
REF_VALUES:
	.db LOW(RED_RED), HIGH(RED_RED), LOW(RED_GREEN), HIGH(RED_GREEN), LOW(RED_BLUE), HIGH(RED_BLUE)
	.db LOW(GREEN_RED), HIGH(GREEN_RED), LOW(GREEN_GREEN), HIGH(GREEN_GREEN), LOW(GREEN_BLUE), HIGH(GREEN_BLUE)
	.db LOW(YELLOW_RED), HIGH(YELLOW_RED), LOW(YELLOW_GREEN), HIGH(YELLOW_GREEN), LOW(YELLOW_BLUE), HIGH(YELLOW_BLUE)
	.db LOW(ORANGE_RED), HIGH(ORANGE_RED), LOW(ORANGE_GREEN), HIGH(ORANGE_GREEN), LOW(ORANGE_BLUE), HIGH(ORANGE_BLUE)
	.db LOW(PURPLE_RED), HIGH(PURPLE_RED), LOW(PURPLE_GREEN), HIGH(PURPLE_GREEN), LOW(PURPLE_BLUE), HIGH(PURPLE_BLUE)
