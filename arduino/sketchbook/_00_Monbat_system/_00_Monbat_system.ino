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
 *              Version 0.10.3   Some debug lines
 *              Version 0.10.2   Add received calibration parameter storage in EEPROM
 *              Version 0.10.1   Difference calibration from normal state in periodic sample capture
 *              Version 0.10.0   Add remote calibration functionality.
 *              Version 0.9.0    Add Status pannel controler functions.
 *              Version 0.8.0    Add frames sent to PC app to confirm the receipt of data
 *              Version 0.7.6    Modify the fifo read when transmiting data. Prevent infinite loop when reading memory
 *              Version 0.7.5    Add some debug lines in rx frame. Detected UNEXPECTED_START_BYTE and CHECKSUM_FAILURE error in rx's frames
 *              Version 0.7.4    Remove duplicated sentence. Now not duplicate periodic function when time is changed
 *              Version 0.7.3    Add some debug lines in tx data and store data procedures
 *              Version 0.7.2    Data calculation like in Set time function. Don´t use pow() funct.
 *              Version 0.7.1    error in data calculation. Probably for type in pow() funct. TODO
 *              Version 0.7.0    restore fifo pointers when restart. Adjust system time at inic with the last stored
 *                               sample time. Don´t work
 *              Version 0.6.1    Allow reading sensors states memory without erasing it
 *              Version 0.6.0    Only store sensors values if are changed
 *              Version 0.5.1    Add autostore fifo pointers periodicaly. NEED TO RESET FIFO ONCE AFTER FIRST RUN
 *              Version 0.5.0    restore fifo status and pointers when restart
 *              Version 0.4.1    Deleted superfluous codigo.
 *              Version 0.4.0    Add a software serial port for debugging. Complete functions for voltaje, current
 *                               and temperature conversion.
 *              Version 0.3.0    Add functions for battery charge calculation
 *              Version 0.2.3    Define sensors values for alarm criterion
 *              Version 0.2.2    Add model and serial data receiving and store
 *              Version 0.2.1    Add byte id for data transmission equal to id byte in rx commands.
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
                        // to add the Arduino.h in the include files. TODO: change for MsTimer2 library
//#include <MsTimer2.h>
#include <XBee.h>
#include <Wire.h>      // For access to i2c externar EEPROM with fifo library
#include <EEPROM.h>    // Store the fifo tail/head, and battery identification
#include <Fifo.h>       // This is a personal library. 
                      // http://code.google.com/p/monbat/source/browse/#svn%2Farduino%2Fmy%20libs%2FFifo
#include <Streaming.h>
#include <SoftwareSerial.h>  // Used for a serial debug connection (this library is only for Arduino 1.0 or later
#include <sLed.h>  // Define the serial interface for multiple digital output control

sLed led(7,5,4,6,900);    // Create a sLed objet and asociate to the arduino pins;
//sLed(unsigned int DataPin, unsigned int shiftCkPin, unsigned int latchCkPin, unsigned int rstPin, unsigned int BaudRate);

char VERSION[] = "MonBat system V0.8.0";
boolean debug = true;
SoftwareSerial debugCon(9,10); //Rx, Tx arduino digital port for debug serial connection

// Application orders_id definition
#define GET_ID 0x01
#define RESET_ALARMS 0x02
#define SET_TRUCK_MODEL 0x03
#define SET_TRUCK_SN 0x04
#define SET_BATT_MODEL 0x05
#define SET_BATT_SN 0x06
#define SET_BATT_CAPACITY 0x61
#define CALIBRATE 0x07
#define SET_TIME 0x08
#define READ_MEMORY 0x10
#define EXIT 0xFA
#define RESET_MEM 0x99

// ******** XBEE PARAMETER DEFINITION ********
boolean ConnToApp = false;     // Used to determinate when an Xbee connection with the 
boolean Calibrar = false;    // Used to determinate when the monitor is in software calibration process
                              // PC app is established 
byte sensorCalibrate = 0;    // Which sensor is been calibreted (00=none, 01 = Vh, 02 = Vl, 03 = A, 04 = T) 

