library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ram is
   port (
         address  : in  std_logic_vector(7 downto 0);
         inclock  : in  std_logic;
         we       : in  std_logic;
         data     : in  std_logic_vector(7 downto 0);
         q        : out std_logic_vector(7 downto 0)
        );
end ram;

architecture RTL of ram is
  type Mem is array (255 downto 0) of std_logic_vector(7 downto 0);
  signal WaveMem  : Mem;
  signal iAddress : std_logic_vector(7 downto 0);

  begin

  process (inclock)
  begin
    if (inclock'event and inclock ='1') then
      if (we = '1') then
        WaveMem(conv_integer(address)) <= data;
      end if;
      iAddress <= address;
    end if;
  end process;

  q <= WaveMem(conv_integer(iAddress));

end RTL;
