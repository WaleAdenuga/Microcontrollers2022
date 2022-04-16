;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18f25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
CHECK	equ 0x40
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
    clrf    LATA 	; Initialize PORTA by clearing output data latches
    movlw   0x00 	; Value used to initialize data direction
    movwf   TRISA 	; Set PORTA as output, RA2 is dacout
    movlw   0x00 	; Configure A/D for digital inputs 0000 1111
    movwf   ANSELA	
    movlw   0x00	; Configure comparators for digital input
    movwf   CM1CON0
    clrf    LATB	; Initialize PORTB by clearing output data latches
    movlw   0x00	; Value used to initialize data direction
    movwf   TRISB	; Set PORTB as output
    clrf    LATC	; Initialize PORTC by clearing output data latches
    movlw   0x00	; Value used to initialize data direction
    movwf   TRISC	; Set RC0 as input

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver
    
main
    movlw   0x00
    movwf   CHECK
    call    init_timer
    call    init_dac
    call    init_lut
    
    
init_timer
    movlw   0x07		; configure timer0 as 16bit
    movwf   T0CON
    movlw   0xA4	; initialize timer0 with 42005 for 2Hz and .5s
    movwf   TMR0H
    movlw   0x15
    movwf   TMR0L
    movlw   0x20
    movwf   INTCON
    bsf	    T0CON,TMR0ON
    bsf	    INTCON,GIE
    
    movlw   B'00000100'
    movwf   T1CON
    
    movlw   0xFD
    movwf   TMR1H
    movlw   0x12
    movwf   TMR1L
    
    bsf	    T1CON,TMR1ON
    bsf	    PIE1,TMR1IE
    bsf	    INTCON,PEIE
    
    return

init_dac    
    ;complete me
    
    movlw   B'01100000'
    movwf   VREFCON1
    movlw   B'00011111'
    movwf   VREFCON2
    bsf	    VREFCON1,DACEN  ; enable dac conversion 
    
    return
    


;***********************************************************
; subroutines
;***********************************************************
init_lut
    ; FSR1: will go though table of sine samples; starts at address 0x010
    lfsr    1, 0x010
    movlw   D'15'	
    movwf   0x10
    movlw   D'21'	
    movwf   0x11
    movlw   D'26'	 
    movwf   0x12
    movlw   D'29'	
    movwf   0x13
    movlw   D'30'	
    movwf   0x14
    movlw   D'29'	
    movwf   0x15
    movlw   D'26'	
    movwf   0x16
    movlw   D'21'	
    movwf   0x17
    movlw   D'15'	
    movwf   0x18
    movlw   D'9'	
    movwf   0x19
    movlw   D'4'	
    movwf   0x1A
    movlw   D'1'	
    movwf   0x1B
    movlw   D'0'	
    movwf   0x1C
    movlw   D'1'	
    movwf   0x1D
    movlw   D'4'	
    movwf   0x1E
    movlw   D'9'	
    movwf   0x1F
    
    ; FSR0: song
    ;complete me
    
    return
    
    ;complete me

    
sample
;    ; move the value in fsr to dac, and check that you don't go over 16
    movff   POSTINC1,VREFCON2
;    ; have a counter to count to 16 so we loop through the fsr
    incf    CHECK,1
    movlw   D'16'
    cpfseq  CHECK   ; skip if check is 16, if, change to 0, not, return to interrupt
    return
    movlw   0x00
    movwf   CHECK
    lfsr    1,0x010
    
    return
;***********************************************************
; interrupt handling
;***********************************************************

timer0_interrupt
    btg	    LATC,LATC1
    movlw   0xA4
    movwf   TMR0H
    movlw   0x15
    movwf   TMR0L
    bcf	    INTCON,TMR0IF
    return
    
timer1_interrupt
    btg	    LATA,LATA0	   ; using it to check something 
    movlw   0xFD
    movwf   TMR1H
    movwf   0x12
    movwf   TMR1L
    goto    sample
    bcf	    PIR1,TMR1IF
    
    return
    
inter_high
    btfsc   INTCON,TMR0IF
    call    timer0_interrupt
    btfsc   PIR1,TMR1IF
    call    timer1_interrupt
    retfie
    
inter_low
    nop
    retfie
;***********************************************************
; table
;***********************************************************
    
NOTES ;TMR1H TM1L
    DB 0x00, 0x00   ;Silence?
    ;calculate the correct values
    DB 0xFF, 0xEE   ;C = do
    ;...
    
    END