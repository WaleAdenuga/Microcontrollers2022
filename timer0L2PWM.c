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
#include <pic18f25k50.h>

/*
 * Prototypes
 */
void __interrupt(high_priority) high_ISR(void); //high priority interrupt routine
void __interrupt(low_priority) low_ISR(void); //low priority interrupt routine, not used in this example
void initChip(void);
void initPWM(void);

/*
 * Global Variables
 */
volatile int counter = 0; //0 for upcounter, 1 for downcounter
unsigned char toggle = 0; //0 for sawtooth, 1 for triangle
unsigned char t2Value = 0;
unsigned char state = 0; // 0 for sawtooth, 1 for triangle
/*
 * Interrupt Service Routines
 */

/********************************************************* 
    Interrupt Handler
 **********************************************************/
void __interrupt(high_priority) high_ISR(void) {
    if (PIR1bits.TMR2IF == 1) {
        t2Value = 1; //alert timer2 has an interrupt for use in the main processing
        PIR1bits.TMR2IF = 0; //CLEAR interrupt flag when you are done!!!
    }


}

/*
 * Functions
 */

/*************************************************
           Main
 **************************************************/
void main(void) {
    initChip();
    initPWM();
    while (1) {
        if (t2Value == 1) { //tmr2 interrupt reached
            if (PORTAbits.RA3 == 0) { // 0 is for sawtooth
                if (CCPR2L <= 1) { //PR2 is 74
                    CCPR2L = PR2;
                }
                CCPR2L--;
            } else if(PORTAbits.RA3 == 1) { //1 for triangle, increases, reaches a point and then decreases
                if (counter == 0) { //0 is upcounter
                    if (CCPR2L < PR2) {
                        CCPR2L++;
                    } else counter = 1; //switch to downcounter at a point
                } else {
                    if (CCPR2L > 1) {
                        CCPR2L--;
                    } else counter = 0; //revert to upcounter when register is 1

                }

            }
            t2Value = 0; //clear interrupt flag at the end
        }

    }
}

/*************************************************
            Initialize the CHIP
 **************************************************/
void initChip(void) {
    //CLK settings
    OSCTUNE = 0x80; //3X PLL ratio mode selected
    OSCCON = 0x70; //Switch to 16MHz HFINTOSC
    OSCCON2 = 0x10; //Enable PLL, SOSC, PRI OSC drivers turned off
    while (OSCCON2bits.PLLRDY != 1); //Wait for PLL lock
    ACTCON = 0x90; //Enable active clock tuning for USB operation

    LATA = 0x00; //Initial PORTA
    TRISA = 0xFF; //Define PORTA as input
    ADCON1 = 0x00; //AD voltage reference
    ANSELA = 0x00; // define analog or digital
    CM1CON0 = 0x00; //Turn off Comparator
    LATB = 0x00; //Initial PORTB
    TRISB = 0x00; //Define PORTB as output
    LATC = 0x00; //Initial PORTC
    TRISC = 0x00; //Define PORTC as output
    INTCONbits.GIE = 0; // Turn Off global interrupt
}

/*************************************************
            Initialize the PWM
 **************************************************/
void initPWM(void) {

    //First enable global and peripheral interrupts
    INTCONbits.GIE = 1;
    INTCONbits.PEIE_GIEL = 1;
    //We're using the 2nd ccpcon register
    //pin RC1 is the PWM output
    //disable output driver, make it an input
    TRISCbits.RC1 = 1;

    PR2 = 74;
    CCP2CON = 0b00001100;
    CCPR2L = 0;
    T2CON = 0b00000010;
    TMR2 = 0x00;

    PIE1bits.TMR2IE = 1;
    PIR1bits.TMR2IF = 0; //clear interrupt flag first
    T2CONbits.TMR2ON = 1; //turn on timer2
    //Enable pwm output pin
    TRISCbits.RC1 = 0;
}