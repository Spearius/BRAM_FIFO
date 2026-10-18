\# BRAM FIFO



\## Overview

This design implements a First-In-First-Out (FIFO) memory container using System Verilog HDL and Block RAM (BRAM) in Vivado. The FIFO implementation will write (input) incoming data and read (output) it in the same order it was written.



\## Software

* Vivado 2023.1
* System Verilog HDL



\## Functionality

The parameters for this FIFO will be as follows:



* WIDTH = 16 			Bit width per word stored
* DEPTH = 32			Maximum amount of memory address locations
* ALMOST\_EMPTY\_THRESHOLD = 1	Threshold to notify when FIFO is almost empty
* ALMOST\_FULL\_THRESHOLD = 31	Threshold to notify when FIFO is almost full
* READ LATENCY = 1		Register Delay stages for the output



The way this FIFO program works is by using the FPGA's internal memory known as Block RAM to store incoming data. A write pointer will determine the address location where the incoming data gets stored. Then, a read pointer will determine the memory address location from where the data is retrieved. While this process occurs, there will be a data count to track the number of data stored in the FIFO container. Based on this data counter, there will be status flags that will triggers to indicate when the FIFO is almost empty, empty, almost full, or full. The write pointer, read pointer, and data counter will update on the rising edge of the clock cycle.



Additionally, there is a Python-generated script that will write 32 data values. The data in this script is also 16-bit values stored in hexadecimal format. This will be shown in the testbench, where one of the test cases load these values using the $readmemh function to verify all values can be written and read through the FIFO.



\## Testbench

The functionality was verified using a testbench with the following ten test cases:



1.) Reset - clears the FIFO count and output registers.

2.) Data Patterns - Writes and reads 0000, FFFF, AAAA, and 5555 to verify correct data storage and FIFO ordering.

3.) Fill All Memory Locations - writes 32 values to fill the FIFO and checks the full and almost full threshold flags.

4.) Overflow - Writes "DEAD" while the FIFO is full.

5.) Full FIFO Readback - Reads all stored values and verifies the order.

6.) Underflow - Attempts to read an empty FIFO and verifies that the request is rejected.

7.) Simultaneous Read/ Write - verifies simultaneous read and write operations when the FIFO contains data.

8.) Simultaneous Read/ Write while empty - verifies simultaneous read and write when the FIFO is empty.

9.) Simultaneous Read/ Write while full - verifies simultaneous read and write when the FIFO is full.

10.) Python-generated Data - tests the 32 8-bit data values generated through the Python script if it is written and read back in the correct order.



Below are the Behavioral Simulation waveforms:







\## Block Diagram





