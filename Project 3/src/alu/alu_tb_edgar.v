`include "alu.v"
`timescale 1ns/1ps

module alu_test;

reg[31:0] instruction,regA,regB;
wire[31:0] result;
wire[2:0] flags;

alu testalu(instruction, regA, regB, result, flags);

task test_bench;
    input[31:0] instruction_t;
    input[31:0] regA_t, regB_t;
    input[31:0] result_t;
    input[2:0] flags_t;
    begin
        instruction = instruction_t;
        regA = regA_t;
        regB = regB_t;
        #10
        $write("instruction:%b; regA:%h regB:%h opcode:%h funct:%h; result:%h flags:%b;\tInfo: ",instruction_t,regA_t,regB_t,testalu.opcode,testalu.funct,result,flags);
        if(result === result_t && flags === flags_t)
            $display("PASS");
        else
            $display("WRONG");       
    end
endtask

initial begin

#10 $display("add");
#10 test_bench(32'b000000_00001_00000_00000_00000_100000,-2,2,8'b00000000,3'b100); // -2+2=0
#10 test_bench(32'b000000_00001_00000_00000_00000_100000,32'h80000001,32'h80000001,32'h00000002,3'b001); //10...01+10...01=0...10 overflow
#10 test_bench(32'b000000_00001_00000_00000_00000_100000,32'h7ffffffe,32'h00000002,32'h80000000,3'b001); // 01...10+0...010=10...0 overflow

#10 $display("\naddi");
#10 test_bench(32'b001000_00000_00001_1111111111111110,3,32'bx,1,3'b000);//-2+3=1
#10 test_bench(32'b001000_00000_00001_1000000000000000,32'h80000000,32'bx,32'h7fff8000,3'b001);//10...0+1...10...0=01...10...0 overflow
#10 test_bench(32'b001000_00000_00001_0000000000000010,32'h7ffffffe,32'bx,32'h80000000,3'b001); //01...10+0...010=10...0 overflow 
#10 test_bench(32'b001000_00000_00001_0000000000000010,-3,32'bx,-1,3'b000);

#10 $display("\naddu");
#10 test_bench(32'b000000_00001_00000_00000_00000_100001,-2,2,0,3'b100);
#10 test_bench(32'b000000_00001_00000_00000_00000_100001,-2147483647,-2147483647,2,3'b000);
#10 test_bench(32'b000000_00001_00000_00000_00000_100001,2147483647,1,32'h80000000,3'b000);
#10 test_bench(32'b000000_00001_00000_00000_00000_100001,7,8,15,3'b000);

#10 $display("\naddiu");
#10 test_bench(32'b001001_00000_00001_0000000000000111,8,32'bx,15,3'b000);
#10 test_bench(32'b001001_00000_00001_1000000000000000,32'h80000000,32'bx,32'h7fff8000,3'b000);


// #10 $display("\nsub");
// #10 test_bench(32'b000000_00001_00000_00000_00000_100010,-2,2,4,3'b000);
// #10 test_bench(32'b000000_00000_00001_00000_00000_100010,-2147483647,2,32'h7fffffff,3'b001);
// #10 test_bench(32'b000000_00000_00001_00000_00000_100010,32'h7fffffff,-1,32'h80000000,3'b001);




#10 $finish;

end

endmodule