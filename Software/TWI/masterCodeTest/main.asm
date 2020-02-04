;
; rgbInitializer.asm
;
; Created: 2020-01-29 11:24:24
; Author : Vige
;


; Replace with your application code

/// i2c/TWI RGB INITIALIZER ///
		
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start

wait1:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait1 //v�nta p� ok till start

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x08
	brne ERROR //koll om status register �r r�tt annars error

	ldi r16 SLA+W //SLA is slave adress, W is write bit
	out TWDR, r16
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skicka SLA+W f�r att aktivera MT mode
wait2:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait2 //v�nta p� ok till SLA+W

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x18
	brne ERROR //koll om status register �r r�tt annars error

	// DATA KAN NU L�GGAS TILL TWDR //

	ldi r16, DATA
	out TWDR, r16 //laddad

	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skjut!
wait3:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait3 //v�nta p� ok till Data

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x28
	brne ERROR //koll om status register �r r�tt annars error