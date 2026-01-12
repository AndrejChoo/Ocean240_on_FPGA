module keyboard_usb_matrix     
(
	input wire clk,
	input wire rst,
	//KB_SPI
	input wire MOSI,
	input wire SCK,
	input wire CS,
	input wire LATCH,
	//PC Bus
	input wire[4:0]PC, //SCAN ADDRESS PORT
	output wire[7:0]PB, //KEY DATA PORT
	output wire PUSH,
	//Debug
	output wire LED
);

//SPI
reg[15:0]tdat,dat;
reg[3:0]scnt;

//Debug
reg[15:0] ld;

always@(negedge rst or posedge SCK)
	begin
		if(!rst)
			begin
				tdat <= 0;
			end
		else
			begin
				tdat[(15-scnt[3:0])] <= MOSI;
			end
	end
	
always@(posedge LATCH or negedge SCK)
	begin
		if(LATCH)
			begin
				scnt <= 0;
			end	
		else
			begin
				scnt <= scnt + 1;
			end	
	end

always@(posedge CS) dat <= tdat;

//Process data
reg push = 1;
reg[87:0]KR;
integer i;


always@(negedge LATCH or negedge rst)
	begin
		if(!rst)
			begin
				push <= 1;
				for(i = 0; i <88; i = i + 1) KR[i] <= 1'b1;
							
			end
		else
			begin
				if(dat[15:8] == 8'h02 || dat[15:8] == 8'h0D) //Shift
					begin
						case(dat[7:0])
							8'h80: begin KR[3] <= dat[9]; push <= dat[9]; end //SHIFT
							8'h83: begin KR[3] <= dat[9]; push <= dat[9]; end //SHIFT
						endcase
					end
				else if(dat[15:8] == 8'h04 || dat[15:8] == 8'h0B) //Control
					begin
						case(dat[7:0])
							/*
							8'h81: ss <= dat[10]; //CTRL
							8'h85: ss <= dat[10]; //CTRL
							*/
							8'h27: KR[0] <= dat[10]; //CTRL
						endcase
					end
				else
					begin
						case(dat[7:0])

							//8'h81: ss <= dat[8]; //CTRL
							8'h52: begin KR[57] <= dat[8]; push <= dat[8]; end //UP
							8'h4F: begin KR[50] <= dat[8]; push <= dat[8]; end //RIGHT
							8'h50: begin KR[75] <= dat[8]; push <= dat[8]; end //LEFT
							8'h51: begin KR[58] <= dat[8]; push <= dat[8]; end //DOWN

							8'h04: begin KR[44] <= dat[8]; push <= dat[8]; end //A
							8'h05: begin KR[76] <= dat[8]; push <= dat[8]; end //B
							8'h06: begin KR[29] <= dat[8]; push <= dat[8]; end //C
							8'h07: begin KR[85] <= dat[8]; push <= dat[8]; end //D
							8'h08: begin KR[54] <= dat[8]; push <= dat[8]; end //E					
							8'h09: begin KR[21] <= dat[8]; push <= dat[8]; end //F
							8'h0A: begin KR[69] <= dat[8]; push <= dat[8]; end //G
							8'h0B: begin KR[73] <= dat[8]; push <= dat[8]; end //H
							8'h0C: begin KR[52] <= dat[8]; push <= dat[8]; end //I
							8'h0D: begin KR[22] <= dat[8]; push <= dat[8]; end //J
							8'h0E: begin KR[45] <= dat[8]; push <= dat[8]; end //K
							8'h0F: begin KR[77] <= dat[8]; push <= dat[8]; end //L
							8'h10: begin KR[43] <= dat[8]; push <= dat[8]; end //M
							8'h11: begin KR[61] <= dat[8]; push <= dat[8]; end //N
							8'h12: begin KR[68] <= dat[8]; push <= dat[8]; end //O
							8'h13: begin KR[53] <= dat[8]; push <= dat[8]; end //P
							8'h14: begin KR[20] <= dat[8]; push <= dat[8]; end //Q
							8'h15: begin KR[60] <= dat[8]; push <= dat[8]; end //R
							8'h16: begin KR[35] <= dat[8]; push <= dat[8]; end //S
							8'h17: begin KR[59] <= dat[8]; push <= dat[8]; end //T
							8'h18: begin KR[37] <= dat[8]; push <= dat[8]; end //U
							8'h19: begin KR[82] <= dat[8]; push <= dat[8]; end //V
							8'h1A: begin KR[36] <= dat[8]; push <= dat[8]; end //W
							8'h1B: begin KR[67] <= dat[8]; push <= dat[8]; end //X
							8'h1C: begin KR[28] <= dat[8]; push <= dat[8]; end //Y
							8'h1D: begin KR[81] <= dat[8]; push <= dat[8]; end //Z
							
							8'h27: begin KR[72] <= dat[8]; push <= dat[8]; end //0
							8'h1E: begin KR[30] <= dat[8]; push <= dat[8]; end //1
							8'h1F: begin KR[38] <= dat[8]; push <= dat[8]; end //2
							8'h20: begin KR[46] <= dat[8]; push <= dat[8]; end //3
							8'h21: begin KR[55] <= dat[8]; push <= dat[8]; end //4
							8'h22: begin KR[62] <= dat[8]; push <= dat[8]; end //5
							8'h23: begin KR[70] <= dat[8]; push <= dat[8]; end //6
							8'h24: begin KR[79] <= dat[8]; push <= dat[8]; end //7
							8'h25: begin KR[87] <= dat[8]; push <= dat[8]; end //8
							8'h26: begin KR[80] <= dat[8]; push <= dat[8]; end //9
							//NUM PAD

							8'h62: begin KR[72] <= dat[8]; push <= dat[8]; end //0
							8'h59: begin KR[30] <= dat[8]; push <= dat[8]; end //1
							8'h5A: begin KR[38] <= dat[8]; push <= dat[8]; end //2
							8'h5B: begin KR[46] <= dat[8]; push <= dat[8]; end //3
							8'h5C: begin KR[55] <= dat[8]; push <= dat[8]; end //4
							8'h5D: begin KR[62] <= dat[8]; push <= dat[8]; end //5
							8'h5E: begin KR[70] <= dat[8]; push <= dat[8]; end //6
							8'h5F: begin KR[79] <= dat[8]; push <= dat[8]; end //7
							8'h60: begin KR[87] <= dat[8]; push <= dat[8]; end //8
							8'h61: begin KR[80] <= dat[8]; push <= dat[8]; end //9
							
							8'h29: begin KR[15] <= dat[8]; push <= dat[8]; end //ESCAPE
							8'h36: begin KR[83] <= dat[8]; push <= dat[8]; end //,
							8'h37: begin KR[66] <= dat[8]; push <= dat[8]; end //.
							8'h2A: begin KR[42] <= dat[8]; push <= dat[8]; end //BKSPC
							8'h2D: begin KR[64] <= dat[8]; push <= dat[8]; end //-
							8'h56: begin KR[64] <= dat[8]; push <= dat[8]; end //-
							8'h33: begin KR[23] <= dat[8]; push <= dat[8]; end //;
							/*8'h38: KR[15] <= dat[8]; //?/
							
							8'h45: us <= dat[10]; //F12
							8'h52: KR[16] <= dat[8]; //@					
							8'h2F: KR[43] <= dat[8]; //[
							
							8'h39: KR[54] <= dat[8]; //CAPS LOCK
							*/
							8'h28: begin KR[49] <= dat[8]; push <= dat[8]; end //ENTER
							8'h58: begin KR[49] <= dat[8]; push <= dat[8]; end //ENTER
							8'h35: begin KR[65] <= dat[8]; push <= dat[8]; end //~
							/*
							8'h30: KR[45] <= dat[8]; //]
							8'h31: KR[44] <= dat[8]; //\
							*/								
							
							//Комбинации
							8'h2C: begin KR[51] <= dat[8]; push <= dat[8]; end //SPACE
							//8'h55: begin KR[65] <= dat[8]; push <= dat[8]; end //*
							8'h57: begin KR[3] <= dat[8]; KR[23] <= dat[8]; push <= dat[8]; end //+
							8'h2E: begin KR[3] <= dat[8]; KR[64] <= dat[8]; push <= dat[8]; end //=
							8'h34: begin KR[3] <= dat[8]; KR[79] <= dat[8]; push <= dat[8]; end //'
							
						endcase
					end
			end
	end


