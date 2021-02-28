module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

logic  [4:0] avm_address;
logic        avm_read;
logic [31:0] avm_readdata;
logic        avm_write;
logic        avm_waitrequest;
logic [7:0]  led_value;
logic		 state;

logic clock_25m;

//final_wrapper pll0(
//	.clk_clk(CLOCK_50),       //     clk.clk
//	.clk_25m_clk(clock_25m),   // clk_25m.clk
//	.reset_reset_n(KEY[3])  //   reset.reset_n
//);

//Wrapper wrapper0 (
//    //RS232
//    .avm_rst(KEY[3]),
//    .avm_clk(clock_25m),
//    .avm_address(avm_address),
//    .avm_read(avm_read),
//    .avm_readdata(avm_readdata),
//    .avm_write(avm_write),
//    //output [31:0] avm_writedata,
//    .avm_waitrequest(avm_waitrequest),
//
//    //VGA
//    .VGA_B(VGA_B),
//	  .VGA_BLANK_N(VGA_BLANK_N),
//	  .VGA_CLK(VGA_CLK),
//	  .VGA_G(VGA_G),
//	  .VGA_HS(VGA_HS),
//	  .VGA_R(VGA_R),
//	  .VGA_SYNC_N(VGA_SYNC_N),
//	  .VGA_VS(VGA_VS),
//
//	  //LED
//	  .LED_value(led_value)
//);

	assign HEX0 = (led_value[0] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX1 = (led_value[1] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX2 = (led_value[2] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX3 = (led_value[3] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX4 = (led_value[4] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX5 = (led_value[5] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX6 = (led_value[6] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign HEX7 = (led_value[7] == 1'b0) ? 7'b1000000 : 7'b1111001;
	assign LEDG = (state) ? 8'b00000001 : 8'b00000010;

final_1219_qsys qsys0(
	.clk_clk(CLOCK_50),                        //                        clk.clk
	.reset_reset_n(KEY[3]),                  //                      reset.reset_n
	.uart_0_external_connection_rxd(UART_RXD), // uart_0_external_connection.rxd
	.uart_0_external_connection_txd(UART_TXD),  //                           .txd
	.VGA_B(VGA_B),
	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_CLK(VGA_CLK),
	.VGA_G(VGA_G),
	.VGA_HS(VGA_HS),
	.VGA_R(VGA_R),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_VS(VGA_VS),
	.SRAM_ADDR(SRAM_ADDR),
	.SRAM_DQ(SRAM_DQ),
	.SRAM_WE_N(SRAM_WE_N),
	.SRAM_CE_N(SRAM_CE_N),
	.SRAM_OE_N(SRAM_OE_N),
	.SRAM_LB_N(SRAM_LB_N),
	.SRAM_UB_N(SRAM_UB_N),
	.led_value(led_value),
	.state(state)
);
// please replace this module with the qsys module you generated
// and connect all the ports
// rsa_qsys my_qsys(
// 	.clk_clk(CLOCK_50),
// 	.reset_reset_n(KEY[0]),
// 	.uart_0_external_connection_rxd(UART_RXD),
// 	.uart_0_external_connection_txd(UART_TXD)
// );

endmodule
