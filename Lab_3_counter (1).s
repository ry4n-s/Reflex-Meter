; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				MOV			R4, #0x0  
test_loop
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [R10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 


;-------------------------------------------------------------------------------------------
counter_loop
				BL			DISPLAY_NUM			; Display the number stored in R4
				MOV			R0, #0x3E8			; Delay for 100ms
				BL			DELAY	
				CMP			R4, #0xFF			; Check to see if the counter has reached the maximum number of 255
				ADD			R4, #0x1			; Add one to the counter R4
				BNE			counter_loop		; loop back to display the new number
				
				MOV			R4, #0x0			; reset the counter back to 0
				B			test_loop

DISPLAY_NUM		STMFD		R13!,{R3, R5, R6, R7, R14}

; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

; receive 8 bit number from r4
; use the bits in number to map to the lights
			LDR 			R3, [R10, #0x20]	; load the address of the first pins into R3
			MOV				R7, R4
		
			MOV				R5, #0x0
			BFI				R5, R7, #0, #5			; Take only the first 5 bits in R7 into R5
			RBIT			R5, R5						; Reverse the bits to align with the pins
			LSR				R5, #0x19					; Shift the number to map it to the pins
			EOR				R5, #0xFFFFFFFF				; Flip the bits because the LEDs are active low
			STR 			R5, [R10, #0x40] 
			
			LSR				R7, #0x5					; Change our original 8-bit number to 3 bits for the next pins
			
			MOV				R6, #0x0
			BFI				R6, R7, #0, #1			; Put the first bit (28th pin) into R6
			LSL				R7, #0x1					; Make R7 4 bits in size so we can have bit 30 in between 29 and 31
			ADD				R7, R6						; Re-insert bit 1 corresponding to pin 28 back into R4
			BFI				R6, R7, #0, #4
			RBIT			R6, R6						; Reverse the bits to align with the pins
			EOR				R6, #0xFFFFFFFF		; Flip the bits because the LEDs are active low
			STR 			R6, [R10, #0x20] 	

exit_display	LDMFD		R13!,{R3, R5, R6, R7, R15}


DELAY			STMFD		R13!,{R2, R14}
		; code to generate a delay of 0.1mS * R0 times

RESET_DELAY		CMP			R0, #0
				BEQ			exitDelay

				MOV			R2, #0x82		;[(4000000 / 0.0001) / 3] - 3 = 0x82

DELAY_LOOP		SUBS		R2, #1
				BNE			DELAY_LOOP

				SUB			R0, #1
				B			RESET_DELAY

exitDelay		LDMFD		R13!,{R2, R15}

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 

				ALIGN 

				END 