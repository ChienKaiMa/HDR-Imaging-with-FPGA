module global_tone 
#(
	parameter d_w = 0,
	parameter d_hw = 0,
	parameter addr_w = 0,
	parameter num_w = 0
)
(
	input i_clk,
	input rst_n,
	input i_start,
	input [num_w-1:0] total_pixels,
	input [d_w-1:0] i_rad_maxmin,
	input [d_w-1:0] i_rad_min,
	output [d_w-1:0] o_wdata,
	output [addr_w-1:0] o_addr,
	output o_wen,
	input [d_w-1:0] i_rdata,
	input [d_hw-1:0] i_beta, //adjust intensity factor
	output o_fin
);
	reg [3:0] state,state_nxt;
	reg [2:0] ctr, ctr_nxt; 

	reg [d_w-1:0] s_addr, s_addr_nxt;
	reg [addr_w-1:0] s_wdata, s_wdata_nxt;
	reg wen, wen_nxt;

	reg [d_w-1:0] data, data_nxt;
	reg [d_hw-1:0] pow_max,pow_max_nxt;
	reg [d_hw-1:0] pow_min,pow_min_nxt;

	reg [d_w-1:0] d_in1,d_in2;
	wire [d_hw-1:0] d_o;
	reg [d_hw-1:0] p_addr;
	wire [d_hw-1:0] p_o;
	localparam S_IDLE = 0;
	localparam S_ADDR = 1;
	localparam S_READ = 2;
	localparam S_NORM = 3; 
	localparam S_POW = 4;
	localparam S_WRITE = 5;
	localparam S_PAUSE = 6;
	localparam S_ADDR2 = 7;
	localparam S_READ2 = 8;
	localparam S_NORM2 = 9;
	localparam S_WRITE2 = 10;
	localparam S_FIN = 11;
	localparam BASE_ADDR = -1;
	division #(.d_w(d_w),.d_hw(d_hw)) D (d_in1,d_in2,d_o);
	pow_table #(.d_hw(d_hw)) P(i_clk,rst_n,p_addr,p_o);
	assign o_wdata = s_wdata;
	assign o_addr = s_addr;
	assign o_fin = (state == S_FIN);
	always @(*) begin
		state_nxt = state;
		ctr_nxt = ctr;

		s_addr_nxt = s_addr;
		s_wdata_nxt = s_wdata;
		wen_nxt =wen;
		
		data_nxt = data;
		pow_max_nxt = pow_max;
		pow_min_nxt = pow_min;
		
		d_in1 = 0;
		d_in2 = 1;
		p_addr = 0;
		case(state)
			S_IDLE: begin
				if(i_start) begin
					state_nxt = S_ADDR;
					ctr_nxt = 1;
					s_addr_nxt = BASE_ADDR;
					pow_max_nxt = 0;
					pow_min_nxt = 255;
				end
			end
			S_ADDR: begin
				state_nxt = S_READ;
				s_addr_nxt = s_addr + 1;
				wen_nxt = 0;
			end
			S_READ: begin
				state_nxt = S_NORM;
				data_nxt = i_rdata;
			end
			S_NORM: begin
				state_nxt = S_POW;
				d_in1 = data - i_rad_min;
				d_in2 = i_rad_maxmin;
				data_nxt = {{d_hw{1'b0}},d_o};
			end
			S_POW: begin
				state_nxt = S_WRITE;
				p_addr = data[d_hw-1:0];
				data_nxt = {{d_hw{1'b0}},p_o};
			end
			S_WRITE: begin
				if(ctr<total_pixels) begin
					state_nxt = S_ADDR;
					ctr_nxt = ctr + 1;
				end
				else begin
					state_nxt = S_PAUSE;
				end
				wen_nxt = 1;
				s_wdata_nxt = data;
				if(data<pow_min) begin
					pow_min_nxt = data;
				end
				if(data>pow_max) begin
					pow_max_nxt = data;
				end
			end
			S_PAUSE: begin
				state_nxt = S_ADDR2;
				ctr_nxt = 1;
				s_addr_nxt = BASE_ADDR;
			end
			S_ADDR2: begin
				state_nxt = S_READ2;
				s_addr_nxt = s_addr + 1;
				wen_nxt = 0;
			end
			S_READ2: begin
				state_nxt = S_NORM2;
				data_nxt = i_rdata;
			end
			S_NORM2: begin
				state_nxt = S_WRITE2;
				d_in1 = data - pow_min;
				d_in2 = pow_max - pow_min;
				data_nxt = {{d_hw{1'b0}},d_o};
			end
			S_WRITE2: begin
				if(ctr<total_pixels) begin
					state_nxt = S_ADDR2;
					ctr_nxt = ctr + 1;
				end
				else begin
					state_nxt = S_FIN;
				end
				wen_nxt = 1;
				s_wdata_nxt = data;	
			end
			S_FIN: begin
				wen_nxt = 0;
			end
		endcase
	end
	always @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			state <= 0;
			data <= 0;
			s_wdata <= 0;
			s_addr <= 0;
			pow_max <= 0;
			pow_min <= 0;
			ctr <= 0;
			wen <= 0;
		end
		else begin
			state <= state_nxt;
			data <= data_nxt;
			s_wdata <= s_wdata_nxt;
			s_addr <= s_addr_nxt;
			pow_max <= pow_max_nxt;
			pow_min <= pow_min_nxt;
			ctr <= ctr_nxt;
			wen <= wen_nxt;
		end
	end
endmodule

module division
#(
	parameter d_w = 0,
	parameter d_hw = 0
)
(
	input [d_w-1:0] a,
	input [d_w-1:0] b,
	output [d_hw-1:0]c
);
	assign c= (a<<(d_hw))/b;
endmodule


module mul
#(
	parameter d_hw = 0
)
(
	input [d_hw-1:0] a,
	input [d_hw-1:0] b,
	output [d_hw-1:0] c
);
	assign c = (a*b)>>d_hw-1;
endmodule

module pow_table
#(
	parameter d_hw = 0
)
(
	input i_clk,
	input rst_n,
	input [d_hw-1:0] addr,
	output [d_hw-1:0] o_data
);
integer i;
reg [d_hw-1:0] data [0:255];
assign o_data = data[addr];
always @(posedge i_clk or negedge rst_n) begin
	if (~rst_n) begin
		data[0] <= 128;
		data[1] <= 128;
		data[2] <= 128;
		data[3] <= 129;
		data[4] <= 129;
		data[5] <= 129;
		data[6] <= 130;
		data[7] <= 130;
		data[8] <= 130;
		data[9] <= 131;
		data[10] <= 131;
		data[11] <= 131;
		data[12] <= 132;
		data[13] <= 132;
		data[14] <= 132;
		data[15] <= 133;
		data[16] <= 133;
		data[17] <= 134;
		data[18] <= 134;
		data[19] <= 134;
		data[20] <= 135;
		data[21] <= 135;
		data[22] <= 135;
		data[23] <= 136;
		data[24] <= 136;
		data[25] <= 136;
		data[26] <= 137;
		data[27] <= 137;
		data[28] <= 138;
		data[29] <= 138;
		data[30] <= 138;
		data[31] <= 139;
		data[32] <= 139;
		data[33] <= 139;
		data[34] <= 140;
		data[35] <= 140;
		data[36] <= 141;
		data[37] <= 141;
		data[38] <= 141;
		data[39] <= 142;
		data[40] <= 142;
		data[41] <= 143;
		data[42] <= 143;
		data[43] <= 143;
		data[44] <= 144;
		data[45] <= 144;
		data[46] <= 144;
		data[47] <= 145;
		data[48] <= 145;
		data[49] <= 146;
		data[50] <= 146;
		data[51] <= 146;
		data[52] <= 147;
		data[53] <= 147;
		data[54] <= 148;
		data[55] <= 148;
		data[56] <= 148;
		data[57] <= 149;
		data[58] <= 149;
		data[59] <= 150;
		data[60] <= 150;
		data[61] <= 150;
		data[62] <= 151;
		data[63] <= 151;
		data[64] <= 152;
		data[65] <= 152;
		data[66] <= 153;
		data[67] <= 153;
		data[68] <= 153;
		data[69] <= 154;
		data[70] <= 154;
		data[71] <= 155;
		data[72] <= 155;
		data[73] <= 155;
		data[74] <= 156;
		data[75] <= 156;
		data[76] <= 157;
		data[77] <= 157;
		data[78] <= 158;
		data[79] <= 158;
		data[80] <= 158;
		data[81] <= 159;
		data[82] <= 159;
		data[83] <= 160;
		data[84] <= 160;
		data[85] <= 161;
		data[86] <= 161;
		data[87] <= 161;
		data[88] <= 162;
		data[89] <= 162;
		data[90] <= 163;
		data[91] <= 163;
		data[92] <= 164;
		data[93] <= 164;
		data[94] <= 165;
		data[95] <= 165;
		data[96] <= 165;
		data[97] <= 166;
		data[98] <= 166;
		data[99] <= 167;
		data[100] <= 167;
		data[101] <= 168;
		data[102] <= 168;
		data[103] <= 169;
		data[104] <= 169;
		data[105] <= 170;
		data[106] <= 170;
		data[107] <= 171;
		data[108] <= 171;
		data[109] <= 171;
		data[110] <= 172;
		data[111] <= 172;
		data[112] <= 173;
		data[113] <= 173;
		data[114] <= 174;
		data[115] <= 174;
		data[116] <= 175;
		data[117] <= 175;
		data[118] <= 176;
		data[119] <= 176;
		data[120] <= 177;
		data[121] <= 177;
		data[122] <= 178;
		data[123] <= 178;
		data[124] <= 179;
		data[125] <= 179;
		data[126] <= 180;
		data[127] <= 180;
		data[128] <= 181;
		data[129] <= 181;
		data[130] <= 182;
		data[131] <= 182;
		data[132] <= 182;
		data[133] <= 183;
		data[134] <= 183;
		data[135] <= 184;
		data[136] <= 184;
		data[137] <= 185;
		data[138] <= 185;
		data[139] <= 186;
		data[140] <= 186;
		data[141] <= 187;
		data[142] <= 188;
		data[143] <= 188;
		data[144] <= 189;
		data[145] <= 189;
		data[146] <= 190;
		data[147] <= 190;
		data[148] <= 191;
		data[149] <= 191;
		data[150] <= 192;
		data[151] <= 192;
		data[152] <= 193;
		data[153] <= 193;
		data[154] <= 194;
		data[155] <= 194;
		data[156] <= 195;
		data[157] <= 195;
		data[158] <= 196;
		data[159] <= 196;
		data[160] <= 197;
		data[161] <= 197;
		data[162] <= 198;
		data[163] <= 199;
		data[164] <= 199;
		data[165] <= 200;
		data[166] <= 200;
		data[167] <= 201;
		data[168] <= 201;
		data[169] <= 202;
		data[170] <= 202;
		data[171] <= 203;
		data[172] <= 203;
		data[173] <= 204;
		data[174] <= 205;
		data[175] <= 205;
		data[176] <= 206;
		data[177] <= 206;
		data[178] <= 207;
		data[179] <= 207;
		data[180] <= 208;
		data[181] <= 208;
		data[182] <= 209;
		data[183] <= 210;
		data[184] <= 210;
		data[185] <= 211;
		data[186] <= 211;
		data[187] <= 212;
		data[188] <= 212;
		data[189] <= 213;
		data[190] <= 214;
		data[191] <= 214;
		data[192] <= 215;
		data[193] <= 215;
		data[194] <= 216;
		data[195] <= 217;
		data[196] <= 217;
		data[197] <= 218;
		data[198] <= 218;
		data[199] <= 219;
		data[200] <= 219;
		data[201] <= 220;
		data[202] <= 221;
		data[203] <= 221;
		data[204] <= 222;
		data[205] <= 222;
		data[206] <= 223;
		data[207] <= 224;
		data[208] <= 224;
		data[209] <= 225;
		data[210] <= 226;
		data[211] <= 226;
		data[212] <= 227;
		data[213] <= 227;
		data[214] <= 228;
		data[215] <= 229;
		data[216] <= 229;
		data[217] <= 230;
		data[218] <= 230;
		data[219] <= 231;
		data[220] <= 232;
		data[221] <= 232;
		data[222] <= 233;
		data[223] <= 234;
		data[224] <= 234;
		data[225] <= 235;
		data[226] <= 236;
		data[227] <= 236;
		data[228] <= 237;
		data[229] <= 237;
		data[230] <= 238;
		data[231] <= 239;
		data[232] <= 239;
		data[233] <= 240;
		data[234] <= 241;
		data[235] <= 241;
		data[236] <= 242;
		data[237] <= 243;
		data[238] <= 243;
		data[239] <= 244;
		data[240] <= 245;
		data[241] <= 245;
		data[242] <= 246;
		data[243] <= 247;
		data[244] <= 247;
		data[245] <= 248;
		data[246] <= 249;
		data[247] <= 249;
		data[248] <= 250;
		data[249] <= 251;
		data[250] <= 251;
		data[251] <= 252;
		data[252] <= 253;
		data[253] <= 253;
		data[254] <= 254;
		data[255] <= 255; 
	end
	else begin
		for(i=0;i<256;i=i+1) begin
			data[i] <= data[i];
		end
	end
end
endmodule