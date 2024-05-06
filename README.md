# ZEmu6502 - 8-Bit Micro Computer Emulator

[![Unit Tests](https://github.com/timsavage/zemu6502/actions/workflows/unit_tests.yaml/badge.svg?branch=main)](https://github.com/timsavage/zemu6502/actions/workflows/unit_tests.yaml)

Emulator that emulates 6502 instructions with the same clock timing as a native processor.

Initially developed in Rust before being ported over to using [Zig](https://ziglang.org/).

Development is currently on Linux, has not been tested on other OSs.

## Install/Build

The Zig compiler (0.12/nightly) is required to build the project.

Use `zig build run -- systems/default.yaml` to build and run the emulator.

## Status

All but indirect addressing modes are implemented, these are currently a work in progress.

Most instructions are complete (many with unit tests), any incomplete instructions will
simply will generate a `MicroOpError.NotImplemented` result and be logged but otherwise
behave like a no-op.

Definition of peripherals and their memory locations is configured via a configuration file.

### Goals

The initial goal is to run Woz-mon in the emulator to provide a basic test case.

### Devices

Devices in development:

* Bit-mapped graphics (incorporating a terminal)

Planned:

* Banked RAM
* Sound device
* Serial devices
* Emulation of an IO controller
* GPIO via external hardware.

### Debugging

A debug interface using the GDB remote debugging protocol is provided (if enabled in
configuration). A Python script in `scripts/gdb-6502.py` provides a basic interactive
interface (GDB itself does not support the 6502). This script will get improvements
over time, but for now it can read/write and memory address, read all registers,
halt/step the processor, query peripherals and reset the system.

Writing back to registers could be added in the future.

## Design

Every instruction is made up of micro-operations, these are the actual operations
that are executed on each clock cycle and correspond with the same behaviour of a
physical MPU.

Peripherals are implemented with a standard peripheral interface providing:

* read/write functions using a 16bit address and 8bit data
* clock signal (with both rising and falling edges)
* optional load function to load a binary (primarily to initialise ROM)
* optional register dump function for future gdb integration

Future enhancement to include NMI and IRQ status requests.

A system clock provides both positive and negative edges at a configurable frequency
used to drive operations of the machine at a fixed rate.

A system module acts as the address bus and decode logic to route address lookup
requests between the MCU and peripherals. Along with clock and NMI and IRQ states.

### Default Memory Map

The default system can be found in the `systems/default.yaml` and resolves to:

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

## Devices

### Builtin

Simple virtual devices not based on a physical component.

* ram - RAM device, defaults to 0xFFFF bytes (actual addressable range based on config)
* rom - ROM device, defaults to 0x8000 bytes (actual addressable range based on config)
  * Use load option to provide an initial ROM image
* terminal - Basic character terminal to output text Apple I style
* keyboard - Keyboard input

### Versatile Interface Adapter (VIA) devices

* w65c22 - WDC W65C22 VIA device (in development currently only provides registers)
