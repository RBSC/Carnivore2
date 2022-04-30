-- 
-- PhaseGenerator.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity PhaseGenerator is port (
  clk      : in std_logic;
  reset    : in std_logic;
  clkena   : in std_logic;
  
  slot     : in SLOT_TYPE;
  stage    : in STAGE_TYPE;
  
  rhythm : in std_logic;
  pm     : in PM_TYPE;
  ml     : in ML_TYPE;
  blk    : in BLK_TYPE;
  fnum   : in FNUM_TYPE;
  key    : in std_logic;

  noise  : out std_logic;  
  pgout  : out PGOUT_TYPE
  );
end PhaseGenerator;

architecture RTL of PhaseGenerator is

  component PhaseMemory is port (
    clk     : in std_logic;
    reset   : in std_logic;
    
	slot    : in SLOT_TYPE;
	memwr   : in std_logic;
	
	memout  : out PHASE_TYPE;
	memin   : in  PHASE_TYPE
    );
  end component;
  
  type ML_TABLE is array (0 to 15) of std_logic_vector(4 downto 0);
  
  constant mltbl : ML_TABLE := (
    "00001","00010","00100","00110","01000","01010","01100","01110",
    "10000","10010","10100","10100","11000","11000","11110","11110"
  ); 
  
  constant noise14_tbl : std_logic_vector(63 downto 0) :=
    "1000100010001000100010001000100100010001000100010001000100010000";
  constant noise17_tbl : std_logic_vector(7 downto 0) :=
    "00001010";

  -- Signals connected to the phase memory.
  signal memwr : std_logic;
  signal memout, memin : PHASE_TYPE;
  
  -- Counter for pitch modulation;  
  signal pmcount : std_logic_vector(12 downto 0);
  
  function CONV_PGOUT ( pv : PHASE_TYPE ) return PGOUT_TYPE is
  begin
    return pv(PHASE_TYPE'high downto PHASE_TYPE'high - PGOUT_TYPE'high);
  end;

begin

  process(clk, reset)

    variable lastkey : std_logic_vector(MAXSLOT-1 downto 0); 
    variable dphase : PHASE_TYPE;   
    variable noise14 : std_logic;
    variable noise17 : std_logic;
    variable pgout_buf : PGOUT_TYPE;
    
  begin

    if reset = '1' then

      pmcount <= (others=>'0');
      memwr <= '0';
      lastkey := (others=>'0');
      dphase  := (others=>'0');
      noise14 := '0';
      noise17 := '0';

    elsif clk'event and clk='1' then if clkena = '1' then
    
      noise <= noise14 xor noise17;

      if stage = 0 then
     
        memwr <= '0';
        
      elsif stage = 1 then
     
        -- Wait for memory
     
      elsif stage = 2 then

        -- Update pitch LFO counter when slot = 0 and stage = 0 (i.e. increment per 72 clocks)
        if slot = 0 then        
          pmcount <= pmcount + '1';          
        end if;
	 
        -- Delta phase
	    dphase := (SHL("00000000"&(fnum*mltbl(CONV_INTEGER(ml))),blk)(19 downto 2));
	    
	    if pm ='1' then
           case pmcount(pmcount'high downto pmcount'high-1) is
             when "01" => 
               dphase := dphase + SHR(dphase,"111");
             when "11" => 
               dphase := dphase - SHR(dphase,"111");
             when others => null;
           end case;
	    end if;
        
  	    -- Update Phase
	    if lastkey(slot) = '0' and key = '1' and (rhythm = '0' or (slot /= 14 and slot /= 17)) then
	      memin <= (others=>'0');
        else
	      memin <= memout + dphase;
	    end if;
	    lastkey(slot) := key;
	    
        -- Update noise
        if slot = 14 then
	      noise14 := noise14_tbl(CONV_INTEGER(memout(15 downto 10)));
        elsif slot = 17 then
	      noise17 := noise17_tbl(CONV_INTEGER(memout(13 downto 11)));
        end if;
        
	    pgout_buf := CONV_PGOUT(memout);
	    pgout <= pgout_buf;
        memwr <= '1';

      elsif stage = 3 then
      
        memwr <= '0';
      
      end if;

    end if; end if;

  end process; 
  
  MEM : PhaseMemory port map(clk,reset,slot,memwr,memout,memin);

end RTL;

