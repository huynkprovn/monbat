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
  power_all_enable();
  attachInterrupt(0,pin2int,FALLING);
}


void pin3int()
{
  detachInterrupt(1);
  Serial.println("3");
  /* Now is the time to set the sleep mode. In the Atmega8 datasheet
     * http://www.atmel.com/dyn/resources/prod_documents/doc2486.pdf on page 35
     * there is a list of sleep modes which explains which clocks and 
     * wake up sources are available in which sleep modus.
     *
     * In the avr/sleep.h file, the call names of these sleep modus are to be found:
     *
     * The 5 different modes are:
     *     SLEEP_MODE_IDLE         -the least power savings 
     *     SLEEP_MODE_ADC
     *     SLEEP_MODE_PWR_SAVE
     *     SLEEP_MODE_STANDBY
     *     SLEEP_MODE_PWR_DOWN     -the most power savings
     *
     *  the power reduction management <avr/power.h>  is described in 
     *  http://www.nongnu.org/avr-libc/user-manual/group__avr__power.html
       
  */   
  set_sleep_mode(SLEEP_MODE_IDLE);   // sleep mode is set here

  sleep_enable();          // enables the sleep bit in the mcucr register
                             // so sleep is possible. just a safety pin 
  
  //power_adc_disable();
  //power_spi_disable();
  //power_timer0_disable();
  //power_timer1_disable();
  //power_timer2_disable();
  //power_twi_disable();
  
  
  sleep_mode();            // here the device is actually put to sleep!!
 
                            // THE PROGRAM CONTINUES FROM HERE AFTER WAKING UP
  sleep_disable();         // first thing after waking from sleep:
                            // disable sleep...

  

  attachInterrupt(1,pin3int,FALLING);
}


void serialEvent()
{
  char ch = Serial.read();
  if (ch == 'D') {
    Serial << hour() << ":" << minute() << ":" << second();
    Serial.println();
    blinking(RedLED,2,100);
  }
}


void sendtime()
{
  Serial << year() << "/" << month() << "/" << day()<< " " << hour() << ":" << minute() << ":" << second();
  Serial.println();
  blinking(GreenLED,5,100);
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

