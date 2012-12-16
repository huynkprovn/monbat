#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification

float charge;
float i, iprev;
float v;
    
void setup()
{
  Serial.begin(9600);
  setTime(18,15,0,15,12,12);
  Alarm.timerRepeat(2,captureData);
  charge = 0.0000;
  i=0.0000;
  iprev=0.0000;
  v=0.0000;
}

void captureData()
{
  v=voltaje(analogRead(0));
  i=temperature(analogRead(1));
  charge = calc_ah_drained(iprev, i, charge, 1);
  
  Serial.print(now());
  Serial.print(" :  Voltaje : ");  
  Serial.print(v);
  Serial.print("Vdc,  Corriente : ");
  Serial.print(i);
  Serial.print("A,  Carga : ");
  Serial.print(charge);
  Serial.println("Ah");
  
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

void loop()
{
  Alarm.delay(10); 
}