XBee xbee = XBee();  // Xbee object to manage the xbee connection 
// state capturated by the arduino. 4 bytes for time, 2 bytes for V+, 2 bytes for V-
// 2 byte for Amperaje, 2 bytes for Tª, 1 byte for level and alarms.
uint8_t payload[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

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
const unsigned int MAX_LENGHT = 131071; //EEPROM Max lenght in bytes
const unsigned int FIFO_BASE = 0; 
unsigned int fifo_tail = word(EEPROM.read(0),EEPROM.read(1));
unsigned int fifo_head =  word(EEPROM.read(2),EEPROM.read(3));

//Fifo fifo(EEPROM_ID, FIFO_BASE, MAX_LENGHT, FRAME_LENGHT);
//fifo_tail = word(EEPROM.read(0),EEPROM.read(1));
//fifo_head =  word(EEPROM.read(2),EEPROM.read(3));
Fifo fifo(EEPROM_ID, FIFO_BASE, fifo_tail, fifo_head, MAX_LENGHT, FRAME_LENGHT);

// ******** SENSORS PIN DEFINITION ********
const int vUpPin = 1;    // Voltaje behind + terminal and central terminal adapted to 3.3Vdc range
const int vLowPin = 2;   // Voltaje behind central terminal and - terminal adapted to 3.3Vdc range
const int ampPin = 6;    // Amperaje charging or drain the battery
const int tempPin = 3;   // External battery temperature 
const int levPin = 3;    // Digital signal representing the electrolyte level 0 = level fault
const int aliAlarmPin = 2;    // Digital signal repersenting the alimentation fault for the levels adaptation board 

//const int fullLED = 11;    // FIFO state in debug mode
//const int emptyLED = 12;

// Others const
const int sample_period = 2; // period for sensor sampling (in seconds)
const float threshold = 3.00;   // threshold variation in analog signals (in %) to store them
const float up_thr = 1.00 +(float(threshold/100));
const float low_thr = 1.00 -(float(threshold/100));

const word charge_amp = 522; //0x020A Min sensor value for considering the battery is charging after draining
const word drain_amp = 505; //0x01F9 Min sensor value for considering the battery is draining after charging

//********* TODO: calculate this values with real battery voltage and equivalent arduino analog input voltage after 
//********* voltage levels conversion
const word full_volt = 913;//0x0391 //Battery voltaje when fully charged.2,65V per element = 15,9V in half batt 
const word empty_volt = 104;//0x0068 //Battery voltaje when charge is at 20%. 1,7V per element = 10,2V in half Batt

const word max_temp = 553;//0x0229 //30ºC Battery life reduced in 30%
const word min_temp = 323;//0x0143 //15ºC (70% batt capacity) minimun permissible temperature


//********* INTERNAL EEPROM DATA DISTRIBUTION
/*
 *  [0..1]: tail fifo address
 *  [2..3]: heal fifo address
 *
 *  [10..24]: truck model (15 characters)
 *  [25..39]: truck serial number (15 characters)
 *  [40..54]: battery model (15 characters)
 *  [55..69]: battery serial number (15 characters)  
 *  [70..71]: battery capacity in Ah
 *  [71..72]: reserved
 *  [80]: vh_gain
 *  [81]: vh_off
 *  [82]: vl_gain
 *  [83]: vl_off
 *  [84]: a_gain
 *  [85]: a_off
 *  [86]: t_gain
 *  [87]: t_off 
 */
 
 
// *********** VAR FOR SW SENSOR CALIBRATION *******
// Calibrated data = SensorAnalogData * gain + off
// Adjusting gain increase/decrease 10% the AnalogData
// Adjunting off increase/decrease 10%FS the zero value of AnalogData.
byte vh_gain = EEPROM.read(80);
byte vh_off = EEPROM.read(81);  
byte vl_gain = EEPROM.read(82);
byte vl_off = EEPROM.read(83);
byte a_gain = EEPROM.read(84);
byte a_off = EEPROM.read(85);
byte t_gain = EEPROM.read(86);
byte t_off = EEPROM.read(87);

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
word capacity; // battry cappacity in Ah
byte soc; // state of charge in % respect battery capacity

// time at several events
time_t fecha;  //now
time_t charge_init;    // time when current charge begin
time_t charge_end;      // time when last charge end
time_t drain_init;      // time when current discharge begin
time_t drain_end;      // time when last discharge end


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
  led.Clear();  //Reset leds status representation
  time_t last_time = 0;
  
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

  capacity=word(EEPROM.read(70),EEPROM.read(71));
  if (capacity == 0){
    bitSet(state,5); //Sys alamr. capacity not fixed and no calculations possibility
  }
  
  if (debug) {
    debugCon.begin(9600);      // DONE: Must convert to NewSoftSerial connection
    debugCon.print("Battery capacity: ");
    debugCon.print(capacity);
    debugCon.println(" Ah.");
  }
  if (debug){
    debugCon << "threshold margins= [" << up_thr << "," << low_thr << "]";  
    debugCon.println();
  }
  
  xbee.begin(9600);
  Wire.begin();           // Start the FIFO connection
  if (debug) {
    debugCon.print("FIFO started with tail pointer= ");
    debugCon.print(fifo_tail);
    debugCon.print(", and head pointer= ");
    debugCon.println(fifo_head);
  }  
  
  pinMode(levPin, INPUT_PULLUP);
  pinMode(aliAlarmPin, INPUT_PULLUP);
  
  for (int x=3; x>=0; x--) // 
            last_time = last_time*255 + fifo.Read(fifo.Get_head() - FRAME_LENGHT + x);
  if (debug) {
    debugCon << "last sample time = " << last_time;
    debugCon.println("");
  }
  
  
  /*if (debug) {
    debugCon.println("|                      SENSORS SOFTWARE CALIBRATION DATA                        |");
    debugCon.println("|-------------------------------------------------------------------------------|");
    debugCon.println("| vh_gain |  vh_off | vl_gain |  vl_off |  a_gain |  a_off  |  t_gain |  t_off  |");
    debugCon.println("|         |         |         |         |         |         |         |         |");
    debugCon << "|   " << vh_gain << "   |   " << vh_off << "   |   " << vl_gain << "   |   " << vl_off << "   |   " << a_gain << "   |   " << a_off << "   |   " << t_gain << "   |   " << t_off << "   |";   
    debugCon.println("");
    debugCon.println("|         |         |         |         |         |         |         |         |");
    debugCon.println("|-------------------------------------------------------------------------------|");
  }*/   // this code causes the arduino reset!!! why??  Only God knows
  
  if (debug) {
    debugCon.println("SENSORS SOFTWARE CALIBRATION DATA");
    debugCon.print("vh_gain = ");
    debugCon.print(vh_gain);
    debugCon.print("      vh_off = ");
    debugCon.println(vh_off);
    debugCon.print("vl_gain = ");
    debugCon.print(vl_gain);
    debugCon.print("      vl_off = ");
    debugCon.println(vl_off);
    debugCon.print("a_gain = ");
    debugCon.print(a_gain);
    debugCon.print("      a_off = ");
    debugCon.println(a_off);
    debugCon.print("t_gain = ");
    debugCon.print(t_gain);
    debugCon.print("      t_off = ");
    debugCon.println(t_off);
    if (Calibrar){
      debugCon.println("In calibration process");
    } else {
      debugCon.println("Not in calibretion process");
    } 
  }
  
  delay(3000);
    
  setTime(last_time);
  //setTime(11,0,0,17,11,2012);
  Alarm.timerRepeat(sample_period,captureData);  // Periodic function for reading sensors values
  //MsTimer2::set(500, captureData); // 500ms period
  //MsTimer2::start();
  
/*  digitalWrite(aliAlarmPin, HIGH);
  attachInterrupt(0, supplyFault, LOW);
  if (debug) {
    debugCon.println("Interrupts configurated");
  }
*/  
  if (debug) {
    debugCon.println("Started...");
  }
  
}



