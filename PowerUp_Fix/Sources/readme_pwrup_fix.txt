Carnivore2 MultiFunctional Cartridge version 2.2
Copyright (c) 2017-2018 RBSC
Portions (c) Mitsutaka Okazaki
Portions (c) Kazuhiro Tsujikawa
Last updated: 12.09.2018

The Altera firmware was created by RBSC. Commercial usage is not allowed!

This is the fix for the Carnivore2 cartridge that allows it to be fully initialized after power-up
on computers with too short power-up cycle. The Carnivore2 cartridge requires at least 190ms to load
the firmware into the Altera chip. On most of MSX computers the power-up cycle (time until the Reset
(RST) signal goes high after power-on) is more than 200ms. But on some computers this cycle is very
short - 150ms or shorter. As a result the cartridge doesn't get fully initialized before the computer
starts executing the BIOS's code.

The fix for this problem is quite simple. It requires 1 shottky SMD diode RB521S-30, a thin wire and
a new firmware to be uploaded into the cartridge.

The diode must be installed instead of the R26 resistor. The diode must be installed so that its anode
is facing the slot contacts. After the diode is installed, the previously removed 330 Ohm resistor
must be soldered to its cathode. Finally a thin wire must be soldered from the other end of the resistor
to the ground (GND). See the powerup_fix.jpg image. The diode's cathode is marked with a red stripe.

When the hardware fix is done, the cartridge must be tested in the computer. If the fix is correct,
then the computer will not boot. The last step is to upload the specially modified firmware into the
cartridge. The name of the firmware's file is "carnivore2_pwrup_fix.pof". After uploading the firmware
the MSX will start normally and the cartridge will be fully initialized after power-on.


IMPORTANT!
----------
Please note that this modification is done on your own risk. RBSC is not responsible for any problems
resulted from implementing this fix into the Carnivore2 cartridge.

Also please note that installing this fix yourself on a cartridge that was bought from our official
manufacturers may void your warranty. So please consult the seller of the cartridge if you want to
attempt this fix on your own!
