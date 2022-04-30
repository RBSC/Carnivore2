-- 
-- Controller.vhd 
-- The core controller module of VM2413
--
-- [Description]
--
-- The Controller is the beginning module of the OPLL slot calculation.
-- It manages register accesses from I/O and sends proper voice parameters 
-- to the succeding PhaseGenerator and EnvelopeGenerator modules. 
-- The one cycle of the Controller consists of 4 stages as follows.
-- 
-- 1st stage: 
--   * Prepare to read the register value for the current slot from RegisterMemory.
--   * Prepare to read the voice parameter for the current slot from VoiceMemory.
--   * Prepare to read the user-voice data from VoiceMemory.
--             
-- 2nd stage: 
--   * Wait for RegisterMemory and VoiceMemory
--
-- 3rd clock stage:
--   * Update register value if wr='1' and addr points the current OPLL channel.
--   * Update voice parameter if wr='1' and addr points the voice parameter area.
--   * Write register value to RegisterMemory.
--   * Write voice parameter to VoiceMemory.
--
-- 4th stage:
--   * Send voice and register parameters to PhaseGenerator and EnvelopeGenerator.
--   * Increment the number of the current slot.
--
-- Each stage is completed in one clock. Thus the Controller traverses all 18 opll 
-- slots in 72 clocks. 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity Controller is port (

  clk    : in std_logic;
  reset  : in std_logic;
  clkena : in std_logic;
  
  slot   : in SLOT_TYPE;
  stage  : in STAGE_TYPE;
  
  wr     : in std_logic;
  addr   : in std_logic_vector(7 downto 0);
  data   : in std_logic_vector(7 downto 0);
    
  -- Output Parameters for PhaseGenerator and EnvelopeGenerator
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

  -- slot_out : out SLOT_ID
);
end Controller;

