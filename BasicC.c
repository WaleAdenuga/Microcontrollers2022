/*********************************************************************************************************************
 * Template lab redo Microcontrollers C
 *
 * Name: Adewale Adenuga Basic C assignment
 * (a) LED that will go on will be RA0
 * (b) Use timer0 to generate interrupt every second, then use a doubling of a number for fibonacci sequence
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
unsigned char twoCounter;
int fibonacciFirst = 0;
int fibonacciSecond = 1;
int next = 0;

void __interrupt (high_priority) high_ISR(void)
{
    if (INTCONbits.TMR0IF == 1) {
        //twoCounter = twoCounter + 1;
        TMR0H = 0x48;
        TMR0L = 0x29;
        
        INTCONbits.TMR0IF = 0;

        twoCounter= twoCounter + 1;
        if ((twoCounter % 2) == 0) { //divide twocounter by 2 to ensure 2 seconds
            next = fibonacciFirst + fibonacciSecond;
            fibonacciFirst = fibonacciSecond;
            fibonacciSecond = next;
            if (next >= 255) {
                fibonacciFirst = 0;
                fibonacciSecond = 1;
            }
            
        }
        //LATA = twoCounter;
        
        if (LATCbits.LATC1 == 1) {
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
    TRISB = 0xFF ; //Define PORTB as output
    LATC = 0x00; //Initial PORTC
    TRISC = 0x00; //Define PORTC as output
}

void initTimer(void) {
    //Use timer0 in 16 bit mode to generate interrupt every second
    T0CON = 0x07;
    INTCON = 0x20;
    //period is 1s, frequency 1Hz
    //prescaler is 256, counter needs to count 1/83ns*256 = 47063
    //Initialize counter with 65536 - 47063 = 18473 which is 0x4829
    TMR0H = 0x48;
    TMR0L = 0x29;
    
    T0CONbits.TMR0ON = 1;
    INTCONbits.TMR0IF = 0;
    INTCONbits.GIE = 1;
}

void main()
{
    initChip();
    initTimer();
    
    while(1) 
    {
        
        //For (a) of basic C assignment
//        if (PORTBbits.RB0 == 1) {
//            LATA = 1;
//        } else {
//            LATA = 0;
//        }

        LATA = next;
    } 
} // End of Main function