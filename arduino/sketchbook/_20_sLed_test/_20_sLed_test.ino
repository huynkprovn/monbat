#include <sLed.h>

byte data;
sLed led(7,5,4,6,8);

void setup(){ 
  led.Clear();
}


/* ===============================================================================
 *
 * Function Name:	blink_led()
 * Description:    	Only for testing, blink a led connected to Arduino pin12 'times' times
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

void loop(){ 
  
  led.Write(data);
  //blink_led(2,300);
  delay(200);
  if (data == 16){
    //led.Clear();
    data=0;
  } else{
    data++;
  }
    

}


