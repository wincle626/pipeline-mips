library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mylib.all;

entity alu32 is
generic
(
	WIDTH : positive := 32
);
port
(
	ia,ib : in std_logic_vector(WIDTH-1 downto 0);
	control : in std_logic_vector(3 downto 0);
	shamt : in std_logic_vector(4 downto 0); --shift amount for shift op
	shdir : in std_logic; --shift direction: 0 left, 1 right
	--cin : in std_logic; --carry in
	o : out std_logic_vector(WIDTH-1 downto 0); --output
	s,v,c,z : out std_logic --sign, overflow, carry
);
end alu32;

architecture arch of alu32 is

signal add_b,add_out : std_logic_vector(WIDTH-1 downto 0);

signal add_cout,add_cin : std_logic;

begin	
	ALU_ADDER : entity work.adder_gen(numeric_std)
	generic map
	(
		WIDTH => WIDTH
	)
	port map
	(
		a => ia,
		b => add_b,
		cin => add_cin,
		cout => add_cout,
		output => add_out
	);
	add_b <= not ib when (control = "0110") else
				ib;
	add_cin <= '1' when (control = "0110") else
				  '0';

	process(ia,ib,control,shamt,shdir,add_out,add_cout)
	
	variable o_v : std_logic_vector(WIDTH-1 downto 0);
	
	--variable temp : std_logic_vector(WIDTH downto 0);
	
	begin
		---INIT FLAGS AND OUTPUTS---	
		c <= '0';
		v <= '0';
		z <= '0';
		s <= '0';
				
		o_v := (others => '0');
		-----------------------------
		
		case control is
			
		when "0010" => --SUM
--			temp := std_logic_vector(resize(unsigned(ia),WIDTH+1) + resize(unsigned(ib),WIDTH+1));
--			c <= temp(WIDTH);						
--			o_v := temp(WIDTH-1 downto 0);			
--			v <= (temp(WIDTH-1) and not ia(WIDTH-1) and not ib(WIDTH-1)) or (not temp(WIDTH-1) and ia(WIDTH-1) and ib(WIDTH-1));	

			v <= (add_cout and not ia(WIDTH-1) and not ib(WIDTH-1)) or (not add_cout and ia(WIDTH-1) and ib(WIDTH-1));			
			o_v := add_out;
			c <= add_cout;						
			v <= (ia(WIDTH-1) and ib(WIDTH-1) and not o_v(WIDTH-1)) or 
				 (not ia(WIDTH-1) and not ib(WIDTH-1) and o_v(WIDTH-1));
				
		when "0110" => --DIFFERENCE, assuming CIN is set correctly by alu32control
--			temp := std_logic_vector(resize(unsigned(ia),WIDTH+1) - resize(unsigned(ib),WIDTH+1));
--			c <= temp(WIDTH);
--			o_v := temp(WIDTH-1 downto 0);
--			v <= (temp(WIDTH-1) and not ia(WIDTH-1) and ib(WIDTH-1)) or (not temp(WIDTH-1) and ia(WIDTH-1) and not ib(WIDTH-1));
			
			v <= (add_cout and not ia(WIDTH-1) and ib(WIDTH-1)) or (not add_cout and ia(WIDTH-1) and not ib(WIDTH-1));			
			o_v := add_out;
			c <= add_cout; --actually borrow (active low)
			v <= (ia(WIDTH-1) and ib(WIDTH-1) and not o_v(WIDTH-1)) or 
				 (not ia(WIDTH-1) and not ib(WIDTH-1) and o_v(WIDTH-1));
				 
		when "0000" => --and
			o_v := ia and ib;
			
		when "0001" => --or
			o_v := ia or ib;
			
		when "1100" => --nor
			o_v := ia nor ib;
			
		when "0111" => --slt signed
			if(signed(ia) < signed(ib)) then
				o_v := std_logic_vector(to_unsigned(1,WIDTH));
			else
				o_v := (others => '0');
			end if;
			
		when "1111" => --slt unsigned
			if(unsigned(ia) < unsigned(ib)) then
				o_v := std_logic_vector(to_unsigned(1,WIDTH));
			else
				o_v := (others => '0');
			end if;
			
		when "0011" => --shift left or right
			if(shdir = '0') then --left
				o_v := std_logic_vector(shift_left(unsigned(ib),to_integer(unsigned(shamt))));
			else
				o_v := std_logic_vector(shift_right(unsigned(ib),to_integer(unsigned(shamt))));
			end if;
			
		when others =>
			null;					
		end case;
		
		if(unsigned(o_v) = 0) then
			z <= '1';		
		elsif(o_v(WIDTH-1) = '1') then
			s <= '1';
		end if;
		
		o <= o_v;
	end process;
end arch;
		
		
		
		
		