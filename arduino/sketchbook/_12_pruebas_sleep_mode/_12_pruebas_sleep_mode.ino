/*
 * Example to test sleeping modes in AT328P chip
 * to interrupts used. First one attached to pin 3 puts the micro in sleep mode
 * Second one attached to pin 2 wake up the chip
 * A periodid function is called.
 * Serial interface is used to send commands to the arduino
 */
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
//#include <Wire.h>
//#include <Fifo.h>
#include <Streaming.h>
#include <avr/power.h>
#include <avr/sleep.h>

const int GreenLED = 12;
const int RedLED = 11;
const int SleepPin = 3;
const int WakeUpPin = 2;
const int debounceDelay = 10;

void setup()
{
  pinMode(GreenLED, OUTPUT);
  pinMode(RedLED, OUTPUT);
  Serial.begin(9600);
  setTime(0,0,0,7,1,78);
  Alarm.timerRepeat(2,sendtime);

  attachInterrupt(0,pin2int,FALLING);
  attachInterrupt(1,pin3int,FALLING);
  digitalWrite(2,HIGH);
  digitalWrite(3,HIGH);
}

void pin2int()
{
  detachInterrupt(0);
  Serial.println("2");
  attachInterrupt(0,pin2int,FALLING);
}


void pin3int()
{
  detachInterrupt(1);
  Serial.println("3");
  attachInterrupt(1,pin3int,FALLING);
}


void serialEvent()
{
  char ch = Serial.read();
  if (ch == 'D') {
    Serial << hour() << ":" << minute() << ":" << second();
    Serial.println();
    //blinking(RedLED,2,100);
  }
}

void sendtime()
{
  Serial << year() << "/" << month() << "/" << day()<< " " << hour() << ":" << minute() << ":" << second();
  Serial.println();
  //blinking(GreenLED,5,100);
}

void blinking(int pin, int times, int period)
{
  for (int c=0; c<times; c++)
  {
    digitalWrite(pin,HIGH);
    delay(period);
    digitalWrite(pin,LOW);
    delay(period);
  }  
}

void loop()
{  
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
}

