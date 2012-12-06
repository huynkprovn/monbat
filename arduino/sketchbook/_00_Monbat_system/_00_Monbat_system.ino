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
 *              Version 0.2.0    Add set time capability
 *              Version 0.1.4    Fix error in command received frame. Test with read FIFO, work ok.
 *              Version 0.1.3    Define id for PC application orders   
 *              Version 0.1.2    Define alarm criterion
 *              Version 0.1.1    Only store in FIFO the sensors values if a different with previous value exist
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
#include <Wire.h>      // For access to i2c externar EEPROM with fifo library
#include <EEPROM.h>    // Store the fifo tail/head, and battery identification
#include <Fifo.h>       // This is a personal library. 
                      // http://code.google.com/p/monbat/source/browse/#svn%2Farduino%2Fmy%20libs%2FFifo
#include <Streaming.h>
#include <NewSoftSerial.h>  // Used for a serial debug connection

char VERSION[] = "MonBat system V0.1.2";
boolean debug = false;

// Application orders_id definition
#define GET_ID 0x01
#define RESET_ALARMS 0x02
#define SET_TRUCK_MODEL 0x03
#define SET_TRUCK_SN 0x04
#define SET_BATT_MODEL 0x05
#define SET_BATT_SN 0x06
#define CALIBRATE 0x07
#define SET_TIME 0x08
#define READ_MEMORY 0x10
#define EXIT 0xFA
#define RESET_MEM 0x99

// ******** XBEE PARAMETER DEFINITION ********
boolean ConnToApp = false;     // Used to determinate when an Xbee connection with the 
                              // PC app is established  
XBee xbee = XBee();  // Xbee object to manage the xbee connection 
// state capturated by the arduino. 4 bytes for time, 2 bytes for V+, 2 bytes for V-
// 2 byte for Amperaje, 2 bytes for Tª, 1 byte for level and alarms.
uint8_t payload[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

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
const unsigned int MAX_LENGHT = 2056; //EEPROM Max lenght in bytes
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

// Others const
const int sample_time = 1; // period for sensor sampling (in seconds)
const int threshold = 2;   // threshold variation in analog signals (in %) to store them
const long up_thr = 1+(threshold/100);
const long low_thr = 1-(threshold/100);

const word charge_amp = 522; // Min sensor value for considering the battery is charging after draining
const word drain_amp = 502; // Min sensor value for considering the battery is draining after charging

//********* TODO: calculate this values with real battery voltage and equivalent arduino analog input voltage after 
//********* voltage levels conversion
const word full_volt = 1000 ; //Battery voltaje when fully charged
const word empty_volt = 100; //Battery voltaje when charge is at 20%

const word max_temp = 600; // maximum permissible temperature
const word min_temp = 100; // minimun permissible temperature


//********* INTERNAL EEPROM DATA DISTRIBUTION
/*
 *  [0..3]: tail fifo address
 *  [4..7]: heal fifo address
 *  [8..9]: reserved
 *  [10..24]: truck model (15 characters)
 *  [25..39]: truck serial number (15 characters)
 *  [40..54]: battery model (15 characters)
 *  [55..69]: battery serial number (15 characters)
 *  [70..]: reserved
 */
 
 
// *********** VAR FOR SW SENSOR CALIBRATION *******
// Calibrated data = SensorAnalogData * gain + off
// Adjusting gain increase/decrease 10% the AnalogData
// Adjunting off increase/decrease 10%FS the zero value of AnalogData.
char vh_gain, vh_off;  
char vl_gain, vl_off;
char a_gain, a_off;
char t_gain, t_off;

//Actual and Previous sensor values
word sensorVh; // Analog pin values
word sensorVl;
word sensorA;
word sensorT;
byte state; // [msb..lsb] [level_sensor_alarm,sensor_alarm,system_alarm,temp_alarm,charge_alarm,level,empty_alarm,charge/drain]

word vh_prev;
word vl_prev;
word a_prev;
word t_prev;
word l_prev;
word s_prev;

// Battery status
//byte st;  
//boolean drain; // true if battery is draining, false if charging 
boolean full; // battery if fully charged
boolean empty; // batrey charge below 20% 

// time at several events
time_t fecha;  //now
time_t charge_init;
time_t charge_end;
time_t drain_init;
time_t drain_end;


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
  state=0;
  vh_prev=0;
  vl_prev=0;
  a_prev=0;
  t_prev=0;
  l_prev=0;
  s_prev=0x00;
  charge_init = now();
  charge_end = now();
  drain_init = now();
  drain_end = now();
  if (debug) {
    Serial.begin(9600);      // TODO: Must convert to NewSoftSerial connection
  } else {
    xbee.begin(9600);
  }
  Wire.begin();           // Start the FIFO connection
  
  pinMode(fullLED, OUTPUT);  //only for testing
  pinMode(emptyLED, OUTPUT);
  
  pinMode(levPin, INPUT_PULLUP);
  pinMode(aliAlarmPin, INPUT_PULLUP);
  
  setTime(11,0,0,17,11,2012);
  Alarm.timerRepeat(sample_time,captureData);  // Periodic function for reading sensors values
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
  unsigned int data;
  time_t t;
  
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
        
        switch (rx.getData(0))
        {
          case GET_ID:
            break;
          
          case RESET_ALARMS:
            break;
          
          case SET_TRUCK_MODEL:
            for (int k=1; rx.getDataLength()-1; k++)
              EEPROM.write(10+k-1,rx.getData(k));              
            break;
          
          case SET_TRUCK_SN:
            for (int k=1; rx.getDataLength()-1; k++)
              EEPROM.write(25+k-1,rx.getData(k));
            break;
          
          case SET_BATT_MODEL:
            for (int k=1; rx.getDataLength()-1; k++)
              EEPROM.write(40+k-1,rx.getData(k));
            break;
          
          case SET_BATT_SN:
            for (int k=1; rx.getDataLength()-1; k++)
              EEPROM.write(55+k-1,rx.getData(k));
            break;
          
          case CALIBRATE:
            break;
          
          case SET_TIME:
            blink_led(3,200);
            
            t=0;
            for (int k = rx.getDataLength()-1; k>=1 ; k--) //read in reverse mode
              t = t*255+int(rx.getData(k));
            /* This work fine
            t=int(rx.getData(4));
            t=t*255+int(rx.getData(3));
            t=t*255+int(rx.getData(2));
            t=t*255+int(rx.getData(1));
            */  
            setTime(t);
            break;

          case READ_MEMORY:
            
            digitalWrite(13,HIGH);
            delay(200);
            digitalWrite(13,LOW);
            while (!fifo.Empty())
            {
              while (fifo.Busy()) // FIFO is not being accesed
                ;
              fifo.Block(true); //
              // Fill the payload
              //payload[0] = READ_MEMORY;
              for (int k = 0; k < 13  ; k++) {
                payload[k] = fifo.Read();
              }
              fifo.Block(false); //
        
              xbee.send(zbTx);
            }
            break;
          
          case EXIT:
            break;
          
          case RESET_MEM:
            fifo.Clear();
            break;
          
          default:
            break;
        
        }         
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

  //boolean aliAlarm;
  
  sensorVh = analogRead(vUpPin);
  sensorVl = analogRead(vLowPin);
  sensorA = analogRead(ampPin);
  sensorT = analogRead(tempPin);
  bitWrite(state,2,digitalRead(levPin));  
  fecha = now();  // get the current date
  
  //if (changed()) {
    while (fifo.Busy()) // FIFO is  being accesed. TODO: analice is Xbee conn is established
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
    
    vh_prev = sensorVh;
    vl_prev = sensorVl;
    a_prev = sensorA;
    t_prev = sensorT;
    s_prev = state;
  //}
}


