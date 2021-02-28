module vga(
    //de2-115
    input  i_rst_n,
    input  i_clk_25M,
    output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,

    //SRAM
    output [19:0] o_addr_display,
    input  [15:0] i_pixel_value,

    //Wrapper
    input i_start_display
);

    // Variable definition
    logic [9:0] x_cnt_r, x_cnt_w;
    logic [9:0] y_cnt_r, y_cnt_w;
    logic hsync_r, hsync_w, vsync_r, vsync_w;
    logic [7:0] vga_r_r, vga_g_r, vga_b_r, vga_r_w, vga_g_w, vga_b_w;
    logic [19:0] addr_display_r, addr_display_w;
    logic state_r, state_w;
    
    // 640*480, refresh rate 60Hz
    // VGA clock rate 25.175MHz
    localparam H_FRONT  =   16;
    localparam H_SYNC   =   96;
    localparam H_BACK   =   48;
    localparam H_ACT    =   640;
    localparam H_BLANK  =   H_FRONT + H_SYNC + H_BACK;
    localparam H_TOTAL  =   H_FRONT + H_SYNC + H_BACK + H_ACT;
    localparam V_FRONT  =   10;
    localparam V_SYNC   =   2;
    localparam V_BACK   =   33;
    localparam V_ACT    =   480;
    localparam V_BLANK  =   V_FRONT + V_SYNC + V_BACK;
    localparam V_TOTAL  =   V_FRONT + V_SYNC + V_BACK + V_ACT;

    localparam S_IDLE    = 1'b0;
    localparam S_DISPLAY = 1'b1;

    // Output assignment
    assign VGA_CLK      =   i_clk_25M;
    assign VGA_HS       =   hsync_r;
    assign VGA_VS       =   vsync_r;
    assign VGA_R        =   vga_r_r;
    assign VGA_G        =   vga_g_r;
    assign VGA_B        =   vga_b_r;
    assign VGA_SYNC_N   =   1'b0;
    assign VGA_BLANK_N  =   ~((x_cnt_r < H_BLANK) || (y_cnt_r < V_BLANK));
    assign o_addr_display = addr_display_r;
    
    // Coordinates
    always_comb begin
        case(state_r)
            S_IDLE: begin
                x_cnt_w = 0;
            end
            S_DISPLAY: begin
                if (x_cnt_r == 800) begin
                    x_cnt_w = 0;
                end
                else begin
                    x_cnt_w = x_cnt_r + 1;
                end
            end
        endcase
    end

    always_comb begin
        case(state_r)
            S_IDLE: begin
                y_cnt_w = 0;
            end
            S_DISPLAY: begin
                if (y_cnt_r == 525) begin
                    y_cnt_w = 0;
                end
                else if (x_cnt_r == 800) begin
                    y_cnt_w = y_cnt_r + 1;
                end
                else begin
                    y_cnt_w = y_cnt_r;
                end
            end
        endcase
    end

    // Sync signals
    always_comb begin
        case(state_r)
            S_IDLE: begin
                hsync_w = 1'b1;
            end
            S_DISPLAY: begin
                if (x_cnt_r == 0) begin
                    hsync_w = 1'b0;
                end
                else if (x_cnt_r == H_SYNC) begin
                    hsync_w = 1'b1;
                end
                else begin
                    hsync_w = hsync_r;
                end
            end
        endcase
    end
    
    always_comb begin
        case(state_r)
            S_IDLE: begin
                vsync_w = 1'b1;
            end
            S_DISPLAY: begin
                if (y_cnt_r == 0) begin
                    vsync_w = 1'b0;
                end
                else if (y_cnt_r == V_SYNC) begin
                    vsync_w = 1'b1;                 
                end
                else begin
                    vsync_w = vsync_r;
                end
            end
        endcase
    end
    
    // RGB data
    always_comb begin
        case(state_r)
            S_IDLE: begin
                addr_display_w = 20'd0;
                vga_r_w = 8'b0;
                vga_g_w = 8'b0;
                vga_b_w = 8'b0;
            end
            S_DISPLAY: begin
                if(addr_display_r == 20'd307200/*x_cnt_r == 0 && y_cnt_r == 0*/) begin
                    addr_display_w = 20'd0;
                    vga_r_w = 8'b0;
                    vga_g_w = 8'b0;
                    vga_b_w = 8'b0;
                end
                else if(x_cnt_r < (H_BLANK-1) || x_cnt_r > (H_TOTAL-2) || y_cnt_r < V_BLANK || y_cnt_r >= V_TOTAL) begin
                    addr_display_w = addr_display_r;
                    vga_r_w = 8'b0;
                    vga_g_w = 8'b0;
                    vga_b_w = 8'b0;
                end
                else begin
                    addr_display_w = addr_display_r + 20'd1;
                    vga_r_w = i_pixel_value[7:0];//{i_pixel_value[0], i_pixel_value[1], i_pixel_value[2], i_pixel_value[3], i_pixel_value[4], i_pixel_value[5], i_pixel_value[6], i_pixel_value[7]};//addr_display_r[15:8];
                    vga_g_w = i_pixel_value[7:0];//{i_pixel_value[0], i_pixel_value[1], i_pixel_value[2], i_pixel_value[3], i_pixel_value[4], i_pixel_value[5], i_pixel_value[6], i_pixel_value[7]};//addr_display_r[15:8];
                    vga_b_w = i_pixel_value[7:0];//{i_pixel_value[0], i_pixel_value[1], i_pixel_value[2], i_pixel_value[3], i_pixel_value[4], i_pixel_value[5], i_pixel_value[6], i_pixel_value[7]};//addr_display_r[15:8];
                end
            end
        endcase
    end

    //FSM
    always_comb begin
        if(i_start_display) begin
            state_w = S_DISPLAY;
        end
        else begin
            state_w = state_r;
        end
    end

    // Flip-flop
    always_ff @(posedge i_clk_25M or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x_cnt_r <= 0;   
            y_cnt_r <= 0;
            hsync_r <= 1'b1;
            vsync_r <= 1'b1;
            vga_r_r <= 8'b0;
            vga_g_r <= 8'b0;
            vga_b_r <= 8'b0;
            addr_display_r <= 20'b0;
            state_r <= S_IDLE;
        end
        else begin
            x_cnt_r <= x_cnt_w;
            y_cnt_r <= y_cnt_w;
            hsync_r <= hsync_w;
            vsync_r <= vsync_w;
            vga_r_r <= vga_r_w;
            vga_g_r <= vga_g_w;
            vga_b_r <= vga_b_w;
            addr_display_r <= addr_display_w;
            state_r <= state_w;
        end
    end
endmodule
