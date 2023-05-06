// CLK: input clock signal

`include "InstructionRAM.v"
`include "MainMemory.v"
`include "alu.v"

module ForwardingUnit
(
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] write_reg,
    input [31:0] write_data,
    output reg [31:0] forwardA,
    output reg [31:0] forwardB
);

    always @(*) begin
        forwardA = 0;
        forwardB = 0;

        if (write_reg != 0) begin
            if (write_reg == rs) begin
                forwardA = write_data;
            end
            if (write_reg == rt) begin
                forwardB = write_data;
            end
        end
    end
endmodule

module ID_stage
(
    input CLOCK,
    input [31:0] instruction,
    input [31:0] write_data,
    input [4:0] write_reg,
    output reg [95:0] ID_EX
);

    reg [4:0] rs, rt, rd, shamt;
    reg [5:0] opcode, funct;
    reg [15:0] immediate;

    // Extract instruction fields
    always @(*) begin
        opcode = instruction[31:26];
        rs = instruction[25:21];
        rt = instruction[20:16];
        rd = instruction[15:11];
        shamt = instruction[10:6];
        funct = instruction[5:0];
        immediate = instruction[15:0];
    end

    // Register File
    reg [31:0] regfile [31:0];
    wire [31:0] read_data1, read_data2;

    always @(posedge CLOCK) begin
        if (write_reg != 0) regfile[write_reg] <= write_data;
    end

    assign read_data1 = regfile[rs];
    assign read_data2 = regfile[rt];

    // Forwarding Unit
    wire [31:0] forwardA, forwardB;
    ForwardingUnit fwdUnit (
        .rs(rs), 
        .rt(rt), 
        .write_reg(write_reg), 
        .write_data(write_data), 
        .forwardA(forwardA), 
        .forwardB(forwardB));

    // Extend immediate value
    reg [31:0] extended_imm;
    always @(*) begin
        extended_imm = { {(16){immediate[15]}}, immediate};
    end

    // Pass values to the next stage
    always @(*) begin
        ID_EX[31:26] = opcode;
        ID_EX[25:21] = rs;
        ID_EX[20:16] = rt;
        ID_EX[15:11] = rd;
        ID_EX[10:6] = shamt;
        ID_EX[5:0] = funct;
        ID_EX[31:0] = (forwardA != 0) ? read_data1 : forwardA;
        ID_EX[63:32] = (forwardB != 0) ? read_data2 : forwardB;
        ID_EX[95:64] = extended_imm;
    end
endmodule


module EX_stage
(
    input CLOCK,
    input [95:0] ID_EX,
    output reg [63:0] EX_MEM
);

    reg [2:0] alu_control;
    wire [31:0] alu_result;
    wire alu_zero;

    // Control Unit
    reg [2:0] aluOp;
    always @(posedge CLOCK) begin
        case (ID_EX[31:26])
            6'b000000: aluOp = 3'b000; // R-type instructions
            6'b001000: aluOp = 3'b001; // addi
            6'b001001: aluOp = 3'b001; // addiu
            6'b001100: aluOp = 3'b010; // andi
            6'b001101: aluOp = 3'b100; // ori
            6'b001110: aluOp = 3'b101; // xori
            6'b001111: aluOp = 3'b011; // lui
            default: aluOp = 3'b111;
        endcase
    end

    // ALU Control
    always @(posedge CLOCK) begin
        if (aluOp == 3'b000) begin
            case (ID_EX[5:0])
                6'b100000: alu_control = 3'b000; // add
                6'b100001: alu_control = 3'b000; // addu
                6'b100010: alu_control = 3'b001; // sub
                6'b100011: alu_control = 3'b001; // subu
                6'b100100: alu_control = 3'b010; // and
                6'b100101: alu_control = 3'b100; // or
                6'b100110: alu_control = 3'b101; // xor
                6'b100111: alu_control = 3'b110; // nor
                6'b101010: alu_control = 3'b111; // slt
                default: alu_control = 3'bxxx;
            endcase
        end else begin
            alu_control = aluOp;
        end
    end

    // ALU
    alu my_alu (.alu_control(alu_control), .a(ID_EX[31:0]), .b(ID_EX[63:32]), .result(alu_result), .zero(alu_zero));

    // Shifting instructions
    reg [31:0] shift_result;
    always @(posedge CLOCK) begin
        case (ID_EX[5:0])
            6'b000000: shift_result = ID_EX[63:32] << ID_EX[10:6]; // sll
            6'b000010: shift_result = ID_EX[63:32] >> ID_EX[10:6]; // srl
            6'b000011: shift_result = $signed(ID_EX[63:32]) >>> ID_EX[10:6]; // sra
            6'b000100: shift_result = ID_EX[63:32] << ID_EX[25:21]; // sllv
            6'b000110: shift_result = ID_EX[63:32] >> ID_EX[25:21]; // srlv
            6'b000111: shift_result = $signed(ID_EX[63:32]) >>> ID_EX[25:21]; // srav
            default: shift_result = 0;
        endcase
    end

    // Choose between ALU result and shift result
    reg [31:0] final_result;
    always @(posedge CLOCK) begin
        if (ID_EX[5:0] == 6'b000000 || ID_EX[5:0] == 6'b000010 || ID_EX[5:0] == 6'b000011 ||
            ID_EX[5:0] == 6'b000100 || ID_EX[5:0] == 6'b000110 || ID_EX[5:0] == 6'b000111) begin
            final_result = shift_result;
        end else begin
            final_result = alu_result;
        end
    end

    // Output to EX_MEM
    always @(posedge CLOCK) begin
        EX_MEM[31:0] = final_result;
        EX_MEM[63:32] = ID_EX[94:63];
    end
endmodule


module MEM_stage
(
    input CLOCK,
    input [63:0] EX_MEM,
    input [31:0] data_mem_data,
    output reg [95:0] MEM_WB
);

    // Control signals
    wire RegWrite = EX_MEM[62];
    wire MemtoReg = EX_MEM[61];
    wire MemRead = EX_MEM[60];
    wire MemWrite = EX_MEM[59];

    // Memory read or write
    reg [31:0] mem_data;
    always @(posedge CLOCK) begin
        if (MemRead) begin
            mem_data = data_mem_data;
        end else if (MemWrite) begin
            mem_data = EX_MEM[31:0];
        end else begin
            mem_data = 0;
        end
    end

    // Output to MEM_WB
    always @(posedge CLOCK) begin
        MEM_WB[31:0] = (MemtoReg) ? mem_data : EX_MEM[31:0];
        MEM_WB[63:32] = EX_MEM[58:32];
        MEM_WB[95:64] = EX_MEM[31:0];
    end
endmodule

module WB_stage
(
    input [95:0] MEM_WB,
    input CLOCK,
    output reg [31:0] write_data,
    output reg [4:0] write_register,
    output RegWrite
);

    // Extract control signals and data from MEM_WB
    wire [31:0] ALU_result = MEM_WB[31:0];
    wire [31:0] mem_data = MEM_WB[95:64];
    wire RegDst = MEM_WB[63];
    wire MemtoReg = MEM_WB[62];

    // Choose between ALU result and memory data
    always @(posedge CLOCK) begin
        if (MemtoReg) begin
            write_data = mem_data;
        end else begin
            write_data = ALU_result;
        end
    end

    // Choose the destination register
    always @(posedge CLOCK) begin
        if (RegDst) begin
            write_register = MEM_WB[58:54];
        end else begin
            write_register = MEM_WB[57:53];
        end
    end

    assign RegWrite = MEM_WB[61];

endmodule

module CPU
(
      input CLK
);
    // Instruction Memory
    wire [31:0] instruction;
    reg [31:0] pc = 0;
    wire [31:0] fetch_address = pc >> 2;
    reg [31:0] register_file [0:31];
    InstructionRAM instruction_ram (
        .CLOCK(CLK), 
        .RESET(1'b0), 
        .ENABLE(1'b1), 
        .FETCH_ADDRESS(fetch_address), 
        .DATA(instruction));

    // Data Memory
    wire [31:0] data_mem_data;
    reg [31:0] data_mem_address;
    reg [64:0] data_mem_edit_serial;
    // $display(data_mem_data);
    MainMemory data_memory (
        .CLOCK(CLK), 
        .RESET(1'b0), 
        .ENABLE(1'b1), 
        .FETCH_ADDRESS(data_mem_address), 
        .EDIT_SERIAL(data_mem_edit_serial), 
        .DATA(data_mem_data));

    // Pipeline Stages
    reg [31:0] IF_ID;
    reg [95:0] ID_EX;
    reg [63:0] EX_MEM;
    reg [95:0] MEM_WB;
    wire [31:0] write_data;
    reg [4:0] write_reg;

    // Stage 1: Instruction Fetch (IF)
    always @(posedge CLK) begin
        IF_ID <= instruction;
        pc <= pc + 4;
    end

    // Stage 2: Instruction Decode (ID)
    ID_stage ID_stage_inst (
        .CLOCK(CLK),
        .instruction(IF_ID), 
        .write_data(write_data), 
        .write_reg(write_reg), 
        .ID_EX(ID_EX));

    // Stage 3: Execute (EX)
    EX_stage EX_stage_inst (
        .CLOCK(CLK),
        .ID_EX(ID_EX), 
        .EX_MEM(EX_MEM));

    // Stage 4: Memory Access (MEM)
    MEM_stage MEM_stage_inst (
        .CLOCK(CLK),
        .EX_MEM(EX_MEM), 
        .data_mem_data(data_mem_data), 
        .MEM_WB(MEM_WB));

    // Stage 5: Write Back (WB)
    reg RegWrite;
    WB_stage WB_stage_inst (
        .CLOCK(CLK),
        .MEM_WB(MEM_WB), 
        .write_data(write_data),
        .write_register(write_reg),
        .RegWrite(RegWrite));

    // Connect Data Memory to the MEM stage
    always @(posedge CLK) begin
        data_mem_address <= EX_MEM[31:0];
        data_mem_edit_serial <= {EX_MEM[63], EX_MEM[62:31]};
    end

    // Write to register file
    always @(posedge CLK) begin
        if (RegWrite) begin
            register_file[write_reg] <= write_data;
        end
    end
endmodule
