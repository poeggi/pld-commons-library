--
-- Generic register stages 
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;

entity REG_S is
	generic (
		EDGE				: std_ulogic := '1';
		STAGES				: positive := 1;
		RSTVAL				: std_ulogic := '0'
	);
	port (
		RST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		EN_i				: in std_ulogic;

		D_i					: in std_ulogic;
		Q_o					: out std_ulogic
	);
end entity;


architecture BEHAVIOR of REG_S is

	type SYNC_D_TYPE		is array(0 to STAGES)
							of std_ulogic;

	signal D_INT			: SYNC_D_TYPE;

begin

	-- input mapping
	D_INT(0) <= D_i;


	RISING_EDGE_GEN : if ( EDGE = '1' ) generate

		-- Generate synchronization stages
		SYNC_STAGES_GEN: for N in 1 to STAGES generate
			MY_STAGE_N: process( RST_i, CLK_i )
			begin
				if ( RST_i = '1' ) then
					D_INT(N) <= RSTVAL;
				elsif ( rising_edge(CLK_i) ) then
					if ( EN_i = '1' ) then
						D_INT(N) <= D_INT(N-1);
					end if;
				end if;
			end process;
		end generate;

	end generate;



	FALLING_EDGE_GEN : if ( EDGE /= '1' ) generate

		-- Generate synchronization stages
		SYNC_STAGES_GEN: for N in 1 to STAGES generate
			MY_STAGE_N: process( RST_i, CLK_i )
			begin
				if ( RST_i = '1' ) then
					D_INT(N) <= RSTVAL;
				elsif ( falling_edge(CLK_i) ) then
					if ( EN_i = '1' ) then
						D_INT(N) <= D_INT(N-1);
					end if;
				end if;
			end process;
		end generate;

	end generate;

	-- map last stages output to entity output
	Q_o <= D_INT(STAGES);

end architecture;
