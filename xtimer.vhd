--
-- A timer
--
-- This instance counts up to a certain value,
-- then asserts the "done" bit and stops counting.
-- It will restart only after being cleared or
-- after a reset.
--
-----------------------------------------------------------------------------
-- Author: Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity XTIMER is
	generic (
		X					: positive := 2 -- make x steps
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLR_i				: in std_ulogic;
		EN_i				: in std_ulogic;
		DONE_o				: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of XTIMER is

	component NCOUNTER
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
	end component;

	signal EN				: std_ulogic;
	signal Q				: std_logic_vector(log2_ceil(X)-1 downto 0);

begin
	--
	-- Instantiations
	--

	NCOUNTER_INST: NCOUNTER
	generic map(
		N					=> log2_ceil(X)
	)
	port map (
		nRST_i				=> nRST_i,
		CLK_i				=> CLK_i,
		CLR_i			 	=> CLR_i,
		EN_i				=> EN,
		Q_o					=> Q 
	);


	COUNT_COMP_PROC : process ( Q, CLR_i, EN_i )
	begin
		if (( unsigned(Q) < X-1 ) or
			( CLR_i = '1' )) then
			EN <= EN_i;
		else
			EN <= '0';
		end if;
	end process;


	OUT_BUF_PROC : process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			DONE_o <= '0';
		elsif ( rising_edge(CLK_i) ) then
			if ( CLR_i = '1' ) then
				DONE_o <= '0';

			-- the counter will reach the last value
			elsif ((unsigned(Q) = X-2) and (EN = '1')) then
				DONE_o <= '1';
			end if;
		end if;
	end process;

end architecture;
