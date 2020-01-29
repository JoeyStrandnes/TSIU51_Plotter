	.equ E = 0
	.equ RW = 1
	.equ RS = 2
	.equ Clear_Display = 0b00000001
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

LCD_SETUP:	
	ldi r16, 0x00
	out DDRD, r16 // DB0-DB7 set to READMODE as default, will change.
	ldi r16, 0x07 
	out DDRA , r16 // PIN0 - E, PIN1- R/W, PIN2 - RS set to WRITEMODE, will not change.

	//WAIT FOR 30 ms AFTER 4.5 V HAS BEEN SUPPLIED TO SCREEN
	call DELAY01
	ldi r20, 0b00111000 // 2_line_5x8_mode 
	call LCD_INSTRUCTION_WRITE

	ldi r20, 0b00001110 // DISPLAY ON, CURSOR ON, BLINK OFF
	call LCD_INSTRUCTION_WRITE

	ldi r20, Clear_Display 
	call LCD_INSTRUCTION_WRITE

	//WAIT FOR MORE THAN 1.53 ms

	ldi r20, 0b00000100 // INCREMENT MODE, ENTIRE SHIFT OFF
	call LCD_INSTRUCTION_WRITE 
	// INIT DONE


	ldi r20, 'S'
	call LCD_DATA_WRITE
	ldi r20, 'O'
	call LCD_DATA_WRITE
	ldi r20, 'S'
	call LCD_DATA_WRITE
DO_NOTHING:
	jmp DO_NOTHING
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

LCD_INSTRUCTION_WRITE:
	ldi r19, (0<<E)|(0<<RW)|(0<<RS) 
	out PORTA, r19 // LCD IN WRITE MODE, INSTRUCTION
	call LCD_WRITE
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_DATA_WRITE:
	ldi r19, (0<<E)|(0<<RW)|(1<<RS) 
	out PORTA, r19 // LCD IN WRITE MODE, DATA
	call LCD_WRITE
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_WRITE: //RS = 1 IS DATA, RS = 0 IS INSTRUCTION.  

	ldi r16, 0xFF
	out DDRD, r16 // PORTD NOW IN WRITE MODE
	out PORTD, r20 // DATA/INSTRUCTION TO BE WRITTEN IS IN R20, MIGHT CHANGE TO STACK ARGUMENT?

	ori r19, (1<<E)
	out PORTA, r19 //E PULSE STARTS
	nop
	nop
	andi r19, 0xFE 
	out PORTA, r19 //E PULSE STOPS

	ldi r16, 0x00
	out DDRD, r16 // PORTD NOW IN READ MODE

	ldi r16, (1<<RW)
	out PORTA, r16 // LCD PUT INTO READMODE
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* ATT GÖRA READ BUSY/ADDRESSCOUNTER?
LCD_INSTRUCTION_READ:
	ldi r19, (0<<E)|(1<<RW)|(0<<RS)
	ret
LCD_DATA_READ:
	ldi r19, (0<<E)|(1<<RW)|(1<<RS)
	ret
LCD_READ:
	ori r19,(1<<E)
	out PORTA, r19 //E PULSE STARTS
	nop
	nop
	andi r19, 0xFE 
	out PORTA, r19 //E PULSE STOPS
	in r20, PIND //BEFORE E STOP?
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