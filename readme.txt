Carnivore2 MultiFunctional Cartridge Readme File
Copyright (c) 2017-2018 RBSC
Last updated: 22.09.2018
------------------------------------------------

WARNING! To avoid damage to the Carnivore2 cartridge and your MSX computer hardware never insert or remove the cartridge
when a computer is powered on! Always power off your computer before inserting or removing of any cartridge!

IMPORTANT! The correct functionality of the Carnivore2 cartridge is not guaranteed in the R800 mode on Panasonic Turbo-R
computers. There may be various anomalies in this mode, for example the games that require a system restart as well as
the configuration entries won't work correctly. So for such games and configuration changes it's not recommended to enable
the R800 mode in the boot block.

NOTE! On certain MSX computers the boot block may not appear after the power is switched on. Pressing the reset button
usually helps to start the cartridge normally. The fix for this problem is very simple. Please check the "PowerUp_Fix"
folder for more information.


The Setup
---------

After assembling, the cartridge needs to be programmed in order to function properly. The following steps are necessary:

 1. Upload the Altera's firmware
 2. Initialize the directory
 3. Write the Boot Block
 4. Write the IDE BIOS
 5. Write the FMPAC BIOS
 6. Restart MSX


How to upload the firmware
--------------------------

Before uploading the firmware please make sure that the CF card is not inserted!

 1. Solder jumper pins to the "+5v" and "GND" soldering points (or solder wires to both sides of C1 capacitor)
 2. Prepare the Byte Blaster or USB Blaster programmer, open the Quartus II software
 3. In the Quartus user interface select "Active Serial" mode for your programmer
 4. Use "Add Device" button to add a new device and select "EPCS4" device
 5. Rightclick on the added device's string and select "Change File"
 6. Select the .POF file from the "Firmware" directory
 7. Enable the checkboxes: "Program/Configure", "Verify" and "Blank Check"
 8. Supply 5v power to the cartridge board (mind the correct polarity!)
 9. Connect the Byte Blaster's or USB Blaster's cable to the AS socket of the cartridge (make sure you connect the cable correctly!)
10. Click "Start" and monitor the programming and verification process

If the programming completed successfully, disconnect the Byte Blaster's or USB Blaster's cable and 5v power from the board.


How to enable the cartridge and install BIOS ROMs
-------------------------------------------------

Insert the cartridge into the MSX slot, preferably into the first main slot. Power up MSX and check if it functions
normally. If the machine shows an anomaly, remove and inspect the cartridge. To fully set up the cartridge the
following needs to be done:

 1. Make sure that all 3 BIN files (BIDECMFC.BIN, BOOTCMFC.BIN, FMPCCMFC.BIN) are in the same folder with the utilities
 2. Run the "c2man.com" or "c2man40.com" (for MSX1 only) utility
 3. When asked, enter the slot number where the cartridge is inserted (for example "10" for first slot, "20" for second slot, etc.)
 4. From the main menu select "Open cartridge's Service Menu" using the "9" key
 5. With the "7" key select "Fully erase FlashROM chip" and confirm twice
 6. With the "3" key select "Init/Erase all directory entries" to initialize the directory
 7. With the "4" key select "Write Boot Block (bootcmfc.bin)" to write the Boot Block
 8. With the "5" key select "Write IDE ROM BIOS (bidecmfc.bin)" to write Nextor IDE BIOS
 9. With the "6" key select "Write FMPAC ROM BIOS (fmpcmfc.bin)" to write the English FMPAC BIOS
10. If there were no errors during the steps 5-9, then power down and start your MSX

There's also another way to write the boot block and bioses into the FlashROM chip. This can be done on a diskless computer by
loading necessary files via the cassette interface and copying them from specially formatter CF card onto a FlashROM. Please
see the readme.txt file in the "Utils\diskless" folder of RBSC's repository.


How to work with Boot Block
---------------------------

