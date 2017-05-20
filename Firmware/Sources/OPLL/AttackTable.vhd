-- 
-- AttackTable.vhd 
-- Envelope attack shaping table for VM2413
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
use WORK.VM2413.ALL;

entity AttackTable is 
  port (
    clk     : in std_logic;
    addr    : in integer range 0 to 2 ** (DB_TYPE'high+1) - 1;
    data    : out DB_TYPE
  );
end AttackTable;

architecture RTL of AttackTable is 

  type AR_ADJUST_ARRAY is array (addr'range) of DB_TYPE;
  constant ar_adjust : AR_ADJUST_ARRAY :=(
    "1111111","1111111","1101100","1100010","1011010","1010100","1010000","1001011",
    "1001000","1000101","1000010","1000000","0111101","0111011","0111001","0111000",
    "0110110","0110100","0110011","0110001","0110000","0101111","0101101","0101100",
    "0101011","0101010","0101001","0101000","0100111","0100110","0100101","0100100",
    "0100100","0100011","0100010","0100001","0100001","0100000","0011111","0011110",
    "0011110","0011101","0011101","0011100","0011011","0011011","0011010","0011010",
    "0011001","0011000","0011000","0010111","0010111","0010110","0010110","0010101",
    "0010101","0010101","0010100","0010100","0010011","0010011","0010010","0010010",
    "0010001","0010001","0010001","0010000","0010000","0001111","0001111","0001111",
    "0001110","0001110","0001110","0001101","0001101","0001101","0001100","0001100",
    "0001100","0001011","0001011","0001011","0001010","0001010","0001010","0001001",
    "0001001","0001001","0001001","0001000","0001000","0001000","0000111","0000111",
    "0000111","0000111","0000110","0000110","0000110","0000110","0000101","0000101",
    "0000101","0000100","0000100","0000100","0000100","0000100","0000011","0000011",
    "0000011","0000011","0000010","0000010","0000010","0000010","0000001","0000001",
    "0000001","0000001","0000001","0000000","0000000","0000000","0000000","0000000"
);

begin
  process (clk)
  begin  
    if clk'event and clk = '1' then    
      data <= ar_adjust(addr'high - addr);
    end if;        
  end process;
end RTL;