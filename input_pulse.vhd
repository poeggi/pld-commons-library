--
-- Input Puls'enizer
-- 
-- Taking an input signal it produces a pulse of
-- T_CLK length on the configured edges.
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

library work;


entity INPUT_PULSE is
	generic (
		EDGE				: std_ulogic := '1'; -- trigger on edge
		TOLEVEL				: std_ulogic := '1' -- generate from edge
	);
	port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_PULSD_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOR of INPUT_PULSE is

	signal INPUT_INT		: std_ulogic;
	signal INPUT_PULSD		: std_ulogic;

begin
	-- register (to generate a reference value)
	REG_PROC: process ( CLK_i )
	begin
		if ( rising_edge(CLK_i) ) then
			INPUT_INT <= INPUT_i;
		end if;
	end process;

	-- generate the pulse
	POS_EDGE_DET_GEN: if ( EDGE = '1' ) generate
	begin
		INPUT_PULSD <= (INPUT_i and (not INPUT_INT));
	end generate;
	NEG_EDGE_DET_GEN: if ( EDGE /= '1' ) generate
	begin
		INPUT_PULSD <=  ((not INPUT_i) and INPUT_INT);
	end generate;

	-- negate the positive pulse (if requested)
	INPUT_PULSD_o <= INPUT_PULSD xor (not TOLEVEL);

end architecture;
