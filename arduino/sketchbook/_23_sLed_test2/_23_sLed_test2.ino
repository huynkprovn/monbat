#include <sLed.h>

word data;
sLed led(7,5,4,6,900);

void setup(){ 
  led.Clear();
  
}

void loop(){ 
  for(int k=0; k<=100; k++){
    data=word(charge(k),temp_alarm(true)|level_alarm(true)|charge_alarm(true));
    led.Write(data);
    delay(10);
  }
  delay(1000);
  //led.Clear();
}


byte charge(unsigned int carga){
  byte res=0;
  if (carga>0 && carga<=12) {
    res|=B00000001;
  } else if (carga>12 && carga<=24) {
    res|=B00000011;
  } else if (carga>24 && carga<=36) {
    res|=B00000111;
  } else if (carga>36 && carga<=48) {
    res|=B00001111;
  } else if (carga>48 && carga<=50) {
    res|=B00011111;
  } else if (carga>50 && carga<=62) {
    res|=B00111111;
  } else if (carga>62 && carga<=88) {
    res|=B01111111;
  } else if (carga>88 && carga<=100) {
    res|=B11111111;
  } else {
    
  }
  return res;
}

byte temp_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,3);
 } else {
   bitSet(res,2);
 }
 return res;
}

byte level_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,5);
 } else {
   bitSet(res,4);
 }
 return res;
}

byte charge_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,7);
 } else {
   bitSet(res,6);
 }
 return res;
}
