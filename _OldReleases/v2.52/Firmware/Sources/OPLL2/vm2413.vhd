-- 
-- VM2413.vhd 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package VM2413 is

  constant MAXCH   : integer := 9;
  constant MAXSLOT : integer := MAXCH * 2;

  subtype CH_TYPE is integer range 0 to MAXCH-1;
  subtype SLOT_TYPE is integer range 0 to MAXSLOT-1;
  subtype STAGE_TYPE is integer range 0 to 3;
  
  subtype REGS_VECTOR_TYPE is std_logic_vector(23 downto 0);
  
  type REGS_TYPE is record
    INST : std_logic_vector(3 downto 0);
    VOL : std_logic_vector(3 downto 0);
    SUS : std_logic;
    KEY : std_logic;
    BLK : std_logic_vector(2 downto 0);
    FNUM : std_logic_vector(8 downto 0);
  end record;

  function CONV_REGS_VECTOR ( regs : REGS_TYPE ) return REGS_VECTOR_TYPE;
  function CONV_REGS ( vec : REGS_VECTOR_TYPE ) return REGS_TYPE; 

  subtype VOICE_ID_TYPE is integer range 0 to 37;
  subtype VOICE_VECTOR_TYPE is std_logic_vector(35 downto 0);

  type VOICE_TYPE is record
    AM, PM, EG, KR : std_logic;
    ML : std_logic_vector(3 downto 0);
    KL : std_logic_vector(1 downto 0);
    TL : std_logic_vector(5 downto 0);
    WF : std_logic;
    FB : std_logic_vector(2 downto 0);
    AR, DR, SL, RR : std_logic_vector(3 downto 0);
  end record;
  
  function CONV_VOICE_VECTOR ( inst : VOICE_TYPE ) return VOICE_VECTOR_TYPE;
  function CONV_VOICE ( inst_vec : VOICE_VECTOR_TYPE ) return VOICE_TYPE; 

  -- Voice Parameter Types
  subtype AM_TYPE is std_logic; -- AM switch - '0':off  '1':3.70Hz
  subtype PM_TYPE is std_logic; -- PM switch - '0':stop '1':6.06Hz
  subtype EG_TYPE is std_logic; -- Envelope type - '0':release '1':sustine
  subtype KR_TYPE is std_logic; -- Keyscale Rate
  subtype ML_TYPE is std_logic_vector(3 downto 0); -- Multiple
  subtype WF_TYPE is std_logic; -- WaveForm - '0':sine '1':half-sine 
  subtype FB_TYPE is std_logic_vector(2 downto 0); -- Feedback
  subtype AR_TYPE is std_logic_vector(3 downto 0); -- Attack Rate
  subtype DR_TYPE is std_logic_vector(3 downto 0); -- Decay Rate
  subtype SL_TYPE is std_logic_vector(3 downto 0); -- Sustine Level
  subtype RR_TYPE is std_logic_vector(3 downto 0); -- Release Rate
  
  -- F-Number, Block and Rks(Rate and key-scale) types
  subtype BLK_TYPE  is std_logic_vector(2 downto 0); -- Block    
  subtype FNUM_TYPE is std_logic_vector(8 downto 0); -- F-Number
  subtype RKS_TYPE is std_logic_vector(3 downto 0);  -- Rate-KeyScale
  
  -- 18 bits phase counter
  subtype PHASE_TYPE is std_logic_vector (17 downto 0);
  -- Phage generator's output
  subtype PGOUT_TYPE is std_logic_vector (8 downto 0);
  -- Final linear output of opll
  subtype LI_TYPE is std_logic_vector (8 downto 0); -- Wave in Linear
  -- Total Level and Envelope output
  subtype DB_TYPE is std_logic_vector(6 downto 0);  -- Wave in dB, Reso: 0.375dB
  
  subtype SIGNED_LI_VECTOR_TYPE is std_logic_vector(LI_TYPE'high + 1 downto 0);
  type SIGNED_LI_TYPE is record
    sign : std_logic;
    value : LI_TYPE;
  end record;
  function CONV_SIGNED_LI_VECTOR( li : SIGNED_LI_TYPE ) return SIGNED_LI_VECTOR_TYPE;
  function CONV_SIGNED_LI( vec : SIGNED_LI_VECTOR_TYPE ) return SIGNED_LI_TYPE;

  subtype SIGNED_DB_VECTOR_TYPE is std_logic_vector(DB_TYPE'high + 1 downto 0);
  type SIGNED_DB_TYPE is record
    sign : std_logic;
    value : DB_TYPE;
  end record;
  function CONV_SIGNED_DB_VECTOR( db : SIGNED_DB_TYPE ) return SIGNED_DB_VECTOR_TYPE;
  function CONV_SIGNED_DB( vec : SIGNED_DB_VECTOR_TYPE ) return SIGNED_DB_TYPE;
  
  -- Envelope generator states
  subtype EGSTATE_TYPE is std_logic_vector(1 downto 0);

  constant Attack  : EGSTATE_TYPE := "01";
  constant Decay   : EGSTATE_TYPE := "10";
  constant Release : EGSTATE_TYPE := "11";
  constant Finish  : EGSTATE_TYPE := "00";
  
  -- Envelope generator phase
  subtype EGPHASE_TYPE is std_logic_vector(22 downto 0); 
  
  -- Envelope data (state and phase)
  type EGDATA_TYPE is record 
    state : EGSTATE_TYPE;
    phase : EGPHASE_TYPE;
  end record; 
  
  subtype EGDATA_VECTOR_TYPE is std_logic_vector(EGSTATE_TYPE'high + EGPHASE_TYPE'high + 1 downto 0);    
  
  function CONV_EGDATA_VECTOR( data : EGDATA_TYPE ) return EGDATA_VECTOR_TYPE;
  function CONV_EGDATA( vec : EGDATA_VECTOR_TYPE ) return EGDATA_TYPE;

  component Opll port(
    XIN     : in std_logic;                       
    XOUT    : out std_logic;
    XENA    : in std_logic;
    D       : in std_logic_vector(7 downto 0); 
    A       : in std_logic;                       
    CS_n    : in std_logic;                       
    WE_n    : in std_logic;
    IC_n    : in std_logic;
    MO      : out std_logic_vector(9 downto 0);
    RO      : out std_logic_vector(9 downto 0)
  );    
  end component;

  component Controller port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;
    
    slot   : in SLOT_TYPE;
    stage  : in STAGE_TYPE;
  
    wr     : in std_logic;
    addr   : in std_logic_vector(7 downto 0);
    data   : in std_logic_vector(7 downto 0);
    
    am     : out AM_TYPE;
    pm     : out PM_TYPE;
    wf     : out WF_TYPE;
    ml     : out ML_TYPE;
    tl     : out DB_TYPE;
    fb     : out FB_TYPE;
    ar     : out AR_TYPE;
    dr     : out DR_TYPE;
    sl     : out SL_TYPE;
    rr     : out RR_TYPE;
    blk    : out BLK_TYPE;
    fnum   : out FNUM_TYPE;
    rks    : out RKS_TYPE;    
    key    : out std_logic;
    rhythm : out std_logic
  );
  end component;

  -- Slot and stage counter
  component SlotCounter 
    generic (
      DELAY : integer range 0 to MAXSLOT*4-1
    );
    port(
      clk    : in std_logic;
      reset  : in std_logic;
      clkena : in std_logic;
      slot   : out SLOT_TYPE;
      stage  : out STAGE_TYPE
    );
  end component;

  component EnvelopeGenerator 
    port (  
      clk    : in std_logic;
      reset  : in std_logic;
      clkena : in std_logic;
    
      slot   : in SLOT_TYPE;
      stage  : in STAGE_TYPE;
	  rhythm : in std_logic;

      am     : in AM_TYPE;
      tl     : in DB_TYPE;
      ar     : in AR_TYPE;
      dr     : in DR_TYPE;
      sl     : in SL_TYPE;
      rr     : in RR_TYPE;
      rks    : in RKS_TYPE;
      key    : in std_logic;

      egout  : out DB_TYPE    
    );
  end component;
  
  component PhaseGenerator port (
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
  end component;
  
  component Operator port (
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
  end component;
  
  component OutputGenerator port (
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
  end component;
  
  component TemporalMixer port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;
    
    slot   : in SLOT_TYPE;
    stage  : in STAGE_TYPE;

    rhythm : in std_logic;
    
    maddr : out SLOT_TYPE;
    mdata : in SIGNED_LI_TYPE;
    
  --  mo : out std_logic_vector(9 downto 0);
  --  ro : out std_logic_vector(9 downto 0);
    BCMO		: out std_logic_vector(15 downto 0);
	BCRO 		: out std_logic_vector(15 downto 0);
	SDO			: out std_logic
  );	    
  end component;
 
end VM2413;

package body VM2413 is

  function CONV_REGS_VECTOR ( regs : REGS_TYPE ) return REGS_VECTOR_TYPE is
  begin
    return  regs.INST & regs.VOL & "00" & regs.SUS & regs.KEY & regs.BLK & regs.FNUM;
  end CONV_REGS_VECTOR;
  
  function CONV_REGS ( vec : REGS_VECTOR_TYPE ) return REGS_TYPE is
  begin
    return ( 
      INST=>vec(23 downto 20), VOL=>vec(19 downto 16),
      SUS=>vec(13), KEY=>vec(12), BLK=>vec(11 downto 9), FNUM=>vec(8 downto 0)
      );
  end CONV_REGS;  

  function CONV_VOICE_VECTOR ( inst : VOICE_TYPE ) return VOICE_VECTOR_TYPE is
  begin
    return inst.AM & inst.PM & inst.EG & inst.KR & 
           inst.ML & inst.KL & inst.TL & inst.WF & inst.FB & 
           inst.AR & inst.DR & inst.SL & inst.RR;
  end CONV_VOICE_VECTOR;
  
  function CONV_VOICE ( inst_vec : VOICE_VECTOR_TYPE ) return VOICE_TYPE is
  begin
    return ( 
      AM=>inst_vec(35), PM=>inst_vec(34), EG=>inst_vec(33), KR=>inst_vec(32),
      ML=>inst_vec(31 downto 28), KL=>inst_vec(27 downto 26), TL=>inst_vec(25 downto 20),
      WF=>inst_vec(19), FB=>inst_vec(18 downto 16),
      AR=>inst_vec(15 downto 12), DR=>inst_vec(11 downto 8), SL=>inst_vec(7 downto 4), RR=>inst_vec(3 downto 0)
      );
  end CONV_VOICE;

  function CONV_SIGNED_LI_VECTOR( li : SIGNED_LI_TYPE ) return SIGNED_LI_VECTOR_TYPE is
  begin
    return li.sign & li.value;
  end;

  function CONV_SIGNED_LI( vec : SIGNED_LI_VECTOR_TYPE ) return SIGNED_LI_TYPE is
  begin
    return ( sign => vec(vec'high), value=>vec(vec'high-1 downto 0) );
  end;

  function CONV_SIGNED_DB_VECTOR( db : SIGNED_DB_TYPE ) return SIGNED_DB_VECTOR_TYPE is
  begin
    return db.sign & db.value;
  end;

  function CONV_SIGNED_DB( vec : SIGNED_DB_VECTOR_TYPE ) return SIGNED_DB_TYPE is
  begin
    return ( sign => vec(vec'high), value=>vec(vec'high-1 downto 0) );
  end;
  
  function CONV_EGDATA_VECTOR( data : EGDATA_TYPE ) return EGDATA_VECTOR_TYPE is
  begin
    return data.state & data.phase;
  end;
  
  function CONV_EGDATA( vec : EGDATA_VECTOR_TYPE ) return EGDATA_TYPE is
  begin
    return ( state => vec(vec'high downto EGPHASE_TYPE'high + 1),
             phase => vec(EGPHASE_TYPE'range) );
  end;
  
end VM2413;
