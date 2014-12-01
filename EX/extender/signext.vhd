library ieee;
use ieee.std_logic_1164.all;

entity signext is
generic
(
	WIDTH_IN : positive := 16;
	WIDTH_OUT : positive := 32
);
port
(
	in0 : in std_logic_vector(WIDTH_IN-1 downto 0);
	out0 : out std_logic_vector(WIDTH_OUT-1 downto 0)
);
end signext;

architecture arch of signext is
begin
	process(in0)
	begin
		out0 <= (others => '0');
		out0(WIDTH_IN-1 downto 0) <= in0(WIDTH_IN-1 downto 0);
		if(in0(WIDTH_IN-1) = '0') then
			--out0 <= x"0000" & in0;
			for i in WIDTH_IN to WIDTH_OUT-1 loop
				out0(i) <= '0';
			end loop;
		else
			--out0 <= x"FFFF" & in0;
			for i in WIDTH_IN to WIDTH_OUT-1 loop
				out0(i) <= '1';
			end loop;
		end if;
	end process;
end arch;