architecture RTL of Controller is

  -- The array which caches instrument number of each channel.
  type INST_ARRAY is array (CH_TYPE'range) of integer range 0 to 15;
  signal inst_cache : INST_ARRAY;

  type KL_ARRAY is array (0 to 15) of std_logic_vector(5 downto 0);
  constant kl_table : KL_ARRAY :=
    ( "000000", "011000", "100000", "100101",
      "101000", "101011", "101101", "101111",
      "110000", "110010", "110011", "110100",
      "110101", "110110", "110111", "111000" ); -- 0.75dB/Step, 6dB/OCT

  component RegisterMemory port (
    clk    : in std_logic;
    reset  : in std_logic;
    addr   : in CH_TYPE;
    wr     : in std_logic;
    idata  : in REGS_TYPE;
    odata  : out REGS_TYPE );
  end component;
  
  component VoiceMemory port (
    clk    : in std_logic;
    reset  : in std_logic;
    idata  : in VOICE_TYPE;
    wr     : in std_logic;
    rwaddr : in VOICE_ID_TYPE;
    roaddr : in VOICE_ID_TYPE;
    odata  : out VOICE_TYPE;
    rodata : out VOICE_TYPE );
  end component;
  
  -- Signals for the READ-ONLY access ports of VoiceMemory module.
  signal slot_voice_addr : VOICE_ID_TYPE;
  signal slot_voice_data : VOICE_TYPE;
  
  -- Signals for the READ-WRITE access ports of VoiceMemory module.
  signal user_voice_wr    : std_logic;
  signal user_voice_addr  : VOICE_ID_TYPE;
  signal user_voice_rdata : VOICE_TYPE;
  signal user_voice_wdata : VOICE_TYPE;
  
  signal extra_mode : std_logic;
  
  -- Signals for the RegisterMemory module.
  signal regs_wr    : std_logic;
  signal regs_addr  : CH_TYPE;
  signal regs_rdata : REGS_TYPE;
  signal regs_wdata : REGS_TYPE;

begin  -- RTL

  RMEM : RegisterMemory port map (
      clk, reset, regs_addr, regs_wr, regs_wdata, regs_rdata
  );
    
  VMEM : VoiceMemory port map (
    clk, reset, user_voice_wdata, user_voice_wr, user_voice_addr, slot_voice_addr,
    user_voice_rdata, slot_voice_data );

  process (clk, reset)

    variable rflag : std_logic_vector(7 downto 0);
    variable kflag : std_logic;
    variable tll : std_logic_vector(DB_TYPE'high+1 downto 0);
    variable kll : std_logic_vector(DB_TYPE'high+1 downto 0);
    
    variable regs_tmp : REGS_TYPE;
    variable user_voice_tmp : VOICE_TYPE;
    
    variable fb_buf : FB_TYPE;
    variable wf_buf : WF_TYPE;
    
    variable extra_mode : std_logic;
    variable vindex : VOICE_ID_TYPE;

  begin  -- process
  
    if(reset = '1') then
      
      key  <= '0';
      rhythm <= '0';
      tll := (others=>'0');
      kll := (others=>'0');
      kflag := '0';
      rflag := (others=>'0');
      user_voice_wr <= '0';
      user_voice_addr <= 0;
      slot_voice_addr <= 0;
      regs_addr <= 0;
      regs_wr <='0';
      ar  <= (others=>'0');
      dr  <= (others=>'0');
      sl  <= (others=>'0');
      rr  <= (others=>'0');
      tl  <= (others=>'0');
      fb  <= (others=>'0');
      wf  <= '0';
      ml  <= (others=>'0');
      fnum <= (others=>'0');
      blk  <= (others=>'0');
      key  <= '0';
      rks  <= (others=>'0');
      rhythm <= '0';
      extra_mode := '0';
      vindex := 0;
      
    elsif clk'event and clk='1' then if clkena='1' then
    
      case stage is 
      --------------------------------------------------------------------------
      -- 1st stage (setting up a read request for Register and Voice memories.)
      --------------------------------------------------------------------------
      when 0 =>
        regs_addr <= slot/2;
        
        if rflag(5) = '1' and 12 <= slot then
		  slot_voice_addr <= slot - 12 + 32;          
        else
          slot_voice_addr <= inst_cache(slot/2) * 2 + slot mod 2;
        end if;
        
        if extra_mode = '0' then
          -- Alternately read modulator or carrior.
           vindex := slot mod 2;
        else
          if vindex = VOICE_ID_TYPE'high then
            vindex:= 0;
          else
            vindex:= vindex + 1;
          end if;
        end if;
        
        user_voice_addr <= vindex;        
        regs_wr <= '0';
        user_voice_wr <='0'; 
      
      --------------------------------------------------------------------------
      -- 2nd stage (just a wait for Register and Voice memories.)
      --------------------------------------------------------------------------
      when 1 =>
        null;      
      
      --------------------------------------------------------------------------
      -- 3rd stage (updating a register and voice parameters.)
      --------------------------------------------------------------------------
      when 2 =>
        
        if wr='1' then
        
          if ( extra_mode = '0' and CONV_INTEGER(addr) < 8 ) or 
             ( extra_mode = '1' and ( CONV_INTEGER(addr) - 64 ) / 8 = vindex / 2 ) then 
            
            -- Update user voice parameter.
            user_voice_tmp := user_voice_rdata;
          
            case addr(2 downto 1) is            
              when "00" =>
                if CONV_INTEGER(addr(0 downto 0)) = (vindex mod 2) then
                  user_voice_tmp.AM := data(7);
                  user_voice_tmp.PM := data(6);
                  user_voice_tmp.EG := data(5);
                  user_voice_tmp.KR := data(4);
                  user_voice_tmp.ML := data(3 downto 0);
                  user_voice_wr <= '1';
                end if;
                
              when "01" =>       
                if addr(0)='0' and (vindex mod 2 = 0) then
                  user_voice_tmp.KL := data(7 downto 6);
                  user_voice_tmp.TL := data(5 downto 0);
                  user_voice_wr <= '1';
                elsif addr(0)='1' and (vindex mod 2 = 0) then
                  user_voice_tmp.WF := data(3);
                  user_voice_tmp.FB := data(2 downto 0);
                  user_voice_wr <= '1';
                elsif addr(0)='1' and (vindex mod 2 = 1) then
                  user_voice_tmp.KL := data(7 downto 6);
                  user_voice_tmp.WF := data(4);
                  user_voice_wr <= '1';
                end if;
                
              when "10" =>
                if CONV_INTEGER(addr(0 downto 0)) = (vindex mod 2) then
                  user_voice_tmp.AR := data(7 downto 4);
                  user_voice_tmp.DR := data(3 downto 0);
                  user_voice_wr <= '1';
                end if;
                
              when "11" =>
                if CONV_INTEGER(addr(0 downto 0)) = (vindex mod 2) then
                  user_voice_tmp.SL := data(7 downto 4);
                  user_voice_tmp.RR := data(3 downto 0);
                  user_voice_wr <= '1';
                end if;                
            end case;

            user_voice_wdata <= user_voice_tmp;
            
          elsif CONV_INTEGER(addr) = 14 then
          
            rflag := data;
            
          elsif CONV_INTEGER(addr) < 16 then
          
            null;
            
          elsif CONV_INTEGER(addr) <= 56 then 
          
            if( CONV_INTEGER(addr(3 downto 0) ) = slot / 2 ) then
              regs_tmp := regs_rdata;
              case addr(5 downto 4) is 
                when "01" => -- register 0x10 to 0x18 (Lower 8bits of f-number)
                  regs_tmp.FNUM(7 downto 0) := data;
                  regs_wr <= '1';              
                when "10" => -- register 0x20 to 0x28 (Sustine, key and MSB of f-number)
                  regs_tmp.SUS := data(5);
                  regs_tmp.KEY := data(4);
                  regs_tmp.BLK := data(3 downto 1);
                  regs_tmp.FNUM(8) := data(0);
                  regs_wr <= '1';                  
                when "11" => -- register 0x30 to 0x38 (Instrument and volume)
                  regs_tmp.INST := data(7 downto 4);
                  regs_tmp.VOL := data(3 downto 0);
                  regs_wr <='1';
                when others =>
                  null;
              end case;
              regs_wdata <= regs_tmp;
            end if;
            
          elsif CONV_INTEGER(addr) = 240 then
          
            if data(7 downto 0) = "10000000" then
              extra_mode := '1';
            else
              extra_mode := '0';
            end if;
         
          end if;

        end if;
      
      --------------------------------------------------------------------------
      -- 4th stage (updating a register and voice parameters.)
      --------------------------------------------------------------------------
      when 3 =>

        -- Output slot number (for explicit synchonization with other units).
        -- slot_out <= slot;

        -- Updating Insturument Cache 
        inst_cache(slot/2) <= CONV_INTEGER(regs_rdata.INST);

        rhythm <= rflag(5);

        -- Updating rhythm status and key flag
        if rflag(5) = '1' and 12 <= slot then
          case slot is
            when 12 | 13 => -- BD
              kflag := rflag(4);
            when 14 => 			-- HH
              kflag := rflag(0);      
            when 15 => 			-- SD
              kflag := rflag(3);      
            when 16 => 			-- TOM
              kflag := rflag(2);      
            when 17 => 			-- CYM
              kflag := rflag(1); 
            when others => null;
          end case;
        else
          kflag := '0';
        end if;

        kflag := kflag or regs_rdata.KEY;

        -- Calculate key-scale attenuation amount.
	    kll := (("0"&kl_table(CONV_INTEGER(regs_rdata.FNUM(8 downto 5)))) 
		     - ("0"&("111"-regs_rdata.BLK)&"000")) & '0';
        
        if kll(kll'high) ='1' or slot_voice_data.KL = "00" then
          kll := (others=>'0');
        else
          kll := SHR(kll, "11" - slot_voice_data.KL );
        end if;	 

        -- Calculate base total level from volume register value.
        if rflag(5) = '1' and (slot = 14 or slot = 16) then -- HH and CYM
          tll := ('0' & regs_rdata.INST & "000");
        elsif (slot mod 2) = 0 then
          tll := ('0' & slot_voice_data.TL & '0'); -- MOD
        else
          tll := ('0' & regs_rdata.VOL & "000");     -- CAR
        end if;

        tll := tll + kll;
        
        if tll(tll'high) ='1' then
          tl <= (others=>'1');
        else
          tl <= tll(tl'range);
        end if;
        
        -- Output Rks, f-number, block and key-status.
        fnum <= regs_rdata.FNUM;
        blk  <= regs_rdata.BLK;        
        key  <= kflag;
        
        if rflag(5) = '1' and 14 <= slot then
          if slot_voice_data.KR = '1' then
            rks <= "0101";
          else
            rks <= "00" & regs_rdata.BLK(2 downto 1);
          end if;
        else 
          if slot_voice_data.KR = '1' then
            rks <= regs_rdata.BLK & regs_rdata.FNUM(8);
          else
            rks <= "00" & regs_rdata.BLK(2 downto 1);
          end if;
        end if;
        
        -- Output voice parameters
        -- Note that WF and FB output MUST keep its value
        -- at least 3 clocks since the Operator module will fetch
        -- the WF and FB 2 clocks later of this stage.
        am <= slot_voice_data.AM;
        pm <= slot_voice_data.PM;
        ml <= slot_voice_data.ML;
        wf_buf := slot_voice_data.WF;
        fb_buf := slot_voice_data.FB;
        wf <= wf_buf;
        fb <= fb_buf;
        ar <= slot_voice_data.AR;
        dr <= slot_voice_data.DR;
        sl <= slot_voice_data.SL;

        -- Output release rate (depends on the sustine and envelope type).
        if( kflag = '1' ) then -- Key on        
          if slot_voice_data.EG = '1' then
            rr <= "0000";
          else
            rr <= slot_voice_data.RR;
          end if;       
        else -- Key off
          if (slot mod 2) = 0 and not ( rflag(5) = '1' and (7 <= slot/2) ) then
            rr  <= "0000";
          elsif regs_rdata.SUS = '1' then
            rr  <= "0101";
          elsif slot_voice_data.EG = '0' then
            rr  <= "0111";
          else
            rr  <= slot_voice_data.RR;	     
          end if;
        end if;       
        
      end case;
    
    end if; end if;

  end process;

end RTL;
