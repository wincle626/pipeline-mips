library ieee;
use ieee.std_logic_1164.all;

entity PIPELINED_MIPS is
port
(
	mem_clk,rst : in std_logic;
	
	Data_Address : out std_logic_vector(31 downto 0);	
	Data_to_memory_out : out std_logic_vector(31 downto 0);
	MemWr_to_memory : out std_logic;
	byte_ena_to_memory : out std_logic_vector(3 downto 0);	
	Data_to_CPU_in : in std_logic_vector(31 downto 0);
	
	Instruction_Address : out std_logic_vector(31 downto 0);
	Instruction_in : in std_logic_vector(31 downto 0)
);
end PIPELINED_MIPS;

architecture arch of PIPELINED_MIPS is	
	
signal clk_half,clk : std_logic;

--signal naming convention: suffix is origin of signal
signal Branch_and_Zero_ID_stage : std_logic;
signal JumpReg_EX_stage : std_logic;
signal Ra_ID_EX_REG : std_logic_vector(31 downto 0);
signal ALUout_EX_MEM_REG : std_logic_vector(31 downto 0);
signal PC_inc_Branch_ID_stage : std_logic_vector(31 downto 0);
signal PC_inc_IF_stage : std_logic_vector(29 downto 0);

signal PC_inc_IF_ID_REG : std_logic_vector(29 downto 0);
signal Rs_IF_ID_REG : std_logic_vector(4 downto 0);
signal Rt_IF_ID_REG : std_logic_vector(4 downto 0);
signal Rd_IF_ID_REG : std_logic_vector(4 downto 0);
signal shamt_IF_ID_REG : std_logic_vector(4 downto 0);
signal Func_IF_ID_REG : std_logic_vector(5 downto 0);
signal Opcode_IF_ID_REG : std_logic_vector(5 downto 0);
signal Immediate26_IF_ID_REG : std_logic_vector(25 downto 0);

signal Rw_MEM_WR_REG : std_logic_vector(4 downto 0);
signal Di_WR_stage : std_logic_vector(31 downto 0);
signal Reg_Wr_MEM_WR_REG : std_logic;
signal Ra_ID_stage : std_logic_vector(31 downto 0);
signal Rb_ID_stage : std_logic_vector(31 downto 0);
signal ALUsrc_ID_stage : std_logic;
signal MemWr_ID_stage : std_logic;
signal byte_enable_ID_stage : std_logic_vector(3 downto 0);
signal MemtoReg_ID_stage : std_logic;
signal RegWr_ID_stage : std_logic;
signal RegDst_ID_stage : std_logic;
signal JAL_ID_stage : std_logic;
signal Jump_ID_stage : std_logic;
signal ALUop_ID_stage : std_logic_vector(2 downto 0);
signal ExtOP_ID_stage : std_logic;
signal immediate32_ID_stage : std_logic_vector(31 downto 0);

signal PC_inc_ID_EX_REG : std_logic_vector(29 downto 0);
signal Immediate32_ID_EX_REG : std_logic_vector(31 downto 0);
signal Rb_ID_EX_REG : std_logic_vector(31 downto 0);
signal Rt_ID_EX_REG : std_logic_vector(4 downto 0);
signal Rd_ID_EX_REG : std_logic_vector(4 downto 0);
signal Func_ID_EX_REG : std_logic_vector(5 downto 0);
signal shamt_ID_EX_REG : std_logic_vector(4 downto 0);
signal RegDst_ID_EX_REG : std_logic;
signal ALUOp_ID_EX_REG : std_logic_vector(2 downto 0);
signal ALUsrc_ID_EX_REG : std_logic;
signal byte_enable_ID_EX_REG : std_logic_vector(3 downto 0);
signal JAL_ID_EX_REG : std_logic;
signal MemToReg_ID_EX_REG : std_logic;
signal MemWr_ID_EX_REG : std_logic;
signal Reg_Wr_ID_EX_REG : std_logic;
signal ExtOp_ID_EX_REG : std_logic;

signal Rw_EX_stage : std_logic_vector(4 downto 0);
signal ALUout_EX_stage : std_logic_vector(31 downto 0);
signal Rb_EX_stage : std_logic_vector(31 downto 0);

