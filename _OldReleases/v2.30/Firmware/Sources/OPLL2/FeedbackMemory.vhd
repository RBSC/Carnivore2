-- 
-- FeedbackMemory.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

--
-- This module represents a store for feedback data of all OPLL channels. The feedback 
-- data is written by the OutputGenerator module. Then the value written is 
-- read from the Operator module.
-- 
entity FeedbackMemory is port ( 
  clk    : in std_logic;
  reset  : in std_logic;
  wr     : in std_logic;
  waddr  : in CH_TYPE;
  wdata  : in SIGNED_LI_TYPE;
  raddr  : in CH_TYPE;
  rdata  : out SIGNED_LI_TYPE
);
end FeedbackMemory;

architecture RTL of FeedbackMemory is

  type SIGNED_LI_ARRAY_TYPE is array (0 to MAXCH-1) of SIGNED_LI_VECTOR_TYPE;
  signal data_array : SIGNED_LI_ARRAY_TYPE;
  
begin

  process(clk, reset)
  
    variable init_ch : integer range 0 to MAXCH;
    
  begin
  
    if reset = '1' then
    
      init_ch := 0;
  
    elsif clk'event and clk='1' then
    
      if init_ch /= MAXCH then
      
        data_array(init_ch) <= (others=>'0');
        init_ch := init_ch + 1;
      
      elsif wr='1' then
      
        data_array(waddr) <= CONV_SIGNED_LI_VECTOR(wdata);
        
      end if;
      
      rdata <= CONV_SIGNED_LI(data_array(raddr));
      
    end if;
    
  end process;
  
end RTL;