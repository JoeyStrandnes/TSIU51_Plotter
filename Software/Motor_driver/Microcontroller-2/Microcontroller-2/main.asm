;motor processor


	;---code
	.cseg
	.org	0
	jmp		START
	.org	INT0addr
	jmp		DRUM_TRIGGER
	.org	0x10
	jmp		TIMER_1



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
DRUM_TRIGGER:
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

TIMER_1:
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


HW_INIT:


	;interupt for drum trigger
	ldi		r16, (1 << ISC00)|(1 << ISC01)
	out		MCUCR, r16
	ldi		r16, (1 << INT0)
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
	