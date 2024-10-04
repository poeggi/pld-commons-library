--
-- Linear Feedback Shift Register (Galois Style)
--
--
-- The TAP bits set to '1' will be the target of a
-- XOR operation with the tail and the previous bit.
-- If the head-end bit is a TAP, its only the tail.
--
-- e.g.:
--
--  DEPTH:  4
--  TAPS: 0x1010
--
-- leads to the following structure:
--
--	,-> b3 -> b2 ->[xor] -> b1 -> b0 -,
--	|			   ^				 |
--	|			   |				 |
--	|			   |				 |
--	'---------------'-----------------'
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity LFSR_GALOIS is
	generic(
		DEPTH				: positive;
		TAPS				: std_logic_vector(DEPTH-1 downto 0);
		RESET_VECTOR		: std_logic_vector(DEPTH-1 downto 0)
							:= (others => '1')
	);
	port(
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		STATUS_o			: out std_logic_vector(DEPTH-1 downto 0);
		Q_o					: out std_ulogic

	);
end entity;


architecture BEHAVIOUR of LFSR_GALOIS is

	--
	-- Signals
	--
	signal LFSR_REG			: std_logic_vector(DEPTH-1 downto 0);
	signal LFSR_REG_PREP	: std_logic_vector(DEPTH-1 downto 0);


begin

	--
	-- sanity checks
	--
	assert ( RESET_VECTOR /= (RESET_VECTOR'range => '0') )
	report "Error: Reset Vector cannot be all zeroes!"
		severity error;


	--
	-- functional code
	--

	-- generate the TAPs as needed
	TAP_PREP_PROC: process ( LFSR_REG )
	begin

		-- the TAP on the head is not XOR'D
		if (TAPS(DEPTH-1) = '1') then
			LFSR_REG_PREP(DEPTH-1) <= LFSR_REG(0);
		end if;

		-- generate the other TAPs down to the tail automatically
		for I in DEPTH-2 downto 0 loop
			if (TAPS(I) = '1') then
				LFSR_REG_PREP(I) <= LFSR_REG(I+1) xor LFSR_REG(0);
			else
				LFSR_REG_PREP(I) <= LFSR_REG(I+1);
			end if;
		end loop;
	end process;


	-- a simple register with clock enable
	SHIFT_REG_PROC: process ( nRST_i, CLK_i )
	begin
		if (nRST_i = '0') then
			LFSR_REG <= RESET_VECTOR;

		elsif (rising_edge(CLK_i) then
			if (CLK_EN_i = '1') then
				LFSR_REG <= LFSR_REG_PREP;
			end if;
		end if;
	end process;


	--
	-- output mapping
	--

	STATUS_o <= std_logic_vector(LFSR_REG);
	Q_o <= std_logic_vector(LFSR_REG(0));

end architecture;
