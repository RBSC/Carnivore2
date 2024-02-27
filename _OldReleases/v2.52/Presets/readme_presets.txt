--------------------------------------------------------------------------------
Carnivore2 MultiFunctional Cartridge
Copyright (c) 2017-2023 RBSC
--------------------------------------------------------------------------------

Register Configuration Presets

The RCP files should be loaded for certain ROM files or for ROM files of certain size.
Below is the list of currently available RCP files and their descriptions.

48K_GAME.RCP	- generic RCP file for 49152 byte ROMs without mapper (except for "Spy vs Spy")
64K_GAME.RCP	- generic RCP file for 65535 byte ROMs without mapper
64K_MAPP.RCP	- generic RCP file for 65535 byte ROMs with mapper
DSK2ROM1.RCP	- generic RCP file for DSK images converted into ROM with the DSK2ROM utility (Konami SCC mapper)
DSK2ROM2.RCP	- generic RCP file for DSK images converted into ROM with the DSK2ROM utility (ASCII 8-bit mapper)
DSK2ROM3.RCP	- generic RCP file for DSK images converted into ROM with the DSK2ROM utility (ASCII 16-bit mapper)
MGEAR2.RCP	- RCP file for "Metal Gear 2: Solid Snake game" (any version)
NEWGOONI.RCP	- RCP file for "Goonies 'r' good enough" (remake of Goonies)
SM_WORLD.RCP	- RCP file for "Super Mario World" game
SPYVBSPY.RCP	- RCP file for "Spy vs Spy" game (any version)
DONKKONG.RCP	- RCP file for "Donkey Kong" game (both 49 and 64kb versions)
GBERET.RCP	- RCP file for "Green Beret" game
XANA_RAM.RCP	- RCP file for "Xanadu: Dragon Slayer 2" game in RAM mode (use C2RAMLDR utility)
XEVIOUS.RCP	- RCP file for "Xevious" game
ALESTE2.RCP	- RCP file for "Aleste 2" game
MANBOW2.RCP	- RCP file for "Manbow 2" game, R1 and R2 (see the patch note below)
1942.RCP	- RCP file for "1942" MSX2 game (shared by Carmeloco)
LIFEMARS.RCP	- RCP file for "Life on Mars" game
ZOMBIE.RCP	- RCP file for "Zombie Outbreak" game
IKARI.RCP	- RCP file for "Ikari Warrior" game
LIFEEART.RCP	- RCP file for "Life on Earth" game
GMASTER.RCP	- RCP file for "Konami Game Master 1" ROM (must be located in the first page of the 64kb block)
GMASTER2.RCP	- RCP file for "Konami Game Master 2" ROM
NEM3E102.RCP	- RCP file for "Nemesis 3 Enhanced v1.02" game (shared by Carmeloco)
PRACE2.RCP	- RCP file for "Pennant Race 2" game
P-WARS2.RCP	- RCP file for "Penguin Wars 2" game
GYRUSS.RCP	- RCP file for "Gyruss" game
BOMBJACK.RCP	- RCP file for "Bomb Jack" game
QBERT.RCP	- RCP file for "Qbert" game
CHOPLIFT.RCP	- RCP file for "ChopLifter" game
PAINTER.RCP	- RCP file for "Painter" graphics editor
QURAN.RCP	- RCP file for "Quran" cartridge dump (shared by Wbahnassi)
EIDOLON.RCP	- RCP file for "Eidolon" game (shared by Carmeloco)
HOIN1SP.RCP	- RCP file for "Hole In One Special" game
RMONSTER.RCP	- RCP file for "Rune Monster" game
GUARDIC.RCP	- RCP file for "Guardic" game
MUTANTS.RCP	- RCP file for "Mutants from the Deep" game
SHRINES.RCP	- RCP file for "Shrines of Enigma" game
DEMO_GNG.RCP	- RCP file for "Ghosts and Goblins" game (demo)
DPUZZLE.RCP	- RCP file for "Dreams Puzzle" game
GGGPLUS.RCP	- RCP file for "Green Gravity Guy+" game
HIGHWAY.RCP	- RCP file for "Highway" game (KAI Magazine)
INTRUDER.RCP	- RCP file for "Codename: Intruder" game
MAPAX.RCP	- RCP file for "Mapax" game
MYTHSMSX.RCP	- RCP file for "Myths and Dragons" game (KAI Magazine)
MYTHSEMU.RCP	- RCP file for "Myths and Dragons" game (KAI Magazine)
SORROWSE.RCP	- RCP file for "The Sorrow of Gadhlan Thur" game (KAI Magazine)
SORROWPE.RCP	- RCP file for "The Sorrow of Gadhlan Thur" game (KAI Magazine)
V90_LOSA.RCP	- RCP file for "Losaben Akel" game


Preset for certain SCC+ games is also included - SCCPLUS.RCP. Please see the readme.txt file for
more information about this file.


Note for MANBOW2.RCP
--------------------
To be able to run the game from FlashROM and to get SCC sound, the ROM must be patched. Below are
the addresses and the byte values that must be there. Please note that there are Release 1 and 2
ROMs, so this patch must be done at one of those 2 addresses depending on the ROM's release:

2CBAh: 00 00 (Release 2, the original bytes are 20 FC) 
..or..
2CBDh: 00 00 (Release 1, the original bytes are 20 FC)

Some ROMs you find may be already patched to use PSG instead of SCC. So it's recommended to also
apply this patch to get SCC sound:

07D9h: D3 10
07DCh: D3 11
07EDh: DB 12
0824h: 0E 11
