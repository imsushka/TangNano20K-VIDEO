//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8.09
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18C
//Created Time: Wed Jan 11 16:32:24 2023

module TMDS_rPLL (clkout, clkoutp, clkoutd3, lock, clkin);

output clkout;
output clkoutp;
output clkoutd3;
output lock;
input clkin;

wire clkoutp_o;
wire clkoutd_o;
wire clkoutd3_o;
wire gw_gnd;

assign gw_gnd = 1'b0;

rPLL rpll_inst (
    .CLKIN	(clkin),
    .RESET	(gw_gnd),
    .RESET_P	(gw_gnd),

    .CLKOUT	(clkout),
    .CLKOUTP	(clkoutp),
    .CLKOUTD	(clkoutd_o),
    .CLKOUTD3	(clkoutd3),
    .CLKFB	(gw_gnd),

    .LOCK	(lock),

    .FBDSEL	({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL	({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL	({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA	({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA	({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY	({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam rpll_inst.FCLKIN           = "27";
defparam rpll_inst.DYN_IDIV_SEL     = "false";
defparam rpll_inst.IDIV_SEL         = 0;
defparam rpll_inst.DYN_FBDIV_SEL    = "false";
defparam rpll_inst.FBDIV_SEL        = 11;
defparam rpll_inst.DYN_ODIV_SEL     = "false";
defparam rpll_inst.ODIV_SEL         = 2;
defparam rpll_inst.PSDA_SEL         = "0000";
defparam rpll_inst.DYN_DA_EN        = "true";
defparam rpll_inst.DUTYDA_SEL       = "1000";
defparam rpll_inst.CLKOUT_FT_DIR    = 1'b1;
defparam rpll_inst.CLKOUTP_FT_DIR   = 1'b1;
defparam rpll_inst.CLKOUT_DLY_STEP  = 0;
defparam rpll_inst.CLKOUTP_DLY_STEP = 0;
defparam rpll_inst.CLKFB_SEL        = "internal";
defparam rpll_inst.CLKOUT_BYPASS    = "false";
defparam rpll_inst.CLKOUTP_BYPASS   = "false";
defparam rpll_inst.CLKOUTD_BYPASS   = "false";
defparam rpll_inst.DYN_SDIV_SEL     = 2;
defparam rpll_inst.CLKOUTD_SRC      = "CLKOUT";
defparam rpll_inst.CLKOUTD3_SRC     = "CLKOUT";
defparam rpll_inst.DEVICE           = "GW2AR-18C";

endmodule //TMDS_rPLL
