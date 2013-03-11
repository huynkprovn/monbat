/*
 * sLed.h - Library for implement multiple Leds driving thougth one data pin 
 * and serial to paralel register/latch
 * Implemented for use with 74*595 family devices
 * 
*/

#ifndef sLed_h
#define sLed_h

#include <Arduino.h>
class sLed
{
    public:
        sLed(unsigned int DataPin, unsigned int shiftCkPin, unsigned int latchCkPin, unsigned int rstPin, unsigned int BaudRate);
        //sLed(unsigned int DataPin, unsigned int shiftCkPin, unsigned int latchCkPin, unsigned int rstPin, unsigned int lenght);
        void Clear();
        void Write(byte data);
        void Write(word data);
    
    private:
        unsigned int _Dat; // Pin attached to the serial pin in the shift register
        unsigned int _Ck; // Pin attached to the shift clock pin in the shift register
        unsigned int _LchCk; //Pin atrached to the latch clock pin in the shift register
        unsigned int _Clr; //Pin attache to the reset pin in the register
        //int _lenght;
        unsigned int _BaudRate;
        unsigned long _period;           
        
        
};  
#endif
