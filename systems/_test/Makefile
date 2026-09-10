VASM=vasm6502_oldstyle
AFLAGS=-Fbin -dotdir

all: test.bin

clean:
	rm *.bin
	rm *.bin.lst

test.bin: test.asm
	echo Building image: $(@)
	$(VASM) $(AFLAGS) -L $(@D)/$(@F).lst -o $(@) $<

	@echo
	@echo Image size:
	@stat -c "%s bytes" $(@)