/* ===============================================================================
 *
 * Function Name:	supplyFault()
 * Description:    	Interrupt 0 handler (digital pin 0) used for detect the ausence of
 *                      main supply in the system. 
 *                      Sleep XBee Modem, Arduino subsystems, store current date and deactivate 
 *                      the capture data function.
 * Parameters:          none
 * Returns;  		none
 *
 * =============================================================================== */
void supplyFault()
{

  
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
  unsigned int temp_dir;
  time_t t;
  byte byteR;
  boolean fin, vuelta;
  
  xbee.readPacket();              // Look for a packet sent by the PC app 
  if (debug){
    debugCon.println("Serial event");
  }
    
  if (xbee.getResponse().isAvailable()) {
    // got something
    if (debug){
      debugCon.print("Xbee packet received: ");
      debugCon.print(byte(xbee.getResponse().getApiId()));
      debugCon.println(" packet.");
      debugCon.print("Frame data received: ");
      for(int x=0; x< xbee.getResponse().getFrameDataLength(); x++){
        debugCon.print(byte(xbee.getResponse().getFrameData()[x]));
      }
      debugCon.println();
    }
    
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
          payload[0]=GET_ID;
          payload[1]=0x01;
          /*fin = false;
          for (int k=1; fin; k++)
          {
            byteR=EEPROM.read(10+k-1);
            if (byteR = 0xFF){
              fin = true;
            } else {
              payload[1+k]=byteR;
            }
          }*/
          for (int k=1; k<15; k++)
            payload[1+k]=EEPROM.read(10+k-1);
          xbee.send(zbTx);  // send truck model
          delay(10);
          
          payload[1]=0x02;
          /*fin = false;
          for (int k=1; fin; k++)
          {
            byteR=EEPROM.read(25+k-1);
            if (byteR = 0xFF){
              fin = true;
            } else {
              payload[1+k]=byteR;
            }
          }*/
          for (int k=1; k<15; k++)
            payload[1+k]=EEPROM.read(25+k-1);
          xbee.send(zbTx);  // send truck serial
          delay(10);
          
          payload[1]=0x03;
          /*fin = false;
          for (int k=1; fin; k++)
          {
            byteR=EEPROM.read(40+k-1);
            if (byteR = 0xFF){
              fin = true;
            } else {
              payload[1+k]=byteR;
            }
          }*/
          for (int k=1; k<15; k++)
            payload[1+k]=EEPROM.read(40+k-1);
          xbee.send(zbTx);  // send battery model
          delay(10);
          
          payload[1]=0x04;
          /*fin = false;
          for (int k=1; fin; k++)
          {
            byteR=EEPROM.read(55+k-1);
            if (byteR = 0xFF){
              fin = true;
            } else {
              payload[1+k]=byteR;
            }
          }*/
          for (int k=1; k<15; k++)
            payload[1+k]=EEPROM.read(55+k-1);
          xbee.send(zbTx);  // send battery model
          
          break;
        
        case RESET_ALARMS:
          break;
        
        case SET_TRUCK_MODEL:
          //blink_led(2,200);
          payload[0]=SET_TRUCK_MODEL;
          xbee.send(zbTx);      // PC App wait for this response or resend
          if (debug){
            debugCon.print("Truck Model received : ");
          }
          for (int k=1; k < rx.getDataLength(); k++)
          {
            EEPROM.write(10+k-1,rx.getData(k));              
            delay(5);          // An EEPROM write takes 3.3 ms to complete
            if (debug){
              debugCon.print(rx.getData(k));
            }
          }
          EEPROM.write(int(rx.getDataLength()),0xFF);
          if (debug){
            debugCon.println();
          }
          break;
        
        case SET_TRUCK_SN:
          payload[0]=SET_TRUCK_SN;
          xbee.send(zbTx);      // PC App wait for this response or resend
          //blink_led(2,200);
          if (debug){
            debugCon.print("Truck SN received : ");
          }
          for (int k=1; k < rx.getDataLength(); k++)
          {
            EEPROM.write(25+k-1,rx.getData(k));
            delay(5);
            if (debug){
              debugCon.print(rx.getData(k));
            }
          }
          EEPROM.write(int(rx.getDataLength()),0xFF);
          if (debug){
            debugCon.println();
          }
          break;
        
        case SET_BATT_MODEL:
          payload[0]=SET_BATT_MODEL;
          xbee.send(zbTx);      // PC App wait for this response or resend
          //blink_led(2,200);
          if (debug){
            debugCon.print("Battery Model received : ");
          }
          for (int k=1; k < rx.getDataLength(); k++)
          {
            EEPROM.write(40+k-1,rx.getData(k));
            delay(5);
            if (debug){
              debugCon.print(rx.getData(k));
            }
          }
          EEPROM.write(int(rx.getDataLength()),0xFF);
          if (debug){
            debugCon.println();
          }
          break;
        
        case SET_BATT_SN:
          payload[0]=SET_BATT_SN;
          xbee.send(zbTx);      // PC App wait for this response or resend
          //blink_led(2,200);
          if (debug){
            debugCon.print("Battery SN received : ");
          }
          for (int k=1; k < rx.getDataLength(); k++)
          {
            EEPROM.write(55+k-1,rx.getData(k));
            delay(10);
            if (debug){
              debugCon.print(rx.getData(k));
            }
          }
          EEPROM.write(int(rx.getDataLength()),0xFF);
          if (debug){
            debugCon.println();
          }
          break;
        
        case SET_BATT_CAPACITY:
          payload[0]=SET_BATT_CAPACITY;
          xbee.send(zbTx);      // PC App wait for this response o resend
          //blink_led(2,200);
          if (debug){
            debugCon.print("Battery capacity received : ");
          }
          EEPROM.write(70,rx.getData(1));
          EEPROM.write(71,rx.getData(2));
          capacity = word(rx.getData(1),rx.getData(2));
          if (debug){
            debugCon.println(capacity);
          }
          break;
        
        case CALIBRATE:
          payload[0]=CALIBRATE;
          xbee.send(zbTx);      // PC App wait for this response o resend
          if (debug){
            debugCon.print("Calibration in procces in sensor : ");
            debugCon.println(rx.getData(1));
          }
          Calibrar = true;
          sensorCalibrate=rx.getData(1);
          if (rx.getDataLength()>2){
          
            switch (rx.getData(1))   // Modify sensor gain and offset 
            {         
              case 0x01:      // vh 
                vh_gain=rx.getData(2);   
                vh_off=rx.getData(3);
                EEPROM.write(80, rx.getData(2));
                EEPROM.write(81, rx.getData(3));
                Calibrar = false;
                break;
              
              case 0x02:
                vl_gain=rx.getData(2);
                vl_off=rx.getData(3);
                EEPROM.write(82, rx.getData(2));
                EEPROM.write(83, rx.getData(3));
                Calibrar = false;
                break;
    
              case 0x03:
                a_gain=rx.getData(2);
                a_off=rx.getData(3);
                EEPROM.write(84, rx.getData(2));
                EEPROM.write(85, rx.getData(3));
                Calibrar = false;
                break;
              
              case 0x04:
                t_gain=rx.getData(2);
                t_off=rx.getData(3);
                EEPROM.write(86, rx.getData(2));
                EEPROM.write(87, rx.getData(3));
                Calibrar = false;
                break;
  
              default:
                Calibrar = false;
                break;
            }
          }  
        
          break;
                
        case SET_TIME:
          payload[0]=SET_TIME;
          xbee.send(zbTx);      // PC App wait for this response o resend
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
          //Alarm.timerRepeat(sample_period,captureData);  // TODO: Check other way to activate alarms
                                    // this instruction generate other call to the "captureData" function
          break;

        case READ_MEMORY:
          
          if (fifo.Empty()){  // Prevent read empty fifo
            fin = true;
          }else{
            fin = false;
          }
          
          if (fifo.Get_tail() > fifo.Get_head()){       // Check if fifo pointer has been overflowed
            vuelta = false;                            // Has read vaules under head pointer?? 
          }else{                                        // normally be true after several hours of operation
            vuelta = true;
          }
          
          temp_dir = fifo.Get_tail();
          if (debug) {
            debugCon << "Tx samples in memory. Start at:" << temp_dir << "   End at:" << fifo.Get_head();
            debugCon.println();
          }
          
          while (!(fin&&vuelta))    // stop condition = (fifo=true and vuelta=true)
          {
            while (fifo.Busy()) // FIFO is not being accesed
              ;
            fifo.Block(true); //
            // Fill the payload
            payload[0] = READ_MEMORY;
            for (int k = 1; k < 14  ; k++) {
              payload[k] = fifo.Read(temp_dir);
              if (temp_dir > MAX_LENGHT) {  //have reach the highest mem address
                temp_dir = FIFO_BASE;
                vuelta = true;
              }
              else {
                temp_dir++;
              }
            }
            fifo.Block(false); //
            if (debug) {
              debugCon << "Tx data at:" << temp_dir;
              debugCon.println();
            }
            xbee.send(zbTx);
            if (temp_dir >= fifo.Get_head()){
              fin=true;
            }
          }
          
          /*
          while (!fifo.Empty())
          {
            while (fifo.Busy()) // FIFO is not being accesed
              ;
            fifo.Block(true); //
            // Fill the payload
            payload[0] = READ_MEMORY;
            for (int k = 1; k < 14  ; k++) {
              payload[k] = fifo.Extract();
            }
            fifo.Block(false); //
      
            xbee.send(zbTx);
          }
          
          //catch fifo pointers and store in arduino eeprom
          fifo_tail = fifo.Get_tail();
          fifo_head =  fifo.Get_head();
          EEPROM.write(0,highByte(fifo_tail));
          EEPROM.write(1,lowByte(fifo_tail));
          EEPROM.write(2,highByte(fifo_head));
          EEPROM.write(3,lowByte(fifo_head));
          if (debug){
            debugCon.print("fifo tail = ");
            debugCon.println(fifo_tail);
            debugCon.print("fifo head = ");
            debugCon.println(fifo_head);            
          }*/
          break;
        
        case EXIT:
          break;
        
        case RESET_MEM:
          payload[0]=RESET_MEM;
          xbee.send(zbTx);      // PC App wait for this response o resend
          fifo.Clear();
          fifo_tail = fifo.Get_tail();
          fifo_head =  fifo.Get_head();
          EEPROM.write(0,highByte(fifo_tail));
          EEPROM.write(1,lowByte(fifo_tail));
          EEPROM.write(2,highByte(fifo_head));
          EEPROM.write(3,lowByte(fifo_head));
          if (debug){
            debugCon.print("fifo tail = ");
            debugCon.println(fifo_tail);
            debugCon.print("fifo head = ");
            debugCon.println(fifo_head);            
          }
          break;
          
        
        default:
          break;
      
      }         
    }else if (xbee.getResponse().getApiId() == MODEM_STATUS_RESPONSE) {      
      xbee.getResponse().getModemStatusResponse(msr);
      // the local XBee sends this response on certain events, like association/dissociation
        
      if (msr.getStatus() == ASSOCIATED) {
        ConnToApp = true;  
      } else if (msr.getStatus() == DISASSOCIATED) {
        ConnToApp = false;
      }
    } else {      //************ OTHER ZB PACKET
    
    } 
  } else if (xbee.getResponse().isError()) {
    if (debug){
      debugCon.print("Error in Rx Packet receiving.  Eror code: ");
      debugCon.println(xbee.getResponse().getErrorCode());
    }
                  //nss.print("Error reading packet.  Error code: ");  
                //nss.println(xbee.getResponse().getErrorCode());
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
  
  static int times = 0;
  
  float vh=voltaje(sensorVh);
  float vl=voltaje(sensorVl);
  float i=current(sensorA);
  float t=temperature(sensorT);
  static float i_p= 0.0000;
  float iprev=current(a_prev);
  static float charge;
  charge=calc_ah_drained(i_p,i,charge,sample_period);
  i_p=i;   // this is a local var used only for charge load/drained calculation
  
  if (!Calibrar) {    // STORE DATA PROCESS
  
    if (debug){
      debugCon.print(now());
      debugCon.print(" :  Voltaje+ : ");  
      debugCon.print(vh);
      debugCon.print("Vdc,  Voltaje- : ");  
      debugCon.print(vl);
      debugCon.print("Vdc,  Corriente : ");
      debugCon.print(i);
      debugCon.print("A, Temperatura : ");
      debugCon.print(t);
       debugCon.println("ºC");
      /*debugCon.print("A,  Carga : ");
      debugCon.print(charge);
      debugCon.print("Ah,    ");
      debugCon.println(charge*100/capacity);*/
    }
    if (changed()) {
    
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
    
      if (debug) {
        debugCon << "Stored. Head pointer= " << fifo.Get_head();
        debugCon.println("");
      }
    
      //these are global vars
      vh_prev = sensorVh;
      vl_prev = sensorVl;
      a_prev = sensorA;
      t_prev = sensorT;
      s_prev = state;
    } else {
      if (debug) {
        debugCon.println("Not Stored"); 
      }
    }
  
    /*if (debug){
      debugCon.print(times);
      debugCon.println(" times in capture data");
    }*/
  } else {          // CALIBRATION PROCESS
    if (debug){
      debugCon.print("Sending value for calibration. Sensor ");
      debugCon.println(sensorCalibrate);
    }
    payload[0] = CALIBRATE;
    payload[1] = sensorCalibrate;
    switch (sensorCalibrate) {
      case 1:
        payload[2]=highByte(sensorVh);
        payload[3]=lowByte(sensorVh);
        break;
      case 2:
        payload[2]=highByte(sensorVl);
        payload[3]=lowByte(sensorVl);      
        break;
      case 3:
        payload[2]=highByte(sensorA);
        payload[3]=lowByte(sensorA);
        break;
      case 4:
        payload[2]=highByte(sensorT);
        payload[3]=lowByte(sensorT);
        break;
      default:
        break;
    }
    for (int k = 4; k <= 14  ; k++) {
      payload[k] = 0x00;
    }
    xbee.send(zbTx); // Send the sensor value to the PC application
  }
  
  if (times == 60){
    fifo_tail = fifo.Get_tail();
    fifo_head =  fifo.Get_head();
    EEPROM.write(0,highByte(fifo_tail));
    EEPROM.write(1,lowByte(fifo_tail));
    EEPROM.write(2,highByte(fifo_head));
    EEPROM.write(3,lowByte(fifo_head));
    times = 0;
    if (debug){
      debugCon.println("fifo pointers capture...");
      debugCon.print("fifo tail = ");
      debugCon.println(fifo_tail);
      debugCon.print("fifo head = ");
      debugCon.println(fifo_head);            
    }
  }  
  times++;
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
  if (((float(sensorVh))>float(up_thr*float(vh_prev))) || (float(sensorVh)<float(low_thr*float(vh_prev)))) {
    if (debug){
      debugCon << "Vh Changed. Actual: " << float(sensorVh) << ", last: " << float(vh_prev) << ", margins = [" << float(low_thr*float(vh_prev)) << "," << float(up_thr*float(vh_prev)) << "]";
      debugCon.println();  
    }
    res = true;
  }
  if (((float(sensorVl))>float(up_thr*float(vl_prev))) || (float(sensorVl)<float(low_thr*float(vl_prev)))) {
    if (debug){
      debugCon << "Vl Changed. Actual: " << float(sensorVl) << ", last: " << float(vl_prev) << ", margins = [" << float(low_thr*float(vl_prev)) << "," << float(up_thr*float(vl_prev)) << "]";
      debugCon.println();  
    }
    res = true;
  }
  if (((float(sensorA))>float(up_thr*float(a_prev))) || (float(sensorA)<float(low_thr*float(a_prev)))) {
    if (debug){
      debugCon << "A Changed. Actual: " << float(sensorA) << ", last: " << float(a_prev) << ", margins = [" << float(low_thr*float(a_prev)) << "," << float(up_thr*float(a_prev)) << "]";
      debugCon.println();  
    }
    res = true;
  }
  if (((float(sensorT))>float(up_thr*float(t_prev))) || (float(sensorT)<float(low_thr*float(t_prev)))) {
    if (debug){
      debugCon << "T Changed. Actual: " << float(sensorT) << ", last: " << float(t_prev) << ", margins = [" << float(low_thr*float(t_prev)) << "," << float(up_thr*float(t_prev)) << "]";
      debugCon.println();  
    }
    res = true;
  }
  if (state != s_prev) {
    if (debug){
      debugCon << "State Changed";
      debugCon.println();  
    }
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
  if ((sensorT > max_temp) || (sensorT < min_temp) && bitRead(state,0)) // Temp over safety margins and battery charging
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


/* ===============================================================================
 *
 * Function Name:	voltaje(word sensorvalue)
 * Description:    	Calculate the equivalent battery voltage to the mv signal at
 *                      Arduino analog pin 
 *
 *                      analogPin = Gain*BatteryVoltaje + offset
 *
 *                      Gain and offset are imposed by levels adaption stage
 *
 *                                  analogPin*Arduinoresolution(V) - offset
 *                      voltage = ------------------------------------------------
 *                                                Gain
 *
 *                      
 * Parameters:          sensorvalue  : word. Value at Arduino analog pin (10 bits)
 *                      
 * Returns;  		float: the battery voltaje expresed in Volts
 *
 * =============================================================================== */
float voltaje(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)+4.1030)/0.4431);
}


