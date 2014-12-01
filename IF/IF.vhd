--contains PC, IUnit, Branch/Jump select mux
--contains program memory connections
--Iunit contains adder for PC+4 and connects to program memory
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_unit is
port
(
	clk, rst : in std_logic;
	
	Branch_and_Zero : in std_logic; --generated in EX stage
	Jump, JumpReg : in std_logic; --jump is from ID stage, Jump reg is either from EX or ID, not sure yet
	
	Jump_Reg_value : in std_logic_vector(31 downto 0); --from EX stage, either simply Ra or a forwarded value (busA value in EX stage)
	Jump_addr_lower : in std_logic_vector(25 downto 0); --jump addr from ID_EX reg
	PC_inc_Branch : in std_logic_vector(31 downto 0); --branch from EX stage
	
	PC_inc_out : out std_logic_vector(29 downto 0);
	--Instruction_out : out std_logic_vector(31 downto 0); --now comes from memory block
	
	--To Memory Block
	Instruction_Address : out std_logic_vector(31 downto 0);
	
	--hazard signals
	stall_pipeline : in std_logic
);
end IF_unit;

architecture arch of IF_unit is
	
signal PC,PC_inc,PC_next : std_logic_vector(29 downto 0); --implicit 00 lsb

signal Next_PC_Select : std_logic_vector(2 downto 0);	

begin	
	PC_INC_ADDER: entity work.adder_gen(numeric_std) --adder to increment PC by one
	generic map(WIDTH => 30)
	port map
	(
		 a      => PC,
	     b      => std_logic_vector(to_unsigned(1,30)),
	     cin    => '0',
	     output => PC_inc
	);
	
	Next_PC_Select <= Jump & JumpReg & Branch_and_Zero; --select line for next PC mux
	with Next_PC_Select select
		PC_next <= Jump_Reg_value(31 downto 2) when "010",
				   PC_inc(29 downto 26) & Jump_addr_lower when "100",
				   PC_inc_Branch(31 downto 2) when "001",
				   PC_inc_Branch(31 downto 2) when "011",
				   PC_inc_Branch(31 downto 2) when "101",
				   PC_inc_Branch(31 downto 2) when "111", --branch outprioritizes jump
				   PC_inc when others;
				    
	
	process(clk,rst, stall_pipeline) --register for PC
	begin
		if(rst = '1') then
			PC <= "00" & x"0100000"; -- left shifted two times this is 0x00400000
		elsif(falling_edge(clk) and stall_pipeline = '0') then
			PC <= PC_next;
		end if;
	end process;
	
	PC_inc_out <= PC_inc;  --send next PC to next stage
	Instruction_Address <= PC & "00";
end architecture arch;
