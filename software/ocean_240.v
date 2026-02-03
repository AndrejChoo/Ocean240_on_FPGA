module ocean_240(
	//Common
	input wire clk,
	input wire rst,
	//HDMI
	output wire[2:0]tmds,
	output wire tmdsc,
	//SRAM
	output wire[18:0]ER_ADD,
	inout wire[15:0]ER_D,
	output wire ER_CS,
	output wire ER_OE,
	output wire ER_WE,
	output wire ER_BH,
	output wire ER_BL,
	//USB_Keyboard
	input wire KB_MOSI,
	input wire KB_SCK,
	input wire KB_CS,
	input wire KB_LATCH,
	//SPI Flash
	output wire SPI_CS,
	output wire MOSI,
	output wire SCK,
	input wire MISO,
	//UART
	output wire UART_TX,
	input wire UART_RX,
	//BEEPPER
	output wire BEEP,
	//DEBUG
	input wire HOLD,
	input wire SW0,
	input wire SW1,
	output wire LED
);


//Clocking
wire CLK2_5,CLK5,CLK10,CLK20,CLK25,CLK125,CLK40,CLK200,CPU_CLK;

main_pll mpl(.inclk0(clk),.c0(CLK20),.c1(CLK25),.c2(CLK125),.c3(CLK40),.c4(CLK200));

reg[28:0] div;
always@(posedge CLK25) div <= div + 1;

assign CLK2_5 = div[2];
assign CLK5 = div[1];
assign CLK10 = div[0];
assign CPU_CLK = CLK2_5; //Ustanovka chastoty CPU

//CPU
wire[15:0]CPU_ADD;
wire[7:0]CPU_DI,CPU_DO,IO_DO;
wire MREQ,IORQ;
wire CRST;
//I8080
wire RM,WM,RIO,WIO,DBIN,WO,HLDA,SYNC,F1,F2;

assign CRST = (rst & HOLD & ~PROG);
assign F1 = div[2] & div[1];
assign F2 = ~div[2];

