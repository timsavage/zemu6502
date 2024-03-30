# ZEmu6502 - 8-Bit Micro Computer Emulator

Emulator that emulates 6502 instructions with the same clock timing as a native processor.

Initially developed in Rust before being ported over to using [Zig](https://ziglang.org/).
The Zig compiler (>=0.11) to build the project.

Development is currently on Linux, has not been tested on other OSs.

## Status

All but indirect addressing modes are implemented, these are currently a work in progress.

Most instructions are complete (many with unit tests), any incomplete instructions will
simply will generate a `MicroOpError.NotImplemented` result and be logged but otherwise
behave like a no-op.

### Goals

The initial goal is to run Woz-mon in the emulator to provide a basic test case. 

### Main MCU

Missing features:

* Handling of NMI and IRQs
* Break instruction

### Peripherals

The currently defined peripherals include:

* RAM (resizable but backed by a fixed 64k block)
* ROM (resizable but backed by a fixed 64k block)
* Terminal (basic character output)

Peripherals in development:

* Keyboard

Planned:

* Banked RAM
* Bit-mapped graphics (incorporating a terminal)
* Sound device
* Serial devices
* Emulation of an IO controller
* GPIO via external hardware.

## Design

Every instruction is made up of micro-operations, these are the actual operations 
that are executed on each clock cycle and correspond with the same behaviour of a
physical MPU.

Peripherals are implemented with a standard peripheral interface providing:

* read/write functions using a 16bit address and 8bit data
* clock signal (with both rising and falling edges)

Future enhancement to include NMI and IRQ status requests.

A system clock provides both positive and negative edges at a configurable frequency
used to drive operations of the machine at a fixed rate. 

A system module acts as the address bus and decode logic to route address lookup 
requests between the MCU and peripherals. Along with clock and NMI and IRQ states.

### Memory Map

The basic memory map can be found in the `src/system.zig` file in the `resolvePeripheral`
function.

| Address Range | Peripheral | Notes                                   |
|---------------|------------|-----------------------------------------|
| 0x0000-0x3FFF | RAM        |                                         |
| 0x0100-0x01FF |            | Stack                                   |
| 0x4000-0x7FFF | -          |                                         |
| 0x8000        | Terminal   | Write-only, data treated as characters. |
| 0x8001-0x800F | -          |                                         |
| 0x8010        | Keyboard   | Read-only, not currently implemented.   |
| 0x801F-0xEFFF | -          |                                         |
| 0xFF00-0xFFFF | ROM        | Read-only                               |
| 0xFFFA-0xFFFF |            | NMI/Reset/IRQ vectors                   |

### Common systems

The system layer allows emulation of any common 6502 based computer by customising the memory
map and behaviours of the peripherals. A long term goal is to all these to be defined via 
configuration with some common systems e.g. C64 or Apple 1/II be bundled with the code.
