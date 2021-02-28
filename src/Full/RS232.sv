module RS232(
    //DE2-115
    input         avm_rst,
    input         avm_clk,
    output [4:0]  avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    input         avm_waitrequest,

    //SRAM
    output [7:0]  pixel_value,
    output [19:0] addr_store,

    //Wrapper
    output store_finish
);

    localparam RX_BASE     = 0*4;
    localparam TX_BASE     = 1*4;
    localparam STATUS_BASE = 2*4;
    localparam TX_OK_BIT   = 6;
    localparam RX_OK_BIT   = 7;

    localparam S_PREPARE = 0;
    localparam S_GET_DATA = 1;
    localparam S_WAIT_CALCULATE = 2;
    //localparam S_SEND_DATA = 3;

    localparam IMAGE_SIZE = 640*480*1; //bytes
    //parameter  IMAGE_NUMBER = 4;

    logic [1:0] state_r, state_w;
    logic [19:0] bytes_counter_r, bytes_counter_w;
    logic [3:0] image_counter_r, image_counter_w;
    logic [4:0] avm_address_r, avm_address_w;
    logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;
    logic [7:0] pixel_value_r, pixel_value_w;
    logic [19:0] addr_store_r, addr_store_w;
    logic store_finish_r, store_finish_w;
    logic [(IMAGE_NUMBER-1):0][7:0] images_r, images_w;
    logic calculate_start_r, calculate_start_w;
    logic calculate_finish;
    logic [7:0] calculate_result;

    integer idx;

    assign avm_address  = avm_address_r;
    assign avm_read     = avm_read_r;
    assign pixel_value  = pixel_value_r;
    assign addr_store   = addr_store_r;
    assign store_finish = store_finish_r;

    task StartRead;
        input [4:0] addr;
        begin
            avm_read_w = 1;
            avm_write_w = 0;
            avm_address_w = addr;
        end
    endtask

    Recover recover0(
        .clk(avm_clk),
        .rst_n(avm_rst),
        .calculate_start(calculate_start_r),
        .images(images_r),
        .calculate_finish(calculate_finish),
        .calculate_result(calculate_result)
    );

    always_comb begin
        avm_read_w = avm_read_r;
        avm_write_w = avm_write_r;
        avm_address_w = avm_address_r;
        images_w = images_r;
        case(state_r)
            S_PREPARE: begin
                calculate_start_w = 1'b0;
                if(~avm_waitrequest & avm_readdata[RX_OK_BIT]) begin
                    StartRead(RX_BASE);
                    pixel_value_w = pixel_value_r;
                    addr_store_w = addr_store_r;
                    image_counter_w = image_counter_r;
                    if(bytes_counter_r < IMAGE_SIZE * IMAGE_NUMBER) begin
                        state_w = S_GET_DATA;
                        bytes_counter_w = bytes_counter_r + 1;
                        store_finish_w = 1'b0;
                    end
                    else begin
                        state_w = state_r;
                        bytes_counter_w = bytes_counter_r;
                        store_finish_w = 1'b1;
                    end
                end
                else begin 
                    bytes_counter_w = bytes_counter_r;
                    image_counter_w = image_counter_r;
                    state_w = state_r;
                    pixel_value_w = pixel_value_r;
                    addr_store_w = addr_store_r;
                    store_finish_w = 1'b0;
                end
            end
            S_GET_DATA: begin
                bytes_counter_w = bytes_counter_r;
                if(~avm_waitrequest) begin
                    if(image_counter_r < IMAGE_NUMBER - 1) begin
                        StartRead(STATUS_BASE);
                        state_w = S_PREPARE;
                        images_w[image_counter_r][7:0] = avm_readdata[7:0];
                        image_counter_w = image_counter_r + 1;
                        pixel_value_w = pixel_value_r;
                        addr_store_w = addr_store_r;
                        //pixel_value_w = avm_readdata[7:0];
                        //addr_store_w = addr_store_r + 20'd1;
                        store_finish_w = 1'b0;
                        calculate_start_w = 1'b0;
                    end
                    else begin
                        state_w = S_WAIT_CALCULATE;
                        images_w[image_counter_r][7:0] = avm_readdata[7:0];
                        image_counter_w = image_counter_r;
                        pixel_value_w = pixel_value_r;
                        addr_store_w = addr_store_r;
                        store_finish_w = 1'b0;
                        calculate_start_w = 1'b1;
                    end
                end
                else begin
                    state_w = state_r;
                    image_counter_w = image_counter_r;
                    pixel_value_w = pixel_value_r;
                    addr_store_w = addr_store_r;
                    store_finish_w = 1'b0;
                    calculate_start_w = 1'b0;
                end
            end
            S_WAIT_CALCULATE: begin
                bytes_counter_w = bytes_counter_r;
                calculate_start_w = 1'b0;
                if(calculate_finish) begin
                    StartRead(STATUS_BASE);
                    state_w = S_PREPARE;
                    image_counter_w = 0;
                    pixel_value_w = calculate_result;
                    addr_store_w = addr_store_r + 20'd1;
                    store_finish_w = 1'b0;
                end
                else begin
                    state_w = S_WAIT_CALCULATE;
                    image_counter_w = image_counter_r;
                    pixel_value_w = pixel_value_r;
                    addr_store_w = addr_store_r;
                    store_finish_w = 1'b0;
                end
            end
        endcase
    end

    always_ff @(posedge avm_clk or negedge avm_rst) begin
        if (!avm_rst) begin
            avm_address_r   <= STATUS_BASE;
            avm_read_r      <= 1;
            avm_write_r     <= 0;
            state_r         <= S_PREPARE;
            pixel_value_r   <= 8'b0;
            bytes_counter_r <= 0;
            addr_store_r    <= 0;
            store_finish_r  <= 0;
            image_counter_r <= 0;
            for(idx = 0; idx < IMAGE_NUMBER; idx = idx + 1) begin
                images_r[idx] <= 0;
            end
        end 
        else begin
            avm_address_r   <= avm_address_w;
            avm_read_r      <= avm_read_w;
            avm_write_r     <= avm_write_w;
            state_r         <= state_w;
            pixel_value_r   <= pixel_value_w;
            bytes_counter_r <= bytes_counter_w;
            addr_store_r    <= addr_store_w;
            store_finish_r  <= store_finish_w;
            image_counter_r <= image_counter_w;
            images_r        <= images_w;
        end
    end

