-- 
-- EnvelopeGenerator.vhd 
-- The envelope generator module of VM2413
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity EnvelopeGenerator is
port (clk    : in std_logic;
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
	       
      egout  : out DB_TYPE);
end EnvelopeGenerator;

architecture RTL of EnvelopeGenerator is

  component EnvelopeMemory port (
    clk     : in std_logic;
    reset   : in std_logic;
  
    waddr   : in SLOT_TYPE;
    wr      : in std_logic;
    wdata   : in EGDATA_TYPE;
    raddr   : in SLOT_TYPE;
    rdata   : out EGDATA_TYPE
    );
  end component;
  
  component AttackTable port (
    clk     : in std_logic;
    addr    : in integer range 0 to 2 ** (DB_TYPE'high+1) - 1;
    data    : out DB_TYPE
    );
  end component;

  signal rslot : SLOT_TYPE;
  signal memin, memout : EGDATA_TYPE;  
  signal memwr : std_logic;
  
  signal aridx : integer range 0 to 2 ** (DB_TYPE'high+1) - 1;
  signal ardata : DB_TYPE;

begin

  ARTBL : AttackTable port map ( clk, aridx, ardata );
  EGMEM : EnvelopeMemory port map ( clk, reset, slot, memwr, memin, rslot, memout );

  process(clk, reset)
  
    variable lastkey : std_logic_vector(MAXSLOT-1 downto 0);
    variable rm : std_logic_vector(4 downto 0);
    variable egtmp : std_logic_vector(DB_TYPE'high + 2 downto 0);
    variable ntable : std_logic_vector(17 downto 0);
    variable amphase : std_logic_vector(19 downto 0);
    variable rslot_buf : SLOT_TYPE;    
    variable egphase : EGPHASE_TYPE;
    variable egstate : EGSTATE_TYPE;
    variable dphase : EGPHASE_TYPE;
    
  begin

    if(reset = '1') then
    
      rm := (others=>'0');
	  lastkey := (others=>'0');
      ntable  := (others=>'1');
      amphase(amphase'high downto amphase'high-4) := "00001";
      amphase(amphase'high-5 downto 0) := (others=>'0');
      memwr <= '0';
      egstate := Finish;
      egphase := (others=>'0');
      rslot_buf := 0;

    elsif(clk'event and clk='1') then if clkena ='1' then

      -- White noise generator
      for I in 17 downto 1 loop
        ntable(I) := ntable(I-1);
      end loop;
      ntable(0) := ntable(17) xor ntable(14);

	  -- Amplitude oscillator ( -4.8dB to 0dB , 3.7Hz )
	  amphase := amphase + '1';
	  if amphase(amphase'high downto amphase'high-4) = "11111" then
        amphase(amphase'high downto amphase'high-4) := "00001";
      end if;

      if stage = 0 then
      
        egstate := memout.state;
        egphase := memout.phase;
        aridx <= CONV_INTEGER( egphase( egphase'high-1 downto egphase'high-7 ) );
      
      elsif stage = 1 then
      
        -- Wait for AttackTable
      
      elsif stage = 2 then 
      
        case egstate is
	      when Attack => 
	        rm := '0'&ar;
   	        egtmp := ("00"&tl) + ("00"&ardata);
          when Decay  => 
            rm := '0'&dr;
   	        egtmp := ("00"&tl) + ("00"&egphase(egphase'high-1 downto egphase'high-7));
          when Release=> 
            rm := '0'&rr;
   	        egtmp := ("00"&tl) + ("00"&egphase(egphase'high-1 downto egphase'high-7));
          when Finish => 
            egtmp(egtmp'high downto egtmp'high -1) := "00";
            egtmp(egtmp'high-2 downto 0) := (others=>'1');
        end case;
        
        -- SD and HH
 	    if ntable(0)='1' and slot/2 = 7 and rhythm = '1' then
	      egtmp := egtmp + "010000000";
        end if;

	    -- Amplitude LFO
	    if am ='1' then
          if (amphase(amphase'high) = '0') then
	        egtmp := egtmp + ("00000"&(amphase(amphase'high-1 downto amphase'high-4)-'1'));
          else
	        egtmp := egtmp + ("00000"&("1111"-amphase(amphase'high-1 downto amphase'high-4)));
	      end if;
        end if;
        
	    -- Generate output
        if egtmp(egtmp'high downto egtmp'high-1) = "00" then
	      egout <= egtmp(egout'range); 
        else
	      egout <= (others=>'1');
        end if;
	   
        if rm /= "00000" then
          
          rm := rm + rks(3 downto 2);
          if rm(rm'high)='1' then 
            rm(3 downto 0):="1111"; 
          end if;
          
          case egstate is          
            when Attack =>
              dphase(dphase'high downto 5) := (others=>'0');
              dphase(5 downto 0) := "110" * ('1'&rks(1 downto 0));
              dphase := SHL( dphase, rm(3 downto 0) );
              egphase := egphase - dphase(egphase'range);             
            when Decay | Release =>
              dphase(dphase'high downto 3) := (others=>'0');
              dphase(2 downto 0) := '1'&rks(1 downto 0);
              dphase  := SHL(dphase, rm(3 downto 0) - '1');              
              egphase := egphase + dphase(egphase'range);              
            when Finish =>
              null;
          end case;
                   
        end if;

        case egstate is        
          when Attack =>          
            if egphase(egphase'high) = '1' then
              egphase := (others=>'0');
              egstate := Decay;
            end if;
          when Decay =>          
		    if egphase(egphase'high downto egphase'high-4) >= '0'&sl then
              egstate := Release;
            end if;
		  when Release =>
		    if( egphase(egphase'high downto egphase'high-4) >= "01111" ) then
		      egstate:= Finish;
		    end if;
          when Finish => 
            egphase := (others => '1');            
        end case;

        if lastkey(slot) = '0' and key = '1' then
          egphase(egphase'high):= '0';
		  egphase(egphase'high-1 downto 0) := (others =>'1');
		  egstate:= Attack;		
        elsif lastkey(slot) = '1' and key = '0' and egstate /= Finish then
	      egstate:= Release;	
	    end if;	
	    lastkey(slot) := key;

        -- update phase and state memory
	    memin <= ( state => egstate, phase => egphase );
        memwr <='1';
       
        -- read phase of next slot (prefetch)
        if slot = 17 then
          rslot_buf := 0;
        else
          rslot_buf := slot + 1;
        end if;       
        rslot <= rslot_buf;

      elsif stage = 3 then
        
        -- wait for phase memory      
        memwr <='0';
        
      end if;
	 
    end if; end if;
        
  end process;

end RTL;

