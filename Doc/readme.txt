Carnivore2 MultiFunctional Cartridge version 2.2
Copyright (c) 2017 RBSC


WARNING! To avoid damage to the Carnivore2 cartridge and your MSX computer hardware never insert or remove the cartridge
when a computer is powered on! Always power off your computer before inserting or removing of any cartridge!


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


How to enable the cartridge and install ROMs
--------------------------------------------

Insert the cartridge into the MSX slot, preferably into the first main slot. Power up MSX and check if it functions
normally. If the machine shows an anomaly, remove and inspect the cartridge. To fully set up the cartridge the
following needs to be done:

 1. Make sure that all 3 BIN files (BIDECMFC.BIN, BOOTCMFC.BIN, FMPCCMFC.BIN) are in the same folder with the utilities
 2. Run the "c2man.com" or "c2man_40.com" (for MSX1 only) utility
 3. When asked, enter the slot number where the cartridge is inserted (for example "10" for first slot, "20" for second slot, etc.)
 4. From the main menu select "Open cartridge's Service Menu" using the "9" key
 5. With the "7" key select "Fully erase FlashROM chip" and confirm twice
 6. With the "3" key select "Init/Erase all directory entries" to initialize the directory
 7. With the "4" key select "Write Boot Block (bootcmfc.bin)" to write the Boot Block
 8. With the "5" key select "Write IDE ROM BIOS (bidecmfc.bin)" to write Nextor IDE BIOS
 9. With the "6" key select "Write FMPAC ROM BIOS (fmpcmfc.bin)" to write the English FMPAC BIOS
10. If there were no errors during the steps 5-9, then power down and start your MSX


How to work with Boot Block
---------------------------

The Boot Block allows to start the ROMs from the flash chip and to restart the cartridge with the desired configuration.
After MSX shows its boot logo, the cartridge's boot block should start and you should see the menu. Navigating the menu is very
easy. Here are the key assignments:

	[ESC] - boot MSX using the default configuration: all enabled
	[F] - select 50Hz or 60Hz frequency for VDP
	[LEFT],[RIGHT] - previous/next directory page
	[UP],[DOWN] - select ROM/CFG entry
	[SPACE]     - start entry normally
	[SHIFT]+[G] - start entry directly (using the jump address of the ROM)
	[SHIFT]+[R] - reset and start entry
	[SHIFT]+[A] - entry's autostart ON
	[SHIFT]+[D] - entry's autostart OFF

Please keep in mind that some ROMs may require alternative starting method, so if pressing SPACE doesn't start the ROM, try
using the direct start or start after system's reset.

When you enable the autostart for an entry, it will be always activated after MSX's boot logo. The Boot Block menu will not be
shown and the ROM or configuration entry will be started automatically. In order to disable the autostart or to skip the boot
block completely the following keys should be used:

	[F4] - disable autostart option
	[F5] - disable startup menu

In addition to F4 key, the ESC and TAB keys can be used to disable the autostart entry. If any of those keys are pressed, the
autostart entry is ignored and the main menu is shown.

The symbols that are displayed near the names of directory entries have certain meaning:

	K5 - Konami 5 SCC
	K4 - Konami 4
	A8 - ASCII 8
	A16 - ASCII 16
	MR - mini ROM
	CF - configuration
	UN - unknown

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
	[HOME]  - reset to default value

The volume's value is stored within the small EEPROM on the cartridge board. The value is saved when ESC key is used to return to
the main menu. If the small EEPROM is not present, then the volume setting is only preserved until the power-off. So setting the
volume once allows to play games and listening to the music until the computer is completely switched off.


C2MAN and C2MAN_40 utilities
----------------------------

The C2MAN utility allows to initialize the cartridge, add ROMs into the FlashROM, create custom configuration entries, edit
the cartridge's directory. The C2MAN_40 utility is for MSX1 computers using the 40 character wide display, the C2MAN utility
is for MSX2 and later computers.

