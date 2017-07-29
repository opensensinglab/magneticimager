# This is largely a port of the Arduino code to Python for the Raspberry Pi 3, to test the framerate. 
# This was able to achieve about 30fps after setting the I2C bus speed to 800KHz (see attached setI2CBaudRate script)

from __future__ import print_function
from Adafruit_MCP230xx import *
import RPi.GPIO as GPIO
import time


# Use busnum = 1 for new Raspberry Pi's (512MB with mounting holes)
mcp = Adafruit_MCP230XX(busnum = 1, address = 0x20, num_gpios = 16)
 

#
# Bit helper/utility functions
#
def bitSet(val, bitNum):
	return val | (1<<bitNum)

def bitClear(val, bitNum):
	return val & ~(1<<bitNum)
	 
 
#
# I/O Expander
# 
def setupIOExpander():
	print(" * setupIOExpander()...")
	# Set pins 0, 1 and 2 to output (you can set pins 0..15 this way)
	for i in range(0, 16):
		mcp.config(i, mcp.OUTPUT)
		mcp.output(i, 0)	# Initialize low


def setCS(multiplexer, channel):
	# Begin with all values inactive
	outA = 0xFF
	outB = 0xFF
	
	# Set local group (1-16)
	if (channel & 0b00000001):
		outB = bitSet(outB, 3)
	else:
		outB = bitClear(outB, 3)
		
	if (channel & 0b00000010):
		outB = bitSet(outB, 2)
	else:
		outB = bitClear(outB, 2)

	if (channel & 0b00000100):
		outB = bitSet(outB, 1)
	else:
		outB = bitClear(outB, 1)

	if (channel & 0b00001000):
		outB = bitSet(outB, 0)
	else:
		outB = bitClear(outB, 0)
		
	
	# Set analog multiplexer number (1-9)
	if (multiplexer == 1): outB = bitClear(outB, 5)
	if (multiplexer == 2): outA = bitClear(outA, 0)
	if (multiplexer == 3): outA = bitClear(outA, 5)
	
	if (multiplexer == 4): outB = bitClear(outB, 6)
	if (multiplexer == 5): outA = bitClear(outA, 3)
	if (multiplexer == 6): outA = bitClear(outA, 6)
	
	if (multiplexer == 7): outB = bitClear(outB, 7)
	if (multiplexer == 8): outA = bitClear(outA, 4)
	if (multiplexer == 9): outA = bitClear(outA, 7)
	
	
	# Sent as 16-bit write to I/O expander
	ports = (outB << 8) + outA
	mcp.write16(ports)
	

def selectChannel(x, y):
	multiplexer = 0
	channel = 0
	
	# Select analog multiplexer
	if (x<=3) and (y<=3):
		multiplexer = 1
	elif (x<=7) and (y<=3):
		multiplexer = 2
	elif (x<=12) and (y<=3):
		multiplexer = 3
	elif (x<=3) and (y<=7):
		multiplexer = 4
	elif (x<=7) and (y<=7):
		multiplexer = 5
	elif (x<=12) and (y<=7):
		multiplexer = 6
	elif (x<=3) and (y<=12):
		multiplexer = 7
	elif (x<=7) and (y<=12):
		multiplexer = 8
	elif (x<=12) and (y<=12):
		multiplexer = 9

		
	# Select channel
	x0 = x % 4
	y0 = y % 4
	if (x0 == 0) and (y0 == 0):
		channel = 9
	elif (x0 == 1) and (y0 == 0):
		channel = 11
	elif (x0 == 2) and (y0 == 0):
		channel = 13
	elif (x0 == 3) and (y0 == 0):
		channel = 15
	elif (x0 == 0) and (y0 == 1):
		channel = 8
	elif (x0 == 1) and (y0 == 1):
		channel = 10
	elif (x0 == 2) and (y0 == 1):
		channel = 12
	elif (x0 == 3) and (y0 == 1):
		channel = 14
	elif (x0 == 0) and (y0 == 2):
		channel = 6
	elif (x0 == 1) and (y0 == 2):
		channel = 4
	elif (x0 == 2) and (y0 == 2):
		channel = 2
	elif (x0 == 3) and (y0 == 2):
		channel = 0
	elif (x0 == 0) and (y0 == 3):
		channel = 7
	elif (x0 == 1) and (y0 == 3):
		channel = 5
	elif (x0 == 2) and (y0 == 3):
		channel = 3
	elif (x0 == 3) and (y0 == 3):
		channel = 1
		
		
	# Set IO expander
	setCS(multiplexer, channel)


#
# Analog to digital converter
#

# Pin definitions
AD7940_SPI_MISO		= 23
AD7940_SPI_CS		= 25
AD7940_SPI_CLK		= 18

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


# Setup pins
GPIO.setmode(GPIO.BCM)

GPIO.setup(AD7940_SPI_MISO, GPIO.IN)
GPIO.setup(AD7940_SPI_CLK, GPIO.OUT)
GPIO.setup(AD7940_SPI_CS, GPIO.OUT)



# Main Program
# Note -- this program is largely intended to test the framerate of the imager tile. 
# Uncomment the print statements to show the imager tile data in the console. 

print("Initializing...")
setupIOExpander()
numFrames = 10

# Keep track of time (to calculate framerate)
startTime = time.time()

# Read numFrames frames from the imager tile.
for frame in range(0, numFrames):
	#print("Frame: " + str(frame))
	
	for x in range(0, 12):
		for y in range(0, 12):
			selectChannel(x, y)
			value = readAD7940()
			#print(str(value) + " ", end="")
		#print("")
	
	#print("")

# Calculate framerate	
endTime = time.time()
print("Total runtime: " + str(endTime - startTime))
framerate = 1 / ((endTime - startTime) / numFrames)
print("Framerate: " + str(framerate) + " frames per second")

# Finish
print("Complete...")
