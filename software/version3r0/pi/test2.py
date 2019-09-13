# This is largely a port of the Arduino code to Python for the Raspberry Pi 3, to test the framerate. 
# This was able to achieve about 120-150fps (depending on whether debug output was displayed to the console)

from __future__ import print_function
import RPi.GPIO as GPIO
import time	 
 

#
# Channel Selection (counter)
#
pixelOrder = [26, 27, 18, 19, 10, 11, 2, 3, 1, 0, 9, 8, 17, 16, 25, 24];
subtileOrder = [0, 2, 1, 3];
subtileOffset = [0, 4, 32, 36];

def clearCounter():
	GPIO.output(PIN_CLR, 0)
	GPIO.output(PIN_CLR, 1)


def incrementCounter():
	GPIO.output(PIN_CLK, 1)
	GPIO.output(PIN_CLK, 0)
	

#
# Analog to digital converter
#

# Pin definitions
AD7940_SPI_MISO		= 9
AD7940_SPI_CS		= 8
AD7940_SPI_CLK		= 11

PIN_CLR				= 20
PIN_CLK				= 21

def readAD7940():
	value = 0
	
	# Idle
	GPIO.output(AD7940_SPI_CS, 1)
	GPIO.output(AD7940_SPI_CLK, 1)
	
	# Enable
	GPIO.output(AD7940_SPI_CS, 0)
	
	# Read 16 bits
	for i in range(0, 16):
		bit = 0
		if (GPIO.input(AD7940_SPI_MISO)): bit = 1

		GPIO.output(AD7940_SPI_CLK, 0)
		
		value = value << 1
		value = value + (bit & 0x01)
		
		GPIO.output(AD7940_SPI_CLK, 1)
		
		
	# Disable
	GPIO.output(AD7940_SPI_CS, 1)	
	
	# Return
	return value



def readTileFrame():
	frame = [0] * 64
	clearCounter()
	incrementCounter()
   
	for curSubtileIdx in range(0, 4):
		for curIdx in range(0, 16):
			# Read value
			value = readAD7940()			
 
			# Store value in correct frame location
			frameOffset = pixelOrder[curIdx] + subtileOffset[subtileOrder[curSubtileIdx]];
			frame[frameOffset] = value;   

			# Increment to next pixel
			incrementCounter();

	return frame;

	
def displayFrame(frame):
	idx = 0;
	for x in range(0, 8):
		for y in range(0, 8):
			print(str(frame[idx]) + " ", end="")
			idx += 1
		print("")
	print("")	
	
	
	
# Setup pins
GPIO.setmode(GPIO.BCM)

# ADC pins
GPIO.setup(AD7940_SPI_MISO, GPIO.IN)
GPIO.setup(AD7940_SPI_CLK, GPIO.OUT)
GPIO.setup(AD7940_SPI_CS, GPIO.OUT)

# Counter pins
GPIO.setup(PIN_CLR, GPIO.OUT)
GPIO.setup(PIN_CLK, GPIO.OUT)



# Main Program
# Note -- this program is largely intended to test the framerate of the imager tile. 
# Uncomment the print statements to show the imager tile data in the console. 

print("Initializing...")
numFrames = 100

# Keep track of time (to calculate framerate)
startTime = time.time()

# Read numFrames frames from the imager tile.
for frame in range(0, numFrames):
	print("Frame: " + str(frame))
	frame = readTileFrame()
	displayFrame(frame)
	

# Calculate framerate	
endTime = time.time()
print("Total runtime: " + str(endTime - startTime))
framerate = 1 / ((endTime - startTime) / numFrames)
print("Framerate: " + str(framerate) + " frames per second")

# Finish
print("Complete...")
GPIO.cleanup()
