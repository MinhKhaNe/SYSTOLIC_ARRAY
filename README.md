# SAURIA_CORE
RTL code of SAURIA Core and testbench to test each module

1.	Adder
  a. Adder Gear (Generic Error-tolerant Adder): 
    -Divide into many Sub-Adder then add them together to create the Result.
    -Low blocks: no carry propagation.
    -High blocks: exact addition.
    -The partial results are combined to create final sum.

  b. Adder Gear 2c:
    -Gear Adder version used for signed two’s complement numbers.

  c. Adder Ideal:
    -Ideal adder, using standard Adding Operands (+) to compare.

  d. Adder Loa (Lower Part OR Adder):
    -Adder is split into low and high bit.
    -Only using Add function for high bit, using OR function for low bit.

  e. Adder Trua (Truncated Adder):
    -Ignore carry from low bits, only add number from high bits.

  f. Adder Truah (Truncated Adder – High Accuracy):
    -Carry from low bits is estimated, guess the carry.

  g. Adder Generic:
    -Control different adders by using ADD_TYPE to compare the result of different adders.

2.	Multiplier
  a. Bam_cell (Bit-level AND Multiplier):
    -And bit then sum with the previous result and carry.
  	
  b. Multiplier Bam_cell:
    -

  c.	
  
3.	PE

4.	Systolic array
