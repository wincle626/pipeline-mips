--contains data memory connections and an and gate for Z and Branch
library ieee;
use ieee.std_logic_1164.all;

entity MEM_unit is
port
(	
	ALUout_in : in std_logic_vector(31 downto 0);
	Data_Address : out std_logic_vector(31 downto 0);
	
	Rb_in : in std_logic_vector(31 downto 0);
	Data_to_Memory_out : out std_logic_vector(31 downto 0);
	
	Data_Memory_out_in : in std_logic_vector(31 downto 0);
	Data_Memory_out_out : out std_logic_vector(31 downto 0);
	
	Rw_in : in std_logic_vector(4 downto 0); --from EX_MEM register
	Rw_out : out std_logic_vector(4 downto 0);
	
	--control signals
	MemWr_in : in std_logic;
	MemWr_out : out std_logic;
	byte_ena_in : in std_logic_vector(3 downto 0);
	byte_ena_out : out std_logic_vector(3 downto 0)
);
end MEM_unit;

architecture arch of MEM_unit is
begin
	Data_Address <= ALUout_in;
	Data_to_Memory_out <= Rb_in;
	Data_Memory_out_out <= Data_Memory_out_in;
	MemWr_out <= MemWr_in;
	byte_ena_out <= byte_ena_in;
	
	Rw_out <= Rw_in;
end architecture arch;
