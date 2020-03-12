ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

main:
	ldi r16, LOW(15752)
	ldi r17, HIGH(15752)

	ldi r18, LOW(16039)
	ldi r19, HIGH(16039)
	call multi16
	jmp main

///////////////////////////////////////////////////////////////////////////
multi16: //MULTI1 i R17:R16 MULTI2 i R19:R18
	//RESULTAT I R21:R20:R19:R18
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r22

	clr r22 //ZERO
	mul r17, r19 //MSB1*MSB2
	mov r4, r0
	mov r5, r1

	mul r16, r18 //LSB1*LSB2
	mov r2, r0
	mov r3, r1

	mul r17, r18 //MSB1*LSB2
	add r3, r0
	adc r4, r1
	adc r5, r22 

	mul r16, r19 //LSB1*MSB2
	add r3, r0
	adc r4, r1
	adc r5, r22 

	mov r18, r2
	mov r19, r3
	mov r20, r4
	mov r21, r5
	pop r22
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	ret
