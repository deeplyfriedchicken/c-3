/***********************************************************************
 * Arduino file for controlling an 8x8x8 cube using 4 Allegro A6276AE
 * LED driver chips.  Logic should be scalable to other sized cubes.
 * by Randy Starcher with some code copied from:
 *
 * demo16x24.c - Arduino demo program for Holtek HT1632 LED driver chip,
 *            As implemented on the Sure Electronics DE-DP016 display board
 *            (16*24 dot matrix LED module.)
 *  Nov, 2008 by Bill Westfield ("WestfW")
 *  Copyrighted and distributed under the terms of the Berkely license
 *  (copy freely, but include this notice of original author.)
 *
 *  and
 *
 *  Eight_x_eight_LED_panel.pde by Paul Badger of www.moderndevice.com
 *
 *  Code uses roughly 1/3 available memory on an ATmega168, so there is
 *  a lot of room for expansion
 *
 *  Build cube with planes in common anode.  Attach LED cathode (columns)
 *  to A6276AE outputs in this pattern:
 *  1  2  3  4  5  6  7  8
 *  9  10 11 12 13 14 15 16
 *  17 18 19 20 21 22 23 24
 *  25 26 27 28 29 30 31 32
 *  33 34 35 36 37 38 39 40
 *  41 42 43 44 45 46 47 48
 *  49 50 51 52 53 54 55 56
 *  57 58 59 60 61 62 63 64
 * Plane pins are 6, 7, 8, 9, 10, 11, 12, 13 top to bottom
 ***********************************************************************/

//Pin connected to SPI latch
int latchPin = 4;
//Pin connected to SPI clock
int clockPin = 3;
//Pin connected to SPI data
int dataPin = 2;

int  frameDelay = 50;

byte anode[]={14,6,7,8,9,10,11,12,13,14};
int leds[]={0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,0};
byte diag1[]={1,2,9,3,10,17,4,11,18,25,5,12,19,26,33,6,13,20,27,34,41,7,14,21,28,35,42,49,8,15,22,29,36,43,50,57,16,23,30,37,44,51,58,24,31,38,45,52,59,32,39,46,53,60,40,47,54,61,48,55,62,56,63,64,0};
byte diag2[]={8,7,16,6,15,24,5,14,23,32,4,13,22,31,40,3,12,21,30,39,48,2,11,20,29,38,47,56,1,10,19,28,37,46,55,64,9,18,27,36,45,54,63,17,26,35,44,53,62,25,34,43,52,61,33,42,51,60,41,50,59,49,58,57,0};

int pattern1[]={50151,50151,50151,50163,33275,509,33150,32959,33247,33263,50151,50151,50151};
int pattern2[]={6309,165,129,257,33025,33153,33153,33153,33152,32897,129,165,6309};
int pattern3[]={42264,42240,33024,32896,32897,33153,33153,33153,385,33025,33024,42240,42264};
int pattern4[]={59331,59331,59331,53187,57217,49024,32385,64769,64385,63361,59331,59331,59331};

//global variable to hold chip totals before writing
int chipval[]={
  0,0,0,0};

//Change this to scale cube
#define CUBESIZE 8

#define NUMLEDS CUBESIZE*CUBESIZE
#define LOWCUBE CUBESIZE-1
#define HIGHCUBE CUBESIZE+1
#define HIGHNUM NUMLEDS+1
#define LOWNUM NUMLEDS-1
#define LED(x,y) (x+CUBESIZE*y)+1

void setup() {
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
  digitalWrite(latchPin, HIGH);
  randomSeed(analogRead(2));
}

