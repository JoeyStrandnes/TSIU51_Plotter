	.equ RS = 0
	.equ RW = 1
	.equ E = 2
	.equ Clear_Display = 0b00000001
	.equ Return_Home   = 0b00000010
	.equ Second_Line_Address = 0b11000000
//////////////MEMORY LAYOUT////////////////////////////////////////////////////////
	.dseg
	.org 0x0060 //SRAM_START
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
	ldi r16, 99 //SHOULD BE 0 but for debug purpse atm
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

MAIN:
	call UPDATE_DISPLAY
DO_NOTHING:
	jmp DO_NOTHING

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
	out PORTB, r16 //E PULSE STOPS
	sbic PINA, 7
	rjmp WAIT_IF_BUSY
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

