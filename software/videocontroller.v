module videocontroller(
	input wire rst,
	input wire pixclk,
	input wire hclk,
	//
	input wire[15:0]CPU_ADD,
	input wire[7:0] MAPPER,
	input wire[7:0]CPU_DO,
	input wire WM,
	//
	input wire[7:0]HSCROLL,
	input wire[7:0]VSCROLL,
	//HDMI
	output wire[2:0]tmds,
	output wire tmdsc,
	input wire color,
	input wire[2:0]palet,
	input wire[2:0]bkgnd
);

wire[7:0]R,G,B,Rx,Gx,Bx;
wire[10:0]HCNT,VCNT;
wire VISIBLE;

hdmi mhd(.pixclk(pixclk),.clk_TMDS(hclk),.n_rst(rst),.TMDSp(tmds),.TMDSp_clock(tmdsc),
		   .color(color),.red(R),.green(G),.blue(B),.visible(VISIBLE),.HCNT(HCNT),.VCNT(VCNT));

//VIDEORAM
wire[14:0]RD_ADD;
wire[7:0]VR_DO;
wire VR_RCLK,VR_WCLK,VR_WREN;			


//Simple dual port RAM
vram mvr(
	.data(CPU_DO),
	.rdaddress(RD_ADD),
	.rdclock(VR_RCLK),
	.wraddress(CPU_ADD[13:0]),
	.wrclock(VR_WCLK),
	.wren(VR_WREN),
	.q(VR_DO));

wire BORDER,BV_BORDER,C_BORDER;
wire[7:0]Rb,Gb,Bb;

assign BV_BORDER = (HCNT > 110 && HCNT < 622 && VCNT > 143 && VCNT < 401)? 1'b1 : 1'b0; //Nomochrome
assign C_BORDER = (HCNT > 222 && HCNT < 733 && VCNT > 66 && VCNT < 579)? 1'b1 : 1'b0; //COLOR
assign BORDER = (color)? C_BORDER : BV_BORDER;

//Гашение
assign R = (VISIBLE)? Rx : 8'h00;	
assign G = (VISIBLE)? Gx : 8'h00;	
assign B = (VISIBLE)? Bx : 8'h00;
//Бордюр
assign Rx = (BORDER)? Rb : 8'h0F;	
assign Gx = (BORDER)? Gb : 8'h0F;	
assign Bx = (BORDER)? Bb : 8'h0F;

wire[10:0]NHCNT,NVCNT;

assign NHCNT = (color)? (HCNT - 206) : (HCNT - 103);
assign NVCNT = (color)? (VCNT - 50 - 17) : (VCNT - 135 - 9);

//Автомат чтения данных знакоместа и шрифта
reg[7:0]tzd,zd;
reg vclk;

//Monochrome
always@(negedge pixclk or negedge rst)
	begin
		if(!rst)
			begin	
				zd <= 0;
				tzd <= 0;
				vclk <= 0;
			end
		else
			begin
				case(NHCNT[2:0])
					1: vclk <= 1'b1;
					4: vclk <= 1'b0;
					7: tzd <= VR_DO;
					0: zd <= tzd;
				endcase
			end
	end

//COLOR	
reg[15:0]tzdc,zdc;

always@(negedge pixclk or negedge rst)
	begin
		if(!rst)
			begin	
				zdc <= 0;
				tzdc <= 0;
			end
		else
			begin
				case(NHCNT[3:0])
					7: tzdc[7:0] <= VR_DO[7:0];
					14: tzdc[15:8] <= VR_DO[7:0];
					0: zdc <= tzdc;
				endcase
			end
	end
	
wire[7:0]VSCRL,MHVSCRL;
wire[5:0]HSCRL;
wire CS;
wire[3:0]MP;

assign VSCRL = NVCNT[8:1] + VSCROLL[7:0];
assign HSCRL = NHCNT[8:3];// + HSCROLL[5:0];
assign MHVSCRL = NVCNT[7:0] + VSCROLL[7:0];	
assign RD_ADD[13:0] = (color)? ({HSCRL,VSCRL}) : ({HSCRL,MHVSCRL}); //  - HSCROLL[7:1] - HSCROLL
assign VR_RCLK = ~vclk;
assign VR_WREN = ~WM;
assign MP[3:0] = {MAPPER[5:4],MAPPER[1:0]};
assign CS = ((MP == 4'b0100 && CPU_ADD[15:14] == 2'b11) || (MP == 4'b0001 && CPU_ADD[15:14] == 2'b01));
assign VR_WCLK = ~(pixclk & CS);

