# Mini11: A Small 68HC11A System

The Mini11 is a small board that is designed to provide a complete large
68HC11 environment with a fairly low chip count. It provides 16K of ROM and
512K of RAM as well as breaking out all the spare I/O including the serial
and SPI in useful ways.

To keep cost down it's designed to use the many old 68HC11A series parts
that can be found in junk boxes and old boards. This has a different pinout
to the later processor variants.

## Requirements

- 68HC11A series processor (A0/A1/A8). 68HC811A probably works too
- 512K SRAM
- 27C256 or 28C256
- 74HC(T)139
- 74HC(T)00
- 74HC(T)573
- DS1233 reset controller
- 8MHz crystal
- pinheaders, sockets, resistors etc

## Construction

As the 68HC11 can be serial bootstrapped it is possible to assemble the
board and fit all the discrete parts and only the 68HC11 into its socket.
Fit jumpers JP1 and JP2 and apply power. You should be able to talk to the
board with db11 or similar tools.

If you have a part with ROM then you should also be able to boot from the
ROM if you boot with JP1 and JP2 removed. If the ROM contains Buffalo as
is usual then you will also need to jumper PE0 to ground. A 68HC11A8 with
Buffalo should then produce a boot message and you'll be able to talk to
the monitor.

The boot mode can also be used to check out the board after the other parts
are fitted. You can boot in single chip mode and then use db11 to turn off the
single chip mode and then check that the memory is behaving. Port A controls
the memory banking. Bit 3 turns the ROM on and off, bits 4-6 are the memory
bank.

With all the parts fitted you can burn firmware of choice into the ROM and
with the jumpers removed the chip should boot the firmware. Remember to use
the ".burn" file with the provided firmware or the tools to flip bit 0 and 2
as the board has D0 and D2 switched on the ROM

The provided firmware simply intializes the SD interface, loads the
first sector and runs it.

### Note

You cannot run an unmodified Buffalo from the ROM. It uses Port A pins for
tracing and this conflicts with the memory banking.

## ROM options

For a 27C256 you can load different firmware into each 16K bank and select
using JP3. For a 28C256 burn the firmware into the upper 16K and jumper JP3
to VCC.

## Rescuing Recalcitrant 68HC11A Parts

If you have problems with the 68HC11A such as it only coming up in bootstrap
mode then there are a few things to check.

### Wrong Config Byte

If the CONFIG byte is set to map in the internal ROM and the ROM contains
garbage or is absent (eg on a 68HC11A0/A1 part) then you can boot it into
single chip mode and use db11 to change the config byte to 0x0C or similar.

### Protected EEROM

The internal EEROM has protection options and some devices wih custom
firmware will set them. These can still be used as they will erase the
EEPROM when the serial boot is triggered. This will put 0F into the CONFIG
register so that will also then need reprogramming.

### Did You Remember D0/D2 Are Swapped In Your ROM Image

No.. opps

## External Interfaces

### J2: Serial (TTL Level)

Simple three wire interface with no flow control. Usually run at 9600 baud.

### J3: SPI (5v)

SPI. Provides the expected SPI interfaces as well as two chip select lines,
reset and the external IRQ (pulled up). Intended for an SD card and
optionally additional devices with an SPI mux/demux board. Remember to use
an SD adapter with voltage shifting.

### J4: Power

5v and ground, needs to be properly regulated. The board has an onboard
reset generator to handle power coming up gracefully.

## J5: GPIO

Three input ports mapped to port A bits 0-2

### J6: Analogue

Port E of the 68HC11.

## Jumpers

### JP1: MODA

Fit the jumper to set MODA low

### JP2: MODB

Fit the jumper to set MODB low

### JP3: ROM Select

Select back on 27C256, set to 5V with a 28C256

## Software

At this point FUZIX. Build the "mini11" target, write the generated SD card
image raw to an SD card and boot the mini11 with it inserted. The console
runs at 9600 baud.
