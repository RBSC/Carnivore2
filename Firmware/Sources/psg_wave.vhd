-- 
-- psg_wave.vhd
--   Programmable Sound Generator (AY-3-8910/YM2149)
--   Revision 1.00
-- 
-- Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
-- All rights reserved.
-- 
-- Redistribution and use of this source code or any derivative works, are 
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, 
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright 
--    notice, this list of conditions and the following disclaimer in the 
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial 
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- fix caro 17/05/2013 
-- adapted for mscc 03/12/2017

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity psg_wave is
  port(
    pSltClk_n  : in std_logic;
    pSltRst_n   : in std_logic;
--    clkena  : in std_logic;
--    req     : in std_logic;
--    ack     : out std_logic;
--    wrt     : in std_logic;
--    adr     : in std_logic_vector(15 downto 0);
--    dbi     : out std_logic_vector(7 downto 0);
    PsgRegPtr   : IN std_logic_vector(3 downto 0);
    pSltDat     : IN std_logic_vector(7 downto 0);    
--    dbo     : in std_logic_vector(7 downto 0);
    PsgAmp    : out std_logic_vector(9 downto 0); -- fix caro
    PsgRegWe : in std_logic
  );
end psg_wave;

architecture rtl of psg_wave is

  signal PsgClkEna   : std_logic_vector(4 downto 0);
--  signal PsgRegPtr   : std_logic_vector(3 downto 0);

  signal PsgEdgeChA  : std_logic;
  signal PsgEdgeChB  : std_logic;
  signal PsgEdgeChC  : std_logic;
  signal PsgNoise    : std_logic;
  signal PsgVolEnv   : std_logic_vector(3 downto 0);
  signal PsgEnvReq   : std_logic;
  signal PsgEnvAck   : std_logic;

  signal PsgFreqChA  : std_logic_vector(11 downto 0);
  signal PsgFreqChB  : std_logic_vector(11 downto 0);
  signal PsgFreqChC  : std_logic_vector(11 downto 0);
  signal PsgFreqNoise: std_logic_vector(4 downto 0);
  signal PsgChanSel  : std_logic_vector(5 downto 0);
  signal PsgVolChA   : std_logic_vector(4 downto 0);
  signal PsgVolChB   : std_logic_vector(4 downto 0);
  signal PsgVolChC   : std_logic_vector(4 downto 0);
  signal PsgFreqEnv  : std_logic_vector(15 downto 0);
  signal PsgShapeEnv : std_logic_vector(3 downto 0);

  alias hold   : std_logic is PsgShapeEnv(0);
  alias alter  : std_logic is PsgShapeEnv(1);
  alias attack : std_logic is PsgShapeEnv(2);
  alias cont   : std_logic is PsgShapeEnv(3);

