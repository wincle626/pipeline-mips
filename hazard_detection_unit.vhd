library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detection_unit is
port
(
	Rt_ID_EX_REG, Rd_ID_EX_REG, Rs_IF_ID_REG, Rt_IF_ID_REG, Rw_EX_MEM_REG : in std_logic_vector(4 downto 0); --destinations and sources
	
	MemtoReg_ID_EX, MemtoReg_EX_MEM: in std_logic; --is the next or after operation a load?
	
	Branch_in : in std_logic; --need to know if branching or Jumping for a stall
	
	ALU_src_ID_stage, ALU_src_ID_EX : in std_logic;
	
	Reg_Wr_ID_stage,Reg_Wr_ID_EX_REG : in std_logic; --need to know if we are going to overwrite any values
	
	stall_pipeline : out std_logic --stall if necessary, forces 0 into ID_EX reg and holds previous IF_ID and PC
);
end hazard_detection_unit;

architecture arch of hazard_detection_unit is
begin
	process(Branch_in, MemtoReg_EX_MEM, MemtoReg_ID_EX, Rd_ID_EX_REG, Reg_Wr_ID_EX_REG, Rs_IF_ID_REG, Rt_ID_EX_REG, Rt_IF_ID_REG, Rw_EX_MEM_REG, ALU_src_ID_stage, Reg_Wr_ID_stage, ALU_src_ID_EX)
	begin
		stall_pipeline <= '0';
		
		if(Branch_in = '1' and Reg_Wr_ID_EX_REG = '1') then --we need to stall
			--operation immediately previous is a load or immediate so result goes in Rt
			if(ALU_src_ID_EX = '1') then
				if((unsigned(Rs_IF_ID_REG) = unsigned(Rt_ID_EX_REG)) or (unsigned(Rt_IF_ID_REG) = unsigned(Rt_ID_EX_REG))) then
					stall_pipeline <= '1';
				end if;
			end if;
			
			--operation immediately previous is not a load so result goes in Rd
			if(MemtoReg_ID_EX = '0') then
				if((unsigned(Rs_IF_ID_REG) = unsigned(Rd_ID_EX_REG)) or (unsigned(Rt_IF_ID_REG) = unsigned(Rd_ID_EX_REG))) then
					stall_pipeline <= '1';
				end if;
			end if;
			
			if(MemtoReg_EX_MEM = '1') then --operation 2 previous is a load result in it's rt (this would be a second stall)
				if((unsigned(Rs_IF_ID_REG) = unsigned(Rw_EX_MEM_REG)) or (unsigned(Rt_IF_ID_REG) = unsigned(Rw_EX_MEM_REG))) then
					stall_pipeline <= '1';
				end if;
			end if;
		end if;
		
		--load op then reg op needs a stall
		if(MemtoReg_ID_EX = '1' and Reg_Wr_ID_stage = '1') then
			--if the load register is equal to either source next instruction and it is R type, stall
			if((unsigned(Rt_ID_EX_REG) = unsigned(Rs_IF_ID_REG) or unsigned(Rt_ID_EX_REG) = unsigned(Rt_IF_ID_REG)) and ALU_src_ID_stage = '0') then
				stall_pipeline <= '1';
			
			--if the load register is equal to rt and the next instruction is immediate
			elsif(((unsigned(Rt_ID_EX_REG) = unsigned(Rs_IF_ID_REG)) and ALU_src_ID_stage = '1')) then
				stall_pipeline <= '1';
			end if;
		end if;
	end process;	
end architecture arch;
