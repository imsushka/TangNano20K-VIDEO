-------------------------------------------------------------------[07.09.2013]
-- AY3-8910
-------------------------------------------------------------------------------
-- V0.1 	15.10.2011	������ ������

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity ay8910m is
   port(
      CLK   	: in  std_logic;                   	-- System Clock
      PSGCLK   	: in  std_logic;                    	-- PSG Clock
      RESET 	: in  std_logic;                    	-- Chip Reset

      CS    	: in  std_logic;                    	-- Chip Select
      BDIR  	: in  std_logic;                    	-- Bus Direction (1 - read , 0 - write)
      BC    	: in  std_logic;                    	-- Bus control
      DI    	: in  std_logic_vector(7 downto 0); 	-- Data In
      DO    	: out std_logic_vector(7 downto 0); 	-- Data Out

      OUT_A 	: out std_logic_vector(7 downto 0); 	-- PSG Output channel A
      OUT_B 	: out std_logic_vector(7 downto 0); 	-- PSG Output channel B
      OUT_C 	: out std_logic_vector(7 downto 0)  	-- PSG Output channel C
   );
end ay8910m;
 
architecture rtl of ay8910m is
 
   signal ClockDiv   : unsigned (7 downto 0);		-- Divide ENA
 
-- AY Registers
   signal Period_A   : std_logic_vector (11 downto 0);	-- Channel A Tone Period (R1:R0)
   signal Period_B   : std_logic_vector (11 downto 0);	-- Channel B Tone Period (R3:R2)
   signal Period_C   : std_logic_vector (11 downto 0);	-- Channel C Tone Period (R5:R4)
   signal Period_N   : std_logic_vector (4 downto 0);	-- Noise Period (R6)
   signal Enable     : std_logic_vector (7 downto 0);	-- Enable (R7)
   signal Volume_A   : std_logic_vector (4 downto 0);	-- Channel A Amplitude (R10)
   signal Volume_B   : std_logic_vector (4 downto 0);	-- Channel B Amplitude (R11)
   signal Volume_C   : std_logic_vector (4 downto 0);	-- Channel C Amplitude (R12)
   signal Period_E   : std_logic_vector (15 downto 0);	-- Envelope Period (R14:R13)
   signal Shape      : std_logic_vector (3 downto 0);	-- Envelope Shape/Cycle (R15)
--   signal Port_A     : std_logic_vector (7 downto 0);	-- I/O Port A Data Store (R16)
--   signal Port_B     : std_logic_vector (7 downto 0);	-- I/O Port B Data Store (R17)
--
   signal Address    : std_logic_vector (3 downto 0);	-- Selected Register
 
   alias  Continue   : std_logic is Shape(3);		-- Envelope Control
   alias  Attack     : std_logic is Shape(2);
   alias  Alternate  : std_logic is Shape(1);
   alias  Hold       : std_logic is Shape(0);
 
   signal Reset_Req  : std_logic;			-- Envelope Reset Required
   signal Reset_Ack  : std_logic;			-- Envelope Reset Acknoledge
   signal Volume_E   : std_logic_vector (3 downto 0);   -- Envelope Volume
 
   signal Freq_A     : std_logic;                       -- Tone Generator A Output
   signal Freq_B     : std_logic;                       -- Tone Generator B Output
   signal Freq_C     : std_logic;                       -- Tone Generator C Output
   signal Freq_N     : std_logic;                       -- Noise Generator Output
 
   function VolumeTable (value : std_logic_vector(3 downto 0)) return std_logic_vector is
      variable result : std_logic_vector (7 downto 0);
   begin
      case value is 					-- Volume Table
         when "1111"  => result := "11111111";
         when "1110"  => result := "10110100";
         when "1101"  => result := "01111111";
         when "1100"  => result := "01011010";
         when "1011"  => result := "00111111";
         when "1010"  => result := "00101101";
         when "1001"  => result := "00011111";
         when "1000"  => result := "00010110";
         when "0111"  => result := "00001111";
         when "0110"  => result := "00001011";
         when "0101"  => result := "00000111";
         when "0100"  => result := "00000101";
         when "0011"  => result := "00000011";
         when "0010"  => result := "00000010";
         when "0001"  => result := "00000001";
         when "0000"  => result := "00000000";
         when others => null;
      end case;
   return result;
   end VolumeTable;
 
begin
 
