library ieee;
use ieee.std_logic_1164.all;

entity alu32control is
port
(
	func : in std_logic_vector(5 downto 0); --function from opcode
	ALUop : in std_logic_vector(2 downto 0); --alu op
	control : out std_logic_vector(3 downto 0);
	shdir,LUI,JumpReg : out std_logic
);
end alu32control;

architecture arch of alu32control is	
begin
	process(func,ALUop)
	begin
		shdir <= 'X';
		LUI <= '0';
		JumpReg <= '0';
		
		control <= "XXXX";
		
		case ALUop is			
		when "000" => --add operation
			control <= "0010";
			
		when "001" => --subtract operation
			control <= "0110";
		
		when "010" => --R type instruction
			case func is
			when "100000" => --add
				control <= "0010";
										--difference is carry overflow
			when "100001" => --add unsigned
				control <= "0010";
				
			when "100100" => --and
				control <= "0000";
			
			when "001000" => --jump register
				control <= "0010"; --add 0 to reg so writeback does nothing
				JumpReg <= '1';
				
			when "100111" => --nor
				control <= "1100";
				
			when "100101" => --or
				control <= "0001";
				
			when "101010" => --slt
				control <= "0111";
				
			when "101011" => --sltu
				control <= "1111";
				
			when "000000" => --sll
				control <= "0011";
				shdir <= '0';
											--difference is shdir in alu
			when "000010" => --srl
				control <= "0011";
				shdir <= '1';
			
			when "100010" => --sub
				control <= "0110";
											--difference is carry overflow
			when "100011" => --subu
				control <= "0110";
				
			when others =>
				null;			
			end case;
		
		when "011" => --and operation
			control <= "0000";
			
		when "100" => --or operation
			control <= "0001";
			
		when "101" => --slt operation
			control <= "0111";
			
		when "110" => --slt unsigned operation
			control <= "1111";
			
		when "111" => --shift left 16
			control <= "0011";
			shdir <= '0';
			LUI <= '1';
			
		when others =>
			null;		
		end case;
		
	end process;	
end arch;
