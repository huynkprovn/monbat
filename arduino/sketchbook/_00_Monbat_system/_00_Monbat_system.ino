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
 *              Version 0.0.0 Initial structure and include files
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

char VERSION[] = "MonBat system V0.0.0";
boolean debug = true;

// ******** XBEE PARAMETER DEFINITION ********
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



/* ===============================================================================
 *
 * Function Name:	Function name()
 * Description:    	_
 * Parameters:
 * Returns;  		Return
 *
 * =============================================================================== */
void setup()
{
  xbee.begin(9600);
  //Serial.begin(9600);
  
  setTime(11,0,0,17,11,2012);
  Alarm.timerRepeat(1,captureData);
}


/* ===============================================================================
 *
 * Function Name:	Function name()
 * Description:    	_
 * Parameters:
 * Returns;  		Return
 *
 * =============================================================================== */
void serialEvent()
{
  
}



/* ===============================================================================
 *
 * Function Name:	Function name()
 * Description:    	_
 * Parameters:
 * Returns;  		Return
 *
 * =============================================================================== */
void captureData()
{
  
}


/* ===============================================================================
 *
 * Function Name:	Function name()
 * Description:    	_
 * Parameters:
 * Returns;  		Return
 *
 * =============================================================================== */
void loop()
{
 
} 


