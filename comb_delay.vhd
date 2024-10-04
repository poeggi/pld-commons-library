--
-- COMB Delay
-- Adding combinational delays to a path
--
--
-- WARNING!  WARNING!  WARNING!  WARNING!  WARNING! 
--
-- This is highly technology dependent behavior
-- and likely to explode on untested hardware/tool-chains!
--
-- WARNING!  WARNING!  WARNING!  WARNING!  WARNING! 
--
--
-- At the time of this writing (2012), on a Lattice ECP2-50-7, a
-- single DELAY (specified by the GENERIC) equals  approx. 2*200ps
-- of logic delay plus some routing delay. For multiple, cascaded
-- delay blocks, typical routing delay is 400 to 800ps.
--
-- Assume a delay of approx. 0.5-1ns per DELAY block as a
-- starting point to play with.
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;


entity COMB_DELAY is
	generic (
		DELAY				: positive
							:= 1
	);
	port (
		INPUT_i				: in std_ulogic;
		OUTPUT_o			: out std_ulogic
	);
end entity;

architecture BEHAVIOUR of COMB_DELAY is

	-- attributes to prevent optimizations on signals
	attribute dont_touch	: boolean; --Precision attribute
	attribute syn_keep		: boolean; --Synplify attribute
	attribute syn_noprune	: boolean; --Synplify attribute
	attribute OPT			: string;  --Lattice attribute
	attribute NOMERGE		: boolean; --Lattice mapper
	attribute NOCLIP		: string;  --Lattice map

	-- the signal for the delay line
	signal DELAY_LINE		: std_logic_vector(DELAY*2 downto 0);

	-- disable all optimizations on the delay line
	attribute dont_touch	of DELAY_LINE
							: signal is true;

	attribute syn_keep		of DELAY_LINE
							: signal is true;

	attribute syn_noprune   of DELAY_LINE
							: signal is true;

	attribute OPT			of DELAY_LINE
							: signal is "KEEP";

	attribute NOMERGE		of DELAY_LINE
							: signal is true;

	attribute NOCLIP		of DELAY_LINE
							: signal is "1";

begin

	-- input mapping
	DELAY_LINE(0) <= INPUT_i;

	--
	-- generate delay stages
	--
	DELAY_STAGES_GEN: for N in 1 to DELAY generate

		DELAY_LINE((N*2)-1) <= not DELAY_LINE((N*2)-2);
		DELAY_LINE(N*2)	 <= not DELAY_LINE((N*2)-1);
	end generate;

	-- output the last delay stage
	OUTPUT_o <= DELAY_LINE(DELAY*2);

end architecture;
