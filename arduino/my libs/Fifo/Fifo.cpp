/*
 * Fifo.cpp - Arduino FIFO memory using external I2C EEPROM memory
 *
 *
*/
#include <arduino.h>
#include <Wire.h>
#include "Fifo.h"

Fifo::Fifo(byte Eeprom_ID, unsigned int max_Lenght, unsigned int frame_Lenght);
{
    _EEPROM_ID = Eeprom_ID;
    _MAX_LENGHT = max_Lenght;
    _FRAME_LENGHT = frame_Lenght; 
    _t_address = 0;
    _h_address = 0;     
    _empty = true;
    _full = false;
    _busy = false;
    Wire.begin();
        
}

// PUBLIC METODS

void Fifo::FIFO_Write(byte data)
{
    Wire.beginTransmission(EEPROM_ID);
    Wire.write((int)highByte(_h_address));
    Wire.write((int)lowByte(_h_address));
    Wire.write(data);
    Wire.endTransmission();
    Serial.print("t_add: ");
    Serial.print(_t_address, DEC);
    Serial.print(", h_add: ");
    Serial.print(_h_address, DEC);
    Serial.print(", data: ");
    Serial.println(data, DEC);
    delay (5);
    _h_address++;
  
    if (_h_address > _MAX_LENGHT) {  //have reach the higer mem address
        _h_address = 0;
    }

    if (_empty) _empty = false; // if FIFO was empty, now not.
    if (_h_address == _t_address) { // FIFO full
        _full = true;
        _t_address += _FRAME_LENGHT; // Increment address to the next valid frame
        if (_t_address > _MAX_LENGHT) _t_address = (_t_address % _MAX_LENGHT) - 1; // Reset the value
    } 
}

byte Fifo::FIFO_Read()
{
    
    if (empty) return -1; // FIFO empty return error -1
  
    byte data;
    Wire.beginTransmission(EEPROM_ID);
    Wire.write((int)highByte(t_address) );
    Wire.write((int)lowByte(t_address) );
    Wire.endTransmission();
    Wire.requestFrom(EEPROM_ID,(byte)1);
    while(Wire.available() == 0) // wait for data
        ;
    data = Wire.read();
  
    t_address++;
  
    if (t_address > MAX_LENGHT) {  //have reach the higer mem address
        t_address = 0;
    }
  
    if (full) full = false; // If FIFO was full, now not.
    if (t_address == h_address){
        empty = true;
    }
    return data;
}

boolean FIFO::FIFO_Empty()
{
    return _empty;    
}


boolean FIFO::FIFO_Full()
{
    return _full;    
}


boolean FIFO::FIFO_Busy()
{
    return _busy;    
}

void FIFO::FIFO_Block(boolean busy)
{
    _busy = busy;
}
