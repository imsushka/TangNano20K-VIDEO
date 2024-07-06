library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity Rom is
	port(
		clk: in std_logic;
		addr: in std_logic_vector(12 downto 0);
		data: out std_logic_vector(7 downto 0)
	);
end Rom;

architecture Behavioral of Rom is
   
	constant ADDR_WIDTH : integer := 8;
	constant DATA_WIDTH : integer := 8;
	
	type rom_type is array (0 to 256+144-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
	-- ROM definition
	signal ROM: rom_type := (   -- 2^11-by-8
x"C3",x"03",x"E0",x"3E",x"00",x"D3",x"F8",x"3E",x"08",x"D3",x"F8",x"3E",x"01",x"D3",x"F9",x"3E",
x"08",x"D3",x"F9",x"3E",x"02",x"D3",x"FA",x"3E",x"08",x"D3",x"FA",x"3E",x"03",x"D3",x"FB",x"3E",
x"08",x"D3",x"FB",x"21",x"00",x"00",x"3E",x"55",x"77",x"BE",x"C2",x"37",x"E0",x"23",x"7C",x"FE",
x"80",x"C2",x"26",x"E0",x"C3",x"40",x"E0",x"7C",x"FE",x"80",x"C2",x"CF",x"E0",x"C3",x"A3",x"E0",
x"3E",x"F0",x"D3",x"FC",x"3E",x"F1",x"D3",x"FD",x"3E",x"F2",x"D3",x"FE",x"21",x"00",x"80",x"F9",
x"21",x"00",x"80",x"0E",x"2F",x"3E",x"C9",x"77",x"23",x"71",x"23",x"06",x"7E",x"3E",x"CD",x"77",
x"23",x"71",x"23",x"10",x"F8",x"3E",x"BB",x"77",x"23",x"71",x"23",x"16",x"5E",x"1E",x"00",x"3E",
x"BA",x"77",x"23",x"71",x"23",x"06",x"7E",x"7B",x"77",x"23",x"3C",x"71",x"23",x"10",x"F9",x"3E",
x"BA",x"77",x"23",x"71",x"23",x"1C",x"15",x"C2",x"6F",x"E0",x"3E",x"C9",x"77",x"23",x"71",x"23",
x"06",x"7E",x"3E",x"CD",x"77",x"23",x"71",x"23",x"10",x"F8",x"3E",x"BB",x"77",x"23",x"71",x"23",
x"C3",x"03",x"E0",x"3E",x"F0",x"D3",x"F4",x"3E",x"0F",x"D3",x"F4",x"3E",x"F1",x"D3",x"F5",x"3E",
x"0F",x"D3",x"F5",x"3E",x"F2",x"D3",x"F6",x"3E",x"0F",x"D3",x"F6",x"21",x"00",x"80",x"3E",x"D9",
x"77",x"23",x"3E",x"87",x"77",x"23",x"7C",x"FE",x"E0",x"C2",x"BE",x"E0",x"C3",x"03",x"E0",x"3E",
x"F0",x"D3",x"FC",x"3E",x"F1",x"D3",x"FD",x"3E",x"F2",x"D3",x"FE",x"21",x"00",x"80",x"0E",x"5F",
x"3E",x"C9",x"77",x"23",x"71",x"23",x"06",x"7E",x"3E",x"CD",x"77",x"23",x"71",x"23",x"10",x"F8",
x"3E",x"BB",x"77",x"23",x"71",x"23",x"16",x"5E",x"1E",x"00",x"3E",x"BA",x"77",x"23",x"71",x"23",
x"06",x"7E",x"7B",x"77",x"23",x"3C",x"71",x"23",x"10",x"F9",x"3E",x"BA",x"77",x"23",x"71",x"23",
x"1D",x"15",x"C2",x"FA",x"E0",x"3E",x"C9",x"77",x"23",x"71",x"23",x"06",x"7E",x"3E",x"CD",x"77",
x"23",x"71",x"23",x"10",x"F8",x"3E",x"BB",x"77",x"23",x"71",x"23",x"C3",x"03",x"E0",x"3E",x"FC",
x"D3",x"FC",x"3E",x"0F",x"D3",x"F4",x"3E",x"FD",x"D3",x"FD",x"3E",x"0F",x"D3",x"F5",x"3E",x"FE",
x"D3",x"FE",x"3E",x"0F",x"D3",x"F6",x"21",x"00",x"80",x"3E",x"D9",x"77",x"23",x"3E",x"07",x"77",
x"23",x"7C",x"FE",x"E0",x"C2",x"49",x"E1",x"C3",x"03",x"E0",x"3E",x"F9",x"D3",x"FC",x"3E",x"0F",
x"D3",x"F4",x"3E",x"FA",x"D3",x"FD",x"3E",x"0F",x"D3",x"F5",x"3E",x"FB",x"D3",x"FE",x"3E",x"0F",
x"D3",x"F6",x"21",x"00",x"80",x"3E",x"D9",x"77",x"23",x"3E",x"07",x"77",x"23",x"7C",x"FE",x"E0",
x"C2",x"75",x"E1",x"C3",x"03",x"E0",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
	);
--    attribute syn_romstyle : string;
--    attribute syn_romstyle of ROM: signal is "black_rom";
begin

	process (clk)
	begin
		if rising_edge(clk) then
			-- Read from Rom
			data <= ROM(to_integer(unsigned(addr)));
		end if;
	end process;
	
end Behavioral;