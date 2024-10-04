--
-- N-bit Shift-Register
-- (parallel in, serial out, with clock enable and asynchronous reset)
--
-- Shifting in zeros
--
----------------------------------------------------------------------
-- Author: Kai Poggensee
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity SHIFT_REGISTER_P2S is
	generic (
		WIDTH				: positive; 
		LSBFIRST			: boolean := true
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		D_i					: in std_logic_vector(WIDTH-1 downto 0);
		LOAD_i				: in std_ulogic;
		SHIFT_EN_i			: in std_ulogic;
		S_o					: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of SHIFT_REGISTER_P2S is

	signal D_PREP		  	: std_logic_vector(WIDTH-1 downto 0);
	signal D				: std_logic_vector(WIDTH-1 downto 0);

begin


	LSBGEN_D: if (LSBFIRST) generate
		D_PREP <= '0' & D(WIDTH-1 downto 1);
	end generate;
	MSBGEN_D: if (not LSBFIRST) generate
		D_PREP <= D(WIDTH-2 downto 0) & '0';
	end generate;

	P2S_REG: process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			D <= (others => '0');

		elsif (rising_edge(CLK_i)) then
			if (LOAD_i = '1') then
				D <= D_i;
			elsif (CLK_EN_i = '1' and SHIFT_EN_i = '1') then
				D <= D_PREP;
			end if;
		end if;
	end process;
	
	LSBGEN_S: if (LSBFIRST) generate
		S_o <= D(0);
	end generate;
	MSBGEN_S: if (not LSBFIRST) generate
		S_o <= D(WIDTH-1);
	end generate;

end architecture;
