--contains memtoreg mux, outputs Rw and Di for regfile
library ieee;
use ieee.std_logic_1164.all;

entity WR_unit is
port
(
	PC_INC_in : in std_logic_vector(29 downto 0);
	
	ALUout_in : in std_logic_vector(31 downto 0); --output of alu comes from MEM_WR register
	Data_Memory_Out_in : in std_logic_vector(31 downto 0); --data memory output from MEM_WR reg
	
	Di_out : out std_logic_vector(31 downto 0); --feedback to ID for writeback
	
	MemToReg_in,JAL_in : in std_logic --control signal to determine writeback
);
end WR_unit;

architecture arch of WR_unit is	

signal WriteBackSelect : std_logic_vector(1 downto 0);

begin
	WriteBackSelect <= MemToReg_in & JAL_in; --select line for write back
	Di_out <= ALUout_in when WriteBackSelect = "00" else --mux to select alu write back, pc write back for JAL, or memory write back
			  PC_INC_in & "00" when WriteBackSelect = "01" else
			  Data_Memory_Out_in;
end architecture arch;