signal PC_inc_EX_MEM_REG : std_logic_vector(29 downto 0);
signal Rb_EX_MEM_REG : std_logic_vector(31 downto 0);
signal Rw_EX_MEM_REG : std_logic_vector(4 downto 0);
signal MemWr_EX_MEM_REG : std_logic;
signal byte_ena_EX_MEM_REG : std_logic_vector(3 downto 0);
signal JAL_EX_MEM_REG : std_logic;
signal MemtoReg_EX_MEM_REG : std_logic;
signal Reg_Wr_EX_MEM_REG : std_logic;

signal Rw_MEM_stage : std_logic_vector(4 downto 0);
signal Data_Memory_out_MEM_stage : std_logic_vector(31 downto 0);

signal MemtoReg_MEM_WR_REG : std_logic;
signal PC_INC_MEM_WR_REG : std_logic_vector(29 downto 0);
signal ALU_out_MEM_WR_REG : std_logic_vector(31 downto 0);
signal Data_Memory_out_MEM_WR_REG : std_logic_vector(31 downto 0);
signal JAL_MEM_WR_REG : std_logic;

--signal Reg_Wr_and_clk : std_logic; not needed because not SRAM
signal MemWr_and_clk_EX_MEM_REG : std_logic;

--signals for forwarding unit
signal Rs_ID_EX_REG : std_logic_vector(4 downto 0);
signal Branch_ID_stage : std_logic;
signal forward_busA_ALU_out_EX_MEM : std_logic;
signal forward_busB_ALU_out_EX_MEM : std_logic;
signal forward_busA_WB_value : std_logic;
signal forward_busB_WB_value : std_logic;
signal forward_Reg_A_ID_EX_WB_stage : std_logic;
signal forward_Reg_B_ID_EX_WB_stage : std_logic;
signal forward_Reg_A_ID_EX_EX_MEM : std_logic;
signal forward_Reg_B_ID_EX_EX_MEM : std_logic;
signal Jump_Reg_value : std_logic_vector(31 downto 0);

signal stall_pipeline : std_logic;