-- Write to AY
process (RESET , CLK)
begin
   if RESET = '0' then
      Address   <= (OTHERS => '0');
      Period_A  <= (OTHERS => '0');
      Period_B  <= (OTHERS => '0');
      Period_C  <= (OTHERS => '0');
      Period_N  <= (OTHERS => '0');
      Enable    <= (OTHERS => '0');
      Volume_A  <= (OTHERS => '0');
      Volume_B  <= (OTHERS => '0');
      Volume_C  <= (OTHERS => '0');
      Period_E  <= (OTHERS => '0');
      Shape     <= (OTHERS => '0');
--      Port_A    <= "00000000";
--      Port_B    <= "00000000";
      Reset_Req <= '0';
   elsif rising_edge(CLK) then
      if CS = '0' and BDIR = '0' then
         if BC = '1' then
            Address <= DI (3 downto 0);			-- Latch Address
         else
            case Address is				-- Latch Registers
               when "0000" => Period_A (7 downto 0)   <= DI;
               when "0001" => Period_A (11 downto 8)  <= DI (3 downto 0);
               when "0010" => Period_B (7 downto 0)   <= DI;
               when "0011" => Period_B (11 downto 8)  <= DI (3 downto 0);
               when "0100" => Period_C (7 downto 0)   <= DI;
               when "0101" => Period_C (11 downto 8)  <= DI (3 downto 0);
               when "0110" => Period_N                <= DI (4 downto 0);
               when "0111" => Enable                  <= DI;
               when "1000" => Volume_A                <= DI (4 downto 0);
               when "1001" => Volume_B                <= DI (4 downto 0);
               when "1010" => Volume_C                <= DI (4 downto 0);
               when "1011" => Period_E (7 downto 0)   <= DI;
               when "1100" => Period_E (15 downto 8)  <= DI;
               when "1101" => Shape                   <= DI (3 downto 0);
                              Reset_Req               <= not Reset_Ack; -- Reset Envelope Generator
               when others => null;
            end case;
         end if;
      end if;
   end if;
end process;
 
-- Read from AY
DO	<=	Period_A (7 downto 0)		when Address = "0000" and CS = '0' else
		"0000" & Period_A (11 downto 8)	when Address = "0001" and CS = '0' else
		Period_B (7 downto 0)   	when Address = "0010" and CS = '0' else
		"0000" & Period_B (11 downto 8) when Address = "0011" and CS = '0' else
		Period_C (7 downto 0)   	when Address = "0100" and CS = '0' else
		"0000" & Period_C (11 downto 8) when Address = "0101" and CS = '0' else
		"000" & Period_N                when Address = "0110" and CS = '0' else
		Enable                  	when Address = "0111" and CS = '0' else
		"000" & Volume_A                when Address = "1000" and CS = '0' else
		"000" & Volume_B                when Address = "1001" and CS = '0' else
		"000" & Volume_C                when Address = "1010" and CS = '0' else
		Period_E (7 downto 0)   	when Address = "1011" and CS = '0' else
		Period_E (15 downto 8)  	when Address = "1100" and CS = '0' else
		"0000" & Shape                  when Address = "1101" and CS = '0' else
		"11111111";
 
-- Divide ENA
process (RESET, PSGCLK)
begin
   if RESET = '0' then
      ClockDiv <= (OTHERS => '0');
   elsif rising_edge(PSGCLK) then
--      if ENA = '1' then
         ClockDiv <= ClockDiv - 1;
--      end if;
   end if;
end process;
 
-- Tone Generator
process (RESET, PSGCLK, ClockDiv)
   variable Counter_A   : unsigned (11 downto 0);
   variable Counter_B   : unsigned (11 downto 0);
   variable Counter_C   : unsigned (11 downto 0);
begin
   if RESET = '0' then
      Counter_A   := (OTHERS => '0');
      Counter_B   := (OTHERS => '0');
      Counter_C   := (OTHERS => '0');
      Freq_A      <= '0';
      Freq_B      <= '0';
      Freq_C      <= '0';
   elsif rising_edge(PSGCLK) then
      if ClockDiv(2 downto 0) = "000" then
 
         -- Channel A Counter
         if (Counter_A /= X"000") then
            Counter_A := Counter_A - 1;
         elsif (Period_A /= X"000") then
            Counter_A := unsigned(Period_A) - 1;
         end if;
         if (Counter_A = X"000") then
            Freq_A <= not Freq_A;
         end if;
 
         -- Channel B Counter
         if (Counter_B /= X"000") then
            Counter_B := Counter_B - 1;
         elsif (Period_B /= X"000") then
            Counter_B := unsigned(Period_B) - 1;
         end if;
         if (Counter_B = X"000") then
            Freq_B <= not Freq_B;
         end if;
 
         -- Channel C Counter
         if (Counter_C /= X"000") then
            Counter_C := Counter_C - 1;
         elsif (Period_C /= X"000") then
            Counter_C := unsigned(Period_C) - 1;
         end if;
         if (Counter_C = X"000") then
            Freq_C <= not Freq_C;
         end if;
 
      end if;
   end if;
