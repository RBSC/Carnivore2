-- 
-- SineTable.vhd 
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


--
-- This entity represents a sine wave table which allow to choose one of
-- the normal sine or half sine wave. The table only contains quarter of 
-- full wave to reduce hardware resources.
--
entity SineTable is 
  port (
    clk     : in std_logic;
    wf      : in std_logic;
    addr    : in integer range 0 to 2 ** (PGOUT_TYPE'high+1) - 1;
    data    : out SIGNED_DB_TYPE
  );
end SineTable;

architecture RTL of SineTable is

  constant TABLE_WIDTH : integer := (addr'high-addr'low+1)/4;
  type sin_type is array (0 to TABLE_WIDTH-1) of DB_TYPE;  
  constant sin_data : sin_type := (
    "1111111","1100101","1010101","1001100",
    "1000101","1000000","0111100","0111000",
    "0110101","0110011","0110000","0101110",
    "0101100","0101010","0101000","0100111",
    "0100101","0100100","0100011","0100001",
    "0100000","0011111","0011110","0011101",
    "0011100","0011011","0011010","0011010",
    "0011001","0011000","0010111","0010110",
    "0010110","0010101","0010100","0010100",
    "0010011","0010011","0010010","0010001",
    "0010001","0010000","0010000","0001111",
    "0001111","0001110","0001110","0001110",
    "0001101","0001101","0001100","0001100",
    "0001011","0001011","0001011","0001010",
    "0001010","0001010","0001001","0001001",
    "0001001","0001000","0001000","0001000",
    "0001000","0000111","0000111","0000111",
    "0000110","0000110","0000110","0000110",
    "0000101","0000101","0000101","0000101",
    "0000101","0000100","0000100","0000100",
    "0000100","0000100","0000011","0000011",
    "0000011","0000011","0000011","0000011",
    "0000010","0000010","0000010","0000010",
    "0000010","0000010","0000010","0000001",
    "0000001","0000001","0000001","0000001",
    "0000001","0000001","0000001","0000001",
    "0000001","0000000","0000000","0000000",
    "0000000","0000000","0000000","0000000",
    "0000000","0000000","0000000","0000000",
    "0000000","0000000","0000000","0000000",
    "0000000","0000000","0000000","0000000",
    "0000000","0000000","0000000","0000000"
  );

begin

  process (clk)
  begin  
    if clk'event and clk = '1' then    
    
      if addr < TABLE_WIDTH then          
      
        data <= ( sign=>'0', value=>sin_data(addr) );   
                  
      elsif addr < TABLE_WIDTH * 2 then      
      
        data <= ( sign=>'0', value=>sin_data(TABLE_WIDTH * 2 - 1 - addr) );  
              
      elsif addr < TABLE_WIDTH * 3 then
      
        if wf = '0' then
          data <= ( sign=>'1', value=>sin_data(addr - TABLE_WIDTH * 2));
        else
          data <= ( sign=>'1', value=>sin_data(0) );
        end if ;
        
      else
      
        if wf = '0' then 
          data <= ( sign=>'1', value=>sin_data( TABLE_WIDTH * 4 - 1 - addr));
        else
          data <= ( sign=>'1', value=>sin_data(0) );
        end if;
        
      end if;        
      
    end if;        
  end process;

end RTL;