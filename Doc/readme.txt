Carnivore2 MultiFunctional Cartridge Readme File
Copyright (c) 2017-2020 RBSC
Last updated: 15.03.2020
------------------------------------------------

WARNING! To avoid damage to the Carnivore2 cartridge and your MSX computer hardware never insert or remove the cartridge
when a computer is powered on! Always power off your computer before inserting or removing any cartridges!

IMPORTANT! The correct functionality of the Carnivore2 cartridge is not guaranteed in the R800 mode on Panasonic Turbo-R
computers. There may be various anomalies in this mode, for example the games that require a system restart as well as
the configuration entries won't work correctly. So for such games and configuration changes it's not recommended to enable
the R800 mode in the Boot Menu. Certain features of Carnivore2 may not work correctly on computers with less than 16kb of
RAM (for example on Casio PV-7).

NOTE! When a computer is just powered on with the Carnivore2 cartridge inserted into a slot, it will reboot twice. This
is normal and was implemented to make sure that the cartridge is fully initialized after the cold boot. You can enable
the dual-reboot feature in the Configuration settings.


The Setup
---------

After assembling, the cartridge needs to be programmed in order to function properly. The following steps are necessary:

 1. Upload the Altera's firmware
 2. Initialize the directory
 3. Write the Boot Menu
 4. Write the IDE BIOS
 5. Write the FMPAC BIOS
 6. Restart MSX


How to upload the firmware
--------------------------

Before uploading the firmware please make sure that the CF card is not inserted!

 1. Solder jumper pins to the "+5v" and "GND" soldering points (or solder wires to both sides of C1 capacitor)
 2. Prepare the Byte Blaster or USB Blaster programmer, open the Quartus II software (we recommend version 15.0)
 3. In the Quartus user interface select "Active Serial" mode for your programmer
 4. Use "Add Device" button to add a new device and select "EPCS4" device
 5. Rightclick on the added device's string and select "Change File"
 6. Select the .POF file from the "Firmware" directory
 7. Enable the checkboxes: "Program/Configure", "Verify" and "Blank Check"
 8. Supply 5v power to the cartridge board (mind the correct polarity!)
 9. Connect the Byte Blaster's or USB Blaster's cable to the AS socket of the cartridge (make sure you connect the cable correctly!)
10. Click "Start" and monitor the programming and verification process

If the programming completed successfully, disconnect the Byte Blaster's or USB Blaster's cable and 5v power from the board. The
cartridge is ready for uploading the necessary software.


How to enable the cartridge and install BIOS ROMs
-------------------------------------------------

The freshly-assembled Carnivore2 cartridge will not boot to MSX-DOS2 without the specific software that needs to be loaded into
the FlashROM chip from any disk drive.

Insert the cartridge into the MSX slot, preferably into the first main slot. Power up MSX and check if it functions
normally. If the machine shows an anomaly, remove and inspect the cartridge. To fully set up the cartridge the
following needs to be done:

 1. Make sure that all 3 BIN files (BIDECMFC.BIN, BOOTCMFC.BIN, FMPCCMFC.BIN) are in the same folder with the utilities
 2. Run the "C2MAN.COM" or "C2MAN40.COM" (for MSX1 only) utility
 3. When asked, enter the slot number where the cartridge is inserted (for example "10" for first slot, "20" for second slot, etc.)
 4. From the main menu select "Open cartridge's Service Menu" using the "9" key
 5. With the "7" key select "Fully erase FlashROM chip" and confirm twice
 6. With the "3" key select "Init/Erase all directory entries" to initialize the directory
 7. With the "4" key select "Write Boot Menu (bootcmfc.bin)" to write the Boot Menu
 8. With the "5" key select "Write IDE ROM BIOS (bidecmfc.bin)" to write Nextor IDE BIOS
 9. With the "6" key select "Write FMPAC ROM BIOS (fmpccmfc.bin)" to write the English FMPAC BIOS
10. If there were no errors during the steps 5-9, then power down and start your MSX

There's also another way to write the Boot Menu and BIOSes into the FlashROM chip. This can be done on a diskless computer by
loading necessary files via the cassette interface and copying them from specially formatter CF card onto a FlashROM. Please
see the readme.txt file in the "Utils\diskless" folder of RBSC's repository. However, after this operation you need to
update the Boot Menu and BIOSes to the latest versions downloaded from the repository.


How to work with Boot Menu
--------------------------

