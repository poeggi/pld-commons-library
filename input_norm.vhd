--
-- Input Normalizer
--
--
-- This normalizer provides means to normalize a
-- signal depending on its logic (active low/high)
--
--
-- Level controls which of the edges should be used
-- as a starting point to generate the normalized signal.
--
--
-- Example1: (Level: 1, Length: 2) - the default!
--
--				  _   _   _   _   _   _   _   _   _   _   _   _
--		 CLK_i: _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--						__________   _____
--	   INPUT_i: _______/		  \_/	 \__/\_________________
--								  _______
-- INPUT_NORMD_o: _________________/	   \______________________
--
--
--
-- Example2: (Level: 0, Length: 4)
--
--				  _   _   _   _   _   _   _   _   _   _   _   _
--		 CLK_i: _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--				____				   _________	  __________
--	   INPUT_i:	 \_________________/		 \____/
--				_________________________			 __________
-- INPUT_NORMD_o:						  \___________/
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity INPUT_NORM is
	generic (
		LEVEL				: std_ulogic := '1'; -- normalize high
		LENGTH				: positive := 2
	);
	port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_NORMD_o		: out std_ulogic
	);
end entity;

architecture BEHAVIOUR of INPUT_NORM is

	component INPUT_PULSE is
	generic (
		EDGE				: std_ulogic := '1'; -- default to rising edge
		TOLEVEL				: std_ulogic := '1' -- default to positive pulse
	);
	port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_PULSD_o		: out std_ulogic
	);
	end component;


	component XTIMER is
	generic (
		X					: positive := 1
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLR_i				: in std_ulogic;
		EN_i				: in std_ulogic;
		DONE_o				: out std_ulogic
	);
	end component;


	signal INPUT_OPTINV_IN  : std_ulogic;
	signal INPUT_DEBOUNCED  : std_ulogic;
	signal INPUT_PULSD		: std_ulogic;
	signal INPUT_EXT		: std_ulogic;
	signal INPUT_OPTINV_OUT : std_ulogic;


begin

	-- 
	-- STAGE 0: optional inversion
	--

	INPUT_OPTINV_IN <= (INPUT_i xor LEVEL);


	--
	-- STAGE 1: de-bounce
	--
	-- combine various pulses which have a maximum
	-- distance of LENGTH cycles into one "block"
	MY_INPUT_DEBOUNCE: XTIMER
	generic map (
		X					=> LENGTH
	)
	port map (
		nRST_i				=> INPUT_OPTINV_IN,
		CLK_i				=> CLK_i,
		CLR_i				=> '0', -- never clear
		EN_i				=> '1', -- always enable
		DONE_o				=> INPUT_DEBOUNCED
	);

	-- Output:  ---.__LENGTH+X___,---


	--
	-- STAGE 2: make pulse from edge
	--
	-- buffer the reset and trim the block to one clock cycle
	MY_INPUT_PULSE_INST: INPUT_PULSE
	generic map (
		EDGE				=> LEVEL,
		TOLEVEL				=> LEVEL
	)
	port map (
		CLK_i				=> CLK_i,
		INPUT_i				=> INPUT_DEBOUNCED,
		INPUT_PULSD_o		=> INPUT_PULSD
	);

	-- Output:  ---._,---


	--
	-- STAGE 3: extend the pulse
	--
	MY_INPUT_EXT_INST: XTIMER
	generic map (
		X					=> LENGTH
	)
	port map (
		nRST_i				=> INPUT_PULSD,
		CLK_i				=> CLK_i,
		CLR_i				=> '0', -- never clear
		EN_i				=> '1', -- always enable
		DONE_o				=> INPUT_EXT
	);

	-- Output:  ---.__LENGTH___,---

	--
	-- STAGE 4: optional inversion
	--
	INPUT_OPTINV_OUT <= (INPUT_EXT xor LEVEL);

	--
	-- STAGE 5: map to output
	--
	INPUT_NORMD_o <= INPUT_OPTINV_OUT;

end architecture;
