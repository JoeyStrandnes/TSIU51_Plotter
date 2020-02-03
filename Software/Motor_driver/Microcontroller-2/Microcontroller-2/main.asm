;motor processor






	.cseg
	.org	0
	jmp		START
	.org	INT0addr
	jmp		UPPER_TRIGGER
	.org	INT1addr
	jmp		LOWER_TRIGGER
	.org	OVF1addr
	jmp		SERVO_DIRECTION



	.dseg
	.org	SRAM_START
POSU:
	.byte	1	;Upper slab possission
POSL:
	.byte	1	;Lower slab possission
COLOR_POS:
	.byte	1	;current color possission
	.cseg


	.equ	SERVO_RR	= 2600		;Refresh rate
	.equ	SERVO_CW	= 300		;Clockwise
	.equ	SERVO_CCW	= 0			;Counter clockwise
	.equ	SERVO_ST	= 0			;Stop


	;---code
START:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	;
    call	HW_INIT
	;


	ldi		r16, HIGH(SERVO_CW)
	out		OCR1BH, r16
	ldi		r16, LOW(SERVO_CW)
	out		OCR1BL, r16
LOOP:
    rjmp	LOOP
;---------------------------------------


;***Eatch time the the drum passes a color dump***
UPPER_TRIGGER:
	;push all used
	push	r16
	in		r16, SREG
	push	r16
	;

	;pull all used
	pop		r16
	out		SREG, r16
	pop		r16
	reti
;----------------------------------------




;***Eatch time the the drum passes a color dump***
LOWER_TRIGGER:
	;push all used
	push	r16
	in		r16, SREG
	push	r16
	push	r17
	;
	in		r16, PINB	
	cpi		r16, 0		;clockwise if 1
	breq	CCW_DIR
CW_DIR:
	lds		r16, (POSL)
	inc		r16
	rjmp	DIR_LIM
CCW_DIR:
	lds		r16, (POSL)
	dec		r16
	;
DIR_LIM:
	ori		r16, 0	;check negative
	brmi	UND_LIM	;under limit
	cpi		r16, 5	;over limit
	brne	POS_OK
	subi	r16, 1	;***utanför sensor***
UND_LIM:
	inc		r16		;***utanför sensor***
	;
POS_OK:
	sts		(POSL), r16	;new pos
	lds		r17, (COLOR_POS)
	cp		r16, r17
	brne	NO_DROP
DROP:
	ldi		r16, HIGH(SERVO_ST)
	out		OCR1BH, r16
	ldi		r16, LOW(SERVO_ST)
	out		OCR1BL, r16
NO_DROP:
	;pull all used
	pop		r17
	pop		r16
	out		SREG, r16
	pop		r16
	reti
;----------------------------------------


SERVO_DIRECTION:
	;push all used
	push	r16
	in		r16, SREG
	push	r16
	;		

	;pull all used
	pop		r16
	out		SREG, r16
	pop		r16
	reti
;----------------------------------------






HW_INIT:
	;interupt for drum trigger
	ldi		r16, (1<<ISC00)|(1<<ISC01)|(1<<ISC11)|(1<<ISC10)
	out		MCUCR, r16
	ldi		r16, (1<<INT0)|(1<<INT1)
	out		GICR, r16

	ldi		r16, 0xF0	
	out		DDRD, r16	;D 4-7 output

	ldi		r16, 0x00
	out		DDRB, r16	;B input 

TIMER_INIT:
	; Setting counter mode 
	ldi		r16, (1<<WGM13)|(1<<WGM12)
	out		TCCR1B, r16

	ldi		r16, (1<<WGM11)|(0<<WGM10)|(1<<COM1A1)|(0<<COM1A0)|(1<<COM1B1)|(0<<COM1B0)
	out		TCCR1A, r16

	; Setting max counter value before overflow
	ldi		r16, HIGH(SERVO_RR)
	out		ICR1H, r16
	ldi		r16, LOW(SERVO_RR)
	out		ICR1L, r16

	; Setting prescaling and interrupt
	in		r16, TCCR1B  
	ori		r16,(0<<CS12)|(1<<CS11)|(1<<CS10) ;Prescaler set to F_CPU/64 (S:108)

	out		TCCR1B, r16
	ldi		r16, 1<<TOIE1
	out		TIMSK, r16
	sei
	ret
