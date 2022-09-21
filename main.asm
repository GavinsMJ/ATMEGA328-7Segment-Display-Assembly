;
; ADCMotorSevSEG.asm
;
; Created: 6/27/2022 11:49:52 AM 
; Author : Gavins
;
; CODE TO :
;	Display my Initials(GMO) on a seven segment display during program startup.
;	4-digit Seven segment display to show value of potentiometer being read
;	TOGGLE Motor OFF and ON WHEN POTENTIOMETER ON ADC0 VALUE EXCEEDS (1/2 * 1023) = 512 ATMEGA368P(16MHz) 
;
; The pin map I used is:
; (dp,g,f,e,d,c,b,a) = (PD7,PD6,PD5,PD4,PD3,PD2,PD1,PD0)
; and the anode pins are:
; (digit0,digit1,digit2,digit3) = (PB0,PB1,PB2,PB3)
; 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.NOLIST 
.INCLUDE "M328PDEF.INC"
.LIST 

; Truth table
.EQU   d0 = 0b11000000           
.EQU   d1 = 0b11111001             
.EQU   d2 = 0b10100100 
.EQU   d3 = 0b10110000           
.EQU   d4 = 0b10011001             
.EQU   d5 = 0b10010010 
.EQU   d6 = 0b10000010           
.EQU   d7 = 0b11111000             
.EQU   d8 = 0b10000000 
.EQU   d9 = 0b10010000     

.EQU       g = 0b00010000           ; g.
.EQU       n = 0b00101011           ; cannot display M thus show n.   
.EQU       O = 0b11000000           ; o
 
.DEF UnitVal    = R25
.DEF CompH      = R16
.DEF CompL      = R17

.CSEG
.ORG 0x0000

SETUP :     
      LDI R16,  0xFF 
	  OUT DDRD, R16 ; set port D output for 7seg 
	  OUT DDRB, R16 ; set port B output for 7seg digit select 
	  SBI DDRC, 1   ; Set PC1 as output to motor

	  CALL NameInitial ; display initials at launch of simulation
	  CALL adcInit	

      sbi DDRC,3       ; PC3 to output FOR MOTOR LOGIC
      sbi DDRC,4       ; PC4 to output FOR MOTOR LOGIC
      cbi PortC,3      ; PC3 to LOW
      cbi PortC,4      ; PC4 to LOW 	

loop :
	    CALL adcRead 
	 	CALL adcWait
 		RJMP ADCval

	; DISPLAY CODE
    loopCont:
	    JMP Separate_digits
	 
adcInit: ; set ADMUX and ADCSRA 
	     LDI R16, 0x40    ;Avcc, right-justified //0b0100000
		 STS ADMUX, R16
		 LDI R16, 0x87    ;enable ADC, ADC prescaler CLK/128 //0b10000111
	     STS ADCSRA, R16
		 
ADCval:
		CPI R19, HIGH(512) ;compare ADCH ADC value with 512
		BRSH MotorON     ;if equal or greater than 512, turn motor ON                 
		JMP MotorOFF     ;if less than 512, turn motor OFF

adcRead:
		 LDI R16, 0x40   ; Set ADSC flag to start ADC Conversion
		 LDS R22, ADCSRA       
		 OR  R22, R16          
		 STS  ADCSRA, R22      
		 RET
		
adcWait:              ; wait for conversion to complete 
	   LDS R16, ADCSRA       ; Observe ADIF flag 
	   SBRS R16, 4          
	   jmp adcWait           ; go back until flag is set

	   LDI R16, 0x10         ; Set the flag again to signal 'ready-to-be-cleared' 
	   LDS R22, ADCSRA      
	   OR  R22, R16         
	   STS ADCSRA, R22   
	   LDS   R18, ADCL      ;get low-byte result from ADCL
	   LDS   R19, ADCH      ;get high-byte result from ADCH
       RET

MotorON:
		SBI PortC, 1
        ;LED stuff - not necessary
        SBI   PORTC, 3           ; Set pin PC3 HIGH -> Motor ON
		CBI   PORTC, 4           ; Set pin PC4 LOW  
        JMP loopCont
MotorOFF: 
		CBI PortC, 1 
        ;LED stuff - not necessary
        SBI   PORTC, 4           ; Set pin PC4 HIGH 
		SBI   PORTC, 3           ; Set pin PC3 HIGH -> Motor OFF
	    JMP loopCont  

NameInitial:
			LDI   R25,30
