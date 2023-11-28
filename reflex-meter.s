                THUMB         ;Thumb instruction set
                AREA          My_code, CODE, READONLY
                EXPORT        __MAIN
                ENTRY  
__MAIN:

test_loop:
                LDR         R9, =FIO2PIN1                 ;loading a pre-declared pointer to the address for the FIO2PIN1 register into R9 for checking the button press
                LDR         R10, =LED_BASE_ADR            ;R10 is a permanent pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
                
                MOV         R3, #0xB0000000               ;turn off three LEDs on port 1  
                STR         R3, [R10, #0x20]
                MOV         R3, #0x0000007C
                STR         R3, [R10, #0x40]              ;turn off five LEDs on port 2

                MOV         R4, #0x0                      ;initiate the incrementing time counter to start at 0
                
                MOV         R11, #0xABCD                  ;init the random number generator with a non-zero number

MAIN_LOOP:
                BL          RandomNum
                MOV         R4, #0x0                      ;stores zero into R4 to initialize counter
                MOV         R7, #0x4                      ;stores 4 into R7 to be used to reset pin 2.10 in the future to reset the button for polling
                MOV         R12, #0xFFFF                  ;stores FFFF into R8 to be ANDed with the random number
                STR         R7, [R9]                      ;resets the second bit in R9, to reset the button polling

                ;-------------- Ensure random number is valid --------------;
                MOV         R5, R11                       ;hold the pseudorandom number in R5
                AND         R5, R12                       ;mask the first 16 bits
                MOV         R8, #1221                     ;scale R8 ((80000 + 1000)/2^16)
                MUL         R5, R8                        ;multiply by scale factor
                MOV         R8, #1000
                UDIV        R5, R8                        ;divide by 1000
                MOV         R8, #20000
                ADD         R5, R8                        ;add 20000
                
                MOV         R11, R5                       ;stores the new pseudorandom number into R11
                ;---------------------------------------------------------------;

                MOV         R0, R5                        ;delay the random number of 0.1ms
                BL          DELAY                         ;delay
                MOV         R3, #0x90000000               ;turn on P1.29 after the random delay
                STR         R3, [R10, #0x20]              ;LED on

POLL_LOOP:
                LDRB        R7, [R9]                      ;load the address of the FIO2PIN1 into R7 to process for polling
                MOV         R0, #0x1                      ;then, delay for 0.1ms
                BL          DELAY
                ADD         R4, #0x1                      ;then, increment the counter to keep track of time.
                TST         R7, #1<<2                     ;test if the second bit is set to see if P2.10 is 0 and continue if zero or repeat if 1
                BNE         POLL_LOOP

                MOV         R3, #0xB0000000               ;turn off P1.29 when button is pressed
                STR         R3, [R10, #0x20]  
                MOV         R6, #0x4                      ;counter for displaying counter number

SHOW_COUNTER_LOOP:
                MOV         R8, #0x0                      ;reset R8
                BFI         R8, R4, #0, #8                ;put the first 8 bits into R8 from R4
                LSR         R4, #0x8                      ;shift off the 8 LSB of R4
                BL          DISPLAY_NUM                   ;display the number stored in R8
                MOV         R0, #0x4E20                   ;delay for 2 seconds
                BL          DELAY
                CMP         R8, #0x0000                   ;compare to see if the next bits are all zero
                BEQ         OPTIMIZE                      ;branches to OPTIMIZE which is an optimization if the next bits to be processed are all zero
                SUBS        R6, #0x1                      ;decrement the display bit counter
                BNE         SHOW_COUNTER_LOOP             ;if we are not done showing the bits loop back and show the next bits

OPTIMIZE:
                MOV         R0, #0x7530                   ;delay for 3 extra seconds if all bits processed
                BL          DELAY
                B           MAIN_LOOP

DISPLAY_NUM:
                STMFD       R13!, {R3, R5, R6, R14}
                LDR         R3, [R10, #0x20]              ;load the address of the first pins into R3
                MOV         R7, R8
                MOV         R5, #0x0
                BFI         R5, R7, #0, #5                ;take only the first 5 bits in R7 into R5
                RBIT        R5, R5                        ;reverse the bits to align with the pins
                LSR         R5, #0x19                     ;shift the number to map it to the pins
                EOR         R5, #0xFFFFFFFF               ;flip the bits because the LEDs are active low
                STR         R5, [R10, #0x40]              ;turn the light on
                LSR         R7, #0x5                      ;change our original 8-bit number to 3 bits for the next pins
                MOV         R6, #0x0                      ;reset R6
                BFI         R6, R7, #0, #1                ;put the first bit (28th pin) into R6
                LSL         R7, #0x1                      ;make R7 4 bits in size so we can have bit 30 in between 29 and 31
                ADD         R7, R6                        ;re-insert bit 1 corresponding to pin 28 back into R4
                BFI         R6, R7, #0, #4                ;insert the four bits from R7 into R6
                RBIT        R6, R6                        ;reverse the bits to align with the pins
                EOR         R6, #0xFFFFFFFF               ;flip the bits because the LEDs are active low
                STR         R6, [R10, #0x20]              ;turn the light on

exit_display:
                LDMFD       R13!, {R3, R5, R6, R15}

RandomNum:
                STMFD       R13!, {R1, R2, R3, R14}
                AND         R1, R11, #0x8000
                AND         R2, R11, #0x2000
                LSL         R2, #2
                EOR         R3, R1, R2
                AND         R1, R11, #0x1000
                LSL         R1, #3
                EOR         R3, R3, R1
                AND         R1, R11, #0x0400
                LSL         R1, #5
                EOR         R3, R3, R1                    ;the new bit to go into the LSB is present
                LSR         R3, #15
                LSL         R11, #1
                ORR         R11, R11, R3
                LDMFD       R13!, {R1, R2, R3, R15}

DELAY:
                STMFD       R13!, {R2, R14}
                ;code to generate a delay of 0.1mS * R0 times

RESET_DELAY:
                CMP         R0, #0                        ;compare and see if our delay counter is zero meaning it's done
                BEQ         exitDelay                     ;exit the delay if the delay counter is zero
                MOV         R2, #0x82                     ; [(4000000 / 0.0001) / 3] - 3 = 0x82

DELAY_LOOP:
                SUBS        R2, #1                        ;subtract 1 from our counter
                BNE         DELAY_LOOP                    ;loop again if we have not finished counting and got to 0
                SUB         R0, #1                        ;subtract 1 from the overall delay counter
                B           RESET_DELAY                   ;go back to the start of delay

exitDelay:
                LDMFD       R13!, {R2, R15}

LED_BASE_ADR:    EQU   0x2009c000                         ; Base address of the memory that controls the LEDs
PINSEL3:         EQU   0x4002c00c                         ; Address of Pin Select Register 3 for P1[31:16]
PINSEL4           EQU   0x4002c010        		  ; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN1          EQU   0x2009C055			  ; Address of Fio2Pin1
                        

                        ALIGN

                        END
			
