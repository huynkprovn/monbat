#include <SoftwareSerial.h>  // Used for a serial debug connection (this library is only for Arduino 1.0 or later

SoftwareSerial debugConn(9,10); //Rx, Tx arduino digital port for debug serial connection

unsigned int Dat = 7; // Pin attached to the serial pin in the shift register
unsigned int Ck = 5; // Pin attached to the shift clock pin in the shift register
unsigned int LchCk = 4; //Pin atrached to the latch clock pin in the shift register
unsigned int Clr = 6; //Pin attache to the reset pin in the register
//int lenght;
int BaudRate = 300 ;
long period = 400000;

byte data;

void setup() {
  data=0;
  debugConn.begin(9600);
  debugConn.print("periodo = ");
  debugConn.print(period);
  debugConn.println("microsegundos");
  pinMode(Dat, OUTPUT);
  pinMode(Ck, OUTPUT);
  pinMode(LchCk, OUTPUT);
  pinMode(Clr, OUTPUT);
  digitalWrite(Dat, LOW);
  digitalWrite(Ck, HIGH);
  digitalWrite(LchCk, HIGH);
  digitalWrite(Dat, HIGH);
  digitalWrite(Clr, LOW);
  debugConn.println("Reset Activado");
  digitalWrite(Clr, HIGH);
  delayMicroseconds(long(period/2));
  debugConn.println("Reset Desactivado");
}

void blink_led(int times, int period)
{
  for (int x=0; x<=times; x++)
  {
    digitalWrite(13,HIGH);
    delay(period);
    digitalWrite(13,LOW);
    delay(period);
  }  
}


void loop(){
  //led.Write(data);
  digitalWrite(Ck, LOW);
  debugConn.println("ck=0");
  digitalWrite(LchCk,LOW);
  debugConn.println("Lck=0");
    
    for(int k = 0; k < 8; k++){
        delayMicroseconds(long(period/4));
        digitalWrite(Dat,bitRead(data,k));
        debugConn.print("D=");
        debugConn.println(bitRead(data,k));
        delayMicroseconds(long(period/4));
        digitalWrite(Ck,HIGH);
        debugConn.println("ck=1");
        delayMicroseconds(long(period/2));
        digitalWrite(Ck, LOW);
        debugConn.println("ck=0");
    }
    delayMicroseconds(int(period/4));
    digitalWrite(LchCk, HIGH);
    debugConn.println("Lck=1");
    delayMicroseconds(long(period/2));
    digitalWrite(LchCk, LOW);
    debugConn.println("Lck=0");
  
  blink_led(1,300);
  delay(500);
  if (data == 16){
    data=0;
    debugConn.println("Data = 0 ");
  } else{
    data++;
    debugConn.print("Data =");
    debugConn.println(data);
  }

}