void loop() {
  int i;
  int x=0;
  int m;
  m=0;

  allclear();

  for(int x = 1; x < HIGHCUBE; x++) {
    digitalWrite(anode[x], HIGH);
  }
  demo_random_walk();
  demo_bouncyline();

  for(int x = 1; x < HIGHCUBE; x++) {
    plane(x);
    delay(50);
  }

  for(int x = CUBESIZE; x>0; x--) {
    plane(x);
    delay(50);
  }

  for(int x = 1; x < HIGHCUBE; x++) {
    digitalWrite(anode[x], HIGH);
  }

  //4 sides outer
  for(int x = 0; x < 10; x++) {
    verticalPlane(1);
    horizontalPlane(1);
    verticalPlane(8);
    horizontalPlane(57);
  }

  for(x=0;x<sizeof(pattern1)/2; x++){
    chipval[0]=pattern1[x];
    chipval[1]=pattern2[x];
    chipval[2]=pattern3[x];
    chipval[3]=pattern4[x];
    chipwrite(1);
    delay(75);
  }

  for (x=1;x<=HIGHNUM;x+=CUBESIZE){
    horizontalPlane(x);
  }
  delay(75);

  for (x=(HIGHNUM-CUBESIZE);x>0;x-=CUBESIZE){
    horizontalPlane(x);
  }

  delay(75);
  for (x=1;x<=CUBESIZE;x++){
    verticalPlane(x);
  }
  delay(75);
  for (x=CUBESIZE;x>0;x--){
    verticalPlane(x);
  }

  //diag fill left to right, forward and back then right to left
  for (i=0;i<NUMLEDS; i++){
    whichled(diag1[i]);
    chipwrite(0);
  }
  allclear();
  for (i=LOWNUM;i>=0; i--){
    whichled(diag1[i]);
    chipwrite(0);
  }
  allclear();

  for (i=0;i<NUMLEDS; i++){
    whichled(diag2[i]);
    chipwrite(0);
  }
  allclear();

  for (i=LOWNUM;i>=0; i--){
    whichled(diag2[i]);
    chipwrite(0);
  }
  allclear();

  //vertical fill forward and back
  for (m=0;m<CUBESIZE;m++){
    for (i=1;i<HIGHNUM; i+=CUBESIZE){
      whichled(i+m);
      chipwrite(0);
    }
  }
  allclear();

  for (m=0;m<CUBESIZE;m++){
    for (i=NUMLEDS;i>0; i-=CUBESIZE){
      whichled(i-m);
      chipwrite(0);
    }
  }
  allclear();
  //fill horizonal forward and reverse
  for (i=1;i<HIGHNUM; i++){
    whichled(i);
    chipwrite(0);
  }
  allclear();

  for (i=NUMLEDS;i>0; --i){
    whichled(i);
    chipwrite(0);
  }
  allclear();
  //scan horizonal forward and reverse
  for (i=1;i<HIGHNUM; i++){
    whichled(i);
    chipwrite(1);
  }

  for (i=NUMLEDS;i>0; --i){
    whichled(i);
    chipwrite(1);
  }

  //vertical scan forward and back
  for (m=0;m<CUBESIZE;m++){
    for (i=1;i<HIGHNUM; i+=CUBESIZE){
      whichled(i+m);
      chipwrite(1);
    }
  }

  for (m=0;m<CUBESIZE;m++){
    for (i=NUMLEDS;i>0; i-=CUBESIZE){
      whichled(i-m);
      chipwrite(1);
    }
  }

  //diag left to right, forward and back
  for (i=0;i<NUMLEDS; i++){
    whichled(diag1[i]);
    chipwrite(1);
  }
  for (i=LOWNUM;i>=0; i--){
    whichled(diag1[i]);
    chipwrite(1);
  }
  for (i=0;i<NUMLEDS; i++){
    whichled(diag2[i]);
    chipwrite(1);
  }
  for (i=LOWNUM;i>=0; i--){
    whichled(diag2[i]);
    chipwrite(1);
  }

  delay(50);
}

// this sends the data to the display with an SPI (shiftout) protocol
// if using multiple chips you MUST send data back to front, chip 4 then 3 then 2 then 1
void chipwrite(int clearit){
  digitalWrite(latchPin, LOW);

  //write values in chipval[] to the chip, last value first
  for (int chp=3;chp>=0;chp--){
    shiftOut(dataPin, clockPin, MSBFIRST, chipval[chp] >>8);   // send high byte
    shiftOut(dataPin, clockPin, MSBFIRST, chipval[chp]);
  }

  //return the latch pin HIGH to update LED's
  digitalWrite(latchPin, HIGH);

//clear chipval[] if needed
  if (clearit==1) {
    allclear();
  }
  delay(frameDelay);  // change frameDelay above to control scrolling speed
}

void verticalPlane(int i) {
  int x=0;

  for (int z=0; z<CUBESIZE;z++){
    whichled(i+(CUBESIZE*z));
  }
  chipwrite(1);
}


void horizontalPlane(int i) {
  int x=0;

  for (int z=0; z<CUBESIZE;z++){
    whichled(i+z);
  }
  chipwrite(1);
}

//determines address of the desired chip and adds the LEDs value to the chipval variable of the correct chip
//there is no error checking in this, if you try to light the same led twice it will screw things up
//use allclear() to reset values to 0
void whichled(int i){
  int chip=0;
  int light=0;
  i--;
  light = i%(2*CUBESIZE);
  light++;
  chip = i/(2*CUBESIZE);  
  chipval[chip]+=leds[light];
}

//darkens all layers then lights all the leds on a specific layer
void plane(int i) {
  for(int x = 1; x < HIGHNUM; x++) {
    digitalWrite(anode[x], LOW);
  }

  digitalWrite(anode[i], HIGH);
  for(int chp=0;chp<4;chp++){
    chipval[chp]=65535;
  }
  chipwrite(1);
}

/* comment and code from Bill Westfield:
 * Draw a line between two points using the bresenham algorithm.
 * This particular bit of code is copied nearly verbatim from
 *   http://www.gamedev.net/reference/articles/article1275.asp
 * I don't like it much (too many local variables!), but it works,
 * and is fully explained at the site, so...
 */
