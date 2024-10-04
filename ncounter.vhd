--
-- adaptable N-bit counter
--
-----------------------------------------------------------------------------
-- Author: Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;


entity NCOUNTER is
	generic (
		N					: positive
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLR_i				: in std_ulogic;
		EN_i				: in std_ulogic;
		Q_o					: out std_logic_vector(N-1 downto 0)
	);
end entity;


architecture BEHAVIOUR of NCOUNTER is

	signal COUNTER		  : unsigned(N-1 downto 0);

begin

	MY_COUNTER_PROC : process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			COUNTER <= (others => '0');
		elsif ( rising_edge(CLK_i) ) then
			if ( CLR_i = '1' ) then
				COUNTER <= (others => '0');
			elsif ( EN_i = '1' ) then
				COUNTER <= COUNTER + 1;
			end if;
		end if;
	end process;
 
	-- signal mapping
	Q_o <= std_logic_vector(COUNTER);

end architecture;
