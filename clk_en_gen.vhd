--
-- Generic clock enable generator
--
-- Fully synchronous clock enable, in a ratio of the input clock.
-- Use to have lower speed design blocks on the same clock tree. 
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity CLK_EN_GEN is
	generic (
		DIV					: positive := 2
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_o			: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of CLK_EN_GEN is

	signal COUNTER			: unsigned(log2_ceil(DIV)-1 downto 0);
	signal RESTART			: std_ulogic;

begin

	MY_COUNTER_PROC : process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			COUNTER <= (others => '0');

		elsif ( rising_edge(CLK_i) ) then
			if ( RESTART = '1' ) then
				COUNTER <= (others => '0');
			else
				COUNTER <= COUNTER + 1;
			end if;
		end if;
	end process;

	MY_COUNT_CONTR_PROC : process ( COUNTER )
	begin
		if ( COUNTER = DIV-1 ) then
			RESTART <= '1';
		else
			RESTART <= '0';
		end if;
	end process;

	MY_OUT_BUF_PROC : process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			CLK_EN_o <= '0';

		elsif ( rising_edge(CLK_i) ) then
			if ( RESTART = '1' ) then
				CLK_EN_o <= '1';
			else
				CLK_EN_o <= '0';
			end if;
		end if;
	end process;

end architecture;