The program that runs from the Carnivore2 cartridge after a computer is powered on is called Boot Menu. It can be also referenced
as "Boot Block" or "bootblock".

The Boot Menu allows to start the ROMs from the FlashROM chip and to restart the cartridge with the desired configuration.
After a computer shows its boot logo, the cartridge's Boot Menu should start and you should see the main menu. Navigating the menu
is very easy. Here are the key assignments:

	[ESC] - boot MSX using the default configuration: all enabled
	[LEFT],[RIGHT] - previous/next page
	[UP],[DOWN] - select ROM/CFG entry
	[SPACE] - start selected entry
	[G] - start an entry directly
	[R] - reset MSX and start an entry
	[ENTER],[O] - Dual-Slot setup page
	[1] - select entry for master slot
	[2] - select entry for slave slot
	[A] - select entry for autostart
	[D] - clear Auto-Start & Dual-Slot
	[F] - select 50Hz or 60Hz frequency
	[T] - toggle Turbo or R800 mode
	[C] - customize configuration

The main menu also supports the built-in joypads and external joysticks connected to any of the 2 joystick ports. The
joystick's stick movements and using the buttons are interpreted as follows:

	[LEFT],[RIGHT] - same as cursor keys
	[UP],[DOWN]    - same as cursor keys
	[BUTTON A] - start an entry (same as SPACE)
	[BUTTON B] - exit from Boot Menu (same as ESC)

All other joystick directions are ignored.

The 'F' button only temporarily changes the frequency to the desired value. Use the "Frequency at startup" setting in the
Configuration screen to control what frequency you would like the computer to boot with and what frequency should be used to
start ROM images. The frequency setting is saved into the configuration EEPROM and is restored even after the computer was
powered off and on again.

The Turbo mode can be enabled with the "T" button only on Panasonic MSX2+ computers and R800 mode can be enabled only on
Panasonic Turbo-R computers with the same button. On other computers this functionality does not work. The status of the
Turbo or R800 mode is not saved into the configuration EEPROM and it is not restored at the start of the Boot Menu after
the power was switched off and back on. However the Turbo/R800 mode is still set for ROMs that require a reset to start.
The current mode is displayed in the status screen:

	Z80 - Z80 mode (default)
	T2+ - Turbo mode for Panasonic MSX2+
	R8x - R800 mode for Panasonic Turbo-R

Please keep in mind that some ROMs may require alternative starting method, so if pressing SPACE doesn't start the ROM, try
using the direct start or start after system's reset.

There are several keys that can affect the cartridge's functionality at boot level. Certain keys can cancel the autostart,
other keys can skip the Boot Menu:

	[F3] - use default UI settings
	[F4] - cancel autostart
	[F5] - skip Boot Menu

When autostart is set for any entry, after reboot a message will be shown and there will be a 3 second delay before this
entry is activated. During these 3 seconds a user can abort autostart with "ESC", "TAB", "F4" keys. If any of these keys
are pressed during the 3 seconds countdown, the autostart will be skipped and the main menu will be shown. Pressing Space
bar will skip countdown and start an entry. During the boot sequence with autostart the following joystick button actions
are possible:

	[BUTTON A] - skip countdown and start an entry
	[BUTTON B] - cancel autostart

Please hold a joystick's button for over 1 second to cancel the autostart and go to the main menu. This works the same way
when the message about the incompatible Boot Menu is shown.

The Boot Menu can detect that it is running on Korean or Arabic MSXs and in case it is not compatible with those systems,
it will output a message and will try to boot to DOS after 10 seconds. In such a case a compatible Boot Menu (BOOTCMFC.BIN)
should be installed into the cartridge (see the "Special" subfolder in the repository for the compatible version of the boot
menu).


Sound settings
--------------

The Boot Menu supports setting the volumeg for the FMPAC and SCC sound cards. Use the 'V' key to enter the volume control
screen from the main menu. The following keys can be used in this screen:

	[ESC]   - save & exit to main menu
	[UP]    - increase FMPAC volume
	[DOWN]  - decrease FMPAC volume
	[RIGHT] - increase SCC/SCC+ volume
	[LEFT]  - decrease SCC/SCC+ volume
	[HOME]  - reset to default values

The volume's value is stored within the small EEPROM on the cartridge board. The value is saved when "ESC" key is used to
return to the main menu. If the small EEPROM is not present, then the volume setting is only preserved until the power-off.
So setting the volume once allows to play games and listening to the music until the computer is completely switched off.

