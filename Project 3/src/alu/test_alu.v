`include "alu.v"
`timescale 1ns/1ps

module alu_test;

reg[31:0] instruction,regA,regB;
wire[31:0] result;
wire[2:0] flags;

alu testalu(instruction, regA, regB, result, flags);

task test_bench;
    input string operation;
    input[31:0] instruction_t;
    input[31:0] regA_t, regB_t;
    input[31:0] result_t;
    input[2:0] flags_t;
    instruction = instruction_t;
    regA = regA_t;
    regB = regB_t;
    #10
    $write("%s, %b, %h, %h, %h, %h, %h, %b, ", operation, instruction_t, regA_t, regB_t, testalu.opcode, testalu.funct, result, flags);
    if(result === result_t && flags === flags_t)
        $display("PASS");
    else
        $display("WRONG");
endtask

initial begin
    string operations[] = {"add", "addi", "addu", "addiu", "sub", "subu", "and", "andi", "nor", "ori", "xor", "xori", "beq", "bne", "slt", "slti", "sltiu", "sltu", "lw", "sw", "sll", "sllv", "srl", "srlv", "sra", "srav"};

    // Add test_bench statements here
    test_bench(operations[0], 32'b000000_00001_00010_00011_00000_100000, 3, 2, 5, 3'b000); // add
    test_bench(operations[1], 32'b001000_00001_00011_1111111111111110, 3, 0, 1, 3'b000); // addi
    test_bench(operations[2], 32'b000000_00001_00010_00011_00000_100001, 3, 2, 5, 3'b000); // addu
    test_bench(operations[3], 32'b001001_00001_00011_1111111111111110, 3, 0, 1, 3'b000); // addiu
    test_bench(operations[4], 32'b000000_00001_00010_00011_00000_100010, 3, 2, 1, 3'b000); // sub
    test_bench(operations[5], 32'b000000_00001_00010_00011_00000_100011, 3, 2, 1, 3'b000); // subu
    test_bench(operations[6], 32'b000000_00001_00010_00011_00000_100100, 5, 3, 1, 3'b000); // and
    test_bench(operations[7], 32'b001100_00001_00011_0000000000000011, 5, 0, 1, 3'b000); // andi
    test_bench(operations[8], 32'b000000_00001_00010_00011_00000_100111, 5, 3, 4294967288, 3'b000); // nor
    test_bench(operations[9], 32'b001101_00001_00011_0000000000000011, 5, 0, 7, 3'b000); // ori
    test_bench(operations[10], 32'b000000_00001_00010_00011_00000_100110, 5, 3, 6, 3'b000); // xor
    test_bench(operations[11], 32'b001110_00001_00011_0000000000000011, 5, 0, 6, 3'b000); // xori
    test_bench(operations[12], 32'b000100_00001_00000_1000000000100000,2,2,32'b0,3'b100); // beq
    test_bench(operations[13], 32'b000101_00001_00000_1000000000100000,2,2,32'b0,3'b100); // bne
    test_bench(operations[14], 32'b001010_00000_00001_1000000000000001,2,2,0,3'b100); // slt
    test_bench(operations[15], 32'b001010_00000_00001_1000000000000001,2,2,0,3'b100); // slti
    test_bench(operations[16], 32'b001011_00000_00001_1111111111111111,3,3,1,3'b000); // sltiu
    test_bench(operations[17], 32'b000000_00001_00000_00000_00000_101011,-1,-3,0,3'b100); // sltu
    test_bench(operations[18], 32'b100011_00001_00000_1111111111111111,32'bx,-3,-4,3'b000); // lw
    test_bench(operations[19], 32'b101011_00001_00000_1111111111111111,32'bx,-3,-4,3'b000); // sw
    test_bench(operations[20], 32'b000000_00001_00000_00000_00010_000000,1,1,4,3'b000); // sll
    test_bench(operations[21], 32'b000000_00000_00001_00000_00000_000100,4,1,16,3'b000); // sllv
    test_bench(operations[22], 32'b000000_00000_00001_00000_00010_000010,32'bx,8,2,3'b000); // srl
    test_bench(operations[23], 32'b000000_00000_00001_00000_00000_000110,2,8,2,3'b000); // srlv
    test_bench(operations[24], 32'b000000_00000_00001_00000_00010_000011,32'bx,8,2,3'b000); // sra
    test_bench(operations[25], 32'b000000_00000_00001_00000_00000_000111,4,32'hf,0,3'b100); // srav

    $finish;
end

endmodule
