#include <SPI.h>
#include "nRF24L01.h"
#include "RF24.h"
int msg[1];
RF24 radio(9,10);
const uint64_t pipe = 0xE8E8F0F0E1LL;

void setup(void){
 Serial.begin(9600);
 radio.begin();
 radio.openReadingPipe(1,pipe);
 radio.startListening();
 }
 
 void loop(void){
   if (radio.available()){
     bool done = false;
     bool done2 = false;
    Serial.println("HI");    
     while (!done2){
       done = radio.read(msg, 1);      
       Serial.println(msg[0]);
       if (msg[0] == 1){Serial.println("Tilted Left");}
       else if (msg[0] == 2){Serial.println("Tilted right");}
       else if (msg[0] == 3){Serial.println("Tilted forward");}
       else if (msg[0] == 4){Serial.println("Tilted away");}
       delay(500);
       }
      }
   else{
    Serial.println("No radio available");
   }
 }