vm80a_core mcp
(
   .pin_clk(clk),
   .pin_f1(F1),
   .pin_f2(F2),
   .pin_reset(~CRST),
   .pin_a(CPU_ADD),
   .pin_dout(CPU_DO),
   .pin_din(CPU_DI),
   .pin_hold(1'b0),
   .pin_ready(1'b1),
   .pin_int(1'b0),
   .pin_wr_n(WO),
   .pin_dbin(DBIN),
	.pin_hlda(HLDA),
	.pin_sync(SYNC),
);

reg[7:0]i8080ctrl;
wire[7:0]CCTRL;

always@(negedge F1) if(SYNC == 1) i8080ctrl[7:0] <= CPU_DO[7:0];
	
assign CCTRL = i8080ctrl;

assign RIO = ~(DBIN & CCTRL[6]);
assign WIO = ~(CCTRL[4] & ~WO); 
assign RM = ~(DBIN & CCTRL[7]);
assign WM = ~(~CCTRL[4] & ~WO);

//SPI
wire[7:0]SPI_DO,SPI_DI;
wire SPI_START,SPI_RDY;

spi msp(
	.clk(clk),
	.rst(rst),
	.start(SPI_START),
	.miso(MISO),
	.DIN(SPI_DI),
	.mosi(MOSI),
	.sck(SCK),
	.bsy(SPI_RDY),
	.DOUT(SPI_DO)
);

//Programmer
wire PROGWE;
wire[1:0]PROG;
wire[18:0]PROGADD;
wire[15:0]PROGDO;
wire[7:0]SPI_DI_P;
wire SPI_CS_P,SPI_START_P;

programmer mpg(
	.clk(clk),
	.rst(rst),
	.PROG(PROG),
	.SRAMADD(PROGADD),
	.SRAMDO(PROGDO),
	.SRAMWE(PROGWE),
	.SPI_CS(SPI_CS_P),
	.SPISTART(SPI_START_P),
	.SPIDI(SPI_DI_P),
	.SPIDO(SPI_DO),
	.SPIRDY(SPI_RDY),
	);

/*
//Эмулятор контроллера дисковода ВГ93
wire[7:0]VG_DO,VG_SREG,VG_TRACK,VG_SECTOR;
wire SPI_CS_VG,SPI_START_VG;
wire[7:0]SPI_DI_VG;
wire[7:0]VG_CMD,VG_STATE,VG_P24H,VG_P25H;
wire[23:0]VG_SPI_ADD;

vg93 mfp(
	.clk(clk),
	.rst(rst),
	.CPU_DO(CPU_DO),
	.CPU_ADD(CPU_ADD[7:0]),
	.WIO(WIO),
	.RIO(RIO),
	.DO(VG_DO),
	.SREG(VG_SREG),
	.SECTOR(VG_SECTOR),
	.TRACK(VG_TRACK),
	.P24H(VG_P24H),
	.P25H(VG_P25H),
	.SPI_CS(SPI_CS_VG),
	.SPI_START(SPI_START_VG),
	.SPI_DI(SPI_DI_VG), //To SPI
	.SPI_DO(SPI_DO), //From SPI
	.SPI_RDY(SPI_RDY),
	//Debug
	.STATE(VG_STATE)
);
*/	

assign SPI_CS = SPI_CS_P;//(PROG)? SPI_CS_P : SPI_CS_VG;
assign SPI_START = SPI_START_P;//(PROG)? SPI_START_P : SPI_START_VG;
assign SPI_DI = SPI_DI_P;//(PROG)? SPI_DI_P : SPI_DI_VG;

					
//IO
reg[7:0]dio;
wire color;

//UART: PORTS 0xA0 - DATA, 0xA1 - CONTROL/STATUS
wire tx_start,tx_bsy;
assign tx_start = (CPU_ADD[7:0] == 8'hA0)? ~WIO : 1'b0;

//UART Tx
uart_tx mutx(.clk(clk),.rst(CRST),.start(tx_start),.DIN(CPU_DO),.tx(UART_TX),.bsy(tx_bsy));

//UART Tx
wire[7:0]UART_DO;
wire UART_LATCH,RST_ULATCH;
wire urx_rdy,utxint;

assign RST_ULATCH = (CPU_ADD[7:0]==8'hA1)? RIO : 1'b1;

latcher urxl(.clk(clk),.rst(CRST),.load(~UART_LATCH),.sbros(RST_ULATCH),.DELAY(32),.result(urx_rdy));
uart_rx murx(.clk(clk),.rx(UART_RX),.DOUT(UART_DO),.clock(UART_LATCH));

//Sys timer interrupt
wire systi,stint,RST_INT;
assign RST_INT = (CPU_ADD[7:0]==8'h80)? RIO : 1'b1;

/////////////////////////////////////SYSTEM TIMER///////////////////////////////////////
reg[7:0]P60_0H,P60_0L;
reg[7:0]P60_1H,P60_1L;
reg[7:0]P60_2H,P60_2L;
reg[5:0]P63_0,P63_1,P63_2;
reg[7:0]syst_mode;

reg[15:0]systimcnt;
reg[15:0]syst_ch1;
reg[15:0]syst_ch2;
reg hl_0;
reg hl_1;
reg hl_2;


always@(negedge WIO)
	begin
		if(CPU_ADD[7:0]==8'h63) syst_mode <= CPU_DO;
		if(CPU_ADD[7:0]==8'h60) 
			begin
				if(hl_0) P60_0H <= CPU_DO;
				else P60_0L <= CPU_DO;
				hl_0 <= hl_0 + 1;
			end
		if(CPU_ADD[7:0]==8'h61) 
			begin
				if(hl_1) P60_1H <= CPU_DO;
				else P60_1L <= CPU_DO;
				hl_1 <= hl_1 + 1;
			end
		if(CPU_ADD[7:0]==8'h62) 
			begin
				if(hl_2) P60_2H <= CPU_DO;
				else P60_2L <= CPU_DO;
				hl_2 <= hl_2 + 1;
			end
	end
	
always@(syst_mode)
	begin
		case(syst_mode[7:6])
			2'b00: P63_0[5:0] <= syst_mode[5:0];
			2'b01: P63_1[5:0] <= syst_mode[5:0];
			2'b10: P63_2[5:0] <= syst_mode[5:0];
			default:;
		endcase
	end

//CH0	
always@(posedge div[3])
	begin
		if({P60_0H,P60_0L} > 16'h0000)
			begin
				if(systimcnt < {P60_0H,P60_0L}) systimcnt <= systimcnt + 1;
				else systimcnt <= 0;
			end
	end

//CH1	
always@(posedge div[3])
	begin
		if({P60_1H,P60_1L} > 16'h0000)
			begin
				if(syst_ch1 < {P60_1H,P60_1L}) syst_ch1 <= syst_ch1 + 1;
				else syst_ch1 <= 0;
			end
	end
	
//CH2	
always@(posedge div[3])
	begin
		if({P60_2H,P60_2L} > 16'h0000)
			begin
				if(syst_ch2 < {P60_2H,P60_2L}) syst_ch2 <= syst_ch2 + 1;
				else syst_ch2 <= 0;
			end
	end
	
	
assign systi = (systimcnt[15:0] >= {P60_0H[7:0],P60_0L[7:1]})? 1'b1 : 1'b0;
///////////////////////////////////////////////////////////////////////////////

//Keyboard
wire[7:0]KPB;
wire PUSH,KBINT;
wire[7:0]KPBM;
wire PUSHM,KBINTM;
wire[7:0]KPBR;


//Приоритеты прерываний
wire[7:0]VI,VO;

//assign VI[7:0] = (SW0)? {3'b000,stint,1'b0,utxint,KBINTM,~CRST} : {3'b000,stint,1'b0,utxint,KBINT,~CRST};
//assign KPBR = (SW0)? KPBM[7:0] : {1'b0,KPB[6:0]};
assign VI[7:0] = {3'b000,stint,1'b0,utxint,KBINTM,~CRST};
assign KPBR = KPBM[7:0];


priority mprt(
	.clk(clk),
	.rst(CRST),
	.VI(VI),
	.VO(VO)
);


//latcher kbl(.clk(clk),.rst(CRST),.load(PUSH),.sbros(RST_INT | ~VO[1]),.DELAY(32'h5FFFFFFF),.result(KBINT)); //REL5
latcher kblm(.clk(clk),.rst(CRST),.load(PUSHM),.sbros(RST_INT | ~VO[1]),.DELAY(32'h10FFFF),.result(KBINTM)); //REL8
latcher stml(.clk(clk),.rst(CRST),.load(~systi),.sbros(RST_INT | ~VO[4]),.DELAY(255),.result(stint));	
latcher utxil(.clk(clk),.rst(CRST),.load(~urx_rdy),.sbros(RST_INT | ~VO[2]),.DELAY(255),.result(utxint));


//Read IO
reg t0_hl,t1_hl,t2_hl;

always@(negedge RIO)
	begin
		case(CPU_ADD[7:0])
			//8'h20: dio <= VG_SREG;
			//8'h21: dio <= VG_TRACK;
			//8'h22: dio <= VG_SECTOR;
			//8'h23: dio <= VG_DO;
			//8'h24: dio <= VG_P24H;
			//8'h25: dio <= VG_P25H;
			8'h40: dio <= KPBR[7:0];//Keyboard
			8'h60: 
				begin
					if(t0_hl) dio <= systimcnt[7:0];
					else  dio <= systimcnt[15:8];
					t0_hl <= t0_hl + 1;
				end
			8'h61: 
				begin
					if(t1_hl) dio <= syst_ch1[7:0];
					else  dio <= syst_ch1[15:8];
					t1_hl <= t1_hl + 1;
				end
			8'h62: 
				begin
					if(t2_hl) dio <= syst_ch2[7:0];
					else  dio <= syst_ch2[15:8];
					t2_hl <= t2_hl + 1;
				end
			8'h80: dio <= VO; //Interrupts
			8'hA0: dio <= UART_DO; //UART DATA
			8'hA1: dio <= {6'b000000,urx_rdy,~tx_bsy}; //UART STATUS
			default: dio <= 8'h00;
		endcase
	end
//////////////////////////////////////////////////////////////////////////////////

//Write IO
reg[7:0]kpb = 8'hFF; //Порт линии сканирования клавиатуры
reg[7:0]kpc = 8'hFF;
reg[7:0]mapper = 8'hFF;
reg[7:0]PE1H = 8'h00;
reg[7:0]PE2H = 8'h00;
reg[7:0]hscroll = 8'h00;
reg[7:0]vscroll = 8'h00;

always@(negedge WIO or negedge CRST)
	begin
		if(!CRST)
			begin
				kpb <= 8'hFF;
				kpc <= 8'hFF;
				mapper <= 8'hFF;
				PE1H <= 8'h00;
				PE2H <= 8'h00;
				hscroll = 8'h00;
				vscroll = 8'h00;
			end
		else
			begin
				case(CPU_ADD[7:0])
					8'h42: kpc <= CPU_DO; //Keyboard					
					8'hC0: vscroll <= CPU_DO;
					8'hC1: mapper <= CPU_DO; //Memory mapper
					8'hC2: hscroll <= CPU_DO;			
					8'hE1: PE1H <= CPU_DO;
					8'hE2: PE2H <= CPU_DO;
					default:;
				endcase
			end
	end					

assign color = PE1H[6];
assign BEEP = ~PE2H[3]; 

//Клавиатура ASCII для REL5
//keyboard_usb mkb(.rst(CRST),.MOSI(KB_MOSI),.SCK(KB_SCK),.CS(KB_CS),.LATCH(KB_LATCH),.PUSH(PUSH),.PB(KPB));

//Клавиатура для REL8
keyboard_usb_matrix mkbm(.clk(clk),.rst(CRST),.MOSI(KB_MOSI),.SCK(KB_SCK),.CS(KB_CS),
							   .LATCH(KB_LATCH),.PUSH(PUSHM),.PB(KPBM),.PC(kpc[4:0]));
								
					
//SRAM
wire[18:0]SRAM_ADD; 
wire[18:0]RAM_ADD,ROM_ADD;
wire[15:0] ER_DI; 
wire RAM_WE;
wire sr_hl;
		
assign RAM_ADD[14:0] = CPU_ADD[14:0];	
assign ROM_ADD[12:0] = CPU_ADD[12:0];
assign RAM_ADD[18:17] = mapper[3:2];
assign ROM_ADD[18:16] = {1'b0,SW1,SW0};
assign ROM_ADD[15:13] = {mapper[7:6],CPU_ADD[13]};
assign RAM_ADD[16:15] = (mapper[0])? {mapper[1],1'b1} : {mapper[1],CPU_ADD[15]};
assign sr_hl = ~((mapper[5]) | (~mapper[4] & CPU_ADD[15] & CPU_ADD[14]));

assign SRAM_ADD[18:0] = (mapper[5])? {1'b0,SW1,SW0,3'b001,CPU_ADD[12:0]} : ((sr_hl)? RAM_ADD[18:0] : ROM_ADD[18:0]);
assign RAM_WE = (sr_hl)? WM : 1'b1;
assign ER_ADD[18:0] = (PROG)? PROGADD[18:0] : {SRAM_ADD[18:0]};
assign ER_D[15:0] = (ER_WE == 0)? ER_DI : 16'bzzzzzzzz;

assign ER_DI[7:0] = (PROG)? PROGDO[7:0] : 8'hFF;
assign ER_DI[15:8] =(PROG)? PROGDO[15:8] : CPU_DO[7:0];

assign ER_WE = (PROG)? PROGWE : ((sr_hl)? RAM_WE : 1'b1);
assign ER_OE = (PROG)? 1'b1 : RM;
assign ER_CS = (PROG)? 1'b0 : (WM & RM);
assign ER_BH = (PROG)? 1'b0 : ((sr_hl)? 1'b0 : 1'b1);
assign ER_BL = (PROG)? 1'b0 : ((sr_hl)? 1'b1 : 1'b0);


//Videoprocessor
wire PIXCLK,HCLK;

assign PIXCLK = (color)? CLK40 : CLK25;
assign HCLK = (color)? CLK200 : CLK125;

videocontroller mvc(
	.rst(rst),
	.pixclk(PIXCLK),
	.hclk(HCLK),
	.CPU_ADD(CPU_ADD),
	.MAPPER(mapper),
	.CPU_DO(CPU_DO),
	.WM(WM),
	.HSCROLL(hscroll),
	.VSCROLL(vscroll),
	.tmds(tmds),
	.tmdsc(tmdsc),
	.color(color),
	.palet(PE1H[2:0]),
	.bkgnd(PE1H[5:3])
);


//CPU DATA IN
wire[7:0]MEM_DO;

assign MEM_DO = (sr_hl)? ER_D[15:8] : ER_D[7:0];
assign CPU_DI = (RM==0)? MEM_DO : ((RIO==0)? dio : 8'h00);

endmodule




//Установка и сброс запроса прерывания
module latcher(
	input wire clk,	
	input wire rst,
	input wire load,
	input wire sbros,
	input wire[31:0]DELAY,
	output result 
);

reg irq;
reg[2:0] state;
reg[31:0]delay;

always@(posedge clk or negedge rst)
	begin
		if(!rst)
			begin
				irq <= 0;
				state <= 0;
				delay <= 0;
			end
		else
			begin
				if(delay > 0) delay <= delay - 1;
				case(state)
					0:
						begin
							if(!load) state <= 1;
							else state <= 0;
						end
					1:
						begin
							irq <= 1;
							state <= 2;
						end
					2:
						begin
							if(!sbros) state <= 3;
							else state <= 2;
						end
					3:
						begin
							if(sbros) 
								begin
									irq <= 0;
									state <= 4;
									delay <= DELAY; //32'h5FFFFFFF;
								end
							else state <= 3;
						end
					4:
						begin
							if(load == 1 || delay == 0)state <= 5;
							else state <= 4;
						end
					5:
						begin
							delay <= 0;
							state <= 0;
						end
				endcase
			end
	end
	
assign result = irq;

endmodule

//Расстановщик приоритетов
module priority(
	input wire clk,
	input wire rst,
	input wire[7:0]VI,
	output wire[7:0]VO
);

reg[7:0]vo;

always@(posedge clk or negedge rst)
	begin
		if(!rst) vo <= 0;
		else
			begin
					if(VI[0]==1) vo <= 8'b00000001;
					else if(VI[1:0]==2'b10) vo <= 8'b00000010;
					else if(VI[2:0]==3'b100) vo <= 8'b00000100;
					else if(VI[3:0]==4'b1000) vo <= 8'b00001000;
					else if(VI[4:0]==5'b10000) vo <= 8'b00010000;
					else if(VI[5:0]==6'b100000) vo <= 8'b00100000;
					else if(VI[6:0]==7'b1000000) vo <= 8'b01000000;
					else if(VI[7:0]==8'b10000000) vo <= 8'b10000000;
					else vo <= 8'b00000000;
			end
	end
	
assign VO = vo;

endmodule