/* ===============================================================================
 *
 * Function Name:	current(word sensorvalue)
 * Description:    	Calculate the equivalent battery instant curren to the mv signal at
 *                      Arduino analog pin 
 *
 *                      analogPin = Gain*BatteryAmperaje + offset
 *
 *                      Gain and offset are imposed by levels adaption stage
 *
 *                                    analogPin*Arduinoresolution(V) - offset
 *                      current = ------------------------------------------------
 *                                                Gain
 *
 *                      
 * Parameters:          sensorvalue  : word. Value at Arduino analog pin (10 bits)
 *                      
 * Returns;  		float: the battery current expresed in Amperes
 *                      Current > 0 considering for battery discharging
 *                      Current < 0 considering for battery charging
 *
 * =============================================================================== */
float current(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)-1.6471)/0.0063);
}


/* ===============================================================================
 *
 * Function Name:	temperature(word sensorvalue)
 * Description:    	Calculate the equivalent battery temperature to the mv signal at
 *                      Arduino analog pin 
 *
 *                      analogPin = Gain*BatteryTemperature + offset
 *
 *                      Gain and offset are imposed by levels adaption stage
 *
 *                                    analogPin*Arduinoresolution(V) - offset
 *                      current = ------------------------------------------------
 *                                                Gain
 *
 *                      
 * Parameters:          sensorvalue  : word. Value at Arduino analog pin (10 bits)
 *                      
 * Returns;  		float: the battery temperature expresed celsius degres
 *
 * =============================================================================== */
