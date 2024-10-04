--
-- N-bit De-Serializer
-- (serial in, parallel out, with asynchronous reset)
--
-------------------------------------------------------------
-- Author: Kai Poggensee  
-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;


entity DESERIALIZER is
	generic (
		SAMPLESPERBIT		: positive := 16;
		DATAWORDSIZE		: positive;
							-- true=start with LSB, false= start with MSB
		LSBFIRST			: boolean := true
	);
	port (
		-- basics
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;
	
		-- serial interface and receive enable
		S_i					: in std_ulogic;
		S_EN_i				: in std_ulogic;

		-- parallel output and status
		WORD_o				: out std_logic_vector(DATAWORDSIZE-1 downto 0);
		WORD_RECVD_o		: out std_ulogic;
		WORD_ERROR_o		: out std_ulogic;
		CLEAR_i				: in std_ulogic
	);
end entity;


architecture BEHAVIOUR of DESERIALIZER is

	component SHIFT_REGISTER_S2P is
	generic (
		WIDTH				: positive;
							-- true=start with LSB, false= start with MSB
		LSBFIRST			: boolean := true
	);
	port (
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		SHIFT_EN_i			: in std_ulogic;
		S_i					: in std_ulogic;
		Q_o					: out std_logic_vector(WIDTH-1 downto 0);
		CLEAR_i				: in std_ulogic
	);
	end component;

	constant CNT_STEPS		: positive
							:= DATAWORDSIZE*SAMPLESPERBIT;

	constant CNT_MAX		: positive
							:= CNT_STEPS-1;

	constant CNT_BITS		: natural
							:= log2_ceil(CNT_STEPS);

	signal COUNTER			: unsigned(CNT_BITS-1 downto 0);
	signal Q_INT			: std_logic_vector(DATAWORDSIZE-1 downto 0);
	signal DONE_INT			: std_ulogic;
	signal DESER_ACTIVE		: std_ulogic;
	signal SHIFT_ENABLE		: std_ulogic;
	signal WORD_RECVD		: std_ulogic;
	signal WORD_ERROR		: std_ulogic; --TODO: implement!


begin

   --
   -- sanity checks
   --

   -- TODO: implement more generic bit-enable, then remove this check
   assert (2**log2_ceil(SAMPLESPERBIT) = SAMPLESPERBIT)
		report "Error report: Only two powers of two allowed for SAMPLESPERBIT!"
		severity error;

	--
	-- functional code
	--

	SHIFT_REG_INST: SHIFT_REGISTER_S2P
	generic map (
		WIDTH				=> DATAWORDSIZE,
		LSBFIRST			=> LSBFIRST
	)
	port map (
		nRST_i				=> nRST_i,
		CLK_i				=> CLK_i,
		CLK_EN_i			=> CLK_EN_i,

		SHIFT_EN_i			=> SHIFT_ENABLE,
		S_i					=> S_i,
		Q_o					=> Q_INT,
		CLEAR_i				=> CLEAR_i
	);

	
	-- both signals together define if we are active
	DESER_ACTIVE <= (not CLEAR_i) and S_EN_i;

	-- control register - count and generate flags
	process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			COUNTER <= (others => '0');
			DONE_INT <= '0';

		elsif (rising_edge(CLK_i)) then
			if (CLEAR_i = '1') then
				COUNTER <= (others => '0');
				DONE_INT <= '0';
			elsif (DESER_ACTIVE = '1' and CLK_EN_i = '1' and DONE_INT = '0') then
				if (COUNTER = CNT_MAX) then
					DONE_INT <= '1';
					COUNTER <= (others => '0');
				else
					COUNTER <= COUNTER + 1;
				end if;
			end if;

		end if;
	end process;
	
	-- sample on the middle of the bit
	-- TODO: rework this, solve generic, remove assert sanity check
EN_MID_2N_GEN: if (SAMPLESPERBIT >= 2) generate
	SHIFT_ENABLE <= '1' after SYMDEL
							-- only check the required bits
					 when (COUNTER(log2_ceil(SAMPLESPERBIT)-1 downto 0) = SAMPLESPERBIT/2)
					 else
					'0';
end generate;
EN_RUN_GEN: if (SAMPLESPERBIT = 1) generate	
	SHIFT_ENABLE <= DESER_ACTIVE;
end generate;

	-- output register
	-- TODO: reduce latency!
	process (nRST_i, CLK_i)
	begin
		if (nRST_i = '0') then
			WORD_RECVD <= '0';
			WORD_ERROR <= '0';
			WORD_o <= (others => '0');

		elsif (rising_edge(CLK_i)) then
			if (CLEAR_i = '1') then
				WORD_RECVD <= '0';
				WORD_ERROR <= '0';
			elsif (DONE_INT = '1') then
				WORD_RECVD <= '1';
				WORD_o <= Q_INT;
			end if;
		end if;
	end process;

	WORD_RECVD_o <= WORD_RECVD;
	WORD_ERROR_o <=  WORD_ERROR;

end architecture;
