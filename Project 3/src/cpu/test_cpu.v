`include "cpu.v"
`timescale 1ns/1ps

module test_CPU();

reg CLK;
reg RESET;

CPU cpu_inst (
    .CLK(CLK)
);

// Clock generator
always begin
    #5 CLK = ~CLK;
end

// Read machine code from file
task load_machine_code;
    integer file;
    reg [31:0] code;
    integer i;

    begin
        file = $fopen("../../testcase/cpu_test/machine_code1.txt", "r");
        if (file) begin
            for (i = 0; i < 64; i = i + 1) begin
                $fscanf(file, "%b\n", code);
                cpu_inst.instruction_ram.memory[i] = code;
            end
            $fclose(file);
        end else begin
            $display("Error: Cannot open machine_code1.txt");
            $finish;
        end
    end
endtask

initial begin
    // Initialize signals
    CLK = 0;
    RESET = 1;

    // Load machine code into instruction memory
    load_machine_code;

    // Reset and start the CPU
    #10 RESET = 0;
    #100000;

    // Display the contents of the register file
    $display("Register File Contents:");
    for (integer i = 0; i < 32; i = i + 1) begin
        $display("Register %0d: 32'h%08x", i, cpu_inst.register_file.registers[i]);
    end

    // Finish simulation
    $finish;
end

endmodule
