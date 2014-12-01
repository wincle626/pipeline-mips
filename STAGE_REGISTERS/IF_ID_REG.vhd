library ieee;
use ieee.std_logic_1164.all;

entity IF_ID_REG is
port
(
	clk, rst : in std_logic;
	
	PC_inc_in : in std_logic_vector(29 downto 0); --PC after increment, goes straight to ID_EX reg
	PC_inc_out : out std_logic_vector(29 downto 0);
	
	Instruction_in : in std_logic_vector(31 downto 0);
	Jump_in : in std_logic; --if jump is true in ID stage then do not load the next instruction, instead load a NOP
	
	JumpReg_in : in std_logic; --signal to insert free NOP because jumpreg
	
	Branch_and_Zero_in : in std_logic; --signal to insert free NOP (no shadow)
	
	Rs_out,Rt_out,Rd_out,shamt_out : out std_logic_vector(4 downto 0);	--Rt and Rd go straight to ID_EX reg
	Func_out,Opcode_out : out std_logic_vector(5 downto 0);	
	Immediate26_out : out std_logic_vector(25 downto 0); --for jumping
	
	--hazard signals
	stall_pipeline : in std_logic
);
end IF_ID_REG;

architecture arch of IF_ID_REG is

signal Instruction : std_logic_vector(31 downto 0);	

begin
	process(clk,rst, stall_pipeline)
	begin
		if(rst = '1') then
			PC_inc_out <= (others => '0');
			Instruction <= (others => '0');
		elsif(falling_edge(clk) and stall_pipeline = '0') then
			if(Jump_in = '0' and JumpReg_in = '0' and Branch_and_Zero_in = '0') then --don't load when ID stage is jumping (forced NOP)
				Instruction <= Instruction_in;				
			else
				Instruction <= (others => '0'); --sll r0,r0,0 aka nop
			end if;
			PC_inc_out <= PC_inc_in;
		end if;
	end process;
	
	--all the divisions for R and shared
	opcode_out <= Instruction(31 downto 26);
	Rs_out <= Instruction(25 downto 21);
	Rt_out <= Instruction(20 downto 16);
	Rd_out <= Instruction(15 downto 11);
	shamt_out <= Instruction(10 downto 6);
	func_out <= Instruction(5 downto 0);
	
	--I/J type
	immediate26_out <= Instruction(25 downto 0);
end architecture arch;
