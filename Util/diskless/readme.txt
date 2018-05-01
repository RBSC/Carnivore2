Carnivore2 MultiFunctional Cartridge version 2.2
Copyright (c) 2017-2018 RBSC

The utilities and the readme.txt file were made by Vladimir and shared with the
RBSC team for deploying into the repository.


Installing ROMs on diskless machine
-----------------------------------

This directory contains utilities that allow flashing Boot Block, IDE BIOS and
FMPAC BIOS to flash memory of newly assembled cartridge using MSX machine
that does not have disk drive. The installation uses CF card with BIOS images
plugged into the cartridge itself. Thus before using this method the FPGA
firmware shall be already loaded to cartridge as describe in readme.txt file in
root directory.


Installation process
--------------------

Note: Before attempting the following process it is worth verifying that the CF
IDE interface on cartridge is functional. The included cftest utility describe
below can be used for that.

 1. Write CfImage.bin file at the start of CF card using CF interface attached
    to PC computer. The file shall be written directly to CF card bypassing any
    file system on the card. 
    
    Note: this operation completely destroys any existing file system on the
    card so any existing files on the card will be lost. Backup anything
    valuable first.
    
    NOTE: If by mistake the operation is applied to any other disk on your
    machine (such as your system disk) the contents of that disk will be
    destroyed. Be warned and take care.
    
    On unix-like OS use the following command:
      sudo dd if=CfImage.bin of=<path to CF device>
    where <path to CF device> is system specific, on linux it will be something
    like /dev/sdb. Consult your OS documentation for getting this path on other
    systems.
    
    On windows machine a utility working with disk drives directly shall be
    used. HXD is one such utility (https://mh-nexus.de/en/):
    - Start the program as administrator. Open CfImage.bin, select all and copy
      (from edit menu).
    - Open disk from "Extras" menu, select "Removable disk" from list of
      Physical disks. Make sure your CF card is the only removable drive plugged
      into computer to avoid mistakes. Uncheck "Open as Readonly" before
      proceeding.
    - Select "Paste Write" from "Edit" menu immidiately after opening disk so
      that cursor is at the start of disk. Select "Save" from file menu
 
 2. Insert CF card into the cartridge. Insert the cartridge into MSX machine.
    Turn on the machine and issue the following Basic command:

     bload"cas:",r

    Play the CF2BIOS.WAV file into cassette input of MSX machine. Note: Windows
    Media Player can not play the file, use audocity
    (http://www.audacityteam.org/)  
 
 3. Once the program loaded it will start automatically and will prompt to enter
    slot number where the cartridge is installed. After slot number is entered
    and confirmed the program will work autmatically, printing currently executed
    operation on screen.
   
 4. After final success message is printed, restart you machine, you should be
    greeted by the Boot Menu.

 
Further steps
-------------
 
From boot menu press Space in order to boot with default and the only
configuration. Once booted to Nextore Basic, enter command "call fdisk", format
your CF card, transfer MSX DOS and  other Carnivore utilities to the card from
your PC. Boot with the card in the cartridge straight to MSX DOS. Enjoy your
machine being not diskless any more

    
Using CFTEST utility to verify IDE function on cartridge
--------------------------------------------------------

Run the utility by playing CFTEST.WAV file into cassette input after entering
Basic command:

  bload"cas:",r

NOTE: Windows Media Player can not play the file, use audocity(http://www.audacityteam.org/)

Enter slot number of the cartridge, press 1 for subslot number,  press "i" key
to dump ide block, enter block number 0. If the IDE interface functions correctly
the program will dump the start of first block on CF card immediately. If you
entered incorrect slot number or IDE is not functional, the will be a long pause
without output, followed by error message. Press "Esc" key to return to slot
selection.
