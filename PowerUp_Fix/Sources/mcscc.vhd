
----------------------------------------------------------------

----------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity mcscc is
  port(
	mCLC		: OUT std_logic;
    pSltClk     : IN std_logic;
    pSltRst1_n   : IN std_logic;
    pSltSltsls_n : IN std_logic;
    pSltIorq_n  : IN std_logic;
    pSltRd_n    : IN std_logic;
    pSltWr_n    : IN std_logic;
    pSltAdr     : IN std_logic_vector(15 downto 0);
    pSltDat     : INOUT std_logic_vector(7 downto 0);
    pSltBdir_n  : OUT std_logic;

    pSltCs1     : IN std_logic;
    pSltCs2     : IN std_logic;
    pSltCs12    : IN std_logic;
    pSltRfsh_n  : IN std_logic;
    pSltWait_n  : OUT std_logic;
    pSltInt_n   : IN std_logic;
    pSltM1_n    : IN std_logic;
    pSltMerq_n  : IN std_logic;

    pSltClk2    : IN std_logic;
    pSltRsv5    : IN std_logic;
    pSltRsv16   : IN std_logic;

 --   pSltSndL    : OUT std_logic;
 --   pSltSndR    : OUT std_logic;
 --   pSltSound   : OUT std_logic;
    
-- FLASH ROM interface
	pFlAdr		: OUT std_logic_vector(22 downto 0);
	pFlDat		: INOUT std_logic_vector(7 downto 0);
	pFlDatH		: IN std_logic_vector(7 downto 0);
	pFlCS_n		: OUT std_logic;
	pFlOE_n		: OUT std_logic;
	pFlW_n		: OUT std_logic;
	pFlBYTE_n	: OUT std_logic;
	pFlRP_n		: OUT std_logic;
	pFlRB_b		: IN std_logic;
	pFlVpp		: OUT std_logic;

-- RAM chip ( Flash bus + rsc )
	pRAMCS_n	: OUT std_logic;


-- First start after power on detected
--	iFsts		: INOUT std_logic;
--	iFsts		: IN std_logic

-- CF card interface

    pIDEAdr		: OUT std_logic_vector(2 downto 0);
    pIDEDat		: INOUT std_logic_vector(15 downto 0);
	pIDECS1_n	: OUT std_logic;
	pIDECS3_n	: OUT std_logic;
	pIDERD_n	: OUT std_logic;
	pIDEWR_n	: OUT std_logic;
	pPIN180		: OUT std_logic;
	pIDE_Rst_n	: OUT std_logic;
	
-- Mapper port register read enable	
	MAPpEn		: IN std_logic;

--	wav			: OUT std_logic_vector(9 downto 0);
-- Key
    Key1_n		: IN std_logic;
	
-- PLL out
	CLK50		: IN std_logic;
--    c0			: OUT std_logic
-- DAC YAC516
	MCLK	: OUT std_logic;
	BICK	: OUT std_logic;
	LRCK	: OUT std_logic;
	SDATA	: OUT std_logic;
	CKS		: OUT std_logic;
	IC_n	: OUT std_logic;
--	PDIN_n
    SDOpo	: INOUT std_logic;
--  EEPROM
    EECS	: OUT std_logic;
    EECK	: OUT std_logic;
    EEDI	: OUT std_logic;
    EEDO	: in std_logic

);
end mcscc;

architecture RTL of mcscc is


    component scc_wave
    port(
      pSltClk_n : IN std_logic;
      pSltRst_n : IN std_logic;
      pSltAdr   : IN std_logic_vector(7 downto 0);
      pSltDat   : INOUT std_logic_vector(7 downto 0);
      SccAmp    : OUT std_logic_vector(10 downto 0);

      SccRegWe  : IN std_logic;
      SccModWe  : IN std_logic;
      SccWavCe  : IN std_logic;
      SccWavOe  : IN std_logic;
      SccWavWe  : IN std_logic;
      SccWavWx  : IN std_logic;
      SccWavAdr : IN std_logic_vector(4 downto 0);
      SccWavDat : IN std_logic_vector(7 downto 0);
      DOutEn_n		: IN std_logic;
      DOut		: INOUT std_logic_vector(7 downto 0)
    );
  end component;
  
  component opll
    port(
      xin  	: in std_logic;
      xout  : out std_logic;
      xena  : in std_logic;
      d 	: in std_logic_vector(7 downto 0);      
      a     : in std_logic;
      cs_n    : in std_logic;
      we_n    : in std_logic;
      ic_n    : in std_logic;
      mo     : out std_logic_vector(9 downto 0);
      ro     : out std_logic_vector(9 downto 0);
      BCMO		: out std_logic_vector(15 downto 0);
	  BCRO 		: out std_logic_vector(15 downto 0);
      SDO	 : out std_logic
      );
  end component;
  
  component MPLL1
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
  end component;
  component MPLL2
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
  end component;
  component mv16
    port(
	    sin16		: IN std_logic_vector(15 downto 0);
	    sout16		: OUT std_logic_vector(15 downto 0);
	    level		: IN std_logic_vector(2 downto 0)
    );  
  end component;
  
  component psg_wave
    port(
      pSltClk_n : IN std_logic;
      pSltRst_n : IN std_logic;
      PsgRegPtr : IN std_logic_vector(3 downto 0);
      pSltDat   : INOUT std_logic_vector(7 downto 0);
      PsgAmp    : OUT std_logic_vector(9 downto 0);
      PsgRegWe  : IN std_logic
    );
  end component;
  
  
  signal pSltClk_n   : std_logic;
  signal DevHit      : std_logic;
  signal Dec1FFE     : std_logic;
  signal DecSccA     : std_logic;
  signal DecSccB     : std_logic;

  signal SccBank0    : std_logic_vector(7 downto 0);
  signal SccBank1    : std_logic_vector(7 downto 0);
  signal SccBank2    : std_logic_vector(7 downto 0);
  signal SccBank3    : std_logic_vector(7 downto 0);
  signal SccModeA    : std_logic_vector(7 downto 0);
  signal SccModeB    : std_logic_vector(7 downto 0);

  signal SccRegWe    : std_logic;
  signal SccModWe    : std_logic;
  signal SccWavCe    : std_logic;
  signal SccWavOe    : std_logic;
  signal SccWavWe    : std_logic;
  signal SccWavWx    : std_logic;
  signal SccWavAdr   : std_logic_vector(4 downto 0);
  signal SccWavDat   : std_logic_vector(7 downto 0);

  signal SccAmp      : std_logic_vector(10 downto 0);

-- Multimode card register

  signal CardMDR     : std_logic_vector(7 downto 0);
  signal AddrM0      : std_logic_vector(7 downto 0);
  signal AddrM1      : std_logic_vector(7 downto 0);
  signal AddrM2		 : std_logic_vector(6 downto 0);
  signal AddrFR	     : std_logic_vector(6 downto 0);

  signal R1Mask	     : std_logic_vector(7 downto 0);
  signal R1Addr	     : std_logic_vector(7 downto 0);
  signal R1Reg     : std_logic_vector(7 downto 0);
  signal R1Mult      : std_logic_vector(7 downto 0);
  signal B1MaskR     : std_logic_vector(7 downto 0);
  signal B1AdrD      : std_logic_vector(7 downto 0);

  signal R2Mask	     : std_logic_vector(7 downto 0);
  signal R2Addr	     : std_logic_vector(7 downto 0);
  signal R2Reg     : std_logic_vector(7 downto 0);
  signal R2Mult      : std_logic_vector(7 downto 0);
  signal B2MaskR     : std_logic_vector(7 downto 0);
  signal B2AdrD      : std_logic_vector(7 downto 0);
 
  signal R3Mask	     : std_logic_vector(7 downto 0);
  signal R3Addr	     : std_logic_vector(7 downto 0);
  signal R3Reg     : std_logic_vector(7 downto 0);
  signal R3Mult      : std_logic_vector(7 downto 0);
  signal B3MaskR     : std_logic_vector(7 downto 0);
  signal B3AdrD      : std_logic_vector(7 downto 0);
  
  signal R4Mask	     : std_logic_vector(7 downto 0);
  signal R4Addr	     : std_logic_vector(7 downto 0);
  signal R4Reg     : std_logic_vector(7 downto 0);
  signal R4Mult      : std_logic_vector(7 downto 0);
  signal B4MaskR     : std_logic_vector(7 downto 0);
  signal B4AdrD      : std_logic_vector(7 downto 0);
 
  signal aAddrFR     : std_logic_vector(6 downto 0);
  
  signal aR1Mask	     : std_logic_vector(7 downto 0);
  signal aR1Addr	     : std_logic_vector(7 downto 0);
  signal aR1Reg     : std_logic_vector(7 downto 0);
  signal aR1Mult      : std_logic_vector(7 downto 0);
  signal aB1MaskR     : std_logic_vector(7 downto 0);
  signal aB1AdrD      : std_logic_vector(7 downto 0);

  signal aR2Mask	     : std_logic_vector(7 downto 0);
  signal aR2Addr	     : std_logic_vector(7 downto 0);
  signal aR2Reg     : std_logic_vector(7 downto 0);
  signal aR2Mult      : std_logic_vector(7 downto 0);
  signal aB2MaskR     : std_logic_vector(7 downto 0);
  signal aB2AdrD      : std_logic_vector(7 downto 0);
 
  signal aR3Mask	     : std_logic_vector(7 downto 0);
  signal aR3Addr	     : std_logic_vector(7 downto 0);
  signal aR3Reg     : std_logic_vector(7 downto 0);
  signal aR3Mult      : std_logic_vector(7 downto 0);
  signal aB3MaskR     : std_logic_vector(7 downto 0);
  signal aB3AdrD      : std_logic_vector(7 downto 0);
  
  signal aR4Mask	     : std_logic_vector(7 downto 0);
  signal aR4Addr	     : std_logic_vector(7 downto 0);
  signal aR4Reg     : std_logic_vector(7 downto 0);
  signal aR4Mult      : std_logic_vector(7 downto 0);
  signal aB4MaskR     : std_logic_vector(7 downto 0);
  signal aB4AdrD      : std_logic_vector(7 downto 0);

 
  signal ConfFl		 : std_logic_vector(2 downto 0);
  
  signal DecMDR      : std_logic;
  signal DirFlW      : std_logic; 
  signal Maddr       : std_logic_vector(22 downto 0);
  signal MR1A		 : std_logic_vector(3 downto 0);
  signal MR2A		 : std_logic_vector(3 downto 0);
  signal MR3A		 : std_logic_vector(3 downto 0);
  signal MR4A		 : std_logic_vector(3 downto 0);
  signal pFlOE_nt    : std_logic;
  signal pFlCS_nt	 : std_logic;
  signal pRAMCS_nt	 : std_logic;
  signal RloadEn     : std_logic;
-- Expend Slot signals  
  signal aMconf      : std_logic_vector(7 downto 0);
  signal Mconf       : std_logic_vector(7 downto 0);
  signal NSReg		 : std_logic_vector(7 downto 0);
  signal aNSReg      : std_logic_vector(7 downto 0);
  signal ExpSltReg   : std_logic_vector(7 downto 0);
  signal ExpSltEna   : std_logic;
  
  signal DOutEn_n	: std_logic;
  signal DOut		: std_logic_vector(7 downto 0);
  signal Sltsl_C_n	: std_logic;
  signal Sltsl_D_n	: std_logic;
  signal Sltsl_M_n  : std_logic;
  signal Sltsl_F_n  : std_logic;
    
-- Timing
  signal LRD		: std_logic;
  signal LRD1		: std_logic;
  signal Rd_n		: std_logic;
  signal Wr_n		: std_logic;

