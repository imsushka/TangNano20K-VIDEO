module video_top (
  input		CLK_27MHz, //27Mhz

  input  [1:0]	BTN,

  output [5:0]	leds,

  input		uart_rx,
  output	uart_tx,

//  -- sdram magic ports 
  output	O_sdram_clk,
  output	O_sdram_cke,
  output	O_sdram_cs_n,
  output	O_sdram_cas_n,
  output	O_sdram_ras_n,
  output	O_sdram_wen_n,

  output [10:0]	O_sdram_addr,
  inout  [31:0]	IO_sdram_dq,
  output [1:0]	O_sdram_ba,
  output [3:0]	O_sdram_dqm,

//  -- sd interface
//    output            sd_clk,
//    inout             sd_cmd,      // MOSI
//    inout      [3:0]  sd_dat,      // MISO
//    output            sd_dat1,     // 1
//    output            sd_dat2,     // 1
//    output            sd_dat3,     // 1

  output	SD_CS,		// CS
  output	SD_SCK,		// SCLK
  output	SD_CMD,		// MOSI
  input		SD_DAT0,	// MISO
  input		SD_DAT1,	// MISO
  input		SD_DAT2,	// MISO

//audio
  output	HP_BCK,
  output	HP_WS,
  output	HP_DIN,
  output	PA_EN,

//  output	WS2812,
//  -- tmds
  output	O_tmds_clk_p,
  output	O_tmds_clk_n,
  output [2:0]	O_tmds_data_p,
  output [2:0]	O_tmds_data_n   
);

//==================================================
// SYSTEM
//==================================================
reg cpu_rst_n;

wire rst_n;
wire pll_lock;
wire CLK_325MHz;
wire CLKp_325MHz;

wire CLK_1MHz;
wire CLK_2MHz;
wire CLK_3MHz;
wire CLK_5MHz;
wire CLK_7MHz;
wire CLK_10MHz;
wire CLK_20MHz;
wire CLK_65MHz;
wire CLK_108MHz;
wire CLK_162MHz;

//==================================================
// HDMI
//==================================================
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;

//==================================================
// UART
//==================================================
wire [7:0]  USART_RXD;
reg         USART_RXS_valid;
wire        USART_RXS_ready;

//wire [7:0]  rx_data_buf;
wire        USART_RXS_valid_;

reg  [7:0]  USART_TXD;
reg         USART_TXS_valid;
wire        USART_TXS_ready;

//==================================================
// VGA
//==================================================
wire        vwe ;
wire        voe ;
wire        ble ;
wire        bhe ;
wire [7:0]  vdatai;
wire [15:0] vdatao;
wire [17:0] vaddr;
wire [17:0] vaddr1;
wire [15:0] mdatao;
wire [15:0] sdatao;
wire [15:0] fdatao;
wire [15:0] spdatao;

//==================================================
// CPU tZ80
//==================================================
//wire        cpu_reset_n;
wire        cpu_clk;
wire [15:0] cpu_a_bus;
wire [7:0]  cpu_do_bus;
wire [7:0]  cpu_di_bus;
wire        cpu_mreq_n;
wire        cpu_iorq_n;
wire        cpu_wr_n;
wire        cpu_rd_n;
reg         cpu_int_n;
wire        cpu_inta_n;
wire        cpu_m1_n;
wire        cpu_rfsh_n;
wire [1:0]  cpu_mult;
wire        cpu_mem_wr;
wire        cpu_mem_rd;
wire        cpu_nmi_n;

//==================================================
// SDRAM
//==================================================
wire        sdram_wr;
wire        sdram_rd;
wire        sdram_rfsh;
wire        sdram_wait;
wire [7:0]  sdram_do_bus;
wire [7:0]  romF_do_bus;
wire [7:0]  romE_do_bus;

//==================================================
// SD
//==================================================
wire [7:0]  SD_RX_data;
reg  [7:0]  SD_TX_data;

//==================================================
// 
//==================================================
wire [11:0] map_a_bus;
//wire [24:0] a_busFull;

//==================================================
// 
//==================================================
wire [7:0]  AY_data0;
wire [7:0]  AY_data1;
wire [15:0]  audio_in;

wire [7:0]  ay0_a;
wire [7:0]  ay0_b;
wire [7:0]  ay0_c;
wire [7:0]  ay1_a;
wire [7:0]  ay1_b;
wire [7:0]  ay1_c;
wire [13:0]  sn_mix0;
wire [13:0]  sn_mix1;

//==================================================
// 
//==================================================
//wire inta;
reg  [7:0] irq_;
//wire int_n;
wire IRQ0 = 1'b1;
wire IRQ1 = 1'b1;
wire IRQ2 = 1'b1;
wire IRQ3 = 1'b1;
wire IRQ4 = 1'b1;
wire IRQ5 = 1'b1;
wire IRQ6 = 1'b1;
wire IRQ7 = 1'b1;
reg  IRQ0_; //= 1'b1;
reg  IRQ1_; //= 1'b1;
reg  IRQ2_; //= 1'b1;
reg  IRQ3_; //= 1'b1;
reg  IRQ4_; //= 1'b1;
reg  IRQ5_; //= 1'b1;
reg  IRQ6_; //= 1'b1;
reg  IRQ7_; //= 1'b1;


