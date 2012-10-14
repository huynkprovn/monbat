/* WORK
 * I2C EEPROM sketch usin the Fifo.h library
 * this version for 24LC256
 * implements a fifo of MAX_LENGHT capacity
 * don´t prevent the FIFO Overflow. When FIFO is full
 * overwrite older data and move tail address to the next oldest data.
 
 */
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
#include <Wire.h>
#include <Fifo.h>

const byte EEPROM_ID = 0x50;      // I2C address for 24LC128 EEPROM
const int FRAME_LENGHT = 8;   // Frame write in FIFO (h,m,s,Dhigh, Dlow)
const unsigned int MAX_LENGHT = 256; //EEPROM Max lenght in bytes

const int fullLED = 11;
const int emptyLED = 12;
const int sensorPIN = 1;

Fifo fifo(EEPROM_ID, MAX_LENGHT, FRAME_LENGHT);

void setup()
{
  pinMode(fullLED, OUTPUT);
  pinMode(emptyLED, OUTPUT);
  
  Serial.begin(9600);
  Wire.begin();
  setTime(16,0,0,14,10,2012);
  Alarm.timerRepeat(2,captureData);

}

void serialEvent()
{
  byte data;

  while(Serial.available())
  {
    
    while (fifo.Busy()) // FIFO is not being accesed
      ;
    fifo.Block(true); //  
    
    char ch = Serial.read();
    if (ch == 'D') {
      if (fifo.Empty()){
        Serial.println("FIFO is empty");
        fifo.Block(false);
        return;
      }
      data = fifo.Read(); //second
      Serial.print("At ");
      Serial.print(data, DEC);
      data = fifo.Read(); //minute
      Serial.print(":");
      Serial.print(data, DEC);
      data = fifo.Read(); //hour
      Serial.print(":");
      Serial.print(data, DEC);
      data = fifo.Read(); //day
      Serial.print(" ");
      Serial.print(data, DEC);
      data = fifo.Read(); //mouth
      Serial.print("-");
      Serial.print(data, DEC);
      data = fifo.Read(); //year hight
      Serial.print("-");
      Serial.print(word(data,fifo.Read()), DEC);
    }
  fifo.Block(false);    
  }      
}      


void captureData()
{
  word sensor;
  
  sensor = analogRead(sensorPIN);
  while (fifo.Busy()) // FIFO is  being accesed
      ;
  fifo.Block(true); //
  fifo.Write(second());
  fifo.Write(minute());
  fifo.Write(hour());
  fifo.Write(day());
  fifo.Write(month());
  fifo.Write(highByte(year()));
  fifo.Write(lowByte(year()));
  
  //Serial.println(highByte(sensor),HEX);
  //Serial.println(lowByte(sensor),HEX);
  fifo.Block(false); // 
  
}

void loop()
{
  digitalWrite(emptyLED, fifo.Empty());
  digitalWrite(fullLED, fifo.Full());
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??


}


