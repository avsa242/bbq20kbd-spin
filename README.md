# bbq20kbd-spin 
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the solderparty BB Q20 keyboard (I2C).

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz
* Read keypress buffer state
* Read keypresses (terminal-standard `getchar()`)
* Read Caps lock and Num lock states
* Read trackpad position (relative, absolute)
* Set trackpad absolute position limits
* Set trackpad sensitivity
* Set keyboard backlight brightness
* Set keyboard press-and-hold duration (time before key repeat)
* Enable/disable modifier keys
* Interrupts: set mask, read source(s), set duration
* Reset the keyboard
* Set the keyboard's I2C address ($08..$77)

## Requirements

P1/SPIN1:
* spin-standard-library

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1	    | SPIN1    | FlexSpin (5.9.23-beta)	| Bytecode    | OK                    |
| P1	    | SPIN1    | FlexSpin (5.9.23-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.23-beta) | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (5.9.23-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Hardware compatibility

* Tested with [Solder Party's BB Q20](https://www.solder.party/docs/bbq20kbd/)

## Limitations

* doesn't handle key repeating yet (i.e., a key being held down)
* doesn't support setting/reading GPIO states

