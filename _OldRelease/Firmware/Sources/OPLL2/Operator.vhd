-- 
-- Operator.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity Operator is
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;
    
    slot   : in SLOT_TYPE;    
    stage  : in STAGE_TYPE;
    rhythm : in std_logic;
        
	WF     : in WF_TYPE;
    FB     : in FB_TYPE;
       
    noise  : in std_logic;
    pgout  : in PGOUT_TYPE;
    egout  : in DB_TYPE;
    
    faddr  : out CH_TYPE;
    fdata  : in SIGNED_LI_TYPE;
    
	opout  : out SIGNED_DB_TYPE
  );	    
end Operator;

architecture RTL of Operator is

  component AttackTable port (
    clk  : in std_logic;
    addr : in  DB_TYPE;
    data : out DB_TYPE  
  );
  end component;

  component SineTable port (
    clk     : in std_logic;
    wf      : in std_logic;
    addr    : in integer range 0 to (2 ** (PGOUT_TYPE'high+1) - 1);
    data    : out SIGNED_DB_TYPE
  );
  end component;
  
  signal addr : integer range 0 to (2 ** (PGOUT_TYPE'high+1) - 1);
  signal data : SIGNED_DB_TYPE;
  
begin

  SINTBL : SineTable port map ( clk, WF, addr, data );

  process(clk, reset)

    variable modula : std_logic_vector(LI_TYPE'high + 2 downto 0);
    variable opout_buf : SIGNED_DB_TYPE;
  
  begin
  
    if reset='1' then

      opout <= ( sign=>'0', value=>(others=>'0') );

    elsif clk'event and clk='1' then if clkena = '1' then
      
      if stage = 0 then      
      
        -- periodic noise
	    if rhythm = '1' and ( slot = 14 or slot = 17 ) then -- HH or CYM
	    	   
	      if noise = '1' then
	        addr <= 127; -- phase of max value
	      else
	        addr <= 383; -- phase of min value
          end if;
           
        elsif rhythm = '1' and slot = 15 then -- SD
               
          if pgout(pgout'high) = '1' then
            addr <= 127; -- phase of max value
          else
            addr <= 383; -- phase of min value
          end if;       
          
        elsif rhythm = '1' and slot = 16 then -- TOM       
          
          addr <= CONV_INTEGER(pgout);
          
        else 
        
          if slot mod 2 = 0 then
            if FB = "000" then            
              modula := (others => '0') ;              
            else      
              modula := "0" & fdata.value & "0";
              modula := SHR( modula, "111" - FB );               
            end if;            
          else
            modula := fdata.value & "00";         
          end if;
          
          if fdata.sign = '0' then          
            addr <= CONV_INTEGER(pgout + modula(pgout'range));
          else          
            addr <= CONV_INTEGER(pgout - modula(pgout'range));
          end if;
          
        end if;
        
      elsif stage = 1 then
      
        -- Wait for sine and attack table.
      
      elsif stage = 2 then
      
        -- output 
	    if ( ( '0'&egout ) + ('0'&data.value) ) < "10000000" then
          opout_buf := ( sign=>data.sign, value=> egout + data.value ); 
        else
          opout_buf := ( sign=>data.sign, value=> (others=>'1') );
        end if;          
	  
        -- read feedback data for the next slot
        if slot mod 2 = 1 then
          if slot/2 = 8 then 
            faddr <= 0;
          else
            faddr <= slot/2 + 1;
          end if;
        else
          faddr <= slot/2;
        end if;
        
        opout <= opout_buf;
	  
	  elsif stage = 3 then
	  
	    -- wait for feedback data.
	  
      end if;

    end if; end if;     

  end process;

end RTL;
