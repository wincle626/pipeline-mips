--contains exec unit, mux for RegDst
--Exec unit contains ALU and branch adder
library ieee;
use ieee.std_logic_1164.all;

entity EX_unit is
port
(	
	Immediate32_in : in std_logic_vector(31 downto 0); --from ID_EX reg, fed to extender
	
	Ra_in, Rb_in : in std_logic_vector(31 downto 0); --from ID_EX reg
	Rb_out : out std_logic_vector(31 downto 0);
	
	Rt_in, Rd_in : in std_logic_vector(4 downto 0); --from ID_EX reg, into a mux selected by RegDst
	Rw_out : out std_logic_vector(4 downto 0); --fed to EX_MEM reg and then MEM_WR for writeback
	
	shamt_in : in std_logic_vector(4 downto 0);
	Func_in : in std_logic_vector(5 downto 0);
	
	ALUout_out,Jump_Reg_value : out std_logic_vector(31 downto 0);
	
	JumpReg : out std_logic;
	
	--Control signals
	ExtOp : in std_logic;
	ALUop : in std_logic_vector(2 downto 0); --selects aluop for ALUcontrol with func_in
	ALUSrc : in std_logic; --selects immediate or Rt
	RegDst : in std_logic; --destination register selector
	JAL_in : in std_logic;
	
	--forwarding signals
	--from EX_MEM
	forward_busA_ALU_out_EX_MEM,forward_busB_ALU_out_EX_MEM : in std_logic;
	--from MEM_WR
	forward_busA_WB_value,forward_busB_WB_value : in std_logic;
	
	--forwarded data
	ALUout_EX_MEM_REG,Di_WR_stage : in std_logic_vector(31 downto 0)
);
end EX_unit;

architecture arch of EX_unit is

signal ALU_control : std_logic_vector(3 downto 0);
signal input_a,input_b : std_logic_vector(31 downto 0);
signal shamt : std_logic_vector(4 downto 0);
signal LUI : std_logic;
signal shdir : std_logic;
signal Immediate32 : std_logic_vector(31 downto 0);
signal Rw_Sel : std_logic_vector(1 downto 0);

signal A_sel : std_logic_vector(1 downto 0); --forward to A from WB & EX_MEM
signal B_sel : std_logic_vector(1 downto 0); --forward to B from WB & EX_MEM
signal input_b_or_immediate : std_logic_vector(31 downto 0);

begin
	ALU_CONTROL_U: entity work.alu32control --alu control
	port map
	(
		 func    => func_in,
	     ALUop   => ALUop,
	     control => ALU_control,
	     LUI	 => LUI,
	     shdir   => shdir,
	     JumpReg => JumpReg
	);
	
	process(Immediate32_in,ExtOp) --zero extend or sign extend, this is a giant and gate with extop on the upper 16 bits of immediate
	variable input_b_upper : std_logic_vector(31 downto 16);
	begin
		for i in 31 downto 16 loop
			input_b_upper(i) := Immediate32_in(i) and ExtOp;
		end loop;
		Immediate32 <= input_b_upper & Immediate32_in(15 downto 0);
	end process;
	
	A_sel <= forward_busA_WB_value & forward_busA_ALU_out_EX_MEM; --input a selection mux, for forwarding
	with A_sel select
	input_a <= Di_WR_stage when "10",
			   ALUout_EX_MEM_REG when "01" | "11", --prioritize later instruction for forwarding
			   Ra_in when others;
	
	B_sel <= forward_busB_WB_value & forward_busB_ALU_out_EX_MEM; --input b selection mux for forwarding
	with B_sel select
	input_b <= Di_WR_stage when "10",
			   ALUout_EX_MEM_REG when "01" | "11", --priority as above
			   Rb_in when others;
			   
	input_b_or_immediate <= input_b when ALUSrc = '0' else
							Immediate32;
	
--	input_b <= Rb_in when ALUSrc = '0' else --alu input b selection mux for immediates
--			   immediate32;		
			   
	shamt <= shamt_in when LUI = '0' else --shamt input selection mux (for LUI)
			 "10000"; --shift by 16 for lui
	
	ALU: entity work.alu32 --the 32 bit alu
	generic map(WIDTH => 32)
	port map
	(
		 ia      => input_a,
	     ib      => input_b_or_immediate,
	     control => ALU_control,
	     shamt   => shamt,
	     shdir   => shdir,
	     o       => ALUout_out
	);
	
	Jump_Reg_value <= input_a;
	
	Rw_Sel <= RegDst & JAL_in;
	
	Rb_out <= input_b;
	
	with Rw_Sel select --select where Rw is, Rt/Rd/31
	Rw_out <= Rd_in when "10",
		      Rt_in when "00",
		      "11111" when others;
end architecture arch;
