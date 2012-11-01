/*
 * Ejemplo para probar interrupciones en Arduino 
 */
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
//#include <Wire.h>
//#include <Fifo.h>
#include <Streaming.h>

const int GreenLED = 12;
const int RedLED = 11;
const int InterruptPin = 2;

void setup()
{
  pinMode(GreenLED, OUTPUT);
  pinMode(RedLED, OUTPUT);
  pinMode(InterruptPin, INPUT);
  digitalWrite(InterruptPin,HIGH);
  attachInterrupt(0,interrupHandler,CHANGE);
  Serial.begin(9600);
}

void interrupHandler()
{
  switch(digitalRead(InterruptPin))
  {
  case HIGH:
    attachInterrupt(0,interrupHandler,LOW);
    digitalWrite(GreenLED,HIGH);
    delay(1000);
    digitalWrite(GreenLED,LOW);
    //Serial.println("High level interrupt detection");
    Serial.println("1");
    attachInterrupt(0,interrupHandler,LOW);
  case LOW:
    
    digitalWrite(RedLED,HIGH);
    delay(1000);
    digitalWrite(RedLED,LOW);
    //Serial.println("Low level interrupt detection");
    Serial.println("0");
    attachInterrupt(0,interrupHandler,HIGH);
  }
    
}

void loop()
{
  while (true)
  {
    delay(10);
  }
  
}


