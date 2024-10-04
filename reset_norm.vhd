--
-- Reset Normalizer
-- 
-- This normalizer can be use as _the_ default way to
-- generate an PLD internal power-on-reset.
--
-- It can be fed an asynchronous reset and will
-- generate four resets, all of them synchronously
-- de-asserted to the rising edge of the clock.
--
-- Positive and negative logic, both slow and long
--
--
-- Example1: (Level: 1, LongLength: 4, ShortLength: 2) 
--
--                  _   _   _   _   _   _   _   _   _   _   _   _
--         CLK_i: _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--                    ______            _
--   RST_ASYNC_i: ___/      \__________/ \________________________
--
--   int.counter: U >< 0      ><1 ><2 ><0 ><1 ><2 >< 3	  
--
--                    __________________________________		   
--    RST_LONG_o: ___/                                  \_________
--                ___                                    _________
--   nRST_LONG_o:    \__________________________________/
--
--                    _____________	    ________
--   RST_SHORT_o: ___/             \___/        \_________________
--                ___               ___          _________________
--  nRST_SHORT_o:    \_____________/   \________/
--
--
-- Note that the actual length of the reset can be longer
-- than defined. This is because this reseter sets reset
-- asynchronously and releases it synchronously.
--
-- Note also that RST_SHORT can get thrown multiple times
-- during a single RST_SHORT cycle. Still, RST_LONG will always
-- be last to be de-asserted.
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity RESET_NORM is
	generic (
		LEVEL				: std_ulogic := '1'; -- normalize high
		LONGLENGTH			: positive;
		SHORTLENGTH			: natural
	);
	port (
		RST_ASYNC_i			: in std_ulogic;
		CLK_i				: in std_ulogic;
		RST_LONG_o			: out std_ulogic;
		nRST_LONG_o			: out std_ulogic;
		RST_SHORT_o			: out std_ulogic;
		nRST_SHORT_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of RESET_NORM is

	-- not really needed ;)
	function max(LEFT, RIGHT: natural) return natural is
	begin
		if ( LEFT > RIGHT ) then
			return LEFT;
		else
			return RIGHT;
		end if;
	end;

	constant COUNTER_LEN	: natural := max(SHORTLENGTH, LONGLENGTH);


	signal COUNTER			: unsigned(log2_ceil(COUNTER_LEN)-1 downto 0);

	signal RST_SHORT		: std_ulogic;						  
	signal RST_LONG			: std_ulogic;						  

begin

	--
	-- error checking
	--

	assert ( LONGLENGTH >= SHORTLENGTH )
		report "Error report: LONGLENGTH _must_ be >= than SHORTLENGTH!"
		severity error;


	--
	-- counter
	--

	MY_RST_COUNTER_PROC : process ( RST_ASYNC_i, CLK_i )
	begin
		if ( RST_ASYNC_i = LEVEL ) then

			RST_LONG <= '1';
			RST_SHORT <= '1';

			COUNTER <= (others => '0');

		elsif ( rising_edge(CLK_i) ) then

			RST_LONG <= '1';
			RST_SHORT <= '1';

			if ( COUNTER < (LONGLENGTH-1) ) then

				if ( COUNTER >= (SHORTLENGTH-1) ) then
					RST_SHORT <= '0';
				end if;

				COUNTER <= COUNTER + 1;

			else
				-- stop here until next reset
				RST_LONG <= '0';
				RST_SHORT <= '0';
			end if;

		end if;
	end process;


	--
	-- Output mappings
	--

	RST_SHORT_o <= RST_SHORT;
	nRST_SHORT_o <= not RST_SHORT;

	RST_LONG_o <= RST_LONG;
	nRST_LONG_o <= not RST_LONG;

end architecture;
