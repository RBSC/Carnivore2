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
signal sgin		: std_logic;
signal uin16 	: std_logic_vector(15 downto 0);
signal uout21 	: std_logic_vector(20 downto 0);
signal M5 		: std_logic_vector(4 downto 0);
begin
  sgin <= sin16(15);
  uin16 <= sin16 when sgin = '0'
        else "0000000000000000" - sin16;
  M5 <= "00101" when level = "000"
   else "00110" when level = "001"
   else "00111" when level = "010"
   else "01000" when level = "011"
   else "01010" when level = "100"
   else "01100" when level = "101"
   else "01110" when level = "110"
   else "10000" ;

  uout21 <= m5*uin16;
  sout16 <= uout21(19 downto 4) when sgin = '0'
       else "0000000000000000" - uout21(19 downto 4); 
--  sout16  <= uout21(20 downto 5) ;      
end RTL;