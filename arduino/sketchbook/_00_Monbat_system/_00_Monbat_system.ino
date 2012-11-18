/*
 * Description: MONBAT is a traction batteries monitoring system using Arduino, AutoIt and XBee
 *              This code is responsible for registering the values ​​of the sensors connected to 
 *              an Arduino FIO in an EEPROM memory and communicate using XBee with an application 
 *              on a PC.
 *              The code is written and tested using Arduino 1.0.1
 *              The Xbee used in communication are the 2 series ones configurated whith and 
 *              EndDevice Api mode firmware. For using the Xbee.h library the modems must be
 *              configurated in Api mode with escaped bytes. AP=2
 *
 * Changelog:
 *              Version 0.1.0    Add Xbee connection functionality. Send the oldest data stored in the FIFO
 *                               a ZBRx packet is recieved
 *              Version 0.0.2    Add debug mode conf for sending stored data for Serial port
 *              Version 0.0.1    Add digital and analog pins definition and first version of capturedata()
 *              Version 0.0.0    Initial structure and include files
 *
 */
 
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
#include <XBee.h>
#include <Wire.h>
#include <Fifo.h>       // This is a personal library. 
                      // http://code.google.com/p/monbat/source/browse/#svn%2Farduino%2Fmy%20libs%2FFifo
#include <Streaming.h>
#include <NewSoftSerial.h>  // Used for a serial debug connection

char VERSION[] = "MonBat system V0.1.0";
boolean debug = false;

// ******** XBEE PARAMETER DEFINITION ********
boolean ConnToApp = false;     // Used to determinate when an Xbee connection with the 
                              // PC app is established  
XBee xbee = XBee();  // Xbee object to manage the xbee connection 
// state capturated by the arduino. 4 bytes for time, 2 bytes for V+, 2 bytes for V-
// 2 byte for Amperaje, 2 bytes for Tª, 1 byte for level and alarms.
uint8_t payload[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

// SH + SL Address of receiving XBee
XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, 0x408C51AB); // Modify for the coordinator Address
ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload)); // ZBbee Tx frame handler
ZBTxStatusResponse txStatus = ZBTxStatusResponse();  // To manage the status response after transmision
XBeeResponse response = XBeeResponse();  
// create reusable response objects for responses we expect to handle 
ZBRxResponse rx = ZBRxResponse();
ModemStatusResponse msr = ModemStatusResponse(); // Manage the status API frames if neccesary

// ******** EEPROM PARAMETER DEFINITION ********
const byte EEPROM_ID = 0x50;      // I2C address for 24LC128 EEPROM
const int FRAME_LENGHT = 13;   // Frame write in FIFO 
const unsigned int MAX_LENGHT = 256; //EEPROM Max lenght in bytes
const unsigned int FIFO_BASE = 16; 

Fifo fifo(EEPROM_ID, FIFO_BASE, MAX_LENGHT, FRAME_LENGHT);


// ******** SENSORS PIN DEFINITION ********
const int vUpPin = 0;    // Voltaje behind + terminal and central terminal adapted to 3.3Vdc range
const int vLowPin = 1;   // Voltaje behind central terminal and - terminal adapted to 3.3Vdc range
const int ampPin = 0;    // Amperaje charging or drain the battery
const int tempPin = 1;   // External battery temperature 
const int levPin = 4;    // Digital signal representing the electrolyte level 0 = level fault
const int aliAlarmPin = 2;    // Digital signal repersenting the alimentation fault for the levels adaptation board 

const int fullLED = 11;    // FIFO state in debug mode
const int emptyLED = 12;

/* ===============================================================================
 *
 * Function Name:	Setup()
 * Description:    	Configuration function. Set the digital pin mode. Set the periodic function call.
  *                     Open the Xbee connection and the virtual Serial connection for debug 
 * Parameters:          None
 * Returns;  		None
 *
 * =============================================================================== */
void setup()
{
  if (debug) {
    Serial.begin(9600);      // TODO: Must convert to NewSoftSerial connection
  } else {
    xbee.begin(9600);
  }
  Wire.begin();           // Start the FIFO connection
  
  pinMode(fullLED, OUTPUT);
  pinMode(emptyLED, OUTPUT);
  
  pinMode(levPin, INPUT_PULLUP);
  pinMode(aliAlarmPin, INPUT_PULLUP);
  
  setTime(11,0,0,17,11,2012);
  Alarm.timerRepeat(2,captureData);  // Periodic function for reading sensors values
}