-- IDE CF adapter
  signal cReg	       : std_logic_vector(7 downto 0);  
  signal IDEReg        : std_logic;
  signal IDEsOUT	   : std_logic_vector(7 downto 0);
  signal IDEsIN		   : std_logic_vector(7 downto 0);
  signal DecIDEconf    : std_logic;  
  signal CLC_n		   : std_logic;  
  signal RD_hT1	   	   : std_logic;
  signal RD_hT2	       : std_logic;
  signal WR_hT1    : std_logic;
  signal WR_hT2    : std_logic;  
  signal RDh1	   	   : std_logic;
  signal RDh2	       : std_logic;
  signal WRh1    : std_logic;
  signal WRh2    : std_logic;
  signal rdtn	       : std_logic;   
  signal IDEROMCs_n    : std_logic;
  signal IDEROMADDR    : std_logic_vector(16 downto 0);
  signal Rdh_n		: std_logic;
  signal Wrh_n		: std_logic;
  
-- MAPPER RAM

  signal MAP_FF		   : std_logic_vector(6 downto 0);
  signal MAP_FE		   : std_logic_vector(6 downto 0);
  signal MAP_FD		   : std_logic_vector(6 downto 0);
  signal MAP_FC		   : std_logic_vector(6 downto 0);
  signal Port3C        : std_logic_vector(7 downto 0);  
  signal AddrMAP 	   : std_logic_vector(6 downto 0); 
  signal DEC_PFC	   : std_logic;
  signal DEC_PFD	   : std_logic;
  signal DEC_PFE	   : std_logic;
  signal DEC_PFF	   : std_logic;
  signal DEC_P3C	   : std_logic; 
  signal DEC_P		   : std_logic; 
  signal MAP_S		   : std_logic;

-- FM Pack
  signal clk21m  : std_logic;
  signal xena    : std_logic;
  signal pYM2413_Cs_n     : std_logic;
  signal pYM2413_We_n     : std_logic;
  signal pYM2413_A		: std_logic;
  signal mo     : std_logic_vector(9 downto 0);
  signal ro     : std_logic_vector(9 downto 0);
  signal mix	: std_logic_vector(10 downto 0);
  signal R7FF6b0 : std_logic;
  signal R7FF6b4 : std_logic;
  signal CsOPLL : std_logic;
  signal CsRAM8k : std_logic;
  signal R7FF7	:std_logic_vector(1 downto 0);
  signal R5FFE	:std_logic_vector(7 downto 0);
  signal R5FFF	:std_logic_vector(7 downto 0);  
  
  
--  PLL
  signal areset		: STD_LOGIC;
  signal c0				: STD_LOGIC;
  signal clk42m 	: std_logic;
  
-- Audio DAC YAC516
  signal ADACDiv	: std_logic_vector(7 downto 0);
  signal ABDAC		: std_logic_vector(15 downto 0);
  signal L_AOUT		: std_logic_vector(15 downto 0);
  signal R_AOUT		: std_logic_vector(15 downto 0);
  signal T1			: std_logic;
  signal LRCKe		: std_logic;
  signal ACL		: std_logic_vector(19 downto 0);
  signal ACR		: std_logic_vector(19 downto 0);
  signal SCL		: std_logic_vector(11 downto 0);
  signal SCR		: std_logic_vector(11 downto 0);
  signal DCL		: std_logic_vector(11 downto 0);
  signal DCR		: std_logic_vector(11 downto 0);
  signal ACMO		: std_logic_vector(15 downto 0);
  signal ACRO 		: std_logic_vector(15 downto 0);
  signal BCMO		: std_logic_vector(15 downto 0);
  signal BCRO 		: std_logic_vector(15 downto 0);
  signal SDO		:std_logic; 
  signal SDOp		:std_logic; 
  signal SDOc  		:std_logic_vector(15 downto 0);    
  signal FDIV	:std_logic_vector(7 downto 0);
  signal SDAC		:std_logic;
  signal pSltClk_nt :std_logic; 
-- Audiomix
  signal MFL		:std_logic_vector(15 downto 0); 
  signal MFR		:std_logic_vector(15 downto 0);   
  signal MSL		:std_logic_vector(15 downto 0);   
  signal MSR		:std_logic_vector(15 downto 0);
  signal MACL		:std_logic_vector(15 downto 0);   
  signal MACR		:std_logic_vector(15 downto 0);      
  signal LVF		:std_logic_vector(2 downto 0);
  signal LVS		:std_logic_vector(2 downto 0);
  signal LVL	    :std_logic_vector(7 downto 0) := "00011011" ;
  signal LVL1	    :std_logic_vector(7 downto 0) := "00011011" ;  
  signal rsta0    	:std_logic;
  signal rsta1    	:std_logic;
  signal LVP		:std_logic_vector(2 downto 0);
  signal LVB		:std_logic_vector(2 downto 0);
  signal SCP		:std_logic_vector(9 downto 0); 
  signal SCB		:std_logic_vector(9 downto 0);  
  signal ACP		:std_logic_vector(18 downto 0); 
  signal ACB		:std_logic_vector(15 downto 0); 
  signal resP		:std_logic;  
  signal resB		:std_logic;  
  signal MACP		:std_logic_vector(15 downto 0);
  signal MACB		:std_logic_vector(15 downto 0);
  signal MPL		:std_logic_vector(15 downto 0);    
  signal MBL		:std_logic_vector(15 downto 0);  
  signal MACB_f		:std_logic_vector(15 downto 0);
  signal MACB_i		:std_logic_vector(15 downto 0);    
  
-- Sltsel
  signal pSltSltsl_n :std_logic;
  signal SltslEn	: std_logic;
  signal pSltSltslt_n	: std_logic;
  signal sltt	: std_logic;
-- Not Standart
  signal NSC : std_logic;
  signal NSC_SCCP : std_logic;
-- EEPROM
  signal EECS1 : std_logic;
  signal EECK1 : std_logic;
  signal EEDI1 : std_logic;
-- PSG
  signal PsgRegPtr   : std_logic_vector(3 downto 0);
  signal PsgRegWe    : std_logic;
  signal KC    : std_logic;
  signal PsgAmp      : std_logic_vector(9 downto 0);

-- Code injector
  signal V_active : std_logic_vector(1 downto 0);
  signal V_hunt   : std_logic;
  signal aV_hunt  : std_logic;
  signal V_fr     : std_logic;
  signal V_stop   : std_logic;
  signal V_RA	  : std_logic_vector(15 downto 0);
  signal V_AR	  : std_logic_vector(13 downto 0);   

-- Reset Conditions
  signal pSltRst_n :std_logic := '0' ;
  signal RstEn 	  :std_logic := '0';
