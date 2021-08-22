MODULE       ?= Main
USE_DOCKER   ?= 1

icepack_cmd  := icepack
nextpnr_cmd  := nextpnr-ice40
yosys_cmd    := yosys
iceprog_cmd  := iceprog
vvp_cmd      := vvp
iverilog_cmd := iverilog

ifeq ($(USE_DOCKER), 1)

use_tty      := $(shell [ -t 0 ] && echo -it)

docker_img   := kovagoz/icestorm
docker_run   := docker run --rm $(use_tty) -v $(PWD):/host -w /host

icepack_cmd  := $(docker_run) $(docker_img) $(icepack_cmd)
nextpnr_cmd  := $(docker_run) $(docker_img) $(nextpnr_cmd)
yosys_cmd    := $(docker_run) $(docker_img) $(yosys_cmd)
iceprog_cmd  := $(docker_run) --device /dev/ttyUSB1 --privileged --user 0 $(docker_img) iceprog
vvp_cmd      := $(docker_run) --entrypoint vvp kovagoz/iverilog:0.5.0
iverilog_cmd := $(docker_run) kovagoz/iverilog:0.5.0

endif

# --  BUILDING ------------------

.PHONY: build
build: bin/$(MODULE).bin

bin/$(MODULE).bin: bin/$(MODULE).asc
	$(icepack_cmd) $< $@

bin/$(MODULE).asc: bin/$(MODULE).json constraints.pcf
	$(nextpnr_cmd) --hx1k --package vq100 --json $< --pcf $(word 2,$^) --asc $@

bin/$(MODULE).json: src/$(MODULE).v bin
	$(yosys_cmd) -p 'synth_ice40 -top $(MODULE) -json $@' $<

bin:
	mkdir $@

constraints.pcf: # Download the constraints file for Go Board
	curl https://www.nandland.com/goboard/Go_Board_Constraints.pcf > $@

.PHONY: clean
clean:
	rm -f {bin,test}/$(MODULE).{json,asc,bin,vvp,vcd}

# -- PROGRAMMING ----------------

.PHONY: install
install: bin/$(MODULE).bin # Send bitstream to the Go Board
	$(iceprog_cmd) $<

# -- TESTING --------------------

.PHONY: test
test: test/$(MODULE).vcd # Run the simulation and show results in GTKWave
	open -a gtkwave $<

test/$(MODULE).vcd: test/$(MODULE).vvp
	$(vvp_cmd) $<

test/$(MODULE).vvp: test/$(MODULE).v
	$(iverilog_cmd) -I src -I test -o $@ \
		-DDUMPFILE_PATH=$(basename $@).vcd \
		-DTEST_SUBJECT=$(MODULE) \
		$<

# -- MISC -----------------------

.PHONY: stats
stats:
	$(yosys_cmd) -p 'stat -top $(MODULE)' src/$(MODULE).v
