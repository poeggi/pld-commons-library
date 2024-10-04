--
-- Measure a period and output it (as multiples of reference freq. ticks)
--
--
-- Input can be any clock frequency smaller than 1/2 the reference freq.
-- and with a duty cycle resulting in longer pulses than the reference
-- frequencies period.
--
-- NOTE: This instance does no filtering on the on the input!
--	   Depending on the frequency source and phase, its output
--	   can be pretty jumpy.
--
-- If the period of the input exceeds the size possible with a defined
-- PERIODCNT_BITS width, the entity will set FREQ_LENGTH to all '1'es
-- but never lock.
--
-- PERIOD_o will initialize with all '0'es and keep this value
-- while no edges on the reference frequency are are detected.
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity PERIOD_MEASURE is
	generic(
		CLKIFREQ			: positive;  -- in Hz
		TBITS				: positive;  -- size of the counter
		TMIN				: positive;  -- in CLK_i ticks
		AVERAGEOVER			: positive   -- do averaging
							:= 1;		  -- default disable
		REFEDGE				: std_ulogic -- which edge to use
							:= '1'		 -- default rising
	);
	port(
		nRST_i			 	: in std_ulogic;
		CLK_i				: in std_ulogic; -- use a fast clock

		A_i					: in std_ulogic; -- analyze this input

		PERIOD_o			: out std_logic_vector(TBITS-1 downto 0);
		UPDATE_o			: out std_ulogic;
		LOCKED_o			: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of PERIOD_MEASURE is

	--
	-- Signals
	--
	signal A_REG			: std_ulogic;

	signal COUNTER			: unsigned(TBITS-1 downto 0);

	signal PERIOD			: unsigned(TBITS-1 downto 0);
	signal NEWVALID			: std_ulogic;
	signal PREP_LOCK		: std_ulogic;
	signal LOCKED			: std_ulogic;

	--
	-- averaging related
	--
	type AVG_REG_ARRAY		is array(natural range 1 to AVERAGEOVER)
							of unsigned(PERIOD'range);

	type AVG_CTRL_ARRAY		is array(natural range 1 to AVERAGEOVER)
							of std_ulogic;

	signal AVG_REG			: AVG_REG_ARRAY;
	signal AVG_NEWVALID		: AVG_CTRL_ARRAY;
	signal AVG_LOCKED		: AVG_CTRL_ARRAY;

begin

	--
	assert ( TMIN < (2**TBITS) )
	report "Error: Allowed minimum frequency is to large for the counter!"
		severity error;


	-- measure the length (in clk_i clock ticks) of a FREQ_i period
	GET_FREQ_PROC: process ( nRST_i, CLK_i )
	begin
		if (nRST_i = '0') then
			A_REG <= '0';

			COUNTER <= (others => '0');

			PREP_LOCK <= '0';
			LOCKED <= '0';
			NEWVALID <= '0';
			PERIOD <= (others => '0');


		elsif (rising_edge(CLK_i)) then

			A_REG <= A_i;
			NEWVALID <= '0';

			-- always count
			COUNTER <= COUNTER + 1;

			-- on the reference edge of the input
			if ((A_i = REFEDGE) and
				(A_REG = (not REFEDGE))) then

				-- make the measurement visible
				PERIOD <= COUNTER;

				-- show we are preparing a lock
				PREP_LOCK <= '1';

				-- ..but only process valid ones (and put lower bound)
				if (COUNTER >= TMIN) then

					-- system is locked with the second valid
					-- edge, thus first valid measurement aquired
					if (PREP_LOCK = '1') then
						LOCKED <= '1';
						NEWVALID <= '1';
					end if;

					COUNTER <= (others => '0');
				end if;

			-- if we overflow..
			elsif (COUNTER = (2**COUNTER'length)-1) then
				-- ..we are not locked anymore!
				PREP_LOCK <= '0';
				LOCKED <= '0';

				-- make erronous (to long) values visible
				PERIOD <= (others => '1');
			end if;
		end if;
	end process;


	--
	-- averaging generation
	--

GEN_AVG1: if (AVERAGEOVER = 1) generate
	AVG_REG(1) <= PERIOD;
	AVG_NEWVALID(1) <= NEWVALID;
	AVG_LOCKED(1) <= LOCKED;
end generate;
-- TODO: make it work for N > 2
GEN_AVGN: if (AVERAGEOVER > 1) generate
	GET_FREQ_PROC: process ( nRST_i, CLK_i )
	begin
		if (nRST_i = '0') then
			AVG_REG <= (others => (others => '0'));
			AVG_NEWVALID <= (others => '0');
			AVG_LOCKED <= (others => '0');

		elsif (rising_edge(CLK_i)) then

			if (NEWVALID = '1') then
				AVG_REG(AVERAGEOVER) <= PERIOD;
				if (AVERAGEOVER > 2) then
					for N in 2 to AVERAGEOVER-1 loop
						AVG_REG(N) <= AVG_REG(N+1);
					end loop;
				end if;
				-- TODO: average and weight the new measurements
				--	   AVG_REG(1) <= AVG_OLD_SUM + PERIOD;
				AVG_REG(1) <= resize(((AVG_REG(2) + ('0' & PERIOD))/2),
									 PERIOD'length);
			end if;

			if (NEWVALID = '1') then
				-- delay valid by number of averaging cycles..
				AVG_NEWVALID(AVERAGEOVER) <= NEWVALID;
				for N in 1 to AVERAGEOVER-1 loop
					AVG_NEWVALID(N) <= AVG_NEWVALID(N+1);
				end loop;
			else
				-- ..but only visible for one cycle
				AVG_NEWVALID(1) <= '0';
			end if;


			if (LOCKED = '0') then
				-- unlock immediately..
				AVG_LOCKED <= (others => '0');
			else
				-- ..lock after pipeline delay
				AVG_LOCKED(AVERAGEOVER) <= LOCKED;
				for N in 1 to AVERAGEOVER-1 loop
					AVG_LOCKED(N) <= AVG_LOCKED(N+1);
				end loop;
			end if;

		end if;
	end process;
end generate;


	--
	-- output mapping
	--
	PERIOD_o <= std_logic_vector(AVG_REG(1));
	UPDATE_o <= AVG_NEWVALID(1);
	LOCKED_o <= AVG_LOCKED(1);

end architecture;
