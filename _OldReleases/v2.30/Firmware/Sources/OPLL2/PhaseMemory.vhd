-- 
-- PhaseMemory.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity PhaseMemory is 
  port (
    clk     : in std_logic;
    reset   : in std_logic;
    slot    : in SLOT_TYPE;
    memwr   : in std_logic;
    memout  : out PHASE_TYPE;
    memin   : in  PHASE_TYPE
  );
end PhaseMemory;

architecture RTL of PhaseMemory is

  type PHASE_ARRAY_TYPE is array (0 to MAXSLOT-1) of PHASE_TYPE;
  signal phase_array : PHASE_ARRAY_TYPE;

begin

  process (clk, reset)

    variable init_slot : integer range 0 to MAXSLOT;

  begin
  
   if reset = '1' then
    
      init_slot := 0;
      
   elsif clk'event and clk = '1' then

     if init_slot /= MAXSLOT then
     
       phase_array(init_slot) <= (others=>'0');
       init_slot := init_slot + 1;
       
     elsif memwr = '1' then
     
         phase_array(slot) <= memin;
         
     end if;
     
     memout <= phase_array(slot);
     
    end if;
        
  end process;

end RTL;