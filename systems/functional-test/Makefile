VASM=vasm6502_oldstyle
AFLAGS=-Fbin -dotdir

all: 6502_functional_test.bin

clean:
	rm *.bin
	rm *.bin.lst

6502_functional_test.bin: 6502_functional_test.asm
	echo Building image: $(@)
	$(VASM) $(AFLAGS) -L $(@D)/$(@F).lst -o $(@) $<

	@echo
	@echo Image size:
	@stat -c "%s bytes" $(@)
