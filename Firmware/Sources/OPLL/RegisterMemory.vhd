-- 
-- RegisterMemory.vhd 
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

entity RegisterMemory is port (  
  clk    : in std_logic;
  reset  : in std_logic;
  addr   : in CH_TYPE;
  wr     : in std_logic;
  idata  : in REGS_TYPE;
  odata  : out REGS_TYPE
);  
end RegisterMemory;

architecture RTL of RegisterMemory is

  -- **SKBLK<FNUMBER><AT><VO> 
  --"000000000000000000000000"
  type REGS_ARRAY_TYPE is array (CH_TYPE'range) of REGS_VECTOR_TYPE;
  signal rarray : REGS_ARRAY_TYPE;
  
begin

  process (clk, reset)

    variable init_ch : integer range 0 to CH_TYPE'high + 1;
   
  begin
  
    if reset = '1' then
    
      init_ch := 0;
  
    elsif clk'event and clk ='1' then
  
      if init_ch /= CH_TYPE'high + 1 then    
        rarray(init_ch) <= (others =>'0');
        init_ch := init_ch + 1;    
      elsif wr = '1' then            
        rarray(addr) <= CONV_REGS_VECTOR(idata);        
      end if;
             
      odata <= CONV_REGS(rarray(addr));
        
    end if;
  
  end process;

end RTL;