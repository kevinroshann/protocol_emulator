// protocol_emulator.v
// Compact 16-bit Protocol Emulator Core (Fixed State Width & FSM Pipeline)

module protocol_emulator (
    input  wire        clk,
    input  wire        rst_n,
    
    // GPIO Pins Interface (8-bit bidir)
    input  wire [7:0]  gpio_in,
    output reg  [7:0]  gpio_out,
    output reg  [7:0]  gpio_dir,  // 1 = Output, 0 = Input/Open-Drain
    
    // Instruction Memory Interface (256 x 16-bit)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    
    // Status & Interface
    input  wire [7:0]  data_in,      // Parallel data from host
    output reg  [7:0]  data_out,     // Parallel data to host
    output reg         busy
);

    // Opcodes Definition
    localparam OP_SET_PIN    = 4'h1;
    localparam OP_DIR_PIN    = 4'h2;
    localparam OP_READ_PIN   = 4'h3;
    localparam OP_WAIT_CYC   = 4'h4;
    localparam OP_WAIT_PIN   = 4'h5;
    localparam OP_OUT_SHIFT  = 4'h6;
    localparam OP_IN_SHIFT   = 4'h7;
    localparam OP_LOAD_IMM   = 4'h8;
    localparam OP_JUMP       = 4'h9;
    localparam OP_JUMP_NZ    = 4'hA;

    // Registers
    reg [7:0]  pc;          // Program Counter
    reg [7:0]  sr;          // Shift Register
    reg [7:0]  ctr;         // Loop Counter
    reg [15:0] delay_cnt;   // Cycle Delay Counter

    // FSM States (FIX: 2-bit register)
    localparam ST_FETCH   = 2'b00;
    localparam ST_EXECUTE = 2'b01;
    localparam ST_WAIT    = 2'b10;

    reg [1:0] state; // FIXED: declared as [1:0] instead of [1:1]

    // Instruction Decode Connections
    assign imem_addr = pc;
    
    wire [3:0] opcode  = imem_data[15:12];
    wire [3:0] pin_id  = imem_data[11:8];
    wire [7:0] imm8    = imem_data[7:0];
    wire [11:0] imm12  = imem_data[11:0];

    // Execution Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc        <= 8'h00;
            sr        <= 8'h00;
            ctr       <= 8'h00;
            delay_cnt <= 16'h0000;
            gpio_out  <= 8'h00;
            gpio_dir  <= 8'h00;
            data_out  <= 8'h00;
            busy      <= 1'b0;
            state     <= ST_FETCH;
        end else begin
            case (state)

                ST_FETCH: begin
                    busy  <= 1'b1;
                    state <= ST_EXECUTE;
                end

                ST_EXECUTE: begin
                    case (opcode)
                        OP_SET_PIN: begin
                            gpio_out[pin_id[2:0]] <= imem_data[0];
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_DIR_PIN: begin
                            gpio_dir[pin_id[2:0]] <= imem_data[0];
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_READ_PIN: begin
                            sr[0] <= gpio_in[pin_id[2:0]];
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_WAIT_CYC: begin
                            if (imm12 > 12'd1) begin
                                delay_cnt <= imm12 - 1'b1;
                                state <= ST_WAIT;
                            end else begin
                                pc <= pc + 1'b1;
                                state <= ST_FETCH;
                            end
                        end

                        OP_WAIT_PIN: begin
                            if (gpio_in[pin_id[2:0]] == imem_data[0]) begin
                                pc <= pc + 1'b1;
                                state <= ST_FETCH;
                            end
                        end

                        OP_OUT_SHIFT: begin
                            gpio_out[pin_id[2:0]] <= imem_data[0] ? sr[7] : sr[0];
                            if (imem_data[0])
                                sr <= {sr[6:0], 1'b0};
                            else
                                sr <= {1'b0, sr[7:1]};
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_IN_SHIFT: begin
                            if (imem_data[0])
                                sr <= {sr[6:0], gpio_in[pin_id[2:0]]};
                            else
                                sr <= {gpio_in[pin_id[2:0]], sr[7:1]};
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_LOAD_IMM: begin
                            if (pin_id[0] == 1'b0)
                                sr <= imm8;
                            else
                                ctr <= imm8;
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end

                        OP_JUMP: begin
                            pc <= imm8;
                            state <= ST_FETCH;
                        end

                        OP_JUMP_NZ: begin
                            if (ctr > 8'd1) begin
                                ctr <= ctr - 1'b1;
                                pc  <= imm8;
                            end else begin
                                ctr <= 8'd0;
                                pc  <= pc + 1'b1;
                            end
                            state <= ST_FETCH;
                        end

                        default: begin
                            pc <= pc + 1'b1;
                            state <= ST_FETCH;
                        end
                    endcase
                end

                ST_WAIT: begin
                    if (delay_cnt <= 16'h0001) begin
                        pc <= pc + 1'b1;
                        state <= ST_FETCH;
                    end else begin
                        delay_cnt <= delay_cnt - 1'b1;
                    end
                end

            endcase
        end
    end

endmodule