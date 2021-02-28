module Recover(
    input                            clk,
    input                            rst_n,
    input                            calculate_start,
    input  [(IMAGE_NUMBER-1):0][7:0] images,
    output                           calculate_finish,
    output [7:0]                     calculate_result
    );

    //parameter IMAGE_NUMBER = 4;
    localparam S_IDLE = 0;
    localparam S_CALCULATE = 1;

    logic state_r, state_w;
    logic calculate_finish_r, calculate_finish_w;
    logic [7:0] calculate_result_r, calculate_result_w;

    assign calculate_finish = calculate_finish_r;
    assign calculate_result = calculate_result_r;

    always_comb begin
        case(state_r)
            S_IDLE: begin
                calculate_finish_w = 1'b0;
                calculate_result_w = calculate_result_r;
                if(calculate_start) begin
                    state_w = S_CALCULATE;
                end
                else begin
                    state_w = state_r;
                end
            end
            S_CALCULATE: begin
                state_w = S_IDLE;
                calculate_finish_w = 1'b1;
                calculate_result_w = (images[0] >> 2) + (images[1] >> 2) + (images[2] >> 2) + (images[3] >> 2);
            end
        endcase
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            state_r <= S_IDLE;
            calculate_finish_r <= 1'b0;
            calculate_result_r <= 8'b0;
        end
        else begin
            state_r <= state_w;
            calculate_finish_r <= calculate_finish_w;
            calculate_result_r <= calculate_result_w;
        end
    end

endmodule
