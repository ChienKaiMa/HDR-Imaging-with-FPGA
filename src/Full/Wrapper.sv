`define IMAGE_NUMBER 4
module Wrapper (
    //RS232
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    input         avm_waitrequest,

    //VGA
    output [7:0]  VGA_B,
	output        VGA_BLANK_N,
	output        VGA_CLK,
	output [7:0]  VGA_G,
	output        VGA_HS,
	output [7:0]  VGA_R,
	output        VGA_SYNC_N,
	output        VGA_VS,

    //SRAM
    output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,

    //LED(test)
    output [7:0] LED_value,

    //DE2-115(test)
    output state
);

    //parameter
    localparam S_STORE   = 0;
    localparam S_DISPLAY = 1;

    //wire/register
    logic [7:0]  pixel_value;
    logic        state_r, state_w;
    logic [19:0] addr_store, addr_display;
    logic        start_display;
    logic [15:0] pixel_display;

    //output
    assign LED_value = pixel_value;
    assign state = state_r;
    assign o_SRAM_ADDR = (state_r == S_STORE)? addr_store : addr_display;
    assign io_SRAM_DQ  = (state_r == S_STORE)? pixel_value : 16'dz;
    assign o_SRAM_WE_N = (state_r == S_STORE)? 1'b0 : 1'b1;
	assign o_SRAM_CE_N = 1'b0;
	assign o_SRAM_OE_N = 1'b0;
	assign o_SRAM_LB_N = 1'b0;
	assign o_SRAM_UB_N = 1'b0;

    //assignment
    assign pixel_display = (state_r == S_DISPLAY)? io_SRAM_DQ : 16'b0;

    //combinational circuit
    always_comb begin
        case(state_r)
            S_STORE: begin
                if(start_display) begin
                    state_w = S_DISPLAY;
                end
                else begin
                    state_w = state_r;
                end
            end
            S_DISPLAY: begin
                state_w = state_r;
            end
            default: begin
                state_w = state_r;
            end
        endcase
    end

    //sequential circuit
    always_ff @(posedge avm_clk or negedge avm_rst) begin
        if(!avm_rst) begin
            state_r <= S_STORE;
        end
        else begin
            state_r <= state_w;
        end
    end

    //submodules
    RS232 rs232_0(
        .avm_rst(avm_rst),
        .avm_clk(avm_clk),
        .avm_address(avm_address),
        .avm_read(avm_read),
        .avm_readdata(avm_readdata),
        .avm_waitrequest(avm_waitrequest),
        .pixel_value(pixel_value),
        .addr_store(addr_store),
        .store_finish(start_display)
    );

    vga vga0(
        .i_rst_n(avm_rst),
        .i_clk_25M(avm_clk),
        .VGA_B(VGA_B),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_CLK(VGA_CLK),
        .VGA_G(VGA_G),
        .VGA_HS(VGA_HS),
        .VGA_R(VGA_R),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_VS(VGA_VS),
        .o_addr_display(addr_display),
        .i_pixel_value(pixel_display),
        .i_start_display(start_display)
    );

endmodule
