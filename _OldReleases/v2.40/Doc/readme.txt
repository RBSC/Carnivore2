--------------------------------------------------------------------------------
Carnivore2 MultiFunctional Cartridge version 2.40
Copyright (c) 2017-2020 RBSC
Includes Boot Menu 2.41 bugfix 
Last updated: 17.12.2021
--------------------------------------------------------------------------------

The user guide and technical documentation have been moved into the PDF files:

Carnivore2 User Guide (English).pdf
Carnivore2 User Guide (Russian).pdf
Carnivore2 Technical Description (English).pdf
Carnivore2 Technical Description (Russian).pdf

The CF card/adapter compatibility reference is available in these files:

Carnivore2 Compatibility Reference (English).pdf
Carnivore2 Compatibility Reference (Russian).pdf

The partslist and changelog have been moved into the PDF files:

Carnivore2 Changelog (English).pdf
Carnivore2 Changelog (Russian).pdf
Carnivore2 Partslist (English).pdf
Carnivore2 Partslist (Russian).pdf


The documentation is also available here:

https://sysadminmosaic.ru/msx/carnivore2/carnivore2
https://sysadminmosaic.ru/msx/carnivore2/carnivore2-en
https://sysadminmosaic.ru/msx/carnivore2/specification
https://sysadminmosaic.ru/msx/carnivore2/specification-en
https://sysadminmosaic.ru/msx/carnivore2/changelog
https://sysadminmosaic.ru/msx/carnivore2/changelog-en
https://sysadminmosaic.ru/msx/carnivore2/partslist
https://sysadminmosaic.ru/msx/carnivore2/partslist-en
https://sysadminmosaic.ru/msx/carnivore2/qvl_list
https://sysadminmosaic.ru/msx/carnivore2/qvl_list-en


Bugfixes in Boot Menu 2.41:
---------------------------

 - Fixed a bug in Boot Menu that prevented the second/third Carnivore2 properly reading the configuration settings
 - Fixed a bug in Boot Menu - Arabic/Korean warning was shown twice during boot
 - Fixed a bug in Boot Menu - alert messages were shown on top of title screen if Dual-Reset was not active


Last minute notes
-----------------

The default dual-slot functionality doesn't work on at least 2 computers: Sony HB-55 and HB-75. Please enable the "Slave Slot
as Master's Subslot" option to be able to run 2 ROMs at the same time on these computers. This also applies to certain Arabic
MSXs that have only one free available slot.

If any of your CF cards or SD-to-CF adapters no longer work with Carnivore2, try to replace the IDE bios with an alternative
version. To do this, rename BIDECMFC.ALT into BIDECMFC.BIN and write the IDE BIOS into Carnivore2 with the C2MAN or C2MAN40
utility.

When a computer is just powered on with the Carnivore2 cartridge inserted into a slot, it may reboot twice. This is normal and
was implemented to make sure that the cartridge is fully initialized after the cold boot. You can enable the dual-reboot feature
in the Configuration settings.


IMPORTANT!
----------

The RBSC provides all the files and information for free, without any liability (see the disclaimer.txt file). The provided information,
software or hardware must not be used for commercial purposes unless permitted by the RBSC. Producing a small amount of bare boards for
personal projects and selling the rest of the batch is allowed without the permission of RBSC.

When the sources of the tools are used to create alternative projects, please always mention the original source and the copyright!


Where and how to report problems:
---------------------------------

All problems during testing should be reported to "wierzbowsky@rbsc.su" e-mail address. When reporting a problem please
include the following information and files (inside a ZIP archive):

 - Carnivore2's manufacturer (Maxiol, 8bits4ever, Carmeloco, Retro Game Restore, Other - please specify)
 - Slot number where Carnivore2 was installed
 - Nextor's BIOS and IDE driver version (this is important when you have CF card problem)
 - Detailed problem's description
 - How to reproduce the problem (step-by-step instructions)
 - Screenshot(s) of the problem if applicable
 - File(s) that trigger the problem (ROMs, executables, etc.)
 - MSX computer where the problem was identified (vendor, configuration, external hardware)
 - Dump of your configuration EEPROM if applicable (use C2CFGBCK utility)
 - Dump of your FlashROM if applicable (use C2BACKUP utility)

If you have CF cards that don't work with Carnivore2, please fill one of the templates with the information about your
CF card, please also include a photo of the problematic card. If you have several different cards, please add the
info and pictures of them into the template too. See the example PDF document on how your input should look like.

In addition, you may always ask a question in English or Russian in the RBSC's Discord channel: https://discord.gg/dExqxXe


Contact information
-------------------

The members of RBSC group Tnt23, Wierzbowsky, Pencioner, Ptero, GreyWolf, SuperMax and DJS3000 can be contacted via the group's e-mail
address: info@rbsc.su

The group's coordinator could be reached via this e-mail address: admin@rbsc.su

The group's website can be found here:
https://rbsc.su/
https://rbsc.su/ru

The RBSC's hardware repository can be found here:
https://github.com/rbsc

The RBSC's 3D model repository can be found here:
https://www.thingiverse.com/groups/rbsc/things

-= ! MSX FOREVER ! =-