This screen also supports joystick. The joystick's stick movements and using the buttons are interpreted as follows:

	[LEFT],[RIGHT] - increase/decrease SCC/SCC+ volume
	[UP],[DOWN]    - increase/decrease FMPAC volume
	[BUTTON A] - apply changes and exit (same as ESC)
	[BUTTON B] - apply changes and exit (same as ESC)


PSG/PPI clicker settings
------------------------

The Boot Menu also supports enabling or disabling the internal PSG and PPI's Clicker emulation as well as setting the volumes
for both of them. Use the 'P' key to enter the PSG control screen from the main menu. The following keys can be used in this
screen:

	[ESC]   - save & exit to main menu
	[SPACE] - enable/disable PSG
	[ENTER] - enable/disable PPI Clicker
	[UP]    - increase PSG volume
	[DOWN]  - decrease PSG volume
	[RIGHT] - increase Clicker volume
	[LEFT]  - decrease Clicker volume
	[HOME]  - reset to default values

The volume's value is stored within the small EEPROM on the cartridge board. The value is saved when 'ESC' key is used to
return to the main menu. If the small EEPROM is not present, then the volume setting is only preserved until the power-off.
So setting the volume once allows to play games and listening to the music until the computer is completely switched off.

It is also possible to disable the default FMPAC stereo mode using the setting in the Configuration screen. This will switch
mono mode for FMPAC's output through the Carnivore2's audio socket.

This screen also supports joystick. The joystick's stick movements and using the buttons are interpreted as follows:

	[LEFT],[RIGHT] - same as cursor keys
	[UP],[DOWN]    - same as cursor keys
	[BUTTON A] - enable or disable PSG (same as SPACE)
	[BUTTON B] - apply changes and exit (same as ESC)


Configuration screen
--------------------

Starting from version 2.10 the Boot Menu can be customized and the custom settings will be stored in the configuration EEPROM.
To customize the configuration please use the 'C' key from the main menu. Beside the cursor keys, the following keys can be
used in configuration screen:

	[ESC]   - save & exit to main menu
	[SPACE] - change selected value
	[HOME]  - reset to default values

