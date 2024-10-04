--
-- Event (edge) mitigation unit
--
--
-- This core mitigates events. It can be used to do e.g.
-- interrupt mitigation (limit the number of IRQs per time).
--
-- An edge is considered a event.
-- If the DROP flag is set, events that fall into a time
-- frame where no new events are allowed yet will be ignored.
-- If DROP is false, then a stop event falling into the
-- time-frame where the start event has not yet been passed
-- through will immediately trigger an event on the output.
--
--
-- An example of the basic functionality:
--
--  EVENT_EDGE:   '1'
--  MIN_DISTANCE: 500
--  DROP:		 false
--
--					_   _   _   _   _   _   _   _   _   _   _   _   _   _   _
--  (CLK_i/100):	   |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| 
--
--						_______		 ___________	 ___
--  INPUT:		   ____/	   \_______/		   \___/   \_________________
--						_______			 _______		 ___
--  INPUT_MITIGATED: ____/	   \___________/	   \_______/   \_____________
--
--  (start event:)	   x			   x			   x
--  (end event:)				  x				  x	   x
--  (event allowed:) YYYYYnnnnnnnnnnnnnnnnnnnYnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYY
--
--
-- NOTE: all inputs have to be fully synchronous!
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.helper-functions.all;


entity EVENT_MITIGATE is
	generic (
		EVENT_EDGE			: std_ulogic := '1'; -- default to rising edge
		MIN_DISTANCE		: positive;
		DROP				: boolean
	);
	port (
		RST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_MITIGATED_o	: out std_ulogic
	);
end emtity;


architecture BEHAVIOR of EVENT_MITIGATE is

	--
	-- auto-sizing
	--
							
	constant DIST_CNT_WIDHT : positive
							:= log2_ceil(MIN_DISTANCE);

	--
	-- signals
	--

	signal INPUT_REGD	 	: std_ulogic;
	signal START_EVENT		: std_ulogic;
	signal END_EVENT		: std_ulogic;


	signal DIST_CNT			: unsigned(DIST_CNT_WIDTH-1 downto 0);


	signal INPUT_MITIGATED  : std_ulogic;


begin

	--
	-- event generation
	--

	INPUT_REG_PROC: process( RST_i, CLK_i )
	begin
		if ( RST_i = '1' ) then
			INPUT_REGD <= '0' after SYMDEL;
		elsif ( rising_edge(CLK_i) ) then
			INPUT_REGD <= INPUT_i after SYMDEL;
		end if;
	end process;


	START_EVENT <= '1' after SYMDEL
					when ((INPUT_i = EVENT_EDGE) and (INPUT_REGD = not EVENT_EDGE))
					else
				   '0' after SYMDEL;

	END_EVENT   <= '1' after SYMDEL
					when ((INPUT_i = not EVENT_EDGE) and (INPUT_REGD = EVENT_EDGE))
					else
				   '0' after SYMDEL;


	--
	-- counter
	--

	DIST_CNT_PROC: process(RST_i, CLK_i)
	begin
		if ( RST_i = '1' ) then
			ALLOW_EVENT <= '1' after SYMDEL;
			DIST_CNT <= (others => '0') after SYMDEL;

		elsif ( rising_edge(CLK_i) ) then

			if ( START_EVENT = '1' ) then -- clear
				ALLOW_EVENT <= '0' after SYMDEL;
				DIST_CNT <= (others => '0') after SYMDEL;
			elsif ( DIST_CNT = MIN_DISTANCE ) then -- enable
				ALLOW_EVENT <= '1' after SYMDEL;
			else -- count
				DIST_CNT <= DIST_CNT + 1 after SYMDEL;
			end if;
			
		end if;
	end if;


	--
	-- event generation
	--

	INPUT_MITIGATED <= '1' after SYMDEL
						when ((INPUT_i = EVENT_EDGE) and (ALLOW_EVENT = '1')) or
							 ((ALLOW_EVENT = '0') and (END_EVENT = '1') and (DROP = false))
						else
					   '0' after SYMDEL;


	INPUT_REG_PROC: process( RST_i, CLK_i )
	begin
		if ( RST_i = '1' ) then
			INPUT_MITIGATED_o <= '0' after SYMDEL;
		elsif ( rising_edge(CLK_i) ) then
			INPUT_MITIGATED <= INPUT_MITIGATED after SYMDEL;
		end if;
	end process;

end architecture;
