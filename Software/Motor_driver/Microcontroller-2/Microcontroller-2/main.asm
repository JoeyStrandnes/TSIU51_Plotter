;motor processor


	.dseg
	.org	SRAM_START
POSU:
	.byte	1	;Upper slab possission
POSL:
	.byte	1	;Lower slab possission


	.cseg
SERVO_STOP:	
	.db		0x00, 0x00	;***fixa sen***
SERVO_RR:	;refresh rate
	.db		0x00, 0x00	;***fixa sen***
SERVO_CW:	;clockwise
	.db		0x00, 0x00	;***fixa sen***
SERVO_CCW:	;counter clockwise
	.db		0x00, 0x00	;***fixa sen***



	;---code
	.cseg
	.org	0
	jmp		START
	.org	INT0addr
	jmp		UPPER_TRIGGER
	.org	INT1addr
	jmp		LOWER_TRIGGER
	.org	0x10
	jmp		SERVO_DIRECTION



START:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	;
    call	HW_INIT
	
    rjmp	start
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
	out		r16, SREG
	pop		r16
	reti
;----------------------------------------




;***Eatch time the the drum passes a color dump***
LOWER_TRIGGER:
	;push all used
	push	r16
	in		r16, SREG
	push	r16
	;

	;pull all used
	pop		r16
	out		r16, SREG
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
	out		r16, SREG
	pop		r16
	reti
;----------------------------------------





CHANGE_SERVO:
	lpm		r16, Z+
	out		ICR1H, r16
	lpm		r16, Z
	out		ICR1L, r16
	ret
;----------------------------------------




HW_INIT:
	;interupt for drum trigger
	ldi		r16, (1<<ISC00)|(1<<ISC01)|(1<<ISC11)|(1<<ISC10)
	out		MCUCR, r16
	ldi		r16, (1<<INT0)|(1<<INT1)
	out		GICR, r16


TIMER_INIT:
	; Setting counter mode 
	ldi		r16, (1<<WGM13)|(1<<WGM12)
	out		TCCR1B, r16

	ldi		r16, (1<<WGM11)|(0<<WGM10) 
	out		TCCR1A, r16

	; Setting max counter value before overflow
	ldi		r16, 0x3D
	out		ICR1H, r16
	ldi		r16, 0x08
	out		ICR1L, r16

	; Setting prescaling and interrupt
	in		r16, TCCR1B  
	ori		r16,(0<<CS12)|(1<<CS11)|(1<<CS10) ;Prescaler set to F_CPU/64 (S:108)

	out		TCCR1B, r16
	ldi		r16, 1<<TOIE1
	out		TIMSK, r16
	ret
	