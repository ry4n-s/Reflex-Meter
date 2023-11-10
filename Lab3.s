; ECE-222 Lab ... Winter 2013 term
; Lab 3 sample code
                        THUMB             ; Thumb instruction set
                AREA          My_code, CODE, READONLY
                EXPORT        __MAIN
                        ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs
test_loop
                        LDR         R9, =FIO2PIN1                 ; Loading a pre-declared pointer to the address for the FIO2PIN1 register into R9 for checking the button press
                        LDR         R10, =LED_BASE_ADR            ; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
                        
                        MOV         R3, #0xB0000000         ; Turn off three LEDs on port 1  
                        STR         R3, [R10, #0x20]
                        MOV         R3, #0x0000007C
                        STR         R3, [R10, #0x40]  ; Turn off five LEDs on port 2

                        MOV               R4, #0x0                ; Initiate the incrementing time counter to start at 0
                        ;MOV              R8, #0x4E20             ; Lower bound of random number
                        ;MOV32            R9, #0x186A0            ; Upper bound of random number
                        
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
                        MOV               R11, #0xABCD            ; Init the random number generator with a non-zero number
MAIN_LOOP         BL                RandomNum
                        MOV        		  R4, #0x0				; Stores zero into R4 to initialize counter
                        MOV               R7, #0x4				; Stores 4 into R7 to be used to reset pin 2.10 in the future to reset the button for polling
						MOV				  R12, #0xFFFF			; Stores FFFF into R8 to be ANDed with the random number
                        STR               R7, [R9]				; Resets the second bit in R9, to reset the button polling

;-------------- Ensure our random number is valid --------------;
                        
                        MOV               R5, R11               ; Hold the random number in R5
						
						AND					R5, R12				; mask the first 16 bits
						
						MOV					R8, #1221			; Scale R8 ((80000 + 1000)/2^16)
						MUL					R5, R8				; Multiply by scale factor
						MOV					R8, #1000
						UDIV 				R5, R8				; Divide by 1000
						MOV 				R8, #20000
						ADD					R5, R8				; Add 20000
                        
                        MOV               R11, R5        		; stores the new random number into R11
;---------------------------------------------------------------;

                        MOV               R0,R5					; Delay the random number of 0.1ms
                        BL                DELAY					; Delay
                        MOV               R3,#0x90000000        ; turn on P1.29 after the random delay
                        STR         R3, [R10, #0x20]  			; LED on
                        
;                       MOV               R0,#0x7E5
;                       BL                DELAY
;                       B                 test_loop

POLL_LOOP         LDRB        R7, [R9]						; Load the address of the FIO2PIN1 into R7 to process for polling
		
                        MOV               R0, #0x1			; Then, delay for 0.1ms
                        BL                DELAY
                        ADD               R4, #0x1			; Then, increment the counter to keep track of time.
                        
                        TST               R7, #1<<2   			; test if the second bit is set to see if P2.10 is 0 and continue if zero or repeat if 1
                        BNE               POLL_LOOP

                        MOV               R3,#0xB0000000          ; turn off P1.29 when button is pressed
                        STR         R3, [R10, #0x20]  ;
                        MOV               R6, #0x4                ; Counter for displaying counter number
                        ;B                test_loop


SHOW_COUNTER_LOOP
                        
                        MOV               R8, #0x0				; reset R8
                        BFI               R8, R4, #0, #8		; put the first 8 bits into R8 from R4
                        LSR               R4, #0x8				; shift off the 8 LSB of R4
                        BL                DISPLAY_NUM			; Display the number stored in R8
                        
                        MOV         	  R0,#0x4E20            ; Delay for 2 seconds
                        BL                DELAY
                        
                        CMP               R8, #0x0000			; Compare to see if the next bits are all zero
                        BEQ               OPTIMIZE				; Branches to OPTIMIZE which is an optimization if the next bits to be processed are all zero
                        
                        SUBS       		  R6, #0x1				; decrement the display bit counter
                        BNE               SHOW_COUNTER_LOOP		; if we are not done showing the bits loop back and show the next bits
                        
OPTIMIZE          		MOV               R0, #0x7530           ; Delay for 3 extra seconds if all bits processed
                        BL                DELAY

                        B                 MAIN_LOOP



; receives an 8 bit number from R8
DISPLAY_NUM       STMFD       R13!,{R3, R5, R6, R14}

                  LDR               R3, [R10, #0x20]  ; load the address of the first pins into R3
                  MOV                     R7, R8
            
                  MOV                     R5, #0x0
                  BFI                     R5, R7, #0, #5               		  ; Take only the first 5 bits in R7 into R5
                  RBIT              R5, R5                                    ; Reverse the bits to align with the pins
                  LSR                     R5, #0x19                           ; Shift the number to map it to the pins
                  EOR                     R5, #0xFFFFFFFF                     ; Flip the bits because the LEDs are active low
                  STR               R5, [R10, #0x40]						  ; turn the light on
                  
                  LSR                     R7, #0x5                            ; Change our original 8-bit number to 3 bits for the next pins
                  
                  MOV                     R6, #0x0							  ;reset R6
                  BFI                     R6, R7, #0, #1                      ; Put the first bit (28th pin) into R6
                  LSL                     R7, #0x1                            ; Make R7 4 bits in size so we can have bit 30 in between 29 and 31
                  ADD                     R7, R6                                    ; Re-insert bit 1 corresponding to pin 28 back into R4
                  BFI                     R6, R7, #0, #4					  ; insert the four bits from R7 into R6
                  RBIT              R6, R6                                    ; Reverse the bits to align with the pins
                  EOR                     R6, #0xFFFFFFFF                     ; Flip the bits because the LEDs are active low
                  STR               R6, [R10, #0x20]        				  ; turn the light on

exit_display      LDMFD       R13!,{R3, R5, R6, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in, the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum         STMFD       R13!,{R1, R2, R3, R14}

                        AND               R1, R11, #0x8000
                        AND               R2, R11, #0x2000
                        LSL               R2, #2
                        EOR               R3, R1, R2
                        AND               R1, R11, #0x1000
                        LSL               R1, #3
                        EOR               R3, R3, R1
                        AND               R1, R11, #0x0400
                        LSL               R1, #5
                        EOR               R3, R3, R1        ; the new bit to go into the LSB is present
                        LSR               R3, #15
                        LSL               R11, #1
                        ORR               R11, R11, R3
                        
                        LDMFD       R13!,{R1, R2, R3, R15}

;
;           Delay 0.1ms (100us) * R0 times
;           aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.

DELAY             STMFD       R13!,{R2, R14}
            ; code to generate a delay of 0.1mS * R0 times

RESET_DELAY       		CMP               R0, #0			; Compare and see if our delay counter is zero meaning its done
                        BEQ               exitDelay			; exit the delay if the delay counter is zero

                        MOV               R2, #0x82         ; [(4000000 / 0.0001) / 3] - 3 = 0x82

DELAY_LOOP        		SUBS       		  R2, #1			; Subtract 1 from our counter
                        BNE               DELAY_LOOP		; loop again if we have not finished counting and got to 0

                        SUB               R0, #1			; Subtract 1 from the overall delay counter
                        B                 RESET_DELAY		; Go back to the start of delay

exitDelay         LDMFD       R13!,{R2, R15}

LED_BASE_ADR      EQU   0x2009c000        ; Base address of the memory that controls the LEDs
PINSEL3                 EQU   0x4002c00c        ; Address of Pin Select Register 3 for P1[31:16]
PINSEL4                 EQU   0x4002c010        ; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN1          EQU   0x2009C055		; Address of Fio2Pin1
                        
;     Usefull GPIO Registers
;     FIODIR  - register to set individual pins as input or output
;     FIOPIN  - register to read and write pins
;     FIOSET  - register to set I/O pins to 1 by writing a 1
;     FIOCLR  - register to clr I/O pins to 0 by writing a 1

                        ALIGN

                        END

;-------------------------LAB REPORT-------------------------;
;     Q1)   
;           - For 8 bits, we can store up to 25.5 miliseconds
;           - For 16 bits --> 6.5535 seconds
;           - For 24 bits --> 1,677.7215 seconds
;           - For 32 bits --> 429,496.7295 seconds

;     Q2)
;           Since the average human reaction time is anywhere around
;           150 - 320 ms, we only need to use 16 bits. This will
;           prevent the use an unecessary amount of bits being stored
;           and unused for our purposes.
