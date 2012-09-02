
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
const int FRAME_LENGHT = 5;   // Frame write in FIFO (h,m,s,Dhigh, Dlow)
const unsigned int MAX_LENGHT = 63; //EEPROM Max lenght in bytes

const int fullLED = 11;
const int emptyLED = 12;
const int sensorPIN = 1;

// first visible ASCII character '!' is number 33:
// int thisByte = 33;
unsigned int t_address = 0; // FIFO tail
unsigned int h_address = 0; // FIFO head
boolean full = false;
boolean empty = true;
boolean busy = false; // FIFO is being accesed

byte d_hour, d_minute, d_second;

/*
boolean I2CEEPROM_Write(unsigned int &h_address, unsigned int &t_address, byte data);
boolean I2CEEPROM_Read(unsigned int &h_address, unsigned int &t_address, byte &data);
*/

void setup()
{
  pinMode(fullLED, OUTPUT);
  //digitalWrite(fullLED, full);
  pinMode(emptyLED, OUTPUT);
  //digitalWrite(emptyLED, empty);

  Serial.begin(9600);
  Wire.begin();
  setTime(16,21,0,1,9,12);
  Alarm.timerRepeat(2,captureData);

}

void serialEvent()
{
  //boolean f_e; // FIFO Empty
  byte data;

  while(Serial.available())
  {
    while (busy) // FIFO is not being accesed
      ;
    busy = true; //  
    
    char ch = Serial.read();
    if (ch == 'D') {
      if (empty){
        Serial.println("FIFO is empty");
        busy = false;
        return;
      }
      data = I2CEEPROM_Read();
      Serial.print("At ");
      Serial.print(data);
      data = I2CEEPROM_Read();
      Serial.print(":");
      Serial.print(data);
      data = I2CEEPROM_Read();
      Serial.print(":");
      Serial.print(data);
      data = I2CEEPROM_Read();
      Serial.print(" Sensor Value");
      Serial.print(data);
      data = I2CEEPROM_Read();
      Serial.println(data);
      
      Serial.print("t_add: ");
      Serial.print(t_address, DEC);
      Serial.print(", h_add: ");
      Serial.println(h_address, DEC);
      
      busy = false; //
    }    
  }      
}      
      
      
void captureData()
{
  word sensor;
  
  sensor = analogRead(sensorPIN);
  while (busy) // FIFO is  being accesed
      ;
  busy = true; //
  I2CEEPROM_Write(hour());
  I2CEEPROM_Write(minute());
  I2CEEPROM_Write(second());
  
  //Serial.println(highByte(sensor),HEX);
  //Serial.println(lowByte(sensor),HEX);
  I2CEEPROM_Write(highByte(sensor));
  I2CEEPROM_Write(lowByte(sensor));
  busy = false; // 
  
}

void loop()
{
  digitalWrite(emptyLED, empty);
  digitalWrite(fullLED, full);
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??


}


// Write one byte in the FIFO
void I2CEEPROM_Write(byte data)
{
  ///Serial.print("1");
  Wire.beginTransmission(EEPROM_ID);
  Wire.write((int)highByte(h_address));
  Wire.write((int)lowByte(h_address));
  Wire.write(data);
  Wire.endTransmission();
  Serial.print("t_add: ");
  Serial.print(t_address, DEC);
  Serial.print(", h_add: ");
  Serial.print(h_address, DEC);
  Serial.print(", data: ");
  Serial.println(data, DEC);
  delay (5);
  h_address++;
  
  if (h_address > MAX_LENGHT) {  //have reach the higer mem address
    h_address = 0;
  }

  if (empty) empty = false; // if FIFO was empty, now not.
  if (h_address == t_address) { // FIFO full
        full = true;
        t_address += FRAME_LENGHT; // Increment address to the next valid frame
        if (t_address > MAX_LENGHT) t_address = (t_address % MAX_LENGHT) - 1; // Reset the value
  }
}


// This function is similar to EEPROM.read()
byte I2CEEPROM_Read()
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

