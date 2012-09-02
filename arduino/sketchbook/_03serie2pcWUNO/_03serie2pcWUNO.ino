/* 
 * ************** PRUEBA DE ENVIO RECEPCION POR PUERTO SERIE ***********
 * El sketch envia el estado del pin 5 por el puerto serie
 * y pone el pin 11 al valor del pin 5.
 * El obejetivo es leer estos valores desde una aplicacion
 * escrita en C desde el pc
 */

#define VERSION "1.00a0"


int BUTTON = 5; // con una resistencia de 10k conectada a GND
int LED = 11;

void setup() {
  pinMode(BUTTON,INPUT);
  pinMode(LED,OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // si se activa la entsend a capital D over the serial port if the button is pressed
  if (digitalRead(BUTTON) == HIGH) {
    Serial.print(1);
    delay(10); // prevents overwhelming the serial port
    digitalWrite(LED, HIGH);
  }
  else {
    Serial.print(0);
    delay(10);
    digitalWrite(LED, LOW);
  }
  delay(500);
}
