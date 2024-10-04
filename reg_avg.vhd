--
-- Averaging Register
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;


entity REG_AVG is
	generic (
		DEPTH				: positive;
		REG_WIDTH			: positive
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		EN_i				: in std_ulogic;
		REG_i				: in unsigned( REG_WIDTH-1 downto 0 );
		AVG_o				: out unsigned( REG_WIDTH-1 downto 0 )
	);
end entity;


architecture BEHAVIOUR of REG_AVG is
							 
	signal AVG				: unsigned( REG_WIDTH-1 downto 0 );
	signal SUM				: unsigned( REG_WIDTH-1 downto 0 );

	signal UPDATE_SUM	  	: std_ulogic;

	type REG_ARRAY_TYPE		is array( 0 to DEPTH-1 )
							of unsigned( REG_WIDTH-1 downto 0 );

	signal TEMP_REG			: REG_ARRAY_TYPE;

	signal OLD_REG			: unsigned( REG_WIDTH-1 downto 0 );

begin

	process (nRST_i, CLK_i)
	begin
		if ( nRST_i = '0' ) then
			UPDATE_SUM <= '0';

			AVG <= (others => '0');
			for N in 0 to DEPTH-1 loop
				TEMP_REG(N) <= (others => '0');
			end loop;
			OLD_REG <= (others => '0');

			SUM <= (others => '0');

		elsif ( rising_edge(CLK_i) ) then
			UPDATE_SUM <= '0';

			AVG <= SUM / DEPTH;

			if ( EN_i = '1' ) then
				UPDATE_SUM <= '1';

				TEMP_REG(0) <= REG_i;
				for N in 1 to DEPTH-1 loop
					TEMP_REG(N) <= TEMP_REG(N-1);
				end loop;
				OLD_REG <= TEMP_REG(DEPTH-1);
			end if;


			if ( UPDATE_SUM = '1' ) then
				SUM <= (SUM - OLD_REG)
						+ TEMP_REG(0);
			end if;

		end if;
	end process;

	-- output mapping
	AVG_o <= AVG;

end architecture;
