// This basic example shows how to interface with the Magnetic Imaging Tile V3
// with a Chipkit MAX32, with data displayed via the serial port. 
// Simple serial commands allow viewing the data in a serial console, or
// sending the data to a program on a host system (such as the accompanying
// Processing example) for display. 
//
// The code primarily uses the internal ADC of the Chipkit MAX32, but
// (slow) code is also provided for using the AD7940 on the tile as 
// well.  The speed of the ADC and I/O clocking is essentially the
// limiting factor in framerate, and this should be kept in mind
// when porting to other platforms (e.g. the Arduino Uno). 
//
// The Chipkit MAX32 provides ~128K of RAM, which is enough for a
// short framebuffer (up to about 500 frames) when recording
// high-speed data. 
//
// This code was written in MPIDE 0023-windows-20140316 . 


char inputString[80];       // a String to hold incoming data
boolean stringComplete = false;  // whether the string is complete
int curStrIdx = 0;


int PIN_CLR   =   8;
int PIN_CLK   =   9;

#define PIN_ANALOG  A1

#define CS_INACTIVE  1
#define CS_ACTIVE    0

// AD7940 pinout
#define AD7940_SPI_MISO    5
#define AD7940_SPI_CS      6      
#define AD7940_SPI_CLK     7


// Frames
//#define MAX_BASE_FRAMES  500
//#define MAX_BASE_FRAMES  250
#define MAX_BASE_FRAMES  100
//#define _8BIT

#ifdef _8BIT
#define MAX_FRAMES      MAX_BASE_FRAMES*2
uint8_t frames[MAX_FRAMES][64];
#else
#define MAX_FRAMES      MAX_BASE_FRAMES
uint16_t frames[MAX_FRAMES][64];
#endif


// Frame variables
// Magnetic tile reading
int pixelOrder[] = {26, 27, 18, 19, 10, 11, 2, 3, 1, 0, 9, 8, 17, 16, 25, 24};
int subtileOrder[] = {0, 2, 1, 3};
int subtileOffset[] = {0, 4, 32, 36};
uint16_t frame[64]; 

int numFrames = 0;
int curFrame = 0;

#define MODE_IDLE          0  
#define MODE_LIVE          1
#define MODE_HIGHSPEED1    2
#define MODE_HIGHSPEED2    3
#define MODE_HIGHSPEED3    4
#define MODE_HIGHSPEED4    5

int curMode = MODE_IDLE;



/*
 * Analog Read
 */
 
int readMagnetometer() {
  //return 0;
  return analogRead(PIN_ANALOG);
  //return readInternalADC();
  //return readAD7940();
  //return read_ad7940();
}

// Take one measurement form the internal ADC
int readInternalADC() {
  int numSamples = 2;
  float sum = 0.0f;
  for (int i=0; i<numSamples; i++) {
    int sensorValue = analogRead(PIN_ANALOG);
    sum += sensorValue;
  }
  sum /= numSamples;
  
  //return sensorValue;
  return int(floor(sum));
}
c
// Take one measurement from an external AD7940 14-bit ADC (SPI)
uint16_t readAD7940() {
  uint16_t value = 0;
  uint16_t delay_time = 2;
  // Idle
  digitalWrite(AD7940_SPI_CS, HIGH);   
  digitalWrite(AD7940_SPI_CLK, HIGH);  
    
  // Enable
  digitalWrite(AD7940_SPI_CS, LOW);    
  
  // Read 16 bits
  for (int i=0; i<16; i++) {
    char bit = digitalRead(AD7940_SPI_MISO);
    digitalWrite(AD7940_SPI_CLK, LOW);  
//    delayMicroseconds(delay_time);

    value = value << 1;    
    value = value + (bit & 0x01);   
    digitalWrite(AD7940_SPI_CLK, HIGH);     
//    delayMicroseconds(delay_time);    
  }
  // Disable
  digitalWrite(AD7940_SPI_CS, HIGH);    
//  delayMicroseconds(delay_time);
  
  return value;    
}



/*
 * Magnetic Sensors
 */

void clearCounter() {
  digitalWrite(PIN_CLR, 0);
  //delay(10);
  digitalWrite(PIN_CLR, 1);
  //delay(10);
}

void incrementCounter() {
  digitalWrite(PIN_CLK, 1);
  //delay(1);
  digitalWrite(PIN_CLK, 0);
  //delay(1);
}


/*
 * Capture one frame from imaging array
 */ 
void readTileFrame() {
   
  clearCounter();
  incrementCounter();
   
  for (int curSubtileIdx=0; curSubtileIdx<4; curSubtileIdx++) {
    for (int curIdx=0; curIdx<16; curIdx++) {
      // Read value
      int value = readMagnetometer();  
  
//    Serial.println(value);
//    delay(10);
 
      // Store value in correct frame location
      int frameOffset = pixelOrder[curIdx] + subtileOffset[subtileOrder[curSubtileIdx]];
      //Serial.println(frameOffset);
      //delay(25);
      frame[frameOffset] = value;   

      // Increment to next pixel
      incrementCounter();
    }
  }
  
}

// Display current frame on serial console
void displayCurrentFrame() {
  // Display frame
//  Serial.println ("\nCurrent Frame");
  int idx = 0;    
  for (int i=0; i<8; i++) {
    for (int j=0; j<8; j++) {
      Serial.print( frame[idx] );
      Serial.print( " " );        
      idx += 1;
    }
    Serial.println("");
  }    
  Serial.println("*");  
  
}


