--
-- Generic clock divider
--
-- This entity generates a ripple/gated clock net!
-- Be sure to know when NOT to use this kind of clock!
--
-- BEWARE: In FPGAs, do only use this clock divider for
--		 clocks (low quality!) that are going to pads!
--
--		 If you want to generate a slow clock
--		 for internal use, do it via clock
--		 enables to prevent synthesis headache!!!
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity CLK_DIV is
	generic (
		DIV					: positive := 2
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		DIVCLK_o			: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of CLK_DIV is

	signal COUNTER			: unsigned(log2_ceil(DIV)-1 downto 0);

begin

	MY_RIPPLEDIV_PROC : process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			COUNTER <= (others => '0');
			DIVCLK_o <= '0';

		elsif ( rising_edge(CLK_i) ) then

			if ( COUNTER = DIV-1 ) then
				COUNTER <= (others => '0');
			else
				COUNTER <= COUNTER + 1;
			end if;

			if ( COUNTER >= DIV/2 ) then
				DIVCLK_o <= '0';
			else
				DIVCLK_o <= '1';
			end if;

		end if;
	end process;

end architecture;
