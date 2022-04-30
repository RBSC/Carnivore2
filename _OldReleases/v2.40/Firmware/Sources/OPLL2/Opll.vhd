-- 
-- Opll.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity opll is
  port(
    XIN     : in std_logic;
    XOUT    : out std_logic;
    XENA    : in std_logic;
    D       : in std_logic_vector(7 downto 0);
    A       : in std_logic;
    CS_n    : in std_logic;
    WE_n    : in std_logic;
    IC_n    : in std_logic;
    MO      : out std_logic_vector(9 downto 0);
    RO      : out std_logic_vector(9 downto 0);
    BCMO	: out std_logic_vector(15 downto 0);
    BCRO 	: out std_logic_vector(15 downto 0); 
    SDO		: out std_logic
  );    
end opll;

architecture RTL of opll is

  signal reset : std_logic;
  
  signal opllptr : std_logic_vector(7 downto 0);
  signal oplldat : std_logic_vector(7 downto 0);
  signal opllwr  : std_logic;

  signal am  : AM_TYPE;
  signal pm  : PM_TYPE;
  signal wf  : WF_TYPE;
  signal tl  : DB_TYPE;
  signal fb  : FB_TYPE;
  signal ar  : AR_TYPE;
  signal dr  : DR_TYPE;
  signal sl  : SL_TYPE;
  signal rr  : RR_TYPE;
  signal ml  : ML_TYPE;
  signal fnum: FNUM_TYPE;
  signal blk : BLK_TYPE;
  signal rks : RKS_TYPE;
  signal key : std_logic;
  
  signal rhythm : std_logic;

  signal noise : std_logic;
  signal pgout : PGOUT_TYPE;
  
  signal egout : DB_TYPE; 
  
  signal opout : SIGNED_DB_TYPE;
  
  
  signal faddr : CH_TYPE;
  signal maddr : SLOT_TYPE;
  signal fdata, mdata : SIGNED_LI_TYPE;

  signal slot, slot2, slot5, slot8 : SLOT_TYPE;
  signal stage, stage2, stage5, stage8 : STAGE_TYPE;

begin

  XOUT <= XIN;
  reset <= not IC_n;

  process( XIN, reset )
  begin

    if reset ='1' then
      opllwr  <= '0';
      opllptr <= (others =>'0');
      -- D <= (others =>'Z');
    elsif XIN'event and XIN = '1' then
      if XENA = '1' then
        if CS_n = '0' and WE_n = '0' and A ='0' then
          opllptr <= D(7 downto 0);
          opllwr  <= '0';
        elsif CS_n = '0' and WE_n = '0' and A = '1' then
          oplldat <= D;
          opllwr  <= '1';
      -- elsif CS_n ='0' and WE_n ='1' and A = '0' then
      --   D <= "11111111";
      --   opllwr <= '0';
      -- else
      --   D <= (others =>'Z');
      --   opllwr <= '0';
        end if;    
      end if; -- XENA
    end if;
  end process;
  
  S0: SlotCounter generic map (0) port map(XIN,reset,XENA,slot,stage);
  S2: SlotCounter generic map (2) port map(XIN,reset,XENA,slot2,stage2);
  S5: SlotCounter generic map (5) port map(XIN,reset,XENA,slot5,stage5);
  S8: SlotCounter generic map (8) port map(XIN,reset,XENA,slot8,stage8);
  
  -- no delay
  CT: Controller port map (
    XIN,reset,XENA, slot, stage, opllwr,opllptr,oplldat,
    am,pm,wf,ml,tl,fb,ar,dr,sl,rr,blk,fnum,rks,key,rhythm);
                       
  -- 2 stages delay                     
  EG: EnvelopeGenerator port map (
    XIN,reset,XENA, 
    slot2, stage2, rhythm, 
    am, tl, ar, dr, sl, rr, rks, key, 
    egout
  );

  PG: PhaseGenerator port map (
    XIN,reset,XENA,  
    slot2, stage2, rhythm,
    pm, ml, blk, fnum, key, 
    noise, pgout
  );
  
  -- 5 stages delay
  OP: Operator port map ( 
    XIN,reset,XENA, 
    slot5, stage5, rhythm, 
    wf, fb, noise, pgout, egout, faddr, fdata, opout
  );
  
  -- 8 stages delay
  OG: OutputGenerator port map (
    XIN, reset, XENA, slot8, stage8, rhythm, 
    opout, faddr, fdata, maddr, mdata
  );
  
  -- independent from delay
  TM: TemporalMixer port map (
    XIN, reset, XENA, 
    slot, stage, rhythm, 
    maddr, mdata, 
    MO, RO, BCMO, BCRO, SDO
  );

  
end RTL;

