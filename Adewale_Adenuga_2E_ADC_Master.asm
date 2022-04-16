;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
X1 equ  0x00	; This directive replaces each X1 with 0x00 => We will use register 0 to store a value
Y1 equ  0x01	; We will use register 1 to store another value
		; The label Y1 (representing an address) is equal to the constant 0x01  
; TIP: Since these locations are located in the access bank, this is the easier option.
		
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
    movwf   TRISA 	; Set PORTA as output
    movlw   0x00 	; Configure A/D for digital inputs 0000 1111
    movwf   ANSELA	
    movlw   0x00	; Configure comparators for digital input
    movwf   CM1CON0
    clrf    LATB	; Initialize PORTB by clearing output data latches
    movlw   0x00	; Value used to initialize data direction
    movwf   TRISB	; Set PORTB as output
    clrf    LATC	; Initialize PORTC by clearing output data latches
    movlw   0x01	; Value used to initialize data direction
    movwf   TRISC	; Set RC0 as input

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver
    
    bsf	    TRISB,RB2	; set RB2 as input
    bsf	    ANSELB,RB2	; RB2 is analog input 8
    
    bcf	    TRISC,RC7	;RC7 is output(SDO)
    bcf	    TRISB,RB1	;master clock output, sck
    bcf	    TRISB,RB3	;alternate output SPI, sdo, opposite configuration for undesired function
    
    bsf	    TRISB,RB0	;RB0 is input, sdi
        
    movlw   0x47
    movwf   T0CON
    movlw   0xD1	; initialize with 209 for 1Khz frequency
    movwf   TMR0L
    movlw   0x20
    movwf   INTCON
    bsf	    T0CON,TMR0ON
    bsf	    INTCON,GIE
    
    movlw   0x00
    movwf   ADCON1	; configure vss and vdd
    movlw   0x20
    movwf   ADCON0	; analog input 8, go and on switched off
    movlw   0x1E
    movwf   ADCON2	;left justified, 6 Tad, Fosc/64
    bsf	    ADCON0,ADON
    bsf	    INTCON,PEIE
    bsf	    PIE1,ADIE
    bcf	    PIR1,ADIF
    
    movlw   0x00
    movwf   SSP1STAT
    bsf	    SSP1CON1,SSPEN  ; enable spi
    
    bsf	    PIE1,SSPIE
    bsf	    INTCON,GIE
    
main
    nop
    goto main
    
 
timer_interrupt
    movlw   0xD1
    movwf   TMR0L
    bsf	    ADCON0,GO
    bcf	    INTCON,TMR0IF
    return
    
adc_interrupt
    movff   ADRESH,SSP1BUF	;move adc value to leds immediately
    bcf	    PIR1,ADIF
    return
    
spi_interrupt
    movff   SSP1BUF,LATA
    bcf	    PIR1,SSPIF	    ; clear interrupt flag when finished
    return

; interrupt handling
inter_high
    btfsc   INTCON,TMR0IF
    call    timer_interrupt
    btfsc   PIR1,ADIF
    call    adc_interrupt
    btfsc   PIR1,SSPIF
    call    spi_interrupt
    RETFIE
    
inter_low
    btfsc   INTCON,TMR0IF
    call    timer_interrupt
    btfsc   PIR1,ADIF
    call    adc_interrupt

    RETFIE
        
    END