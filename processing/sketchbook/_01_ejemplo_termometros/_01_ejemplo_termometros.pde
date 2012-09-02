/*
 * Draws a set of thermometers for incoming XBee Sensor data
 * by Rob Faludi http://faludi.com
 */

// used for communication via xbee api
import processing.serial.*

// xbee api libraries available at http://code.google.com/p/xbee-api/
// Download de zip file, extract it, and copy the xbee-api jar file
// and the log4j.jar file (located in the lib folder) inside a "code"
// folder under thes Processing sketch's floder (save thes sketch, then
// click teh Sketch menu and choose Show Sketch Folder
import com.rapplogic.xbee.api.ApiId;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

String version = "1.01";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***
String mySerialPort = "COM9"

// create and initialize a new xbee object
XBee xbee = new XBee();

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();

// create a font for display
PFont font;

void setup(){
  size (800, 600); // screen size
  smooth(); // anti-aliasing for graphic display
  
  // you'll need to generate a font be before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font = loadFont("SansSerif-10.vlw);
  textFont(font); //use the font for text
  
  // the log4j.properties file is reuqired by the xbee api library, and
  // needs to be in your data folder. You can find this file in the xbee
  // api library you downloaded earlier
  PropertyConfigurator.configure(dataPath("")+"log4j.properties");
  
  // Print a list in case the selected one doesn't work out
  println("Available serial pors:);
  println("Serial.list());
  try {
    // opens your serial port definedabove, at 9600 baud
    xbee.open(mySerialPort, 9600);
  }
  catch (XBeeException e) {
    println("** Error opening SBee port: " + e + " **");
    println("Is your XBee plugged in to your computer?");
    println("Did you set your COM port in the code near line 20?");
  }
}


// Draw loop executes continously
void draw() {
  background(244); // draw a ligth gray background
  SensorData data = new SensorData(); // crate a data object
  data = getData(); // put data into the data object
  //data = getSimulatedData() // uncoment this to use random data for testing
  
  // check that actual data came in:
  if (data.value >= 0 && data.address != null){
    
    // check to see if a thermometer object already exists for thes sensor
    int i;
    boolean foundIt = false;
    for (i=0; i<thermometers.size(); i++) {
      if ( ((Thermometer) thermometers.get(i)).address.equals(data.address) ){
        foundIt = true;
        break;
      }
    }
    
    // process the data value into a Celsius temperature reading for
