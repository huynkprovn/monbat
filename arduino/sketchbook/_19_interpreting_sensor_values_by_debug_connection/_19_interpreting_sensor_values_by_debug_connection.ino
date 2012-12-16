#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
#include <MsTimer2.h>
#include <SoftwareSerial.h>  // Used for a serial debug connection

float charge;
float i, iprev;
float v;

time_t charge_init;
time_t charge_end;
time_t drain_init;
time_t drain_end;
SoftwareSerial debugCon(9,10); //RX,TX

void setup()
{
  Serial.begin(9600);
  debugCon.begin(9600);
  setTime(18,15,0,15,12,12);
  
  //Alarm.timerRepeat(1,captureData);
  charge = 0.0000;
  i=0.0000;
  iprev=0.0000;
  v=0.0000;
  MsTimer2::set(500, captureData); // 500ms period
  MsTimer2::start();
}

void captureData()
{
  v=voltaje(analogRead(0));
  i=current(analogRead(1));
  charge = calc_ah_drained(iprev, i, charge, 1);
  
  debugCon.print(now());
  debugCon.print(" :  Voltaje : ");  
  debugCon.print(v);
  debugCon.print("Vdc,  Corriente : ");
  debugCon.print(i);
  debugCon.print("A,  Carga : ");
  debugCon.print(charge);
  debugCon.print("Ah,    ");
  debugCon.println(charge*100/500);
  
  
  iprev=i;
}

float voltaje(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)+4.1030)/0.4431);
}


float current(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)-1.6471)/0.0063);
}


float temperature(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)-0.5965)/0.0296);
}

float calc_ah_drained(float sa0, float sa1, float ah0, int fs)
{
  return (float(fs)/3600)*((sa0+sa1)/2)+ah0;
}

float curr_average(float ah, time_t ch_inic)
{
  return (ah*3600/(now()-ch_inic));  //  ah/time(h)
}

void loop()
{
  //Alarm.delay(10); 
  delay(10);
}
