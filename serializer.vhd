--
-- N-bit Serializer
-- (parallel in, serial out, with asynchronous reset)
--
-- LOAD_i is not clock enabled, but serialization will start
-- with the first clock enable. So pulling LOAD_i once allows
-- arming the serializer (load data etc).
--
-- If the QUCIKSTART generic is TRUE, the first data-bit will
-- be visible directly after LOAD_i has been pulled. If it
-- is false, the first clock enable following START makes the
-- first bit visible,...
--
-- NOTE: If the serializer is running, no new cycle can
-- be registered. If you wish to keep serializing, simply
-- keep LOAD_i asserted and count the DONE_o pulses.
--
-------------------------------------------------------------
-- Author: Kai Poggensee
-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;

library synplify;
use synplify.attributes.all;


entity SERIALIZER is
	generic (
		SAMPLESPERBIT		: positive := 1;
		DATAWORDSIZE		: positive := 16;
		QUICKSTART			: boolean := true;
		LSBFIRST			: boolean := true
	);
	port (
		-- basics
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;
	
		-- parallel input and control
		WORD_i				: in std_logic_vector(DATAWORDSIZE-1 downto 0);
		LOAD_i				: in std_ulogic;
		ABORT_i				: in std_ulogic;
		DONE_o				: out std_ulogic;

		-- serial output and enable
		S_o					: out std_ulogic;
		OUT_EN_o			: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of SERIALIZER is

	component SHIFT_REGISTER_P2S is
	generic (
		WIDTH				: positive;
		LSBFIRST			: boolean := true
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		D_i					: in std_logic_vector(WIDTH-1 downto 0);
		LOAD_i				: in std_ulogic;
		SHIFT_EN_i			: in std_ulogic;
		S_o					: out std_ulogic
	);
	end component;


	constant CNT_STEPS	  : positive
							:= DATAWORDSIZE*SAMPLESPERBIT;

	constant CNT_MAX		: positive
							:= CNT_STEPS-1;

	constant CNT_BITS	   : natural
							:= log2_ceil(CNT_STEPS);

	signal COUNTER		  : unsigned(CNT_BITS-1 downto 0);
	signal DONE_INT		 : std_ulogic;

	signal SHIFT_ENABLE	 : std_ulogic;
	signal LOAD			 : std_ulogic;
	signal PENDING		  : std_ulogic;
	signal RUNNING		  : std_ulogic;

	subtype COMPARE_RANGE   is natural range log2_ceil(SAMPLESPERBIT)-1 downto 0;

	attribute syn_keep of SHIFT_ENABLE: signal is true;

begin

   --
   -- sanity checks
   --

   assert (2**log2_ceil(SAMPLESPERBIT) = SAMPLESPERBIT)
		report "Error report: Only two powers of two allowed for SAMPLESPERBIT!"
		severity error;


	-- load once before starting to shift
	LOAD <= '1'
			 when ((LOAD_i = '1') and (RUNNING = '0' or DONE_INT = '1'))
			 else
			'0';


	SHIFT_REG_INST: SHIFT_REGISTER_P2S
	generic map (
		WIDTH				=> DATAWORDSIZE,
		LSBFIRST			=> LSBFIRST
	)
	port map (
		nRST_i				=> nRST_i,
		CLK_i				=> CLK_i,
		CLK_EN_i			=> CLK_EN_i,

		D_i					=> WORD_i,
		LOAD_i				=> LOAD,
		SHIFT_EN_i			=> SHIFT_ENABLE,
		S_o					=> S_o
	);


	-- control register - count and generate flags
	process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			if (QUICKSTART) then -- TODO: this is a ugly hack!
				COUNTER <= to_unsigned(SAMPLESPERBIT, CNT_BITS);
			else
				COUNTER <= (others => '0');
			end if;
			DONE_INT <= '0';
			PENDING <= '0';
			RUNNING <= '0';

		elsif (rising_edge(CLK_i)) then

			if (ABORT_i = '1') then

				if (QUICKSTART) then
					COUNTER <= to_unsigned(SAMPLESPERBIT, CNT_BITS);
				else
					COUNTER <= (others => '0');
				end if;
				DONE_INT <= '1';
				PENDING <= '0';
				RUNNING <= '0';

			else

				DONE_INT <= '0';

				if (RUNNING = '1') then
					PENDING <= '0';
				-- register load (as pending) if we cannot directly load
				elsif ((LOAD_i = '1') and (CLK_EN_i = '0')) then
					PENDING <= '1';
				end if;
	
				-- first, validate the serializer output with bit0
				if ((PENDING = '1' or LOAD_i ='1') and
					((CLK_EN_i = '1') or QUICKSTART)) then
					RUNNING <= '1';
				-- only clear if no new data is available
				-- elsif (DONE_INT = '1') then
				elsif ( (COUNTER = CNT_MAX) and (CLK_EN_i = '1') ) then
					RUNNING <= '0';
				end if;

				if (DONE_INT = '1') then
					if (QUICKSTART) then
						COUNTER <= to_unsigned(SAMPLESPERBIT, CNT_BITS);
					else
						COUNTER <= (others => '0');
					end if;
				elsif (RUNNING = '1' and CLK_EN_i = '1') then
					-- todo, auto detect whats better ge or eq
					if (COUNTER = CNT_MAX) then
						DONE_INT <= '1';
					else
						COUNTER <= COUNTER + 1;
					end if;
				end if;

			end if;
			
		end if;
	end process;


	-- TODO: rework this, solve generic, remove assert sanity check
EN_MID_2N_GEN: if (SAMPLESPERBIT >= 2) generate
	SHIFT_ENABLE <= '1'
					 -- only check the required bits
					 -- when (COUNTER(log2_ceil(SAMPLESPERBIT)-1 downto 0) = SAMPLESPERBIT/2)
					 when ( COUNTER(COMPARE_RANGE) = (COMPARE_RANGE => '1') )
					 else
					'0';
end generate;
EN_RUN_GEN: if (SAMPLESPERBIT <= 1) generate	
	SHIFT_ENABLE <= RUNNING;
end generate;
	

	-- output register
	process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			DONE_o <= '0';

		elsif (rising_edge(CLK_i)) then
			-- make DONE visible at least one cycle
			if (DONE_INT = '1') then
				DONE_o <= '1';
			-- and clear on next serialization run but keep till then
			elsif (LOAD_i = '1') or (PENDING = '1') or (RUNNING = '1') then
				DONE_o <= '0';
			end if;
		end if;
	end process;  
	
	-- disable output if we have finished the cycle
	OUT_EN_o <= RUNNING;

end architecture;
