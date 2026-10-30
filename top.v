module top (
    input  wire clk,
    output wire tx,
    input  wire rx,
    output wire led_blue_n,   
    output wire led_amber_n  
);

    // Reliable power-on reset generator (active-low)
    reg [7:0] rst_pipe = 8'h00;
    wire rst_n = rst_pipe[7];
    always @(posedge clk) begin
        rst_pipe <= {rst_pipe[6:0], 1'b1};
    end

    // Instruction Memory (256 x 16-bit)
    wire [7:0]  imem_addr;
    reg  [15:0] imem_data;
    reg  [15:0] rom [0:255];

    initial begin
 $readmemh("imem.hex", rom);   

    always @(posedge clk) begin
        imem_data <= rom[imem_addr];
    end


    wire [7:0] gpio_in = 8'h00;
    wire [7:0] gpio_out;
    wire [7:0] gpio_dir;

    assign tx = gpio_out[0];

    assign led_blue_n  = ~rst_n;       // Turns ON blue LED when core is un-reset & running
    assign led_amber_n = ~gpio_out[0]; // Flashes amber LED with TX activity

    // Instantiate Protocol Emulator Core
    protocol_emulator u_core (
        .clk      (clk),
        .rst_n    (rst_n),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_dir (gpio_dir),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .data_in  (8'h00),
        .data_out (),
        .busy     ()
    );

endmodule