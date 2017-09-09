library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
entity mv16 is
  port(
	sin16		: IN std_logic_vector(15 downto 0);
	sout16		: OUT std_logic_vector(15 downto 0);
	level		: IN std_logic_vector(2 downto 0)
  );
end mv16;
architecture RTL of mv16 is
  signal hbits   : std_logic_vector(19 downto 0);
  signal sb0   : std_logic_vector(15 downto 0);
  signal sb1   : std_logic_vector(15 downto 0);
  signal sb2   : std_logic_vector(15 downto 0);
  signal sb3   : std_logic_vector(15 downto 0);
  signal sb4   : std_logic_vector(15 downto 0);
begin
  sout16 <= hbits(19 downto 4);
  hbits <= (sb0&"0000")+(sb1(15)&sb1&"000")
           +(sb2(15)&sb2(15)&sb2&"00")
           +(sb3(15)&sb3(15)&sb3(15)&sb3&"0")
           +(sb4(15)&sb4(15)&sb4(15)&sb4(15)&sb4);
  sb0 <= sin16 when level = "111"
      else (others => '0');   
  sb1 <= sin16 when level = "110" or level = "101" or level = "100" or level = "011" 
      else (others => '0');   
  sb2 <= sin16 when level = "110" or level = "101" or level = "010" or level = "001" or level = "000" 
      else (others => '0'); 
  sb3 <= sin16 when level = "110" or level = "100" or level = "010" or level = "001" 
      else (others => '0');
  sb4 <= sin16 when level = "010" or level = "000" 
      else (others => '0');              
end RTL;