The Boot Block allows to start the ROMs from the flash chip and to restart the cartridge with the desired configuration.
After MSX shows its boot logo, the cartridge's boot block should start and you should see the menu. Navigating the menu is very
easy. Here are the key assignments:

	[ESC] - boot MSX using the default configuration: all enabled
	[LEFT],[RIGHT] - previous/next directory page
	[UP],[DOWN] - select ROM/CFG entry
	[SPACE],[ENTER] - start an entry
	[G] - start an entry directly
	[R] - reset MSX and start an entry
	[A] - select an entry for autostart
	[D] - disable autostart option
	[F] - select 50Hz or 60Hz frequency
	[T] - toggle Turbo or R800 mode

The boot block also supports the built-in joypads and external joysticks connected to any of the 2 joystick ports. The joystick's
stick movements are interpreted as follows:

	[LEFT],[RIGHT] - previous/next directory page
	[UP],[DOWN] - select ROM/CFG entry
	[BUTTON_A] - start an entry
	[BUTTON_B] - reset MSX and start an entry

The selected VDP frequency is preserved for ROMs that require a reset to start. The frequency setting is saved into the configuration
EEPROM and is restored even after the computer was powered off and on again.

The Turbo mode can be enabled only on Panasonic MSX2+ computers and R800 mode can be enabled only on Panasonic Turbo-R computers.
On other computers this functionality does not work. The status of the Turbo or R800 mode is not saved into the configuration
EEPROM and it is not restored at the start of the boot block after the power was switched off and back on. However the Turbo/R800
mode is still set for ROMs that require a reset to start. The current mode is displayed in the status screen:

	Z80 - Z80 mode (default)
	T2+ - Turbo mode for Panasonic MSX2+
	R8x - R800 mode for Panasonic Turbo-R

Please keep in mind that some ROMs may require alternative starting method, so if pressing SPACE doesn't start the ROM, try
using the direct start or start after system's reset.

There are several keys that can affect the cartridge's functionality at boot level. Certain keys can skip the autostart option,
other keys can skip the boot block's main menu:

	[F4] - disable autostart option
	[F5] - disable startup menu

When autostart is set on any entry, after reboot there will be a note shown and there will be a 3 second delay before this
entry is activated. During these 3 seconds a user can abort autostart with ESC, TAB, F4 key or a joystick button. If any of
these keys or a joystick button are pressed during the 3 seconds, the autostart will be skipped and the main menu will be
shown.

The symbols that are displayed near the names of directory entries have certain meaning:

	K5  - Konami 5 SCC
	K4  - Konami 4
	A8  - ASCII 8
	A16 - ASCII 16
	MR  - mini ROM
	CF  - configuration
	UN  - unknown

For any other symbol there will be just 2 dashes.

The cartridge has a pushbutton to completely disable its functionality if something goes wrong. If the cartridge stops working
correctly, you may need to reinitialize it like described in the "How to enable the cartridge and install ROMs" section. The
MSX has to be started with the cartridge's pushbutton pressed down. When the DOS prompt appears, the button can be released.

The latest Boot Block supports volume changing for the FMPAC and SCC modules. Use the 'V' key to enter the volume control screen
from the main menu. The following keys can be used in this screen:

	[ESC]   - save & exit to main menu
	[UP]    - increase FMPAC volume
	[DOWN]  - decrease FMPAC volume
	[RIGHT] - increase SCC/SCC+ volume
	[LEFT]  - decrease SCC/SCC+ volume
	[HOME]  - reset to default values

The volume's value is stored within the small EEPROM on the cartridge board. The value is saved when ESC key is used to return to
the main menu. If the small EEPROM is not present, then the volume setting is only preserved until the power-off. So setting the
volume once allows to play games and listening to the music until the computer is completely switched off.

The latest Boot Block also supports enabling or disabling the internal PSG and PPI's Clicker emulation as well as setting the
volume for both of them. Use the 'P' key to enter the PSG control screen from the main menu. The following keys can be used in
this screen:

	[ESC]   - save & exit to main menu
	[ENTER] - enable/disable PSG
	[SPACE] - enable/disable PPI Clicker
	[UP]    - increase PSG volume
	[DOWN]  - decrease PSG volume
	[RIGHT] - increase Clicker volume
	[LEFT]  - decrease Clicker volume
	[HOME]  - reset to default values

