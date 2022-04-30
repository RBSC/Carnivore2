-- 
-- OutputGenerator.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity OutputGenerator is 
  port (
    clk     : in std_logic;
    reset   : in std_logic;
    clkena  : in std_logic;
    slot    : in SLOT_TYPE;
    stage   : in STAGE_TYPE;    
    
    rhythm  : in std_logic;
    opout   : in SIGNED_DB_TYPE; 
    
    faddr  : in CH_TYPE;
    fdata  : out SIGNED_LI_TYPE;
    
    maddr  : in SLOT_TYPE;
    mdata  : out SIGNED_LI_TYPE
  );
end OutputGenerator;

architecture RTL of OutputGenerator is

  component FeedbackMemory port ( 
    clk    : in std_logic;
    reset  : in std_logic;
    wr     : in std_logic;
    waddr  : in CH_TYPE;
    wdata  : in SIGNED_LI_TYPE;
    raddr  : in CH_TYPE;
    rdata  : out SIGNED_LI_TYPE
  );
  end component;

  component OutputMemory port ( 
    clk    : in std_logic;
    reset  : in std_logic;
    wr     : in std_logic;
    addr   : in SLOT_TYPE;
    wdata  : in SIGNED_LI_TYPE;
    rdata  : out SIGNED_LI_TYPE;
    addr2  : in SLOT_TYPE;
    rdata2 : out SIGNED_LI_TYPE
  );
  end component;

  component LinearTable port ( 
    clk    : in std_logic;
    reset  : in std_logic;    
    addr   : in  SIGNED_DB_TYPE;
    data   : out SIGNED_LI_TYPE
  );
  end component;
   
  function AVERAGE ( L : SIGNED_LI_TYPE ; R : SIGNED_LI_TYPE ) return SIGNED_LI_TYPE is
    variable vL, vR : std_logic_vector(LI_TYPE'high + 2 downto 0);
  begin
  
    if L.sign = '0' then
      vL := "00" & L.value;
    else
      vL := not ( "00" & L.value ) + '1';
    end if;
     if R.sign = '0' then
      vR := "00" & R.value;
    else
      vR := not ( "00" & R.value ) + '1';
    end if; 
    
    vL := vL + vR;

    if vL(vL'high) = '0' then -- positive
      return ( sign => '0', value => vL(vL'high-1 downto 1) );
    else -- negative
      vL := not ( vL - '1' );
      return ( sign => '1', value => vL(vL'high-1 downto 1) );
    end if;
    
  end;
  
  signal fb_wr, mo_wr : std_logic;
  signal fb_addr : CH_TYPE;  
  signal mo_addr : SLOT_TYPE;
  signal li_addr : SIGNED_DB_TYPE;
  signal li_data, fb_wdata, mo_wdata, mo_rdata : SIGNED_LI_TYPE;
  
begin
  
  Fmem : FeedbackMemory port map( clk, reset, fb_wr, fb_addr, fb_wdata, faddr, fdata );
   
  Mmem : OutputMemory port map( clk, reset, mo_wr, mo_addr, mo_wdata, mo_rdata, maddr, mdata );
  
  Ltbl : LinearTable port map( clk, reset, li_addr, li_data );
  
  process (clk, reset)
 
  begin
    
    if reset = '1' then
    
      mo_wr <= '0';
      fb_wr <= '0';
    
    elsif clk'event and clk = '1' then if clkena = '1' then
  
      if stage = 0 then
    
        mo_wr <= '0';
        fb_wr <= '0';
        
        mo_addr <= slot;
        li_addr  <= opout;
    
      elsif stage = 1 then
    
        -- wait for linear table data & feedback memory
    
      elsif stage = 2 then
    
        -- Store modulator output to feedback memory
        if slot mod 2 = 0 then         
          fb_addr  <= slot/2;
          fb_wdata <= AVERAGE(mo_rdata, li_data);
          fb_wr <= '1';     
        end if;
        
        -- Store raw output
        mo_addr <= slot;
        mo_wdata <= li_data;
        mo_wr <= '1';
        
      elsif stage = 3 then
      
        mo_wr <= '0';
        fb_wr <= '0';
          
      end if;
  
    end if; end if;
    
  end process;

end RTL;
