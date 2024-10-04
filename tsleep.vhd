--
-- Timer Sleep
--
-----------------------------------------------------------------------------
-- Author: Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.helper-functions.all;


entity TSLEEP is
	generic (
		T					: time := 1 ns
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLR_i				: in std_ulogic;
		EN_i				: in std_ulogic;
		DONE_o				: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of TSLEEP is

	component NCOUNTER
		generic (
			N				: natural := 8
		);
		port (
			nRST_i			: in std_ulogic;
			CLK_i			: in std_ulogic;
			CLR_i			: in std_ulogic;
			EN_i			: in std_ulogic;
			Q_o				: out std_logic_vector(N-1 downto 0)
		);
	end component;

	signal EN				: std_ulogic;
	signal Q				: std_logic_vector(log2_ceil(T/CLK_CYC)-1 downto 0);

begin
	--
	-- Sanity checks
	--

	assert (T >= CLK_CYC)
		report "The sleep time T is to small! Will sleep 0 cycles!"
		severity Warning;


	--
	-- Instantiations
	--

	MY_NCOUNT_INST : NCOUNTER
	generic map(
		N					=> log2_ceil(T/CLK_CYC)
	)
	port map (
		nRST_i				=> nRST_i,
		CLK_i				=> CLK_i,
		CLR_i				=> CLR_i,
		EN_i				=> EN,
		Q_o					=> Q 
	);

	process (nRST_i, CLK_i)
		constant T_SLEEP	: natural := T/CLK_CYC;
	begin
		if ( nRST_i = '0' ) then
			EN <= '0';
			DONE_o <= '0';
			
		elsif ( rising_edge(CLK_i) ) then
			-- default
			EN <= EN_i;
			DONE_o <= '0';

			if ( Q >= To_StdLogicVector(T_SLEEP) ) then
				EN <= '0';
				DONE_o <= '1';
			end if;
		end if;
	end process;

end architecture;
