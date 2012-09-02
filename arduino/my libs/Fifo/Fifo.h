/*
 * Fifo.h - Library for implement FIFO mem structure in external 
 * I2C EEPROM memories whith Arduino
 * 
*/

#ifndef Fifo_h
#define Fifo_h

#include <Arduino.h>
#include <wire.h>

class Fifo
{
    public:
        
        void FIFO_Write(byte data);
        byte FIFO_Read();
        boolean FIFO_Empty();
        boolean FIFO_Full();
        boolean FIFO_Busy();
        void FIFO_Block();
        
        
    private:
        Fifo(byte _EEPROM_ID);  // Addres for I2C EEPROM memory
        Fifo(int _FRAME_LENGH); // 
        Fifo(unsigned int _MAX_LENGH); // FIFO lengh
        Fifo(unsigned int _t_address); // FIFO tail
        Fifo(unsigned int _h_address); // FIFO head}
        Fifo(boolean full);
        Fifo(boolean empty);
        Fifo(boolean busy); // FIFO is being accesed

#endif
