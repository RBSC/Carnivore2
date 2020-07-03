----------------------------------------------------------------
--  Title     : scc_wave.vhd
--  Function  : Sound Creation Chip (KONAMI)
--  Date      : 28th,August,2000
--  Revision  : 1.01
--  Author    : Kazuhiro TSUJIKAWA (ESE Artists' factory)
----------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity scc_wave is
  port(
    pSltClk_n   : IN std_logic;
    pSltRst_n   : IN std_logic;
    pSltAdr     : IN std_logic_vector(7 downto 0);
    pSltDat     : INOUT std_logic_vector(7 downto 0);
    SccAmp      : OUT std_logic_vector(10 downto 0);

    SccRegWe    : IN std_logic;
    SccModWe    : IN std_logic;
    SccWavCe    : IN std_logic;
    SccWavOe    : IN std_logic;
    SccWavWe    : IN std_logic;
    SccWavWx    : IN std_logic;
    SccWavAdr   : IN std_logic_vector(4 downto 0);
    SccWavDat   : IN std_logic_vector(7 downto 0);
    DOutEn_n	: IN std_logic;
    DOut		: INOUT std_logic_vector(7 downto 0)
 );
end scc_wave;

architecture RTL of scc_wave is

  -- Wave memory control
  signal WaveWe      : std_logic;
  signal WaveAdr     : std_logic_vector(7 downto 0);
  signal iWaveDat    : std_logic_vector(7 downto 0);
  signal oWaveDat    : std_logic_vector(7 downto 0);

  -- SCC resisters
  signal SccFreqChA  : std_logic_vector(11 downto 0);
  signal SccFreqChB  : std_logic_vector(11 downto 0);
  signal SccFreqChC  : std_logic_vector(11 downto 0);
  signal SccFreqChD  : std_logic_vector(11 downto 0);
  signal SccFreqChE  : std_logic_vector(11 downto 0);
  signal SccVolChA   : std_logic_vector(3 downto 0);
  signal SccVolChB   : std_logic_vector(3 downto 0);
  signal SccVolChC   : std_logic_vector(3 downto 0);
  signal SccVolChD   : std_logic_vector(3 downto 0);
  signal SccVolChE   : std_logic_vector(3 downto 0);
  signal SccChanSel  : std_logic_vector(4 downto 0);

  signal SccModeSel  : std_logic_vector(7 downto 0);

  -- SCC temporaries
  signal SccRstChA   : std_logic;
  signal SccRstChB   : std_logic;
  signal SccRstChC   : std_logic;
  signal SccRstChD   : std_logic;
  signal SccRstChE   : std_logic;

  signal SccPtrChA   : std_logic_vector(4 downto 0);
  signal SccPtrChB   : std_logic_vector(4 downto 0);
  signal SccPtrChC   : std_logic_vector(4 downto 0);
  signal SccPtrChD   : std_logic_vector(4 downto 0);
  signal SccPtrChE   : std_logic_vector(4 downto 0);

  signal SccClkEna   : std_logic_vector(2 downto 0);
  signal SccChEna    : std_logic;
  signal SccChNum    : std_logic_vector(2 downto 0);
 
  component ram
    port(
      address  : IN  std_logic_vector(7 downto 0);
      inclock  : IN  std_logic;
      we       : IN  std_logic;
      data     : IN  std_logic_vector(7 downto 0);
      q        : OUT std_logic_vector(7 downto 0)
    );
  end component;

begin

  ----------------------------------------------------------------
  -- Misceracle control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then

      SccClkEna <= (others => '0');
      SccChNum  <= (others => '0');

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      -- Clock Enable (clock divider)
      SccClkEna <= SccClkEna + 1;

      if (SccClkEna = "111") then
        SccChNum <= "000";
      elsif (SccChEna = '1') then
        SccChNum <= SccChNum + 1;
      end if;

    end if;

  end process;

  ----------------------------------------------------------------
  -- Wave memory control
  ----------------------------------------------------------------
  WaveAdr  <= pSltAdr(7 downto 0) when SccWavCe = '1'   else
              ("100" & SccWavAdr) when SccWavWx = '1'   else
              ("000" & SccPtrChA) when SccChNum = "000" else
              ("001" & SccPtrChB) when SccChNum = "001" else
              ("010" & SccPtrChC) when SccChNum = "010" else
              ("011" & SccPtrChD) when SccChNum = "011" else
              ("100" & SccPtrChE);

  iWaveDat <= pSltDat when SccWavWx = '0' else SccWavDat;
  WaveWe   <= '1' when SccWavWe = '1' or SccWavWx = '1' else '0';

  WaveMem : ram port map(WaveAdr, pSltClk_n, WaveWe, iWaveDat, oWaveDat);

  pSltDat   <= oWaveDat when SccWavOe = '1' else 
			   DOut   when DOutEn_n  = '0' else (others => 'Z');

  ----------------------------------------------------------------
  -- SCC resister access
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

  begin

    if (pSltRst_n = '0') then

      SccFreqChA <= (others => '0');
      SccFreqChB <= (others => '0');
      SccFreqChC <= (others => '0');
      SccFreqChD <= (others => '0');
      SccFreqChE <= (others => '0');
      SccVolChA  <= (others => '0');
      SccVolChB  <= (others => '0');
      SccVolChC  <= (others => '0');
      SccVolChD  <= (others => '0');
      SccVolChE  <= (others => '0');
      SccChanSel <= (others => '0');

      SccModeSel <= (others => '0');

      SccRstChA <= '0';
      SccRstChB <= '0';
      SccRstChC <= '0';
      SccRstChD <= '0';
      SccRstChE <= '0';

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      -- Mapped I/O port access on 9880-988Fh / B8A0-B8AF ... Resister write
      if (SccRegWe = '1') then
        case pSltAdr(3 downto 0) is
          when "0000" => SccFreqChA(7 downto 0)  <= pSltDat(7 downto 0); SccRstChA <= SccModeSel(5);
          when "0001" => SccFreqChA(11 downto 8) <= pSltDat(3 downto 0); SccRstChA <= SccModeSel(5);
          when "0010" => SccFreqChB(7 downto 0)  <= pSltDat(7 downto 0); SccRstChB <= SccModeSel(5);
          when "0011" => SccFreqChB(11 downto 8) <= pSltDat(3 downto 0); SccRstChB <= SccModeSel(5);
          when "0100" => SccFreqChC(7 downto 0)  <= pSltDat(7 downto 0); SccRstChC <= SccModeSel(5);
          when "0101" => SccFreqChC(11 downto 8) <= pSltDat(3 downto 0); SccRstChC <= SccModeSel(5);
          when "0110" => SccFreqChD(7 downto 0)  <= pSltDat(7 downto 0); SccRstChD <= SccModeSel(5);
          when "0111" => SccFreqChD(11 downto 8) <= pSltDat(3 downto 0); SccRstChD <= SccModeSel(5);
          when "1000" => SccFreqChE(7 downto 0)  <= pSltDat(7 downto 0); SccRstChE <= SccModeSel(5);
          when "1001" => SccFreqChE(11 downto 8) <= pSltDat(3 downto 0); SccRstChE <= SccModeSel(5);
          when "1010" => SccVolChA(3 downto 0)   <= pSltDat(3 downto 0);
          when "1011" => SccVolChB(3 downto 0)   <= pSltDat(3 downto 0);
          when "1100" => SccVolChC(3 downto 0)   <= pSltDat(3 downto 0);
          when "1101" => SccVolChD(3 downto 0)   <= pSltDat(3 downto 0);
          when "1110" => SccVolChE(3 downto 0)   <= pSltDat(3 downto 0);
          when others => SccChanSel(4 downto 0)  <= pSltDat(4 downto 0);
        end case;
      else
        SccRstChA <= '0'; SccRstChB <= '0'; SccRstChC <= '0'; SccRstChD <= '0'; SccRstChE <= '0';
      end if;

      -- Mapped I/O port access on 98C0-98FFh / B8C0-B8DFh ... Resister write
      if (SccModWe = '1') then
        SccModeSel <= pSltDat;
      end if;

    end if;

  end process;

  ----------------------------------------------------------------
  -- Tone generator
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

    variable SccCntChA : std_logic_vector(11 downto 0);
    variable SccCntChB : std_logic_vector(11 downto 0);
    variable SccCntChC : std_logic_vector(11 downto 0);
    variable SccCntChD : std_logic_vector(11 downto 0);
    variable SccCntChE : std_logic_vector(11 downto 0);

  begin

    if (pSltRst_n = '0') then

      SccCntChA := (others => '0');
      SccCntChB := (others => '0');
      SccCntChC := (others => '0');
      SccCntChD := (others => '0');
      SccCntChE := (others => '0');

      SccPtrChA <= (others => '0');
      SccPtrChB <= (others => '0');
      SccPtrChC <= (others => '0');
      SccPtrChD <= (others => '0');
      SccPtrChE <= (others => '0');

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      if (SccFreqChA(11 downto 3) = "000000000" or SccRstChA = '1') then
        SccPtrChA <= "00000";
        SccCntChA := SccFreqChA;
      elsif (SccCntChA = "000000000000") then
        SccPtrChA <= SccPtrChA + 1;
        SccCntChA := SccFreqChA;
      else
        SccCntChA := SccCntChA - 1;
      end if;

      if (SccFreqChB(11 downto 3) = "000000000" or SccRstChB = '1') then
        SccPtrChB <= "00000";
        SccCntChB := SccFreqChB;
      elsif (SccCntChB = "000000000000") then
        SccPtrChB <= SccPtrChB + 1;
        SccCntChB := SccFreqChB;
      else
        SccCntChB := SccCntChB - 1;
      end if;

      if (SccFreqChC(11 downto 3) = "000000000" or SccRstChC = '1') then
        SccPtrChC <= "00000";
        SccCntChC := SccFreqChC;
      elsif (SccCntChC = "000000000000") then
        SccPtrChC <= SccPtrChC + 1;
        SccCntChC := SccFreqChC;
      else
        SccCntChC := SccCntChC - 1;
      end if;

      if (SccFreqChD(11 downto 3) = "000000000" or SccRstChD = '1') then
        SccPtrChD <= "00000";
        SccCntChD := SccFreqChD;
      elsif (SccCntChD = "000000000000") then
        SccPtrChD <= SccPtrChD + 1;
        SccCntChD := SccFreqChD;
      else
        SccCntChD := SccCntChD - 1;
      end if;

      if (SccFreqChE(11 downto 3) = "000000000" or SccRstChE = '1') then
        SccPtrChE <= "00000";
        SccCntChE := SccFreqChE;
      elsif (SccCntChE = "000000000000") then
        SccPtrChE <= SccPtrChE + 1;
        SccCntChE := SccFreqChE;
      else
        SccCntChE := SccCntChE - 1;
      end if;

    end if;

  end process;

  ----------------------------------------------------------------
  -- Mixer control
  ----------------------------------------------------------------
  process(pSltClk_n, pSltRst_n)

    variable SccMix    : std_logic_vector(14 downto 0);

  begin

    if (pSltRst_n = '0') then

      SccChEna <= '0';
      SccMix := (others => '0');
      SccAmp <= (others => '0');

    elsif (pSltClk_n'event and pSltClk_n = '1') then

      if (SccWavCe = '1' or SccWavWx = '1') then
        SccChEna <= '0';
      else
        SccChEna <= '1';
      end if;

      if (SccChEna = '1') then

        case SccChNum is
          when "001"  => SccMix := "000" & ((SccChanSel(0) & SccChanSel(0) & SccChanSel(0) & SccChanSel(0) &
                                             SccChanSel(0) & SccChanSel(0) & SccChanSel(0) & SccChanSel(0)
                                             and oWaveDat) xor "10000000") * SccVolChA;
          when "010"  => SccMix := "000" & ((SccChanSel(1) & SccChanSel(1) & SccChanSel(1) & SccChanSel(1) &
                                             SccChanSel(1) & SccChanSel(1) & SccChanSel(1) & SccChanSel(1)
                                             and oWaveDat) xor "10000000") * SccVolChB + SccMix;
          when "011"  => SccMix := "000" & ((SccChanSel(2) & SccChanSel(2) & SccChanSel(2) & SccChanSel(2) &
                                             SccChanSel(2) & SccChanSel(2) & SccChanSel(2) & SccChanSel(2)
                                             and oWaveDat) xor "10000000") * SccVolChC + SccMix;
          when "100"  => SccMix := "000" & ((SccChanSel(3) & SccChanSel(3) & SccChanSel(3) & SccChanSel(3) &
                                             SccChanSel(3) & SccChanSel(3) & SccChanSel(3) & SccChanSel(3)
                                             and oWaveDat) xor "10000000") * SccVolChD + SccMix;
          when "101"  => SccMix := "000" & ((SccChanSel(4) & SccChanSel(4) & SccChanSel(4) & SccChanSel(4) &
                                             SccChanSel(4) & SccChanSel(4) & SccChanSel(4) & SccChanSel(4)
                                             and oWaveDat) xor "10000000") * SccVolChE + SccMix;
          when others => null;

        end case;

      end if;

      if (SccClkEna = "111") then
        SccAmp <= SccMix(14 downto 4);
      end if;

    end if;

  end process;

end RTL;
