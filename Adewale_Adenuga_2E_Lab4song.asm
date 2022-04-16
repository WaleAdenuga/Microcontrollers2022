;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18f25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
FLAG	equ 0x35
CHECK	equ 0x40
TMR1_H	equ 0x41
TMR1_L	equ 0x42
CHECK1	equ 0x43
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
    
    call    init_lut
    call    init_song
    call    init_timer
    call    init_dac
    
    movlw   0x00
    movwf   CHECK
    movlw   0x00
    movwf   CHECK1
    movlw   0x00
    movwf   TMR1_H
    movlw   0x00
    movwf   TMR1_L
    movlw   0x00
    movwf   FLAG

; infinite loop added at the end of main loop    
loop
    btfsc   FLAG,0
    call    frequency
    btfsc   FLAG,1
    call    sample
    goto    loop
  
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
    lfsr    0,0x020
    movlw   0x02
    movwf   0x20
    movlw   0x04
    movwf   0x21
    movlw   0x06
    movwf   0x22
    movlw   0x02
    movwf   0x23
    movlw   0x02
    movwf   0x24
    movlw   0x04
    movwf   0x25
    movlw   0x06
    movwf   0x26
    movlw   0x02
    movwf   0x27
    movlw   0x06
    movwf   0x28
    movlw   0x08
    movwf   0x29
    movlw   0x0A
    movwf   0x2A
    movlw   0x00
    movwf   0x2B
    movlw   0x06
    movwf   0x2C
    movlw   0x08
    movwf   0x2D
    movlw   0x0A
    movwf   0x2E
    movlw   0x00
    movwf   0x2F
    
    return
    
sample
    bcf	    FLAG,1
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
    
frequency
    bcf	    FLAG,0
    movf    POSTINC0,W	   ; move value from fsr0 to working register
    addwf   TBLPTRL,F	   ; add value from fsr to low table pointer, and store in that low table pointer
    btfsc   STATUS,C	   ; check if carry bit is set then increment higher point
    incf    TBLPTRH,1
    tblrd*+		    ; read from table and store in register
    movff   TABLAT,TMR1_H
    tblrd*+
    movff   TABLAT,TMR1_L
    call    init_song
    incf    CHECK1,1
    movlw   D'16'	    ; 16 notes at the moment
    cpfseq  CHECK1	    ; skip if check is 16, if not, change to 0
    return
    movlw   0x00
    movwf   CHECK1
    lfsr    0,0x020
    return
init_timer
    movlw   0x07		; configure timer0 as 16bit
    movwf   T0CON
    movlw   0xA4	; initialize timer0 with 42005 for 2Hz and .5s
    movwf   TMR0H
    movlw   0x72
    movwf   TMR0L
    movlw   0x20
    movwf   INTCON
    bsf	    T0CON,TMR0ON
    bsf	    INTCON,GIE
    
    movlw   B'01000100'
    movwf   T1CON
    
    movlw   0xfd
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
    
init_song
    movlw   upper NOTES
    movwf   TBLPTRU
    movlw   high NOTES
    movwf   TBLPTRH
    movlw   low NOTES
    movwf   TBLPTRL
    return

 
;***********************************************************
; interrupt handling
;***********************************************************

timer0_interrupt
    btg	    LATC,LATC1
    bsf	    FLAG,0
    movlw   0xA4
    movwf   TMR0H
    movlw   0x72
    movwf   TMR0L
    
    bcf	    INTCON,TMR0IF
    return
    
timer1_interrupt
    btg	    LATA,LATA0	   ; using it to check something 
    bsf	    FLAG,1
    movff   TMR1_H,TMR1H
    movff   TMR1_L,TMR1L
    
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
    
; every timer0, update the value in the lsfr0 to a new frequeny, that way 
; we will get the newer index
    ; then I think we write that index to program memory
    ; from program memory, read the values which should contain the values
    ; for tmr1h and tmr1l, then you use those to the dac
    ; then we connect the dac to heasdphones and that should solve everything
    
NOTES ;TMR1H TM1L
    DB 0x00, 0x00   ;Silence?
    ;calculate the correct values, values subject to change of course
    DB 0xe9, 0x30   ;C = do
    DB 0xec, 0x30   ;D
    DB 0xee, 0x30   ;E
    DB 0xef, 0x30   ;F
    DB 0xF1, 0x30   ;G

    ;...
    
    END