end process;
 
-- Noise Generator
process (RESET, PSGCLK, ClockDiv)
   variable NoiseShift : unsigned (16 downto 0);
   variable Counter_N  : unsigned (4 downto 0);
begin
   if RESET = '0' then
      Counter_N   := (OTHERS => '0');
      NoiseShift  := "00000000000000001";
   elsif rising_edge(PSGCLK) then
      if ClockDiv(2 downto 0) = "000" then
         if (Counter_N /= "00000") then
            Counter_N := Counter_N - 1;
         elsif (Period_N /= "00000") then
            Counter_N := unsigned(Period_N) - 1;
         end if;
         if Counter_N = "00000" then
            NoiseShift := (NoiseShift(0) xor NoiseShift(2)) & NoiseShift(16 downto 1);
         end if;
         Freq_N <= NoiseShift(0);
      end if;
   end if;
end process;
 
-- Envelope Generator
process (RESET , PSGCLK, ClockDiv)
   variable EnvCounter  : unsigned(15 downto 0);
   variable EnvWave     : unsigned(4 downto 0);
begin
   if RESET = '0' then
      EnvCounter  := (OTHERS => '0');
      EnvWave     := "11111";
      Volume_E    <= (OTHERS => '0');
      Reset_Ack   <= '0';
   elsif rising_edge(PSGCLK) then
      if ClockDiv(3 downto 0) = "0000" then
         -- Envelope Period Counter 
         if (EnvCounter /= X"0000" and Reset_Req = Reset_Ack) then 
            EnvCounter := EnvCounter - 1;
         elsif (Period_E /= X"0000") then
            EnvCounter := unsigned(Period_E) - 1;
         end if;
 
         -- Envelope Phase Counter
         if (Reset_Req /= Reset_Ack) then
            EnvWave := (others => '1');
         elsif (EnvCounter = X"0000" and (EnvWave(4) = '1' or (Hold = '0' and Continue = '1'))) then
            EnvWave := EnvWave - 1;
         end if;
 
         -- Envelope Amplitude Counter
         for I in 3 downto 0 loop
            if (EnvWave(4) = '0' and Continue = '0') then
               Volume_E(I) <= '0';
            elsif (EnvWave(4) = '1' or (Alternate xor Hold) = '0') then
               Volume_E(I) <= EnvWave(I) xor Attack;
            else
              Volume_E(I) <= EnvWave(I) xor Attack xor '1';
            end if;
         end loop;
         Reset_Ack <= Reset_Req;
      end if;
   end if;
end process;
 
-- Mixer
process (RESET , PSGCLK)
begin
   if RESET = '0' then
      OUT_A <= (OTHERS => '0');
      OUT_B <= (OTHERS => '0');
      OUT_C <= (OTHERS => '0');
   elsif rising_edge(PSGCLK) then
         if (((Enable(0) or Freq_A) and (Enable(3) or Freq_N)) = '0') then
            OUT_A <= (OTHERS => '0');
         elsif (Volume_A(4) = '0') then
            OUT_A <= VolumeTable(Volume_A(3 downto 0));
         else
            OUT_A <= VolumeTable(Volume_E);
         end if;
 
         if (((Enable(1) or Freq_B) and (Enable(4) or Freq_N)) = '0') then
            OUT_B <= (OTHERS => '0');
         elsif (Volume_B(4) = '0') then
            OUT_B <= VolumeTable(Volume_B(3 downto 0));
         else
            OUT_B <= VolumeTable(Volume_E);
         end if;
 
         if (((Enable(2) or Freq_C) and (Enable(5) or Freq_N)) = '0') then
            OUT_C <= (OTHERS => '0');
         elsif (Volume_C(4) = '0') then
            OUT_C <= VolumeTable(Volume_C(3 downto 0));
         else
            OUT_C <= VolumeTable(Volume_E);
         end if;
   end if;
end process;
 
end rtl;