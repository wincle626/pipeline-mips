library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity registerFile is
generic
(
	WIDTH : positive := 32;
	NUMREGISTERS : positive := 32
);
port
(
	rr0,rr1,rw : in std_logic_vector(positive(ceil(log2(real(NUMREGISTERS))))-1 downto 0);
	q0,q1 : out std_logic_vector(WIDTH-1 downto 0);
	d : in std_logic_vector(WIDTH-1 downto 0);
	wr,clk,clr : in std_logic
);
end registerFile;

architecture arch of registerFile is	

type regArray is array(NUMREGISTERS-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);

signal ra : regArray;

begin
	process(clk,clr, wr)
	begin
		if(clr = '1') then
			for i in 0 to NUMREGISTERS-1 loop
				ra(i) <= (others => '0');
			end loop;
		elsif(falling_edge(clk) and wr = '1') then
			ra(to_integer(unsigned(rw))) <= d;
		end if;		
		
		ra(0) <= (others => '0');		
	end process;

	q0 <= ra(to_integer(unsigned(rr0)));	
	q1 <= ra(to_integer(unsigned(rr1)));
	
end architecture arch;
