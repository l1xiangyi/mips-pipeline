`timescale 100ps/100ps

`ifndef alu
`define alu

module alu(
    input [2:0] alu_control,
    input signed [31:0] a, b,
    output reg [31:0] result,
    output zero);

    assign zero = (0 == result);

    always @(*) begin
        case (alu_control)
            3'd0 : 
            begin
                result = a + b;
            end
            3'd1 : 
            begin
                result = a - b;
            end
            3'd2 : 
            begin
                result = a & b;
            end
            3'd3 : 
            begin
                result = ~(a | b);
            end
            3'd4 : 
            begin
                result = a | b;
            end
            3'd5 :
            begin
                result = a ^ b;
            end
            3'd6 : 
            begin
                result = a < b;
            end
            default : result = 0;
        endcase
    end
endmodule


`endif