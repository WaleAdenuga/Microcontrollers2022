/*********************************************************************************************************************
 * Template lab redo Microcontrollers C
 *
 * Name: Adewale Adenuga Advanced C assignment
 * (a) LED that will go on will be Rc1, but not using pwm
 * (b) , use timer0 to generate 5hz blinking led
 * (c) but when you leave switch RC0, it goes off fast and turns off fast
 *********************************************************************************************************************/

/*
 * Includes
 */
#include <xc.h>
#define _XTAL_FREQ 48000000

/*
 * Prototypes
 */
void __interrupt (high_priority) high_ISR(void);   //high priority interrupt routine
void __interrupt (low_priority) low_ISR(void);  //low priority interrupt routine, not used in this example
void initChip(void);
void initTimer(void);

/*
 * Interrupt Service Routines
 */

void __interrupt (high_priority) high_ISR(void)
{
    if (INTCONbits.TMR0IF == 1) {
        //blink at 5hz from now on
        //counter needs to count .2/(83ns * 256) = 9413, initialize with 65536 - 9413
        TMR0H = 0xDB;
        TMR0L = 0x3B;
        
        INTCONbits.TMR0IF = 0;

        
        if (LATCbits.LATC1 == 1) { //toggle RC1
            LATCbits.LATC1 = 0;
        } else {
            LATCbits.LATC1 = 1;
        }
    }
}

/*
 * Functions
 */
void initChip(void)
{
	//CLK settings
	OSCTUNE = 0x80; //3X PLL ratio mode selected
	OSCCON = 0x70; //Switch to 16MHz HFINTOSC
	OSCCON2 = 0x10; //Enable PLL, SOSC, PRI OSC drivers turned off
	while(OSCCON2bits.PLLRDY != 1); //Wait for PLL lock
	ACTCON = 0x90; //Enable active clock tuning for USB operation

	LATA =0x00 ; //Initial PORTA   
    TRISA = 0x00;  
    ANSELA = 0b00000000;	// define digital or analog
    ADCON1 = 0x00; //AD voltage reference           
    CM1CON0 = 0x00; //Turn off Comparator        
    LATB = 0x00; //Initial PORTB
    PORTB = 0x00;
    TRISB = 0xFF ; //Define PORTB as input
    LATC = 0x00; //Initial PORTC
    TRISC = 0b00000001; //Define PORTC as input
}

void initTimer(void) {
    //Use timer0 in 16 bit mode to generate interrupt every .2 second
    T0CON = 0x07;
    INTCON = 0x20;
    //period is .8µs
    //prescaler is 1, counter needs to count .µs/83ns*1 = 10
    //Initialize counter with 65536 - 10 = 65526 which is 0xfff5
    TMR0H = 0xFF;
    TMR0L = 0xF5;
    
    //T0CONbits.TMR0ON = 1;
    INTCONbits.TMR0IF = 0;
    INTCONbits.GIE = 1;
}

void main()
{
    initChip();
    initTimer();
    while(1) 
    {
       if (PORTCbits.RC0 == 1) {
           TMR0H = 0xFF;
           TMR0L = 0xF5;
           T0CONbits.TMR0ON = 0;
           LATCbits.LATC1 = 0;
       } else {
           T0CONbits.TMR0ON = 1;
       }
       
    } 
} // End of Main function

