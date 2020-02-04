;
; rgbInitializer.asm
;
; Created: 2020-01-29 11:24:24
; Author : Vige
;


; Replace with your application code

/// i2c/TWI MT code ///
.equ IDcommand = 0x12

init:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	ldi r16, 0xFF
	out DDRA, r16

main:
	call start
	jmp sendAddress

start:
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start

wait1:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait1 //vänta på ok till start

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x08
	brne ERROR //koll om status register är rätt annars error
	ret
/////////////////////


sendAddress:
	ldi r16, 0x29 //SLA is slave adress, W is write bit
	lsl r16
	ori r16, 0 //sätter write bit
	out TWDR, r16
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skicka SLA+W för att aktivera MT mode
wait2:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait2 //vänta på ok till SLA+W

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x18
	brne ERROR //koll om status register är rätt annars error

///////////////////////

	// DATA KAN NU LÄGGAS TILL TWDR //
sendData:
	ldi r16, IDcommand //Här laddas data
	out TWDR, r16 //laddad

	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skjut!
wait3:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait3 //vänta på ok till Data

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x28
	brne ERROR //koll om status register är rätt annars error
/////////////////////////


readData:
	call start

sendAddressRead:
	ldi r16, 0x29 //SLA is slave adress, W is write bit
	lsl r16
	ori r16, 1 //sätter write bit
	out TWDR, r16
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skicka SLA+W för att aktivera MT mode
wait2Read:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait2 //vänta på ok till SLA+W

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x18
	brne ERROR //koll om status register är rätt annars error

wait3Read:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait3Read

	in r16, TWDR
	out PORTA, r16

doneLoop:
	rjmp doneLoop



ERROR:
	ldi r16, 0b01010101
	out porta, r16
	rjmp error