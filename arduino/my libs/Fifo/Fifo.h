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
        
        void Write(byte data);
        byte Read();
        boolean Empty();
        boolean Full();
        boolean Busy();
        void Block(boolean busy);
        
        
    private:
        byte _EEPROM_ID;  // Addres for I2C EEPROM memory
        int _FRAME_LENGH; // 
        unsigned int _MAX_LENGH; // FIFO lengh
        unsigned int _t_address; // FIFO tail
        unsigned int _h_address; // FIFO head}
        boolean full;
        boolean empty;
        boolean busy; // FIFO is being accesed

};
#endif
