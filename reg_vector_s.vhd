--
-- Generic register stages (for vectors)
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity REG_VECTOR_S is
	generic (
		EDGE				: std_ulogic := '1';
		STAGES				: positive := 1;
		WIDTH				: positive
	);
	port (
		RST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		D_i					: in std_logic_vector(WIDTH-1 downto 0);
		Q_o					: out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;


architecture BEHAVIOR of REG_VECTOR_S is

	type REG_STAGES_TYPE	is array (0 to STAGES-1)
							of std_logic_vector(WIDTH-1 downto 0);

	signal D_INT			: REG_STAGES_TYPE;

begin

	RISING_EDGE_GEN : if ( EDGE = '1' ) generate

		FIRST_STAGE: process( RST_i, CLK_i )
		begin
			-- first stage
			if ( RST_i = '1' ) then
				D_INT(0) <= (others => '0');
			elsif ( rising_edge(CLK_i) ) then
				D_INT(0) <= D_i;
			end if;
		end process;
		
		-- Generate synchronization stages
		SYNC_STAGES_GEN: for N in 1 to STAGES-1 generate
			MY_STAGE_N: process( RST_i, CLK_i )
				begin
					if ( RST_i = '1' ) then
						D_INT(N) <= (others => '0');
					elsif ( rising_edge(CLK_i) ) then
						D_INT(N) <= D_INT(N-1);
					end if;
			end process;
		end generate;

	end generate;


	FALLING_EDGE_GEN : if ( EDGE = '0' ) generate

		FIRST_STAGE: process( RST_i, CLK_i )
		begin
			-- first stage
			if ( RST_i = '1' ) then
				D_INT(0) <= (others => '0');
			elsif ( falling_edge(CLK_i) ) then
				D_INT(0) <= D_i;
			end if;
		end process;
		
		-- Generate synchronization stages
		SYNC_STAGES_GEN: for N in 1 to STAGES-1 generate
			MY_STAGE_N: process( RST_i, CLK_i )
				begin
					if ( RST_i = '1' ) then
						D_INT(N) <= (others => '0');
					elsif ( falling_edge(CLK_i) ) then
						D_INT(N) <= D_INT(N-1);
					end if;
			end process;
		end generate;

	end generate;

	-- map last stages output to entity output
	Q_o <= D_INT(STAGES-1);

end architecture;
