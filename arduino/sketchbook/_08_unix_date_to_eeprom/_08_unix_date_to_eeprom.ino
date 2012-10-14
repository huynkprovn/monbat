
/*
 * I2C EEPROM sketch
 * this version for 24LC256
 * implements a fifo of MAX_LENGHT capacity
 * don´t prevent the FIFO Overflow. When FIFO is full
 * overwrite older data and move tail address to the next oldest data.
 
 */
#include <Wire.h>
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files

const byte EEPROM_ID = 0x50;      // I2C address for 24LC128 EEPROM

unsigned int w_address, r_address;
byte d_hour, d_minute, d_second;
time_t fecha;

void setup()
{
  w_address = 0;
  r_address = 0;
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
    char ch = Serial.read();
    if (ch == 'D') {
      Serial.print("r_add: ");
      Serial.print(r_address);
      Serial.print("\t");
      data = I2CEEPROM_Read();
      Serial.println(data);
    }    
  }      
}      
      
      
void captureData()
{
  Wire.beginTransmission(EEPROM_ID);
  Wire.write((int)highByte(w_address));
  Wire.write((int)lowByte(w_address));
  Serial.println(char(now()),DEC);
  Wire.write(char(now()));
  Wire.endTransmission();
  delay (5);
  w_address++;
}

void loop()
{
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
}


// This function is similar to EEPROM.read()
byte I2CEEPROM_Read()
{
  byte data;
  Wire.beginTransmission(EEPROM_ID);
  Wire.write((int)highByte(r_address) );
  Wire.write((int)lowByte(r_address) );
  Wire.endTransmission();
  Wire.requestFrom(EEPROM_ID,(byte)1);
  while(Wire.available() == 0) // wait for data
    ;
  data = Wire.read();
  
  r_address++;
  
  return data;
}

