module video_top #(
    parameter led_number = 6
)
(
    input             I_clk, //27Mhz
    input             I_rst_n,

    output [ led_number-1 :0] leds,

    input  [1:0]      BTN,

    input             uart_rx,
    output            uart_tx,

//    -- sdram magic ports 
    output            O_sdram_clk,
    output            O_sdram_cke,
    output            O_sdram_cs_n,
    output            O_sdram_cas_n,
    output            O_sdram_ras_n,
    output            O_sdram_wen_n,

    output    [10:0]  O_sdram_addr,
    inout     [31:0]  IO_sdram_dq,
    output     [1:0]  O_sdram_ba,
    output     [3:0]  O_sdram_dqm,

//    -- tmds
    output            O_tmds_clk_p,
    output            O_tmds_clk_n,
    output     [2:0]  O_tmds_data_p,
    output     [2:0]  O_tmds_data_n   
);

//==================================================
//--------------------------
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;


wire        vwe ;
wire        voe ;
wire        ble ;
wire        bhe ;
wire [15:0] vdatai;
wire [15:0] vdatao;
wire [16:0] vaddr;
wire [15:0] sdatao;
wire [15:0] fdatao;
wire [15:0] cdatao;

reg        rwe1 ;
reg        vwe1 ;
wire        voe1 ;
wire        ble1 ;
wire        bhe1 ;
reg [15:0] rx_addr;
reg [15:0] rx_cnt;
reg [7:0] rx_color;
reg [7:0] rx_type;
reg [15:0] addr_w;
reg [15:0] data_w;
reg [7:0] rx_mode;


wire[7:0]                        rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
reg[7:0]                         tx_data;
reg                              tx_data_valid;
wire                             tx_data_ready;

reg[31:0]                        wait_cnt;
reg[3:0]                         state;


//------------------------------------
//HDMI4 TX
wire rst_n;

wire pll_lock;
wire CLK_325MHz;
wire CLKp_325MHz;

wire CLK_5MHz;
wire CLK_65MHz;
wire CLK_162MHz;
wire CLK_108MHz;

wire cpu0_reset_n;
wire cpu0_clk;
wire [15:0] cpu0_a_bus;
wire [7:0] cpu0_do_bus;
wire [7:0] cpu0_di_bus;
wire cpu0_mreq_n;
wire cpu0_iorq_n;
wire cpu0_wr_n;
wire cpu0_rd_n;
wire cpu0_int_n;
wire cpu0_inta_n;
wire cpu0_m1_n;
wire cpu0_rfsh_n;
wire [1:0] cpu0_mult;
wire cpu0_mem_wr;
wire cpu0_mem_rd;
wire cpu0_nmi_n;

wire [11:0] a_busH;
wire [24:0] a_busFull;

wire [7:0] sdram_do_bus;
wire sdram_wr;
wire sdram_rd;
wire sdram_rfsh;
wire sdram_wait;

wire [7:0] rom_do_bus;

reg [5:0] ledram;

wire wr_vga;
wire io_vga;
wire io_map;

