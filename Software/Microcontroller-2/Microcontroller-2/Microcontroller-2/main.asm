;motor processor


	;---code
	.cseg
	.org	0
	jmp		START
	.org	INT0addr
	jmp		DRUM_TRIGGER



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
	reti



HW_INIT:
	