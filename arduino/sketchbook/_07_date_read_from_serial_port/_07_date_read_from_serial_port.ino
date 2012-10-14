#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
//#include <Wire.h>
//#include <Fifo.h>

const byte EEPROM_ID = 0x50;      // I2C address for 24LC128 EEPROM
const int FRAME_LENGHT = 5;   // Frame write in FIFO (h,m,s,Dhigh, Dlow)
const unsigned int MAX_LENGHT = 255;

//Fifo fifo(EEPROM_ID, MAX_LENGHT, FRAME_LENGHT);

void setup()
{
  
  Serial.begin(9600);
  //Wire.begin();
  setTime(14,0,0,13,10,12);
  Alarm.timerRepeat(2,captureData);

}

void captureData()
{
  word sensor;
  Serial.println(now());
  Serial.print(second());
  Serial.print(":");
  Serial.print(minute());
  Serial.print(":");
  Serial.print(hour());
  Serial.print(" ");
  Serial.print(day());
  Serial.print("-");
  Serial.print(month());
  Serial.print("-");
  Serial.println(year());
  
    
}

void loop()
{
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
}
