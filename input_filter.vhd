--
-- Input Filter
-- 
-- Only accept an input signal transition if it has
-- a certain length.
--
-- This module can be used to filter glitches.
--
-- !!! NOTE: the input signal is _required_ to be   !!!
-- !!!	   registered with respect to CLK.		!!!
-- !!!	   If it is not, then sync it!			!!!
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity INPUT_FILTER is
	generic (
		MINLENGTH			: positive
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_FILTERD_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOR of INPUT_FILTER is

	signal WAITING_FOR_LEVEL : std_ulogic;
	signal INPUT_FILTERD	: std_ulogic;
	signal COUNTER			: unsigned(log2_ceil(MINLENGTH)-1 downto 0);

begin

	-- register (to generate a reference value)
	CLEAN_PROC: process ( nRST_i, CLK_i )
	begin
		if (nRST_i = '0') then
			WAITING_FOR_LEVEL <= '0';
			INPUT_FILTERD <= '0';

			COUNTER <= (others => '0');

		elsif (rising_edge(CLK_i)) then

			-- only true after reset
			if ((INPUT_FILTERD = '0') and (WAITING_FOR_LEVEL ='0')) then
				-- set initial values when starting up
				WAITING_FOR_LEVEL <= not INPUT_i;
				INPUT_FILTERD <= INPUT_i;

			-- new level was stable for defined time
			elsif (COUNTER = MINLENGTH-1) then
				-- switch to other edge
				WAITING_FOR_LEVEL <= not WAITING_FOR_LEVEL;
				-- what we are not waiting for anymore is what we have... ;)
				INPUT_FILTERD <= WAITING_FOR_LEVEL;
				COUNTER <= (others => '0');

			else
			-- only start counting if pin level changed
				if (INPUT_i = WAITING_FOR_LEVEL) then
					COUNTER <= COUNTER + 1;
				else
					COUNTER <= (others => '0');
				end if;
			end if;
		end if;
	end process;

	-- output mapping
	INPUT_FILTERD_o <= INPUT_FILTERD;

end architecture;
