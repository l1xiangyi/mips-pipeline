// instruction: 32-bit instruction
// regA/B: 32-bit data in registerA(addr=00000), registerB(addr=00001)
// result: 32-bit result of Alu execution
// flags: 3-bit alu flag
// flags[2] : zero flag
// flags[1] : negative flag
// flags[0] : overflow flag 
module alu(input[31:0] instruction, input[31:0] regA, input[31:0] regB, output[31:0] result, output[2:0] flags);