void bres_line(byte x1, byte y1, byte x2, byte y2 )
{
  byte deltax = abs(x2 - x1);        // The difference between the x's
  byte deltay = abs(y2 - y1);        // The difference between the y's
  byte x = x1;                       // Start x off at the first pixel
  byte y = y1;                       // Start y off at the first pixel
  byte xinc1, xinc2, yinc1, yinc2, den, num, numadd, numpixels, curpixel;
  
  if (x2 >= x1) {                // The x-values are increasing
    xinc1 = 1;
    xinc2 = 1;
  }
  else {                          // The x-values are decreasing
    xinc1 = -1;
    xinc2 = -1;
  }

  if (y2 >= y1)                 // The y-values are increasing
  {
    yinc1 = 1;
    yinc2 = 1;
  }
  else                          // The y-values are decreasing
  {
    yinc1 = -1;
    yinc2 = -1;
  }

  if (deltax >= deltay)         // There is at least one x-value for every y-value
  {
    xinc1 = 0;                  // Don't change the x when numerator >= denominator
    yinc2 = 0;                  // Don't change the y for every iteration
    den = deltax;
    num = deltax / 2;
    numadd = deltay;
    numpixels = deltax;         // There are more x-values than y-values
  }
  else                          // There is at least one y-value for every x-value
  {
    xinc2 = 0;                  // Don't change the x for every iteration
    yinc1 = 0;                  // Don't change the y when numerator >= denominator
    den = deltay;
    num = deltay / 2;
    numadd = deltax;
    numpixels = deltay;         // There are more y-values than x-values
  }

  for (curpixel = 0; curpixel <= numpixels; curpixel++)
  {
    whichled(LED(x,y));
    num += numadd;              // Increase the numerator by the top of the fraction
    if (num >= den)             // Check if numerator >= denominator
    {
      num -= den;               // Calculate the new numerator value
      x += xinc1;               // Change the x as appropriate
      y += yinc1;               // Change the y as appropriate
    }
    x += xinc2;                 // Change the x as appropriate
    y += yinc2;                 // Change the y as appropriate
  }
  chipwrite(1);
}

/*
 * demo_bouncyline  comment and code from Bill Westfield:
 * Do the classic "bouncing line" demo, where the endpoints of a line
 * move independently and bounce off the edges of the display.
 * This should demonstrate (more or less) the performance limits of
 * the line drawing function.
 */
void demo_bouncyline ()
{
  byte x1,y1, x2,y2, dx1, dy1, dx2, dy2;

  x1 = random(0,LOWCUBE);
  x2 = random(0,LOWCUBE);
  y1 = random(0,LOWCUBE);
  y2 = random(0,LOWCUBE);
  dx1 = random(1,4);
  dx2 = random(1,4);
  dy1 = random(1,4);
  dy2 = random(1,4);
  for (int i=0; i < 100; i++) {
    bres_line(x1,y1, x2,y2);
    delay(75);

    x1 += dx1;
    if (x1 > LOWCUBE) {
      x1 = LOWCUBE;
      dx1 = -random(1,4);
    }
    else if (x1 < 0) {
      x1 = 0;
      dx1 = random(1,4);
    }

    x2 += dx2;
    if (x2 > LOWCUBE) {
      x2 = LOWCUBE;
      dx2 = -random(1,4);
    }
    else if (x2 < 0) {
      x2 = 0;
      dx2 = random(1,4);
    }

    y1 += dy1;
    if (y1 > LOWCUBE) {
      y1 = LOWCUBE;
      dy1 = -random(1,3);
    }
    else if (y1 < 0) {
      y1 = 0;
      dy1 = random(1,3);
    }

    y2 += dy2;
    if (y2 > LOWCUBE) {
      y2 = LOWCUBE;
      dy2 = -random(1,3);
    }
    else if (y2 < 0) {
      y2 = 0;
      dy2 = random(1,3);
    }
  }
}

/*
 * demo_random_walk()  comment and code from Bill Westfield:
 * have a single LED walk all over the display, randomly.
 */
void demo_random_walk ()
{
  byte x,y, dx, dy;
  dx = dy = 1;
  byte change;
  x=4;
  y=4;

  for (int i=0; i < (100);  i++) {
    whichled(LED(x,y));
    chipwrite(1);
    delay(30);
    change = random(0,4);
    /*
   * figure out where to go next.  This code is a bit
     * random in more senses than one, but it seems to
     * have results that are more or less what I had in
     * mind for this portion of the demo.
     */
    if (change == 0) {
      dx = -dx;
    }
    else if (change == 1) {
      dy = -dy;
    }
    else if (change == 2) {
      dx = dy = 0;
    }
    else if (change == 3) {
      dx = dy = 1;
    }
    else if (change == 4) {
      dx = dy = -1;
    }

    x = x + dx;
    y = y+ dy;
    if (x > LOWCUBE) {
      dx = -1;
      x = LOWCUBE;
    }
    else if (x < 0) {
      x = 0;
      dx = 1;
    }
    if (y >  LOWCUBE) {
      y = LOWCUBE;
      dy = -1;
    }
    else if (y < 0) {
      y = 0;
      dy = 1;
    }
  }
}

void allclear(){
  chipval[0]=0;
  chipval[1]=0; //zero out the global variable so you can fill it again
  chipval[2]=0;
  chipval[3]=0;
}
