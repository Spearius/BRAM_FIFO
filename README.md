# BRAM FIFO

## Software Tools & Languages Used
- Vivado 2023.1
  - SystemVerilog Hardware Description Language (HDL)
- Python 3 IDE
  - Python Programming Language


## Overview
This design implements a First-In-First-Out (FIFO) memory container using SystemVerilog HDL and Block RAM (BRAM) in Vivado. The FIFO writes incoming data into memory and reads it in the same order it was written. Additionally, the program was created using a Tool Command Language (TCL) script which auto populated the project files with its design source and simulation source files.

## Functionality
The parameters for this FIFO are as follows:

- `WIDTH = 16`: Bit width per stored word.
- `DEPTH = 32`: Maximum number of memory locations.
- `ALMOST_EMPTY_THRESHOLD = 1`: Threshold indicating when the FIFO is almost empty.
- `ALMOST_FULL_THRESHOLD = 31`: Threshold indicating when the FIFO is almost full.
- `READ_LATENCY = 1`: Number of registered output pipeline stages.

The FIFO uses the FPGA's internal memory, known as Block RAM (BRAM), to store incoming data. A write pointer determines the memory address where incoming data is stored, while a read pointer determines the memory address from which data is retrieved. A data counter tracks the number of words stored in the FIFO. Based on this counter, status flags indicate whether the FIFO is almost empty, empty, almost full, or full. The write pointer, read pointer, and data counter update on the rising edge of the clock.

Additionally, another Python TCL script generates 32 data values. These are 16-bit values stored in hexadecimal format. The testbench loads the values using the `$readmemh` function to verify that all values can be written into and read from the FIFO in the correct order.


## Testbench
The functionality was verified using a testbench with the following ten test cases:

1\. `Reset`: Clears the FIFO count and output registers.  
2\. `Data Patterns`: Writes and reads `0000`, `FFFF`, `AAAA`, and `5555` to verify correct data storage and FIFO ordering.  
3\. `Fill All Memory Locations`: Writes 32 values to fill the FIFO and checks the full and almost-full flags.  
4\. `Overflow`: Attempts to write `DEAD` while the FIFO is full and verifies that the write is rejected.  
5\. `Full FIFO Readback`: Reads all stored values and verifies their order.  
6\. `Underflow`: Attempts to read an empty FIFO and verifies that the request is rejected.  
7\. `Simultaneous Read/Write`: Verifies simultaneous read and write operations when the FIFO contains data.  
8\. `Simultaneous Read/Write While Empty`: Verifies simultaneous read and write operations when the FIFO is empty.  
9\. `Simultaneous Read/Write While Full`: Verifies simultaneous read and write operations when the FIFO is full.  
10\. `Python-Generated Data`: Verifies that the 32 Python-generated 16-bit values are written and read back in the correct order.  

### Behavioral Simulation Waveforms
Below is the behavioral simulation waveform with the testbench values:

<p align="center">
  <img src="Images/BRAM_FIFO_Waveform.png" width="48%">
  <img src="Images/BRAM_FIFO_Waveform2.png" width="48%">
</p>

The two waveforms above shows the following:
1.\ When 'srst' is asserted, all other signals are low except for 'empty'. This shows that reset is clearing all signals and the empty flag is triggered. Also, 'data_out' is reset to zero.
2.\ The FIFO is storing and receiving the correct data patterns ('0000', 'FFFF', 'AAAA', and '5555') in that intended order and the 'data_count' signal is incrementing to show the amount of data currently stored in the FIFO.
3.\ From '0000' to '001F', we can see that the FIFO is also storing all 32 data values, filling up the entire FIFO container. Before full, the 'almost_full' signal is asserted followed by the 'full' signal.
4.\ When the FIFO is full, there is a 'DEAD' data value outputted when more than 32 values are inputted. This 'DEAD' value appears when there is an overflow.
5.\ All 32 stored values are retrieved in order, then when the 'read_enable' signal is asserted, 'data_count' decreases as 'data_out' returns the values. Once all data values are read from the FIFO, the 'empty' signal is then asserted.  

Below is the behavioral simulation waveform with the Python-generated Script values:

<p align="center">
  <img src="Images/BRAM_FIFO_Waveform_PythonGeneratedData.png" width="48%">
  <img src="Images/BRAM_FIFO_Waveform_PythonGeneratedData2.png" width="48%">
  <img src="Images/BRAM_FIFO_Waveform_PythonGeneratedData3.png" width="48%">
</p>

6.\ 


## Block Diagram
Below is the RTL schematic of the BRAM FIFO which was coded versus generated through the IP Catalog:

![RTL Schematic BRAM-FIFO Block Diagram](Images/RTL_FIFO_BlockDiagram.png)

Below is the IP Block Diagram of the BRAM FIFO:

![IP Generated BRAM-FIFO Block Diagram](Images/IP_FIFO_BlockDiagram.png)

- To create this IP Generated Block Diagram, Vivado needed a `.v` file versus a `.sv` file. So, `fifo_wrapper.v` was created as a top module to instantiate `sc_fifo.sv` inside. Then, when selecting to create a block diagram, I added `fifo_wrapper.v` to infer the IP Generated Block Diagram.