float temperature(word sensorvalue)
{
  return float(((sensorvalue*3.2226/1000)-0.5965)/0.0296);
}

/* ===============================================================================
 *
 * Function Name:	calc_ah_drained(word sa0, word sa1, float ah0)
 * Description:    	Calculate the Ah drained by the battery until is draining
 *                      
 * Parameters:          sa0  : float. Last value of amperaje sensor sample in Amperes
 *                      sa1  : float. Actual value of amperaje sensor sample in Amperes
 *                      ah0  : float. Last value returned by this function (in Ah)
 *                      fs   : int. Sample frecuency in seconds
 * Returns;  		float: Total Ah drained by the battery.
 *
 * =============================================================================== */
float calc_ah_drained(float sa0, float sa1, float ah0, int fs)
{
  return (float(fs)/3600)*((sa0+sa1)/2)+ah0;
}


/* ===============================================================================
 *
 * Function Name:	curr_average(float ah, time_t inic)
 * Description:    	Calculate the drain/charge current average dividing the total
 *                      charge loaded/drained in/by battery by the time elapsed in the period 
 *                      
 * Parameters:          ah0  : float. Charge in Ah
 *                      inic : time_t. Time at period inic
 * Returns;  		float: Current average in Amperes
 *
 * =============================================================================== */