wire MEMWR   = cpu0_mreq_n | cpu0_wr_n;
wire MEMRD   = cpu0_mreq_n | cpu0_rd_n;
wire IOWR    = cpu0_iorq_n | cpu0_wr_n;
wire IORD    = cpu0_iorq_n | cpu0_rd_n;
wire MEMRAM  = (a_busH[11:4] !=  8'hFF);
wire MEMROM  = (a_busH       == 12'hFFF);

assign sdram_wr   = (MEMWR == 1'b0 && MEMRAM)                    ? 1'b0 : 1'b1;
assign sdram_rd   = (MEMRD == 1'b0 && MEMRAM)                    ? 1'b0 : 1'b1;
assign sdram_rfsh = (cpu0_mreq_n == 1'b0 && cpu0_rfsh_n == 1'b0) ? 1'b0 : 1'b1;

assign wr_vga = (MEMWR == 1'b0 && a_busH[11:4] == 8'b11111111 )  ? 1'b0 : 1'b1;
//assign wr_vga = (MEMWR == 1'b0 && cpu0_a_bus[15] == 1'b1)        ? 1'b0 : 1'b1;
//assign wr_vga = 1'b1;

assign io_vga = (IOWR  == 1'b0 && cpu0_a_bus[7:3] == 5'b11110)   ? 1'b0 : 1'b1;
assign io_map = (IOWR  == 1'b0 && cpu0_a_bus[7:3] == 5'b11111)   ? 1'b0 : 1'b1;

assign cpu0_di_bus = (MEMRD == 1'b0 && MEMROM) ? rom_do_bus : sdram_do_bus;

assign a_busFull = {a_busH, cpu0_a_bus[12:0] };
//==============================================================================
reg [23:0] count_1s = 'd0;
reg count_1s_flag;

always @(posedge I_clk ) begin
    if( count_1s < 27000 ) begin
        count_1s <= count_1s + 'd1;
        count_1s_flag <= 'd0;
    end
    else begin
        count_1s <= 'd0;
        count_1s_flag <= 'd1;
    end
end

always @(posedge I_clk ) begin
  if ( sdram_wr == 1'b0 ) begin
    ledram <= cpu0_a_bus[5:0];
  end
end

//assign leds = ~a_busH[5:0];
//assign leds = { 2'b0, O_sdram_cs_n, O_sdram_cas_n, O_sdram_ras_n, O_sdram_wen_n };
//assign leds = sdram_do_bus[5:0];
assign leds = cpu0_a_bus[5:0];

assign rst_n = I_rst_n & pll_lock & ~BTN[0];

//==============================================================================
//==============================================================================
vga u_vga(
    .clk		(CLK_65MHz    ),//pixel clock
    .RESET_n		(rst_n        ),//low active 

//    .CSMEM (wr_vga),
    .CSREG (io_vga),
    .CSMEM		(1'b1),
//    .CSREG		(1'b1),
    .A			({a_busH[3:0],cpu0_a_bus[12:0]}),
    .D			(cpu0_do_bus),

    .blank		(tp0_de_in      ),   
    .hsync		(tp0_hs_in      ),
    .vsync		(tp0_vs_in      ),
    .r			(tp0_data_r[7:5]),   
    .g			(tp0_data_g[7:5]),
    .b			(tp0_data_b[7:5]),

    .VDi		(vdatao),
    .VDo		(vdatai),
    .VA			(vaddr),
    .VWE		(vwe),
    .VOE		(voe),
    .BLE		(ble),
    .BHE		(bhe)
);


//==============================================================================

//==============================================================================
ram_screen u_vram(
    .clk		(~CLK_65MHz),//pixel clock

    .data_w		({ cpu0_do_bus, cpu0_do_bus }),
    .addr_w		({ a_busH[3:0], cpu0_a_bus[12:1] }),
    .we			(1'b1),
//    .we			(wr_vga),
    .le			( cpu0_a_bus[0]),
    .he			(~cpu0_a_bus[0]),

    .data_r		(sdatao),
    .addr_r		(vaddr[15:0])
);

//==============================================================================
ram_font u_fram(
    .clk		(~CLK_65MHz),//pixel clock

    .data_w		({ cpu0_do_bus, cpu0_do_bus }),
    .addr_w		({ a_busH[3:0], cpu0_a_bus[12:1] }),
    .we			(1'b1),
//    .we			(wr_vga),
    .le			( cpu0_a_bus[0]),
    .he			(~cpu0_a_bus[0]),

    .data_r		(fdatao),
    .addr_r		(vaddr[15:0])
);

//==============================================================================
ram_color u_cram(
    .clk		(~CLK_65MHz),//pixel clock

    .data_w		({ cpu0_do_bus, cpu0_do_bus }),
    .addr_w		({ a_busH[3:0], cpu0_a_bus[12:1] }),
    .we			(1'b1),
//    .we			(wr_vga),
    .le			( cpu0_a_bus[0]),
    .he			(~cpu0_a_bus[0]),

    .data_r		(cdatao),
    .addr_r		(vaddr[15:0])
);

assign vdatao = (vaddr[16] == 1'b1) ? fdatao : (vaddr[15:8] == 8'b11111111) ? cdatao : sdatao;

//==============================================================================
// Zilog Z80A CPU
T80a u_cpu(
    .CLK_n		(CLK_5MHz),
//    .CLK_n		(count_1s_flag),
    .RESET_n		(rst_n),

    .CEN		(1'b1),
//    .WAIT_n		(1'b1),
    .WAIT_n		(sdram_wait),
    .INT_n		(cpu0_int_n),
    .NMI_n		(cpu0_nmi_n),
    .BUSRQ_n		(1'b1),
    .M1_n		(cpu0_m1_n),

    .MREQ_n		(cpu0_mreq_n),
    .IORQ_n		(cpu0_iorq_n),
    .RD_n		(cpu0_rd_n),
    .WR_n		(cpu0_wr_n),
    .RFSH_n		(cpu0_rfsh_n),

    .A			(cpu0_a_bus),
    .DIN		(cpu0_di_bus),
    .DOUT		(cpu0_do_bus)
);

//==============================================================================
mapper u_mapper(
    .CLK		(CLK_65MHz),
    .RESET_n		(rst_n),

    .A			(cpu0_a_bus),
    .D			(cpu0_do_bus),
    .WR			(io_map),

    .Q			(a_busH)
);


//==============================================================================
rom u_rom(
    .clk		(CLK_65MHz),//pixel clock

    .data		(rom_do_bus),
    .addr		(cpu0_a_bus[12:0])
);


//==============================================================================
// RAM Controller
ram u_ram(
    .CLK		(CLK_65MHz),
    .CLK_MEM		(~CLK_65MHz),
    .RESET_n		(rst_n),

    // cpu signals
    .A			({a_busH[9:0], cpu0_a_bus[12:0]}),
    .DI			(cpu0_do_bus),
    .DO			(sdram_do_bus),
    .WR			(sdram_wr),
    .RD			(sdram_rd),
    .RFSH		(sdram_rfsh),
    .BUSY		(sdram_wait),

    // phy

    .O_sdram_clk	(O_sdram_clk),
    .O_sdram_cke	(O_sdram_cke),
    .O_sdram_cs_n	(O_sdram_cs_n),
    .O_sdram_cas_n	(O_sdram_cas_n),
    .O_sdram_ras_n	(O_sdram_ras_n),
    .O_sdram_wen_n	(O_sdram_wen_n),

    .O_sdram_addr	(O_sdram_addr),
    .IO_sdram_dq	(IO_sdram_dq),
    .O_sdram_ba		(O_sdram_ba),
    .O_sdram_dqm	(O_sdram_dqm)
    );


//==============================================================================
TMDS_rPLL u_rpll
(
    .clkin		(I_clk),	// 27 Mhz
    .clkout		(CLK_325MHz),	// 324 MHz
    .clkoutp		(CLKp_325MHz),	// 324 MHz phase shift 180 
    .clkoutd3		(CLK_108MHz),	// 108 MHz
    .lock		(pll_lock)	// output lock
);

//==============================================================================
CLKDIV u_clkdiv65
(
    .RESETN		(rst_n),
    .HCLKIN		(CLK_325MHz),	// 324 MHz
    .CLKOUT		(CLK_65MHz),	// 64.8 MHz
    .CALIB		(1'b1)
);
defparam u_clkdiv65.DIV_MODE="5";
defparam u_clkdiv65.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv162
(
    .RESETN		(rst_n),
    .HCLKIN		(CLK_325MHz),	// 324 MHz
    .CLKOUT		(CLK_162MHz),	// 162 MHz
    .CALIB		(1'b1)
);
defparam u_clkdiv162.DIV_MODE="2";
defparam u_clkdiv162.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv5
(
    .RESETN		(rst_n),
    .HCLKIN		(I_clk),	// 27 MHz
    .CLKOUT		(CLK_5MHz),	// 5.4 MHz
    .CALIB		(1'b1)
);
defparam u_clkdiv5.DIV_MODE="5";
defparam u_clkdiv5.GSREN="false";

//==============================================================================
//==============================================================================
DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n		(rst_n         ),  //asynchronous reset, low active
    .I_serial_clk	(CLK_325MHz    ),
    .I_rgb_clk		(CLK_65MHz     ),  //pixel clock

    .I_rgb_vs		(tp0_vs_in     ), 
    .I_rgb_hs		(tp0_hs_in     ),    
    .I_rgb_de		(tp0_de_in     ), 

    .I_rgb_r		(tp0_data_r    ),  //tp0_data_r
    .I_rgb_g		(tp0_data_g    ),  
    .I_rgb_b		(tp0_data_b    ),  

    .O_tmds_clk_p	(O_tmds_clk_p  ),
    .O_tmds_clk_n	(O_tmds_clk_n  ),
    .O_tmds_data_p	(O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n	(O_tmds_data_n )
);

//==============================================================================
parameter                        CLK_FRE  = 27;//Mhz
parameter                        UART_FRE = 115200;//Mhz

localparam                       IDLE =  0;
localparam                       RECV1 =  1;   //send 
localparam                       RECV2 =  2;   //send 
localparam                       RECV3 =  3;   //send 
localparam                       RECV4 =  4;   //send 
localparam                       RECV5 =  5;   //send 
localparam                       RECV_COLOR =  6;   //send 
localparam                       RECV_DATA =  7;   //send 
localparam                       RECV_DATA1 =  8;   //send 
localparam                       RECV_DATA2 =  9;   //send 
localparam                       RECV_DATA2a =  10;   //send 
localparam                       RECV_DATA3 =  11;   //send 
localparam                       RECV_NONE =  12;   //send 
localparam                       RECV_MODE =  13;   //send 

assign rx_data_ready = 1'b1;//always can receive data,


always@(posedge I_clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		state <= IDLE;
	end
	else
	begin
	wait_cnt <= wait_cnt + 32'd1;
	if(wait_cnt >= CLK_FRE * 10_000_000) // wait for 1 second
	begin
		vwe1 <= 1'b1;
		rwe1 <= 1'b1;
		state <= IDLE;
	end

	if(rx_data_valid == 1'b1)
	begin
		tx_data_valid <= 1'b1;
		tx_data <= rx_data;   // send uart received data
	end
	else if(tx_data_valid && tx_data_ready)
	begin
		tx_data_valid <= 1'b0;
	end

	case(state)
		IDLE:
			if (rx_data_valid == 1'b1 )
			begin
//			        count_1s_flag <= 'd1;
				wait_cnt <= 32'd0;
				rx_type <= rx_data;
				if(rx_data < 8'd48)
					state <= RECV1;
				else
				begin
					state <= RECV_MODE;
					rwe1 <= 1'b0;
					if(rx_data == 8'd48)
						rx_mode <= 8'b00000000;
					else
					if(rx_data == 8'd49)
						rx_mode <= 8'b00000001;
					else
					if(rx_data == 8'd50)
						rx_mode <= 8'b00000010;
					else
					if(rx_data == 8'd51)
						rx_mode <= 8'b00000011;
					else
					if(rx_data == 8'd52)
						rx_mode <= 8'b00000111;
					else
					if(rx_data == 8'd53)
						rx_mode <= 8'b00001111;
					else
					if(rx_data == 8'd54)
						rx_mode <= 8'b00010000;
				end
			end
		RECV_MODE:
		begin
			state <= IDLE;
			rwe1 <= 1'b1;
		end
		RECV1:
		begin
			if(rx_data_valid == 1'b1)
			begin
//			        count_1s_flag <= 'd0;
				rx_addr[7:0] <= rx_data;
				state <= RECV2;
			end
		end
		RECV2:
		begin
			if(rx_data_valid == 1'b1)
			begin
//			        count_1s_flag <= 'd1;
				rx_addr[15:8] <= rx_data;
				state <= RECV3;
			end
		end
		RECV3:
		begin
			if(rx_data_valid == 1'b1)
			begin
//			        count_1s_flag <= 'd0;
				rx_cnt[7:0] <= rx_data;
				state <= RECV4;
			end
		end
		RECV4:
		begin
			if(rx_data_valid == 1'b1)
			begin
//			        count_1s_flag <= 'd1;
				rx_cnt[15:8] <= rx_data;
				addr_w <= rx_addr;

				if(rx_type == 8'd1)
				begin
					state <= RECV_COLOR;
				end
				else
				if(rx_type == 8'd2)
				begin
					state <= RECV_DATA1;
				end
				else
					state <= RECV_NONE;
			end
		end
		RECV5:
		begin
			if(rx_data_valid == 1'b1)
			begin
			end
		end
		RECV_COLOR:
		begin
			if(rx_data_valid == 1'b1)
			begin
//			        count_1s_flag <= 'd0;
				data_w[15:8] <= rx_data;
				state <= RECV_DATA;
			end
		end
		RECV_DATA1:
		begin
			wait_cnt <= 32'd0;

			if(rx_data_valid == 1'b1)
			begin
				data_w[7:0] <= rx_data;
				state <= RECV_DATA2;
			end
		end
		RECV_DATA2:
		begin
			if(rx_data_valid == 1'b1)
			begin
				data_w[15:8] <= rx_data;
				vwe1 <= 1'b0;

				state <= RECV_DATA2a;
			end
		end
		RECV_DATA2a:
		begin
			vwe1 <= 1'b1;

			state <= RECV_DATA1;

			rx_cnt <= rx_cnt - 1'd1;
			addr_w <= addr_w + 16'd1;

			if ( rx_cnt == 1'd0 )
				state <= IDLE;
		end
		RECV_DATA:
		begin
			wait_cnt <= 32'd0;

			if(rx_data_valid == 1'b1)
			begin
				data_w[7:0] <= rx_data;
				vwe1 <= 1'b0;

				state <= RECV_DATA3;
			end
		end
		RECV_DATA3:
		begin
			vwe1 <= 1'b1;

			state <= RECV_DATA;

			rx_cnt <= rx_cnt - 1'd1;
			addr_w <= addr_w + 16'd1;

			if ( rx_cnt == 1'd0 )
				state <= IDLE;
		end
		RECV_NONE:
		begin
			if(rx_data_valid == 1'b1)
			begin
				state <= RECV_NONE;
			end
		end
		default:
			state <= IDLE;
	endcase
	end
end

//==============================================================================
uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (I_clk              ),
	.rst_n                      (rst_n              ),
	.rx_data                    (rx_data            ),
	.rx_data_valid              (rx_data_valid      ),
	.rx_data_ready              (rx_data_ready      ),
	.rx_pin                     (uart_rx            )
);

//==============================================================================
uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (I_clk              ),
	.rst_n                      (rst_n              ),
	.tx_data                    (tx_data            ),
	.tx_data_valid              (tx_data_valid      ),
	.tx_data_ready              (tx_data_ready      ),
	.tx_pin                     (uart_tx            )
);


endmodule