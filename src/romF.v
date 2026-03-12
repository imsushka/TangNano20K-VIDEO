module romF (clk, addr, data);

input  clk;
input  [12:0] addr;
output [7:0] data;

reg [7:0] rom [8191:0];
reg [7:0] data;

//always @* begin
always @(posedge clk) begin
  data <= rom[addr];
end

initial $readmemh("rom_bios.dat", rom);
//initial $readmemh("rom_ds.dat", rom);

endmodule