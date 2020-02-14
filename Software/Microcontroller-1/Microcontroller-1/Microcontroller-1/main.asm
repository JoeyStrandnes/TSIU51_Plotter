	.equ E = 0
	.equ RW = 1
	.equ RS = 2
	.equ Clear_Display = 0b00000001

//////////////MEMORY LAYOUT////////////////////////////////////////////////////////
	.dseg
	.org 0x0060 //SRAM_START
DDRAM_ADDR:
	.byte 1
GREEN_N:
	.byte 1
ORANGE_N:
	.byte 1
RED_N:
	.byte 1
PURPLE_N:
	.byte 1
YELLOW_N:
	.byte 1

	.cseg


	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16
	
	call INIT_CLEAR_SRAM
	call LCD_SETUP
	jmp MAIN
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
	out DDRD, r16 // DB0-DB7 set to READMODE as default, will change briefly when writing.
	ldi r16, 0x07 
	out DDRA, r16 // PIN0 - E, PIN1- R/W, PIN2 - RS set to WRITEMODE, will not change.

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

MAIN:
	ldi r20, 'H'
	call LCD_DATA_WRITE
	
	ldi r20, 'A'
	call LCD_DATA_WRITE
	
	ldi r20, 'O'
	call LCD_DATA_WRITE
	
	ldi YH, HIGH(GREEN_N)
	ldi YL, LOW(GREEN_N)
	call LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN
DO_NOTHING:
	jmp DO_NOTHING
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TODO: MAKE IT TAKE REGISTER AND MAKE ANOTHER FUNCTION FOR Y-POINTER?
LCD_OUTPUT_BYTE_IN_BINARY_TO_SCREEN: //LOADS FROM SRAM WITH Y-POINTER AS ARGUMENT, DDRAM ADRESS SHOULD BE SET BEFORE WITH AUTO INC-MODE! 
	push r16
	push r17
	ldi r16, 8
	ld r17, Y
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
	out PORTA, r19 
	call LCD_WRITE
	pop r19
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_DATA_WRITE:
	push r19
	ldi r19, (0<<E)|(0<<RW)|(1<<RS) 
	out PORTA, r19 
	call LCD_WRITE
	pop r19
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_WRITE: //RS = 1 IS DATA, RS = 0 IS INSTRUCTION.  FINDS IF INSTR OR DATA IN r19...change?
	push r16
	push r19
	ldi r16, 0xFF
	out DDRD, r16 // PORTD NOW IN WRITE MODE
	out PORTD, r20 // DATA/INSTRUCTION TO BE WRITTEN IS IN R20, MIGHT CHANGE TO STACK ARGUMENT?

	ori r19, (1<<E)
	out PORTA, r19 //E PULSE STARTS
	nop
	andi r19, 0xFE 
	out PORTA, r19 //E PULSE STOPS

	ldi r16, 0x00
	out DDRD, r16 // PORTD NOW IN READ MODE

	ldi r16, (1<<RW)
	out PORTA, r16 // LCD PUT INTO READMODE
	call WAIT_IF_BUSY
	pop r19
	pop r16
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
WAIT_IF_BUSY:
	push r16
	cli //TIMING DEPENDANT I THINK
	ldi r16, (1<<E)|(1<<RW)|(0<<RS)
	out PORTA, r16 //E PULSE STARTS
	andi r16, 0xFE 
	out PORTA, r16 //E PULSE STOPS
	sbic PIND, 7
	rjmp WAIT_IF_BUSY
	pop r16
	sei //?? NOT GOOD IF USED IN INTERUPT?
	ret

LCD_READ_DDRAM: //EXPERIMENTAL
	ldi r19, (1<<E)|(1<<RW)|(0<<RS)
	out PORTA, r16
	//WAIT 220 ns for valid data?
	in r17, PIND

	andi r16, 0xFE
	out PORTA, r16

	in r18, PIND 
	andi r17, 0x7F // MASK OUT DB7 
	andi r18, 0x7F // MASK OUT DB7
	cp r17, r18 // NOT SURE IF DDRAM ADDR IS CHANGED?
	breq TEST_EQUAL
TEST_LOOP:
	rjmp TEST_LOOP
TEST_EQUAL:
	sts DDRAM_ADDR, r17
	ret
/*LCD_INSTRUCTION_READ:
	ldi r19, (0<<E)|(1<<RW)|(0<<RS)
	ret
LCD_DATA_READ:
	ldi r19, (0<<E)|(1<<RW)|(1<<RS)
	ret

	//in r17, PIND
	//andi r17, 0b01111111
	//sts DDRAM_ADDR, r17
LCD_READ:
	ori r19,(1<<E)
	out PORTA, r19 //E PULSE STARTS
	nop
	nop
	andi r19, 0xFE 
	out PORTA, r19 //E PULSE STOPS
	in r20, PIND //BEFORE E STOP
	ret*/




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
