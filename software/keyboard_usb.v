module keyboard_usb      
(
	input wire rst,
	//KB_SPI
	input wire MOSI,
	input wire SCK,
	input wire CS,
	input wire LATCH,
	//PC Bus
	output wire PUSH, 
	output wire[6:0]PB //KEY DATA PORT
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
reg push = 1,shift = 1;
reg[6:0]KR;

always@(negedge LATCH or negedge rst)
	begin
		if(!rst)
			begin
				push <= 1;
				shift <= 1;
				KR[6:0] <= 0;			
			end
		else
			begin
				if(dat[15:8] == 8'h02 || dat[15:8] == 8'h0D) //Shift
					begin
						case(dat[7:0])
							8'h80: shift <= dat[9]; //SHIFT
							8'h83: shift <= dat[9]; //SHIFT
							default:;
						endcase
					end
				else if(dat[15:8] == 8'h04 || dat[15:8] == 8'h0B) //Control
					begin
						case(dat[7:0])
							//8'h81: ss <= dat[10]; //CTRL
							//8'h85: ss <= dat[10]; //CTRL
							default:;
						endcase
					end
				else
					begin
						case(dat[7:0])
							8'h04: 
								begin 
									if(shift) KR <= 7'h41;
									else KR <= 7'h61;
									push <= dat[8]; 
								end //A
							8'h05: 
								begin 
									if(shift) KR <= 7'h42; 
									else KR <= 7'h62;
									push <= dat[8]; 
								end //B
							8'h06: 
								begin 
									if(shift) KR <= 7'h43;
									else KR <= 7'h63;
									push <= dat[8];
								end //C
							8'h07: 
								begin 
									if(shift) KR <= 7'h44;
									else KR <= 7'h64;
									push <= dat[8]; 
								end //D
							8'h08: 
								begin 
									if(shift) KR <= 7'h45;
									else KR <= 7'h65;
									push <= dat[8]; 
								end //E
							8'h09: 
								begin 
									if(shift) KR <= 7'h46;
									else KR <= 7'h66;
									push <= dat[8]; 
								end //F
							8'h0A: 
								begin 
									if(shift) KR <= 7'h47;
								   else KR <= 7'h67;	
									push <= dat[8]; 
								end //G
							8'h0B: 
								begin 
									if(shift) KR <= 7'h48;
								   else KR <= 7'h68;	
									push <= dat[8]; 
								end //H
							8'h0C: 
								begin 
									if(shift) KR <= 7'h49;
								   else KR <= 7'h69;	
									push <= dat[8]; 
								end //I
							8'h0D: 
								begin 
									if(shift) KR <= 7'h4A; 
									else KR <= 7'h6A;
									push <= dat[8]; 
								end //J
							8'h0E: 
								begin 
									if(shift) KR <= 7'h4B; 
									else KR <= 7'h6B;
									push <= dat[8]; 
								end //K
							8'h0F: 
								begin 
									if(shift) KR <= 7'h4C;
									else KR <= 7'h6C;
									push <= dat[8]; 
								end //L
							8'h10: 
								begin 
									if(shift) KR <= 7'h4D; 
									else KR <= 7'h6D;
									push <= dat[8]; 
								end //M
							8'h11: 
								begin 
									if(shift) KR <= 7'h4E; 
									else KR <= 7'h6E;
									push <= dat[8]; 
								end //N
							8'h12: 
								begin 
									if(shift) KR <= 7'h4F; 
									else KR <= 7'h6F;
									push <= dat[8]; 
								end //O
							8'h13: 
								begin 
									if(shift) KR <= 7'h50; 
									else KR <= 7'h70;
									push <= dat[8]; 
								end //P
							8'h14: 
								begin 
									if(shift) KR <= 7'h51; 
									else KR <= 7'h71;
									push <= dat[8]; 
								end //Q
							8'h15: 
								begin 
									if(shift) KR <= 7'h52; 
									else KR <= 7'h72;
									push <= dat[8]; 
								end //R
							8'h16: 
								begin 
									if(shift) KR <= 7'h53; 
									else KR <= 7'h73;
									push <= dat[8]; 
								end //S
							8'h17: 
								begin 
									if(shift) KR <= 7'h54; 
									else KR <= 7'h74;
									push <= dat[8]; 
								end //T
							8'h18: 
								begin 
									if(shift) KR <= 7'h55; 
									else KR <= 7'h75;
									push <= dat[8]; 
								end //U
							8'h19: 
								begin 
									if(shift) KR <= 7'h56; 
									else KR <= 7'h76;
									push <= dat[8]; 
								end //V
							8'h1A: 
								begin 
									if(shift) KR <= 7'h57; 
									else KR <= 7'h77;
									push <= dat[8]; 
								end //W
							8'h1B: 
								begin 
									if(shift) KR <= 7'h58; 
									else KR <= 7'h78;
									push <= dat[8]; 
								end //X
							8'h1C: 
								begin 
									if(shift) KR <= 7'h59; 
									else KR <= 7'h79;
									if(shift) push <= dat[8]; 
								end //Y
							8'h1D: 
								begin 
									if(shift) KR <= 7'h5A; 
									else KR <= 7'h7A;
									push <= dat[8]; 
								end //Z
							8'h35: 
								begin 
									if(shift) KR <= 7'h60; 
									else KR <= 7'h7E;
									push <= dat[8]; 
								end //~
							8'h27: 
								begin 
									if(shift) KR <= 7'h30; 
									else KR <= 7'h29;
									push <= dat[8]; 
								end //0
							8'h1E: 
								begin 
									if(shift) KR <= 7'h31; 
									else KR <= 7'h21;
									push <= dat[8]; 
								end //1
							8'h1F: 
								begin 
									if(shift) KR <= 7'h32; 
									else KR <= 7'h40;
									push <= dat[8]; 
								end //2
							8'h20: 
								begin 
									if(shift) KR <= 7'h33; 
									else KR <= 7'h23;
									push <= dat[8]; 
								end //3
							8'h21: 
								begin 
									if(shift) KR <= 7'h34; 
									else KR <= 7'h24;
									push <= dat[8]; 
								end //4
							8'h22: 
								begin 
									if(shift) KR <= 7'h35; 
									else KR <= 7'h25;
									push <= dat[8]; 
								end //5
							8'h23: 
								begin 
									if(shift) KR <= 7'h36; 
									else KR <= 7'h5E;
									push <= dat[8]; 
								end //6
							8'h24: 
								begin 
									if(shift) KR <= 7'h37; 
									else KR <= 7'h26;
									push <= dat[8]; 
								end //7
							8'h25: 
								begin 
									if(shift) KR <= 7'h38; 
									else KR <= 7'h2A;
									push <= dat[8]; 
								end //8
							8'h26: 
								begin 
									if(shift) KR <= 7'h39; 
									else KR <= 7'h28;
									push <= dat[8]; 
								end //9
							8'h36: 
								begin 
									if(shift) KR <= 7'h2C; 
									else KR <= 7'h3C;
									push <= dat[8]; 
								end //,
							8'h37: 
								begin 
									if(shift) KR <= 7'h2E; 
									else KR <= 7'h3E;
									push <= dat[8]; 
								end //.
							8'h38: 
								begin 
									if(shift) KR <= 7'h2F;
									else KR <= 7'h3F;
									push <= dat[8]; 
								end //?/
							8'h33: 
								begin 
									if(shift) KR <= 7'h3B; 
									else KR <= 7'h3A;
									push <= dat[8]; 
								end //;
							8'h34: 
								begin 
									if(shift) KR <= 7'h27; 
									else KR <= 7'h22;
									push <= dat[8]; 
								end //'				
							8'h2F: 
								begin 
									if(shift) KR <= 7'h5B; 
									else KR <= 7'h7B;
									push <= dat[8]; 
								end //[
							8'h2E: 
								begin 
									if(shift) KR <= 7'h3D; 
									else KR <= 7'h2B;
									push <= dat[8]; 
								end //+
							8'h30: 
								begin 
									if(shift) KR <= 7'h5d; 
									else KR <= 7'h7D;
									push <= dat[8]; 
								end //]
							8'h31: 
								begin 
									if(shift) KR <= 7'h5C; 
									else KR <= 7'h7C;
									push <= dat[8]; 
								end //Obr SLASH
							8'h2D: 
								begin 
									if(shift) KR <= 7'h2D; 
									else KR <= 7'h5F;
									push <= dat[8]; 
								end //-
							//NUM PAD
							8'h62: begin KR <= 7'h30; push <= dat[8]; end //0
							8'h59: begin KR <= 7'h31; push <= dat[8]; end //1
							8'h5A: begin KR <= 7'h32; push <= dat[8]; end //2
							8'h5B: begin KR <= 7'h33; push <= dat[8]; end //3
							8'h5C: begin KR <= 7'h34; push <= dat[8]; end //4
							8'h5D: begin KR <= 7'h35; push <= dat[8]; end //5
							8'h5E: begin KR <= 7'h36; push <= dat[8]; end //6
							8'h5F: begin KR <= 7'h37; push <= dat[8]; end //7
							8'h60: begin KR <= 7'h38; push <= dat[8]; end //8
							8'h61: begin KR <= 7'h39; push <= dat[8]; end //9
							8'h56: begin KR <= 7'h2D; push <= dat[8]; end //-								
							8'h2A: begin KR <= 7'h08; push <= dat[8]; end //BKSPC	
							//Комбинации
							8'h2C: begin KR <= 7'h20; push <= dat[8]; end //SPACE
							8'h55: begin KR <= 7'h2A; push <= dat[8]; end //*
							8'h57: begin KR <= 7'h2B; push <= dat[8]; end //+
							8'h39: shift <= shift + ~dat[8]; //CAPS LOCK
							8'h28: begin KR <= 7'h0D; push <= dat[8]; end //ENTER
							8'h58: begin KR <= 7'h0D; push <= dat[8]; end //ENTER
							8'h29: begin KR <= 7'h1B; push <= dat[8]; end //ESCAPE
							8'h2B: begin KR <= 7'h09; push <= dat[8]; end //TAB
							8'h4C: begin KR <= 7'h7F; push <= dat[8]; end //DELETE
						endcase
					end
			end
	end	
	
	assign PB = KR;
	assign PUSH = push;

endmodule