float curr_average(float ah, time_t inic)
{
  return (ah*3600/(now()-inic));  //  ah/time(h)
}


/* ===============================================================================
 *
 * Function Name:	calc_charge_level()
 * Description:    	Calculate the % battery charge depending of actual voltaje and
 *                      temperature and in middel amp during draining
 *                      
 * Parameters:          none?¿
 * Returns;  		byte: battery actual capacity expresed in % over battery total capacity
 *
 * =============================================================================== */
byte calc_charge_level(int a0, int a1)
{  
  byte level;
  if (!bitRead(state,0)){  // Battery is draining
    level=map(min(sensorVl,sensorVh),empty_volt,459,0,100);
    
  }
  
}


/* ===============================================================================
 *
 * Function Name:	calc_ah_drained(word sa0, word sa1, float ah0)
 * Description:    	Calculate the Ah drained by the battery until is draining
 *                      
 * Parameters:          sa0  : word. Last analog value of amperaje sensor sample
 *                      sa1  : word. Actual analog value of amperaje sensor sample
 *                      ah0  : float. Last value returned by this function
 *                      fs   : int. Sample frecuency in seconds
 * Returns;  		float: Total Ah drained by the battery.
 *
 * =============================================================================== */
/*float calc_ah_drained(word sa0, word sa1, float ah0, int fs)
{
  // Varduino(mv) = 0.0063 * Ibat(A) + 1,6471
  float a0 = (((sa0*3.2226/1000)-1.6471)/0.0063);   // calculate equivalent battery current Amperaje
  float a1 = (((sa1*3.2226/1000)-1.6471)/0.0063);
  
  float ah1 = (float(fs)/3600)*((a0+a1)/2);
  return (ah1 + ah0);
}*/


