/*********************************************************************************************************************
 *
 * FileName:        main.c
 * Processor:       PIC18F25K50
 * Compiler:        MPLAB XC8
 * Comment:         Main code
 * Dependencies:    Header (.h) files if applicable, see below
 *
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Author                       Date                Version             Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Eva Andries	                12/10/2018          0.1                 Initial release
 * Eva Andries					 6/11/2018			1.0					XC8 v2.00 new interrupt declaration
 * Tim Stas                     12/11/2018          1.1                 volatile keyword: value can change beyond control of code section
 * Tim Stas						15/07/2019			2.0					PIC18F25K50
 * G.S.							2020									fixed CLK settings
 * G.S.							27/07/2021								updated comments
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * TODO                         Date                Finished
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *********************************************************************************************************************/

/*
 * Includes
 */
#include <xc.h>

/*
 * Prototypes
 */
void __interrupt (high_priority) high_ISR(void);   //high priority interrupt routine
void __interrupt (low_priority) low_ISR(void);  //low priority interrupt routine, not used in this example
void initChip(void);
void initTimer(void);
void initADC(void);

/*
 * Global Variables
 */
volatile int  counter = 0;
unsigned char adc_value; //left-justified, only the first 8 bits matter
/*
 * Interrupt Service Routines
 */
/********************************************************* 
	Interrupt Handler
**********************************************************/
void __interrupt (high_priority) high_ISR(void)
{
	if(INTCONbits.TMR0IF == 1)
     {
        counter += 1;
         TMR0L = 0xD1;    			//reload the value 209 to the Timer0
         INTCONbits.TMR0IF=0;     //CLEAR interrupt flag when you are done!!!
         //start the AD conversion when timer is done
         ADCON0bits.GO = 1;
     }
    
    if (PIR1bits.ADIF == 1) { //check if interrupt is a result of ADC
        adc_value = ADRESH;
        PIR1bits.ADIF = 0; //clear flag when finished
        //ADCON0bits.GO = 0; //automatically cleared by hardware when conversion is completed
    }
}

/*
 * Functions
 */


/*************************************************
			Initialize the CHIP
**************************************************/
void initChip(void)
{
	//CLK settings
	OSCTUNE = 0x80; //3X PLL ratio mode selected
	OSCCON = 0x70; //Switch to 16MHz HFINTOSC
	OSCCON2 = 0x10; //Enable PLL, SOSC, PRI OSC drivers turned off
	while(OSCCON2bits.PLLRDY != 1); //Wait for PLL lock
	ACTCON = 0x90; //Enable active clock tuning for USB operation

    LATA = 0x00; //Initial PORTA
    TRISA = 0xFF; //Define PORTA as input, RA1 is analog input
    ADCON1 = 0x00; //AD voltage reference
    ANSELA = 0x00; // define analog or digital
    CM1CON0 = 0x00; //Turn off Comparator
    LATB = 0x00; //Initial PORTB
    TRISB = 0x00; //Define PORTB as output
    LATC = 0x00; //Initial PORTC
    TRISC = 0x00; //Define PORTC as output
	INTCONbits.GIE = 0;	// Turn Off global interrupt
}

/*************************************************
			Initialize the TIMER
**************************************************/
void initTimer(void)
{
    T0CON =0x47;    //Timer0 Control Register  //0b01000111
               		//bit7 "0": Disable Timer
               		//bit6 "1": 8-bit timer
               		//bit5 "0": Internal clock
               		//bit4 "0": not important in Timer mode
               		//bit3 "0": Timer0 prescale is assigned
               		//bit2-0 "111": Prescale 1:256  
    /********************************************************* 
	     Calculate Timer 
             F = Fosc/(4*Prescale*number of counting)
	**********************************************************/

    
    TMR0L = 0xD1;    //Initialize the timer value
    //Initialize with value 209 with prescale of 256 and accuracy 997Hz
    //Stolen from Professor Luc Geurts in lecture 8
    

    /*Interrupt settings for Timer0*/
    INTCON= 0x20;   /*Interrupt Control Register //0b00100000
               		//bit7 "0": Global interrupt Enable
               		//bit6 "0": Peripheral Interrupt Enable
               		//bit5 "1": Enables the TMR0 overflow interrupt
               		//bit4 "0": Disables the INT0 external interrupt
               		//bit3 "0": Disables the RB port change interrupt
               		//bit2 "0": TMR0 Overflow Interrupt Flag bit
                    //bit1 "0": INT0 External Interrupt Flag bit
                    //bit0 "0": RB Port Change Interrupt Flag bit
                     */
    
    T0CONbits.TMR0ON = 1;  //Enable Timer 0
    INTCONbits.GIE = 1;    //Enable interrupt
}

void initADC(void) {
    ANSELA = 0x01;//set pin RA0 as analog input
    ADCON1 = 0x00;//configure Vss & Vdd //0b00000000//connected to internal signal Vdd and Vss
    ADCON0 = 0x00;//select input channel AN0 //0b00000001
    ADCON2 = 0b00011110;//left justified, 6 Tad, Fosc/64 clock because values violate minimum required TAD time
    //Tc = -13.5pF(1000+7000+2500)In(.0004885)
    //Tacq = 5µs + .432µs + [25(.05)] = 6.682µs
    //acqs = 6.682/1.3 = 5
    //choose 6 Tad for acqusition time
    
    ADCON0bits.ADON = 1;//turn AD on
    INTCONbits.PEIE_GIEL = 1;//allow peripheral interrupts
    INTCONbits.GIE = 1; //enable global interrupt enable
    PIE1bits.ADIE = 1;   //enable AD interrupt
    PIR1bits.ADIF = 0;    // Clear the flag bit!!!
}

 /*************************************************
			Main
**************************************************/
void main(void)
{
    initChip();
    initTimer();
	initADC();
    //counter = 0;
    while(1)    //Endless loop
    {

        LATB = adc_value;    //Give adc_value to PORTB
        

    }
}