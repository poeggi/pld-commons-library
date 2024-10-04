--
-- A Register that is only reset during power up!
--
-- WARNING! this is highly technology dependent behavior
-- and likely to explode on untested hardware/tool-chains!
-- 
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity PUR_ONLY_REG is
	generic (
		RESET_VAL			: std_ulogic := '0'
	);
	port (
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;
		D_i					: in std_ulogic;
		Q_o					: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of PUR_ONLY_REG is


	-- attributes to prevent optimizations
	attribute dont_touch  	: boolean;	--Precision attribute
	attribute syn_keep		: boolean;	--Synplify attribute
	attribute syn_noprune 	: boolean;	--Synplify attribute

	-- the signals
	signal SYMBOLIC_ASYNC_RESET : std_ulogic;
	signal REG_DATA			: std_ulogic;


	-- disable all optimizations on the reset and the register
	attribute dont_touch	of SYMBOLIC_ASYNC_RESET
							: signal is true;

	attribute dont_touch	of REG_DATA
							: signal is true;
	
	attribute syn_keep		of SYMBOLIC_ASYNC_RESET
							: signal is true;

	attribute syn_keep		of REG_DATA
							: signal is true;

	attribute syn_noprune   of SYMBOLIC_ASYNC_RESET
							: signal is true;

	attribute syn_noprune   of REG_DATA
							: signal is true;

begin

	-- a reset that is no reset
	SYMBOLIC_ASYNC_RESET <= '0';

	-- reset resistant register
	PUR_ONLY_REG_PROC: process ( SYMBOLIC_ASYNC_RESET, CLK_i )
	begin
		if ( SYMBOLIC_ASYNC_RESET = '1' ) then
			-- define value after PUR
			REG_DATA <= RESET_VAL;

		elsif ( rising_edge(CLK_i) ) then
			if ( CLK_EN_i = '1' ) then
				REG_DATA <= D_i;
			end if;
		end if;
	end process;

	-- map the output
	Q_o <= REG_DATA;

end architecture;
