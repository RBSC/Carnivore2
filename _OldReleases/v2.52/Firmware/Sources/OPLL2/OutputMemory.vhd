-- 
-- OutputMemory.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity OutputMemory is port ( 
  clk    : in std_logic;
  reset  : in std_logic;
  wr     : in std_logic;
  addr  : in SLOT_TYPE;
  wdata  : in SIGNED_LI_TYPE;
  rdata  : out SIGNED_LI_TYPE;
  addr2  : in SLOT_TYPE;
  rdata2 : out SIGNED_LI_TYPE
);
end OutputMemory;

architecture RTL of OutputMemory is

  type SIGNED_LI_ARRAY_TYPE is array (0 to MAXSLOT) of SIGNED_LI_VECTOR_TYPE;
  signal data_array : SIGNED_LI_ARRAY_TYPE;
  
begin

  process(clk, reset)
  
    variable init_ch : integer range 0 to MAXSLOT;
    
  begin
  
    if (reset = '1') then 
         
      init_ch := 0; 
               
    elsif clk'event and clk='1' then
    
      if init_ch /= MAXSLOT then
            
        data_array(init_ch) <= (others=>'0');
        init_ch := init_ch + 1;
              
      elsif wr='1' then
            
        data_array(addr) <= CONV_SIGNED_LI_VECTOR(wdata);
                
      end if;
      
      rdata <= CONV_SIGNED_LI(data_array(addr));
      rdata2 <= CONV_SIGNED_LI(data_array(addr2));
      
    end if;
    
  end process;
  
end RTL;