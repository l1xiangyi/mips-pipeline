`timescale 100ps/100ps


module alu(
    input [2:0] alu_control,
    input signed [31:0] a, b,
    output [31:0] result,
    output zero);

    wire [31:0] add_result, sub_result, and_result, nand_result, or_result, xor_result, less_result;

    // Perform arithmetic and logic operations
    assign add_result = a + b;
    assign sub_result = a - b;
    assign and_result = a & b;
    assign nand_result = ~(a | b);
    assign or_result = a | b;
    assign xor_result = a ^ b;
    assign less_result = a < b;

    // Control signals for operation selection
    wire isAdd = (alu_control == 3'd0);
    wire isSub = (alu_control == 3'd1);
    wire isAnd = (alu_control == 3'd2);
    wire isNand = (alu_control == 3'd3);
    wire isOr = (alu_control == 3'd4);
    wire isXor = (alu_control == 3'd5);
    wire isLess = (alu_control == 3'd6);

    // Select the appropriate operation result based on control signals
    assign result = {32{isAdd | isSub}} & (isAdd ? add_result : sub_result)
                  | {32{isAnd}} & and_result
                  | {32{isNand}} & nand_result
                  | {32{isOr}} & or_result
                  | {32{isXor}} & xor_result
                  | {32{isLess}} & less_result;

    // Set the zero if the result is 0
    assign zero = (0 == result);

endmodule
