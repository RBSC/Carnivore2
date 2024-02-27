--------------------------------------------------------------------------------
Carnivore2 MultiFunctional Cartridge version 2.50
Copyright (c) 2017-2023 RBSC
Last updated: 26.04.2023
--------------------------------------------------------------------------------

On some MSX computers with built-in firmware, for example Sony HB-75P, after exiting the Boot Menu it's impossible to
boot Nextor (DOS2) as the control is passed to the firmware instead of Nextor's BIOS. There's not a trivial way to
bypass the firmware on various MSX systems, but for some of them there is a solution.

This folder contains the special ROM file that should be added into the Carnivore2's FlashROM by the C2MAN or C2MAN40
utility. Please make sure that the RCP file is located in the same folder as the BYPASSFW.ROM when flashing. After a
reboot you need to enter the Dual-Slot configuration screen (with Enter button) and set up the cartridge configuration
as seen on the "bypassfw_cfg.png" image. Once set, press Enter and Carnivore2 will boot into Nextor (DOS2).

The firmware bypassing should work on the following computers: Mitsubishi ML-G1, National FS-4000, FS-4500, FS-4600,
FS-4700, Toshiba HX-21I, HX-22I, HX-23I, Sony HB-55P, HB-75D, HB-75P, HB-101, HB-101P, HB-201, HB-201P, HB-F1, HB-F1II,
HB-F9P/S and maybe on some other systems. On Panasonic FS-A1 and similar systems this ROM should also work. But if it
fails, the only way to boot to Nextor would be removing the firmare from the computer's ROM chip.

See the readme.txt file for more info.


