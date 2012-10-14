
/*
 * 
 */
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
#include <Wire.h>
#include <Fifo.h>
#include <Streaming.h>

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
  unsigned long fecha;
  
  while(Serial.available())
  {
    
    while (fifo.Busy()) // FIFO is not being accesed
      ;
    fifo.Block(true); //  
    fecha = 0;
    char ch = Serial.read();
    if (ch == 'D') {
      if (fifo.Empty()){
        Serial.println("FIFO is empty");
        fifo.Block(false);
        return;
      }
      for (int i = 0; i < 4; i++){
        data = fifo.Read();
        Serial << data << "   " << i << "   " << ceil(pow(int(255),int(i)));
        Serial.println();        
        fecha = fecha + (data * ceil(pow(int(255),int(i))));   //Hay un problema con la funcion
                                            // pow(). trabaja en coma flotante y por alguna razon que
                                            // aun no comprendo no realiza bien las pontencias.
                                            // los datos se almacenan bien en la fifo.!!!
      }
      Serial.println(fecha);
    }
  fifo.Block(false);    
  }      
}      


void captureData()
{
  time_t fecha;
  fecha = now();
  Serial.println(fecha);
  
  while (fifo.Busy()) // FIFO is not being accesed
      ;
  fifo.Block(true); //  
    
  while (fecha != 0 ){
    fifo.Write(fecha%255);
    //Serial << fecha << "   " << byte(fecha % 256);
    //Serial.println(); 
    fecha /= 255;    
  }
 
  fifo.Block(false); //    
}

void loop()
{
//  digitalWrite(emptyLED, fifo.Empty());
//  digitalWrite(fullLED, fifo.Full());
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??


}


