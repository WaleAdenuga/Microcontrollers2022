;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
COUNTER equ  0x00	; This directive replaces each X1 with 0x00 => We will use register 0 to store the counter value
Y1 equ  0x01	; We will use register 1 to store another value
Z1 equ	0x02	; We will use register 2 to store another value
K1 equ	0x03	; delay register
L1 equ	0x04	; delay register
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
    movlw   0xFF	; Value used to initialize data direction
    movwf   TRISB	; Set PORTB as input
    clrf    LATC	; Initialize PORTC by clearing output data latches
    movlw   0x01	; Value used to initialize data direction
    movwf   TRISC	; Set RC0 as input

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver   
    
   
    
    bcf	    TRISC,RC7	;RC7 is output(SDO)
    bcf	    TRISB,RB1	;master clock output, sck
    bcf	    TRISB,RB3	;alternate output SPI, sdo, opposite configuration for undesired function
    
    bsf	    TRISB,RB0	;RB0 is input, sdi
    bsf	    TRISB,RB6	;RB6 is input, enable signal
    bsf	    TRISB,RB7	;RB7 is input, up or down mode
    
    movlw   0x00	; input data sampled at middle of data output
    movwf   SSP1STAT
    movlw   0x23	; clock is timer2 output/2
    movwf   SSP1CON1
    
    movlw   0x02	; initialize timer2 with prescale 16
    movwf   T2CON
    movlw   0xFF
    movwf   PR2		; timer2 period register at slowest possible frequency
      
    bsf	    PIE1,SSPIE	;enable SPI interrupt
    bsf	    INTCON,PEIE	;enable periheral interrupts PIE
    bsf	    INTCON,GIE
    bsf	    T2CON,TMR2ON	;set T2 ON
main
    clrf    COUNTER,ACCESS	; clear registers
    clrf    Y1,ACCESS
    clrf    Z1,ACCESS	;access-access bank is used, banked-bsr is used
    clrf    K1,ACCESS
    clrf    L1,ACCESS
    
    movlw   0x00
    movwf   COUNTER,ACCESS	;initialize counter with value 0
    
    
ifstart
    movlw   0x00    ; move literal 0 to working register, count from 0
    movwf   Z1	    ; move 0 to register Z1
    movwf   K1
    movwf   L1

    btfss   PORTB,6 ; check if RB6 is enabled (enable for counter)
    goto    ifstart
    call    delay1
    btfss   PORTB,7 ;RB7==1 -upcounter, if 0 is downcounter
    goto    downcounter
    goto    upcounter
    goto    ifstart
; end of main loop

upcounter
    incf    COUNTER,1	;increment and store in counter
    movff   COUNTER,SSP1BUF    ;move from counter to working register
    ;movwf   SSP1BUF	;move from working register to spi buffer
    goto    ifstart	;movff COUNTER,SSPBUF
downcounter
    decf    COUNTER,1
    movff   COUNTER,SSP1BUF
    ;movwf   SSP1BUF
    goto    ifstart
; your delay routine
delay1
    ; complete this with e.g. something similar as a for loop delay ... but in assembly
    incf    Z1,1	    ;inner inner loop
    movlw   0xFF    ;move 255 to working register
    cpfseq  Z1	    ;compare Z1 with W, skip if equal
    goto    delay1
    incf    K1,1
    movlw   0xFF
    cpfseq  K1	    ;skip if K1 equal to W
    goto    delay1
    incf    L1,1
    movlw   0x04    ;run the loop 4 times
    cpfseq  L1
    goto    delay1
    return
; for some reason movff ssp1buf,lata does not work    
receive
    movff   SSP1BUF,LATA   ; move value received in buffer to working register
    ;movwf   LATA	; move from working register to latA
    bcf	    PIR1,SSPIF  ; clear interrupt when finished
    return
; interrupt handling
inter_high
    btfsc   PIR1,SSPIF	; when flag is 1, interrupt subroutine is called
    call    receive
    RETFIE
    
inter_low
    nop
    RETFIE
        
    END