reg [7:0]  count_rst;

wire        vga_wrF;
wire        vgaS_wr;
wire        vga_wrM;
wire        vga_wrS;
wire        o_vga;
wire        o_vga_pal;
wire        o_map;
wire        i_uart;
wire        o_uart;
wire        i_sd;
wire        o_sd;
wire        i_ay;
wire        i_ym;

//==================================================
// 
//==================================================
wire        blank;
wire        hact;
wire        vact;
wire [3:0]  color;
wire [8:0]  s_color;
wire [8:0]  m_color;
wire [5:0]  b_color;
wire [7:0]  sp_color;
wire [17:0]  rgb;
wire [31:0]  control;
wire [7:0]  hscrollm;
wire [6:0]  vscrollm;
wire [7:0]  hscrolls;
wire [6:0]  vscrolls;
wire [7:0]  hscrollb;
wire [6:0]  vscrollb;
wire [6:0]  hcursor;
wire [6:0]  vcursor;
wire [11:0]  h;
wire [11:0]  v;
wire [2:0]  animat;
wire [5:0]  m_split0;
wire [6:0]  m_split1;
wire [5:0]  s_split0;
wire [6:0]  s_split1;
wire [5:0]  b_split0;
wire [6:0]  b_split1;


wire [17:0] spr_addr;
wire [15:0] spr_data;
wire [15:0] spr_dataF;
wire [15:0] spr_datao;

wire [8:0]  lb0_a;
wire [8:0]  lb1_a;
wire [15:0] lb0_di;
wire [15:0] lb0_do;
wire [15:0] lb1_di;
wire [15:0] lb1_do;

wire [7:0]  oam_addr;
wire [63:0] oam_di;
wire [63:0] oam_do;
wire        oam_we;
wire        oam_oe;
wire        oam_ble;
wire        oam_bhe;

wire        lb1_we;
wire        lb0_we;
wire        lb1_ble;
wire        lb0_ble;
wire        lb1_bhe;
wire        lb0_bhe;