// Record MAX_FRAMES, as fast as possible
void recordHighSpeedFrames(int frameDelayTime) {
  long startTime = millis();
  
  for (int curFrame=0; curFrame<MAX_FRAMES; curFrame++) {
    // Read one frame
    readTileFrame();
          
    // Store frame
    #ifdef _8BIT
      for (int a=0; a<64; a++) {
        frames[curFrame][a] = frame[a] >> 2;
      }
    #else
      for (int a=0; a<64; a++) {
        frames[curFrame][a] = frame[a];
      }
    #endif        
    
    if (frameDelayTime > 0) {
     delay(frameDelayTime);
    } 
  } 
  
  long endTime = millis();
  Serial.print("Framerate: "); 
  Serial.println((float)MAX_FRAMES / ((float)(endTime-startTime)/1000.0f));           
    
}  


// Playback the high speed frames stored 
void playbackHighSpeedFrames() {
  
  for (int curFrame=0; curFrame<MAX_FRAMES; curFrame++) { 
    // Display frame
//    Serial.print ("\nFrame ");
//    Serial.println (curFrame);
    
    int idx = 0;    
    for (int i=0; i<8; i++) {
      for (int j=0; j<8; j++) {
        Serial.print( frames[curFrame][idx] );
        Serial.print( " " );        
        idx += 1;
      }
      Serial.println("");
    }    
        
    Serial.println("*");
    delay(50);
  }
  

  
}



long startTime = 0;
void setup() {
  // Setup pin modes
  pinMode(PIN_CLR, OUTPUT);
  pinMode(PIN_CLK, OUTPUT);

  // AD7940 ADC Pin modes
  pinMode(AD7940_SPI_CS, OUTPUT);
  pinMode(AD7940_SPI_CLK, OUTPUT);
  pinMode(AD7940_SPI_MISO, INPUT);


  // Setup initial states
  incrementCounter();
  clearCounter();
  
  // initialize serial:
  Serial.begin(115200);
  
  Serial.println ("Initializing.... Press L (live) or H (high speed), 1, 2, 3, or S (idle)");
  
  clearCounter();
  incrementCounter();  
  delay(100);

  startTime = millis();
}



void loop() {

  /*
   *  Parse serial data (if any)
   */ 
  if (Serial.available()) {
    serialEvent();
  }
   
  // print the string when a newline arrives:
  if (stringComplete) {
    Serial.println(inputString);

    if (strcmp(inputString, "L") == 0) {
      Serial.println("Live");
      curMode = MODE_LIVE;

    } else if ((strcmp(inputString, "H") == 0) || (strcmp(inputString, "1") == 0)) {
      Serial.println("High-speed Save1");
      curMode = MODE_HIGHSPEED1;

    } else if (strcmp(inputString, "2") == 0) {
      Serial.println("High-speed Save2 (1000hz)");
      curMode = MODE_HIGHSPEED2;

    } else if (strcmp(inputString, "3") == 0) {
      Serial.println("High-speed Save3 (500hz)");
      curMode = MODE_HIGHSPEED3;

    } else if (strcmp(inputString, "4") == 0) {
      Serial.println("High-speed Save4 (250hz)");
      curMode = MODE_HIGHSPEED4;

    } else if (strcmp(inputString, "S") == 0) {
      Serial.println("Idle");
      curMode = MODE_IDLE;
    }
    
    Serial.print("Input: ");
    Serial.println(inputString);
    // clear the string:
    strcpy(inputString, "");
    curStrIdx = 0;
    stringComplete = false;
  }

  
  /*
   * Take action based on current mode
   */
  if (curMode == MODE_LIVE) {
    readTileFrame();
    displayCurrentFrame();
    
  } else if (curMode == MODE_HIGHSPEED1) {
    // Full/maximum speed
    recordHighSpeedFrames(0);
    playbackHighSpeedFrames();
    curMode = MODE_IDLE;
    
    Serial.println ("Initializing.... Press L (live) or H (high speed), 1, 2, 3, or S (idle)");

  } else if (curMode == MODE_HIGHSPEED2) {
    // ~1000Hz
    recordHighSpeedFrames(1);
    playbackHighSpeedFrames();
    curMode = MODE_IDLE;
    
    Serial.println ("Initializing.... Press L (live) or H (high speed), 1, 2, 3, or S (idle)");

  } else if (curMode == MODE_HIGHSPEED3) {
    // ~500Hz
    recordHighSpeedFrames(2);
    playbackHighSpeedFrames();
    curMode = MODE_IDLE;
    
    Serial.println ("Initializing.... Press L (live) or H (high speed), 1, 2, 3, or S (idle)");
    
  } else if (curMode == MODE_HIGHSPEED4) {
    // ~250Hz    
    recordHighSpeedFrames(4);
    playbackHighSpeedFrames();
    curMode = MODE_IDLE;
    
    Serial.println ("Initializing.... Press L (live) or H (high speed), 1, 2, 3, or S (idle)");
    
  }


  
  //delay(10);
  
  
}



/*
  SerialEvent occurs whenever a new data comes in the hardware serial RX. This
  routine is run between each time loop() runs, so using delay inside loop can
  delay response. Multiple bytes of data may be available.
*/
void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inChar == '\n') {
      stringComplete = true;
    } else {
      // add it to the inputString:
      inputString[curStrIdx] = inChar;
      curStrIdx += 1;
      
    }
  }
}

