-- 
-- EnvelopeMemory.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity EnvelopeMemory is port (
  clk     : in std_logic;
  reset   : in std_logic;

  waddr   : in SLOT_TYPE;
  wr      : in std_logic;
  wdata   : in EGDATA_TYPE;
  raddr   : in SLOT_TYPE;
  rdata   : out EGDATA_TYPE
  );
end EnvelopeMemory;
 
architecture RTL of EnvelopeMemory is

  type EGDATA_ARRAY is array (0 to MAXSLOT-1) of EGDATA_VECTOR_TYPE;
  signal egdata_set : EGDATA_ARRAY;
  
begin

  process (clk, reset) 
   
    variable init_slot : integer range 0 to SLOT_TYPE'high+1;  
    
  begin
  
   if reset = '1' then
   
     init_slot := 0;       
   
   elsif clk'event and clk = '1' then
   
     if init_slot /= SLOT_TYPE'high + 1 then     
       egdata_set(init_slot) <= (others=>'1');
       init_slot := init_slot + 1;     
     elsif wr = '1' then     
       egdata_set(waddr) <= CONV_EGDATA_VECTOR(wdata);       
     end if;       
     rdata <= CONV_EGDATA(egdata_set(raddr));
     
   end if;
   
end process;

end RTL;