begin
  ----------------------------------------------------------------
  -- Miscellaneous control / clock enable (divider)
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
  begin
    if (pSltRst_n = '0') then
      PsgClkEna <= (others => '0');
    elsif (pSltClk_n'event and pSltClk_n = '1') then
--      if (clkena = '1') then
        PsgClkEna <= PsgClkEna - 1;
--      end if;
    end if;
  end process;
--  ack <= req;
  ----------------------------------------------------------------
  -- PSG register read
  ----------------------------------------------------------------
  --dbi <=          PsgFreqChA( 7 downto 0) when PsgRegPtr = "0000" and adr(1 downto 0) = "10" else
  --       "0000" & PsgFreqChA(11 downto 8) when PsgRegPtr = "0001" and adr(1 downto 0) = "10" else
  --                PsgFreqChB( 7 downto 0) when PsgRegPtr = "0010" and adr(1 downto 0) = "10" else
  --       "0000" & PsgFreqChB(11 downto 8) when PsgRegPtr = "0011" and adr(1 downto 0) = "10" else
  --                PsgFreqChC( 7 downto 0) when PsgRegPtr = "0100" and adr(1 downto 0) = "10" else
  --      "0000" & PsgFreqChC(11 downto 8) when PsgRegPtr = "0101" and adr(1 downto 0) = "10" else
  --       "000"  & PsgFreqNoise            when PsgRegPtr = "0110" and adr(1 downto 0) = "10" else
  --       "10"   & PsgChanSel              when PsgRegPtr = "0111" and adr(1 downto 0) = "10" else
  --       "000"  & PsgVolChA               when PsgRegPtr = "1000" and adr(1 downto 0) = "10" else
  --       "000"  & PsgVolChB               when PsgRegPtr = "1001" and adr(1 downto 0) = "10" else
  --       "000"  & PsgVolChC               when PsgRegPtr = "1010" and adr(1 downto 0) = "10" else
  --                PsgFreqEnv(7 downto 0)  when PsgRegPtr = "1011" and adr(1 downto 0) = "10" else
  --                PsgFreqEnv(15 downto 8) when PsgRegPtr = "1100" and adr(1 downto 0) = "10" else
  --       "0000" & PsgShapeEnv             when PsgRegPtr = "1101" and adr(1 downto 0) = "10" else
  --       (others => '1');
  ----------------------------------------------------------------
  -- PSG register write
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
  begin
    if (pSltRst_n = '0') then
--      PsgRegPtr    <= (others => '0');
      PsgFreqChA   <= (others => '1');
      PsgFreqChB   <= (others => '1');
      PsgFreqChC   <= (others => '1');
      PsgFreqNoise <= (others => '1');
      PsgChanSel   <= (others => '1');
      PsgVolChA    <= (others => '1');
      PsgVolChB    <= (others => '1');
      PsgVolChC    <= (others => '1');
      PsgFreqEnv   <= (others => '1');
      PsgShapeEnv  <= (others => '1');
      PsgEnvReq    <= '0';
    elsif (pSltClk_n'event and pSltClk_n = '1') then
--      if (req = '1' and wrt = '1' and adr(1 downto 0) = "00") then
--        -- register pointer
--        PsgRegPtr <= dbo(3 downto 0);
--      elsif (req = '1' and wrt = '1' and adr(1 downto 0) = "01") then
        -- PSG registers
      if (PsgRegWe = '1') then
        case PsgRegPtr is
          when "0000" => PsgFreqChA(7 downto 0)  <= pSltDat;
          when "0001" => PsgFreqChA(11 downto 8) <= pSltDat(3 downto 0);
          when "0010" => PsgFreqChB(7 downto 0)  <= pSltDat;
          when "0011" => PsgFreqChB(11 downto 8) <= pSltDat(3 downto 0);
          when "0100" => PsgFreqChC(7 downto 0)  <= pSltDat;
          when "0101" => PsgFreqChC(11 downto 8) <= pSltDat(3 downto 0);
          when "0110" => PsgFreqNoise            <= pSltDat(4 downto 0);
          when "0111" => PsgChanSel              <= pSltDat(5 downto 0);
          when "1000" => PsgVolChA               <= pSltDat(4 downto 0);
          when "1001" => PsgVolChB               <= pSltDat(4 downto 0);
          when "1010" => PsgVolChC               <= pSltDat(4 downto 0);
          when "1011" => PsgFreqEnv(7 downto 0)  <= pSltDat;
          when "1100" => PsgFreqEnv(15 downto 8) <= pSltDat;
          when "1101" => PsgShapeEnv             <= pSltDat(3 downto 0); PsgEnvReq <= not PsgEnvAck;
          when others => null;
        end case;
      end if;
    end if;
  end process;
  ----------------------------------------------------------------
  -- Tone generator
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
    variable PsgCntChA : std_logic_vector(11 downto 0);
    variable PsgCntChB : std_logic_vector(11 downto 0);
    variable PsgCntChC : std_logic_vector(11 downto 0);
  begin
    if (pSltRst_n = '0') then
      PsgEdgeChA <= '0';
      PsgCntChA  := (others => '0');
      PsgEdgeChB <= '0';
      PsgCntChB  := (others => '0');
      PsgEdgeChC <= '0';
      PsgCntChC  := (others => '0');
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      -- Base frequency : 112kHz = 3.58MHz / 16 / 2
      if (PsgClkEna(3 downto 0) = "0000" ) then --and clkena = '1') then
        if (PsgCntChA /= X"000") then
          PsgCntChA := PsgCntChA - 1;
        elsif (PsgFreqChA /= X"000") then
          PsgCntChA := PsgFreqChA - 1;
        end if;
        if (PsgCntChA = X"000") and (PsgFreqChA /= X"000") then -- fix caro
          PsgEdgeChA <= not PsgEdgeChA;
        end if;
        if (PsgCntChB /= X"000") then
          PsgCntChB := PsgCntChB - 1;
        elsif (PsgFreqChB /= X"000") then
          PsgCntChB := PsgFreqChB - 1;
        end if;
        if (PsgCntChB = X"000") and (PsgFreqChB /= X"000") then -- fix caro
          PsgEdgeChB <= not PsgEdgeChB;
        end if;
        if (PsgCntChC /= X"000") then
          PsgCntChC := PsgCntChC - 1;
        elsif (PsgFreqChC /= X"000") then
          PsgCntChC := PsgFreqChC - 1;
        end if;
        if (PsgCntChC = X"000") and (PsgFreqChC /= X"000") then -- fix caro
          PsgEdgeChC <= not PsgEdgeChC;
        end if;
      end if;
    end if;
  end process;
  ----------------------------------------------------------------
  -- Noise generator 
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
    variable PsgCntNoise : std_logic_vector(4 downto 0);
    variable PsgGenNoise : std_logic_vector(17 downto 0);
  begin
    if (pSltRst_n = '0') then
      PsgCntNoise := (others => '0');
      PsgGenNoise := "011111111111111110";
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      -- Base frequency : 112kHz = 3.58MHz / 32
      if (PsgClkEna(4 downto 0) = "00000") then -- and clkena = '1') then
        -- Noise frequency counter
        if (PsgCntNoise /= "00000") then
          PsgCntNoise := PsgCntNoise - 1;
        elsif (PsgFreqNoise /= "00000") then
          PsgCntNoise := PsgFreqNoise - 1;
          -- (Maximum-length linear shift register sequence)
          -- f(x) = x^17 + x^14 + 1
            for I in 17 downto 1 loop
              PsgGenNoise(I) := PsgGenNoise(I - 1);
            end loop;
              PsgGenNoise(0) := not(PsgGenNoise(17) xor PsgGenNoise(14)); -- fix caro
        end if;
      end if;
    end if;
    PsgNoise <= PsgGenNoise(17);
  end process;
  ----------------------------------------------------------------
  -- Envelope generator
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
    variable PsgCntEnv : std_logic_vector(15 downto 0);
    variable PsgPtrEnv : std_logic_vector(4 downto 0);
  begin
    if (pSltRst_n = '0') then
      PsgCntEnv := (others => '0');
      PsgPtrEnv := (others => '1');
      PsgVolEnv <= (others => '0');
      PsgEnvAck <= '0';
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      -- Envelope base frequency : 56kHz = 3.58MHz / 32 / 2
      if (PsgClkEna(4 downto 0) = "00000") then -- and clkena = '1') then
        -- Envelope period counter
        if (PsgCntEnv /= X"0000" and PsgEnvReq = PsgEnvAck) then
          PsgCntEnv := PsgCntEnv - 1;
        elsif (PsgFreqEnv /= X"0000") then
          PsgCntEnv := PsgFreqEnv - 1;
        end if;
        -- Envelope phase counter
        if (PsgEnvReq /= PsgEnvAck) then
          PsgPtrEnv := (others => '1');
        elsif (PsgCntEnv = X"0000" and (PsgPtrEnv(4) = '1' or (hold = '0' and cont = '1'))) then
          PsgPtrEnv := PsgPtrEnv - 1;
        end if;
        -- Envelope amplitude control
        for I in 3 downto 0 loop
          if (PsgPtrEnv(4) = '0' and cont = '0') then
            PsgVolEnv(I) <= '0';
          elsif (PsgPtrEnv(4) = '1' or (alter xor hold) = '0') then
            PsgVolEnv(I) <= PsgPtrEnv(I) xor attack;
          else
            PsgVolEnv(I) <= PsgPtrEnv(I) xor attack xor '1';
          end if;
        end loop;
        PsgEnvAck <= PsgEnvReq;
      end if;
    end if;
  end process;
  ----------------------------------------------------------------
  -- Mixer control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)
    variable PsgEnaNoise : std_logic;
    variable PsgEnaTone  : std_logic;
    variable PsgEdge     : std_logic;
    variable PsgVol      : std_logic_vector(4 downto 0);
    variable PsgIndex    : std_logic_vector(3 downto 0);
    variable PsgTable    : std_logic_vector(7 downto 0);
    variable PsgMix      : std_logic_vector(9 downto 0);
  begin
    if (pSltRst_n = '0') then
      PsgMix := (others => '0');
      PsgAmp   <= (others => '0');
    elsif (pSltClk_n'event and pSltClk_n = '1') then
      case PsgClkEna(1 downto 0) is
        when "11"   =>
          PsgEnaTone  := PsgChanSel(0); PsgEdge  := PsgEdgeChA;
          PsgEnaNoise := PsgChanSel(3); PsgVol   := PsgVolChA;
        when "10"   =>
          PsgEnaTone  := PsgChanSel(1); PsgEdge  := PsgEdgeChB;
          PsgEnaNoise := PsgChanSel(4); PsgVol   := PsgVolChB;
        when "01"   =>
          PsgEnaTone  := PsgChanSel(2); PsgEdge  := PsgEdgeChC;
          PsgEnaNoise := PsgChanSel(5); PsgVol   := PsgVolChC;
        when others =>
          PsgEnaTone  := '1';           PsgEdge  := '1';
          PsgEnaNoise := '1';           PsgVol   := "00000";
      end case;
      if (((PsgEnaTone or PsgEdge) and (PsgEnaNoise or PsgNoise)) = '0') then
        PsgIndex := (others => '0');
      elsif (PsgVol(4) = '0') then
        PsgIndex := PsgVol(3 downto 0);
      else
        PsgIndex := PsgVolEnv;
      end if;
      case PsgIndex is
        when "1111" => PsgTable := "11111111";
        when "1110" => PsgTable := "10110100";
        when "1101" => PsgTable := "01111111";
        when "1100" => PsgTable := "01011010";
        when "1011" => PsgTable := "00111111";
        when "1010" => PsgTable := "00101101";
        when "1001" => PsgTable := "00011111";
        when "1000" => PsgTable := "00010110";
        when "0111" => PsgTable := "00001111";
        when "0110" => PsgTable := "00001011";
        when "0101" => PsgTable := "00000111";
        when "0100" => PsgTable := "00000101";
        when "0011" => PsgTable := "00000011";
        when "0010" => PsgTable := "00000010";
        when "0001" => PsgTable := "00000001";
        when others => PsgTable := "00000000";
      end case;
--      if (clkena = '1') then
        case PsgClkEna(1 downto 0) is
          when "00"   => PsgAmp   <= PsgMix(9 downto 0); -- fix caro
                         PsgMix(9 downto 0) := (others => '0');
          when others => PsgMix := "00" & PsgTable + PsgMix;
        end case;
--      end if;
    end if;
  end process;
end rtl;
