library ieee;
use ieee.std_logic_1164.all;

entity EX_MEM_REG is
port
(
	clk, rst : in std_logic;
	
	PC_inc_in : in std_logic_vector(29 downto 0); --for JAL, directly from ID_EX
	PC_inc_out : out std_logic_vector(29 downto 0);
	
	ALUout_in : in std_logic_vector(31 downto 0);
	ALUout_out : out std_logic_vector(31 downto 0); --to data address and next stage, or PC_inc_Branch calculation
	
	Rb_in : in std_logic_vector(31 downto 0);
	Rb_out : out std_logic_vector(31 downto 0); --to data in on memory
	
	Rw_in : in std_logic_vector(4 downto 0); --forwarding write register for register writeback
	Rw_out : out std_logic_vector(4 downto 0);
	
	--MEM stage control signals
	MemWr_in : in std_logic; --control signal, mem write enable, needed in MEM stage
	MemWr_out : out std_logic;
	byte_ena_in : in std_logic_vector(3 downto 0);
	byte_ena_out : out std_logic_vector(3 downto 0);
	JAL_in : in std_logic;
	JAL_out : out std_logic;
	
	--WR stage control signals
	MemtoReg_in : in std_logic;
	MemtoReg_out : out std_logic;
	Reg_Wr_in : in std_logic;
	Reg_Wr_out : out std_logic --needed in ID stage from Wr
);
end EX_MEM_REG;

architecture arch of EX_MEM_REG is	
begin
	process(clk,rst)
	begin
		if(rst = '1') then
			PC_inc_out <= (others => '0');
			
			ALUout_out <= (others => '0');
			Rb_out <= (others => '0');
			Rw_out <= (others => '0');
			
			MemWr_out <= '0';
			byte_ena_out <= (others => '0');
			JAL_out <= '0';
			
			MemtoReg_out <= '0';
		elsif(falling_edge(clk)) then
			PC_inc_out <= PC_inc_in;
			
			ALUout_out <= ALUout_in;
			Rb_out <= Rb_in;
			Rw_out <= Rw_in;
			
			--control signals for MEM stage
			MemWr_out <= MemWr_in;
			byte_ena_out <= byte_ena_in;
			JAL_out <= JAL_in;
			
			--control signals for WR tage
			MemtoReg_out <= MemtoReg_in;
			Reg_Wr_out <= Reg_Wr_in;
		end if;
	end process;			
end architecture arch;
