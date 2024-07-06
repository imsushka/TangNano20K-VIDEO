module comp1024x768a
(
    input              clk   ,//pixel clock
    input              rst     ,//low active 

    input      [11:0]  H   ,//hor total time 
    input      [11:0]  V   ,//ver total time 

    output             blank        ,   
    output             hblank       ,   
    output             vblank       ,   
    output reg         hsync        ,//������
    output reg         vsync        ,//������
    output reg         hreset        ,   
    output reg         vreset       
); 

//====================================================
localparam N = 8; //delay N clocks

//====================================================
wire          Pout_hde_w    ;                          
wire          Pout_vde_w    ;                          
wire          Pout_de_w    ;                          
wire          Pout_hs_w    ;
wire          Pout_vs_w    ;
wire          Pout_hr_w    ;
wire          Pout_vr_w    ;

reg  [N-1:0]  Pout_hde_dn   ;                          
reg  [N-1:0]  Pout_vde_dn   ;                          
reg  [N-1:0]  Pout_de_dn   ;                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;
reg  [N-1:0]  Pout_hr_dn   ;
reg  [N-1:0]  Pout_vr_dn   ;


//==============================================================================
//Generate HS, VS, DE signals

assign  Pout_hde_w = ( H >= 12'd0 ) & ( H <= 1023 );
assign  Pout_vde_w = ( V >= 12'd0 ) & ( V <= 767 );
assign  Pout_de_w  = ( ( H >= 12'd0 ) & ( H <= ( 1023 ) ) ) &
                     ( ( V >= 12'd0 ) & ( V <= ( 767 ) ) ) ;

assign  Pout_hs_w  =  ~( ( H >= ( 160 + 1023 ) ) & ( H <= ( 160 + 1024 + 135 ) ) ) ;
assign  Pout_vs_w  =  ~( ( V >= (  29 +  767 ) ) & ( V <= (  29 +  768 +   5 ) ) ) ;  

assign  Pout_hr_w  = ~( H == 1343 );
assign  Pout_vr_w  = ~( V ==  805 );
//-------------------------------------------------------------
always@(posedge clk or negedge rst)
begin
	if(!rst)
		begin
			Pout_hde_dn  <= {N{1'b0}};
			Pout_vde_dn  <= {N{1'b0}};
			Pout_de_dn   <= {N{1'b0}};

			Pout_hs_dn   <= {N{1'b1}};
			Pout_vs_dn   <= {N{1'b1}};

			Pout_hr_dn   <= {N{1'b0}};
			Pout_vr_dn   <= {N{1'b0}};
		end
	else 
		begin
			Pout_hde_dn  <= {Pout_de_dn[N-2:0],Pout_de_w};
			Pout_vde_dn  <= {Pout_de_dn[N-2:0],Pout_de_w};
			Pout_de_dn   <= {Pout_de_dn[N-2:0],Pout_de_w};

			Pout_hs_dn   <= {Pout_hs_dn[N-2:0],Pout_hs_w};
			Pout_vs_dn   <= {Pout_vs_dn[N-2:0],Pout_vs_w};

			Pout_hr_dn   <= {Pout_hr_dn[N-2:0],Pout_hr_w};
			Pout_vr_dn   <= {Pout_vr_dn[N-2:0],Pout_vr_w};
		end
end

assign hblank = Pout_hde_dn[N-1];
assign vblank = Pout_vde_dn[N-1];
assign blank  = Pout_de_dn[N-1];
//assign blank = Pout_de_w;

always@(posedge clk or negedge rst)
begin
	if(!rst)
		begin                        
			hsync  <= 1'b1;
			vsync  <= 1'b1; 

			hreset <= 1'b0;
			vreset <= 1'b0; 
		end
	else 
		begin                         
			hsync  <= Pout_hs_dn[N-1] ;
			vsync  <= Pout_vs_dn[N-1] ;

			hreset <= Pout_hr_w ;
			vreset <= Pout_vr_w ; 
		end
end

endmodule       
            