begin
  ----------------------------------------------------------------
  -- Slot Select Disable trigger key
  ----------------------------------------------------------------
  pSltSltsl_n <= pSltSltslt_n when SltslEn	= '1'
						      else '1';
  process(pSltRst_n, Key1_n)
  begin
    if (Key1_n = '1') then
      SltslEn	<= '1';
    elsif (pSltRst_n = '0') then
	  SltslEn   <= '0';
    end if;
  end process;


  ----------------------------------------------------------------
  -- Expand Slot Processing
  ----------------------------------------------------------------
  ExpSltEna <= '1' when Mconf(7) = '1'
	               else '0';
  Sltsl_C_n <= '0' when pSltSltsl_n = '0' and ExpSltEna = '0' and Mconf(0) = '1'
		  else '0' when pSltSltsl_n = '0' and Mconf(0) = '1' and ( 
						(pSltAdr(15 downto 14) = "00" and ExpSltReg(1 downto 0) = "00") or
						(pSltAdr(15 downto 14) = "01" and ExpSltReg(3 downto 2) = "00") or
						(pSltAdr(15 downto 14) = "10" and ExpSltReg(5 downto 4) = "00") or
						(pSltAdr(15 downto 14) = "11" and ExpSltReg(7 downto 6) = "00") )
                   else '1';
  Sltsl_D_n <= '0' when pSltSltsl_n = '0' and ExpSltEna = '0' and Mconf(1 downto 0) = "10"
		  else '0' when	pSltSltsl_n = '0' and Mconf(1) = '1' and  ExpSltEna = '1' and (
						(pSltAdr(15 downto 14) = "00" and ExpSltReg(1 downto 0) = "01") or
						(pSltAdr(15 downto 14) = "01" and ExpSltReg(3 downto 2) = "01") or
						(pSltAdr(15 downto 14) = "10" and ExpSltReg(5 downto 4) = "01") or
						(pSltAdr(15 downto 14) = "11" and ExpSltReg(7 downto 6) = "01") )
                   else '1';
  Sltsl_M_n <= '0' when pSltSltsl_n = '0' and ExpSltEna = '0' and Mconf(2 downto 0) = "100"
		  else '0' when	pSltSltsl_n = '0' and Mconf(2) = '1' and  ExpSltEna = '1' and (
						(pSltAdr(15 downto 14) = "00" and ExpSltReg(1 downto 0) = "10") or
						(pSltAdr(15 downto 14) = "01" and ExpSltReg(3 downto 2) = "10") or
						(pSltAdr(15 downto 14) = "10" and ExpSltReg(5 downto 4) = "10") or
						(pSltAdr(15 downto 14) = "11" and ExpSltReg(7 downto 6) = "10") )
                   else '1';
  Sltsl_F_n <= '0' when pSltSltsl_n = '0' and ExpSltEna = '0' and Mconf(3 downto 0) = "1000"
		  else '0' when	pSltSltsl_n = '0' and Mconf(3) = '1' and  ExpSltEna = '1' and (
						(pSltAdr(15 downto 14) = "00" and ExpSltReg(1 downto 0) = "11") or
						(pSltAdr(15 downto 14) = "01" and ExpSltReg(3 downto 2) = "11") or
						(pSltAdr(15 downto 14) = "10" and ExpSltReg(5 downto 4) = "11") or
						(pSltAdr(15 downto 14) = "11" and ExpSltReg(7 downto 6) = "11") )
                   else '1';
  
  process(pSltRst_n, pSltWr_n)
  begin
    if (pSltRst_n = '0') then
      ExpSltReg		<= "00000000";
    elsif (pSltWr_n'event and pSltWr_n = '0') then
	  if (pSltSltsl_n = '0' and pSltAdr(15 downto 0) = "1111111111111111" and
          ExpSltEna = '1') then
        ExpSltReg <= pSltDat;
      end if;
      end if;
  end process;
  ----------------------------------------------------------------
  -- Read Data 
  ----------------------------------------------------------------
  
  DOutEn_n	<= '0' 	when pFlOE_nt = '0'  -- Cartridge read
						 or (pSltSltsl_n = '0' and pSltAdr(15 downto 0) = "1111111111111111" and
							ExpSltEna = '1' and pSltRd_n = '0') -- Expand Slot Register read
						 or (DecMDR = '1' and CardMDR(0) = '0' and pSltRd_n = '0') -- MDR registers read				 
						 or (IDEROMCs_n = '0' and pSltRd_n = '0') -- IDE ROM read
						 or (IDEReg = '1' and pSltRd_n = '0') -- IDE Register read
						 or ((DEC_PFC ='1' or  DEC_PFD ='1' or DEC_PFE ='1' or DEC_PFF ='1' or DEC_P3C ='1')
						     and pSltRd_n = '0') -- MMM page register read
						 or (pSltAdr(7 downto 2) = "111111" and pSltIorq_n = '0' and Port3C(5) = '0'
						     and pSltRd_n = '0' and MAPpEn = '1' and Mconf(6) = '1') -- MAP reister read (port)
						 or (Sltsl_F_n = '0' and pSltRd_n = '0' and pSltAdr(15 downto 1) = "011111111111011")-- FM page register
						 
					else '1';
  -- Expand Slot Register Read 
  DOut		<=     	not ExpSltReg when pSltSltsl_n = '0' and pSltAdr(15 downto 0) = "1111111111111111" and
  							           ExpSltEna = '1' and pSltRd_n = '0'
  -- IDE Register 
 					else IDEsIN      		 when IDEReg = '1' and pSltAdr(9) = '0' and pSltAdr(0) = '1'
											      and pSltRd_n = '0'
					else pIDEDat(7 downto 0) when IDEReg = '1' and (pSltAdr(0) = '0' or pSltAdr(9) = '1') 
											      and pSltRd_n = '0'										      						      
  -- IDE ROM read (the same pFlDat)				  
  -- FM Pack Slot register read
                    else "000"&R7FF6b4&"000"&R7FF6b0 when Sltsl_F_n = '0' and pSltAdr(15 downto 0) = "0111111111110110"
                    else "000000"&R7FF7 when Sltsl_F_n = '0' and pSltAdr(15 downto 0) = "0111111111110111"
                    else R5FFE when Sltsl_F_n = '0' and pSltAdr(15 downto 0) = "0101111111111110" and CsRAM8k = '1'
  -- error find Wouter Vermaelen
  ---               else R5FFF when Sltsl_F_n = '0' and pSltAdr(15 downto 0) = "0101111111111110" and CsRAM8k = '1'
                    else R5FFF when Sltsl_F_n = '0' and pSltAdr(15 downto 0) = "0101111111111111" and CsRAM8k = '1'
                    
  -- FM Pack ROM read (the same pFlDat)		
  
  -- MAPPER register read
	        else "Z" & MAP_FC(6 downto 0) when ((pSltAdr(7 downto 0) = "11111100" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FC
                                                or DEC_PFC ='1') and pSltRd_n = '0' and MAP_S = '1'
 	        else "ZZ" & MAP_FC(5 downto 0) when ((pSltAdr(7 downto 0) = "11111100" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FC
                                                or DEC_PFC ='1') and pSltRd_n = '0' and MAP_S = '0'
            else "Z" & MAP_FD(6 downto 0) when ((pSltAdr(7 downto 0) = "11111101" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FD
                                                or DEC_PFD ='1') and pSltRd_n = '0' and MAP_S = '1'
            else "ZZ" & MAP_FD(5 downto 0) when ((pSltAdr(7 downto 0) = "11111101" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FD
                                                or DEC_PFD ='1') and pSltRd_n = '0' and MAP_S = '0'
            else "Z" & MAP_FE(6 downto 0) when ((pSltAdr(7 downto 0) = "11111110" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FE
                                                or DEC_PFE ='1') and pSltRd_n = '0' and MAP_S = '1'
            else "ZZ" & MAP_FE(5 downto 0) when ((pSltAdr(7 downto 0) = "11111110" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FE
                                                or DEC_PFE ='1') and pSltRd_n = '0' and MAP_S = '0'                                                                                                                                              
            else "Z" & MAP_FF(6 downto 0) when ((pSltAdr(7 downto 0) = "11111111" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FF
                                                or DEC_PFF ='1') and pSltRd_n = '0' and MAP_S = '1'
            else "ZZ" & MAP_FF(5 downto 0) when ((pSltAdr(7 downto 0) = "11111111" and pSltIorq_n = '0' and Port3C(5) = '0') -- MAP reg FF
                                                or DEC_PFF ='1') and pSltRd_n = '0' and MAP_S = '0'
            else Port3C when DEC_P3C ='1' and pSltRd_n = '0'    
            
--			MDRregister				
			else CardMDR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000000" 
			else AddrM0  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000001"
			else AddrM1  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000010"
			else "0"&AddrM2  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000011" 			
--						 when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000100"
			else "0"&aAddrFR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000101"
			
			else aR1Mask when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000110"
			else aR1Addr when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000111"
			else aR1Reg  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001000"
			else aR1Mult when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001001"
			else aB1MaskR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001010"
			else aB1AdrD when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001011" 
			
			else aR2Mask when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001100"
			else aR2Addr when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001101"
			else aR2Reg  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001110"
			else aR2Mult when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "001111"
			else aB2MaskR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010000"
			else aB2AdrD when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010001"
			
			else aR3Mask when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010010"
			else aR3Addr when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010011"
			else aR3Reg  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010100"
			else aR3Mult when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010101"
			else aB3MaskR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010110"
			else aB3AdrD when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "010111"
			
			else aR4Mask when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011000"
			else aR4Addr when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011001"
			else aR4Reg  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011010"
			else aR4Mult when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011011"
			else aB4MaskR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011100"
			else aB4AdrD when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011101"
			
			else aMconf when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011110"
			else CardMDR when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "011111"
			else "00000"&ConfFl when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100000"
			else aNSReg  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100001"
			else LVL  when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100010"
			else "0000" & EECS1 & EECK1 & EEDI1 & EEDO 
			          when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100011"
			else LVL1 when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100100"
			else V_AR(7 downto 0) when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100101"
			else pSltAdr(15 downto 14) & V_AR(13 downto 8) when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100110"
			else "000000" & V_fr & aV_hunt when DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "100111"
--	        
            else V_RA(7 downto 0) when V_active = "10"
            else V_RA(15 downto 8) when V_active = "01"  				   					
			else pFlDat ;
  



  ----------------------------------------------------------------
  -- Dummy pin
  ----------------------------------------------------------------
  --pSltRsv5  <= '1';
  --pSltRsv16 <= '1';

  pSltClk_n <= not pSltClk;

  pSltBdir_n <= '0' when pSltSltsl_n = '0' and pSltRd_n = '0' 
           else '0' when pSltRd_n = '0' and pSltAdr(7 downto 2) = "111111" and pSltIorq_n = '0' 
                         and Port3C(5) = '0' and Mconf(6) = '1' and MAPpEn = '1'    
		   else '1';

  pFlBYTE_n	<= ConfFl(2);
  pFlRP_n <= ConfFl(1);
  pFlVpp <= ConfFl(0);



  ----------------------------------------------------------------
  -- Slot access control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n, pSltIorq_n, pSltSltsl_n, pSltRd_n, pSltWr_n)

    variable DevAcs0 : std_logic;
    variable DevAcs1 : std_logic;

  begin

    if ((pSltIorq_n = '0' or pSltSltsl_n = '0') and (pSltRd_n = '0' or pSltWr_n = '0')) then
      DevAcs0 := '1';
    else
      DevAcs0 := '0';
    end if;

    if (DevAcs0 = '1' and DevAcs1 = '0') then
      DevHit <= '1';
    else
      DevHit <= '0';
    end if;

    if (pSltRst_n = '0') then
      DevAcs1 := '0';
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      DevAcs1 := DevAcs0;
    end if;

  end process;
   
  ---
  --- Cartrige Slot
  ---
  
  ----------------------------------------------------------------
  -- Decode Cartrige
  ----------------------------------------------------------------

  Dec1FFE <= '1' when pSltAdr(12 downto 1) = "111111111111" 
                      and CardMDR(4) = '1' 
                 else '0';
  DecSccA <= '1' when pSltAdr(15 downto 11) = "10011" and SccModeB(5) = '0' and SccBank2(5 downto 0) = "111111"
                      and CardMDR(4) = '1'
                 else '0';
  DecSccB <= '1' when pSltAdr(15 downto 11) = "10111" and SccModeB(5) = '1' and SccBank3(7) = '1'
                      and CardMDR(4) = '1'
                 else '0';
  
  DecMDR <= '1'  when Sltsl_C_n = '0' and pSltAdr(13 downto 6) = "00111110" and
                      CardMDR(7) = '0' and pSltAdr (15 downto 14) = CardMDR (6 downto 5)
				 else '0';
  RloadEn <= '1' when CardMDR(3) = '0' 
                      or (CardMDR(2) = '0' and pSltAdr(15 downto 0) = "0000000000000000" and pSltM1_n = '0'
                          and pSltRd_n = '0' and pSltClk_n = '0')
                      or (CardMDR(2) = '1' and pSltAdr(15 downto 4) = "010000000000" and pSltRd_n = '0'
                          and pSltClk_n = '0' and Sltsl_C_n = '0')
                 else '0';
  -- iFsts	 <= CardMDR(0) when CardMDR(1)  = '1' and Sltsl_C_n = '1' else ('Z');

  

  ----------------------------------------------------------------
  -- Conf register 
  ----------------------------------------------------------------
  
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then
 --     R1Reg <= aR1Reg; R2Reg <= aR2Reg; R3Reg <= aR3Reg; R4Reg <= aR4Reg;
       
         CardMDR   <= "00110000"; -- 7b - disable is conf.regs; 
							   -- 6,5b - addr r.conf=0F80/4F80/8F80/CF80
                               -- 4b - enable SCC, 
                               -- 3b - delayed reconfiguration (bank registers only)
                               -- 2b - select activate bank configurations 0=of start/jmp0/rst0 1= read(400Xh)
                               -- 1b - Shadow BIOS ( to RAM )
                               -- 0b - Disable read direct card vector port and card configuration register (4F80..)  
         ConfFl    <= "010";    
         AddrM0	<= "00000000";
         AddrM1 <= "00000000";
         AddrM2 <= "0000000";
         AddrFR    <= "0000000";  -- shift  addr Flash Rom x 64κα
         aAddrFR    <= "0000000";
         R1Mult    <= "10000101"; -- 7b - enable page register bank 1
                               -- 6b - 
							   -- 5b - RAM (select RAM or atlernative ROM...)
							   -- 4b - enable write to bank
							   -- 3b - disable bank ( read and write )
							   -- 2b,1b,0b - bank size
							   -- 111 - 64kbyte
							   -- 110 - 32 
                               -- 101 - 16
                               -- 100 - 8
                               -- 011 - 4
                               -- other - disable bank
         aR1Mult    <= "10000101";
         R1Mask    <= "11111000"; -- 0000h-07FFh + |
	     aR1Mask    <= "11111000"; 
         R1Addr    <= "01010000"; -- 5000h         | = 5000h-57FFh
         aR1Addr    <= "01010000";
         R1Reg     <= "00000000"; -- Page 0 (Relative)
         aR1Reg     <= "00000000";
         B1MaskR   <= "00000011"; -- Size "Cartrige" 4 Page ( 4 Page x 16 Kbyte )
	     aB1MaskR   <= "00000011";
         B1AdrD    <= "01000000"; -- Bank Addr 4000h
         aB1AdrD    <= "01000000";
      
         R2Mult    <= "00000000"; -- Disable B2, B3, B4
         aR2Mult    <= "00000000";
         R3Mult    <= "00000000";
         aR3Mult    <= "00000000";
         R4Mult    <= "00000000";
         aR4Mult    <= "00000000";
         
 --        REXPSLT	<= "00000000";  -- Extend Slot Register Reset to 0
         aMconf  	<= "11111111";  -- Reset slot configurations
         Mconf  	<= "11111111"; 
									-- 7 bit - enable Expand Slot
									-- 6 bit - enable Read mapper port ( FC FD FE FF )
									-- 5 bit - enable YM2413 (FM Pack syntesator)
									-- 4 bit - enable control MMM port (3C)
									-- 3 bit - enable x3 Expand slot FM Pack BIOS ROM
									-- 2 bit - enable x2 Expand slot MMM RAM mapper
									-- 1 bit - enable x1 Expand slot CF card disk interface
									-- 0 bit - enable x0 Expand slot SCC Cartridge
		 MAP_S <= '0' ; -- MAP size 1 MB
		 NSReg <= "00000000" ; -- NonStandartRegister
		 aNSReg <= "00000000" ;
--		 LVL <= "00011011"; 
		 EECS1 <= '0'; EECK1 <= '0'; EEDI1 <= '0';
		 V_hunt <= '0';
		 aV_hunt <= '0';
		 V_fr <= '0';
       
    elsif (pSltClk_n'event and pSltClk_n = '1') then

          -- Mapped I/O port access on 8F80 ( 0F80, 4F80, CF80 ) Cart mode resister write
      if (DecMDR = '1' and pSltWr_n = '0' ) then 
        if (pSltAdr(5 downto 0) = "000000") then CardMDR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000001") then AddrM0  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000010") then AddrM1  <= pSltDat ; end if;         
        if (pSltAdr(5 downto 0) = "000011") then AddrM2  <= pSltDat(6 downto 0) ; end if;
--      if (pSltAdr(5 downto 0) = "000100") then DatM0   <= pSltDat ; end if; -- transit
        if (pSltAdr(5 downto 0) = "000101") then aAddrFR  <= pSltDat(6 downto 0) ; end if;
----------------------------------------------------------------------------------------
        if (pSltAdr(5 downto 0) = "000110") then aR1Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "000111") then aR1Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001000") then aR1Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001001") then aR1Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001010") then aB1MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001011") then aB1AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001100") then aR2Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001101") then aR2Addr  <= pSltDat ; end if; 
        if (pSltAdr(5 downto 0) = "001110") then aR2Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "001111") then aR2Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010000") then aB2MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010001") then aB2AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010010") then aR3Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010011") then aR3Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010100") then aR3Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010101") then aR3Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010110") then aB3MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "010111") then aB3AdrD  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011000") then aR4Mask  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011001") then aR4Addr  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011010") then aR4Reg   <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011011") then aR4Mult  <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011100") then aB4MaskR <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011101") then aB4AdrD  <= pSltDat ; end if;
 
        if (pSltAdr(5 downto 0) = "011110" and (pSltDat(7) = '1' or pSltDat(3 downto 0) /= "1111" )) then aMconf    <= pSltDat ; end if;
        if (pSltAdr(5 downto 0) = "011111") then CardMDR <= pSltDat ; end if;
 ---------------------------------------------------------------------------------------       
        if (pSltAdr(5 downto 0) = "100000") then ConfFl  <= pSltDat(2 downto 0); end if;
        if (pSltAdr(5 downto 0) = "100001") then aNSReg  <= pSltDat(7 downto 0); end if;
        if (pSltAdr(5 downto 0) = "100010") then LVL     <= pSltDat(7 downto 0); end if;
        if (pSltAdr(5 downto 0) = "100011") then EECS1 <= pSltDat(3);
                                                 EECK1 <= pSltDat(2);
                                                 EEDI1 <= pSltDat(1);  end if;
        if (pSltAdr(5 downto 0) = "100100") then LVL1    <= pSltDat(7 downto 0); end if;                                                 
        if (pSltAdr(5 downto 0) = "100101") then V_AR(7 downto 0) <= pSltDat ; end if; 
        if (pSltAdr(5 downto 0) = "100110") then V_AR(13 downto 8) <= pSltDat(5 downto 0); end if;    
        if (pSltAdr(5 downto 0) = "100111") then aV_hunt <= pSltDat(0); V_fr <= pSltDat(1); end if;             
      end if;
 -- V_hunt off
      if V_active = "11" then
        aV_hunt <= '0'; V_hunt <='0';
     end if;
 -- delayed reconfiguration
     if RloadEn = '1' then

      AddrFR  <= aAddrFR;
      R1Mask  <= aR1Mask;
      R1Addr  <= aR1Addr;
      R1Reg   <= aR1Reg;
      R1Mult  <= aR1Mult;
      B1MaskR <= aB1MaskR;
      B1AdrD  <= aB1AdrD;

      R2Mask  <= aR2Mask;
      R2Addr  <= aR2Addr;
      R2Reg   <= aR2Reg;
      R2Mult  <= aR2Mult;
      B2MaskR <= aB2MaskR;
      B2AdrD  <= aB2AdrD;

      R3Mask  <= aR3Mask;
      R3Addr  <= aR3Addr;
      R3Reg   <= aR3Reg;
      R3Mult  <= aR3Mult;
      B3MaskR <= aB3MaskR;
      B3AdrD  <= aB3AdrD;
     
      R4Mask  <= aR4Mask;
      R4Addr  <= aR4Addr;
      R4Reg   <= aR4Reg;
      R4Mult  <= aR4Mult;
      B4MaskR <= aB4MaskR;
      B4AdrD  <= aB4AdrD;   
      
      Mconf   <= aMconf; 
      NSReg   <= aNSReg;  
      V_hunt <= aV_hunt;
      end if;
    
              -- Mapped I/O port access on R1 Bank resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and R1Mult(7) = '1' and DecMDR = '0'
			                and ( pSltAdr(15) = R1Addr(7) or R1Mask(7) = '0' )
							and ( pSltAdr(14) = R1Addr(6) or R1Mask(6) = '0' )
							and ( pSltAdr(13) = R1Addr(5) or R1Mask(5) = '0' )
							and ( pSltAdr(12) = R1Addr(4) or R1Mask(4) = '0' )
							and ( pSltAdr(11) = R1Addr(3) or R1Mask(3) = '0' )
							and ( pSltAdr(10) = R1Addr(2) or R1Mask(2) = '0' )
							and ( pSltAdr(9)  = R1Addr(1) or R1Mask(1) = '0' )
							and ( pSltAdr(8)  = R1Addr(0) or R1Mask(0) = '0' )
							-- SCC+ options
							and ( NSC_SCCP = '0' or (SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0'
							                         and SccModeB(0) = '0'))
															       )
      then
        R1Reg <= pSltDat; aR1Reg <= pSltDat;
      end if;
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and R2Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R2Addr(7) or R2Mask(7) = '0' )
							and ( pSltAdr(14) = R2Addr(6) or R2Mask(6) = '0' )
							and ( pSltAdr(13) = R2Addr(5) or R2Mask(5) = '0' )
							and ( pSltAdr(12) = R2Addr(4) or R2Mask(4) = '0' )
							and ( pSltAdr(11) = R2Addr(3) or R2Mask(3) = '0' )
							and ( pSltAdr(10) = R2Addr(2) or R2Mask(2) = '0' )
							and ( pSltAdr(9)  = R2Addr(1) or R2Mask(1) = '0' )
							and ( pSltAdr(8)  = R2Addr(0) or R2Mask(0) = '0' )
							-- SCC+ options
							and ( NSC_SCCP = '0' or (SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0'
							                         and SccModeB(1) = '0'))
															       )
      then
        R2Reg <= pSltDat; aR2Reg <= pSltDat;
      end if;
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and R3Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R3Addr(7) or R3Mask(7) = '0' )
							and ( pSltAdr(14) = R3Addr(6) or R3Mask(6) = '0' )
							and ( pSltAdr(13) = R3Addr(5) or R3Mask(5) = '0' )
							and ( pSltAdr(12) = R3Addr(4) or R3Mask(4) = '0' )
							and ( pSltAdr(11) = R3Addr(3) or R3Mask(3) = '0' )
							and ( pSltAdr(10) = R3Addr(2) or R3Mask(2) = '0' )
							and ( pSltAdr(9)  = R3Addr(1) or R3Mask(1) = '0' )
							and ( pSltAdr(8)  = R3Addr(0) or R3Mask(0) = '0' )
							-- SCC+ options
							and ( NSC_SCCP = '0' or (SccModeB(4) = '0'
							                         and (SccModeB(2) = '0' or SccModeB(5) = '0')) )
															       )
      then
        R3Reg <= pSltDat; aR3Reg <= pSltDat;
      end if;
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and R4Mult(7) = '1' and DecMDR = '0' 
							and ( pSltAdr(15) = R4Addr(7) or R4Mask(7) = '0' )
							and ( pSltAdr(14) = R4Addr(6) or R4Mask(6) = '0' )
							and ( pSltAdr(13) = R4Addr(5) or R4Mask(5) = '0' )
							and ( pSltAdr(12) = R4Addr(4) or R4Mask(4) = '0' )
							and ( pSltAdr(11) = R4Addr(3) or R4Mask(3) = '0' )
							and ( pSltAdr(10) = R4Addr(2) or R4Mask(2) = '0' )
							and ( pSltAdr(9)  = R4Addr(1) or R4Mask(1) = '0' )
							and ( pSltAdr(8)  = R4Addr(0) or R4Mask(0) = '0' )
							-- SCC+ options
							and ( NSC_SCCP = '0' or (SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0'))
															       )
      then
        R4Reg <= pSltDat; aR4Reg <= pSltDat;
      end if;
       
    end if;

  end process;
  ----------------------------------------------------------------
  -- Not standart configurations 
  ----------------------------------------------------------------  
  NSC <= '1' when R4Mult(2 downto 0) = "001"
    else '0';
  NSC_SCCP <= '1' when NSC = '1' and  B4MaskR = "00000001"
         else '0';
  ----------------------------------------------------------------
  -- Flash ROM/RAM interface 
  ---------------------------------------------------------------- 
  -- Flash/RAM DataWrite
  pFlDat <= pSltDat when (Sltsl_C_n = '0' or SltSl_M_n = '0' or Sltsl_F_n = '0')
  --                     and pSltRd_n = '1' and RDh1 = '0'
                         and pSltRd_n = '1' and Rd_n = '1'
      else (others => 'Z');

  -- Flash -ChipSelect
  pFlCS_n <= pFlCS_nt;
  pFlCS_nt <= '0' when Sltsl_C_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")   	-- DatM0  
					 		             or (MR1A(3) = '0' and R1Mult(5) = '0')
					 		             or (MR2A(3) = '0' and R2Mult(5) = '0')
					 		             or (MR3A(3) = '0' and R3Mult(5) = '0')
					 		             or (MR4A(3) = '0' and R4Mult(5) = '0') --uv )
					 		             or (V_active /= "00" and V_fr = '0')  ) -- H vector in ROM
		 else '0' when IDEROMCs_n = '0' and CardMDR(1) = '0' -- IDE ROM read
		 else '0' when Sltsl_F_n = '0'  and CardMDR(1) = '0' and pSltAdr(15 downto 14) = "01" and CsRAM8k = '0'  -- FM Pack ROM read
		 else '1';

  -- RAM -ChipSelect
  pRAMCS_n <= pRAMCS_nt;
  pRAMCS_nt <= '0' when SltSl_M_n = '0' and DEC_P3C = '0' and DEC_PFC = '0' and DEC_PFD = '0'
					   and DEC_PFE = '0' and DEC_PFF = '0'
	     else '0' when pFlCS_nt = '1' and Sltsl_C_n = '0' and 
	                   (  (MR1A(3) = '0' and R1Mult(5) = '1') 
					   or (MR2A(3) = '0' and R2Mult(5) = '1')
					   or (MR3A(3) = '0' and R3Mult(5) = '1')
					   or (MR4A(3) = '0' and R4Mult(5) = '1') --uv )
					   or (V_active /= "00" and V_fr = '1')  ) -- H vector in RAM  
		 else '0' when Sltsl_F_n = '0' and pSltAdr(15 downto 13) = "010" and CsRAM8k = '1'  -- FM Pack RAM
		 else '0' when IDEROMCs_n = '0' and CardMDR(1) = '1' -- Shadow IDE ROM read
		 else '0' when Sltsl_F_n = '0'  and CardMDR(1) = '1' and pSltAdr(15 downto 14) = "01" -- Shadow FM Pack ROM read
  		 else '1';
             
  -- Flash -OutputEnable (-Gate)
