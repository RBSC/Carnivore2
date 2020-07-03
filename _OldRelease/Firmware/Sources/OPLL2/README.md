vm2413
======

A YM2413 clone module written in VHDL

## Extra Register

Unlike the original YM2413 chip, VM2413's voice parameters are stored in the extra registers 0x40 to 0xD7.
The all embedded voice can be modified through these registers. This means that we can use user-defined voice on every channels
by mapping different voice number to each channel.

By default, the extra registers are disabled. To enable them, set the bit 7 of register 0xF0 to `1`. 
The extra registers need 42 us (152 clocks) waiting time for each access.

|Address|Voice|
|:-:|:--|
|0x40-0x47|@15 User|　　　　　　
|0x48-0x4F|@0 Violin|
|0x50-0x57|@1 Guitar|
|0x58-0x5F|@2 Piano|
|0x60-0x67|@3 Flute|
|0x68-0x6F|@4 Clarinet|
|0x70-0x77|@5 Oboe|
|0x78-0x7F|@6 Trumpet|
|0x80-0x87|@7 Organ|
|0x88-0x8F|@8 Horn|
|0x90-0x97|@9 Synthesizer|
|0x98-0x9F|@10 Harpsicode|
|0xA0-0xA7|@11 Vibraphone|
|0xA8-0xAF|@12 Synthesizer bass|
|0xB0-0xB7|@13 Wood bass|
|0xB8-0xBF|@14 Electrical bass|
|0xC0-0xC7|BD|
|0xC8-0xCF|HH & SD|
|0xD0-0xD7|TOM & CYM|

Note that the MSX-MUSIC `y` MML command can not write the extra registers.
To access the extra registers through MSX-MUSIC on VM2413 (ex. 1chip MSX), use `OUT` command instead.

