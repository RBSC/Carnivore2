vm2413
======

A YM2413 互換モジュール VHDL

## 拡張レジスタ

オリジナルのYM2413とは異なり、VM2413は音色データを拡張レジスタ 0x40-0xD7 に格納しており、
組み込み音色をすべて書き換えることができます（つまり、チャンネル毎に別の音色を割り当てれば、全チャンネルで異なる音色を利用できます）。

拡張レジスタは、デフォルトでは無効になっています。有効にするにはレジスタ 0xF0 の ビット 7 を `1` にします。
拡張レジスタへの書き込みには 42 us (152クロック)のウェイトが必要です。

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

なお、MSX-BASIC の MML の `y` コマンドでは、上記のレジスタにアクセスできません。1chip MSX など VM2413 を搭載した環境のBASICで上記のレジスタを利用する際は、`OUT`　コマンドを使う必要があります。

