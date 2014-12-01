library ieee;
use ieee.std_logic_1164.all;

package mylib is

	function vectorize(input : std_logic) return std_logic_vector;
	
	type STD_LOGIC_VECTOR_ARR is array (positive range <>, positive range <>) of std_logic; --first range is # of vectors, second is width
	
	type BYTE_ARRAY is array(natural range <>) of std_logic_vector(7 downto 0); --pretty commonly used, array of bytes
	
	function get_vector(input : STD_LOGIC_VECTOR_ARR; width : natural; index : natural) return std_logic_vector; --a way to wrap a 2d array of std_logic into vectors
	
	procedure pack_vector(vector_array : inout STD_LOGIC_VECTOR_ARR; in_vec : in std_logic_vector; index : in natural); --packs std_logic_vector into a std_logic_vector_arr
end mylib;

package body mylib is

	function vectorize(input : std_logic) return std_logic_vector is
	
	variable v : std_logic_vector(0 downto 0);
	
	begin
		v(0) := input;
		return v;
	end;

	function get_vector(input : STD_LOGIC_VECTOR_ARR; width : natural; index : natural)  return std_logic_vector is
		
	variable ret : std_logic_vector(WIDTH-1 downto 0);
	
	begin
		for i in 0 to width-1 loop
			ret(i) := input(index,i);
		end loop;
		
		return ret;
	end;
	
	procedure pack_vector(vector_array : inout STD_LOGIC_VECTOR_ARR; in_vec : in std_logic_vector; index : in natural) is --packs std_logic_vector into a std_logic_vector_arr
	begin
		for i in 0 to in_vec'length-1 loop
			vector_array(index,i) := in_vec(i);
		end loop;
	end procedure;
		
end mylib;



-----Components

---------------------------General Width Register-------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reg_gen is
generic
(
	WIDTH : positive
);
port
(
	D : in std_logic_vector(WIDTH-1 downto 0);
	Q : out std_logic_vector(WIDTH-1 downto 0);
	wr,clk,clr : in std_logic
);
end reg_gen;

architecture arch of reg_gen is
begin
	process(clk,clr)
	begin
		if(clr = '1') then --when reset is true, output is asynch 0
			Q <= (others => '0');
		elsif(rising_edge(clk)) then --otherwise, on rising_edge update
			if(wr = '1') then --only when wr is true
				Q <= D;
			end if;
		end if;
	end process;
end arch;

---------------------------General Width Mux-------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mux_gen is
generic
(
	WIDTH : positive
);
port
(
	in1 : in std_logic_vector(WIDTH-1 downto 0);
	in0 : in std_logic_vector(WIDTH-1 downto 0);
	sel    : in std_logic;
	O		 : out std_logic_vector(WIDTH-1 downto 0)
);
end mux_gen;
	
architecture arch of mux_gen is
begin
	O <= in0 when sel = '0' else
			in1;
end arch;

---------------------------General Input/Width Mux-------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use work.mylib.all;

entity mux_gen_inputs is
generic
(
	INPUTS : positive;
	WIDTH : positive
);
port
(
	--SEL_WIDTH : in positive := positive(ceil(log2(real(INPUTS)))); this was not allowed to determine other things directly so its copy pasted in sel
	MUX_INPUTS : in STD_LOGIC_VECTOR_ARR(INPUTS-1 downto 0, WIDTH-1 downto 0); --left is # of vectors, right is their width, need the wrap function to get the vectors out
	SEL : in std_logic_vector(positive(ceil(log2(real(INPUTS))))-1 downto 0);
	OUTPUT : out std_logic_vector(WIDTH-1 downto 0)
);
end mux_gen_inputs;

architecture arch of mux_gen_inputs is

type std_logic_vector_internal_array is array(natural range <>) of std_logic_vector(WIDTH-1 downto 0);	

signal inputs_v : std_logic_vector_internal_array(INPUTS-1 downto 0);

begin
	process(mux_inputs) --process for wrapping std_logic double array into usable vectors, for readability
	begin		
		for i in 0 to width-1 loop
			inputs_v(i) <= get_vector(mux_inputs,width,i);
		end loop;
	end process;
	
	process(sel, inputs_v)
	begin
		if(unsigned(sel) < inputs-1) then			
			output <= inputs_v(to_integer(unsigned(sel)));
		else
			output <= (others => '0');
		end if;
	end process;	
end arch;