begin
	process(mem_clk,rst) --clock dividers
	begin
		if(rst = '1') then
			clk_half <= '0';
			clk <= '0';
		elsif(rising_edge(mem_clk)) then
			clk_half <= not clk_half;
			if(clk_half = '1') then
				clk <= not clk;
			end if;
		end if;
	end process;

	IF_UNIT_U: entity work.IF_unit
	port map
	(
		 clk                 => clk,
	     rst                 => rst,
	     Branch_and_Zero     => Branch_and_Zero_ID_stage,
	     Jump                => Jump_ID_stage,
	     JumpReg             => JumpReg_EX_stage,
	     Jump_Reg_value      => Jump_Reg_value,
	     Jump_addr_lower     => Immediate26_IF_ID_REG,
	     PC_inc_Branch       => PC_inc_Branch_ID_stage,
	     PC_inc_out          => PC_inc_IF_stage,
	     Instruction_Address => Instruction_Address,
	     stall_pipeline		 => stall_pipeline
	);
	
	IF_ID_REG_U: entity work.IF_ID_REG
	port map
	(
		 clk              => clk,
	     rst              => rst,
	     PC_inc_in        => PC_inc_IF_stage,
	     PC_inc_out       => PC_inc_IF_ID_REG,
	     Instruction_in   => Instruction_in,
	     Rs_out           => Rs_IF_ID_REG,
	     Rt_out           => Rt_IF_ID_REG,
	     Rd_out           => Rd_IF_ID_REG,
	     shamt_out        => shamt_IF_ID_REG,
	     Func_out         => Func_IF_ID_REG,
	     Opcode_out       => Opcode_IF_ID_REG,
	     Immediate26_out  => Immediate26_IF_ID_REG,
	     Jump_in		  => Jump_ID_stage,
	     JumpReg_in		  => JumpReg_EX_stage,
	     Branch_and_Zero_in => Branch_and_Zero_ID_stage,
	     stall_pipeline => stall_pipeline
	);
	
	--Reg_Wr_and_clk <= Reg_Wr_MEM_WR_REG and clk; --anded signal to be sure we don't write to the wrong Rw address while it is transient (if it is SRAM or somethign)
	--do not do this as we need this rising edge to write before reads of reg file since it is DFF's not SRAM
	ID_UNIT_U: entity work.ID_unit
	port map
	(
		 clk            => clk,
	     rst            => rst,
	     Rs             => Rs_IF_ID_REG,
	     Rt             => Rt_IF_ID_REG,
	     Rw             => Rw_MEM_WR_REG,
	     Di             => Di_Wr_stage,
	     ALUout_EX_MEM_REG => ALUout_EX_MEM_REG,
	     opcode 	    => Opcode_IF_ID_REG,
	     Reg_Wr         => Reg_Wr_MEM_WR_REG, --if SRAM change back
	     Ra_out         => Ra_ID_stage,
	     Rb_out         => Rb_ID_stage,
	     immediate26_in => Immediate26_IF_ID_REG,
	     immediate32_out => Immediate32_ID_stage,
	     PC_inc_in		=> PC_inc_IF_ID_REG,
	     PC_inc_Branch_out => PC_inc_Branch_ID_stage,
	     Branch_and_Zero_out => Branch_and_Zero_ID_stage,
	     Branch_out     => Branch_ID_stage,
	     ALUsrc         => ALUsrc_ID_stage,
	     ExtOp			=> ExtOP_ID_stage,
	     MemWr          => MemWr_ID_stage,
	     byte_enable    => byte_enable_ID_stage,
	     MemtoReg       => MemtoReg_ID_stage,
	     RegWr          => RegWr_ID_stage,
	     RegDst         => RegDst_ID_stage,
	     JAL            => JAL_ID_stage,
	     ALUop			=> ALUop_ID_stage,
	     Jump           => Jump_ID_stage,
	     forward_Reg_A_ID_EX_EX_MEM => forward_Reg_A_ID_EX_EX_MEM,
	     forward_Reg_B_ID_EX_EX_MEM => forward_Reg_B_ID_EX_EX_MEM,
	     forward_Reg_A_ID_EX_WB_stage => forward_Reg_A_ID_EX_WB_stage,
	     forward_Reg_B_ID_EX_WB_stage => forward_Reg_B_ID_EX_WB_stage
	);
	
	ID_EX_REG_U: entity work.ID_EX_REG
	port map
	(
		 clk             => clk,
	     rst             => rst,
	     PC_inc_in       => PC_inc_IF_ID_REG,
	     PC_inc_out      => PC_inc_ID_EX_REG,
	     Immediate32_in  => Immediate32_ID_stage,
	     Immediate32_out => Immediate32_ID_EX_REG,
	     Ra_in           => Ra_ID_stage,
	     Rb_in           => Rb_ID_stage,
	     Ra_out          => Ra_ID_EX_REG,
	     Rb_out          => Rb_ID_EX_REG,
	     Rs_in			 => Rs_IF_ID_REG,
	     Rt_in           => Rt_IF_ID_REG,
	     Rd_in           => Rd_IF_ID_REG,
	     Rs_out			 => Rs_ID_EX_REG,
	     Rt_out          => Rt_ID_EX_REG,
	     Rd_out          => Rd_ID_EX_REG,
	     Func_in         => Func_IF_ID_REG,
	     Func_out        => Func_ID_EX_REG,
	     shamt_in        => shamt_IF_ID_REG,
	     shamt_out       => shamt_ID_EX_REG,
	     RegDst_in       => RegDst_ID_stage,
	     RegDst_out      => RegDst_ID_EX_REG,
	     ALUOp_in        => ALUop_ID_stage,
	     ALUOp_out       => ALUOp_ID_EX_REG,
	     ALUsrc_in       => ALUsrc_ID_stage,
	     ALUsrc_out      => ALUsrc_ID_EX_REG,
	     ExtOp_in		 => ExtOP_ID_stage,
	     ExtOp_out		 => ExtOp_ID_EX_REG,
	     MemWr_in        => MemWr_ID_stage,
	     MemWr_out       => MemWr_ID_EX_REG,
	     byte_ena_out    => byte_enable_ID_EX_REG,
	     byte_ena_in     => byte_enable_ID_stage,
	     JAL_in          => JAL_ID_stage,
	     JAL_out         => JAL_ID_EX_REG,
	     MemToReg_in     => MemtoReg_ID_stage,
	     MemToReg_out    => MemToReg_ID_EX_REG,
	     Reg_Wr_in       => RegWr_ID_stage,
	     Reg_Wr_out      => Reg_Wr_ID_EX_REG,
	     JumpReg_in		 => JumpReg_EX_stage,
	     stall_pipeline  => stall_pipeline
	);
	
	EX_UNIT_U: entity work.EX_unit
	port map
	(
	     Immediate32_in    => Immediate32_ID_EX_REG,
	     Ra_in             => Ra_ID_EX_REG,
	     Rb_in             => Rb_ID_EX_REG,
	     Rb_out			   => Rb_EX_stage,
	     Rt_in             => Rt_ID_EX_REG,
	     Rd_in             => Rd_ID_EX_REG,
	     Rw_out            => Rw_EX_stage,
	     shamt_in          => shamt_ID_EX_REG,
	     Func_in           => Func_ID_EX_REG,
	     ALUout_out        => ALUout_EX_stage,
	     Jump_Reg_value    => Jump_Reg_value,
	     ExtOp			   => ExtOp_ID_EX_REG,
	     ALUop             => ALUOp_ID_EX_REG,
	     ALUSrc            => ALUsrc_ID_EX_REG,
	     RegDst            => RegDst_ID_EX_REG,
	     JumpReg           => JumpReg_EX_stage,
	     JAL_in			   => JAL_ID_EX_REG,
	     forward_busA_ALU_out_EX_MEM => forward_busA_ALU_out_EX_MEM,
	     forward_busA_WB_value => forward_busA_WB_value,
	     forward_busB_ALU_out_EX_MEM => forward_busB_ALU_out_EX_MEM,
	     forward_busB_WB_value => forward_busB_WB_value,
	     ALUout_EX_MEM_REG => ALUout_EX_MEM_REG,
	     Di_WR_stage => Di_WR_stage
	);
	
	EX_MEM_REG_U: entity work.EX_MEM_REG
	port map
	(
		 clk               => clk,
	     rst               => rst,
	     PC_inc_in         => PC_inc_ID_EX_REG,
	     PC_inc_out        => PC_inc_EX_MEM_REG,
	     ALUout_in         => ALUout_EX_stage,
	     ALUout_out        => ALUout_EX_MEM_REG,
	     Rb_in             => Rb_EX_stage, --selects between forwarded and stored value
	     Rb_out            => Rb_EX_MEM_REG,
	     Rw_in             => Rw_EX_stage,
	     Rw_out            => Rw_EX_MEM_REG,
	     MemWr_in          => MemWr_ID_EX_REG,
	     MemWr_out         => MemWr_EX_MEM_REG,
	     byte_ena_in       => byte_enable_ID_EX_REG,
	     byte_ena_out      => byte_ena_EX_MEM_REG,
	     JAL_in            => JAL_ID_EX_REG,
	     JAL_out           => JAL_EX_MEM_REG,
	     MemtoReg_in       => MemToReg_ID_EX_REG,
	     MemtoReg_out      => MemtoReg_EX_MEM_REG,
	     Reg_Wr_in         => Reg_Wr_ID_EX_REG,
	     Reg_Wr_out        => Reg_Wr_EX_MEM_REG
	);
	
	MemWr_and_clk_EX_MEM_REG <= MemWr_EX_MEM_REG and clk;
	
	MEM_UNIT_U: entity work.MEM_unit
	port map
	(
		 ALUout_in           => ALUout_EX_MEM_REG,
	     Data_Address        => Data_Address,
	     Rb_in               => Rb_EX_MEM_REG,
	     Data_to_Memory_out  => Data_to_Memory_out,
	     Data_Memory_out_in  => Data_to_CPU_in,
	     Data_Memory_out_out => Data_Memory_out_MEM_stage,
	     Rw_in               => Rw_EX_MEM_REG,
	     Rw_out              => Rw_MEM_stage,
	     MemWr_in            => MemWr_and_clk_EX_MEM_REG,
	     MemWr_out           => MemWr_to_memory,
	     byte_ena_in         => byte_ena_EX_MEM_REG,
	     byte_ena_out        => byte_ena_to_memory
	);
	
	MEM_WR_REG_U: entity work.MEM_WR_REG
	port map
	(
		 clk                 => clk,
	     rst                 => rst,
	     PC_INC_in           => PC_inc_EX_MEM_REG,
	     PC_INC_out          => PC_INC_MEM_WR_REG,
	     ALU_out_in          => ALUout_EX_MEM_REG,
	     ALU_out_out         => ALU_out_MEM_WR_REG,
	     Data_Memory_out_in  => Data_Memory_out_MEM_stage,
	     Data_Memory_out_out => Data_Memory_out_MEM_WR_REG,
	     Rw_in               => Rw_MEM_stage,
	     Rw_out              => Rw_MEM_WR_REG,
	     MemtoReg_in         => MemtoReg_EX_MEM_REG,
	     MemtoReg_out        => MemtoReg_MEM_WR_REG,
	     Reg_Wr_in           => Reg_Wr_EX_MEM_REG,
	     Reg_Wr_out          => Reg_Wr_MEM_WR_REG,
	     JAL_in  			 => JAL_EX_MEM_REG,
	     JAL_out			 => JAL_MEM_WR_REG
	);
	
	WR_UNIT_U: entity work.WR_unit
	port map
	(
		 PC_INC_in          => PC_INC_MEM_WR_REG,
	     ALUout_in          => ALU_out_MEM_WR_REG,
	     Data_Memory_Out_in => Data_Memory_out_MEM_WR_REG,
	     Di_out             => Di_WR_stage,
	     MemToReg_in        => MemtoReg_MEM_WR_REG,
	     JAL_in             => JAL_MEM_WR_REG
	);
	
	FORWARDING_UNUT_U: entity work.forwarding_unit --forwarding unit (fixes not stalling hazards)
	port map
	(
		 rw_EX_MEM_REG                => rw_EX_MEM_REG,
	     rw_MEM_WR_REG                => rw_MEM_WR_REG,
	     Reg_Wr_EX_MEM_REG            => Reg_Wr_EX_MEM_REG,
	     Reg_Wr_MEM_WR_REG            => Reg_Wr_MEM_WR_REG,
	     rs_ID_EX_REG                 => rs_ID_EX_REG,
	     rt_ID_EX_REG                 => rt_ID_EX_REG,
	     rs_IF_ID_REG                 => rs_IF_ID_REG,
	     rt_IF_ID_REG                 => rt_IF_ID_REG,
	     ALU_src_ID_EX_REG            => ALUsrc_ID_EX_REG,
	     ALU_src_ID_stage             => ALUsrc_ID_stage,
	     Branch_ID_stage              => Branch_ID_stage,
	     MemWr_ID_EX_REG			  => MemWr_ID_EX_REG,
	     MemWr_ID_stage				  => MemWr_ID_stage,
	     forward_busA_ALU_out_EX_MEM  => forward_busA_ALU_out_EX_MEM,
	     forward_busB_ALU_out_EX_MEM  => forward_busB_ALU_out_EX_MEM,
	     forward_busA_WB_value        => forward_busA_WB_value,
	     forward_busB_WB_value        => forward_busB_WB_value,
	     forward_Reg_A_ID_EX_WB_stage => forward_Reg_A_ID_EX_WB_stage,
	     forward_Reg_B_ID_EX_WB_stage => forward_Reg_B_ID_EX_WB_stage,
	     forward_Reg_A_ID_EX_EX_MEM   => forward_Reg_A_ID_EX_EX_MEM,
	     forward_Reg_B_ID_EX_EX_MEM   => forward_Reg_B_ID_EX_EX_MEM
	);
	
	HAZARD_UNIT_U: entity work.hazard_detection_unit --stalling unit for necessary data hazards
	port map
	(
		 Rt_ID_EX_REG     => Rt_ID_EX_REG,
	     Rd_ID_EX_REG     => Rd_ID_EX_REG,
	     Rs_IF_ID_REG     => Rs_IF_ID_REG,
	     Rt_IF_ID_REG     => Rt_IF_ID_REG,
	     Rw_EX_MEM_REG    => Rw_EX_MEM_REG,
	     MemtoReg_ID_EX   => MemtoReg_ID_EX_REG,
	     MemtoReg_EX_MEM  => MemtoReg_EX_MEM_REG,
	     Branch_in        => Branch_ID_stage,
	     ALU_src_ID_stage => ALUsrc_ID_stage,
	     ALU_src_ID_EX    => ALUsrc_ID_EX_REG,
	     Reg_Wr_ID_stage  => RegWr_ID_stage,
	     Reg_Wr_ID_EX_REG => Reg_Wr_ID_EX_REG,
	     stall_pipeline   => stall_pipeline
	);
end architecture arch;
