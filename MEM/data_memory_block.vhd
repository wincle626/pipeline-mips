library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_memory_block is
port
(
	address : in std_logic_vector(9 downto 0);
	byteena : in std_logic_vector(3 downto 0);
	clock : in std_logic;
	rden	: in std_logic;
	wren	: in std_logic;
	data	: in std_logic_vector(31 downto 0);
	q : out std_logic_vector(31 downto 0)
);
end data_memory_block;

architecture arch of data_memory_block is
	
signal data_out_mem : std_logic_vector(31 downto 0);

type address_array is array(natural range <>) of std_logic_vector(7 downto 0);

signal addresses : address_array(3 downto 0);
signal base_address : std_logic_vector(7 downto 0);
signal address_inc : std_logic_vector(7 downto 0);

signal address_lsb2 : std_logic_vector(1 downto 0);

signal output : std_logic_vector(31 downto 0);
signal output_u : unsigned(31 downto 0);

signal byteen_vec : std_logic_vector(3 downto 0);

begin
	base_address <= address(9 downto 2);
	address_lsb2 <= address(1 downto 0);
	address_inc <= std_logic_vector(unsigned(base_address) + 1); --address for odd number blocks
	
	process(address_inc, address_lsb2, base_address) --generate incremented addresses for the rams	
	begin
		addresses(0) <= base_address;
		addresses(1) <= base_address;
		addresses(2) <= base_address;
		addresses(3) <= base_address; --this is always true
		case address_lsb2 is
		when "01" =>
			addresses(0) <= address_inc;
		when "10" =>
			addresses(0) <= address_inc;
			addresses(1) <= address_inc;
		when "11" =>
			addresses(0) <= address_inc;
			addresses(1) <= address_inc;
			addresses(2) <= address_inc;
		when others =>
			null;
		end case;
	end process;
	
	GEN_MEM: for i in 1 to 4 generate --instantiate 4 memories for parallel access
		byteen_vec(i-1) <= (wren and byteena(i-1));
		
		MEM_BYTE: entity work.data_memory
		port map
		(
			 address => addresses(i-1),
		     clock   => clock,
		     data    => data(i*8-1 downto (i-1)*8),
		     rden    => rden,
		     wren    => byteen_vec(i-1),
		     q       => data_out_mem(i*8-1 downto (i-1)*8)
		);
	end generate;
	
	output_u <= rotate_right(unsigned(data_out_mem),natural(8*to_integer(unsigned(address_lsb2))));
	
	output <= std_logic_vector(output_u);
	
	q(31 downto 24) <= output(31 downto 24) when byteena(3) = '1' else (others => '0'); --byteenable outputs
	q(23 downto 16) <= output(23 downto 16) when byteena(2) = '1' else (others => '0');
	q(15 downto 8) <= output(15 downto 8) when byteena(1) = '1' else (others => '0');
	q(7 downto 0) <= output(7 downto 0) when byteena(0) = '1' else (others => '0');	
		
end architecture arch;
