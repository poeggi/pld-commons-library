--
-- Generic Address Domain Translator
--
-- This modules translates addresses from
-- A) master domain (MASTER_*), where the controller is connected to
-- B) slave domain (SLAVE_*), where the device is connected
--
-- The data byte order is specified as a huge natural number which will
-- be converted to an array inside the module.
--
-- NOTE: the implementation is completely combinational!
--	   -> as such it will impose some delay into your design!
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; --for to_integer

library work;
use work.helper-functions.all; --for log2_ceil


entity ADDRESS_DOMAIN_TRANSLATOR is
generic (
	MADRWIDTH		: positive := 8;
	MDATWIDTH		: positive := 8;
	MBYTEORDER		: natural range 0 to 76543210
				:= 76543210;
	SADRWIDTH		: positive;
	SDATWIDTH		: positive;
	SBYTEORDER		: natural range 0 to 76543210
				:= 76543210
);
port (
	MASTER_ADDR_i		: in  std_logic_vector(MADRWIDTH-1 downto 0);
	MASTER_DATA_i		: in  std_logic_vector(MDATWIDTH-1 downto 0);
	MASTER_BYTE_EN_i	: in  std_logic_vector((MDATWIDTH/8)-1 downto 0);
	MASTER_DATA_o		: out std_logic_vector(MDATWIDTH-1 downto 0);

	SLAVE_ADDR_o		: out std_logic_vector(SADRWIDTH-1 downto 0);
	SLAVE_DATA_i		: in  std_logic_vector(SDATWIDTH-1 downto 0);
	SLAVE_DATA_o		: out std_logic_vector(SDATWIDTH-1 downto 0);
	SLAVE_BYTE_EN_o		: out std_logic_vector((SDATWIDTH/8)-1 downto 0)
);
end entity;

architecture behaviour of ADDRESS_DOMAIN_TRANSLATOR is

	subtype BYTE_NUM is natural range 0 to (SDATWIDTH/8-1);
	type BYTE_ORDER_ARRAY is array (natural range <>) of BYTE_NUM;
	signal MBYTE_ORDER_A: BYTE_ORDER_ARRAY(MDATWIDTH/8-1 downto 0);
	signal SBYTE_ORDER_A: BYTE_ORDER_ARRAY(SDATWIDTH/8-1 downto 0);

	constant SDAT_ABITS 	: natural := log2_ceil(SDATWIDTH/8);
	signal adr_idx		: integer range 0 to (SDATWIDTH/8-1);
	constant BYTE_EN	: bit_vector(SLAVE_BYTE_EN_o'range)
				:= (0 => '1', others => '0');

begin

	--
	-- Generic/config options and port list sanity checks
	--
	assert( (MDATWIDTH/8) = 1 )
		report "ERROR: Master side data width must be 1 byte!"
		severity failure;

	assert( (MDATWIDTH mod 8) = 0 and MDATWIDTH > 0 )
		report "ERROR: Master data vector lengths must be a multiple of 8!"
		severity failure;

	assert( (SDATWIDTH/8) <= 8 )
		report "ERROR: Slave side data width max. 8 bytes supported!"
		severity failure;

	assert( (SDATWIDTH mod 8) = 0 and SDATWIDTH > 0 )
		report "ERROR: Slave data vector lengths must be a multiple of 8!"
		severity failure;

	
	M_CHECK_ARRAY: for I in 0 to MBYTE_ORDER_A'length-2 generate
		M_CHECK_UNIQUE: for J in I+1 to MBYTE_ORDER_A'length-1 generate
			assert ( (MBYTEORDER / (10**I)) /= (MBYTEORDER / (10**J)) )
				report "Master byte order array elements must be unique MBYTEORDER("
					   &integer'image(I) &") : " &integer'image(MBYTEORDER / (10**I))
					   &", MBYTEORDER(" &integer'image(J) &") : " &integer'image(MBYTEORDER / (10**J))
				severity failure;
		end generate;
	end generate;

	S_CHECK_ARRAY: for I in 0 to SBYTE_ORDER_A'length-2 generate
		S_CHECK_UNIQUE: for J in I+1 to SBYTE_ORDER_A'length-1 generate
			assert ( (SBYTEORDER / (10**I)) /= (SBYTEORDER / (10**J)) )
				report "Slave byte order array elements must be unique SBYTEORDER("
					   &integer'image(I) &") : " &integer'image(SBYTEORDER / (10**I))
					   &", SBYTEORDER(" &integer'image(J) &") : " &integer'image(SBYTEORDER / (10**J))
				severity failure;
		end generate;
	end generate;

	


	M_ARRAY_GEN: for I in MBYTE_ORDER_A'range generate
		MBYTE_ORDER_A(I) <= ( (MBYTEORDER/(10**I)) mod 10);
	end generate;

	S_ARRAY_GEN: for I in SBYTE_ORDER_A'range generate
		SBYTE_ORDER_A(I) <= ( (SBYTEORDER/(10**I)) mod 10);
	end generate;

	
	-- This signal serves as index to byte order array
	adr_idx <= to_integer(unsigned(MASTER_ADDR_i(SDAT_ABITS-1 downto 0)));


	--
	-- Slave outputs
	--

	-- Set upper (unused) bits to zero
	OUTADDR_MAP: if (SLAVE_ADDR_o'length > MASTER_ADDR_i'length) generate
		SLAVE_ADDR_o(SLAVE_ADDR_o'left downto MASTER_ADDR_i'length)
			<= (others => '0');
	end generate;

	-- Lower bits are always zero
	SLAVE_ADDR_o <= resize_msb(MASTER_ADDR_i(MASTER_ADDR_i'left downto SDAT_ABITS),
					   MASTER_ADDR_i'length);

	-- Map input data byte to all output data bytes (duplicate)
	OUTDATA_MAP: process(MASTER_DATA_i)
	begin
		for I in 0 to ((SDATWIDTH/8)-1) loop
			SLAVE_DATA_o(I*8+7 downto I*8) <= MASTER_DATA_i;
		end loop;
	end process;

	-- TODO: this must be based on MASTER_BYTE_EN_i
	-- do similar to this untested code:
	--OUTSEL_MAP: process(adr_idx)
	--begin
	--	for I in SLAVE_BYTE_EN_i'range loop
	--		SLAVE_BYTE_EN_o(I) <= MASTER_BYTE_EN_i(SBYTE_ORDER_A(adr_idx));
	--	end loop;
	--end process;
	
	-- NOTE: code only supporting 8-bit slave interface
	SLAVE_BYTE_EN_o <= to_stdlogicvector(BYTE_EN sll SBYTE_ORDER_A(adr_idx));


	--
	-- Master output
	--
	MASTER_DATA_o   <= SLAVE_DATA_i(SBYTE_ORDER_A(adr_idx)*8+7 downto SBYTE_ORDER_A(adr_idx)*8);

end architecture;
