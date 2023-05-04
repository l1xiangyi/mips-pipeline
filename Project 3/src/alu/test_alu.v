`include "./alu.v"
`timescale 1ns / 1ps

module alu_tb();

reg [31:0] instruction_tb;
reg [31:0] regA_tb;
reg [31:0] regB_tb;
wire [31:0] result_tb;
wire [2:0] flags_tb;

alu uut (
    .instruction(instruction_tb),
    .regA(regA_tb),
    .regB(regB_tb),
    .result(result_tb),
    .flags(flags_tb)
);

initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, alu_tb);
    
    // Test cases
    regA_tb = 32'h0000000A;
    regB_tb = 32'h00000005;
    
    // Test ADD
    instruction_tb = 32'h00051020; // add $t0, $t0, $t1
    #10;
    
    // Test ADDI
    instruction_tb = 32'h2108000B; // addi $t0, $t0, 11
    #10;
    
    // Test ADDU
    instruction_tb = 32'h00051021; // addu $t0, $t0, $t1
    #10;

    // Test ADDIU
    instruction_tb = 32'h2508000C; // addiu $t0, $t0, 12
    #10;
    
    // Test SUB
    instruction_tb = 32'h00051022; // sub $t0, $t0, $t1
    #10;
    
    // Test SUBU
    instruction_tb = 32'h00051023; // subu $t0, $t0, $t1
    #10;
    
    // ... Add more test cases for other instructions

    $finish;
end

endmodule