/* ===============================================================================
 *
 * Function Name:	blink_led()
 * Description:    	Only for testing, blink a led connected to Arduino pin13 'times' times
 *                      with a 'period' period
 *                      
 * Parameters:          times:    nº of repetitions
 *                      period:   time active in ms.
 * Returns;  		none
 *
 * =============================================================================== */
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



/* ===============================================================================
 *
 * Function Name:	carga()
 * Description:    	This funtrions convert the battery state of charge (in %) to
 *                      equivalent 8 leds representation form
 * Parameters:          carga: SOC in %
 * Returns;  		a byte with the codification for the 8 leds status display
 *
 * =============================================================================== */
byte charge(unsigned int carga){
  byte res=0;
  if (carga>0 && carga<=6) {
    res|=B00000000;
  } else if (carga>6 && carga<=18) {
    res|=B00000001;
  } else if (carga>18 && carga<=30) {
    res|=B00000011;
  } else if (carga>30 && carga<=42) {
    res|=B00000111;
  } else if (carga>42 && carga<=54) {
    res|=B00001111;
  } else if (carga>54 && carga<=66) {
    res|=B00011111;
  } else if (carga>66 && carga<=78) {
    res|=B00111111;
  } else if (carga>78 && carga<=90) {
    res|=B01111111;
  } else if (carga>90 && carga<=100) {
    res|=B11111111;
  } else {
    
  }
  return res;
}