//Дешифратор линий сканирования
reg[10:0]line;
	
always@(posedge clk)
	begin
		case(PC[4:0])
			5'b00000: line <= 11'b11111111110; //0
			5'b00001: line <= 11'b11111111101; //1
			5'b00010: line <= 11'b11111111011; //2
			5'b00011: line <= 11'b11111110111; //3
			5'b00100: line <= 11'b11111101111; //4
			5'b00101: line <= 11'b11111011111; //5
			5'b00110: line <= 11'b11110111111; //6
			5'b00111: line <= 11'b11101111111; //7
			5'b01000: line <= 11'b11011111111; //8
			5'b01001: line <= 11'b10111111111; //9 
			default:  line <= 11'b01111111111; //10
		endcase
	end


assign PB[0] = ((line[0]|KR[0])&(line[1]|KR[8])&(line[2]|KR[16])&(line[3]|KR[24])&(line[4]|KR[32])&
						(line[5]|KR[40])&(line[6]|KR[48])&(line[7]|KR[56])&(line[8]|KR[64])&(line[9]|KR[72])&
							(line[10]|KR[80]));
							
assign PB[1] = ((line[0]|KR[1])&(line[1]|KR[9])&(line[2]|KR[17])&(line[3]|KR[25])&(line[4]|KR[33])&
						(line[5]|KR[41])&(line[6]|KR[49])&(line[7]|KR[57])&(line[8]|KR[65])&(line[9]|KR[73])&
							(line[10]|KR[81]));
							