--pFlOE_n <= not RDh1 when pSltRd_n = '0'  --pFlOE_nt;
  pFlOE_n <= Rd_n;-- when pSltRd_n = '0'  --pFlOE_nt;
--         else '1';
--pFlOE_nt <= not RDh1 when (pRAMCS_nt = '0' or pFlCS_nt = '0') and pSltRd_n = '0'
  pFlOE_nt <= Rd_n when (pRAMCS_nt = '0' or pFlCS_nt = '0') -- and pSltRd_n = '0'
         else '1';
--  pFlOE_nt <= '0' when Sltsl_C_n = '0' and pSltRd_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")   	-- DatM0
--					 		               or MR1A(3) = '0'  								-- Bank1
--					 		               or MR2A(3) = '0' 									-- Bank2
--					 		               or MR3A(3) = '0' 									-- Bank3
--					 		               or MR4A(3) = '0')   							-- Bank4
--				  else '0' when IDEROMCs_n = '0' and pSltRd_n = '0' -- IDE ROM read
--				  else '0' when SltSl_M_n = '0'  and pSltRd_n = '0' -- MAP RAM read
--				  else
--             '1'; 


  -- Flash/ROM Write
--pFlW_n  <= not WRh1 when Sltsl_C_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")  	-- DatM0
  pFlW_n  <= Wr_n     when Sltsl_C_n = '0' and ((DecMDR = '1' and pSltAdr(5 downto 0) = "000100")  	-- DatM0					 		                   
					 		               or (MR1A(3) = '0' and R1Mult(4) = '1' and DecMDR = '0'
					 		                   and (NSC_SCCP = '0' or -- scc+
											   SccModeB(4) = '1' or SccModeA(4) = '1' or SccModeB(0) = '1')) 			-- Bank1
					 		               or (MR2A(3) = '0' and R2Mult(4) = '1' and DecMDR = '0'
					 		                   and (NSC_SCCP = '0' or -- scc+
											   SccModeB(4) = '1' or SccModeB(1) = '1' or (SccModeA(4) = '1' and Dec1FFE /= '1')))
											                                                                			-- Bank2
					 		               or (MR3A(3) = '0' and R3Mult(4) = '1' and DecMDR = '0'
					 		                   and (NSC_SCCP = '0' or -- scc+
					 		                   SccModeB(4) = '1' or (SccModeB(2) = '1' and SccModeB(5) = '1') )) 							-- Bank3
					 		               or (MR4A(3) = '0' and R4Mult(4) = '1' and DecMDR = '0'
					 		                   and (NSC_SCCP = '0' or -- scc+
					 		                   (SccModeB(4) = '1' and Dec1FFE /= '1'))) )		-- Bank4 
					 		                   