//Colors								R G B
parameter[23:0]BLACK = 		24'h000000;
parameter[23:0]WHITE = 		24'hFFFFFF;
parameter[23:0]RED   = 		24'hFF0000;
parameter[23:0]GREEN = 		24'h00FF00;
parameter[23:0]BGREEN = 	24'h0FFF0F;
parameter[23:0]DGREEN = 	24'h009999;
parameter[23:0]BLUE  = 		24'h0FDfFF;
parameter[23:0]LBLUE = 		24'h000000;
parameter[23:0]RASPB = 		24'hFF0F83;
parameter[23:0]YELLOW = 	24'hFFD70F;

wire[23:0]PALETTE[0:7][0:4];
//000
assign PALETTE[0][0] = BLACK;
assign PALETTE[0][1] = RED;
assign PALETTE[0][2] = GREEN;
assign PALETTE[0][3] = BLUE;
assign PALETTE[0][4] = WHITE;
//001
assign PALETTE[1][0] = WHITE;
assign PALETTE[1][1] = RED;
assign PALETTE[1][2] = GREEN;
assign PALETTE[1][3] = BLUE;
assign PALETTE[1][4] = RED;
//010
assign PALETTE[2][0] = RED;
assign PALETTE[2][1] = GREEN;
assign PALETTE[2][2] = LBLUE;
assign PALETTE[2][3] = YELLOW;
assign PALETTE[2][4] = GREEN;
//011
assign PALETTE[3][0] = DGREEN;
assign PALETTE[3][1] = YELLOW;
assign PALETTE[3][2] = GREEN;
assign PALETTE[3][3] = WHITE;
assign PALETTE[3][4] = BLUE;
//100
assign PALETTE[4][0] = BLACK;
assign PALETTE[4][1] = RED;
assign PALETTE[4][2] = YELLOW;
assign PALETTE[4][3] = BLUE;
assign PALETTE[4][4] = LBLUE;
//101
assign PALETTE[5][0] = BLACK;
assign PALETTE[5][1] = BLUE;
assign PALETTE[5][2] = GREEN;
assign PALETTE[5][3] = YELLOW;
assign PALETTE[5][4] = YELLOW;
//110
assign PALETTE[6][0] = GREEN;
assign PALETTE[6][1] = WHITE;
assign PALETTE[6][2] = YELLOW;
assign PALETTE[6][3] = BLUE;
assign PALETTE[6][4] = BGREEN;
//111
assign PALETTE[7][0] = BLACK;
assign PALETTE[7][1] = BLACK;
assign PALETTE[7][2] = BLACK;
assign PALETTE[7][3] = BLACK;
assign PALETTE[7][4] = BLACK;

wire[7:0]CRb,CGb,CBb,BRb,BGb,BBb;

//Вывод Ч/Б изображения
wire[23:0]BK;

assign BK =  PALETTE[palet][(bkgnd[2:0])];

assign BRb = (zd[((NHCNT[2:0]))])? PALETTE[palet][4][23:16] : BK[23:16];
assign BGb = (zd[((NHCNT[2:0]))])? PALETTE[palet][4][15:8]  : BK[15:8];
assign BBb = (zd[((NHCNT[2:0]))])? PALETTE[palet][4][7:0]   : BK[7:0];

//Цветное
assign CRb = PALETTE[palet][{zdc[(NHCNT[3:1])],zdc[(NHCNT[3:1])+8]}][23:16];
assign CGb = PALETTE[palet][{zdc[(NHCNT[3:1])],zdc[(NHCNT[3:1])+8]}][15:8];
assign CBb = PALETTE[palet][{zdc[(NHCNT[3:1])],zdc[(NHCNT[3:1])+8]}][7:0];

assign Rb = (color)? CRb : BRb;
assign Gb = (color)? CGb : BGb;
assign Bb = (color)? CBb : BBb;
			
endmodule