---------------------Carry Look Ahead Block Generator------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cgen2 is
	port
	(
		ci : in std_logic;
		pi : in std_logic;
		gi : in std_logic;
		pi_n : in std_logic;
		gi_n : in std_logic;
		cout_in_between : out std_logic;
		cout : out std_logic;
		bp : out std_logic;
		bg : out std_logic
	);
end cgen2;

architecture arch of cgen2 is

begin
	process(ci,pi,gi,pi_n,gi_n)
	
	begin
		cout_in_between <= (ci and pi) or gi;
		cout <= (((ci and pi) or gi) and pi_n) or gi_n;
		
		bp <= pi_n and pi;
		bg <= (gi and pi_n) or (gi_n);
	end process;
end arch;

--------------2 bit carry look ahead adder----------------
library ieee;
use ieee.std_logic_1164.all;

entity cla2 is
	port
	(
		x : in std_logic_vector(1 downto 0);
		y : in std_logic_vector(1 downto 0);
		cin : in std_logic;
		s : out std_logic_vector(1 downto 0);
		cout : out std_logic;
		bp : out std_logic;
		bg : out std_logic
	);
end cla2;

architecture arch of cla2 is

begin
	process(x,y,cin)	
	
	variable zero_to_one,g,p : std_logic;
	
	begin
		g := x(0) and y(0);
		p := (x(0) or y(0));
		zero_to_one := g or (p and cin);
		
		s(0) <= (x(0) xor y(0)) xor cin;
		s(1) <= (x(1) xor y(1)) xor zero_to_one;
		
		bg <= (x(1) and y(1)) or ((x(1) or y(1)) and g);
		bp <= (x(1) or y(1)) and p;
		
		cout <= (x(1) and y(1)) or (zero_to_one and (x(1) or y(1)));	
	end process;
end arch;

----------------------ADDER with BG and BP outputs for CLA-------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_super is 
	generic
	(
		WIDTH : positive := 4
	);
	port
	(
		 x, y  : in  std_logic_vector(WIDTH-1 downto 0);
		 cin   : in  std_logic;
		 s     : out std_logic_vector(WIDTH-1 downto 0);
		 cout  : out std_logic;
		 bg : out std_logic;
		 bp : out std_logic
	);
end adder_super;

architecture arch of adder_super is --recursive magic
	
signal bg0,bp0,bg1,bp1,cout_in_between : std_logic;
constant HALFWIDTH : positive := WIDTH/2;

signal x_low : std_logic_vector(HALFWIDTH-1 downto 0) := x(HALFWIDTH-1 downto 0);
signal y_low : std_logic_vector(HALFWIDTH-1 downto 0) := y(HALFWIDTH-1 downto 0);
signal s_low : std_logic_vector(HALFWIDTH-1 downto 0);

signal x_high : std_logic_vector(HALFWIDTH-1 downto 0) := x(WIDTH-1 downto HALFWIDTH);
signal y_high : std_logic_vector(HALFWIDTH-1 downto 0) := y(WIDTH-1 downto HALFWIDTH);
signal s_high : std_logic_vector(HALFWIDTH-1 downto 0);

begin
  s <= s_high & s_low; --concatonate lower and upper nibbles
  
	end_condition: if(WIDTH = 2) generate
		end_adder : entity work.cla2 port
		map
		(
			x(1 downto 0) => x(1 downto 0),
			y(1 downto 0) => y(1 downto 0),
			cin => cin,
			s(1 downto 0) => s(1 downto 0),
			cout => cout,
			bp => bp,
			bg => bg
		);
	end generate end_condition;
		
	adderx: if(WIDTH /= 2) generate
		ADDER_LOW : entity work.adder_super
		generic map
		(
			WIDTH => HALFWIDTH
		)
		port map
		(
			x => x_low,
			y => y_low,
			s => s_low,
			cin => cin,			
			bp => bp0,
			bg => bg0
		);
		
		CGEN : entity work.cgen2
		port map
		(
			ci => cin,
			pi => bp0,
			gi => bg0,
			pi_n => bp1,
			gi_n => bg1,
			cout => cout,
			cout_in_between => cout_in_between,
			bp => bp,
			bg => bg
		);
	
		ADDER_HIGH : entity work.adder_super
		generic map
		(
			WIDTH => WIDTH/2
		)
		port map
		(
			x => x_high,
			y => y_high,
			cin => cout_in_between,
			s => s_high,
			bp => bp1,
			bg => bg1
		);
	end generate adderx;