A user can customize various configuration settings including directory sorting, fade in/out effects, keyboard/joystick delay
as well as the colors (font and background) for the main menu, help screen, volume control screen and PSG setup screen. In
addition, a user can enable or disable the dual-reboot, disable stereo output for FMPAC and select what frequency to use at
startup (50Hz, 60Hz or default computer's frequency).

Pressing 'Home' at any time will restore all customized values to default settings. Holding 'F3' key at the Boot Menu's startup
allows to use the default settings for the UI - all custom settings will be ignored for the session.

Please note that editing of the palette on MSX computers with v991x or v992x video processors will be disabled. Also if the
directory sorting is enabled or disabled, the current autostart entry as well as the master/slave slot assignments are
cleared to prevent a mix-up.

The directory sorting is a complex operation, so if there are many entries in the Boot Menu's directory, then it may take a few
seconds to completely sort all of them. The sorting only happens at the Boot Menu's startup and when the sorting gets enabled
in the configuration screen. If the delay is too uncomfortable for you, please disable the directory sorting option.

This screen also supports joystick. The joystick's stick movements and using the buttons are interpreted as follows:

	[LEFT],[RIGHT] - same as cursor keys
	[UP],[DOWN]    - same as cursor keys
	[BUTTON A] - toggle setting (same as SPACE)
	[BUTTON B] - apply changes and exit (same as ESC)


How to run 2 ROMs at the same time
----------------------------------

Starting from Boot Menu's version 2.30 and the Altera's firmware version 2.30 it is possible to run 2 ROMs at the same time.
The new setup screen was introduced - "Dual-Slot". It can be called with "O" hotkey or by pressing "Enter". The new setup
screen allows to run dual-slot configuration with flexible options selection for the master slot (you can choose what
Carnivore2 built-in devices to enable). You can select 2 ROMs to run simultaneously. The only restriction for the slave slot
is that it can run games with Konami4 and Konami5 mappers as well as small games up to 32kb without mapper. The slave slot
becomes available if there's one unused physical slot found in a computer and this slot is not occupied by another device.

IMPORTANT! By default the slots in the dual-slot mode are non-expanded. This is done to make the selections faster. If you
want to expand the slots, please move the cursor to the "Disable Slot Expansion" setting and select "N" by pressing the
space bar. This will allow you to expand both slots. You can disable the expansion of either slot by putting the cursor
on the corresponding "Expanded" setting and pressing the space bar.

The Boot Menu identifies whether there's a suitable free slot in the MSX and then shows this slot as "slave" in the settings.
The working slots will have their numbers shown on the left side. If only one slot was identified as usable, running 2 ROMs
at the same time will not be possible. To avoid losing the slave slot, please remove all cartridges except Carnivore2 from
your computer.

Be aware, that some cartridge, for example SCC, MegaRAM and other ones that do not modify the slot's area in any way will
not be detected by the Boot Menu, so the slave slot will be available even if it should not be. If Carnivore2 configures
the slave slot as the same slot that is occupied by another device, this may cause conflicts and potentially damage your
MSX. So please make sure that you do have enough free slots before enabling the dual-slot configuration.

Beside the cursor keys, the following keys are usable in the Dual-Slot setup screen:

	[ESC]   - cancel & exit to main menu
	[SPACE] - change or toggle setting select ROM or SCC+ mode
	[ENTER] - apply changes and restart

The ROMs for the dual-slot configuration can be selected from the main menu. The entry for the master slot can be selected 
by pressing "1", the entry for the slave slot can be selected by pressing "2". The "D" key clears the selection as well as
autostart entry. The selection will be visible in the "Dual-Slot" area above the list of ROMs, to the right from the
"Auto-Start".

Also the ROMs can be selected with the "Space" key in the Dual-Slot screen. Pressing space bar will allow to cycle through
the compatible ROMs for each slot. After the full cycle there will be an "empty" selection to keep the slot vacant.

The "Disable Slot Expansion" option is enabled by default. It will allow to select ROMs for unexpanded slots. However, if
you disable this feature, you will be able to configure the devices in the master slot - enable or disable FMPAC, RAM and
IDE separately.

In addition, the master slot can also use the "Konami SCC+" configuration. So you can run SCC+ games in the slave slot and
enjoy SCC+ and a game on a single cartridge. It is recommended to use SCC+ mode only with certain games that support it.

This screen also supports joystick. The joystick's stick movements and using the buttons are interpreted as follows:

	[UP],[DOWN]    - same as cursor keys
	[LEFT],[RIGHT] - apply selected configuration and restart
	[BUTTON A] - toggle setting or select an entry for master or slave slot (same as SPACE)
	[BUTTON B] - exit (same as ESC)


C2MAN and C2MAN40 utilities
---------------------------

The C2MAN utility allows to initialize the cartridge, add ROMs into the FlashROM, create custom configuration entries, edit
the cartridge's directory. The Service Menu allows to see the FlashROM block usage, erase and optimize the directory, upload
the Boot Menu as well as IDE and FMPAC BIOSes into the FlashROM; it also allows to completely erase the FlashROM chip.

The C2MAN utility works only on MSX2 and later computers, it sets the 80 character mode by default. On MSX1 computers this
utility shows an incompatibility note and exits. For MSX1 computers the C2MAN40 utility must be used. This utility, however,
will also work on MSX2 and later computers in 80 character mode, but all messages will be truncated for the 40 character
mode.

Both utilities will automatically reboot a computer after uploading a ROM into the FlashROM chip if the /a and /r command line
options are used.

The utility supports the following command line options:

 C2MAN [filename.rom] [/h] [/v] [/a] [/r] [/su]

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

The FlashROM chip contains 128 blocks by 64kb (8mb in total). The first 4 blocks are occupied by the Boot Menu, directory, IDE BIOS and
FMPAC BIOS. Other blocks are available for a user to add the ROMs. The ROMs that are smaller than 64kb are grouped into one block. For
example two 32kb ROMs will be written into the same 64kb block, eight 8kb ROMs will be grouped into the same 64kb block and finally four
16kb ROMs will be grouped written into the same 64kb block. All this is done automatically.

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
directory entries, 10 per page. The key assignment is similar to the Boot Menu with the exception that you can't start the entry.
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

The RCP stands for "Register Configuration Preset". It is a small data file with the settings for certain non-standard games or
configurations.

When a ROM file doesn't start properly after being detected by the "C2MAN" utility, there may be a need to adjust its configuration.
This can be done either manually - by editing the configuration registers or by loading an RCP (Register Configuration Preset) file.
We are providing a few RCP files for the ROM files that are not working correctly with default configuration.

To load the RCP file manually you need to run the "C2MAN" utility, enter the directory editor and start editing the selected ROM
entry. When editing, select the "Save/load register preset" option and then use "Load register preset file". When asked, enter the
preset's file name and it will be loaded for the entry you are editing. Just save the entry with the new settings and your ROM will
start working correctly.

When you are making your own configuration settings for a selected ROM file, you can always save them into RCP file. You need to
select the "Save/load register preset" option and then use "Save register preset file". When asked, entry the name of the RCP file
and it will be saved for future use.

The latest versions of "C2MAN", "C2MAN40" and "C2RAMLDR" utilities try to automatically find the matching RCP file when a ROM is
being loaded. For example if a user writes the "TEST.ROM" file into the cartridge, the utilities will try to locate the "TEST.RCP"
file and ask a user whether he/she wants to load and use the data from that RCP file. When a ROM file is loaded with the "/a"
command line option, the data from the matching RCP file is automatically applied.


Using the cartridge as MegaRAM
------------------------------

It is possible to use the cartridge as a MegaRAM - for loading ROM images into the cartridge's own RAM and starting them after reboot.
The "C2RAMLDR.COM" utility allows to copy ROM images up to 1mb into the cartridge's RAM and it also creates a directory entry for the
copied ROM with the "RAM:" prefix before the name.

This utility is similar to "C2MAN.COM" utility - it has a menu that allows user to select copying the ROM image into RAM with or without
protection. If the ROM is copied without protection, it will be able to write into its own address space. Some games that have
copy-protection will corrupt their data and won't work. So it's always recommended to apply protection for the copied ROM image in RAM.
The utility can be also used from the command line to automatically load the ROM image into RAM without any user interaction.

The utility has a feature to restart a computer after loading a ROM image into the cartridge's RAM. This can be either done from the
utility's main menu or by specifying the /r command line option together with the /a option.

Please note that the ROM's image exists in the cartridge's RAM only until the next power-off unless there's a battery installed onto
the cartridge's board to always preserve the RAM's data. Don't power-off your MSX if you want to keep the ROM in the cartridge's RAM.
The "RAM:" entries are also selecatable in the Dual-Slot setup screen. They will work only while the power is on.

The old directory entries with "RAM:" prefix, created by the "C2RAMLDR.COM" utility can be deleted by the "C2MAN.COM" utility. After
power-off they become useless anyway.


Using FMPAC's SRAM option
-------------------------

The FMPAC's 8kb SRAM is emulated by the cartridge at the Shadow RAM's address 0FE000h. This area is not affected by the 1mb of primary
RAM in any way. This area is used by certain games to save the data. If the Carnivore2 cartridge doesn't have a backup RAM battery
installed, then the data that was saved into that area will be lost when an MSX computer is switched off. As this data survives the
reset, it's possible to save it to a file and load it back into RAM when needed. The utility that allows to save/load this data is
called "C2SRAM.COM". The files with the save data will have .SRM extension by default and these files will be found by the utility
when a user selects files manually. However the file can be saved with any name and extension. In such a case when a user wants to
upload the file into the emulated SRAM area, he will have to type its name manually.

To save the data it's enough to reset MSX (no power-off!), run the "C2SRAM.COM" utility and save the data to a file. Then a computer
can be switched off. In case a user wants to restore the data and then run a game, the "C2SRAM.COM" utility should be used to upload
the previously saved file into SRAM area. Then a computer should be reset and a game can be then started from the Boot Menu or from
an emulated DSK image.


Backing up and restoring FlashROM's contents
--------------------------------------------

The "C2BACKUP.COM" utility allows to dump the contents of the entire FlashROM chip into a file. The size of the file is 8 megabytes.
The utility also allows to copy the contents of the FlashROM's dump back into the chip. Because of the BIOS shadowing this operation
can be performed live, however the system must be restarted as soon as possible after uploading the new contents into the FlashROM
chip.

The utility asks a user whether he would like to preserve the existing Boot Menu on the cartridge and in case of a positive answer
it doesn't overwrite the existing Boot Menu with the one stored in the backup file. In this case the utility shows the '-' symbol
instead of '>' when skipping writing of the Boot Menu.

WARNING! Interrupting the FlashROM's contents uploading may result in a non-working Carnivore2 cartridge! In this case the cartridge
must be re-initialized. The description of the procedure can be found in the "How to enable the cartridge and install BIOS ROMs"
section of this readme file.


Backing up and restoring configuration EEPROM's contents
--------------------------------------------------------

The "C2CFGBCK.COM" utility allows to dump the contents of the configuration EEPROM chip into a file. The size of the file is 128
bytes. The utility also allows to copy the contents of the EEPROM's dump back into the chip. The system must be restarted after
uploading the new data into the EEPROM chip for the configuration changes to be taken into use.


Testing IDE controller's functionality
--------------------------------------

The "C2IDETST.COM" utility is used to test IDE controller's read/write functionality. When run, it performs 16384 read/write
iterations and shows the passed/failed status of any of the disk operations fail. To stop the test it's necessary to hold the
ESC key. In the end the utility shows the total/success/failed counters.


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

Alternatively, the SCC+ mode could be enabled in the Dual-Slot configuration screen. This allows to enable the SCC+ mode and run a
ROM file in the slave slot (dual-slot configuration) at the same time. It is also possible to set the SCC+ configuration for the master
slot. A computer will need to boot from another device because Carnivore2's IDE device will not be enabled. This way you can run disk
games with SCC+ mode of Carnivore2. Please see the "How to run 2 ROMs at the same time" section for more info.


Directory entry icons
---------------------

The symbols that are displayed near the names of directory entries have certain meaning:

	K5  - Konami 5 SCC
	K4  - Konami 4
	A8  - ASCII 8
	A16 - ASCII 16
	MR  - mini ROM (8, 16, 32, 48 and 64kb ROM without mapper)
	CF  - configuration
	UN  - unknown

For any other symbol there will be just 2 dashes. However, this is unlikely to happen if you use normal MSX ROMs.


Troubleshooting
---------------

The cartridge has a pushbutton to completely disable its functionality if something goes wrong. If the cartridge stops working
correctly, you may need to reinitialize it like described in the "How to enable the cartridge and install ROMs" section. A
computer has to be started while holding the cartridge's pushbutton. When the DOS prompt appears, the button can be released.


Notes
-----

When using Nextor's "_fdisk" command to partition the CF card please make sure you create and start from the configuration entry
that has the expanded slot disabled and the only enabled device there is IDE. Otherwise partitioning will not work.

Carnivore2 is incompatible with the Russian network modules from KYBT and KYBT2 systems. If such network modules are detected in
a system, the Boot Menu outputs a warning message and halts a system.

The audio socket of the Carnivore2 cartridge may not be suitable for connecting the headphones. It's recommended to connect it
to the speakers or to the amplifier. This socket will output emulated SCC and/or FMPAC music and sounds as well as PSG sounds
and PPI clicks if the internal PSG/PPI clicker emulation is enabled.

When booting to DOS on a Panasonic A1 computer (also on A1 MK2), please hold the DEL key while computer reboots after selection
on the default configuration entry and until you see the DOS prompt.

Certain games with the so-called "delayed start", for example Metal Gear 2 and King's Valley 2 will not work on the Russian models
of Yamaha YIS503III computers because of the incompatibility with the built-in CP/M. It is recommended to remove CP/M from the
subrom of these computers or to replace it with a custom-made subrom with better fonts, working RAM counter and built-in TESTRAM.
This custom subrom can be found here: 

https://www.msx.org/forum/msx-talk/hardware/yamaha-msx2-upgrade

The dual-slot functionality doesn't work on at least 2 computers: Sony HB-55 and HB-75. The reason is still unknown. We hope to
mitigate this issue in the future versions of Boot Meny, when the subslot is invoked in the dual-slot emulation functionality.
Certain subslot combinations may not work well on MSX TurboR computers. We will try to fix this as well.


IMPORTANT!
----------

The RBSC provides all the files and information for free, without any liability (see the disclaimer.txt file). The provided information,
software or hardware must not be used for commercial purposes unless permitted by the RBSC. Producing a small amount of bare boards for
personal projects and selling the rest of the batch is allowed without the permission of RBSC.

When the sources of the tools are used to create alternative projects, please always mention the original source and the copyright!


Contact information
-------------------

The members of RBSC group Tnt23, Wierzbowsky, Pencioner, Ptero, GreyWolf and DJS3000 can be contacted via the group's e-mail address:

info@rbsc.su

The group's coordinator could be reached via this e-mail address:

admin@rbsc.su

The group's website can be found here:

https://rbsc.su/

The RBSC's hardware repository can be found here:

https://github.com/rbsc

The RBSC's 3D model repository can be found here:

https://www.thingiverse.com/groups/rbsc/things

-= ! MSX FOREVER ! =-