//==================================================
// 
//==================================================
wire MEMWR   = (cpu_mreq_n | cpu_wr_n);
wire MEMRD   = (cpu_mreq_n | cpu_rd_n);
wire IOWR    = (cpu_iorq_n | cpu_wr_n);
wire IORD    = (cpu_iorq_n | cpu_rd_n);
wire IORQ    = (cpu_iorq_n == 1'b0);

wire MEMRAM  = (map_a_bus[11:10] ==  2'b10          );

wire MEMVGA  = (map_a_bus[11:4]  ==  8'b11000000    );
wire MEMVGAF = (map_a_bus[11:4]  ==  8'b11000001    );
wire MEMVGAS = (map_a_bus[11:4]  ==  8'b11000010    );
wire MEMVGAT = (map_a_bus[11:4]  ==  8'b11000011    );

wire MEMROM8 = (map_a_bus        == 12'b111111111000);
wire MEMROM9 = (map_a_bus        == 12'b111111111001);
wire MEMROMA = (map_a_bus        == 12'b111111111010);
wire MEMROMB = (map_a_bus        == 12'b111111111011);
wire MEMROMC = (map_a_bus        == 12'b111111111100);
wire MEMROMD = (map_a_bus        == 12'b111111111101);
wire MEMROME = (map_a_bus        == 12'b111111111110);
wire MEMROMF = (map_a_bus        == 12'b111111111111);

wire IO_C0   = (cpu_a_bus[7:1] == 7'b1100_000);
wire IO_C2   = (cpu_a_bus[7:1] == 7'b1100_001);
wire IO_C4   = (cpu_a_bus[7:1] == 7'b1100_010);
wire IO_C8   = (cpu_a_bus[7:1] == 7'b1100_100);
wire IO_CA   = (cpu_a_bus[7:1] == 7'b1100_101);
wire IO_CC   = (cpu_a_bus[7:1] == 7'b1100_110);
wire IO_CE   = (cpu_a_bus[7:1] == 7'b1100_111);

wire IO_D0   = (cpu_a_bus[7:2] == 6'b1101_00 );
wire IO_D4   = (cpu_a_bus[7:2] == 6'b1101_01 );
wire IO_D8   = (cpu_a_bus[7:2] == 6'b1101_10 );
wire IO_DC   = (cpu_a_bus[7:2] == 6'b1101_11 );

wire IO_E0   = (cpu_a_bus[7:3] == 5'b1110_0  );
wire IO_E8   = (cpu_a_bus[7:3] == 5'b1110_1  );
wire IO_F0   = (cpu_a_bus[7:3] == 5'b1111_0  );
wire IO_F8   = (cpu_a_bus[7:3] == 5'b1111_1  );

wire IOSN0   = ( IO_C8 && IORQ && (cpu_a_bus[0] == 1'b0) ) ? 1'b0 : 1'b1;
wire IOSN1   = ( IO_C8 && IORQ && (cpu_a_bus[0] == 1'b1) ) ? 1'b0 : 1'b1;
wire IOAY0   = ( IO_CA && IORQ ) ? 1'b0 : 1'b1;
wire IOAY1   = ( IO_CC && IORQ ) ? 1'b0 : 1'b1;
wire IOUART  = IO_CE;
wire IOSD    = IO_E8;
wire IOVGA   = IO_F0;
wire IOVGA_PAL = IO_DC;
wire IOMAP   = IO_F8;

assign rst_n = ~BTN[1] & pll_lock;

always@(posedge CLK_27MHz)
begin
  if (BTN[0] == 1'b1 || pll_lock == 1'b0 || BTN[1] == 1'b1 ) begin
    count_rst <= 8'd0;
    cpu_rst_n <= 1'b0;
  end
  else begin
    if (count_rst == 8'hFF ) cpu_rst_n <= 1'b1;
    else count_rst <= count_rst + 8'd1;
  end
end

assign vga_wrM    = (MEMWR == 1'b0 && MEMVGA && map_a_bus[3] == 1'b0)                   ? 1'b0 : 1'b1;
assign vga_wrS    = (MEMWR == 1'b0 && MEMVGA && map_a_bus[3] == 1'b1)                   ? 1'b0 : 1'b1;
assign vga_wrF    = (MEMWR == 1'b0 && MEMVGAF)                   ? 1'b0 : 1'b1;
assign vgaS_wr    = (MEMWR == 1'b0 && MEMVGAS)                   ? 1'b0 : 1'b1;
assign vgaT_wr    = (MEMWR == 1'b0 && MEMVGAT)                   ? 1'b0 : 1'b1;

assign sdram_wr   = (MEMWR == 1'b0 && MEMRAM)                    ? 1'b0 : 1'b1;
assign sdram_rd   = (MEMRD == 1'b0 && MEMRAM)                    ? 1'b0 : 1'b1;
assign sdram_rfsh = (cpu_mreq_n == 1'b0 && cpu_rfsh_n == 1'b0)   ? 1'b0 : 1'b1;

assign i_uart     = (IORD == 1'b0 && IOUART) ? 1'b0 : 1'b1;
assign o_uart     = (IOWR == 1'b0 && IOUART) ? 1'b0 : 1'b1;
assign i_sd       = (IORD == 1'b0 && IOSD)   ? 1'b0 : 1'b1;
assign o_sd       = (IOWR == 1'b0 && IOSD)   ? 1'b0 : 1'b1;
assign o_vga      = (IOWR == 1'b0 && IOVGA)  ? 1'b0 : 1'b1;
assign o_vga_pal  = (IOWR == 1'b0 && IOVGA_PAL)  ? 1'b0 : 1'b1;
//assign i_vga      = (IORD == 1'b0 && IOVGA)  ? 1'b0 : 1'b1;
assign o_map      = (IOWR == 1'b0 && IOMAP)  ? 1'b0 : 1'b1;
//assign i_ay0       = (IORD == 1'b0 && IOAY0)   ? 1'b0 : 1'b1;
//assign i_ay1       = (IORD == 1'b0 && IOAY1)   ? 1'b0 : 1'b1;

assign cpu_di_bus = (MEMRD == 1'b0 && MEMROMF) ? romF_do_bus :
                     (MEMRD == 1'b0 && MEMROME) ? romE_do_bus :
                     (MEMRD == 1'b0 && MEMRAM)  ? sdram_do_bus :
                     (i_uart == 1'b0 && cpu_a_bus[0] == 1'b0) ? USART_RXD : 
                     (i_uart == 1'b0 && cpu_a_bus[0] == 1'b1) ? {USART_RXS_valid, USART_RXS_ready, USART_TXS_valid, USART_TXS_ready, 3'b000, tp0_vs_in} : 
//                     (i_vga == 1'b0) ? SD_RX_data : 
                     (i_sd == 1'b0) ? SD_RX_data : 
//                     (i_ay == 1'b0) ? AY_data : 
//                     (i_ym == 1'b0) ? YM_data : 
//                     (cpu_inta_n == 1'b0) ? irq_ :
                     8'hFF;


//assign a_busFull = { map_a_bus, cpu_a_bus[12:0] };
//==============================================================================

//assign leds = { IOMAP, IOVGA, IOUART, IOSD, IOAY, IOYM };
//assign leds = { 2'b0, O_sdram_cs_n, O_sdram_cas_n, O_sdram_ras_n, O_sdram_wen_n };
//assign leds = sdram_dodfg_bus[5:0];
//assign leds = USART_RXD[5:0];
//assign leds = cpu_a_bus[8:3];
//assign leds = cpu_di_bus[7:2];
//assign leds[5:0] = {SD_RX_data[7:6], SD_TX_data[3:0]};

//==============================================================================
vga_regs u_vga_regs(
	.clk		(CLK_65MHz    ),//pixel clock
	.RESET_n	(rst_n        ),//low active 

	.CS		(o_vga),
	.A		(cpu_a_bus[2:0]),
	.D		(cpu_do_bus),

	.control	(control),
	.hscrollm	(hscrollm),
	.vscrollm	(vscrollm),
	.hscrolls	(hscrolls),
	.vscrolls	(vscrolls),
	.hscrollb	(hscrollb),
	.vscrollb	(vscrollb),
	.hcursor	(hcursor),
	.vcursor	(vcursor),

	.m_split0	(m_split0),
	.m_split1	(m_split1),

	.s_split0	(s_split0),
	.s_split1	(s_split1),

	.b_split0	(b_split0),
	.b_split1	(b_split1)
//	.MA		(vaddr1),
//	.MDo		(vdatai),
//	.MWE		(vwe),
//	.MBLE		(ble),
//	.MBHE		(bhe)
);

//==============================================================================
synch u_synch(
	.clk		(CLK_65MHz    ),//pixel clock
	.RESET_n	(rst_n        ),//low active 

	.h		(h),
	.v		(v),

	.animat		(animat),

	.hactive	(hact),
	.vactive	(vact),
	.blank		(blank),   

	.hsync		(tp0_hs_in),
	.vsync		(tp0_vs_in)
);
//==============================================================================
vga u_vga(
	.clk		(CLK_65MHz    ),//pixel clock
	.RESET_n	(rst_n        ),//low active 

	.control	(control),
	.hscrollm	(hscrollm),
	.vscrollm	(vscrollm),
	.hscrolls	(hscrolls),
	.vscrolls	(vscrolls),
	.hscrollb	(hscrollb),
	.vscrollb	(vscrollb),
	.hcursor	(hcursor),
	.vcursor	(vcursor),

	.h		(h),
	.v		(v),

	.animat		(animat),

	.m_split0	(m_split0),
	.m_split1	(m_split1),

	.s_split0	(s_split0),
	.s_split1	(s_split1),

	.b_split0	(b_split0),
	.b_split1	(b_split1),

//	.hactive	(hact),
//	.vactive	(vact),
	.blank		(blank),
   
	.m_color	(m_color),
	.s_color	(s_color),
	.b_color	(b_color),

	.MA		(vaddr),
	.MDi		(vdatao),
	.MSEL		(voe)
);

//==============================================================================
sprite u_sprite(
	.clk		(CLK_65MHz    ),//pixel clock
	.RESET_n	(rst_n        ),//low active 

	.h		(h),
	.v		(v),

	.hactive	(hact),
	.vactive	(vact),

	.sprite_en	(control[31]),

	.oam_di		(oam_di),
	.oam_do		(oam_do),
	.oam_a		(oam_addr),
	.oam_ble	(oam_ble),
	.oam_bhe	(oam_bhe),
	.oam_we		(oam_we),

	.lb_0_di	(lb0_di),
	.lb_0_do	(lb0_do),
	.lb_0_a		(lb0_a),
	.lb_0_oe	(lb0_oe),
	.lb_0_we	(lb0_we),
	.lb_0_ble	(lb0_ble),
	.lb_0_bhe	(lb0_bhe),

	.lb_1_di	(lb1_di),
	.lb_1_do	(lb1_do),
	.lb_1_a		(lb1_a),
	.lb_1_oe	(lb1_oe),
	.lb_1_we	(lb1_we),
	.lb_1_ble	(lb1_ble),
	.lb_1_bhe	(lb1_bhe),

	.color		(sp_color),

	.MA		(spr_addr),
	.MDi		(spr_datao),
	.MREQ		(spr_oe)
);

//==============================================================================
vga_pal u_vga_pal(
	.clk		(CLK_65MHz    ),//pixel clock
	.RESET_n	(rst_n        ),//low active 

	.CS		(o_vga_pal),
	.A		(cpu_a_bus[1:0]),
	.D		(cpu_do_bus),

	.m_color	(m_color),
	.s_color	(s_color),
	.b_color	(b_color),

	.sp_color	({1'b1, sp_color}),

	.rgb		(rgb)
);

//==============================================================================
assign tp0_de_in  = blank;
assign tp0_data_r = {rgb[ 5: 0], 2'b00};
assign tp0_data_g = {rgb[11: 6], 2'b00};
assign tp0_data_b = {rgb[17:12], 2'b00};

//==============================================================================
ram_screenM u_vramM(
    .clk		(CLK_65MHz	),//pixel clock

    .data_w		({ cpu_do_bus, cpu_do_bus }),
    .addr_w		({ map_a_bus[3:0], cpu_a_bus[12:1] }),
    .we			(vga_wrM	),
    .le			( cpu_a_bus[0]	),
    .he			(~cpu_a_bus[0]	),

    .data_r		(mdatao		),
    .addr_r		(vaddr[15:0]	)
);

//==============================================================================
ram_screenS u_vramS(
    .clk		(CLK_65MHz	),//pixel clock

    .data_w		({ cpu_do_bus, cpu_do_bus }),
    .addr_w		({ map_a_bus[3:0], cpu_a_bus[12:1] }),
    .we			(vga_wrS	),
    .le			( cpu_a_bus[0]	),
    .he			(~cpu_a_bus[0]	),

    .data_r		(sdatao		),
    .addr_r		(vaddr[15:0]	)
);

//==============================================================================
ram_font u_vramF(
    .clk		(CLK_65MHz	),//pixel clock

    .data_w		({ cpu_do_bus, cpu_do_bus }),
    .addr_w		({ map_a_bus[3:0], cpu_a_bus[12:1] }),
    .we			(vga_wrF),
    .le			( cpu_a_bus[0]	),
    .he			(~cpu_a_bus[0]	),

    .data_r		(fdatao		),
    .addr_r		(vaddr[15:0]	)
);

//==============================================================================
ram_sprite u_sram(
    .clk		(CLK_65MHz	),//pixel clock

    .data_w		({ cpu_do_bus, cpu_do_bus }),
    .addr_w		({ map_a_bus[3:0], cpu_a_bus[12:1] }),
    .we			(vgaS_wr),
    .le			( cpu_a_bus[0]	),
    .he			(~cpu_a_bus[0]	),

    .data_r		(spr_data	),
    .addr_r		(spr_addr[15:0]	)
);

//==============================================================================
ram_spriteF u_sfram(
    .clk		(CLK_65MHz	),//pixel clock

    .data_w		({ cpu_do_bus, cpu_do_bus }),
    .addr_w		({ map_a_bus[3:0], cpu_a_bus[12:1] }),
    .we			(vgaT_wr),
    .le			( cpu_a_bus[0]	),
    .he			(~cpu_a_bus[0]	),

    .data_r		(spr_dataF	),
    .addr_r		(spr_addr[15:0]	)
);

//==============================================================================
lbram u_lbram0(
    .clk		(CLK_65MHz	),//pixel clock
    .data_i		(lb0_do		),
    .addr		(lb0_a		),
    .we			(lb0_we		),
    .ble		(lb0_ble	),
    .bhe		(lb0_bhe	),

    .data_o		(lb0_di		)
);

//==============================================================================
lbram u_lbram1(
    .clk		(CLK_65MHz	),//pixel clock
    .data_i		(lb1_do		),
    .addr		(lb1_a		),
    .we			(lb1_we		),
    .ble		(lb1_ble	),
    .bhe		(lb1_bhe	),

    .data_o		(lb1_di		)
);

//==============================================================================
ram_oam u_oamram(
    .clk		(CLK_65MHz	),//pixel clock

    .data_i		(oam_do		),
    .addr		(oam_addr	),
    .we			(oam_we		),
//    .ble		(oam_ble	),
//    .bhe		(oam_bhe	),

    .data_o		(oam_di		)
);

assign vdatao = (vaddr[17] == 1'b1) ? fdatao : (vaddr[15] == 1'b1) ? sdatao : mdatao;
assign spr_datao = (spr_addr[17] == 1'b1) ? spr_dataF : spr_data;

//==============================================================================
// Zilog Z80A CPU
T80a u_cpu(
    .CLK_n		(CLK_5MHz	),
    .RESET_n		(cpu_rst_n	),

    .CEN		(1'b1		),
    .WAIT_n		(1'b1		),
//    .WAIT_n		(sdram_wait	),
    .INT_n		(1'b1	),
//    .INT_n		(~tp0_vs_in	),
//    .INT_n		(cpu_int_n	),
    .NMI_n		(1'b1		),
//    .NMI_n		(cpu_nmi_n	),
    .BUSRQ_n		(1'b1		),
    .M1_n		(cpu_m1_n	),

    .MREQ_n		(cpu_mreq_n	),
    .IORQ_n		(cpu_iorq_n	),
    .RD_n		(cpu_rd_n	),
    .WR_n		(cpu_wr_n	),
    .RFSH_n		(cpu_rfsh_n	),

    .A			(cpu_a_bus	),
    .DIN		(cpu_di_bus	),
    .DOUT		(cpu_do_bus	)
);

//==============================================================================
mapper u_mapper(
    .CLK		(CLK_65MHz	),
    .RESET_n		(rst_n		),

    .A			(cpu_a_bus	),
    .D			(cpu_do_bus	),
    .WR			(o_map		),

    .Q			(map_a_bus	)
);

//==============================================================================
romF u_romF(
    .clk		(CLK_65MHz	),//pixel clock

    .data		(romF_do_bus	),
    .addr		(cpu_a_bus[12:0])
);

//==============================================================================
romE u_romE(
    .clk		(CLK_65MHz	),//pixel clock

    .data		(romE_do_bus	),
    .addr		(cpu_a_bus[12:0])
);

//==============================================================================
// Interrupt
//
always@(posedge CLK_5MHz or negedge rst_n)
begin
  if(rst_n == 1'b0)
  begin
    irq_ <= 8'hFF;
  end
  else
  begin
    IRQ7_ <= IRQ7;
    IRQ6_ <= IRQ6;
    IRQ5_ <= IRQ5;
    IRQ4_ <= IRQ4;
    IRQ3_ <= IRQ3;
    IRQ2_ <= IRQ2;
    IRQ1_ <= IRQ1;
    IRQ0_ <= IRQ0;
    if     ( IRQ0 == 1'b0 && IRQ0_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h00; end
    else if( IRQ0 == 1'b1 && IRQ0_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ1 == 1'b0 && IRQ1_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h02; end
    else if( IRQ1 == 1'b1 && IRQ1_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ2 == 1'b0 && IRQ2_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h04; end
    else if( IRQ2 == 1'b1 && IRQ2_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ3 == 1'b0 && IRQ3_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h06; end
    else if( IRQ3 == 1'b1 && IRQ3_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ4 == 1'b0 && IRQ4_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h08; end
    else if( IRQ4 == 1'b1 && IRQ4_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ5 == 1'b0 && IRQ5_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h0A; end
    else if( IRQ5 == 1'b1 && IRQ5_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ6 == 1'b0 && IRQ6_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h0C; end
    else if( IRQ6 == 1'b1 && IRQ6_ == 1'b0 ) irq_ <= 8'hFF;
    else if( IRQ7 == 1'b0 && IRQ7_ == 1'b1 ) begin cpu_int_n <= 1'b0; irq_ <= 8'h0E; end
    else if( IRQ7 == 1'b1 && IRQ7_ == 1'b0 ) irq_ <= 8'hFF;
    if (cpu_inta_n == 1'b0) cpu_int_n <= 1'b1;
  end
end

assign cpu_inta_n = cpu_iorq_n | cpu_m1_n;
//assign IRQ0 = ~tp0_vs_in;

//==============================================================================
// RAM Controller
//
ram u_ram(
    .CLK		(CLK_65MHz	),
    .CLK_MEM		(~CLK_65MHz	),
    .RESET_n		(rst_n		),

    // cpu signals
    .A			({ map_a_bus[9:0], cpu_a_bus[12:0] }),
    .DI			(cpu_do_bus	),
    .DO			(sdram_do_bus	),
    .WR			(sdram_wr	),
    .RD			(sdram_rd	),
    .RFSH		(sdram_rfsh	),
    .BUSY		(sdram_wait	),

    // phy

    .O_sdram_clk	(O_sdram_clk	),
    .O_sdram_cke	(O_sdram_cke	),
    .O_sdram_cs_n	(O_sdram_cs_n	),
    .O_sdram_cas_n	(O_sdram_cas_n	),
    .O_sdram_ras_n	(O_sdram_ras_n	),
    .O_sdram_wen_n	(O_sdram_wen_n	),

    .O_sdram_addr	(O_sdram_addr	),
    .IO_sdram_dq	(IO_sdram_dq	),
    .O_sdram_ba		(O_sdram_ba	),
    .O_sdram_dqm	(O_sdram_dqm	)
    );

//==============================================================================
TMDS_rPLL u_rpll
(
    .clkin		(CLK_27MHz		),	// 27 Mhz
    .clkout		(CLK_325MHz	),	// 324 MHz
    .clkoutp		(CLKp_325MHz	),	// 324 MHz phase shift 180 
    .clkoutd3		(CLK_108MHz	),	// 108 MHz
    .lock		(pll_lock	)	// output lock
);

//==============================================================================
CLKDIV u_clkdiv65
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_325MHz	),	// 324 MHz
    .CLKOUT		(CLK_65MHz	),	// 64.8 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv65.DIV_MODE="5";
defparam u_clkdiv65.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv162
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_325MHz	),	// 324 MHz
    .CLKOUT		(CLK_162MHz	),	// 162 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv162.DIV_MODE="2";
defparam u_clkdiv162.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv5
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_27MHz		),	// 27 MHz
    .CLKOUT		(CLK_5MHz	),	// 5.4 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv5.DIV_MODE="5";
defparam u_clkdiv5.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv2
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_5MHz	),	// 5.4 MHz
    .CLKOUT		(CLK_2MHz	),	// 2.7 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv2.DIV_MODE="2";
defparam u_clkdiv2.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv7
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_27MHz		),	// 27 MHz
    .CLKOUT		(CLK_7MHz	),	// 6.75 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv7.DIV_MODE="4";
defparam u_clkdiv7.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv3
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_7MHz	),	// 6.75 MHz
    .CLKOUT		(CLK_3MHz	),	// 3.375 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv3.DIV_MODE="2";
defparam u_clkdiv3.GSREN="false";

//==============================================================================
CLKDIV u_clkdiv1
(
    .RESETN		(rst_n		),
    .HCLKIN		(CLK_7MHz	),	// 6.75 MHz
    .CLKOUT		(CLK_1MHz	),	// 1.6875 MHz
    .CALIB		(1'b1		)
);
defparam u_clkdiv1.DIV_MODE="4";
defparam u_clkdiv1.GSREN="false";

//==============================================================================
//CLKDIV u_clkdiv21
//(
//    .RESETN		(rst_n		),
//    .HCLKIN		(CLK_108MHz	),	// 108 MHz
//    .CLKOUT		(CLK_20MHz	),	// 20.16 MHz
//    .CALIB		(1'b1		)
//);
//defparam u_clkdiv21.DIV_MODE="5";
//defparam u_clkdiv21.GSREN="false";

//==============================================================================
//CLKDIV u_clkdiv10
//(
//    .RESETN		(rst_n		),
//    .HCLKIN		(CLK_20MHz	),	// 20.16 MHz
//    .CLKOUT		(CLK_10MHz	),	// 10.08 MHz
//    .CALIB		(1'b1		)
//);
//defparam u_clkdiv10.DIV_MODE="2";
//defparam u_clkdiv10.GSREN="false";

//==============================================================================
//==============================================================================
DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n		(rst_n		),  //asynchronous reset, low active
    .I_serial_clk	(CLK_325MHz	),
    .I_rgb_clk		(CLK_65MHz	),  //pixel clock

    .I_rgb_vs		(tp0_vs_in	), 
    .I_rgb_hs		(tp0_hs_in	),    
    .I_rgb_de		(tp0_de_in	), 

    .I_rgb_r		(tp0_data_r	),  //tp0_data_r
    .I_rgb_g		(tp0_data_g	),  
    .I_rgb_b		(tp0_data_b	),  

    .O_tmds_clk_p	(O_tmds_clk_p	),
    .O_tmds_clk_n	(O_tmds_clk_n	),
    .O_tmds_data_p	(O_tmds_data_p	),  //{r,g,b}
    .O_tmds_data_n	(O_tmds_data_n	)
);

//==============================================================================
parameter                        CLK_FRE  = 27;//Mhz
parameter                        UART_FRE = 115200;//Mhz

assign USART_RXS_ready = 1'b1; //always can receive data,
reg USART_TXS_valid_;

always@(posedge CLK_27MHz or negedge rst_n)
begin
  if(rst_n == 1'b0)
  begin
    USART_TXD <= 8'd0;
    USART_TXS_valid <= 1'b0;
  end
  else
  if(USART_TXS_valid && USART_TXS_ready) begin
    USART_TXS_valid <= 1'b0;
  end
  else
  if ( o_uart == 1'b0 ) begin
    if ( cpu_a_bus[0] == 1'b0 && USART_TXS_valid_ == 1'b0 ) begin
      USART_TXD        <= cpu_do_bus;
      USART_TXS_valid  <= 1'b1;
      USART_TXS_valid_ <= 1'b1;
    end
  end
  else
      USART_TXS_valid_ <= 1'b0;

end

always@(posedge CLK_27MHz or negedge rst_n)
begin
  if(rst_n == 1'b0)
  begin
    USART_RXS_valid <= 1'b0;
  end
  else
  if(USART_RXS_valid_ == 1'b1) begin
    USART_RXS_valid <= 1'b1;
  end
  else
  if ( i_uart == 1'b0 ) begin
    if ( cpu_a_bus[0] == 1'b0 && USART_RXS_valid == 1'b1 ) begin
      USART_RXS_valid <= 1'b0;
    end
  end

end
//==============================================================================
uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
    .clk                (CLK_27MHz		),
    .rst_n              (rst_n		),

    .rx_data            (USART_RXD	),
    .rx_data_valid      (USART_RXS_valid_	),
    .rx_data_ready      (USART_RXS_ready	),

    .rx_pin             (uart_rx	)
);

//==============================================================================
uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
    .clk                (CLK_27MHz		),
    .rst_n              (rst_n		),

    .tx_data            (USART_TXD	),
    .tx_data_valid      (USART_TXS_valid	),
    .tx_data_ready      (USART_TXS_ready	),

    .tx_pin             (uart_tx	)
);

//==============================================================================
assign SD_RX_data   = {SD_DAT0, 7'b0000000};
assign SD_CS  = SD_TX_data[2];
assign SD_SCK = SD_TX_data[1];
assign SD_CMD = SD_TX_data[0];

always@(posedge CLK_27MHz or negedge rst_n)
begin
  if(rst_n == 1'b0)
  begin
    SD_TX_data <= 8'd5;
  end
  else
    if ( o_sd == 1'b0 ) begin
      SD_TX_data <= cpu_do_bus;
    end

end
//==============================================================================
//sd_controller sd1 (
//    .clk		(CLK_5MHz),
//    .n_reset		(rst_n),

//    .regAddr		(cpu_a_bus[2:0]),
//    .n_wr		(o_sd),
//    .n_rd		(i_sd),
//    .dataIn		(cpu_do_bus),
//    .dataOut		(SD_RX_data),

//    .sdSCLK		(SD_SCK),
//    .sdCS		(SD_CS),
//    .sdMOSI		(SD_CMD),
//    .sdMISO		(SD_DAT0),

//    .driveLED		(leds[5])
//);

audio_drive u_audio_drive_0(
    .clk_1p536m	(CLK_2MHz),
    .rst_n	(rst_n),

    .idata	(audio_in),
//    .req	(req_w),

    .HP_BCK	(HP_BCK),
    .HP_WS	(HP_WS),
    .HP_DIN	(HP_DIN)
);

assign PA_EN = 1'b1;
assign audio_in = {8'b00000000, ay0_a} + {8'b00000000, ay0_b} + {8'b00000000, ay0_c} + 
                  {8'b00000000, ay1_a} + {8'b00000000, ay1_b} + {8'b00000000, ay1_c};
//                  {2'b00, sn_mix0} + {2'b00, sn_mix1};
//assign audio_in = {8'b00000000, ym_a[7:0]} + {8'b00000000, ym_b[7:0]} + {8'b00000000, cpu_a_bus[7:0]};// + {8'b00000000, ym_c[7:0]};
//assign audio_in = {4'b0000, ym_a} + {4'b0000, ym_b} + {4'b0000, ym_c};
//assign audio_in = {2'b00, ym_mix};
//assign audio_in = {8'b00000000, jt_a} + {8'b00000000, jt_b} + {8'b00000000, jt_c};

///reg [5:0] ena_cnt;
//wire [5:0] ena_cnt_;
//wire ena_1_75mhz;

//always@(posedge CLK_27MHz)
//begin
//  ena_cnt <= ena_cnt_;
//end

//assign ena_cnt_ = ena_cnt + 1;
//assign ena_1_75mhz = ena_cnt[3] & ena_cnt[2] & ena_cnt[1] & ena_cnt[0];

ay8910m u_aym0(
	.clk		(CLK_5MHz),
	.reset		(rst_n),
	.psgclk		(CLK_1MHz), //(ena_1_75mhz), //

	.cs		(IOAY0),
	.bdir		(IOWR),
	.bc		(cpu_a_bus[0]),
	.di		(cpu_do_bus),
	.do		(AY_data0),

	.out_a		(ay0_a),
	.out_b		(ay0_b),
	.out_c		(ay0_c)
);

ay8910m u_aym1(
	.clk		(CLK_5MHz),
	.reset		(rst_n),
	.psgclk		(CLK_1MHz), //(ena_1_75mhz), //

	.cs		(IOAY1),
	.bdir		(IOWR),
	.bc		(cpu_a_bus[0]),
	.di		(cpu_do_bus),
	.do		(AY_data1),

	.out_a		(ay1_a),
	.out_b		(ay1_b),
	.out_c		(ay1_c)
);

//assign YMbdir = (IOYM == 1'b0) ? ~cpu_wr_n : 1'b0;
//assign YMbc   = (IOYM == 1'b0) ? cpu_a_bus[0] : 1'b0;

//ym2149_audio u_ym(
//	.clk_i		(CLK_5MHz),
//	.reset_n_i	(rst_n),
//	.sel_n_i	(1'b1),
//	.en_clk_psg_i	(ena_1_75mhz), //(1'b1), //

//	.bdir_i		( YMbdir ), // 1 -wr
//	.bc_i		( YMbc ), // 1 -cs
//	.data_i		(cpu_do_bus),
//	.data_r_o	(YM_data),

//	.mix_audio_o	(ym_mix)
//);

//sn76489_audio u_sn0(
//	.clk_i		(CLK_3MHz),
//	.en_clk_psg_i	(1'b1), //(ena_1_75mhz),

//	.ce_n_i		( IOSN0 ),
//	.wr_n_i		( IOWR ),
//	.data_i		(cpu_do_bus),

//	.mix_audio_o	(sn_mix0)
//);

//sn76489_audio u_sn1(
//	.clk_i		(CLK_3MHz),
//	.en_clk_psg_i	(1'b1), //(ena_1_75mhz),

//	.ce_n_i		( IOSN1 ),
//	.wr_n_i		( IOWR ),
//	.data_i		(cpu_do_bus),

//	.mix_audio_o	(sn_mix1)
//);

endmodule