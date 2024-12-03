// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module ram_color (clk, we, he, le, addr_w, addr_r, data_w, data_r);

input  clk, we, he, le;
input  [15:0] addr_w,addr_r;
input  [15:0] data_w;
output [15:0] data_r;

reg [7:0] ramh [1023:0];
reg [7:0] raml [1023:0];
reg [15:0] data_r;

always @(posedge clk) begin
  if (we == 1'b0) begin
    if (he == 1'b0)
      ramh[addr_w] <= data_w[15:8];
    if (le == 1'b0)
      raml[addr_w] <= data_w[7:0];
  end
end

always @(posedge clk) begin
  data_r <= { ramh[addr_r], raml[addr_r] };
end

initial $readmemh("color_roml.dat", raml);
initial $readmemh("color_romh.dat", ramh);

endmodule