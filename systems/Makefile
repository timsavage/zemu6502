VASM=vasm6502_oldstyle
AFLAGS=-Fbin -dotdir

all: default

clean:
	rm -rf out

out/%.bin: %.asm out
	echo Building image: $(@)
	$(VASM) $(AFLAGS) -L $(@D)/$(@F).lst -o $(@) $<

	@echo
	@echo Image size:
	@stat -c "%s bytes" $(@)

out:
	mkdir -p $@

default: out/default-rom.bin
wozmon: out/wozmon-rom.bin
input: out/input-rom.bin
