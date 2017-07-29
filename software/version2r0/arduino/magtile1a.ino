#include "Adafruit_MCP23017.h"
#include <elapsedMillis.h>
#include <Servo.h>

#define PIN_POWER   4
#define PIN_ANALOG  A1

#define CS_INACTIVE  1
#define CS_ACTIVE    0

// AD7940 pinout
#define AD7940_SPI_MISO    5
#define AD7940_SPI_CS      6      
#define AD7940_SPI_CLK     7


elapsedMillis timeElapsed;
Adafruit_MCP23017 IOExpander;



/*
 * Multiplexer
 */
 
// Initialize the I/O expander
void setupIOExpander() {
  // MCP23017 I/O Expander  (for detector CS lines)
  IOExpander.begin();                        // Use default address (0)
  delay(50);
  
  // Set all pins (which are chip selects) to outputs  
  for (int i=0; i<16; i++) {
    IOExpander.pinMode(i, OUTPUT);
  }    
  
}


// Set the chip select value on a given channel
void setCS(uint8_t multiplexer, uint8_t channel) {
  uint8_t outA = 0xFF;
  uint8_t outB = 0xFF;

  // Set all values to inactive
  for (int i=0; i<16; i++) {
    //IOExpander.digitalWrite(i, CS_INACTIVE);
  }  

  // Set local group (1-16)
  if (channel & 0b00000001) {
    //IOExpander.digitalWrite(8+3, 1);
    bitSet(outB, 3);
  } else {
    //IOExpander.digitalWrite(8+3, 0);
    bitClear(outB, 3);
  }
  
  if (channel & 0b00000010) {
    //IOExpander.digitalWrite(8+2, 1);
    bitSet(outB, 2);
  } else {
    //IOExpander.digitalWrite(8+2, 0);
    bitClear(outB, 2);
  }

  if (channel & 0b00000100) {
    //IOExpander.digitalWrite(8+1, 1);
    bitSet(outB, 1);
  } else {
    //IOExpander.digitalWrite(8+1, 0);
    bitClear(outB, 1);
  }

  if (channel & 0b00001000) {
    //IOExpander.digitalWrite(8+0, 1);
    bitSet(outB, 0);
  } else {
    //IOExpander.digitalWrite(8+0, 0);
    bitClear(outB, 0);
  }


  // Set multiplexer number (1-9)
  if (multiplexer == 1) bitClear(outB, 5); //IOExpander.digitalWrite(13, CS_ACTIVE);
  if (multiplexer == 2) bitClear(outA, 0); //IOExpander.digitalWrite(0, CS_ACTIVE);
  if (multiplexer == 3) bitClear(outA, 5); //IOExpander.digitalWrite(5, CS_ACTIVE);

  if (multiplexer == 4) bitClear(outB, 6); //IOExpander.digitalWrite(14, CS_ACTIVE);
  if (multiplexer == 5) bitClear(outA, 3); //IOExpander.digitalWrite(3, CS_ACTIVE);
  if (multiplexer == 6) bitClear(outA, 6); //IOExpander.digitalWrite(6, CS_ACTIVE);

  if (multiplexer == 7) bitClear(outB, 7); //IOExpander.digitalWrite(15, CS_ACTIVE);
  if (multiplexer == 8) bitClear(outA, 4); // IOExpander.digitalWrite(4, CS_ACTIVE);
  if (multiplexer == 9) bitClear(outA, 7); //IOExpander.digitalWrite(7, CS_ACTIVE);
  

  uint16_t ports = outA + ((uint16_t)outB<<8);
  IOExpander.writeGPIOAB(ports);
}


void selectChannel(uint8_t x, uint8_t y) {
  uint8_t multiplexer = 0;
  uint8_t channel = 0;

  // Select multiplexer
  if ((x <= 3) && (y <= 3)) {
    multiplexer = 1;
  } else if ((x <= 7) && (y <= 3)) {
    multiplexer = 2;
  } else if ((x <= 12) && (y <= 3)) {
    multiplexer = 3;
  } else if ((x <= 3) && (y <= 7)) {
    multiplexer = 4;
  } else if ((x <= 7) && (y <= 7)) {
    multiplexer = 5;
  } else if ((x <= 12) && (y <= 7)) {
    multiplexer = 6;
  } else if ((x <= 3) && (y <= 12)) {
    multiplexer = 7;
  } else if ((x <= 7) && (y <= 12)) {
    multiplexer = 8;
  } else if ((x <= 12) && (y <= 12)) {
    multiplexer = 9;
  }

  // Select channel
  uint8_t x0 = x % 4;
  uint8_t y0 = y % 4;
  if ((x0 == 0) && (y0 == 0)) {
    channel = 9;
  } else if ((x0 == 1) && (y0 == 0)) {
    channel = 11;
  } else if ((x0 == 2) && (y0 == 0)) {
    channel = 13;
  } else if ((x0 == 3) && (y0 == 0)) {
    channel = 15;
  } else if ((x0 == 0) && (y0 == 1)) {
    channel = 8;
  } else if ((x0 == 1) && (y0 == 1)) {
    channel = 10;
  } else if ((x0 == 2) && (y0 == 1)) {
    channel = 12;
  } else if ((x0 == 3) && (y0 == 1)) {
    channel = 14;
  } else if ((x0 == 0) && (y0 == 2)) {
    channel = 6;
  } else if ((x0 == 1) && (y0 == 2)) {
    channel = 4;
  } else if ((x0 == 2) && (y0 == 2)) {
    channel = 2;
  } else if ((x0 == 3) && (y0 == 2)) {
    channel = 0;
  } else if ((x0 == 0) && (y0 == 3)) {
    channel = 7;
  } else if ((x0 == 1) && (y0 == 3)) {
    channel = 5;
  } else if ((x0 == 2) && (y0 == 3)) {
    channel = 3;
  } else if ((x0 == 3) && (y0 == 3)) {
    channel = 1;
  }

  setCS(multiplexer, channel);
}

/*
 * Analog Read
 */
 
int readMagnetometer() {
  //return readInternalADC();
  return readAD7940();
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
 * Power
 */

void powerTile(int mode) {
   digitalWrite(PIN_POWER, mode); 
}



void setup() {
  // Serial
  Serial.begin(115200);
  Serial.println("Initializing...");

  
  // Disable power to tile during setup
  pinMode(PIN_POWER, OUTPUT);
  Serial.println("*Power");
  
  // Setup I/O Expander
  Serial.println("*IO Expander");
  setupIOExpander();

  // Blink light
  Serial.println("*Blink");
  pinMode(LED_BUILTIN, OUTPUT);

  // AD7940 ADC Pin modes
  pinMode(AD7940_SPI_CS, OUTPUT);
  pinMode(AD7940_SPI_CLK, OUTPUT);
  pinMode(AD7940_SPI_MISO, INPUT);
  

  Serial.println("*Powering Array...");
  delay(1000);
  powerTile(0);
  
}

uint8_t pos = 0;

void loop() {
  timeElapsed=0;
  Serial.println("*Cycle");
  selectChannel(5, 5);

  // Read the imager data, pixel by pixel, and send the values to the serial port
  for (uint8_t x=0; x<12; x++) {
    for (uint8_t y=0; y<12; y++) {
      //setCS(i, j);
      selectChannel(x, y);
      int value = readMagnetometer();

      Serial.print(value);
      Serial.print(" ");
    }
    Serial.println("");
  }

  Serial.println(timeElapsed);
  // Blink 
  digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
//  delay(500);                       // wait for a second
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
//  delay(500);                       // wait for a second
  

}
