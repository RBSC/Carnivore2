-- 
-- RegisterMemory.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity RegisterMemory is port (  
  clk    : in std_logic;
  reset  : in std_logic;
  addr   : in CH_TYPE;
  wr     : in std_logic;
  idata  : in REGS_TYPE;
  odata  : out REGS_TYPE
);  
end RegisterMemory;

architecture RTL of RegisterMemory is

  -- **SKBLK<FNUMBER><AT><VO> 
  --"000000000000000000000000"
  type REGS_ARRAY_TYPE is array (CH_TYPE'range) of REGS_VECTOR_TYPE;
  signal rarray : REGS_ARRAY_TYPE;
  
begin

  process (clk, reset)

    variable init_ch : integer range 0 to CH_TYPE'high + 1;
   
  begin
  
    if reset = '1' then
    
      init_ch := 0;
  
    elsif clk'event and clk ='1' then
  
      if init_ch /= CH_TYPE'high + 1 then    
        rarray(init_ch) <= (others =>'0');
        init_ch := init_ch + 1;    
      elsif wr = '1' then            
        rarray(addr) <= CONV_REGS_VECTOR(idata);        
      end if;
             
      odata <= CONV_REGS(rarray(addr));
        
    end if;
  
  end process;

end RTL;