/* ===============================================================================
 *
 * Function Name:	serialEvent()
 * Description:    	Asincronous interrupt handler when data is present at incoming buffer in serial port.
 *                      Handler the command send from the PC application for reading the data in FIFO or for
 *                      set the configuration for the battery parameters
 * Parameters:          none
 * Returns;  		none
 *
 * =============================================================================== */
void serialEvent()
{
  byte data;
  
  if (debug) {
    while(Serial.available())
    {
      while (fifo.Busy()) // FIFO is not being accesed
        ;
      fifo.Block(true); //  
    
      char ch = Serial.read();
      if (ch == 'D') {
        if (fifo.Empty()){
          Serial.println("FIFO is empty");
          fifo.Block(false);
          return;
        }
        Serial.print("At ");
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        Serial.print("   sensor V+:");
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        Serial.print("   sensor V-:");
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        Serial.print("   sensor A:");
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        Serial.print("   sensor T:");
        data = fifo.Read();
        Serial.print(data);
        data = fifo.Read();
        Serial.print(data);
        Serial.print("   sensor T:");
        data = fifo.Read();
        Serial.println(data);
        //
      }
    fifo.Block(false);    
    }      // while(Serial.available())
  } else {        // if  not (debug)     *************************
    xbee.readPacket();              // Look for a packet sent by the PC app 
    
    if (xbee.getResponse().isAvailable()) {
      // got something
    
      if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {   // the PC APP send data to Arduino
        // got a zb rx packet
      
        // now fill our zb rx class
        xbee.getResponse().getZBRxResponse(rx);
          
        /* if (rx.getOption() == ZB_PACKET_ACKNOWLEDGED) {
            // the sender got an ACK
          
        } else {
            // we got it (obviously) but sender didn't get an ACK
        }
        */  //  This is not important now    
      
        while (fifo.Busy()) // FIFO is not being accesed
          ;
        fifo.Block(true); //
          // Fill the payload
        for (int k = 0; k < 13  ; k++) {
          payload[k] = fifo.Read();
        }
        fifo.Block(false); //
        
        xbee.send(zbTx);
              
      }
    } else if (xbee.getResponse().isError()) {
                  //nss.print("Error reading packet.  Error code: ");  
                //nss.println(xbee.getResponse().getErrorCode());
    }
  }  
}



/* ===============================================================================
 *
 * Function Name:	captureData()
 * Description:    	This function read the analog values of sensor and determines if is necessary to store
 *                      them in the FIFO, doin so if necessary.
 * Parameters:          none  
 * Returns;  		none
 *
 * =============================================================================== */
void captureData()
{
  time_t fecha;
  word sensorVh;
  word sensorVl;
  word sensorA;
  word sensorT;
  byte state;
  //boolean aliAlarm;
  
  sensorVh = analogRead(vUpPin);
  sensorVl = analogRead(vLowPin);
  sensorA = analogRead(ampPin);
  sensorT = analogRead(tempPin);
  state = 0;
  bitWrite(state,0,digitalRead(levPin));  
  fecha = now();  // get the current date
  
  while (fifo.Busy()) // FIFO is  being accesed
      ;
  fifo.Block(true); //  Block the FIFO access

  while (fecha != 0 ){         // and store it in the FIFO converting the date
    fifo.Write(fecha%255);     // in a byte data succesion
    fecha /= 255;
  }
  
  fifo.Write(highByte(sensorVh));
  fifo.Write(lowByte(sensorVh));
  fifo.Write(highByte(sensorVl));
  fifo.Write(lowByte(sensorVl));
  fifo.Write(highByte(sensorA));
  fifo.Write(lowByte(sensorA));
  fifo.Write(highByte(sensorT));
  fifo.Write(lowByte(sensorT));
  fifo.Write(state);
  
  fifo.Block(false); //  Releases the FIFO access 
}


/* ===============================================================================
 *
 * Function Name:	void()
 * Description:    	Main loop
 * Parameters:          none
 * Returns;  		none
 *
 * =============================================================================== */
void loop()
{
  digitalWrite(emptyLED, fifo.Empty());
  digitalWrite(fullLED, fifo.Full());
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
} 


