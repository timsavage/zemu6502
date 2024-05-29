VASM=vasm6502_oldstyle
AFLAGS=-Fbin -dotdir

all: os-rom.bin

clean:
	rm *.bin
	rm *.bin.lst

os-rom.bin: os-rom.asm characters.asm interrupts.asm reset.asm
	echo Building image: $(@)
	$(VASM) $(AFLAGS) -L $(@D)/$(@F).lst -o $(@) $<

	@echo
	@echo Image size:
	@stat -c "%s bytes" $(@)
