library ieee;
use ieee.std_logic_1164.all;

entity extender is
port
(
	in0 : in std_logic_vector(15 downto 0);
	out0 : out std_logic_vector(31 downto 0);
	sel : in std_logic
);
end extender;

architecture arch of extender is

signal sign_out, zero_out : std_logic_vector(31 downto 0);

begin
	SIGN : entity work.signext
	port map
	(
		in0 => in0,
		out0 => sign_out
	);
	
	ZERO : entity work.zeroext
	port map
	(
		in0 => in0,
		out0 => zero_out
	);
	
	out0 <= zero_out when sel = '0' else
			  sign_out;
end arch;
			  