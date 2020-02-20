
	.equ RS = 0
	.equ RW = 1
	.equ E = 2
	.equ Clear_Display = 0b00000001
	.org 0
	jmp INIT
	.org TWIaddr
	jmp ISR_TWI


INIT:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	//call INIT_CLEAR_SRAM NOT USED 
	
	call TWI_SLAVE_INIT
	call LCD_SETUP
	sei
	jmp MAIN

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

MAIN:
	ldi r20, 'W'
	call LCD_DATA_WRITE
	ldi r20, 'A'
	call LCD_DATA_WRITE
	ldi r20, 'I'
	call LCD_DATA_WRITE
	ldi r20, 'T'
	call LCD_DATA_WRITE
	ldi r20, '.'
	call LCD_DATA_WRITE
	ldi r20, '.'
	call LCD_DATA_WRITE
	ldi r20, '.'
	call LCD_DATA_WRITE
MAIN_LOOP:
	jmp MAIN_LOOP


///////////////////////////////////////////////////////////////////////////////////////////////////////////////

TWI_SLAVE_INIT:
	ldi r16, 0b11010010 //0x69 but shifted
	out TWAR, r16	
	ldi r16, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)|(1<<TWIE)
	out TWCR, r16
	ret

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
ISR_TWI:
	push r16
	in r16, SREG
	push r16

	in r16, TWSR
	cpi r16, 0x80
	brne NO_DATA
	in r17, TWDR
	call LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN
NO_DATA:
	ldi r16, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)|(1<<TWIE)
	out TWCR, r16

	
	pop r16
	out SREG, r16
	pop r16
	reti

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

	TWI_WAIT:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp TWI_WAIT
	ret


//////////////MEMORY LAYOUT////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
INIT_CLEAR_SRAM:
	ldi r17, 6 //NUMBER OF BYTES TO CLEAR
	ldi r16, 0xC0 //SHOULD BE 0 but for debug purpse atm
	ldi YH,HIGH(SRAM_START)
	ldi YL,LOW(SRAM_START)
INIT_CLEAR_SRAM_LOOP:
	st Y+, r16
	dec r17
	brne INIT_CLEAR_SRAM_LOOP
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_SETUP:	
	ldi r16, 0x00
	out DDRA, r16 // DB0-DB7 set to READMODE as default, will change briefly when writing.
	ldi r16, 0x07 
	out DDRB, r16 // PIN0 - RS, PIN1- R/W, PIN2 - E set to WRITEMODE, will not change.

	ldi r20, 0b00111100 // 2_line_5x8_mode 
	call LCD_INSTRUCTION_WRITE
	
	ldi r20, 0b00001100 // DISPLAY ON, CURSOR ON, BLINK OFF
	call LCD_INSTRUCTION_WRITE
	
	ldi r20, Clear_Display 
	call LCD_INSTRUCTION_WRITE

	ldi r20, 0b00000110 // INCREMENT MODE, ENTIRE SHIFT OFF
	call LCD_INSTRUCTION_WRITE 
	// INIT DONE
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TODO: MAKE IT TAKE REGISTER AND MAKE ANOTHER FUNCTION FOR Y-POINTER?
LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN: //LOADS FROM SRAM WITH Y-POINTER AS ARGUMENT, DDRAM ADRESS SHOULD BE SET BEFORE WITH AUTO INC-MODE! 
	push r16
	push r17
	ldi r16, 8
	//ld r17, Y
LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN_LOOP:	
	lsl r17
	brcc LCD_OUTPUT_BIT_AS_ZERO
	ldi r20, '1'
	rjmp LCD_OUTPUT_BIT
LCD_OUTPUT_BIT_AS_ZERO:
	ldi r20, '0'
LCD_OUTPUT_BIT:
	call LCD_DATA_WRITE
	dec r16
	brne LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN_LOOP

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
	call WAIT_IF_BUSY
	pop r19
	pop r16
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
WAIT_IF_BUSY:
	ldi r16, (1<<E)|(1<<RW)|(0<<RS)
	out PORTB, r16 //E PULSE STARTS
	andi r16, 0xFB //FILTER OUT E 
	nop
	out PORTB, r16 //E PULSE STOPS
	
	sbic PINA, 7
	rjmp WAIT_IF_BUSY
	ret


///////////////////////////////////////////////////////////////////////////////////////////////////////////////

DELAY01:
	ldi r16, 0xFF
	ldi r17, 0xFF
DELAY01_LOOP:
	dec r16
	brne DELAY01_LOOP
	dec r17
	brne DELAY01_LOOP
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////