The C2MAN_40 utility sets the 40 character mode by default, however the C2MAN utility tries to detect the VDP's version and
the current screen mode. On MSX1 computers, even on those that have v9938 VDP, the C2MAN utility will show a note that it's not
optimized for the 40 character mode and ask whether it should continue. On MSX2 computers this note will be shown only if
the screen mode is less or equal 40 symbols. On both MSX1 and MSX2 systems the note will not be shown if a command line is not
empty, this is done to avoid user interaction during automated adding of ROMs into the cartridge.

The utility supports the following command line options:

 c2man [filename.rom] [/h] [/v] [/a] [/su]

 /h  - help screen
 /v  - verbose mode (show detailed information)
 /a  - automatically detect and write ROM image (no user interaction needed)
 /su - enable Super User mode (allows editing all registers and overriding IDE BIOS write lock when BIOS shadowing is off)

The utility is normally able to find the inserted cartridge by itself. If the utility can't find the cartridge, you will need
to input the slot number manually and press Enter. The slot number is "10" for first slot, "20" for second slot, and so on.

The main menu allows to:

 - Write new ROM image into FlashROM
 - Create new configuration entry
 - Browse/edit cartridge's directory

The menu options should be selected with the corresponding numeric buttons.


Adding a ROM file into the FlashROM
-----------------------------------

To add a new ROM file into the FlashROM chip, select the "Write new ROM image into FlashROM" option. Follow the on-screen instructions
until the ROM is successfully written into the chip and the main menu re-appears. The large ROMs' mapper should be normally
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
We are providing a few RCP files for the ROM files that are not working correctly with default configuration. To load the RCP file
you need to run the "c2man" utility, enter the directory editor and start editing the selected ROM entry. When editing, select the
"Save/load register preset" option and then use "Load register preset file". When asked, enter the preset's file name and it will
be loaded for the entry you are editing. Just save the entry with the new settings and your ROM will start working correctly.

When you are making your own configuration settings for a selected ROM file, you can always save them into RCP file. You need to
select the "Save/load register preset" option and then use "Save register preset file". When asked, entry the name of the RCP file
and it will be saved for future use.


Using the cartridge as MegaRAM
------------------------------

It is possible to use the cartridge as a MegaRAM - for loading ROM images into the cartridge's own RAM and starting them after reboot.
The "c2ramldr.com" utility allows to copy ROM images up to 1mb into the cartridge's RAM and it also creates a directory entry for the
copied ROM with the "RAM: " prefix before the name.

This utility is similar to "c2man.com" utility - it has a menu that allows user to select copying the ROM image into RAM with or without
protection. If the ROM is copied without protection, it will be able to write into its own address space. Some games that have
copy-protection will corrupt their data and won't work. So it's always recommended to apply protection for the copied ROM image in RAM.
The utility can be also used from the command line to automatically load the ROM image into RAM without any user interaction.

Please note that the ROM's image exists in the cartridge's RAM only until the next power-off unless there's a battery installed into the
cartridge to always preserve RAM's data. Don't power-off your MSX if you want to keep the ROM in the cartridge's RAM.

The old directory entries with "RAM: " prefix, created by the "c2ramldr.com" utility can be deleted by the "c2man.com" utility. After
power-off they become useless anyway.


Notes for SCC+ mode
-------------------

The Carnivore2 cartridge supports both SCC and SCC+ modes. Certain games started from the cartridge's IDE device may not like the SCC+
being in the expanded slot, so there will be no sound. In this case such games can be started from a different IDE device and the
Carnivore2 cartridge can be configured as the SCC+ sound cartridge. To do this a new configuration entry must be created. It's necessary
to start the C2MAN or C2MAN_40 utility, enter the directory editing mode and do the following:

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
startdard sound output - it will have the amplified SCC and FMPAC sound and music as well as the PSG sound and music.


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
