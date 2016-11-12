#include  <SPI.h>
#include "nRF24L01.h"
#include "RF24.h"
#include <Wire.h> //Include the Wire library
#include <MMA_7455.h> //Include the MMA_7455 library
int msg[1];
RF24 radio(9,10);
const uint64_t pipe = 0xE8E8F0F0E1LL;
/*-----( Declare objects )-----*/
MMA_7455 mySensor = MMA_7455(); //Make an instance of MMA_7455
/*-----( Declare Variables )-----*/
char xVal, yVal, zVal; //Variables for the values from the sensor

void setup(void) {
  Serial.begin(9600);
  radio.begin();
  radio.openWritingPipe(pipe);
  delay(500);
  Serial.println("MMA7455 Accelerometer Test");
  // Set the sensitivity you want to use
  // 2 = 2g, 4 = 4g, 8 = 8g
  mySensor.initSensitivity(8); // Good for "Tilt" measurements
  //mySensor.calibrateOffset(0,0,-60); //Uncomment for first try: find offsets
  mySensor.calibrateOffset(5.0, 11.0, -70.0); //Then Uncomment and use this
}

 void loop(void){
    xVal = mySensor.readAxis('x'); //Read out the 'x' Axis
    yVal = mySensor.readAxis('y'); //Read out the 'y' Axis
    zVal = mySensor.readAxis('z'); //Read out the 'z' Axis
    Serial.print("X = ");
    Serial.print(xVal, DEC);
    Serial.print("   Y = ");
    Serial.print(yVal, DEC);
    Serial.print("   Z = ");
    Serial.println(zVal, DEC);
  /*--( Show tilt [Assumes unit has been calibrated ] )----*/  
    msg[0] = 111;
    if (xVal < -20 && zVal > -45) msg[0] = 1; // tilted left
    if (xVal >  20 && zVal > -45) msg[0] = 2; // titled right
    if (yVal < -20 && zVal > -45) msg[0] = 3; // titled forward   
    if (yVal >  20 && zVal > -45) msg[0] = 4; // titled away  
    if (zVal < -45 ) Serial.println("UPSIDE DOWN!"); 
    radio.write(msg, 1);
    Serial.println(msg[0]);
 }
