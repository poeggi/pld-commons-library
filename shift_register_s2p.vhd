--
-- N-bit Shift-Register
-- (serial in, parallel out, with clock enable and asynchronous reset)
--
----------------------------------------------------------------------
-- Author: Kai Poggensee
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity SHIFT_REGISTER_S2P is
	generic (
		WIDTH				: positive;
		LSBFIRST			: boolean := true

	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		SHIFT_EN_i			: in std_ulogic;
		S_i					: in std_ulogic;
		Q_o					: out std_logic_vector(WIDTH-1 downto 0);
		CLEAR_i				: in std_ulogic
	);
end entity;


architecture BEHAVIOUR of SHIFT_REGISTER_S2P is

	signal Q_PREP			: std_logic_vector(WIDTH-1 downto 0);
	signal Q				: std_logic_vector(WIDTH-1 downto 0);

begin

	LSBGEN: if (LSBFIRST) generate
		Q_PREP <= S_i & Q(WIDTH-1 downto 1);
	end generate;
	MSBGEN: if (not LSBFIRST) generate
		Q_PREP <= Q(WIDTH-2 downto 0) & S_i;
	end generate;

	S2P_REG: process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			Q <= (others => '0');

		elsif (rising_edge(CLK_i)) then
			if (CLEAR_i = '1') then
				Q <= (others => '0');
			elsif (CLK_EN_i = '1' and SHIFT_EN_i = '1') then
				Q <= Q_PREP;
			end if;
		end if;
	end process;

	Q_o <= Q;
	
end architecture;
