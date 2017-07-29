Carnivore2 MultiFunctional Cartridge version 2.2
Copyright (c) 2017 RBSC


WARNING! To avoid damage to the Carnivore2 cartridge and your MSX computer hardware never insert or remove the cartridge
when a computer is powered on! Always power off your computer before inserting or removing of any cartridge!


Enabling SCC+ mode
------------------

The "carnivore2_sccplus.pof" firmware allows to use the Carnivore2 cartridge as a separate SCC+ cartridge. Due to design
limitations the SCC+ mode can not be combined with any other mode (IDE, RAM, FMPAC, SCC). So the games have to be started
from another device, preferably from a floppy or IDE controller. Using the second Carnivore2 cartridge to load disk games
is also possible and has been verified to be working properly.

To enable the SCC+ mode you first need to upload a new firmware into the cartridge. Then a new configuration entry must be
created. To do this it's necessary to start the C2MAN or C2MAN_40 utility, enter the directory editing mode and doing the
following:

 1. Edit the first configuration entry "DefConfig: RAM+IDE+FMPAC+SCC"
 2. Rename it to "Config: SCC+ Cartridge"
 3. Select "Save/load register preset" and then choose "Load register preset file"
 4. Load the provided SCCPLUS.RCP file by typing SCCPLUS and pressing Enter key
 5. Save the configuration entry and exit the utility

Put the Carnivore2 cartridge that you want to use as the SCC+ device into the first MSX slot and the device to load games
from into the second slot. Start your MSX and when the Carnivore2's cartridge menu appears, select the newly created
"Config: SCC+ Cartridge" entry. The computer will reboot and start loading a game or an operating system from the device
in the second MSX slot. If the device in the second slot is configured to load a game that uses SCC+ (for example Snatcher),
it will use the Carnivore2 cartridge working as SCC+ device for output.

The functionality has been verified to be working with "Snatcher" and "Konami Game Collection" volumes 1-4 and also with
the special volume.


Contact information
-------------------

The members of RBSC group Wierzbowsky, Ptero and DJS3000 can be contacted via the MSX.ORG or ZX-PK.RU forums. Just send a
personal message and state your business.

The RBSC repository can be found here:

https://github.com/rbsc


-= ! MSX FOREVER ! =-
