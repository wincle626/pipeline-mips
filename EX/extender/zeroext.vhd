library ieee;
use ieee.std_logic_1164.all;

entity zeroext is
port
(
	in0 : in std_logic_vector(15 downto 0);
	out0 : out std_logic_vector(31 downto 0)
);
end zeroext;

architecture arch of zeroext is
begin
	out0 <= x"0000" & in0;
end arch;