The volume's value is stored within the small EEPROM on the cartridge board. The value is saved when ESC key is used to return to
the main menu. If the small EEPROM is not present, then the volume setting is only preserved until the power-off. So setting the
volume once allows to play games and listening to the music until the computer is completely switched off.


C2MAN and C2MAN40 utilities
---------------------------

The C2MAN utility allows to initialize the cartridge, add ROMs into the FlashROM, create custom configuration entries, edit
the cartridge's directory. The Service Menu allows to see the FlashROM block usage, erase and optimize the directory, upload
the boot block as well as IDE and FMPAC BIOSes into the FlashROM; it also allows to completely erase the FlashROM chip.

The C2MAN utility works only on MSX2 and later computers, it sets the 80 character mode by default. On MSX1 computers this
utility shows an incompatibility note and exits. For MSX1 computers the C2MAN40 utility must be used. This utility, however,
will also work on MSX2 and later computers in 80 character mode, but all messages will be truncated for the 40 character
mode.

Both utilities will automatically reboot a computer after uploading a ROM into the FlashROM chip if the /a and /r command line
options are used.

The utility supports the following command line options:

 c2man [filename.rom] [/h] [/v] [/a] [/r] [/su]

 /h  - help screen
 /v  - verbose mode (show detailed information)
 /a  - automatically detect and write ROM image (no user interaction needed)
 /r  - automatically restart MSX after flashing ROM image
 /su - enable Super User mode (allows editing all registers and overriding IDE BIOS write lock when BIOS shadowing is off)

The utility is normally able to find the inserted cartridge by itself. If the utility can't find the cartridge, you will need
to input the slot number manually and press Enter. The slot number is "10" for first slot, "20" for second slot, and so on.

The main menu allows to:

 - Write new ROM image into FlashROM
 - Create new configuration entry
 - Browse/edit cartridge's directory
 - Restart a computer

The menu options should be selected with the corresponding numeric buttons.


Adding a ROM file into the FlashROM
-----------------------------------

To add a new ROM file into the FlashROM chip, select the "Write new ROM image into FlashROM" option. Follow the on-screen instructions
until the ROM is successfully written into the chip and the main menu re-appears. The large ROMs' mappers should be normally
detected automatically by the utility, but on some ROMs autodetecting may fail. In this case the utility will ask you to choose the
mapper. The ROM will not start with incorrect mapper settings, so if your setting didn't work, try to change the mapper type.

The FlashROM chip contains 128 blocks by 64kb (8mb in total). The first 4 blocks are occupied by the Boot Block, IDE BIOS and FMPAC BIOS.
Other blocks are available for a user to add the ROMs. The ROMs that are smaller than 64kb are grouped into one block. For example two 32kb
ROMs will be written into the same 64kb block, eight 8kb ROMs will be grouped into the same 64kb block and finally four 16kb ROMs will be
grouped written into the same 64kb block. All this is done automatically.

You can add a ROM into the chip without user interaction. The following command line should be used:

 C2MAN file.rom /a

The utility will try to automatically detect the ROM's mapper, check whether any free space is available and then it will write the
selected ROM into the FlashROM chip. If you add the "/v" option, the utility will show additional information about the chip and the
ROM that is being added as well as the map of the free chip's blocks.

The map of FlashROM chip blocks can be viewed from the Service Menu. Just select the "Show FlashROM chip's block usage" option.


Adding a custom configuration entry
-----------------------------------

To add a new configuration entry select the "Create new configuration entry" option. You will be asked to enter the name of the entry
and then you will need to answer 5 questions. The utility will ask whether the slot should be expanded or not (if you want to enable more
that one internal device, the slot must be expanded), and whether to enable one of the 4 built-in devices: RAM + mapper, FMPAC, IDE and
MultiMapper + SCC. You can select any combination you want. The cartridge can work as pure SCC or FMPAC sound cartridge, as a 1MB
RAM expander or as a disk drive. Or as a combination of those devices.

The configuration entries will have the "C" symbol close to their names. Once the configuration entry is selected, the MSX will restart
to take the new configuration into effect.

The configuration entries don't occupy any space in the FlashROM chip, so they can be created as long as there's free space in the
cartridge's directory.


Editing or deleting directory entries
-------------------------------------
 
