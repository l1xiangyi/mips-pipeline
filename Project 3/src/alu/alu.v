// For the overflow flag, you should only consider add, addi, and sub instruction. 
// For the zero flag, you should only consider beq and bne instruction. 
// For the negative flag, you only need to deal with slt, slti, sltiu, sltu instruction. 

// For example, at any time, when you execute addu instruction, the overflow flag will remain zero. 
// And for subu instruction, even the result is less than 0, the negative flag will remain zero.

// instruction: 32-bit instruction
// regA/B: 32-bit data in registerA(addr=00000), registerB(addr=00001)
// result: 32-bit result of Alu execution
// flags: 3-bit alu flag
// flags[2] : zero flag
// flags[1] : negative flag
// flags[0] : overflow flag 

// - add, addi, addu, addiu
// - sub, subu
// - and, andi, nor, or, ori, xor, xori
// - beq, bne, slt, slti, sltiu, sltu
// - lw, sw
// - sll, sllv, srl, srlv, sra, srav

module alu(
    input[31:0] instruction, 
    input[31:0] regA, 
    input[31:0] regB, 
    output[31:0] result, 
    output[2:0] flags);

// Step 1: You should parsing the instruction;

    wire[5:0] opcode;
    wire[5:0] funct;
    wire[15:0] imm;
    wire[31:0] imm_ext;
    reg[31:0] alu_result;
    reg[2:0] alu_flags;
    wire[31:0] shamt;
    
    reg[31:0] result_reg;
    reg[2:0] flags_reg;

    assign opcode = instruction[31:26];
    assign funct = instruction[5:0];
    assign imm = instruction[15:0];
    assign imm_ext = { {16{imm[15]}} , imm };
    assign shamt = instruction[10:6];

    always @(opcode or funct or regA or regB or imm_ext or shamt) begin
    case(opcode)
        6'b001000: 
            begin // addi
                alu_result = regA + imm_ext;
                if (~regA[31] & imm_ext[31] & alu_result[31] | regA[31] & ~imm_ext[31] & ~alu_result[31])
                    flags_reg[2] = 1'b1;
            end
        6'b001001: alu_result = regA + imm_ext; // addiu
        6'b001100: alu_result = regA & imm_ext; // andi
        6'b001101: alu_result = regA | imm_ext; // ori
        6'b001110: alu_result = regA ^ imm_ext; // xori
        6'b100011: alu_result = regA + imm_ext; // lw
        6'b101011: alu_result = regA + imm_ext; // sw
        6'b000100: alu_result = regA - regB;    // beq
        6'b000101: alu_result = regA - regB;    // bne
        6'b001010: alu_result = regA < regB ? 32'h00000001 : 32'h00000000; // slti
        6'b001011: alu_result = regA < imm_ext ? 32'h00000001 : 32'h00000000; // sltiu
        default: begin
            case(funct)
                6'b100000: alu_result = regA + regB; // add
                6'b100001: alu_result = regA + regB; // addu
                6'b100010: alu_result = regA - regB; // sub
                6'b100011: alu_result = regA - regB; // subu
                6'b100100: alu_result = regA & regB; // and
                6'b100111: alu_result = ~(regA | regB); // nor
                6'b100101: alu_result = regA | regB; // or
                6'b100110: alu_result = regA ^ regB; // xor
                6'b101010: alu_result = regA < regB ? 32'h00000001 : 32'h00000000; // slt
                    6'b101001: alu_result = regA < regB ? 32'h00000001 : 32'h00000000; // sltu
                    6'b000000: begin
                        case(shamt)
                            5'b00000: alu_result = regA << shamt; // sll
                            5'b00001: alu_result = regA << shamt; // sllv
                            5'b00010: alu_result = regA >> shamt; // srl
                            5'b00011: alu_result = regA >> shamt; // srlv
                            5'b00100: alu_result = $signed(regA) >>> shamt; // sra
                            5'b00101: alu_result = $signed(regA) >>> shamt; // srav
                            default: alu_result = 32'h00000000;
                        endcase
                    end
                    default: alu_result = 32'h00000000;
                endcase
            end
        endcase

        alu_flags = (alu_result == 0) ? 3'b001 : (alu_result[31]) ? 3'b100 : 3'b000;
    end

    always @(alu_result or alu_flags) begin
        result_reg <= alu_result;
        flags_reg <= alu_flags;
    end

    assign result = result_reg;
    assign flags = flags_reg;
    
// Step 2: You may fetch values in mem;
// Step 3: You should output the correct value of result 
//         and correct status offlags


endmodule