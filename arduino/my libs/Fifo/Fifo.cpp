/*
 * Fifo.cpp - Arduino FIFO memory using external I2C EEPROM memory
 *
 *
*/
#include <arduino.h>
#include <Wire.h>
#include "Fifo.h"

byte _EEPROM_ID;
unsigned int _MAX_LENGHT;
unsigned int _FRAME_LENGHT;
unsigned int _t_address = 0; // FIFO tail
unsigned int _h_address = 0; // FIFO head
boolean _full = false;
boolean _empty = true;
boolean _busy = false; // FIFO is being accesed


Fifo::Fifo(byte Eeprom_ID, unsigned int max_Lenght, unsigned int frame_Lenght)
{
    _EEPROM_ID = Eeprom_ID;
    _MAX_LENGHT = max_Lenght;
    _FRAME_LENGHT = frame_Lenght; 
    _b_address = 0;
    _t_address = 0;
    _h_address = 0;     
    _empty = true;
    _full = false;
    _busy = false;
}

Fifo::Fifo(byte Eeprom_ID, unsigned int base_Add, unsigned int max_Lenght, unsigned int frame_Lenght)
{
    _EEPROM_ID = Eeprom_ID;
    _MAX_LENGHT = max_Lenght;
    _FRAME_LENGHT = frame_Lenght; 
    _b_address = base_Add;
    _t_address = base_Add;
    _h_address = base_Add;     
    _empty = true;
    _full = false;
    _busy = false;
}

Fifo::Fifo(byte Eeprom_ID, unsigned int base_Add, unsigned int tail_Add, unsigned int head_Add, unsigned int max_Lenght, unsigned int frame_Lenght)
{
    _EEPROM_ID = Eeprom_ID;
    _MAX_LENGHT = max_Lenght;
    _FRAME_LENGHT = frame_Lenght; 
    _b_address = base_Add;
    _t_address = tail_Add;
    _h_address = head_Add;     
    if ((_t_address == _b_address) && (_h_address == _b_address)){
        _empty = true;
    } else {
        _empty = false;
    }
    if ((_t_address - _h_address) <= _FRAME_LENGHT){
        _full = true;
    } else {
        _full = false;
    }
    _busy = false;
}    

// PUBLIC METODS

void Fifo::Write(byte data)
{
    Wire.beginTransmission(_EEPROM_ID);
    Wire.write((int)highByte(_h_address));
    Wire.write((int)lowByte(_h_address));
    Wire.write(data);
    Wire.endTransmission();
    /*
    Serial.print("t_add: ");
    Serial.print(_t_address, DEC);
    Serial.print(", h_add: ");
    Serial.print(_h_address, DEC);
    Serial.print(", data: ");
    Serial.println(data, DEC);
    */
    delay (5);
    _h_address++;
  
    if (_h_address > _MAX_LENGHT) {  //have reach the highest mem address
        _h_address = _b_address;
    }

    if (_empty) _empty = false; // if FIFO was empty, now not.
    if (_h_address == _t_address) { // FIFO full
        _full = true;
        _t_address += _FRAME_LENGHT; // Increment address to the next valid frame
        if (_t_address > _MAX_LENGHT) _t_address = (_t_address % _MAX_LENGHT) - 1 + _b_address; // Reset the value
    } 
}

byte Fifo::Read()
{
    
    if (_empty) return -1; // FIFO empty return error -1
  
    byte data;
    Wire.beginTransmission(_EEPROM_ID);
    Wire.write((int)highByte(_t_address) );
    Wire.write((int)lowByte(_t_address) );
    Wire.endTransmission();
    Wire.requestFrom(_EEPROM_ID,(byte)1);
    while(Wire.available() == 0) // wait for data
        ;
    data = Wire.read();
  
    _t_address++;
  
    if (_t_address > _MAX_LENGHT) {  //have reach the highest mem address
        _t_address = _b_address;
    }
  
    if (_full) _full = false; // If FIFO was full, now not.
    if (_t_address == _h_address){
        _empty = true;
    }
    return data;
}


void Fifo::Clear()
{
    _t_address = _b_address;
    _h_address = _b_address;     
    _empty = true;
    _full = false;    
}


boolean Fifo::Empty()
{
    return _empty;    
}


boolean Fifo::Full()
{
    return _full;    
}


boolean Fifo::Busy()
{
    return _busy;    
}

void Fifo::Block(boolean busy)
{
    _busy = busy;
}

unsigned int Fifo::Get_tail()
{
    return _t_address;
}

unsigned int Fifo::Get_head()
{
    return _h_address;
}
