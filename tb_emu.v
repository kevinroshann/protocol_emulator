// tb_protocol_emulator.v
// Testbench for Protocol Emulator Core

`timescale 1ns / 1ps

module tb_protocol_emulator;

    // Inputs
    reg        clk;
    reg        rst_n;
    reg  [7:0] gpio_in;
    reg  [7:0] data_in;

    // Outputs
    wire [7:0] gpio_out;
    wire [7:0] gpio_dir;
    wire [7:0] imem_addr;
    wire [7:0] data_out;
    wire       busy;

    // Instruction Memory array (256 instructions x 16-bit)
    reg [15:0] imem [0:255];
    wire [15:0] imem_data = imem[imem_addr];

    // Instantiate Unit Under Test (UUT)
    protocol_emulator uut (
        .clk(clk),
        .rst_n(rst_n),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy)
    );

    // ------------------------------------------------------------------------
    // Clock Generation: 50 MHz Clock (20ns Period)
    // ------------------------------------------------------------------------
    always #10 clk = ~clk;

    // ------------------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------------------
    integer i;
  initial begin
        $dumpfile("tb_protocol_emulator.vcd");
        $dumpvars(0, tb_protocol_emulator);

        clk     = 0;
        rst_n   = 0;
        gpio_in = 8'h00;
        data_in = 8'h00;

        // Load compiled assembly code into Instruction Memory
        $readmemh("imem.hex", imem);

        #40;
        rst_n = 1;

        #1500;
        $finish;
    end
endmodule