//test begin
    //logic [9:0] x_cnt_r, x_cnt_w;
    //logic [9:0] y_cnt_r, y_cnt_w;
    //logic [18:0] counter_r, counter_w;
    //always_comb begin
    //    if (x_cnt_r == 800) begin
    //        x_cnt_w = 0;
    //    end
    //    else begin
    //        x_cnt_w = x_cnt_r + 1;
    //    end
    //end
    //
    //always_comb begin
    //    if (y_cnt_r == 525) begin
    //        y_cnt_w = 0;
    //    end
    //    else if (x_cnt_r == 800) begin
    //        y_cnt_w = y_cnt_r + 1;
    //    end
    //    else begin
    //        y_cnt_w = y_cnt_r;
    //    end
    //end
    //
    //always_comb begin
    //    if(counter_r == 19'd420524) begin
    //        counter_w = 0;
    //    end
    //    else begin
    //        counter_w = counter_r + 1;            
    //    end
    //end
    //
    //always_comb begin
    //    if(counter_r <= 19'd40000) begin
    //        pixel_value_w = 8'd20;
    //    end
    //    else if(counter_r <= 19'd80000) begin
    //        pixel_value_w = 8'd40;
    //    end
    //    else if(counter_r <= 19'd120000) begin
    //        pixel_value_w = 8'd60;
    //    end
    //    else if(counter_r <= 19'd160000) begin
    //        pixel_value_w = 8'd80;
    //    end
    //    else if(counter_r <= 19'd200000) begin
    //        pixel_value_w = 8'd100;
    //    end
    //    else if(counter_r <= 19'd240000) begin
    //        pixel_value_w = 8'd120;
    //    end
    //    else if(counter_r <= 19'd280000) begin
    //        pixel_value_w = 8'd140;
    //    end
    //    else if(counter_r <= 19'd320000) begin
    //        pixel_value_w = 8'd160;
    //    end
    //    else if(counter_r <= 19'd360000) begin
    //        pixel_value_w = 8'd180;
    //    end
    //    else if(counter_r <= 19'd400000) begin
    //        pixel_value_w = 8'd200;
    //    end
    //    else begin
    //        pixel_value_w = 8'd220;
    //    end
    //end
    //always_ff @(posedge avm_clk or negedge avm_rst) begin
    //    if(!avm_rst) begin
    //        pixel_value_r <= 8'b0;
    //        x_cnt_r <= 0;   
    //        y_cnt_r <= 0;
    //        counter_r <= 0;
    //    end
    //    else begin
    //        pixel_value_r <= pixel_value_w;
    //        x_cnt_r <= x_cnt_w;
    //        y_cnt_r <= y_cnt_w;
    //        counter_r <= counter_w;
    //    end
    //end
//test end

endmodule
