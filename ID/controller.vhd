library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
port
(
	opcode : in std_logic_vector(5 downto 0);
	RegDst,ExtOp,ALUSrc,MemtoReg,RegWr,MemWr,Branch,Jump,Z_Invert,JAL : out std_logic; --signals from controller
	ALUop : out std_logic_vector(2 downto 0);
	byteena : out  std_logic_vector(3 downto 0)
);
end controller;

architecture arch of controller is	
begin	
	process(opcode)
	begin
		RegDst <= '1'; --default is Rd
		ExtOp <= '0'; --no longer a controller for extender, default 0 so immediate's upper is default 0'd
		ALUSrc <= '0'; --default busB is register, otherwise sign extended immediate value
		MemtoReg <= '0'; --default ALU result is writeback
		RegWr <= '1'; --default is write back value
		MemWr <= '0'; --default reading from data memory
		Branch <= '0'; --default do not branch
		Jump <= '0'; --default do not jump
		JAL <= '0';
		ALUop <= "XXX";
		Z_invert <= '0';
		
		byteena <= (others => '1'); --default reading word from data memory
		
		ALUop <= (others => '0');
		
		case opcode is
			
		when "000000" => --R type function, ALU32control will determine ALUctr from func
			ALUop <= "010"; --use func
	
		when "001000" => --add immediate signed
			ALUop <= "000"; --add
			ExtOp <= '1'; --signed extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001001" => --add immediate unsigned turns out it just doesn't execute a trap, which this CPU doesn't support
			ALUop <= "000"; --add
			ExtOp <= '0'; --signed extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001100" => --and immediate
			ALUop <= "011"; --and
			ExtOp <= '0'; --zero extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "000100" => --beq
			ALUop <= "001"; --subtract
			Branch <= '1'; --branch if z is true, no need to not z
			ALUSrc <= '1';
			RegWr <= '0'; --do not write back value
			
		when "000101" => --bne
			ALUop <= "001"; --subtract
			Branch <= '1'; --branch if z is false
			ALUSrc <= '1';
			z_invert <= '1'; --if z is false we'll branch
			RegWr <= '0'; --do not write back value
			
		when "000010" => --jump
			Jump <= '1';
			RegWr <= '0'; --do not write back value
			
		when "000011" => --jal
			Jump <= '1';
			JAL <= '1';
			
		when "100100" => --load byte unsigned
			ALUop <= "000"; --add to get address offset
			byteena <= "0001"; --only enable one byte from memory
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "100101" => --load halfword unsigned
			ALUop <= "000"; --add to get address offset
			byteena <= "0011"; --only enable 2 bytes from memory
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "001111" => --lui
			ALUop <= "111"; --select shift
			ALUsrc <= '1'; --src is immediate to alu
			ExtOp <= '0'; --zero extend
			RegDst <= '0'; --t is destination for loads
			
		when "100011" => --load word
			ALUop <= "000"; --add to get address offset, default byteena of 1111 is good
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "001101" => --or immediate
			ALUop <= "100"; --or
			ExtOp <= '0'; --zero extension
			ALUsrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001010" => --slti
			ALUop <= "101"; --slt
			ExtOp <= '1'; --signed comparison
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001011" => --sltiu
			ALUop <= "110"; --sltu
			ExtOp <= '0'; --unsigned comparison
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for immediates
			
		when "101000" => --store byte
			ALUop <= "000"; --add to get address offset
			ALUSrc <= '1'; --alu value is immediate value
			byteena <= "0001"; --only enable one byte to memory
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when "101001" => --store halfword
			ALUop <= "000"; --add to get address offset
			ALUSrc <= '1'; --alu value is immediate value
			byteena <= "0011"; --only enable 2 bytes to memory
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when "101011" => --store word
			ALUop <= "000"; --add to get address offset, all bytes enabled
			ALUSrc <= '1'; --alu value is immediate value
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when others =>
			null;
		end case;		
	end process;	
end architecture arch;
