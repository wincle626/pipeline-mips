--connects CPU to memory unit
library ieee;
use ieee.std_logic_1164.all;

entity CPU_AND_MEMORY is
port
(
	mem_clk,rst : in std_logic
);
end CPU_AND_MEMORY;

architecture arch of CPU_AND_MEMORY is	
	
signal Data_Address : std_logic_vector(31 downto 0);
signal Data_to_memory_out : std_logic_vector(31 downto 0);
signal MemWr_to_memory : std_logic;
signal byte_ena_to_memory : std_logic_vector(3 downto 0);
signal Data_to_CPU_in : std_logic_vector(31 downto 0);
signal Instruction_Address : std_logic_vector(31 downto 0);
signal Instruction_in : std_logic_vector(31 downto 0);

begin
	MIPS_CPU: entity work.PIPELINED_MIPS
	port map
	(
		 mem_clk             => mem_clk,
	     rst                 => rst,
	     Data_Address        => Data_Address,
	     Data_to_memory_out  => Data_to_memory_out,
	     MemWr_to_memory     => MemWr_to_memory,
	     byte_ena_to_memory  => byte_ena_to_memory,
	     Data_to_CPU_in      => Data_to_CPU_in,
	     Instruction_Address => Instruction_Address,
	     Instruction_in      => Instruction_in
	);
	
	MEMORY: entity work.memory_unit
	port map
	(
		 mem_clk      => mem_clk,
	     address_prog => Instruction_Address,
	     address_data => Data_Address,
	     data_in      => Data_to_memory_out,
	     data_out     => Data_to_CPU_in,
	     instruction  => Instruction_in,
	     byteena      => byte_ena_to_memory,
	     MemWr        => MemWr_to_memory
	);
	
end architecture arch;
