/// i2c/TWI MT code ///
.equ IDcommand = 0x12
.equ redColor = 0x17

init:
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	ldi r16, 0xFF
	out DDRA, r16
	ldi r16, 0x00
	out PORTA, r16

	ldi r16, 0x00
	out TWBR, r16
	ldi r16, 0x02
	out TWSR, r16
main:
	///////////DUMMY///////
	call start
	call sendAddress
	call stop
	///////////////////////
	call start

	call sendAddress

	call sendData

	call repeated_start
	call readData
//	call repeated_start
//	call sendAddress
doneLoop:
	call stop
	rjmp doneLoop
	/////////////////////
start:
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start

wait1:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp wait1 //v�nta p� ok till start

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x08
//	brne ERROR1 //koll om status register �r r�tt annars error
	ret
/////////////////////
stop:
	ldi r16, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
	out TWCR, r16 //stop
	ret
/////////////////////
repeated_start:
	ldi r16, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	out TWCR, r16 //start
	call TWI_WAIT
	

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x10//0x10 OM REPEATED START!
	brne ERROR2 //koll om status register �r r�tt annars error
	ret
////////////////////////////

sendAddress:
	ldi r16, 0x29 //SLA is slave adress, W is write bit
	lsl r16
	ori r16, 0 //s�tter write bit
	out TWDR, r16
	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skicka SLA+W f�r att aktivera MT mode
	call TWI_WAIT

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x18
	//brne ERROR3 //koll om status register �r r�tt annars error
	ret
///////////////////////
	
	// DATA KAN NU L�GGAS TILL TWDR //
sendData:
	ldi r16, IDcommand //H�r laddas data
	ori r16, 0x80
	out TWDR, r16 //laddad

	ldi r16, (1<<TWINT) | (1<<TWEN)
	out TWCR, r16 //skjut!
	call TWI_WAIT

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x28
	brne ERROR4 //koll om status register �r r�tt annars error
	ret
/////////////////////////


readData:
	

sendAddressRead:
	ldi r16, 0x29 //SLA is slave adress, W is write bit
	lsl r16
	ori r16, 1 //s�tter read bit
	out TWDR, r16
	ldi r16, (1<<TWINT) | (1<<TWEN) //| (1<<TWEA)
	out TWCR, r16 //skicka SLA+W f�r att aktivera MT mode
	call TWI_WAIT


	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x40
	brne ERROR5 //koll om status register �r r�tt annars error

	ldi r16, (1<<TWINT) | (1<<TWEN) | (1<<TWEA)
	out TWCR, r16
	call TWI_WAIT

	in r16, TWSR
	andi r16, 0xF8
	cpi r16, 0x50
	brne ERROR6 //koll om status register �r r�tt annars error

	in r16, TWDR
	out PORTA, r16
	ret
TWI_WAIT:
	in r16, TWCR
	sbrs r16, TWINT
	rjmp TWI_WAIT
	ret
ERROR1:
	ldi r16, 0x01
	out porta, r16
	call stop
	jmp error1
ERROR2:
	ldi r16, 0x02
	out porta, r16
	call stop
	jmp error2
ERROR3:
	ldi r16, 0x04
	out porta, r16
	call stop
	jmp error3
ERROR4:
	ldi r16, 0x08
	out porta, r16
	call stop
	jmp error4
ERROR5:
	ldi r16, 0x10
	out porta, r16
	call stop
	jmp error5
ERROR6:
	ldi r16, 0x10
	out porta, r16
	call stop
	jmp error6
DELAY_INIT:
	ldi r16, 0xFF
	ldi r17, 0xFF
DELAY_INIT1:
	dec r16
	brne DELAY_INIT1
DELAY_INIT2:
	dec r17
	brne DELAY_INIT1
	ret
