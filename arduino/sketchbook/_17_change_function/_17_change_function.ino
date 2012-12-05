/*
 * Description: Periodicamente lee los valores de 2 entradas analogicas
 * si hay una diferencia > 2% envia el estado de los cuatro pines analogicos por 
 * XBee junto con la hora 
 */
 
#include <Time.h>
#include <TimeAlarms.h> // Require the TimeAlarms.ccp file modification
                        // to add the Arduino.h in the include files
#include <XBee.h>
#include <Wire.h>
#include <Streaming.h>
#include <NewSoftSerial.h>  // Used for a serial debug connection


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



// ******** SENSORS PIN DEFINITION ********
const int vUpPin = 0;    // Voltaje behind + terminal and central terminal adapted to 3.3Vdc range
const int vLowPin = 1;   // Voltaje behind central terminal and - terminal adapted to 3.3Vdc range
const int ampPin = 0;    // Amperaje charging or drain the battery
const int tempPin = 1;   // External battery temperature 
const int levPin = 4;    // Digital signal representing the electrolyte level 0 = level fault
const int aliAlarmPin = 2;    // Digital signal repersenting the alimentation fault for the levels adaptation board 

const int fullLED = 11;    // FIFO state in debug mode
const int emptyLED = 12;


// *********** VAR FOR SW SENSOR CALIBRATION *******
// Calibrated data = SensorAnalogData * gain + off
// Adjusting gain increase/decrease 10% the AnalogData
// Adjunting off increase/decrease 10%FS the zero value of AnalogData.
char vh_gain, vh_off;  
char vl_gain, vl_off;
char a_gain, a_off;
char t_gain, t_off;

//Actual and Previous sensor values
time_t fecha;
word sensorVh;
word sensorVl;
word sensorA;
word sensorT;
byte state;

word vh_prev;
word vl_prev;
word a_prev;
word t_prev;
byte s_prev;

// Battery status
byte st;  // [msb..lsb] [sensor_alarm,system_alarm,temp_alarm,charge_alarm,level,empty_alarm,charge/drain]


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
  state=0x00;
  xbee.begin(9600);

  pinMode(fullLED, OUTPUT);
  pinMode(emptyLED, OUTPUT);
  
  pinMode(levPin, INPUT_PULLUP);
  pinMode(aliAlarmPin, INPUT_PULLUP);
  
  setTime(11,0,0,17,11,2012);
  Alarm.timerRepeat(2,captureData);  // Periodic function for reading sensors values
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
  int k = 0;
  //boolean aliAlarm;
  
  sensorVh = analogRead(vUpPin);
  sensorVl = analogRead(vLowPin);
  sensorA = analogRead(ampPin);
  sensorT = analogRead(tempPin);
  //state = 0;
  bitWrite(state,0,digitalRead(levPin));  
  fecha = now();  // get the current date
  
  if (change()) {
    while (fecha != 0 ){         // and store it in the FIFO converting the date
      payload[k]=fecha%255;     // in a byte data succesion
      fecha /= 255;
      k++;
    }
    payload[k]=highByte(sensorVh);
    k++;
    payload[k]=lowByte(sensorVh);
    k++;
    payload[k]=highByte(sensorVl);
    k++;
    payload[k]=lowByte(sensorVl);
    k++;
    payload[k]=highByte(sensorA);
    k++;
    payload[k]=lowByte(sensorA);
    k++;
    payload[k]=highByte(sensorT);
    k++;
    payload[k]=lowByte(sensorT);
    k++;
    payload[k]=state;
   
    xbee.send(zbTx);
  }
  
  vh_prev = sensorVh;
  vl_prev = sensorVl;
  a_prev = sensorA;
  t_prev = sensorT;
  s_prev = state;
  
}


/* ===============================================================================
 *
 * Function Name:	change()
 * Description:    	analice the actual sensor values and compare them with previous values
 *                      determining if is neccesary store them
 * Parameters:          none
 * Returns;  		boolean: True if stored is neccesary. False if not
 *
 * =============================================================================== */
boolean change()
{
  boolean res = false;
  if (((int(sensorVh))>int(1.03*int(vh_prev))) || (int(sensorVh)<int(0.97*int(vh_prev)))) {
    res = true;
  }
  if (((int(sensorVl))>int(1.03*int(vl_prev))) || (int(sensorVl)<int(0.97*int(vl_prev)))) {
    res = true;
  }
  if (((int(sensorA))>int(1.03*int(a_prev))) || (int(sensorA)<int(0.97*int(a_prev)))) {
    res = true;
  }
  if (((int(sensorT))>int(1.03*int(t_prev))) || (int(sensorT)<int(0.97*int(t_prev)))) {
    res = true;
  }
  if (state != s_prev) {
    res = true;
  } 
  
  return res;
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
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
} 


