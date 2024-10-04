--
-- Input Sync
--
-- Generic input synchronization to bring any async signal into a
-- clock domain, minimizing the risk of metastability.
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity INPUT_SYNC is
	generic (
		EDGE				: std_ulogic := '1'; -- default rising edge
		STAGES				: positive := 2 -- viable default
	);
	port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_SYNCD_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOR of INPUT_SYNC is

	function only_01(B : std_ulogic) return std_ulogic is
	begin
		if ( B = '1' ) then
			return '1';
		else
			return '0';
		end if;
	end function;


	type REG_STAGES_TYPE	is array (0 to STAGES-1)
							of std_ulogic;

	signal INPUT_INT		: REG_STAGES_TYPE;

begin

	-- first stage
	RISING_EDGE_GEN : if ( EDGE = '1' ) generate
	end generate;

		FIRST_STAGE: process( CLK_i )
		begin
			if ( CLK_i'event and CLK_i = only_01(EDGE) ) then
				INPUT_INT(0) <= INPUT_i;
			end if;
		end process;

	--
	-- Generate synchronization stages
	--
	SYNC_STAGES_GEN: for N in 1 to STAGES-1 generate
		MY_STAGE_N: process( CLK_i )
		begin
			if ( CLK_i'event and CLK_i = only_01(EDGE) ) then
				INPUT_INT(N) <= INPUT_INT(N-1);
			end if;
		end process;
	end generate;

	-- map last stages output to entity output
	INPUT_SYNCD_o <= INPUT_INT(STAGES-1);

end architecture;
