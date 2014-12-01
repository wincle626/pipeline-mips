library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
port
(
	rw_EX_MEM_REG,rw_MEM_WR_REG : in std_logic_vector(4 downto 0); --results that could cause hazards if not forwarded from
	Reg_Wr_EX_MEM_REG, Reg_Wr_MEM_WR_REG : in std_logic; --writeback flag, if true then do hazard detection	
	
	rs_ID_EX_REG,rt_ID_EX_REG : in std_logic_vector(4 downto 0); --sources that may use future results
	rs_IF_ID_REG,rt_IF_ID_REG : in std_logic_vector(4 downto 0);
	
	ALU_src_ID_EX_REG, ALU_src_ID_stage, Branch_ID_stage,MemWr_ID_EX_REG : in std_logic; --signals needed to differentiate R/I/B type instructions
	
	MemWr_ID_stage : in std_logic; --needed for forwarding to ID_EX reg's
	
	forward_busA_ALU_out_EX_MEM,forward_busB_ALU_out_EX_MEM : out std_logic; --control signals to forward the new data to busA or busB of ALU from ALU_out_EX_MEM reg, also forwards to ID_EX for branches
	forward_busA_WB_value, forward_busB_WB_value : out std_logic; --control signals to forward new data to busA or busB of the ALU
	forward_Reg_A_ID_EX_WB_stage, forward_Reg_B_ID_EX_WB_stage : out std_logic; --control signals to forward WB_stage value to ID_EX register
	forward_Reg_A_ID_EX_EX_MEM, forward_Reg_B_ID_EX_EX_MEM : out std_logic --control signal to forward RegA/B from EX_MEM reg for branching
);
end forwarding_unit;

architecture arch of forwarding_unit is
begin
	process(rw_EX_MEM_REG, Reg_Wr_EX_MEM_REG, rs_ID_EX_REG, rs_IF_ID_REG, rt_ID_EX_REG, rt_IF_ID_REG,
		    rw_MEM_WR_REG, Reg_Wr_MEM_WR_REG, ALU_src_ID_EX_REG, Branch_ID_stage, ALU_src_ID_stage, MemWr_ID_EX_REG, MemWr_ID_stage)
	begin
		forward_busA_ALU_out_EX_MEM <= '0'; --forward nothing by default
		forward_busB_ALU_out_EX_MEM <= '0';
		forward_busA_WB_value <= '0';
		forward_busB_WB_value <= '0';
		forward_Reg_A_ID_EX_WB_stage <= '0';
		forward_Reg_B_ID_EX_WB_stage <= '0';
		forward_Reg_A_ID_EX_EX_MEM <= '0';
		forward_Reg_B_ID_EX_EX_MEM <= '0';
		
		--things coming after JAL are handled, RegWr is checked and so is the register being written to
				
		--only execute if we are doing an operation that will writeback a value
		if(Reg_Wr_EX_MEM_REG = '1') then
			--forwards from the EX_MEM register to the ALU inputs
			if(unsigned(rw_EX_MEM_REG) = unsigned(rs_ID_EX_REG)) then
				forward_busA_ALU_out_EX_MEM <= '1';
			end if;		
			if(unsigned(rw_EX_MEM_REG) = unsigned(rt_ID_EX_REG) and (ALU_src_ID_EX_REG = '0' or MemWr_ID_EX_REG = '1')) then --only forward to Rt if later operation is R type or a store
				forward_busB_ALU_out_EX_MEM <= '1';
			end if;
			
			--case where we need to forward for branches to ID_EX reg selection mux, which goes to branch comparator as well
			--these are only used for branches and forwarding for them, otherwise the 3rd cycle branches are handled later on
			if((unsigned(rw_EX_MEM_REG) = unsigned(rs_IF_ID_REG)) and Branch_ID_stage = '1') then
				forward_Reg_A_ID_EX_EX_MEM <= '1';
			end if;
			
			if((unsigned(rw_EX_MEM_REG) = unsigned(rt_IF_ID_REG)) and Branch_ID_stage = '1') then
				forward_Reg_B_ID_EX_EX_MEM <= '1';
				end if;		
		end if;
		
		if(Reg_Wr_MEM_WR_REG = '1') then
			--forwards from the WB_stage to the ALU inputs
			if(unsigned(rw_MEM_WR_REG) = unsigned(rs_ID_EX_REG)) then
				forward_busA_WB_value <= '1';
			end if;
			if(unsigned(rw_MEM_WR_REG) = unsigned(rt_ID_EX_REG) and (ALU_src_ID_EX_REG = '0' or MemWr_ID_EX_REG = '1')) then --only forward to Rt if later operation is R type
				forward_busB_WB_value <= '1';
			end if;
			
			--from the WB_stage to the ID_EX register a and b inputs
			if(unsigned(rw_MEM_WR_REG) = unsigned(rs_IF_ID_REG)) then
				forward_Reg_A_ID_EX_WB_stage <= '1';
			end if;
			if(unsigned(rw_MEM_WR_REG) = unsigned(rt_IF_ID_REG) and (ALU_src_ID_stage = '0' or MemWr_ID_stage = '1')) then --only forward to Rt if later operation is R type
				forward_Reg_B_ID_EX_WB_stage <= '1';
			end if;	
		end if;				
	end process;			
end architecture arch;
