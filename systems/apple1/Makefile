VASM=vasm6502_oldstyle
AFLAGS=-Fbin -dotdir

all: wozmon-rom.bin

clean:
	rm *.bin
	rm *.bin.lst

wozmon-rom.bin: wozmon-rom.asm
	echo Building image: $(@)
	$(VASM) $(AFLAGS) -L $(@D)/$(@F).lst -o $(@) $<

	@echo
	@echo Image size:
	@stat -c "%s bytes" $(@)
