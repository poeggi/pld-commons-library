--
-- Input Vector Filter
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


entity INPUT_VECTOR_FILTER is
	generic (
		MINLENGTH			: positive;
		WIDTH				: positive
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_logic_vector(WIDTH-1 downto 0);
		INPUT_FILTERD_o		: out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;


architecture BEHAVIOR of INPUT_VECTOR_FILTER is

	signal WAITING_FOR_LEVEL : std_logic_vector(WIDTH-1 downto 0);

	subtype COUNTER_TYPE_SUBTYPE is unsigned(log2_ceil(MINLENGTH)-1 downto 0);
	type COUNTER_TYPE		is array(integer range 0 to WIDTH-1)
							of COUNTER_TYPE_SUBTYPE;
	signal COUNTER			: COUNTER_TYPE;

begin

	-- register (to generate a reference value)
	CLEAN_PROC: process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			WAITING_FOR_LEVEL <= (others => '1');
			INPUT_FILTERD_o   <= (others => '0');

			for I in 0 to (WIDTH - 1) loop
				COUNTER(I)		<= (others => '0');
			end loop;

		elsif ( rising_edge(CLK_i) ) then
			for I in 0 to (WIDTH - 1) loop
				if ( COUNTER(I) = MINLENGTH-1 ) then
					-- switch to other edge
					WAITING_FOR_LEVEL(I) <= not WAITING_FOR_LEVEL(I);
					-- what we are not waiting for anymore is what we have... ;)
					INPUT_FILTERD_o(I) <= WAITING_FOR_LEVEL(I);

					-- clear counter
					COUNTER(I) <= (others => '0');
				else
					if ( INPUT_i(I) = WAITING_FOR_LEVEL(I) ) then
						COUNTER(I) <= COUNTER(I) + 1;
					else
						COUNTER(I) <= (others => '0');
					end if;
				end if;
			end loop;
		end if;
	end process;

end architecture;
