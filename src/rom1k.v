// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module rom (clk, addr, data);

input  clk;
input  [12:0] addr;
output [7:0] data;

reg [7:0] rom [2047:0];
reg [7:0] data;

always @(posedge clk) begin
  data <= rom[addr];
end

initial $readmemh("rom.dat", rom);

endmodule