--
-- Generic PWM Generator
--
--
-- Note: a DUTY_CYCLE of 255 is 100%,
--	   and 127 is 50%.
--
-- Usually we use the following formula:
-- DUTY_CYCLE = (DUTY_CYCLE_i+1)/256
--
-- There is one special case though, which
-- is the 0. It really means that the PWM
-- is disabled.
--
-- The range of usable Duty Cycles thus is:
-- (0/256), (2/256)..(256/256)
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity PWM_GEN is
	generic(
		CLKIFREQ			: positive; -- in Hz
		PWMFREQ				: positive -- in Hz
	);
	port(
		-- input
		nRST_i				: in std_logic;
		CLK_i				: in std_logic; -- use a fast clock here

		-- synchronous to CLK_i
		DUTY_CYCLE_i		: in std_logic_vector( 7 downto 0 );
		PWM_o				: out std_logic
	 );


	--
	-- Calculations for config options
	--

	constant PWM_PERIOD		: positive
							:= CLKIFREQ/PWMFREQ;

end entity;


architecture BEHAVIOUR of PWM_GEN is
							
	signal DUTY_CYCLE		: unsigned( DUTY_CYCLE_i'range );

	signal PWM_GEN_COUNTER  : unsigned( log2_ceil(PWM_PERIOD)-1 downto 0 );
	signal PWM_GEN_TICKS	: unsigned( log2_ceil(PWM_PERIOD)-1 downto 0 );
	signal PWM_GEN_HI_TICKS : unsigned( log2_ceil(PWM_PERIOD)-1 downto 0 );
	
	signal PWM				: std_ulogic;

begin

	DUTY_REG_PROC: process (nRST_i, CLK_i)
	begin
		if ( nRST_i = '0' ) then
			DUTY_CYCLE <= (others => '0');
		elsif ( rising_edge(CLK_i) ) then
			DUTY_CYCLE <= unsigned(DUTY_CYCLE_i);
		end if;
	end process;

	PWM_GEN_PROC: process ( nRST_i, CLK_i )
	begin
		if ( nRST_i = '0' ) then
			PWM <= '0';
			PWM_GEN_COUNTER <= (others => '0');
			PWM_GEN_TICKS <= (others => '0');
			PWM_GEN_HI_TICKS <= (others => '0');
		elsif ( CLK_i'event and CLK_i='1' ) then

			-- define the counter
			PWM_GEN_TICKS <= to_unsigned(PWM_PERIOD, PWM_GEN_TICKS'length)
							;

			if ( DUTY_CYCLE > 0 ) then

				-- count
				if ( (PWM_GEN_COUNTER+1) < PWM_GEN_TICKS ) then
				   PWM_GEN_COUNTER <= PWM_GEN_COUNTER + 1;
				else
					PWM_GEN_COUNTER <= (others => '0');

					-- "0 + x" is a hack to allow rhs to be shorter than lhs!
					PWM_GEN_HI_TICKS <=
--						(PWM_GEN_HI_TICKS'range => '0') +
						(
							(
								(DUTY_CYCLE+1)
								* PWM_PERIOD
							)
							/ (2**(DUTY_CYCLE'length))
						)
						after SYMDEL;
				end if;

				-- generate the output
				if ( PWM_GEN_COUNTER < PWM_GEN_HI_TICKS ) then
					PWM <= '1';
				else
					PWM <= '0';
				end if;
			else
				-- PWM disabled
				PWM <= '0';
				PWM_GEN_COUNTER <= (others => '0');
				PWM_GEN_TICKS <= (others => '0');
				PWM_GEN_HI_TICKS <= (others => '0');
			end if;
		end if;
	end process;

	-- output mapping
	PWM_o <= PWM;

end architecture;
