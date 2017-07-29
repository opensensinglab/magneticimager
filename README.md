Magnetic Imaging Tile
======

Work-in-progress.  Please use at your own risk. <br>

This is a board intended to function as a "magnetic field camera", and visualize magnetic fields.  In it's current form, it consists of an array of 12x12 hall effect sensors (144 total) that sense magnetic fields, arrayed in a 4mm grid.  Each sensor is connected to an array of analog switches, that allow an individual sensor to be addressed.  Read out is accomplished one magnetic "pixel" at a time, selecting a given hall sensor from the array, reading it's value (either using the internal ADC, or an external ADC), and repeating this process until the entire array has been read out.  

The current array is designed to be tile-able, with up to four of the boards (24x24 magnetic field sensors) arrayed together. 

The Arduino firmware has a framerate of approximately 10 frames per second, when the image data is streamed over the serial port and displayed using the Processing visualization.  The Raspberry Pi Python example achieves approximately 30fps.  The array itself is likely capable of much higher speeds, but one of the major limiting factors is currently the speed of the I2C I/O multiplexer (used to select which magnetometer to read from). 


# Open Source

This project is open source software and hardware, and is released under various open licenses.

# Disclaimer

**DISCLAIMER OF WARRANTIES AND LIMITATION OF LIABILITY.**

UNLESS OTHERWISE SEPARATELY UNDERTAKEN BY THE LICENSOR, TO THE EXTENT POSSIBLE, THE LICENSOR OFFERS THE LICENSED MATERIAL AS-IS AND AS-AVAILABLE, AND MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND CONCERNING THE LICENSED MATERIAL, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHER. THIS INCLUDES, WITHOUT LIMITATION, WARRANTIES OF TITLE, MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, ABSENCE OF LATENT OR OTHER DEFECTS, ACCURACY, OR THE PRESENCE OR ABSENCE OF ERRORS, WHETHER OR NOT KNOWN OR DISCOVERABLE. WHERE DISCLAIMERS OF WARRANTIES ARE NOT ALLOWED IN FULL OR IN PART, THIS DISCLAIMER MAY NOT APPLY TO YOU.

TO THE EXTENT POSSIBLE, IN NO EVENT WILL THE LICENSOR BE LIABLE TO YOU ON ANY LEGAL THEORY (INCLUDING, WITHOUT LIMITATION, NEGLIGENCE) OR OTHERWISE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL, CONSEQUENTIAL, PUNITIVE, EXEMPLARY, OR OTHER LOSSES, COSTS, EXPENSES, OR DAMAGES ARISING OUT OF THIS PUBLIC LICENSE OR USE OF THE LICENSED MATERIAL, EVEN IF THE LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH LOSSES, COSTS, EXPENSES, OR DAMAGES. WHERE A LIMITATION OF LIABILITY IS NOT ALLOWED IN FULL OR IN PART, THIS LIMITATION MAY NOT APPLY TO YOU.

THE DISCLAIMER OF WARRANTIES AND LIMITATION OF LIABILITY PROVIDED ABOVE SHALL BE INTERPRETED IN A MANNER THAT, TO THE EXTENT POSSIBLE, MOST CLOSELY APPROXIMATES AN ABSOLUTE DISCLAIMER AND WAIVER OF ALL LIABILITY.

