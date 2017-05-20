--
-- TemporalMixer.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
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
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_arith.all;
use WORK.VM2413.ALL;

entity TemporalMixer is
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;

    slot   : in SLOT_TYPE;
    stage  : in STAGE_TYPE;

    rhythm : in std_logic;

    maddr : out SLOT_TYPE;
    mdata : in SIGNED_LI_TYPE;

    mo : out std_logic_vector(9 downto 0);
    ro : out std_logic_vector(9 downto 0)
  );
end TemporalMixer;

architecture RTL of TemporalMixer is

  signal mmute, rmute : std_logic;

begin

  process (clk, reset)
  begin

    if reset = '1' then

      mo <= (others =>'0');
      ro <= (others =>'0');
      maddr <= (others => '0');
      mmute <= '1';
      rmute <= '1';

    elsif clk'event and clk = '1' then if clkena='1' then

      if stage = 0 then

        mo <= "1000000000";
        ro <= "1000000000";

        if rhythm = '0' then

          case slot is
            when "00000" => maddr <= "00001"; mmute <='0'; -- CH0
            when "00001" => maddr <= "00011"; mmute <='0'; -- CH1
            when "00010" => maddr <= "00101"; mmute <='0'; -- CH2
            when "00011" => mmute <= '1';
            when "00100" => mmute <= '1';
            when "00101" => mmute <= '1';
            when "00110" => maddr <= "00111"; mmute<='0'; -- CH3
            when "00111" => maddr <= "01001"; mmute<='0'; -- CH4
            when "01000" => maddr <= "01011"; mmute<='0'; -- CH5
            when "01001" => mmute <= '1';
            when "01010" => mmute <= '1';
            when "01011" => mmute <= '1';
            when "01100" => maddr <= "01101"; mmute<='0'; -- CH6
            when "01101" => maddr <= "01111"; mmute<='0'; -- CH7
            when "01110" => maddr <= "10001"; mmute<='0'; -- CH8
            when "01111" => mmute <= '1';
            when "10000" => mmute <= '1';
            when "10001" => mmute <= '1';
            when others  =>
          end case;
          rmute <= '1';

        else

          case slot is
            when "00000" => maddr <= "00001"; mmute <='0'; rmute <='1'; -- CH0
            when "00001" => maddr <= "00011"; mmute <='0'; rmute <='1'; -- CH1
            when "00010" => maddr <= "00101"; mmute <='0'; rmute <='1'; -- CH2
            when "00011" => maddr <= "01111"; mmute <='1'; rmute <='0'; -- SD
            when "00100" => maddr <= "10001"; mmute <='1'; rmute <='0'; -- CYM
            when "00101" =>                   mmute <='1'; rmute <='1';
            when "00110" => maddr <= "00111"; mmute <='0'; rmute <='1'; -- CH3
            when "00111" => maddr <= "01001"; mmute <='0'; rmute <='1'; -- CH4
            when "01000" => maddr <= "01011"; mmute <='0'; rmute <='1'; -- CH5
            when "01001" => maddr <= "01110"; mmute <='1'; rmute <='0'; -- HH
            when "01010" => maddr <= "10000"; mmute <='1'; rmute <='0'; -- TOM
            when "01011" => maddr <= "01101"; mmute <='1'; rmute <='0'; -- BD
            when "01100" => maddr <= "01111"; mmute <='1'; rmute <='0'; -- SD
            when "01101" => maddr <= "10001"; mmute <='1'; rmute <='0'; -- CYM
            when "01110" => maddr <= "01110"; mmute <='1'; rmute <='0'; -- HH
            when "01111" => maddr <= "10000"; mmute <='1'; rmute <='0'; -- TOM
            when "10000" => maddr <= "01101"; mmute <='1'; rmute <='0'; -- BD
            when "10001" =>                   mmute <='1'; rmute <='1';
            when others  =>
          end case;

        end if;

      else

        if mmute = '0' then
          if mdata.sign = '0' then
            mo <= "1000000000" + mdata.value;
          else
            mo <= "1000000000" - mdata.value;
          end if;
        else
          mo <= "1000000000";
        end if;

        if rmute = '0' then
          if mdata.sign = '0' then
            ro <= "1000000000" + mdata.value;
          else
            ro <= "1000000000" - mdata.value;
          end if;
        else
          ro <= "1000000000";
        end if;

      end if;

    end if; end if;

  end process;

end RTL;