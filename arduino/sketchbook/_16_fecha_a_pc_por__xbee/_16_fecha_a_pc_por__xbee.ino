
/*
 * 
 */
  #include <Time.h>
  #include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                          // to add the Arduino.h in the include files
  #include <XBee.h>
  #include <Wire.h>
  #include <Fifo.h>
  #include <Streaming.h>


// create the XBee object
XBee xbee = XBee();

uint8_t payload[] = { 0, 0, 0, 0 };

// SH + SL Address of receiving XBee
XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, 0x408C51AB);
ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
XBeeResponse response = XBeeResponse();
// create reusable response objects for responses we expect to handle 
ZBRxResponse rx = ZBRxResponse();
ModemStatusResponse msr = ModemStatusResponse();
  


void setup()
{
  
  xbee.begin(9600);
  //Serial.begin(9600);
  
  setTime(11,0,0,17,11,2012);
  //Alarm.timerRepeat(2,captureData);

}


void serialEvent()
{
  byte data;
  time_t fecha;
  //unsigned long fecha;
  unsigned int k;
  
  xbee.readPacket();
    
  if (xbee.getResponse().isAvailable()) {
    // got something
    
    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
      // got a zb rx packet
      
      // now fill our zb rx class
      xbee.getResponse().getZBRxResponse(rx);
          
      if (rx.getOption() == ZB_PACKET_ACKNOWLEDGED) {
          // the sender got an ACK
          
      } else {
          // we got it (obviously) but sender didn't get an ACK
      }
      // set dataLed PWM to value of the first byte in the data
      
      //analogWrite(dataLed, rx.getData(0));
      
      
      fecha = now();
      k = 3;
      while (fecha != 0 ){
        payload[k] = fecha%255;
        fecha /= 255;
        k -= 1;    
      }
      xbee.send(zbTx);
              
    }
  } else if (xbee.getResponse().isError()) {
    //nss.print("Error reading packet.  Error code: ");  
    //nss.println(xbee.getResponse().getErrorCode());
  }
}      

void loop()
{
//  digitalWrite(emptyLED, fifo.Empty());
//  digitalWrite(fullLED, fifo.Full());
  //Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
  delay(10);

}
