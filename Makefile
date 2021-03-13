# Usage:
#
# Build a bin file using nextpnr
# > make build
#
# Build a bin file using arachne-pnr
# > make build legacy=y
#
# Program the Cu
# > make program

# top-level module name
module ?= cu_0

sources = $(wildcard work/verilog/*.v)
constraints = work/constraint/merged_constraint.pcf

yosys_bin ?= yosys
nextpnr_bin ?= nextpnr-ice40
arachne_bin ?= arachne-pnr
icepack_bin ?= icepack
iceprog_bin ?= iceprog

bin_dep = $(if $(legacy), work/cu.txt, work/cu.asc)

work/cu.json: $(sources)
	$(yosys_bin) -p "synth_ice40 -top $(module) -json $@" $(sources)

work/cu.blif: $(sources)
	$(yosys_bin) -p "synth_ice40 -top $(module) -blif $@" $(sources)

work/cu.asc: work/cu.json $(constraints)
	$(nextpnr_bin) --json $< --hx8k --pcf $(constraints) --package cb132 --asc $@

work/cu.txt: work/cu.blif $(constraints)
	$(arachne_bin) -d 8k -P cb132 -o $@ -p $(constraints) $<

work/cu.bin: $(bin_dep)
	$(icepack_bin) $< $@

.PHONY: build
build: work/cu.bin

.PHONY: program
program: work/cu.bin
	$(iceprog_bin) -I A -d i:0x0403:0x6010 -b $<

.PHONY: clean
clean:
	rm -f work/cu*.{bin,asc,txt,blif,json}

