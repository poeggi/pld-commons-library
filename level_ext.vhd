--
-- Level extender
-- 
-- After a transition to the target level
-- has occurred, stay at that level for
-- a minimum time before following the
-- next transition on the input.
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


entity LEVEL_EXT is
	generic (
		EXT_LEVEL			: std_ulogic;
		MINLENGTH			: positive
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		SIGNAL_i			: in std_ulogic;
		SIGNAL_EXTD_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOR of LEVEL_EXT is

	signal COUNTER			: unsigned(log2_ceil(MINLENGTH)-1 downto 0);

begin

	-- register (to generate a reference value)
	EXT_PROC: process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			SIGNAL_EXTD_o <= not EXT_LEVEL;
			COUNTER <= (others => '0');

		elsif ( rising_edge(CLK_i) ) then

			if ( (SIGNAL_i = EXT_LEVEL) and (COUNTER /= 0) ) then
				-- have a transition as early as possible
				SIGNAL_EXTD_o <= SIGNAL_i;
				COUNTER <= (others => '0');
			elsif ( COUNTER /= MINLENGTH-1 ) then
				-- stay the minimum time at the target
				-- level after the transition
				COUNTER <= COUNTER + 1;
			else
				SIGNAL_EXTD_o <= SIGNAL_i;
			end if;

		end if;
	end process;

end architecture;
