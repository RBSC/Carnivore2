-- 
-- SlotCounter.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity SlotCounter is 
  generic (
      DELAY : integer range 0 to MAXSLOT*4-1
  );
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;
  
    slot   : out SLOT_TYPE;
    stage  : out STAGE_TYPE
  );
end SlotCounter;

architecture RTL of SlotCounter is

begin

  process(clk, reset)
  
    variable count : integer range 0 to MAXSLOT*4-1;

  begin

    if reset = '1' then

      count := MAXSLOT*4-1-DELAY;

    elsif clk'event and clk='1' then if clkena ='1' then

      if count = MAXSLOT*4-1 then
        count := 0;
      else
        count := count + 1;
      end if;
      
      slot  <= count/4;
      stage <= count mod 4;

    end if; end if;
  
  end process;    
  
end RTL;
