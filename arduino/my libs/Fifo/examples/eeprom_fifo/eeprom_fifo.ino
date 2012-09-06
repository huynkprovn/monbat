/*
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
const int FRAME_LENGHT = 5;   // Frame write in FIFO (h,m,s,Dhigh, Dlow)
const unsigned int MAX_LENGHT = 127; //EEPROM Max lenght in bytes

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
  setTime(16,21,0,1,9,12);
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
      data = fifo.Read();
      Serial.print("At ");
      Serial.print(data);
      data = fifo.Read();
      Serial.print(":");
      Serial.print(data);
      data = fifo.Read();
      Serial.print(":");
      Serial.print(data);
      data = fifo.Read();
      Serial.print(" Sensor Value");
      Serial.print(data);
      data = fifo.Read();
      Serial.println(data);
      
       //
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
  fifo.Write(hour());
  fifo.Write(minute());
  fifo.Write(second());
  
  //Serial.println(highByte(sensor),HEX);
  //Serial.println(lowByte(sensor),HEX);
  fifo.Write(highByte(sensor));
  fifo.Write(lowByte(sensor));
  fifo.Block(false); // 
  
}

void loop()
{
  digitalWrite(emptyLED, fifo.Empty());
  digitalWrite(fullLED, fifo.Full());
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??


}