assign PB[2] = ((line[0]|KR[2])&(line[1]|KR[10])&(line[2]|KR[18])&(line[3]|KR[26])&(line[4]|KR[34])&
						(line[5]|KR[42])&(line[6]|KR[50])&(line[7]|KR[58])&(line[8]|KR[66])&(line[9]|KR[74])&
							(line[10]|KR[82]));
							
assign PB[3] = ((line[0]|KR[3])&(line[1]|KR[11])&(line[2]|KR[19])&(line[3]|KR[27])&(line[4]|KR[35])&
						(line[5]|KR[43])&(line[6]|KR[51])&(line[7]|KR[59])&(line[8]|KR[67])&(line[9]|KR[75])&
							(line[10]|KR[83]));
							
assign PB[4] = ((line[0]|KR[4])&(line[1]|KR[12])&(line[2]|KR[20])&(line[3]|KR[28])&(line[4]|KR[36])&
						(line[5]|KR[44])&(line[6]|KR[52])&(line[7]|KR[60])&(line[8]|KR[68])&(line[9]|KR[76])&
							(line[10]|KR[84]));
							
assign PB[5] = ((line[0]|KR[5])&(line[1]|KR[13])&(line[2]|KR[21])&(line[3]|KR[29])&(line[4]|KR[37])&
						(line[5]|KR[45])&(line[6]|KR[53])&(line[7]|KR[61])&(line[8]|KR[69])&(line[9]|KR[77])&
							(line[10]|KR[85]));
							
assign PB[6] = ((line[0]|KR[6])&(line[1]|KR[14])&(line[2]|KR[22])&(line[3]|KR[30])&(line[4]|KR[38])&
						(line[5]|KR[46])&(line[6]|KR[54])&(line[7]|KR[62])&(line[8]|KR[70])&(line[9]|KR[78])&
							(line[10]|KR[86]));
							
assign PB[7] = ((line[0]|KR[7])&(line[1]|KR[15])&(line[2]|KR[23])&(line[3]|KR[31])&(line[4]|KR[39])&
						(line[5]|KR[47])&(line[6]|KR[55])&(line[7]|KR[63])&(line[8]|KR[71])&(line[9]|KR[79])&
							(line[10]|KR[87]));


//assign PB[7:0] = (PC[3:0] < 10)? (KR[(PC[3:0])][7:0]) : ((PC[4])? (KR[10][7:0]) : 8'hFF);						
							
assign PUSH = push;
assign LED = push;

endmodule

