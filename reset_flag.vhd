--
-- Reset Flag
--
--
-- This instance will detect if the FPGA has been reset
-- again - after the first (initial power up) reset.
--
--
-- NOTE: Connect the (possibly asynchronous) reset to the
--	   reset input of this instance. If triggered it
--	   will lead to flag assertion. This flag will only
--	   be removed when the system is power-cycled.
--
--
-- WARNING! WARNING ! WARNING ! WARNING ! WARNING ! WARNING !
--
--
-- this is highly technology dependent behavior
-- and likely to explode on untested hardware/tool-chains!
--
-- Tested on Lattice HW, ISPLever, SP2 - Precision synthesis.
--
--
-- WARNING! WARNING ! WARNING ! WARNING ! WARNING !
-- 
---------------------------------------------------------------------
-- Author: Kai Poggensee
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity RESET_FLAG is
	port (
		RST_ASYNC_i			: in std_ulogic;
		CLK_i				: in std_ulogic;
		RESET_FLAG_o		: out std_ulogic
	);
end entity;


architecture BEHAVIOUR of RESET_FLAG is

	component INPUT_SYNC
	generic (
		EDGE				: std_ulogic := '1'; -- default to rising edge
		STAGES				: positive := 1
	);
	port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_SYNCD_o		: out std_ulogic
	);
	end component;


	component INPUT_PULSE
	generic (
		EDGE				: std_ulogic := '1'; -- trigger on edge
		TOLEVEL				: std_ulogic := '1'  -- generate from edge
	 );
	 port (
		CLK_i				: in std_ulogic;
		INPUT_i				: in std_ulogic;
		INPUT_PULSD_o		: out std_ulogic
	);
	end component;


	component PUR_ONLY_REG is
	generic (
		RESET_VAL			: std_ulogic := '0'
	);
	port (
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;
		D_i					: in std_ulogic;
		Q_o					: out std_ulogic
	);
	end component;


	-- disable GSR optimizations
	attribute hierarchy	 	: string; --Precision attribute
	attribute GSR		  	: string; --Lattice attribute

	-- attributes to prevent optimizations on signals
	attribute dont_touch  	: boolean;	--Precision attribute
	attribute syn_keep		: boolean;	--Synplify attribute
	attribute syn_noprune 	: boolean;	--Synplify attribute


	attribute hierarchy	 of MY_RST_SYNC_INST
							: label is "preserve";
	attribute hierarchy	 of MY_RST_END_DETECT_INST
							: label is "preserve";
	attribute hierarchy	 of MY_FIRST_RESET_FLAG_INST
							: label is "preserve";
	attribute hierarchy	 of MY_RESET_FLAG_INST
							: label is "preserve";

	attribute GSR		   of MY_RST_SYNC_INST
							: label is "DISABLED";
	attribute GSR		   of MY_RST_END_DETECT_INST
							: label is "DISABLED";
	attribute GSR		   of MY_FIRST_RESET_FLAG_INST
							: label is "DISABLED";
	attribute GSR		   of MY_RESET_FLAG_INST
							: label is "DISABLED";


	-- The clock enable for the PUR register
	signal nRESET_INT		: std_ulogic;
	signal RESET_INT		: std_ulogic;
	signal RESET_SYNC		: std_ulogic;
	signal RESET_DONE		: std_ulogic;
	signal FIRST_RESET_FLAG	: std_ulogic;


	-- disable all optimizations on the reset and the register
	attribute dont_touch	of nRESET_INT
							: signal is true;
	attribute dont_touch	of RESET_INT
							: signal is true;
	
	attribute syn_keep	  	of nRESET_INT
							: signal is true;
	attribute syn_keep	  	of RESET_INT
							: signal is true;

	attribute syn_noprune   of nRESET_INT
							: signal is true;
	attribute syn_noprune   of RESET_INT
							: signal is true;

begin

	-- create a register to preserve the reset
	-- at least till after the next clock edge
	RESET_REG : process ( RST_ASYNC_i, CLK_i )
	begin
		if ( RST_ASYNC_i = '1' ) then
			-- reset default to 0 is safer for synthesis
			nRESET_INT <= '0';
		elsif ( rising_edge(CLK_i) ) then
			nRESET_INT <= '1';
		end if;
	end process;

	-- invert 
	RESET_INT <= not nRESET_INT;

	-- synchronize the asynchronous reset in
	MY_RST_SYNC_INST : INPUT_SYNC
	generic map ( EDGE => '1', STAGES => 2 )
	port map ( CLK_i, RESET_INT, RESET_SYNC );

	-- detect the end of a reset cycle and generate
	-- a short enable pulse from it
	MY_RST_END_DETECT_INST : INPUT_PULSE
	generic map ( EDGE => '0', TOLEVEL => '1' )
	port map ( CLK_i, RESET_SYNC, RESET_DONE );


	-- this flag will be set after the first power up cycle ended
	MY_FIRST_RESET_FLAG_INST : PUR_ONLY_REG
	port map (
		CLK_i				=> CLK_i,
		CLK_EN_i			=> RESET_DONE,
		D_i					=> '1',
		Q_o					=> FIRST_RESET_FLAG
	);
	

	-- this flag will get set during the second reset, i.e. first without PUR
	MY_RESET_FLAG_INST : PUR_ONLY_REG
	port map (
		CLK_i				=> CLK_i,
		CLK_EN_i			=> RESET_DONE,
		D_i					=> FIRST_RESET_FLAG,
		Q_o					=> RESET_FLAG_o
	);

end architecture;
