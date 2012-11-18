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
        Fifo(byte Eeprom_ID, unsigned int max_Lenght, unsigned int frame_Lenght);
        Fifo(byte Eeprom_ID, unsigned int base_Add, unsigned int max_Lenght, unsigned int frame_Lenght);
        void Write(byte data);
        byte Read();
        boolean Empty();
        boolean Full();
        boolean Busy();
        void Block(boolean busy);
        
        
    private:
        byte _EEPROM_ID;  // Addres for I2C EEPROM memory
        int _FRAME_LENGH; // 
        unsigned int _b_address; // FIFO base in the EEPROM memory
        unsigned int _MAX_LENGH; // FIFO lengh
        unsigned int _t_address; // FIFO tail
        unsigned int _h_address; // FIFO head}
        boolean _full;
        boolean _empty;
        boolean _busy; // FIFO is being accesed

};
#endif
