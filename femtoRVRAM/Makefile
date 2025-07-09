TARGET = SOC_flash
TOP = SOC_flash

CROSS   = riscv32-unknown-elf
OBJCOPY = $(CROSS)-objcopy
OBJDUMP = $(CROSS)-objdump
LD      = $(CROSS)-ld
AS      = $(CROSS)-as
AFLAGS  = -march=rv32i -mabi=ilp32

OBJECTS = firmware/objects/test.o
OBJECTS += firmware/objects/putchar.o

CORES = SOC_flash.v
#CORES += cores/femtorv32_quark.v
CORES += cores/femtorv32_quark_V2.v
CORES += cores/perip_uart.v
CORES += cores/uart.v
CORES += cores/perip_mult.v
CORES += cores/mult.v
#CORES += cores/MappedSPIFlash.v
CORES += cores/MappedSPIFlash_V3.v
CORES += cores/MappedSPIRAM.v
#CORES+= cores/bram.v

SIM_CORES = sim/cores/spiflash.v
SIM_CORES += sim/cores/spiram.v

ECP5_SIM_CELLS = /home/leodtr/Programs/yosys/share/ecp5/cells_sim.v

SIM_LIB_SKY = lib/verilog_model/sky130_fd_sc_hd.v
SIM_LIB_SKY += lib/verilog_model/primitives.v

BUILD_DIR = build

clean:
	chmod -R u+w synthesis/
	rm -rf *.svg *.json \
	firmware/results/* firmware/objects/*.o \
	sim/results/*.vcd sim/results/*.vpp \
	synthesis/results/* synthesis/*.stat synthesis/*.rpt synthesis/*.dot synthesis/*.json synthesis/*.sdc synthesis/*.log \
	build/*.json build/*.rpt build/*.bit build/*.svf build/*.config

##############
#  firmware  #    export PATH=$PATH:/home/leodtr/Programs/riscv/bin
##############

firmware:
	rm -rf firmware/results/* firmware/objects/*.o
	make firmware.hex

firmware.hex: firmware.elf firmware.lst
	$(OBJCOPY) -O verilog firmware/results/$< firmware/results/$@

firmware.elf: $(OBJECTS) 
	$(LD) -T firmware/bram.ld  -m elf32lriscv -nostdlib -Map firmware/results/firmware.map -N -o firmware/results/$@ $(OBJECTS)
	chmod -x firmware/results/$@

firmware.lst: firmware.elf
	$(OBJDUMP) -h -S firmware/results/$< > firmware/results/$@

%.o: %.S
	$(AS) $(AFLAGS) -c $< -o $@

##################
#  Simulaciones  #
##################

sim_presynth: 
	rm -rf sim/results/presynth_result.vcd sim/results/presynth_result.vpp
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 -o sim/results/presynth_result.vpp sim/presynth_TB.v $(CORES) $(SIM_CORES)
	vvp sim/results/presynth_result.vpp
	gtkwave sim/results/presynth_result.vcd sim/results/presynth.gtkw &

sim_postsynth:
	yosys -v3 -l synthesis/synth.log -p 'setattr -set keep 1 ; synth -flatten; synth_ecp5 -top SOC_flash -json synthesis/$(TOP).json; write_verilog -attr2comment synthesis/results/$(TOP)_synth.v' $(CORES)
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 -DNRV_IS_IO_ADDR -o sim/results/postsynth_result.vpp sim/postsynth_TB.v synthesis/results/$(TOP)_synth.v $(ECP5_SIM_CELLS) $(SIM_CORES)
	vvp sim/results/postsynth_result.vpp
	gtkwave sim/results/postsynth_result.vcd sim/results/postsynth.gtkw &

sim_postsynthSky:
	rm -rf sim/results/postsynthSky_result.vcd sim/results/postsynthSky_result.vpp synthesis/results/$(TOP)_synthSky.v
	yosys -l synthesis/synth.log -c synthesis/synth.tcl
	cp out.v synthesis/results/$(TOP)_synthSky.v
	rm -rf out.v
	iverilog -DFUNCTIONAL -DUNIT_DELAY=#1 -o sim/results/postsynthSky_result.vpp sim/postsynthSky_TB.v synthesis/results/$(TOP)_synthSky.v $(SIM_CORES) $(SIM_LIB_SKY)
	vvp sim/results/postsynthSky_result.vpp
	gtkwave sim/results/postsynthSky_result.vcd sim/results/postsynthSky.gtkw &

sim_postsynthOpenLane:
	iverilog -DFUNCTIONAL -DUNIT_DELAY=#1  -o sim/results/postsynthOpenLane_result.vpp sim/postsynthOpenLane_TB.v femtoRV.v $(SIM_CORES) $(SIM_LIB_SKY)
	vvp sim/results/postsynthOpenLane_result.vpp
	gtkwave sim/results/postsynthOpenLane_result.vcd sim/results/postsynthOpenLane.gtkw &

###################
#  COLORLIGHT I5  #
###################

$(TARGET)_i5.json: $(CORES)
	mkdir -p $(BUILD_DIR)
	yosys -p 'setattr -set keep 1; abc -keepff;  synth -flatten; verilog_defaults -push; verilog_defaults -add -defer; read_verilog -formal $(CORES); verilog_defaults -pop; attrmap -tocase keep -imap keep="true" keep=1 -imap keep="false" keep=0 -remove keep=0; synth_ecp5 -top $(TARGET); write_json $(BUILD_DIR)/$@' -l $(BUILD_DIR)/${TARGET}.rpt

$(TARGET)_i5_out.config: $(TARGET)_i5.json
	nextpnr-ecp5 --json $(BUILD_DIR)/$< --lpf build/$(TARGET)_i5.lpf --textcfg $(BUILD_DIR)/$@ --25k --package CABGA381 --speed 6  --timing-allow-fail --seed 1 --lpf-allow-unconstrained

$(TARGET)_i5.bit: $(TARGET)_i5_out.config
	ecppack --bootaddr 0 --compress $(BUILD_DIR)/$< --svf $(BUILD_DIR)/$(TARGET).svf --bit $(BUILD_DIR)/$@

configure_i5: $(TARGET)_i5.bit
	sudo openFPGALoader -b colorlight-i5 -m $(BUILD_DIR)/$(TARGET)_i5.bit 





.PHONY: clean firmware sim_presynth sim_postsynth sim_postsynth_OpenLane configure_i5
# export PATH=$PATH:/home/leodtr/Embedded/Gowin/IDE/bin
# Install netlistsvg for svg generation