NameInitialLoop1:  
			CBI PortB, 0 

			LDI R16, g
			SBI PortB, 1 
			Call DispInitial
			CBI PortB, 1

			LDI R16, n
			SBI PortB, 2 
			Call DispInitial
			CBI PortB, 2

			LDI R16, o
			SBI PortB, 3 
			Call DispInitial
			CBI PortB, 2

			CLR R16
			OUT PORTB, R16

			DEC  R25
		    BRNE NameInitialLoop1
	RET


DispInitial:
		OUT PortD, R16
		CALL Delay
		RET




Separate_digits:
    
	CLR   UnitVal
	;.equ  valuee = 968        ;; for test
    ; LDI   R19, HIGH(valuee)
	; LDI   R18, LOW(valuee)	

	THOUSANDS_ :              ; GET Thousands Digit
		LDI   CompH, HIGH(1000)
		LDI   COMPL, LOW(1000)	
		CP    R19, CompH
		BREQ  CheckLowTh       
		BRSH  IncrementTh      
	outloopTh:
        sbi PortB,0         
		call truth_Val   
	    call Delay      
	    cbi PortB,0        
    
	   CLR   UnitVal


	HUNDREDS_ :               ; GET Hundreds Digit    
		LDI   CompH, HIGH(100)
		LDI   COMPL, LOW(100)
		CPI   R19,0 
		BRNE  IncrementHh        
  		CP    R18, COMPL     
		BRSH  IncrementH       
    doneH:
	    CP    R18, COMPL       
		BRLO  outloopH
		RJMP  HUNDREDS_
    outloopH:
	    sbi PortB,1       
		call truth_Val   
	    call Delay      
	    cbi PortB,1        

		CLR   UnitVal


	TENS_ :                   ; GET Tens Digit
		LDI   CompH, HIGH(10)
		LDI   COMPL, LOW(10)
		CP    R18, COMPL   
		BRSH  IncrementT        
	doneT:
	    CP    R18, COMPL      
		BRLO  outloopT
		RJMP  TENS_
	outloopT:  
	    sbi PortB,2        
		call truth_Val        
	    call Delay      
	    cbi PortB,2         

		CLR   UnitVal


	ONES_ :                   ; GET Ones Digit
		sbi   PortB,3        
		MOV   UnitVal, R18
		call truth_Val      
	    call  Delay      
	    cbi   PortB,3       

	JMP loop


;; THOUSANDS MANIPULATION 
CheckLowTh:              ; COMPARING LOW BYTE IS HIGH BYTE WAS EQUAL
		CP    R18, COMPL  
		BRLO  outloopTh
		CALL Increment
		JMP outloopTh

IncrementTh:
		CALL Increment
		JMP outloopTh


;; HUNDREDS MANIPULATION 		
IncrementHh:              
		CALL Increment
		JMP HUNDREDS_		
IncrementH:
		CALL Increment
		JMP doneH

;; TENS MANIPULATION 
IncrementT:
		CALL Increment
		JMP doneT

Increment:
		INC		UnitVal
		CLC
		SUB 	R18,CompL      ; subtract 10* in operation -- adcl
 		SBC 	R19,CompH      ; subtract 10* in operation -- ADCH
	RET


truth_Val:                     ; TRUTH TABLE COMPARISON AND OUTPUTTING TO PORT D
	CLR		R20
    
	CPI UnitVal,0    
		LDI   R20, d0
		BREQ DisplaySetDigit
	CPI UnitVal,1    
		LDI   R20, d1
		BREQ DisplaySetDigit
	CPI UnitVal,2    
		LDI   R20, d2
		BREQ DisplaySetDigit
	CPI UnitVal,3    
		LDI   R20, d3
		BREQ DisplaySetDigit
	CPI UnitVal,4    
		LDI   R20, d4
		BREQ DisplaySetDigit
	CPI UnitVal,5    
		LDI   R20, d5
		BREQ DisplaySetDigit
	CPI UnitVal,6    
		LDI   R20, d6
		BREQ DisplaySetDigit	
	CPI UnitVal,7    
		LDI   R20, d7
		BREQ DisplaySetDigit
	CPI UnitVal,8    
		LDI   R20, d8
		BREQ DisplaySetDigit
	CPI UnitVal,9    
		LDI   R20, d9
		BREQ DisplaySetDigit	

DisplaySetDigit:
    OUT portD, R20          ; OUTPUT FOUND VALUE TO PORTD
    RET

 Delay:      ;multiplexing delay 0.666ms
			LDI R23, 100
Loop1:		LDI R24, 60
Loop2:		NOP 
	
			DEC R24
			BRNE	Loop2
			
			DEC R23
			BRNE    loop1
			RET	