/* ===============================================================================
 *
 * Function Name:	changed()
 * Description:    	analice the actual sensor values and compare them with previous values
 *                      determining if is neccesary store them
 * Parameters:          none
 * Returns;  		boolean: True if stored is neccesary. False if not
 *
 * =============================================================================== */
boolean changed()
{
  boolean res = false;
  if (((int(sensorVh))>int(up_thr*int(vh_prev))) || (int(sensorVh)<int(low_thr*int(vh_prev)))) {
    res = true;
  }
  if (((int(sensorVl))>int(up_thr*int(vl_prev))) || (int(sensorVl)<int(low_thr*int(vl_prev)))) {
    res = true;
  }
  if (((int(sensorA))>int(up_thr*int(a_prev))) || (int(sensorA)<int(low_thr*int(a_prev)))) {
    res = true;
  }
  if (((int(sensorT))>int(up_thr*int(t_prev))) || (int(sensorT)<int(low_thr*int(t_prev)))) {
    res = true;
  }
  if (state != s_prev) {
    res = true;
  } 
  
  return res;
}


/* ===============================================================================
 *
 * Function Name:	check_alarms()
 * Description:    	
 *                      
 * Parameters:          none
 * Returns;  		boolean: True if an alarm has produced. False if not
 *
 * =============================================================================== */
boolean check_alarms()
{
  boolean alarm = false;
  
  //  check temperature alarms
  if ((sensorT > max_temp) || (sensorT < min_temp))
  {
    bitSet(state,4);
    alarm = true;
  }
  
  // check level alarms. Wait for 15 times followed
  if (bitRead(state,2))
  {
    //if (times > 15) //check 
    bitSet(state,7);
    alarm = true;
  }
  
  if (!bitRead(s_prev,0))    // previous statate draining
  {
    if (sensorA > charge_amp)   //now is charging
    {
      bitSet(state,0);
      charge_init = now();
      drain_end = now();
      // check if battery charge is ok
    } 
    else // continues draining
    {
      if ((sensorVh < empty_volt) && (sensorVl < empty_volt))   //battery below 20% capacity
      {
        empty = true;
        bitSet(state,1);
        alarm = true;
      }
      else  // battery is not completely discharged
      {
       
      }
    }
  } 
  else             //previous state charging
  {
    if (sensorA < drain_amp)   //now is draining
    {
      bitClear(state,0);
      drain_init = now();
      charge_end = now();
      if (!full) 
      {
        bitSet(state,3);
        alarm = true;
      }
    }
    else // cotinues charging
    {
      if ((sensorVh > full_volt) && (sensorVl > full_volt))   // battery fully charged
      {
        full = true;
      }
    }
  }
  return alarm;
}


void blink_led(int times, int period)
{
  for (int x=0; x<=times; x++)
  {
    digitalWrite(12,HIGH);
    delay(period);
    digitalWrite(12,LOW);
    delay(period);
  }  
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


