library ieee;
use ieee.std_logic_1164.all;

entity MEM_WR_REG is
port
(
	clk,rst : in std_logic;
	
	PC_INC_in : in std_logic_vector(29 downto 0);
	PC_INC_out : out std_logic_vector(29 downto 0);

	ALU_out_in : in std_logic_vector(31 downto 0);
	ALU_out_out : out std_logic_vector(31 downto 0);
	
	Data_Memory_out_in : in std_logic_vector(31 downto 0);
	Data_Memory_out_out : out std_logic_vector(31 downto 0);
	
	Rw_in : in std_logic_vector(4 downto 0); --from mem stage
	Rw_out : out std_logic_vector(4 downto 0); --goes straigth to ID stage for writeback
	
	--WR stage control signals
	MemtoReg_in : in std_logic;
	MemtoReg_out : out std_logic;
	Reg_Wr_in : in std_logic;
	Reg_Wr_out : out std_logic; --needed in ID stage from Wr
	JAL_in : in std_logic;
	JAL_out : out std_logic
);
end MEM_WR_REG;

architecture arch of MEM_WR_REG is	
begin
	process(clk,rst)
	begin
		if(rst = '1') then
			PC_INC_out <= (others => '0');
			
			ALU_out_out <= (others => '0');
			Data_Memory_out_out <= (others => '0');
			Rw_out <= (others => '0');
			
			MemtoReg_out <= '0';
			
			JAL_out <= '0';
		elsif(falling_edge(clk)) then
			PC_INC_out <= PC_INC_in;
			
			ALU_out_out <= ALU_out_in;
			Data_Memory_out_out <= Data_Memory_out_in;
			Rw_out <= Rw_in;
			
			--control signals for MEM
			MemtoReg_out <= MemtoReg_in;
			Reg_Wr_out <= Reg_Wr_in;
			JAL_out <= JAL_in;
		end if;
	end process;	
end architecture arch;