To edit the cartridge's directory select the "Browse/edit cartridge's directory" option. This will open the screen with the list of
directory entries, 10 per page. The key assignment is similar to the boot block with the exception that you can't start the entry.
An entry can be edited or deleted. Follow the on-screen instructions for editing a directory entry. Please keep in mind that the very
first entry called "DefConfig: RAM+IDE+FMPAC+SCC" can't be deleted.

In the directory editor you can change almost all fields of an entry, select a different mapper, enable or disable the internal devices
or expanded slot (some games don't like being in the expanded slot). The editor has the context based help that is displayed at the bottom
of the screen.

With the Super User mode you can edit any register you want, but be advised, that you may damage the directory beyond repair and you
will need to initialize it to continue using the cartridge.

When you finish editing, you need to save the entry. The utility will offer you to replace the older entry or to create a copy of the
edited entry. The new entry will be located in the end of the list. The name of the entry will be the same if you didn't rename it while
editing.

The number of directory entries is limited to 254. If the utility can't find an empty directory entry, it will ask you whether the
directory should be optimized. If you select "Yes", then there's a big chance that unused directory entries will be found and deleted
and you will have the possibility to add new ones.


Loading and saving RCP files
----------------------------

When a ROM file doesn't start properly after being detected by the "c2man" utility, there may be a need to adjust its configuration.
This can be done either manually - by editing the configuration registers or by loading an RCP (Register Configuration Preset) file.
We are providing a few RCP files for the ROM files that are not working correctly with default configuration.

To load the RCP file manually you need to run the "c2man" utility, enter the directory editor and start editing the selected ROM
entry. When editing, select the "Save/load register preset" option and then use "Load register preset file". When asked, enter the
preset's file name and it will be loaded for the entry you are editing. Just save the entry with the new settings and your ROM will
start working correctly.

When you are making your own configuration settings for a selected ROM file, you can always save them into RCP file. You need to
select the "Save/load register preset" option and then use "Save register preset file". When asked, entry the name of the RCP file
and it will be saved for future use.

The latest versions of "c2man", "c2man40" and "c2ramldr" utilities try to automatically find the matching RCP file when a ROM is
being loaded. For example if a user writes the "TEST.ROM" file into the cartridge, the utilities will try to locate the "TEST.RCP"
file and ask a user whether he/she wants to load and use the data from that RCP file. When a ROM file is loaded with the "/a"
command line option, the data from the matching RCP file is automatically applied.


Using the cartridge as MegaRAM
------------------------------

It is possible to use the cartridge as a MegaRAM - for loading ROM images into the cartridge's own RAM and starting them after reboot.
The "c2ramldr.com" utility allows to copy ROM images up to 1mb into the cartridge's RAM and it also creates a directory entry for the
copied ROM with the "RAM: " prefix before the name.

This utility is similar to "c2man.com" utility - it has a menu that allows user to select copying the ROM image into RAM with or without
protection. If the ROM is copied without protection, it will be able to write into its own address space. Some games that have
copy-protection will corrupt their data and won't work. So it's always recommended to apply protection for the copied ROM image in RAM.
The utility can be also used from the command line to automatically load the ROM image into RAM without any user interaction.

The utility has a feature to restart a computer after loading a ROM image into the cartridge's RAM. This can be either done from the
utility's main menu or by specifying the /r command line option together with the /a option.

Please note that the ROM's image exists in the cartridge's RAM only until the next power-off unless there's a battery installed into the
cartridge to always preserve RAM's data. Don't power-off your MSX if you want to keep the ROM in the cartridge's RAM.

The old directory entries with "RAM: " prefix, created by the "c2ramldr.com" utility can be deleted by the "c2man.com" utility. After
power-off they become useless anyway.


Using FMPAC's SRAM option
-------------------------

The FMPAC's 8kb SRAM is emulated by the cartridge at the Shadow RAM's address 0FE000h. This area is not affected by the 1mb of primary
RAM in any way. This area is used by certain games to save the data. If the Carnivore2 cartridge doesn't have a backup RAM battery
installed, then the data that was saved into that area will be lost when an MSX computer is switched off. As this data survives the
reset, it's possible to save it to a file and load it back into RAM when needed. The utility that allows to save/load this data is
called "c2sram.com". The files with the save data will have .SRM extension by default and these files will be found by the utility
when a user selects files manually. However the file can be saved with any name and extension. In such a case when a user wants to
upload the file into the emulated SRAM area, he will have to type its name manually.

To save the data it's enough to reset MSX (no power-off!), run the "c2sram.com" utility and save the data to a file. Then a computer
can be switched off. In case a user wants to restore the data and then run a game, the "c2sram.com" utility should be used to upload
the previously saved file into SRAM area. Then a computer should be reset and a game can be then started from the boot block or from
an emulated DSK image.


Backing up and restoring FlashROM's contents
--------------------------------------------

The "c2backup.com" utility allows to dump the contents of the entire FlashROM chip into a file. The size of the file is 8 megabytes.
The utility also allows to copy the contents of the FlashROM's dump back into the chip. Because of the BIOS shadowing this operation
can be performed live, however the system must be restarted as soon as possible after uploading the new contents into the FlashROM
chip.

WARNING! Interrupting the FlashROM's contents uploading may result in a non-working Carnivore2 cartridge! In this case the cartridge
must be re-initialized. The description of the procedure can be found in the "How to enable the cartridge and install BIOS ROMs"
section of this readme file.


Notes for SCC+ mode
-------------------

The Carnivore2 cartridge supports both SCC and SCC+ modes. Certain games started from the cartridge's IDE device may not like the SCC+
being in the expanded slot, so there will be no sound. In this case such games can be started from a different IDE device and the
Carnivore2 cartridge can be configured as the SCC+ sound cartridge. To do this a new configuration entry must be created. It's necessary
to start the C2MAN or C2MAN40 utility, enter the directory editing mode and do the following:

 1. Edit the first configuration entry "DefConfig: RAM+IDE+FMPAC+SCC"
 2. Rename it to "Config: SCC+ Cartridge"
 3. Select "Save/load register preset" and then choose "Load register preset file"
 4. Load the provided SCCPLUS.RCP file by typing SCCPLUS and pressing Enter key
 5. Save the configuration entry and exit the utility

Put the Carnivore2 cartridge that you want to use as the SCC+ device into the first MSX slot and the device to load games from into the
second slot. Start your MSX and when the Carnivore2's cartridge menu appears, select the newly created "Config: SCC+ Cartridge" entry.
The computer will reboot and start loading a game or an operating system from the device in the second MSX slot. If the device in the
second slot is configured to load a game that uses SCC+ (for example Snatcher), it will use the Carnivore2 cartridge working as SCC+
device for the output.

This functionality has been verified to be working with "Snatcher" and "Konami Game Collection" volumes 1-4 and also with the special
game volume.


Notes
-----

When using Nextor's "_fdisk" command to partition the CF card please make sure you create and start from the configuration entry that
has the expanded slot disabled and the only enabled device there is IDE. Otherwise partitioning will not work.

The audio socket of the Carnivore2 cartridge may not be suitable for connecting the headphones. It's recommended to connect it to the
speakers or to the amplifier. This socket will only output SCC or FMPAC music and sounds. For the full experience please use the MSX's
standard sound output - it will have the amplified SCC and FMPAC sound and music as well as the PSG sound and music.

When booting to DOS on a Panasonic A1 computer (also on A1 MK2), please hold the DEL key while computer reboots after selection on the
default configuration entry and until you see the DOS prompt.


IMPORTANT!
----------

The RBSC provides all the files and information for free, without any liability (see the disclaimer.txt file). The provided information,
software or hardware must not be used for commercial purposes unless permitted by the RBSC. Producing a small amount of bare boards for
personal projects and selling the rest of the batch is allowed without the permission of RBSC.

When the sources of the tools are used to create alternative projects, please always mention the original source and the copyright!


Contact information
-------------------

The members of RBSC group Wierzbowsky, Ptero and DJS3000 can be contacted via the MSX.ORG or ZX-PK.RU forums. Just send a personal
message and state your business.

The RBSC repository can be found here:

https://github.com/rbsc


-= ! MSX FOREVER ! =-
