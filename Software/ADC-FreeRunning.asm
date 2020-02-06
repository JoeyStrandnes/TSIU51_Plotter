.org 0x00
jmp SETUP

.org 0x1C
jmp ADC_ISR


SETUP:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16


	call	ADC_INIT


	jmp MAIN


ADC_INIT:
	ldi		r16, (0<<REFS1)|(0<<REF0)||(0<<ADLAR)(0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0)
	out		ADMUX, r16

	ldi		r16, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)(1<<ADIE)|(1<<ADPS2)|(0<<ADPS1)|(1<<ADPS0) 
	out		ADCSRA, r16

	ldi		r16, 
	out		SIFOR, r16

	ret


MAIN:
	nop
	jmp MAIN





ADC_ISR:



	reti
