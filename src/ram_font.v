// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module ram_font (clk, we, he, le, addr_w, addr_r, data_w, data_r);

input  clk, we, he, le;
input  [15:0] addr_w,addr_r;
input  [15:0] data_w;
output [15:0] data_r;

//reg [7:0] ramh [16383:0];
//reg [7:0] raml [16383:0];
reg [7:0] ramh [8191:0];
reg [7:0] raml [8191:0];
//reg [15:0] data_r;

always @(posedge clk) begin
  if (we == 1'b0) begin
    if (he == 1'b0)
      ramh[addr_w] <= data_w[15:8];
    if (le == 1'b0)
      raml[addr_w] <= data_w[7:0];
  end
end

assign  data_r = { ramh[addr_r], raml[addr_r] };

initial $readmemb("font08x08x1_roml.dat", raml);
initial $readmemb("font08x08x1_romh.dat", ramh);

//initial $readmemb("font16x16x1_roml.dat", raml);
//initial $readmemb("font16x16x1_romh.dat", ramh);

//initial $readmemb("lr_font_romh.dat", raml);
//initial $readmemb("lr_font_roml.dat", ramh);

endmodule