/* ===============================================================================
 *
 * Function Name:	temp_alamr()
 * Description:    	Set the appropriate bits to control the representation of the 
 *                      temperature alarm
 * Parameters:          alarm (boolean). True: indicates a temperature alarm present
 *                                       False: indicates temperature is ok
 * Returns;  		a byte containing the active led for the actual temperature alarm
 *                      The return must be used with a bit-or opperaion with the other alarms funct
 *
 * =============================================================================== */
byte temp_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,3);
 } else {
   bitSet(res,2);
 }
 return res;
}




/* ===============================================================================
 *
 * Function Name:	level_alamr()
 * Description:    	Set the appropriate bits to control the representation of the 
 *                      level alarm
 * Parameters:          alarm (boolean). True: indicates a level alarm present
 *                                       False: indicates level is ok
 * Returns;  		a byte containing the active led for the actual level alarm
 *                      The return must be used with a bit-or opperaion with the other alarms funct
 *
 * =============================================================================== */
 byte level_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,5);
 } else {
   bitSet(res,4);
 }
 return res;
}




/* ===============================================================================
 *
 * Function Name:	charge_alamr()
 * Description:    	Set the appropriate bits to control the representation of the 
 *                      temperature alarm
 * Parameters:          alarm (boolean). True: indicates a charge alarm present
 *                                       False: indicates charge is ok
 * Returns;  		a byte containing the active led for the actual charge alarm
 *                      The return must be used with a bit-or opperaion with the other alarms funct
 *
 * =============================================================================== */
byte charge_alarm(boolean alarm){
 byte res=0;
 if (alarm){
   bitSet(res,7);
 } else {
   bitSet(res,6);
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
  //digitalWrite(emptyLED, fifo.Empty());
  //digitalWrite(fullLED, fifo.Full());
  Alarm.delay(10); // Necesary for the periodic event function. ¿¿??
  //delay(10);
} 


