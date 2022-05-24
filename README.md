# sin_lut
This is a simple, parameterized sine lookup table, which should work for pretty much any FPGA architecture. I've tested it on Lattice MachXO2 and Microchip PolarFire. The attributes in the code are for Synplify Pro, which supports both architetures. It is a full period, not 1/4 period, so if you are constrained for BRAM space, consider modifying it to be tricky.

## Generic Parameters
`DEPTH`: How many steps are in the table, which is to say, how fine do you want to slice your circle

`WIDTH`: The size of the samples

## Ports
`clk`:   this is your logic clock. The table output is registered.

`angle`: this is the index into the table, constrained to be in the range 0 to `DEPTH` - 1

`sine`:  this is the table output, a signed value ranging from -2<sup>(`WIDTH`-1)</sup> to 2<sup>(`WIDTH`-1)</sup> - 1


## Usage
Just instantiate in your design in the usual way. 
The report statement in the initializer function prints out each table entry as the table is created. Synthesis ignores this, of course, and if you prefer you can either just delete it or come up with a clever way to enable/disable it with a generic control.
