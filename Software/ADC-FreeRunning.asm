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

	ldi		r16, (1<<PB0)
	out		DDRB, r16

	sei

	jmp MAIN


ADC_INIT: 
/*
***ADC SETTINGS***
AREF
Left adjusted
ADC0

ADC always enabled
Auto Trigger enabled
Interrupt enabled
Prescaler: 32 ((8MHz/32)= ADC_FREQ = 250KHz)
Free Running mode (SIFOR defaults to Free Running)
*/
	ldi		r16, (0<<REFS1)|(0<<REFS0)|(0<<ADLAR)|(0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0)
	out		ADMUX, r16

	ldi		r16, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS2)|(0<<ADPS1)|(1<<ADPS0) 
	out		ADCSRA, r16

	ret


MAIN:
	nop
	jmp MAIN


ADC_ISR:
	in		r16, ADCL
	in		r17, ADCH

	cpi		r16, 0x0F
	brlo	NO_OVER_CURRENT
	 
	ldi		r16, (1<<PB0)
	out		PORTB, r16
	jmp		ADC_DONE

NO_OVER_CURRENT:
	ldi		r16, (0<<PB0)
	out		PORTB, r16

ADC_DONE:

	reti