end arch;


---------------------------ADDERS-------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mylib.all;

entity adder_gen is
generic
(
	WIDTH : positive
);
port
(
	a,b : in std_logic_vector(WIDTH-1 downto 0);
	cin : in std_logic;
	cout : out std_logic;
	output : out std_logic_vector(WIDTH-1 downto 0)
);
end adder_gen;

architecture ripple of adder_gen is
begin
	process(a,b,cin)
	
	variable carry : std_logic_vector(WIDTH downto 0);
	
	begin
	
		carry(0) := cin;
		
		for i in 0 to WIDTH-1 loop
			output(i) <= a(i) xor b(i) xor carry(i);
			carry(i+1) := (a(i) and b(i)) or (a(i) and carry(i)) or (b(i) and carry(i));
		end loop;
		
		cout <= carry(WIDTH);
	end process;
end ripple;

architecture heirarchal_look_ahead of adder_gen is --recursively creates adders down to widht of 2 base case and uses carry look aheads between each block

signal bg0,bg1,bp0,bp1,cout_in_between : std_logic;

signal a_low : std_logic_vector(WIDTH/2-1 downto 0) := a(WIDTH/2-1 downto 0);
signal b_low : std_logic_vector(WIDTH/2-1 downto 0) := b(WIDTH/2-1 downto 0);

signal a_high : std_logic_vector(WIDTH/2-1 downto 0) := a(WIDTH-1 downto WIDTH/2);
signal b_high : std_logic_vector(WIDTH/2-1 downto 0) := b(WIDTH-1 downto WIDTH/2);

signal out_low,out_high : std_logic_vector(WIDTH/2-1 downto 0);

begin
  output <= out_high & out_low;
	--instantiate two adder_supers and a cgen2
	ADDER_LOW : entity work.adder_super 
	generic map
	(
		WIDTH => WIDTH/2
	)
	port map
	(
		x => a_low,
		y => b_low,
		cin => cin,
		s => out_low,
		bp => bp0,
		bg => bg0
	);
	
	CGEN : entity work.cgen2
	port map
	(
		ci => cin,
		pi => bp0,
		gi => bg0,
		pi_n => bp1,
		gi_n => bg1,
		cout => cout,
		cout_in_between => cout_in_between
		--no bp and bg connection on the outside here
	);
	
	ADDER_HIGH : entity work.adder_super
	generic map
	(
		WIDTH => WIDTH/2
	)
	port map
	(
		x => a_high,
		y => b_high,
		cin => cout_in_between,
		s => out_high,
		bp => bp1,
		bg => bg1
	);
end heirarchal_look_ahead;

library ieee;
use ieee.std_logic_1164.all;

architecture numeric_std of adder_gen is

signal temp : std_logic_vector(WIDTH downto 0);	

begin
	temp <= std_logic_vector(unsigned('0' & a) + unsigned('0' & b) + unsigned(vectorize(cin)));
	cout <= temp(WIDTH);
	output <= temp(WIDTH-1 downto 0);
end numeric_std;

-----------------------------COUNTERS------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity counter_gen is
generic
(
	START_COUNT : natural := 0;
	END_COUNT 	: natural := 255;
	DIRECTION	: boolean := true; --true for up
	LOADABLE	: boolean := true
);
port
(
	clk,rst,en : in std_logic;
	d		: in std_logic_vector(integer(ceil(log2(real(END_COUNT))))-1 downto 0);
	ld		: in std_logic; --simply tie to something if not loadable
	q		: out std_logic_vector(integer(ceil(log2(real(END_COUNT))))-1 downto 0)
);
end counter_gen;

architecture max_ff of counter_gen is
	
signal count : unsigned(integer(ceil(log2(real(END_COUNT))))-1 downto 0);
constant WIDTH : integer := integer(ceil(log2(real(END_COUNT))));
	
begin
	process(clk,rst)
	begin
		if(rst = '1') then
			count <= to_unsigned(START_COUNT,WIDTH);
		elsif(rising_edge(clk)) then
			if(en = '1') then
				if(DIRECTION) then count <= count + 1;
				else count <= count - 1;
				end if;
			
				if(LOADABLE) then
					if(ld = '1') then
						count <= unsigned(d);
					end if;
				end if;
			end if;
		end if;
	end process;			
	
	q <= std_logic_vector(count);
end max_ff;

--TODO minimize number of FFs by counting from 0 to end count - start count and using logic to translate
