# ATMEGA328-7Segment-Display-Assembly

Atmega 328 assembly for reading ADC value, extracting the character at each digit point and displaying the reading on a seven segment display.

Comparison is also done when the read character exceeds 1/2 the process value a motor is turned on and status LEDs change state.
-- The process is simulated using a pot at ADC0.

The program is built using atmel studio 7 and run on proteus.

The proteus file is provided, just import the hex file from debug file after build and run the sim. 