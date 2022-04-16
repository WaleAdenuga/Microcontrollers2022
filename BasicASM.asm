; ***LAB REDO ASM***
; NAME: Adewale Adenuga Basic ASM

;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18f25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
VALUE	equ 0x0A    ; value stored on gpr memory
COUNTER	equ 0x20      
;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000	; Reset Vector
			; When debugging:0x0000; when loading: 0x1000
    GOTO    START

;***********************************************************
; Interrupt Vector
;***********************************************************

    ORG     0x1008	; Interrupt Vector HIGH priority
    GOTO    inter_high	; When debugging:0x008; when loading: 0x1008
    ORG     0x1018	; Interrupt Vector LOW priority
    GOTO    inter_low	; When debugging:0x0008; when loading: 0x1018

;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020	; When debugging:0x020; when loading: 0x1020

START
    movlw   0x80	; load value 0x80 in work register
    movwf   OSCTUNE		
    movlw   0x70	; load value 0x70 in work register
    movwf   OSCCON		
    movlw   0x10	; load value 0x10 to work register
    movwf   OSCCON2	
			; initialize PINS 	
    clrf    LATA 	
    movlw   0x00		
    movwf   TRISA 	; Set PORTA as output
    movlw   0x00		
    movwf   ANSELA	
    movlw   0x00	
    movwf   CM1CON0
    clrf    LATB	
    movlw   0x00	; set PORTB as output
    movwf   TRISB	
    clrf    LATC	

    movlw   0x01	
    movwf   TRISC	

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver

main
    movlw   D'4'	; value to be displayed on LEDs
    movwf   VALUE	; move to corresponding register
    movlw   D'0'
    movwf   COUNTER	; to check the value of value
loop
    movlw   D'8'
    cpfslt  VALUE	; check if value is greater than 8
    cpfsgt  VALUE
    call    display
    call    greater_display
    goto    loop
    
display
    movff   VALUE,W	; move value of value from value to working register
    cpfseq  COUNTER	; compare counter with working register, if equal, remove
    bsf	    LATA,COUNTER
    incf    COUNTER,1	; increment counter and store ein the file register
    movff   VALUE,W
    cpfsgt  COUNTER
    goto    display
    ;movlw   0x00
    ;movwf   COUNTER
    goto    loop
    
greater_display
    movlw   B'01010101'
    movwf   LATA	; display if value provided is greater than 8
    goto    loop

; interrupt handling
inter_high
    nop
    RETFIE
    
inter_low
    nop
    RETFIE
        
    END