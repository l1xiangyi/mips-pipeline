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
    

    reg[31:0] alu_result;
    reg[2:0] alu_flags;
    
    reg[31:0] result_reg;
    reg[2:0] flags_reg;

    // Step 1: You should parsing the instruction;
    reg[5:0] opcode;
    reg[5:0] funct;
    reg[31:0] shamt;
    reg[15:0] imm;
    reg[31:0] imm_ext;
    reg[4:0] rs;
    reg[4:0] rt;

    reg[31:0] reg0;

    always @(opcode or funct or regA or regB or imm_ext or shamt) begin
        flags_reg = 3'b000;
        opcode = instruction[31:26];
        funct = instruction[5:0];
        imm = instruction[15:0];
        imm_ext = { {16{imm[15]}} , imm };
        shamt = instruction[10:6];

        case(opcode)
            6'b001000: begin // addi
                    alu_result = regA + imm_ext;
                    if ((regA[31] == imm_ext[31]) && (alu_result[31] != regA[31]))
                        flags_reg[0] = 1'b1;
                end
            6'b001001: alu_result = regA + imm_ext; // addiu
            6'b001100: alu_result = regA & imm_ext; // andi
            6'b001101: alu_result = regA | imm_ext; // ori
            6'b001110: alu_result = regA ^ imm_ext; // xori
            6'b100011: begin // alu_result = regA + imm_ext; // lw
                reg0 = $signed(instruction[15:0]);
                if(instruction[25:21] == 5'b00000)
                    alu_result = $signed(regA) + $signed(reg0);
                if(instruction[25:21] == 5'b00001)
                    alu_result = $signed(regB) + $signed(reg0);
            end
            6'b101011: begin // alu_result = regA + imm_ext; // sw
                reg0 = $signed(instruction[15:0]);
                if(instruction[25:21] == 5'b00000)
                    alu_result = $signed(regA) + $signed(reg0);
                if(instruction[25:21] == 5'b00001)
                    alu_result = $signed(regB) + $signed(reg0);
            end
            6'b000100: begin // beq
                    alu_result = regA - regB;
                    if (alu_result == 32'h00000000)
                        flags_reg[2] = 1'b1;
                end
            6'b000101: begin // bne
                    alu_result = regA - regB;
                    if (alu_result != 32'h00000000)
                        flags_reg[2] = 1'b1;
                end
            6'b001010: begin // slti
                alu_result = $signed(regA) < $signed(imm_ext) ? 32'h00000001 : 32'h00000000;
                // alu_result = regA;
                if (alu_result[31])
                    flags_reg[1] = 1'b1;
            end
            6'b001011: begin // sltiu
                alu_result = regA < imm_ext ? 32'h00000001 : 32'h00000000;
                if (alu_result[31])
                    flags_reg[1] = 1'b1;
            end
            default: begin
                case(funct)
                    6'b100000: begin // add
                            alu_result = regA + regB;
                            if (!regA[31] && !regB[31] && alu_result[31] || regA[31] && regB[31] && !alu_result[31])
                                flags_reg[0] = 1'b1;
                        end
                    6'b100001: alu_result = regA + regB; // addu
                    6'b100010: begin // sub
                            alu_result = regA - regB;
                            if (regA[31] & ~regB[31] & ~alu_result[31] | ~regA[31] & regB[31] & alu_result[31])
                                flags_reg[0] = 1'b1;
                        end
                    6'b100011: alu_result = regA - regB; // subu
                    6'b100100: alu_result = regA & regB; // and
                    6'b100111: alu_result = ~(regA | regB); // nor
                    6'b100101: alu_result = regA | regB; // or
                    6'b100110: alu_result = regA ^ regB; // xor
                    6'b101010: begin // slt
                            alu_result = regA < regB ? 32'h00000001 : 32'h00000000;
                            if (alu_result[31])
                                flags_reg[1] = 1'b1;
                        end

                    6'b101011: begin // sltu
                        alu_result = regA < regB ? 32'h00000001 : 32'h00000000;
                        if (alu_result[31])
                            flags_reg[1] = 1'b1;
                    end
                    6'b000000: begin // sll
                        reg0 = instruction[10:6];
                        if (instruction[20:16] == 5'b00000)
                            alu_result = regA << reg0;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = regB << reg0;
                    end
                    6'b000100: begin // sllv
                        if (instruction[20:16] == 5'b00000)
                            alu_result = regA << regB;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = regB << regA;
                    end
                    6'b000110: begin // srlv
                        if (instruction[20:16] == 5'b00000)
                            alu_result = regA >> regB;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = regB >> regA;
                    end

                    6'b000010: begin // srl
                        reg0 = instruction[10:6];
                        if (instruction[20:16] == 5'b00000)
                            alu_result = regA >> reg0;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = regB >> reg0;
                    end

                    6'b000011: begin // sra
                        reg0 = instruction[10:6];
                        if (instruction[20:16] == 5'b00000)
                            alu_result = $signed(regA) >>> reg0;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = $signed(regB) >>> reg0;
                    end

                    6'b000111: begin // srav
                        if (instruction[20:16] == 5'b00000)
                            alu_result = $signed(regA) >>> regB;
                        if (instruction[20:16] == 5'b00001)
                            alu_result = $signed(regB) >>> regA;
                    end






                    default: alu_result = 32'h00000000;
                endcase
                end
            endcase
        flags_reg[2] = (alu_result == 0) ? 1'b1 : 1'b0;
    end

    always @(alu_result or alu_flags) begin
        result_reg <= alu_result;
    end

    assign result = result_reg;
    assign flags = flags_reg;
    
// Step 2: You may fetch values in mem;
// Step 3: You should output the correct value of result 
//         and correct status offlags


endmodule