--	 else	 not WRh1 when SltSl_M_n = '0' and ( (Port3C(0) = '0' and pSltAdr(15 downto 14) = "00") -- MAP RAM write
	 else	 Wr_n     when SltSl_M_n = '0' and ( (Port3C(0) = '0' and pSltAdr(15 downto 14) = "00") -- MAP RAM write
											    or (Port3C(1) = '0' and pSltAdr(15 downto 14) = "01")
											    or (Port3C(2) = '0' and pSltAdr(15 downto 14) = "10")
											    or (Port3C(3) = '0' and pSltAdr(15 downto 14) = "11") )
--	 else    not WRh1 when SltSl_F_n = '0' and CsRAM8k = '1' -- FM Pac RAM8k write
	 else    Wr_n     when SltSl_F_n = '0' and CsRAM8k = '1' -- FM Pac RAM8k write

	 else    '1';
	 
  
  -- Adress Flash/ROM mapping          
  pFlAdr(22 downto 0) <=  ("000000" & IDEROMADDR(16) + "0000001") & IDEROMADDR(15 downto 0) when Sltsl_D_n = '0' -- IDE ROM Addr 10000h-2FFFFh
			else   "0000011" & R7FF7 & pSltAdr(13 downto 0) when SltSl_F_n = '0' and CsRAM8k = '0'-- FM Pack ROM 30000h-3FFFFh
			else   "0001111" & "111" & pSltAdr(12 downto 0) when SltSl_F_n = '0' and CsRAM8k = '1'-- FM Pack RAM8Kb 
			else   "01" & (AddrMAP(6) or (not MAP_S)) & AddrMAP(5 downto 0) & pSltAdr(13 downto 0) when SltSl_M_n = '0' -- Mapper RAM 
    
			else   AddrM2(6 downto 0) & AddrM1(7 downto 0) & AddrM0(7 downto 0) 
                         when (DecMDR = '1' and CardMDR(0) = '0' and pSltAdr(5 downto 0) = "000100") -- Direct card vector port
            else   "000000000"&(V_AR + pSltAdr(13 downto 0) - V_RA(13 downto 0)) -- inject vector address
                         when V_active /= "00"          
			else  (AddrFR(6 downto 0) + Maddr(22 downto 16)) & Maddr(15 downto 0); -- Cartridge 
  
  AddrMAP	<=	MAP_FC when  pSltAdr(15 downto 14) = "00" else	-- Mapper Page
				MAP_FD when  pSltAdr(15 downto 14) = "01" else	
				MAP_FE when  pSltAdr(15 downto 14) = "10" else	
				MAP_FF;
  		             
  Maddr(11 downto 0) <=pSltAdr(11 downto 0);
  MR1A <= "0111" when R1Mult(2 downto 0) = "111" and R1Mult(3) = '0' else -- 64k
          "0110" when R1Mult(2 downto 0) = "110" and R1Mult(3) = '0' and B1AdrD(7) = pSltAdr(15) else -- 32k
          "0101" when R1Mult(2 downto 0) = "101" and R1Mult(3) = '0' and B1AdrD(7 downto 6) = pSltAdr(15 downto 14) else -- 16k
          "0100" when R1Mult(2 downto 0) = "100" and R1Mult(3) = '0' and (B1AdrD(7) = pSltAdr(15) or R1Mult(6) = '0') and B1AdrD(6 downto 5) = pSltAdr(14 downto 13) else -- 8k
          "0011" when R1Mult(2 downto 0) = "011" and R1Mult(3) = '0' and (B1AdrD(7 downto 6) = pSltAdr(15 downto 14) or R1Mult(6) = '0') and B1AdrD(5 downto 4) = pSltAdr(13 downto 12) else -- 4k
     --     "0010" when R1Mult(2 downto 0) = "010" and R1Mult(7) = '1' and B1AdrD(7 downto 3) = pSltAdr(15 downto 11)else
     --     "0001" when R1Mult(2 downto 0) = "001" and R1Mult(7) = '1' and B1AdrD(7 downto 2) = pSltAdr(15 downto 10)else
     --     "0000" when R1Mult(2 downto 0) = "000" and R1Mult(7) = '1' and B1AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;

  MR2A <= "0111" when R2Mult(2 downto 0) = "111" and R2Mult(3) = '0' else
          "0110" when R2Mult(2 downto 0) = "110" and R2Mult(3) = '0' and B2AdrD(7) = pSltAdr(15) else
          "0101" when R2Mult(2 downto 0) = "101" and R2Mult(3) = '0' and B2AdrD(7 downto 6) = pSltAdr(15 downto 14) else
          "0100" when R2Mult(2 downto 0) = "100" and R2Mult(3) = '0' and (B2AdrD(7) = pSltAdr(15) or R2Mult(6) = '0') and B2AdrD(6 downto 5) = pSltAdr(14 downto 13) else
          "0011" when R2Mult(2 downto 0) = "011" and R2Mult(3) = '0' and (B2AdrD(7 downto 6) = pSltAdr(15 downto 14) or R2Mult(6) = '0') and B2AdrD(5 downto 4) = pSltAdr(13 downto 12) else
--          "0010" when R2Mult(2 downto 0) = "010" and R2Mult(7) = '1' and B2AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R2Mult(2 downto 0) = "001" and R2Mult(7) = '1' and B2AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R2Mult(2 downto 0) = "000" and R2Mult(7) = '1' and B2AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
 
  MR3A <= "0111" when R3Mult(2 downto 0) = "111" and R3Mult(3) = '0' else
          "0110" when R3Mult(2 downto 0) = "110" and R3Mult(3) = '0' and B3AdrD(0) = pSltAdr(15) else
          "0101" when R3Mult(2 downto 0) = "101" and R3Mult(3) = '0' and B3AdrD(7 downto 6) = pSltAdr(15 downto 14) else
          "0100" when R3Mult(2 downto 0) = "100" and R3Mult(3) = '0' and (B3AdrD(7) = pSltAdr(15) or R3Mult(6) = '0') and B3AdrD(6 downto 5) = pSltAdr(14 downto 13) else
          "0011" when R3Mult(2 downto 0) = "011" and R3Mult(3) = '0' and (B3AdrD(7 downto 6) = pSltAdr(15 downto 14) or R3Mult(6) = '0') and B3AdrD(5 downto 4) = pSltAdr(13 downto 12) else
--          "0010" when R3Mult(2 downto 0) = "010" and R3Mult(7) = '1' and B3AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R3Mult(2 downto 0) = "001" and R3Mult(7) = '1' and B3AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R3Mult(2 downto 0) = "000" and R3Mult(7) = '1' and B3AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
 
  MR4A <= "0111" when R4Mult(2 downto 0) = "111" and R4Mult(3) = '0' and NSC = '0' else
		  "0111" when R3Mult(2 downto 0) = "111" and R4Mult(3) = '0' and NSC = '1' else
          "0110" when R4Mult(2 downto 0) = "110" and R4Mult(3) = '0' and B4AdrD(7) = pSltAdr(15) and NSC = '0' else
          "0110" when R3Mult(2 downto 0) = "110" and R4Mult(3) = '0' and B4AdrD(7) = pSltAdr(15) and NSC = '1' else
          "0101" when R4Mult(2 downto 0) = "101" and R4Mult(3) = '0' and B4AdrD(7 downto 6) = pSltAdr(15 downto 14) and NSC = '0' else
          "0101" when R3Mult(2 downto 0) = "101" and R4Mult(3) = '0' and B4AdrD(7 downto 6) = pSltAdr(15 downto 14) and NSC = '1' else
          "0100" when R4Mult(2 downto 0) = "100" and R4Mult(3) = '0' and (B4AdrD(7) = pSltAdr(15) or R4Mult(6) = '0') and B4AdrD(6 downto 5) = pSltAdr(14 downto 13) and NSC = '0' else
          "0100" when R3Mult(2 downto 0) = "100" and R4Mult(3) = '0' and (B4AdrD(7) = pSltAdr(15) or R4Mult(6) = '0') and B4AdrD(6 downto 5) = pSltAdr(14 downto 13) and NSC = '1' else
          "0011" when R4Mult(2 downto 0) = "011" and R4Mult(3) = '0' and (B4AdrD(7 downto 6) = pSltAdr(15 downto 14) or R4Mult(6) = '0') and B4AdrD(5 downto 4) = pSltAdr(13 downto 12) and NSC = '0' else
          "0011" when R3Mult(2 downto 0) = "011" and R4Mult(3) = '0' and (B4AdrD(7 downto 6) = pSltAdr(15 downto 14) or R4Mult(6) = '0') and B4AdrD(5 downto 4) = pSltAdr(13 downto 12) and NSC = '1' else
--          "0010" when R4Mult(2 downto 0) = "010" and R4Mult(7) = '1' and B4AdrD(7 downto 3) = pSltAdr(15 downto 11)else
--          "0001" when R4Mult(2 downto 0) = "001" and R4Mult(7) = '1' and B4AdrD(7 downto 2) = pSltAdr(15 downto 10)else
--          "0000" when R4Mult(2 downto 0) = "000" and R4Mult(7) = '1' and B4AdrD(7 downto 1) = pSltAdr(15 downto 9)else
          "1000" ;
                        
  Maddr(22 downto 12) <= (B1MaskR(6 downto 0) and R1Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR1A = "0111" else
                        (B1MaskR and R1Reg) & pSltAdr(14 downto 12) when MR1A = "0110" else
                        "0" & (B1MaskR and R1Reg) & pSltAdr(13 downto 12) when MR1A = "0101" else
                        "00" & (B1MaskR and R1Reg) & pSltAdr(12) when MR1A = "0100" else
                        "000" & (B1MaskR and R1Reg) when MR1A = "0011" else
--                        "0000" & (B1MaskR and R1Reg) & pSltAdr(10 downto 9) when MR1A = "0010" else
--                        "00000" & (B1MaskR and R1Reg) & pSltAdr(9) when MR1A = "0001" else
--                        "000000" & (B1MaskR and R1Reg) when MR1A = "0000" else
                        
                        (B2MaskR(6 downto 0) and R2Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR2A = "0111" else
                        (B2MaskR and R2Reg) & pSltAdr(14 downto 12) when MR2A = "0110" else
                        "0" & (B2MaskR and R2Reg) & pSltAdr(13 downto 12) when MR2A = "0101" else
                        "00" & (B2MaskR and R2Reg) & pSltAdr(12) when MR2A = "0100" else
                        "000" & (B2MaskR and R2Reg) when MR2A = "0011" else
--                        "0000" & (B2MaskR and R2Reg) & pSltAdr(10 downto 9) when MR2A = "0010" else
--                       "00000" & (B2MaskR and R2Reg) & pSltAdr(9) when MR2A = "0001" else
--                        "000000" & (B2MaskR and R2Reg) when MR2A = "0000" else
                        
                        (B3MaskR(6 downto 0) and R3Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR1A = "0111" else
                        (B3MaskR and R3Reg) & pSltAdr(14 downto 12) when MR3A = "0110" else
                        "0" & (B3MaskR and R3Reg) & pSltAdr(13 downto 12) when MR3A = "0101" else
                        "00" & (B3MaskR and R3Reg) & pSltAdr(12) when MR3A = "0100" else
                        "000" & (B3MaskR and R3Reg) when MR3A = "0011" else
--                        "0000" & (B3MaskR and R3Reg) & pSltAdr(10 downto 9) when MR3A = "0010" else
--                        "00000" & (B3MaskR and R3Reg) & pSltAdr(9) when MR3A = "0001" else
--                        "000000" & (B3MaskR and R3Reg) when MR3A = "0000" else
                        
                        (B4MaskR(6 downto 0) and R4Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR4A = "0111" and NSC = '0' else
                        (B3MaskR(6 downto 0) and R4Reg(6 downto 0)) & pSltAdr(15 downto 12) when MR4A = "0111" and NSC = '1' else
                        (B4MaskR and R4Reg) & pSltAdr(14 downto 12) when MR4A = "0110" and NSC = '0' else
                        (B3MaskR and R4Reg) & pSltAdr(14 downto 12) when MR4A = "0110" and NSC = '1' else
                        "0" & (B4MaskR and R4Reg) & pSltAdr(13 downto 12) when MR4A = "0101" and NSC = '0' else
                        "0" & (B3MaskR and R4Reg) & pSltAdr(13 downto 12) when MR4A = "0101" and NSC = '1' else
                        "00" & (B4MaskR and R4Reg) & pSltAdr(12) when MR4A = "0100" and NSC = '0' else
                        "00" & (B3MaskR and R4Reg) & pSltAdr(12) when MR4A = "0100" and NSC = '1' else
                        "000" & (B4MaskR and R4Reg) when MR4A = "0011" and NSC = '0' else
                        "000" & (B3MaskR and R4Reg) when MR4A = "0011" and NSC = '1' -- else
--                        "0000" & (B4MaskR and R4Reg) & pSltAdr(10 downto 9) when MR4A = "0010" else
--                        "00000" & (B4MaskR and R4Reg) & pSltAdr(9) when MR4A = "0001" else
--                        "000000" & (B4MaskR and R4Reg) when MR4A = "0000" 
						;
                        
                        
  -- if(R1Mult(2 downto 0) =  "111") then Maddr(22 downto 8) <= (B1MaskR(6 downto 0) and R1Reg(6 downto 0)) & pSltAdr(15 downto 8);
  -- elsif (R1Mult(2 downto 0) =  "110" and B1AdrD(0) = pSltAdr(15)) then Maddr(22 downto 8) <= (B1MaskR and R1Reg) & pSltAdr(14 downto 8);
  -- elsif (R1Mult(2 downto 0) =  "101" and B1AdrD(1 downto 0) = pSltAdr(15 downto 14)) then Maddr(22 downto 8) <= "0" & (B1MaskR and R1Reg) & pSltAdr(13 downto 8); 
  -- end if;
  
  ----------------------------------------------------------------
  -- SCC register / wave memory access
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then

      SccBank0   <= "00000000";
      SccBank1   <= "00000001";
      SccBank2   <= "00000010";
      SccBank3   <= "00000011";
      SccModeA   <= (others => '0');
      SccModeB   <= (others => '0');

      SccWavWx   <= '0';
      SccWavAdr  <= (others => '0');
      SccWavDat  <= (others => '0');

    elsif (pSltClk_n'event and pSltClk_n = '1') then

          -- Mapped I/O port access on 5000-57FFh ... Bank resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "01010" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank0 <= pSltDat;
      end if;
      -- Mapped I/O port access on 7000-77FFh ... Bank resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "01110" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank1 <= pSltDat;
      end if;
      -- Mapped I/O port access on 9000-97FFh ... Bank resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "10010" and
          SccModeB(4) = '0') then
        SccBank2 <= pSltDat;
      end if;
      -- Mapped I/O port access on B000-B7FFh ... Bank resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 11) = "10110" and
          SccModeA(6) = '0' and SccModeA(4) = '0' and SccModeB(4) = '0') then
        SccBank3 <= pSltDat;
      end if;

      -- Mapped I/O port access on 7FFE-7FFFh ... Resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 13) = "011" and Dec1FFE = '1' and
          SccModeB(5 downto 4) = "00") then
        SccModeA <= pSltDat;
      end if;

      -- Mapped I/O port access on BFFE-BFFFh ... Resister write
      if (Sltsl_C_n = '0' and pSltWr_n = '0' and pSltAdr(15 downto 13) = "101" and Dec1FFE = '1' and
          SccModeA(6) = '0' and SccModeA(4) = '0') then
        SccModeB <= pSltDat;
      end if;

      -- Mapped I/O port access on 9860-987Fh ... Wave memory copy
      if (Sltsl_C_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and pSltAdr(7 downto 5) = "011" and
          DevHit = '1' and SccModeB(4) = '0' and DecSccA = '1') then
        SccWavAdr <= pSltAdr(4 downto 0);
        SccWavDat <= pSltDat;
        SccWavWx  <= '1';
      else
        SccWavWx  <= '0';
      end if;

    end if;

  end process;

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavCe <= '1' when Sltsl_C_n = '0' and CardMDR(4) = '1' and DevHit = '1' and SccModeB(4) = '0' and
                       (DecSccA = '1' or DecSccB = '1')
                  else '0';

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavOe <= '1' when Sltsl_C_n = '0' and CardMDR(4) = '1' and pSltRd_n = '0' and SccModeB(4) = '0' and
                       ((DecSccA = '1' and pSltAdr(7) = '0') or
                        (DecSccB = '1' and (pSltAdr(7) = '0' or pSltAdr(6 downto 5) = "00")))
                  else '0';

  -- Mapped I/O port access on 9800-987Fh / B800-B89Fh ... Wave memory
  SccWavWe <= '1' when Sltsl_C_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and DevHit = '1' and SccModeB(4) = '0' and
                       ((DecSccA = '1' and pSltAdr(7) = '0') or DecSccB = '1')
                  else '0';

  -- Mapped I/O port access on 9880-988Fh / B8A0-B8AF ... Resister write
  SccRegWe <= '1' when Sltsl_C_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and
                       ((DecSccA = '1' and pSltAdr(7 downto 5) = "100") or
                        (DecSccB = '1' and pSltAdr(7 downto 5) = "101")) and
                       DevHit = '1' and SccModeB(4) = '0'
                  else '0';

  -- Mapped I/O port access on 98C0-98FFh / B8C0-B8DFh ... Resister write
  SccModWe <= '1' when Sltsl_C_n = '0' and CardMDR(4) = '1' and pSltWr_n = '0' and pSltAdr(7 downto 6) = "11" and
                       (DecSccA = '1' or (pSltAdr(5) = '0' and DecSccB = '1')) and
                       DevHit = '1' and SccModeB(4) = '0'
                  else '0';

  ----------------------------------------------------------------
  -- Connect components
  ----------------------------------------------------------------

  SccCh  : scc_wave
    port map(
      pSltClk_n, pSltRst_n, pSltAdr(7 downto 0), pSltDat, SccAmp,
      SccRegWe, SccModWe, SccWavCe, SccWavOe, SccWavWe, SccWavWx, SccWavAdr, SccWavDat, DOutEn_n, DOut(7 downto 0) 
    );

  ----------------------------------------------------------------
  -- 1 bit D/A  control
  ----------------------------------------------------------------
--  process(pSltClk_n, pSltRst_n)
--
--    variable Amp  : std_logic_vector(7 downto 0);
--    variable Acu  : std_logic_vector(8 downto 0);
--
--  begin
--
--    if (pSltRst_n = '0') then
--
--      Amp  := (others => '0');
--      Acu  := (others => '0');
--      pSltSndL  <= '0';
--      pSltSndR  <= '0';
--      pSltSound <= '0';
--
--    elsif (pSltClk_n'event and pSltClk_n = '1') then
--
--      Amp  := SccAmp and "11111110";
--      Acu  := ('0' & Acu(7 downto 0)) + ('0' & Amp);
--      pSltSndL  <= Acu(8);
--      pSltSndR  <= Acu(8);
--      pSltSound <= Acu(8);
--
--    end if;
--  end process;

--- **************************************************************************************************
--- CF Disk controller slot
---
-- Sltsl_D_n

---------------------------------------------------------------
-- Adapt timing
----------------------------------------------------------------
  CLC_n		<= not pSltClk;
  process(pSltRst_n, CLC_n, pSltRd_n)
  begin
    if (pSltRd_n = '1') then
      RD_hT1 <= '0';
    elsif (RD_hT2 = '0') then
      if (pSltRd_n = '0' and CLC_n = '0' and IDEReg = '1' and (pSltAdr(9) = '1' or pSltAdr(0) = '0')) then
        RD_hT1 <= '1';
      end if;
    end if;
    if (CLC_n'event and CLC_n = '1') then
      RD_hT2 <= not pSltRd_n;
    end if;
  end process;
  process(pSltRst_n, CLC_n)
  begin
    if (pSltRst_n = '0') then
      WR_hT2 <= '0';
    elsif (CLC_n'event and CLC_n = '0') then
      WR_hT2 <= WR_hT1;
    end if;
  end process;
  process(pSltWr_n,WR_hT2)
  begin
    if (pSltWr_n = '1') then
      WR_hT1 <= '0';
    elsif (WR_hT2 = '0') then
      if (pSltWr_n = '0' and IDEReg = '1' and (pSltAdr(9) = '1' or pSltAdr(0) = '1')) then
        WR_hT1 <= '1';
      end if;
    end if;
  end process;
---
--  process(pSltRst_n, CLC_n, pSltRd_n)
--  begin
--    if (pSltRd_n = '1') then
--      RDh1 <= '0';
--    elsif (RDh2 = '0') then
--      if (pSltRd_n = '0' and CLC_n = '0') then
--        RDh1 <= '1';
--      end if;
--    end if;
--    if (CLC_n'event and CLC_n = '1') then
--      RDh2 <= not pSltRd_n;
--    end if;
--  end process;
--  process(pSltRst_n, CLC_n)
--  begin
--    if (pSltRst_n = '0') then
--      WRh2 <= '0';
--   elsif (CLC_n'event and CLC_n = '0') then
--      WRh2 <= WRh1;
--    end if;
--  end process;
--  process(pSltWr_n,WRh2)
--  begin
--    if (pSltWr_n = '1') then
--      WRh1 <= '0';
--    elsif (WRh2 = '0') then
--      if (pSltWr_n = '0') then
--        WRh1 <= '1';
--     end if;
--    end if;
--  end process;
---  process(pSltRd_n,WRh2)
---  begin
---    if (pSltRd_n = '0') then
---      if (WRh2 = '0') then RDh1 <= '1'; end if;
---    elsif (pSltRd_n = '1') then
---      if (WRh2 = '1') then RDh1 <= '0'; end if;
---    end if;
---  end process;
---  process(pSltWr_n,WRh2)
---  begin
---    if (pSltWr_n = '0') then
---      if (WRh2 = '0') then WRh1 <= '1'; end if;
---    elsif (pSltWr_n = '1') then
---      if (WRh2 = '1') then WRh1 <= '0'; end if;
---    end if;
---  end process;
---  process(pSltClk,WRh1,RDh1)
---  begin
---    if (pSltClk'event and pSltClk = '1') then
---      if (WRh1 = '1' or RDh1 = '1') then
---        WRh2 <= '1'; 
---      else
---        WRh2 <= '0';
---      end if;
---    end if;
---  end process;
  process(pSltSltsls_n, sltt)
  begin
    if (pSltSltsls_n = '0') then
      if (sltt = '0') then pSltSltslt_n <= '0'; end if;
--    elsif (pSltSltsls_n = '1') then
	else
      if (sltt = '1') then pSltSltslt_n <= '1'; end if;
    end if;
  end process; 
  process(pSltClk,pSltSltslt_n)  
  begin
    if (pSltClk'event and pSltClk = '1') then
      if (pSltSltslt_n = '0') then
        sltt <= '1'; 
      else
        sltt <= '0';
      end if;
    end if;
  end process;  
--s  pSltSltslt_n <= pSltSltsls_n;

--  process (pSltClk2)
--  begin
--    if pSltClk2'event and pSltClk2 = '1' then
--        tsrd <= tsrd + "001" ;
--    end if ;
--  end process ;  
--
--  process (pSltRd_n)
--  begin
--  
--  end process ;  

  process (pSltRd_n)
  begin
    if    (pSltRd_n = '0' and LRD = '1') then Rd_n <= '0';
    elsif (pSltRd_n = '1' and LRD = '0') then Rd_n <= '1';
    end if;
  end process;
  process (pSltWr_n)
  begin
    if    (pSltWr_n = '0' and LRD = '1') then Wr_n <= '0';
    elsif (pSltWr_n = '1' and LRD = '0') then Wr_n <= '1';
    end if;
  end process;
  process (pSltClk2)
  begin
  if (pSltClk2'event and pSltClk2 = '1') then LRD <= LRD1 ; LRD1 <= Rd_n and Wr_n;
  end if;
  end process;
  
----------------------------------------------------------------
-- Set IDE Register
----------------------------------------------------------------
  DecIDEconf <= '1' when Sltsl_D_n = '0' and pSltAdr(15 downto 0) = "0100000100000100" 
                   else '0';
    process(pSltRst_n, pSltClk_n)
  begin
    if (pSltRst_n = '0') then
      cReg			<= "00000000";
---    elsif (pSltClk_n'event and pSltClk_n = '1') then
 --   elsif (pSltWr_n'event and pSltWr_n = '0') then
      -- Config IDE Sunrise Register
---      if (DecIDEconf = '1' and pSltWr_n = '0') then
	elsif (Wr_n'event and Wr_n = '0') then
      if (DecIDEconf = '1') then
        cReg <= pSltDat;
      end if;
    end if;
  end process;
----------------------------------------------------------------
-- ROM decoder
---------------------------------------------------------------- 
  IDEROMCs_n	<= '0' when Sltsl_D_n = '0' and IDEReg = '0' and pSltAdr(15 downto 14) = "01"
					   else '1';
  IDEROMADDR    <= 	cReg(5) & cReg(6) & cReg(7) & pSltAdr(13 downto 0);	  
----------------------------------------------------------------
-- IDE Processing
---------------------------------------------------------------- 
  IDEReg 		<= '0' when	pSltAdr(9 downto 8) = "11" 
					   else '1' when Sltsl_D_n = '0' and cReg(0) = '1' and pSltAdr(15 downto 10) = "011111" -- 7C00h-7FEFh
					   else '0';
---  process(IDEReg, RD_hT1)
---  begin
---    if (CLC_n'event and CLC_n = '0') then
---      if (IDEReg = '1' and pSltAdr(9) = '0' and  pSltAdr(0) = '0' and pSltRd_n = '0' and RD_hT2 = '1') then 
---        IDEsIN <=  pIDEDat(15 downto 8);	
---      end if;
---    end if;    
---  end process;
  process(Rd_n,IDEReg)
  begin
    if (IDEReg = '1' and pSltAdr(9) = '0' and  pSltAdr(0) = '0' and Rd_n = '0') then
      IDEsIN <=  pIDEDat(15 downto 8);	
    end if;
  end process;
  process(IDEReg)
  begin
    if (IDEReg = '1' and pSltAdr(9) = '0' and pSltWr_n = '0' and pSltAdr(0) = '0') then 
      IDEsOUT <=  pSltDat;	
    end if;   
  end process; 
--- pIDEDat(15 downto 8) 	<= 	pSltDat when IDEReg = '1' and pSltAdr(9) = '1' and RD_hT1 = '0' 
---                                        and pSltRd_n = '1'
---                           else pSltDat when IDEReg = '1' and RD_hT1 = '0' 
---                                             and pSltRd_n = '1' 
---							else (others => 'Z');
---  pIDEDat(7 downto 0) 	<= 	pSltDat when IDEReg = '1' and pSltAdr(9) = '1' and RD_hT1 = '0' 
---                                         and pSltRd_n = '1' 
---							else IDEsOUT when IDEReg = '1' and pSltAdr(9) = '0' and pSltAdr(0) = '1' 
---							                  and RD_hT1 = '0' 
---							else (others => 'Z');  
  pIDEDat(15 downto 8) 	<= 	pSltDat when IDEReg = '1' and pSltAdr(9) = '1' and Rd_n = '1' and pSltRd_n = '1'
                       else pSltDat when IDEReg = '1' and Rd_n = '1' and pSltRd_n = '1'
					   else (others => 'Z');
  pIDEDat(7 downto 0) 	<= 	pSltDat when IDEReg = '1' and pSltAdr(9) = '1' and Rd_n = '1' and pSltRd_n = '1'
					   else IDEsOUT when IDEReg = '1' and pSltAdr(9) = '0' and pSltAdr(0) = '1' 
							             and Rd_n = '1' and pSltRd_n = '1'
					   else (others => 'Z');


  pIDEAdr		<= pSltAdr(2 downto 0) when pSltAdr(9) = '1'
                   else "000";
--  pIDECS1_n		<= pSltAdr(3) when pSltAdr(9) = '1' and IDEReg = '1'
--				   else '0' when IDEReg = '1'
--				   else '1';
--  pIDECS3_n		<= not pSltAdr(3) when pSltAdr(9) = '1' and IDEReg = '1'
--				   else '1';
  pIDECS1_n             <= pSltAdr(3) when pSltAdr(9) = '1'
                                   else '0';
  pIDECS3_n             <= not pSltAdr(3) when pSltAdr(9) = '1'
                                   else '1';
---  pIDERD_n		<= not RD_hT1;
---  pIDEWR_n		<= not WR_hT1;
  pIDERD_n		<= Rdh_n;
  pIDEWR_n		<= Wrh_n;
  pPIN180		<= '1';
  pIDE_Rst_n	<= pSltRst_n;
  Rdh_n			<= '0' when Rd_n = '0' and IDEReg = '1' and (pSltAdr(9) = '1' or pSltAdr(0) = '0') else '1';
  Wrh_n			<= '0' when Wr_n = '0' and IDEReg = '1' and (pSltAdr(9) = '1' or pSltAdr(0) = '1') else '1';
--- **************************************************************************************************
--- RAM Mapper slot
---
-- Sltsl_M_n

----------------------------------------------------------------
-- Mapper Register
----------------------------------------------------------------
  DEC_P		 <= '1' when Sltsl_M_n = '0' and Port3C(7) = '1' and 
                         (  (pSltAdr(15 downto 14) = "10" and Port3C(3) = '0') 
                         or (pSltAdr(15 downto 14) = "01" and Port3C(3) = '1')  )
                    else '0'; 

  DEC_P3C    <= '1' when pSltAdr(7 downto 0) = "00111100" and DEC_P = '1'
                    else '0';
  DEC_PFC    <= '1' when pSltAdr(7 downto 0) = "11111100" and DEC_P = '1'
                    else '0';
  DEC_PFD    <= '1' when pSltAdr(7 downto 0) = "11111101" and DEC_P = '1'
                    else '0';
  DEC_PFE    <= '1' when pSltAdr(7 downto 0) = "11111110" and DEC_P = '1'
                    else '0';
  DEC_PFF    <= '1' when pSltAdr(7 downto 0) = "11111111" and DEC_P = '1'
                    else '0';

  process(pSltRst_n, pSltClk_n)
  begin
    if(pSltRst_n = '0') then
      
--     MAP_FC <= "0000000" ;
--     MAP_FD <= "0000001" ;
--     MAP_FE <= "0000010" ;
--     MAP_FF <= "0000011" ;
--   Wouter Vermaelen  "But the MSX BIOS initializes them like this:"     
      MAP_FC <= "0000011" ;
      MAP_FD <= "0000010" ;
      MAP_FE <= "0000001" ;
      MAP_FF <= "0000000" ;
      
      Port3C <= "00000000" ;
    elsif (pSltClk_n'event and pSltClk_n = '1') then
 --   elsif (pSltWr_n' event and pSltWr_n = '0') then
    -- IOR Registers access
     if pSltWr_n = '0' then
--   Wouter Vermaelen find error:    
--     if(pSltAdr(7 downto 0) = "0011100" and pSltIorq_n = '0' and Port3C(5) = '0' and Mconf(4) = '1') then -- OUT (#3C),a
      if(pSltAdr(7 downto 0) = "00111100" and pSltIorq_n = '0' and Port3C(5) = '0' and Mconf(4) = '1') then -- OUT (#3C),a
        Port3C(7) <= pSltDat(7);
      end if;
      if(pSltAdr(7 downto 0) = "11111100" and Port3C(5) = '0' and pSltIorq_n = '0') then
        MAP_FC <= pSltDat(6 downto 0);
      end if;
      if(pSltAdr(7 downto 0) = "11111101" and Port3C(5) = '0' and pSltIorq_n = '0') then
        MAP_FD <= pSltDat(6 downto 0);
      end if;
      if(pSltAdr(7 downto 0) = "11111110" and Port3C(5) = '0' and pSltIorq_n = '0') then
        MAP_FE <= pSltDat(6 downto 0);
      end if;
	  if(pSltAdr(7 downto 0) = "11111111" and Port3C(5) = '0' and pSltIorq_n = '0') then
        MAP_FF <= pSltDat(6 downto 0);
      end if;
    -- memory page register access
      if(DEC_P3C = '1') then
--   Wouter Vermaelen find error:    2     
---     Port3C(7) <= pSltDat(7) or pSltDat(1);
        Port3C(7) <= pSltDat(7) or pSltDat(5);
        Port3C(6 downto 0) <=  pSltDat(6 downto 0);
      end if;
      if(DEC_PFC = '1') then
        MAP_FC <= pSltDat(6 downto 0);
      end if;
      if(DEC_PFD = '1') then
        MAP_FC <= pSltDat(6 downto 0);
      end if;
      if(DEC_PFE = '1') then
        MAP_FC <= pSltDat(6 downto 0);
      end if;
      if(DEC_PFF = '1') then 
        MAP_FF <= pSltDat(6 downto 0);
      end if;
     end if;
    end if;
  end process;


--- **************************************************************************************************
--- FM pack slot
---
-- Sltsl_F_n
--	7FF4h: write YM-2413 register port (write only)
--	7FF5h: write YM-2413 data port (write only)
--	7FF6h: activate OPLL I/O ports (read/write)
--	7FF7h: ROM page (read/write)
--  4Dh to 5FFEh and 69h to 5FFFh. Now 8kB SRAM is active in 4000h - 5FFFh 

  CsOPLL <= '1' when Sltsl_F_n = '0' and pSltAdr(15 downto 1) = "011111111111010" and R7FF6b0 = '1'
       else '0';
  process(pSltRst_n, pSltClk_n)
  begin
    if(pSltRst_n = '0') then
      R7FF6b0 <= '0' ;
      R7FF6b4 <= '1' ;
      R7FF7 <= "00" ;
      R5FFE <= "00000000" ;
      R5FFF <= "00000000" ;
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      if (pSltWr_n = '0'and Sltsl_F_n = '0') then
        if pSltAdr(15 downto 0) = "0111111111110110" then
          R7FF6b0 <= pSltDat(0); R7FF6b4 <= pSltDat(4);
        end if;
        if pSltAdr(15 downto 0) = "0111111111110111" then
          R7FF7 <= pSltDat(1 downto 0);
        end if;
        if pSltAdr(15 downto 0) = "0101111111111110" then
          R5FFE <= pSltDat(7 downto 0);
        end if;
        if pSltAdr(15 downto 0) = "0101111111111111" then
          R5FFF <= pSltDat(7 downto 0);
        end if;
      end if;
    end if;
  end process;
  CsRAM8k <= '1' when R5FFE = "01001101" and R5FFF = "01101001"
       else '0';
       
----------------------------------------------------------------
-- FM Pack Register
----------------------------------------------------------------

  U1 : opll port map (pSltClk_n, open, xena, pSltDat, pYM2413_A, pYM2413_Cs_n, pYM2413_We_n, 
                      pSltRst_n, MO, RO, BCMO, BCRO, SDO);
--  clk21m <= pSltClk;
  pYM2413_A <= pSltAdr(0);
  xena <=  '1';
--pYM2413_We_n <= not WRh1;-- pSltWr_n;
  pYM2413_We_n <= Wr_n;-- pSltWr_n;
  pYM2413_Cs_n <= '0' when pSltAdr(7 downto 1) = "0111110" and pSltIorq_n = '0' 
                           and ( R7FF6b0 = '1' or Mconf(5) = '1')  -- processor port address (7C,7D)
  			 else '0' when CsOPLL = '1' -- and R7FF6b0 = '1'
--pYM2413_Cs_n <= '0' when pSltAdr(7 downto 1) = "0111110" and pSltIorq_n = '0' and R7FF6b4 = '1' and Mconf(5) = '1'  -- processor port address (7C,7D)
--			 else '0' when CsOPLL = '1' and R7FF6b0 = '1'
             else '1';

--       mix := ('0'&MO) + ('0'&RO) - "010 0000 0000";
--		mix <= ('0'&MO) + ('0'&RO) - "01000000000"; --(10)
--        wav <= mix(wav'range);-- 10 downto 0
        
        
----------------------------------------------------------------
-- Audio Mixer RO,MO(9 downto 0),SCC, Filter
----------------------------------------------------------------

--  SCL <= ("0"&MO&"0")+('0'&(SccAmp+"100 0000 0000")) ;
--  SCR <= ("0"&RO&"0")+('0'&(SccAmp+"10000000000")) ;
  SCL <= "100000000000" + SccAmp ;--+ PsgAmp + KC ;
  SCR <= "100000000000" + SccAmp;-- + PsgAmp + KC ;
  process (pSltClk_n)
  begin
    if pSltRst_n = '0' then FDIV <= "00000000";
    elsif pSltClk_n'event and pSltClk_n = '1' then
      FDIV <= FDIV + "00000001";
    end if;
  end process;


-- filter SCC

  process (pSltClk_n,LRCKe,pSltClk2)
  begin
    if LRCKe = '0' then rsta1 <= '0';
    elsif pSltClk2'event and pSltClk2 ='1' then
      if LRCKe = '1' and pSltClk_n ='0' and rsta1 = '0' then
         rsta1 <= '1'; rsta0 <='1';
      else 
         rsta0 <= '0';
      end if;
     end if;
  end process;
  process (pSltClk_n,LRCKe)
  begin
    if  LRCKe = '1' then ACL <= "00000000000000000000"; ACR <= "00000000000000000000"; --(0)
    elsif pSltClk_n'event and pSltClk_n ='0' then
      ACL <= ACL + (not SCL(11) & not SCL(11) & not SCL(11) & not SCL(11) & 
                    not SCL(11) & not SCL(11) & not SCL(11) & not SCL(11) & 
                    not SCR(11) & SCL(10 downto 0) ) ;   -- (19-0)       
    end if;
  end process;
 -- process (FDIV(5),FDIV(0))
  process (SDAC,pSltClk_n)
  begin
    if pSltClk_n ='0' then LRCKe <= '0';
--    elsif FDIV(5)'event and FDIV(5) = '0' then
    elsif SDAC'event and SDAC = '0' then
      MACL <=  ACL(17 downto 2);
      MACR <=  ACL(17 downto 2);
--    MACR <=  ACR(18 downto 3);-- (not ACR(19)) & ACR(18 downto 4);
      LRCKe <= '1';
    end if;
  end process;
  process (pSltClk_n)
  begin
    if pSltClk_n'event and pSltClk_n = '1' then
    SDAC <= ADACDiv(7);
    end if;
  end process;  
-- Mixer
 process(c0)
 begin
   if c0'event and c0 = '0' then
     pSltClk_nt <= pSltClk_n;
   end if; 
 end process;
 process (pSltClk_nt)
 begin
   if pSltClk_nt'event and pSltClk_nt = '0' then
     L_AOUT <= MFL + MSL + MPL + MBL;
     R_AOUT <= MFR + MSL + MPL + MBL; -- MSR;
   end if;
 end process;  
----------------------------------------------------------------
-- Volume regulator
----------------------------------------------------------------
  VMFL : mv16 port map (BCMO, MFL, LVF);
  VMFR : mv16 port map (BCRO, MFR, LVF);
  VMSL : mv16 port map (MACL, MSL, LVS);
  VMGL : mv16 port map (MACP, MPL, LVP);
  VMBL : mv16 port map (MACB, MBL, LVB);

  LVF <= LVL(5 downto 3); -- Level FM PAK
  LVS <= LVL(2 downto 0); -- Level SCC, SCC+
  LVP <= LVL1(5 downto 3); -- Level PSG
  LVB <= LVL1(2 downto 0); -- Level Beeper 
----------------------------------------------------------------
-- Filter PSG
----------------------------------------------------------------
-- MACP <= PsgAmp;
  SCP <= PsgAmp(9 downto 0);
  process (pSltClk_n,resP)
  begin
    if resP = '1' or LVL1(7) = '0' then ACP <= (others => '0');
    elsif pSltClk_n'event and pSltClk_n ='0' then  
       ACP <= ACP + ("000000000" & SCP);     
    end if;
  end process;
  process (SDAC,pSltClk_n)
  begin
    if pSltClk_n ='0' then resP <= '0';
    elsif SDAC'event and SDAC = '0' then
      MACP <=  ACP(18 downto 3);-- & '0';
      resP <= '1';
	end if;
  end process;
 
----------------------------------------------------------------
-- Filter Beeper
----------------------------------------------------------------    
--  MACB <=  KC & "000000"
  process (pSltClk_n,resB)
  begin
    if resB = '1' or LVL1(6) = '0' then ACB <= (others => '0');
    elsif pSltClk_n'event and pSltClk_n ='0' then  
       ACB <= ACB - ("000000000" & KC & "000000");     
    end if;
  end process;
  process (FDIV(6),pSltClk_n)
  begin
    if pSltClk_n ='0' then resB <= '0';
    elsif FDIV(6)'event and FDIV(6) = '0' then
      MACB_f <= ACB;-- & '0';
      resB <= '1';
	end if;
  end process;  
  MACB <= MACB_f;-- + MACB_i;
--  process (FDIV(1))
--  begin
--    if FDIV(1)'event and FDIV(1) = '0' then
--      if MACB(15) = '0' then
--        MACB_i <= MACB_i + "1111111111111111";
--      else
--        MACB_i <= MACB_i + "0000000000000001";
--      end if;   
--    end if;
--  end process;
   
----------------------------------------------------------------
-- PLL OUT
----------------------------------------------------------------
  U2 : mpll1 port map (areset,pSltClk2,c0,open);
  areset <= not pSltRst_n;
 
----------------------------------------------------------------
-- DAC control -- Audio DAC YAC516 ( -1 = 8000, 0=0, +1 = 7FFF
----------------------------------------------------------------

  mCLC <=c0; 
-- divider 
  process(c0,pSltRst_n)-- c0 = 11.2896 MHz / LRCK = 44.1 kHz
  begin
    if (pSltRst_n = '0') then ADACDiv <= "00000000" ;
    elsif (c0'event and c0 = '0') then
      ADACDiv <= ADACDiv + "00000001" ;
    end if;
  end process;
  MCLK <= c0; 
  BICK <= ADACDiv(2);
  LRCK <= NOT ADACDiv(7);
-- lach L_DAC , R_DAC
  process(ADACDiv(2))
  begin
    if (c0'event and c0 = '1') then
      if (ADACDiv(2 downto 0) = "000") then --BICK
        if (ADACDiv(6 downto 3) = "0000") then
          if ADACDiv(7) = '0' then
            ABDAC <= L_AOUT;
          else
            ABDAC <= R_AOUT;
          end if;
        else
          ABDAC(15 downto 1) <= ABDAC(14 downto 0);
        end if;
      end if;
    end if;
  end process;  
  SDATA <= ABDAC(15);
  IC_n <= pSltRst_n;
  CKS <= '0';
----------------------------------------------------------------
-- EEPROM Output
----------------------------------------------------------------
  EECS <= '1' when EECS1 = '1' else '0';
  EECK <= '1' when EECK1 = '1' else '0';
  EEDI <= '1' when EEDI1 = '1' else '0';

----------------------------------------------------------------
-- PSG  (SSG + PPI Sound)
----------------------------------------------------------------

  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then

      PsgRegPtr <= (others => '1');
      KC  <= '1';

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      -- I/O port access on A0h ... Resister number setting
      if (DevHit = '1' and pSltIorq_n = '0' and pSltWr_n = '0' and pSltAdr(7 downto 0) = "10100000") then
        PsgRegPtr <= pSltDat(3 downto 0);
      end if;

      -- I/O port access on AAh ... 1 bit sound port write (not PSG)
      if (DevHit = '1' and pSltIorq_n = '0' and pSltWr_n = '0' and pSltAdr(7 downto 1) = "1010101") then
        if (pSltAdr(0) = '0') then
          KC <= pSltDat(7);
        elsif (pSltDat(3 downto 1) = "111" and pSltDat(7) = '0') then
          KC <= pSltDat(0);
        end if;
      end if;

    end if;

  end process;
  -- I/O port access on A1h ... Resister write
  PsgRegWe <= '1' when DevHit = '1' and pSltIorq_n = '0' and pSltWr_n = '0' and pSltAdr(7 downto 0) = "10100001" else '0';
  -- Connect component
  PsgCh  : psg_wave
    port map(
      pSltClk_n, pSltRst_n, PsgRegPtr, pSltDat, PsgAmp,
      PsgRegWe
    );

----------------------------------------------------------------
-- INIT ROM Code Injector
----------------------------------------------------------------

process (Rd_n,pSltRst_n)
begin
  if pSltRst_n = '0' then
    V_active <= "00";
  elsif (Rd_n'event and Rd_n = '0') then
    if pSltM1_n = '0' and  Sltsl_C_n = '0' and V_hunt = '1' then
	  V_RA <= pSltAdr; -- get return address
      V_active <= "11"; -- inject mode on
    end if;
    if Sltsl_C_n = '0' and V_stop = '1' and V_active /= "00" then 
      V_active <= V_active - "01"; -- inject mode off
    end if;
  end if; 
end process;    

process (Rd_n,pSltRst_n)
begin
  if pSltRst_n = '0' then
    V_stop <= '0';
  elsif (Rd_n'event and Rd_n = '1') then
    if pSltM1_n = '0' and V_active = "11" and Sltsl_C_n = '0' and pSltDat = "11000011" then -- C3h :JPXXXX:
    V_stop <= '1';
    end if;
  end if;
end process;  

----------------------------------------------------------------
-- Reset conditions
----------------------------------------------------------------
  pSltRst_n <= pSltRst1_n when RstEN = '1'
          else '0';

process (pSltClk_n,pSltRst1_n)
begin
  if pSltRst1_n = '0' then RstEN <= '0';
--  if pSltRst1_n = '0' then pSltRst_n <= '0';
--  if pSltClk_n'event and pSltClk_n = '1' then 
--    RstEN <= '1';
--  pSltRst_n <= pSltRst1_n;
  elsif pSltSltsls_n = '0' then RstEN <= '1';
  end if;
end process;

  pSltWait_n <= '1';
--
-- problem detector (test) :)
--  SDOpo <= '0' when SDOp = '1' or Key1_n = '0' else '1';
--  SDOp <= '1' when SDOc /= "0000111111111111"  else '0';
--  SDOpo <='0' when pSltIorq_n = '0' and pSltWr_n = '0'and pSltAdr(7 downto 0) = "10100001" else 'Z'; --#A0
  SDOpo <= pSltRst_n; --not KC; 
end RTL;