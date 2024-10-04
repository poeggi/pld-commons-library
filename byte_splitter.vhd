--
-- Byte Splitter
--
-- M Byte in, one byte out
-- (cutting bytes since 2008 ;0)
--
-- starting from the highest byte
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.helper-functions.all;

use work.qci_mpeg_pkg.all;


entity BYTE_SPLITTER is
	generic (
		BIG_nLITTLE_ENDIAN		: boolean := true;
		INBYTES				: positive := 8
	);
	port (
		RST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;

		-- sync. control
		DRAIN_i				: in std_ulogic;

		EN_i				: in std_ulogic;

		RDEN_o				: out std_ulogic;
		D_i				: in std_logic_vector((INBYTES*8)-1 downto 0);

		Q_o				: out std_logic_vector(7 downto 0);
		VALID_o				: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of BYTE_SPLITTER is

	constant CNT_WIDTH	  		: natural
						:= log2_ceil(INBYTES);

	signal RDEN				: std_ulogic;
	signal N				: natural range 0 to INBYTES-1;

	signal Q_ENDIAN				: std_logic_vector(7 downto 0);

begin
	-- endianness specific slicing
	BIG_GEN: if ( BIG_nLITTLE_ENDIAN = true ) generate
		Q_ENDIAN <= D_i(((INBYTES-N)*8)+7 downto (INBYTES-N)*8);
	end generate;
	LITTLE_GEN: if ( BIG_nLITTLE_ENDIAN = false ) generate
		Q_ENDIAN <= D_i((N*8)+7 downto N*8);
	end generate;


	MY_DATA_PROC: process ( RST_i, CLK_i )
	begin
		if ( RST_i = '1' ) then
			Q_o <= (others => '0');
			N <= 0;

		elsif ( rising_edge(CLK_i) ) then

			if ( DRAIN_i = '1' ) then
				Q_o <= (others => '-');
				N <= 0;

			elsif ( EN_i = '1' ) then

				if (N = INBYTES-1) then
					N <= 0;
				else
					N <= N+1;
				end if;
				
				Q_o <= Q_ENDIAN;
			   
			end if;
		end if;
	end process;

	-- generate read enable combinational as it has to be fast.
	RDEN <= '1' after SYMDEL
			 when ((N = INBYTES-1) and (EN_i = '1')) or (DRAIN_i = '1')
			 else
			'0';


	-- valid after the first read-enable
	MY_VALID_PROC: process ( RST_i, CLK_i )
	begin
		if ( RST_i = '1' ) then
			VALID_o <= '0';

		elsif ( rising_edge(CLK_i) ) then
			if ( DRAIN_i = '1' ) then
				VALID_o <= '0';
			elsif ( RDEN='1' ) then
				VALID_o <= '1';
			end if;
		end if;
	end process;

	RDEN_o <= RDEN;

end architecture;
