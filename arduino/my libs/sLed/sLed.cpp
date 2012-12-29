/*
 * Fifo.cpp - Arduino FIFO memory using external I2C EEPROM memory
 *
 *
*/
#include <arduino.h>
#include "sLed.h"


unsigned int _Dat; // Pin attached to the serial pin in the shift register
unsigned int _Ck; // Pin attached to the shift clock pin in the shift register
unsigned int _LchCk; //Pin atrached to the latch clock pin in the shift register
unsigned int _Clr; //Pin attache to the reset pin in the register
int _lenght;
int _BaudRate;
long _period;           
        

//sLed::sLed(unsigned int DataPin, unsigned int shiftCkPin, unsigned int latchCkPin, unsigned int rstPin, unsigned int lenght, unsigned int BaudRate = 300)
sLed::sLed(unsigned int DataPin, unsigned int shiftCkPin, unsigned int latchCkPin, unsigned int rstPin, unsigned int lenght)
{
    _Dat = DataPin; // Pin attached to the serial pin in the shift register
    _Ck = shiftCkPin; // Pin attached to the shift clock pin in the shift register
    _LchCk = latchCkPin; //Pin atrached to the latch clock pin in the shift register
    _Clr = rstPin; //
    _lenght = lenght;
    _BaudRate=300;
    _period = long(1000000/_BaudRate);
    pinMode(_Dat, OUTPUT);
    pinMode(_Ck, OUTPUT);
    pinMode(_LchCk, OUTPUT);
    pinMode(_Clr, OUTPUT);
    digitalWrite(_Dat, LOW);
    digitalWrite(_Ck, HIGH);
    digitalWrite(_LchCk, HIGH);
    digitalWrite(_Dat, HIGH);
    digitalWrite(_Clr, HIGH);
    
    Clear();
}


//*************************************************************
void sLed::Clear()
{
    delayMicroseconds(long(_period/2));
    digitalWrite(_Clr, LOW);
    digitalWrite(_LchCk, LOW);
    
    delayMicroseconds(long(_period));
    digitalWrite(_Clr, HIGH);
    delayMicroseconds(long(_period/4));
    digitalWrite(_LchCk, HIGH);
    
}


//*************************************************************
void sLed::Write(byte data)
{
    digitalWrite(_Ck, LOW);
    digitalWrite(_LchCk,LOW);
    
    for(int k = 0; k < 8; k++){
        delayMicroseconds(long(_period/4));
        digitalWrite(_Dat,bitRead(data,k));
        delayMicroseconds(long(_period/4));
        digitalWrite(_Ck,HIGH);
        delayMicroseconds(long(_period/2));
        digitalWrite(_Ck, LOW);
    }
    delayMicroseconds(int(_period/4));
    digitalWrite(_LchCk, HIGH);
    delayMicroseconds(long(_period/2));
    digitalWrite(_LchCk, LOW);
        
}


//*************************************************************
void sLed::Write(word data)
{
    digitalWrite(_Ck, LOW);
    digitalWrite(_LchCk,HIGH);
    
    for(int k = 0; k < 16; k++){
        delayMicroseconds(long(_period/4));
        digitalWrite(_Dat,bitRead(data,k));
        delayMicroseconds(long(_period/4));
        digitalWrite(_Ck,HIGH);
        delayMicroseconds(long(_period/2));
        digitalWrite(_Ck, LOW);
    }
    delayMicroseconds(long(_period/4));
    digitalWrite(_LchCk, HIGH);
    delayMicroseconds(long(_period/2));
    digitalWrite(_LchCk, LOW);
        
}
