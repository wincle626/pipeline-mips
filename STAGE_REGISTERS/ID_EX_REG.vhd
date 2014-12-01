library ieee;
use ieee.std_logic_1164.all;

entity ID_EX_REG is
port
(
	clk, rst : in std_logic;
	
	PC_inc_in : in std_logic_vector(29 downto 0); --PC after increment, straight from IF_ID register
	PC_inc_out : out std_logic_vector(29 downto 0);
	
	Immediate32_in : in std_logic_vector(31 downto 0);
	Immediate32_out : out std_logic_vector(31 downto 0);
	
	Ra_in,Rb_in : in std_logic_vector(31 downto 0); --forward to exec unit
	Ra_out, Rb_out : out std_logic_vector(31 downto 0);
	
	Rs_in,Rt_in,Rd_in : in std_logic_vector(4 downto 0); --forward to ex to determine regdst and then all the way to register writeback
	Rs_out,Rt_out,Rd_out : out std_logic_vector(4 downto 0);
	
	Func_in: in std_logic_vector(5 downto 0);
	Func_out : out std_logic_vector(5 downto 0);
	
	shamt_in : in std_logic_vector(4 downto 0);
	shamt_out : out std_logic_vector(4 downto 0);
	
	JumpReg_in : in std_logic;
	
	--EX stage control signal
	RegDst_in : in std_logic;
	RegDst_out : out std_logic;
	ALUOp_in : in std_logic_vector(2 downto 0); --ALU32control input, needed in EX stage
	ALUOp_out : out std_logic_vector(2 downto 0);	
	ALUsrc_in : in std_logic; --extension/reg mux select, needed in EX stage
	ALUsrc_out : out std_logic;
	ExtOp_in : in std_logic;
	ExtOp_out : out std_logic;

	--MEM stage control signals
	MemWr_in : in std_logic; --control signal, mem write enable, needed in MEM stage
	MemWr_out : out std_logic;	
	byte_ena_out : out std_logic_vector(3 downto 0);
	byte_ena_in : in std_logic_vector(3 downto 0);
	JAL_in : in std_logic;
	JAL_out : out std_logic;
	
	--WR stage control signals
	MemToReg_in : in std_logic;
	MemToReg_out : out std_logic;
	Reg_Wr_in : in std_logic;
	Reg_Wr_out : out std_logic; --needed in ID stage from Wr
	
	--hazard signals
	stall_pipeline : in std_logic
);
end ID_EX_REG;

architecture arch of ID_EX_REG is	
begin
	process(clk,rst)
	begin
		if(rst = '1') then
			PC_inc_out <= (others => '0');
			Immediate32_out <= (others => '0');
			Ra_out <= (others => '0');
			Rb_out <= (others => '0');
			Rs_out <= (others => '0');
			Rt_out <= (others => '0');
			Rd_out <= (others => '0');
			Func_out <= (others => '0');
			shamt_out <= (others => '0');
			
			ALUOp_out <= (others => '0');
			RegDst_out <= '0';			
			ALUsrc_out <= '0';
			JAL_out <= '0';
			ExtOp_out <= '0';
			
			MemWr_out <= '0';
			byte_ena_out <= (others => '0');
			
			MemToReg_out <= '0';
		elsif(falling_edge(clk)) then
			PC_inc_out <= PC_inc_in;
			
			Immediate32_out <= Immediate32_in;
	
			Ra_out <= Ra_in;
			Rb_out <= Rb_in;
			
			Rs_out <= Rs_in; --Rs needed for forwarding
			Rt_out <= Rt_in;
			Rd_out <= Rd_in;
			
			Func_out <= Func_in;
			
			shamt_out <= shamt_in;
			
			--control signals for EX stage
			ALUOp_out <= ALUOp_in;
			RegDst_out <= RegDst_in;
			ALUsrc_out <= ALUsrc_in;
			ExtOp_out <= ExtOp_in;
			
			--control signals for MEM stage
			MemWr_out <= MemWr_in;
			byte_ena_out <= byte_ena_in;
			JAL_out <= JAL_in;
			
			--control signals for WR tage
			MemToReg_out <= MemToReg_in;
			Reg_Wr_out <= Reg_Wr_in;
			
			if(JumpReg_in = '1' or stall_pipeline = '1') then --turn me to NOP, we jumpreg'd or we are stalling
				ALUOp_out <= (others => '0');
				MemWr_out <= '0';
				JAL_out <= '0';
				Reg_Wr_out <= '0';
			end if;
		end if;
	end process;
end architecture arch;
