-------------------------------------------------------------------------------
-- RAM Controller
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity ram is
	port(
	CLK		: in std_logic; -- 140
	CLK_MEM		: in std_logic; -- 140 deg 180
	RESET_n		: in std_logic;

	-- Memory port
	A		: in std_logic_vector(22 downto 0);
	DI		: in std_logic_vector(7 downto 0);
	DO		: out std_logic_vector(7 downto 0);
	WR		: in std_logic;
	RD		: in std_logic;
	RFSH		: in std_logic;
	BUSY		: out std_logic;

		-- SDRAM Pins
	O_sdram_clk	: out std_logic;
	O_sdram_cke	: out std_logic;
	O_sdram_cs_n	: out std_logic;
	O_sdram_cas_n	: out std_logic;
	O_sdram_ras_n	: out std_logic;
	O_sdram_wen_n	: out std_logic;
	IO_sdram_dq	: inout std_logic_vector(31 downto 0);
	O_sdram_addr	: out std_logic_vector(10 downto 0);
	O_sdram_ba	: out std_logic_vector(1 downto 0);
	O_sdram_dqm	: out std_logic_vector(3 downto 0)
);
end ram;

architecture rtl of ram is

signal sdr_rd : std_logic;
signal sdr_wr : std_logic;
signal sdr_refresh : std_logic;
signal sdr_addr : std_logic_vector(22 downto 0);
signal sdr_din : std_logic_vector(7 downto 0);
signal sdr_dout : std_logic_vector(7 downto 0);
signal sdr_dout32 : std_logic_vector(31 downto 0);
signal sdr_data_ready : std_logic;
signal sdr_busy : std_logic;
signal sdr_bsel : std_logic_vector(2 downto 0);

type qmachine is (init, idle, read, write, refresh);
signal state : qmachine;

begin

U_SDRAM: entity work.sdram
	port map (
		SDRAM_DQ	=> IO_sdram_dq,
		SDRAM_A		=> O_sdram_addr,
		SDRAM_BA	=> O_sdram_ba,
		SDRAM_nCS	=> O_sdram_cs_n,
		SDRAM_nWE	=> O_sdram_wen_n,
		SDRAM_nRAS	=> O_sdram_ras_n,
		SDRAM_nCAS	=> O_sdram_cas_n,
		SDRAM_CLK	=> O_sdram_clk,
		SDRAM_CKE	=> O_sdram_cke,
		SDRAM_DQM	=> O_sdram_dqm,

		clk		=> CLK,
		clk_sdram	=> CLK_MEM,
		resetn		=> RESET_n,

		rd		=> sdr_rd,
		wr		=> sdr_wr,
		refresh		=> sdr_refresh,
		addr		=> sdr_addr,
		din		=> sdr_din,
		dout		=> sdr_dout,
--		bsel		=> sdr_bsel,
		data_ready	=> sdr_data_ready,
		busy		=> sdr_busy
	);

BUSY <= not sdr_busy;
DO <= sdr_dout(7 downto 0);

process (CLK, RESET_n)
begin 
    if RESET_n = '0' then
        state <= init;
    elsif rising_edge(CLK) then 

        case state is

            when init =>
                if sdr_busy = '0' then 
                    state <= idle;
                end if;

            when idle =>
		sdr_addr <= A;
                sdr_din  <= DI;
                if (WR = '0') then
			state  <= write;

			sdr_wr <= '1';
                elsif (RD = '0') then
			state  <= read;

			sdr_rd <= '1';
		elsif (RFSH = '0') then 
			state  <= refresh;

			sdr_refresh <= '1';
                end if;

            when read => 
		sdr_rd <= '0';
                if (sdr_busy = '0') then 
                    state  <= idle;
                end if;

            when write =>
		sdr_wr <= '0';
                if (sdr_busy = '0') then 
                    state <= idle;
                end if; 

	    when refresh =>
		sdr_refresh <= '0';
                if (sdr_busy = '0') then 
                    state <= idle;
                end if; 
        end case;
    end if;
end process;

end rtl;