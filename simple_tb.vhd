library ieee;
use ieee.std_logic_1164.all;

entity simple_tb is
end simple_tb;

architecture tb of simple_tb is

signal mem_clk : std_logic := '0';
signal rst : std_logic := '1';
	
begin
	mem_clk <= not mem_clk after 1.25 ns;
	
	UUT: entity work.CPU_AND_MEMORY
		port map(mem_clk => mem_clk,
			     rst     => rst);			     
	process
	begin
		wait for 10 ns;
		
		rst <= '0';
		
		wait;
	end process;		
end architecture tb;
