--------------------------------------------------------------------------------
Carnivore2 MultiFunctional Cartridge
Copyright (c) 2017-2024 RBSC
--------------------------------------------------------------------------------

The utilities and the readme.txt file were originally made by Vladimir and were
shared with the RBSC team for deploying into the repository. Please note that
this solution may contain the older version of Boot Menu and BIOSes, so it's
advised to update the firmware, Boot Menu, BIOSes and tools from the repository
after enabling your cartridge.

There are 2 different versions of Boot Menu - one is the standard one and the
other is with the special Boot Menu for Arabic and Korean MSXs. If you need the
special version, then you need to use the "CFimage.alt" file instead of the
"CFimage.bin" file.

You can also use the "Carnivore2.rom" file from the OpenMSX subfolder in the
Carnivore's repository. This file should always contain the latest Boot Meny and
BIOSes.


Flashing Boot Menu and BIOSes on a diskless MSX
-----------------------------------------------

This directory contains utilities that allow flashing Boot Menu, IDE and
FMPAC BIOSes into flash memory of newly-assembled cartridge using MSX machine
that does not have a disk drive. The installation uses CF card (with BIOS images
and Boot Menu) plugged into the cartridge. Before using this method the FPGA
firmware must be already updated to the latest compatible version. See the
documentation for the firmware updating instructions.


Flashing instructions
---------------------

Note: Before attempting the following process it is worth verifying that the CF
IDE interface on cartridge is functional. The included cftest utility describe
below can be used for that.

 1. Write "CFimage.bin" file to the physical start of CF card using a card reader
    attached to a PC computer. The file must be written directly to CF card (raw
    image mode), without any file system on the card.
    
    Note: this operation completely destroys any existing file system on a CF
    card, so any existing files on a card will be lost. Backup everything valuable
    first!
    
    NOTE: If, by mistake, this operation is applied to any other local disk drive
    on your computer (such as your system drive) the contents of that disk will be
    destroyed! So, be very careful and check on which drive you write the BIN file!
    
    On unix-like OS use the following command:

      sudo dd if=CfImage.bin of=<path to CF device>

    where <path to CF device> is system specific, on linux it will be something
    like /dev/sdb. Consult your OS documentation for getting this path on other
    systems.
    
    On Windows OS any utility working with disk drives directly must be used. For
    example, WinHex or HXD (https://mh-nexus.de/en/):
    - Start the program as administrator. Open CFImage.bin, select all and copy
      (from edit menu)
    - Open disk from "Extras" menu, select "Removable disk" from list of
      Physical disks. Make sure your CF card is the only removable drive plugged
      into computer to avoid mistakes. Uncheck "Open as Readonly" before
      proceeding
    - Select "Paste Write" from "Edit" menu immidiately after opening disk so
      that cursor is at the start of disk. Select "Save" from file menu
 
 2. Insert CF card into the cartridge. Insert the cartridge into MSX machine.
    Turn on the machine and run the following Basic command:

     bload"cas:",r

    Play the CF2FLASH.WAV or CF2FLASH.MP3 file via the cassette interface of MSX
    machine.
    Note: If Windows Media Player doesn't play the file, use Audacity or VLC Player:
    (http://www.audacityteam.org/)

    !IMPORTANT!
    If the FlashROM is not recognized by the utility or MSX doesn't boot, keep the
    button on Carnivore2 cartridge pressed all the time until the machine boots to
    MSX Basic.
 
 3. Once the program loaded, it will start automatically and will prompt to enter
    the slot number where the cartridge is installed. After they slot number is
    entered, and the operation is confirmed, the program will write all necessary data
    from CF card into the cartridge's FlashROM
   
 4. After the "All done" success message, restart you machine, and you should be
    greeted by the freshly installed Boot Menu.

 
Further steps
-------------
 
From boot menu press Space or Esc in order to boot with default and the only
configuration. Once booted to Nextor Basic, enter command "call fdisk", format
your CF card, transfer MSX DOS2 and other Carnivore utilities to the card from
your PC. Boot with the card in the cartridge straight to MSX DOS2. Enjoy your
machine being not diskless any more!

    
Using CFTEST utility to verify IDE function on cartridge
--------------------------------------------------------

The CFTEST utility allows to dump the contents of a ROM in any slot to screen and
also to read and show the contents of any sectors from Carnivore's CF card when
the slot and subslot are entered correctly.

Run the utility by playing CFTEST.WAV or CFTEST.MP3 file into cassette input after
entering the Basic command:

  bload"cas:",r

NOTE: If Windows Media Player doesn't play the file, use Audacity or VLC Player:
(http://www.audacityteam.org/)

Enter the main slot number of the cartridge, press 1 for the subslot number (IDE),
press "i" key to dump IDE sector. Enter sector number 0, for example. If the IDE
interface functions well and the slot and subslot were entered correctly, the program
will dump the contents of a sector on CF card to the screen. If you entered an
incorrect slot number or the IDE is not working correctly, there will be a long pause
without output followed by an error message.

You can use the "Esc" key to return to slot selection at any time.
