# Systems

Systems are defined in a yaml configuration file, see `default.yaml` for a documented config
file. Due to limitations of the YAML reader in Zig all non-null fields must be supplied.

## Build ROM image

All ROM images are built from ASM using the vasm assembler.

## VASM Assembler

The VASM assemble can be obtained from the [vasm website](http://sun.hasenbraten.de/vasm/).

VASM needs to be compiled for the 6502 using the `oldstyle` syntax for example:

```shell
make CPU=6502 SYNTAX=oldstyle
```

Put the resulting binary into your `$PATH`.
