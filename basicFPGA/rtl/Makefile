#   run make TOP=SOC or make TOP=SOC_flash
EFINITY_HOME  = /home/carlos/Embedded/efinity/2023.2/
EFXPT_HOME    = $(EFINITY_HOME)/pt

SOC = SOC
TARGET=SOC_flash
TOP=SOC_flash_syn

ECP5_SIM_CELLS=$(shell yosys-config --datdir/ecp5/cells_sim.v)

COMM_OBJS= cores/cpu/femtorv32_quark.v
COMM_OBJS+= cores/uart/perip_uart.v
COMM_OBJS+= cores/uart/uart.v
COMM_OBJS+= cores/mult/perip_mult.v
COMM_OBJS+= cores/mult/mult.v

OBJS = SOC_flash.v
OBJS+= cores/cpu/femtorv32_quark.v
OBJS+= cores/uart/perip_uart.v
OBJS+= cores/uart/uart.v
OBJS+= cores/mult/perip_mult.v
OBJS+= cores/mult/mult.v
OBJS+= cores/spi_flash/MappedSPIFlash.v
OBJS+= cores/spi_ram/MappedSPIRAM.v

SIM_OBJS = cores/sim_spi_flash/spiflash.v
#SIM_OBJS+= cores/sim_spi_ram/spiram.v



BUILD_DIR = build

all: $(TARGET).fs

$(TARGET).fs: 
	gw_sh  soc_src.tcl

${TARGET}.svf : ${TARGET}.bit


sim: 
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 bench_iverilog.v soc_femto.v
	vvp a.out
	gtkwave bench.vcd

sim_quark:
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 bench_quark.v $(OBJS)
	vvp a.out
	gtkwave bench.vcd pre.gtkw &

sim_quark_flash:
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 bench_quark_flash.v $(OBJS) $(SIM_OBJS)
	vvp a.out
	gtkwave bench.vcd pre.gtkw &

sim_quark_flash_ram:
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 bench_quark_flash_ram.v $(OBJS) $(SIM_OBJS)
	vvp a.out
	gtkwave bench.vcd ram.gtkw

sim_verilator: 
	verilator -CFLAGS '-I../libfemtorv32/ -DSTANDALONE_FEMTOELF' -DBENCH -DBOARD_FREQ=10 -DCPU_FREQ=10 -DPASSTHROUGH_PLL -Wno-fatal \
	--top-module SOC -cc -exe sim_main.cpp libfemtorv32/femto_elf.c soc_femto.v
	cd obj_dir; make -f VSOC.mk 
	obj_dir/VSOC

## ---------------------
## post-synth simulation
## ---------------------
sim_post_syn:  $(FLASH_OBJS)
	yosys -v3 -l synth.log -p 'setattr -set keep 1 ; synth -flatten; synth_ecp5 -top SOC_flash -json $(TOP).json; write_verilog -attr2comment $(TOP)_synth.v' ${OBJS}
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 -DNRV_IS_IO_ADDR -o $@_PS.vpp -s bench bench_quark_flash.v SOC_flash_syn_synth.v $(ECP5_SIM_CELLS)  $(SIM_OBJS)
	vvp $@_PS.vpp
	gtkwave bench.vcd post.gtkw &
  	
svg: $(FLASH_OBJS)
	yosys -p "prep -top ${TARGET}; write_json ${TARGET}.json" -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27  ${FLASH_OBJS}
	netlistsvg ${TARGET}.json -o ${TARGET}.svg  #--skin default.svg
	yosys -p "prep -top ${TARGET} -flatten; write_json ${TARGET}_flat.json" ${FLASH_OBJS}
	netlistsvg ${TARGET}_flat.json -o ${TARGET}_flat.svg  #--skin default.svg

	
########################
#  LATTICE COLORLIGHT I5
########################
$(TARGET)_i5.json: $(FLASH_OBJS)
	mkdir -p $(BUILD_DIR)
	yosys -p 'verilog_defaults -push; verilog_defaults -add -defer; read_verilog -formal $(OBJS); verilog_defaults -pop; attrmap -tocase keep -imap keep="true" keep=1 -imap keep="false" keep=0 -remove keep=0; synth_ecp5 -top $(TARGET); write_json $(BUILD_DIR)/$@' -l $(BUILD_DIR)/${TARGET}.rpt

$(TARGET)_i5_out.config: $(TARGET)_i5.json
	nextpnr-ecp5 --json $(BUILD_DIR)/$< --lpf $(TARGET)_i5.lpf --textcfg $(BUILD_DIR)/$@ --25k --package CABGA381 --speed 6  --timing-allow-fail --seed 1 --lpf-allow-unconstrained

$(TARGET)_i5.bit: $(TARGET)_i5_out.config
	ecppack --bootaddr 0 --compress $(BUILD_DIR)/$< --svf $(BUILD_DIR)/${TARGET}.svf --bit $(BUILD_DIR)/$@

configure_i5: ${TARGET}_i5.bit   # TDI:TDO:TCK:TMS
	sudo openFPGALoader -b colorlight-i5 -m $(BUILD_DIR)/${TARGET}_i5.bit 

.PHONY: clean


##########################
#    EFINIX ECB_T20_T113
##########################
EFINITY_HOME=/home/carlos/Embedded/efinity/2023.2/
EFXPT_HOME=$(EFINITY_HOME)/pt
create_files:
	export EFINITY_HOME=/home/carlos/Embedded/efinity/2023.2/
	export EFXPT_HOME=$(EFINITY_HOME)/pt
	$(EFINITY_HOME)/bin/python3  femtorv32.py
synth: create_files
	$(EFINITY_HOME)/bin/efx_map --project "$(TOP)" --root "$(TOP)" --write-efx-verilog "outflow/$(TOP).map.v" --write-premap-module "outflow/$(TOP).elab.vdb" --binary-db "outflow/$(TOP).vdb" --device "T20Q144" --family "Trion" --veri_option "verilog_mode=verilog_2k,vhdl_mode=vhdl_2008" --work-dir "work_syn" --output-dir "outflow" --project-xml "$(TOP).xml" --I "."
place_and_route: synth
	$(EFINITY_HOME)/bin/python3  "/home/carlos/Embedded/efinity/2023.2/scripts/efx_run_pt.py"  "$(TOP)"  "Trion"  "T20Q144"
	$(EFINITY_HOME)/bin/efx_pnr --circuit "$(TOP)" --family "Trion" --device "T20Q144" --operating_conditions "C3" --pack --place --vdb_file "outflow/$(TOP).vdb" --use_vdb_file "on" --place_file "outflow/$(TOP).place" --route_file "outflow/$(TOP).route" --sdc_file "$(TOP).sdc" --sync_file "outflow/$(TOP).interface.csv" --seed "1" --placer_effort_level "2" --max_threads "-1" --print_critical_path "10" --work_dir "work_pnr" --output_dir "outflow" --timing_analysis "on" --load_delay_matrix
	$(EFINITY_HOME)/bin/efx_pnr --circuit "$(TOP)" --family "Trion" --device "T20Q144" --operating_conditions "C3" --route --vdb_file "outflow/$(TOP).vdb" --use_vdb_file "on" --place_file "outflow/$(TOP).place" --route_file "outflow/$(TOP).route" --sdc_file "$(TOP).sdc" --sync_file "outflow/$(TOP).interface.csv" --seed "1" --placer_effort_level "2" --max_threads "-1" --print_critical_path "10" --work_dir "work_pnr" --output_dir "outflow" --timing_analysis "on" --load_delay_matrix
bitstream: place_and_route
	$(EFINITY_HOME)/bin/efx_pgm --source "work_pnr/$(TOP).lbf" --dest "outflow/$(TOP).hex" --device "T20Q144" --family "Trion" --periph "outflow/$(TOP).lpf" --interface_designer_settings "outflow/$(TOP)_or.ini" --enable_external_master_clock "off" --oscillator_clock_divider "DIV8" --active_capture_clk_edge "posedge" --spi_low_power_mode "on" --io_weak_pullup "on" --enable_roms "smart" --mode "active" --width "1" --release_tri_then_reset "on"
configure_efinix: outflow/$(TOP).bit
	openFPGALoader -b trion_t120_bga576  outflow/$(TOP).bit
clean_efinix:
	rm -rf work_pnr work_pt work_syn outflow $(TOP).peri.xml

######################
#    SPI  FLASH      #
######################

##########################
#    EFINIX ECB_T20_T113
##########################

EFINITY_HOME=/home/carlos/Embedded/efinity/2023.2/
EFXPT_HOME=$(EFINITY_HOME)/pt

svg_flash: $(FLASH_OBJS)
	yosys -p "prep -top ${TARGET}; write_json ${TARGET}.json" -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27  ${FLASH_OBJS}
	netlistsvg ${TARGET}.json -o ${TARGET}_flash.svg  #--skin default.svg
	yosys -p "prep -top ${TARGET} -flatten; write_json ${TARGET}_flat.json" ${FLASH_OBJS}
	netlistsvg ${TARGET}_flat.json -o ${TARGET}_flat_flash.svg  #--skin default.svg



create_files_flash:
	$(EFINITY_HOME)/bin/python3  femtorv32_flash.py
synth_flash: create_files_flash
	$(EFINITY_HOME)/bin/efx_map --project "$(TOP)" --root "$(TOP)" --write-efx-verilog "outflow/$(TOP).map.v" --write-premap-module "outflow/$(TOP).elab.vdb" --binary-db "outflow/$(TOP).vdb" --device "T20Q144" --family "Trion" --veri_option "verilog_mode=verilog_2k,vhdl_mode=vhdl_2008" --work-dir "work_syn" --output-dir "outflow" --project-xml "$(TOP).xml" --I "."
place_and_route_flash: synth_flash
	$(EFINITY_HOME)/bin/python3  "/home/carlos/Embedded/efinity/2023.2/scripts/efx_run_pt.py"  "$(TOP)"  "Trion"  "T20Q144"
	$(EFINITY_HOME)/bin/efx_pnr --circuit "$(TOP)" --family "Trion" --device "T20Q144" --operating_conditions "C3" --pack --place --vdb_file "outflow/$(TOP).vdb" --use_vdb_file "on" --place_file "outflow/$(TOP).place" --route_file "outflow/$(TOP).route" --sdc_file "$(TOP).sdc" --sync_file "outflow/$(TOP).interface.csv" --seed "1" --placer_effort_level "2" --max_threads "-1" --print_critical_path "10" --work_dir "work_pnr" --output_dir "outflow" --timing_analysis "on" --load_delay_matrix
	$(EFINITY_HOME)/bin/efx_pnr --circuit "$(TOP)" --family "Trion" --device "T20Q144" --operating_conditions "C3" --route --vdb_file "outflow/$(TOP).vdb" --use_vdb_file "on" --place_file "outflow/$(TOP).place" --route_file "outflow/$(TOP).route" --sdc_file "$(TOP).sdc" --sync_file "outflow/$(TOP).interface.csv" --seed "1" --placer_effort_level "2" --max_threads "-1" --print_critical_path "10" --work_dir "work_pnr" --output_dir "outflow" --timing_analysis "on" --load_delay_matrix
bitstream_flash: place_and_route_flash
	$(EFINITY_HOME)/bin/efx_pgm --source "work_pnr/$(TOP).lbf" --dest "outflow/$(TOP).hex" --device "T20Q144" --family "Trion" --periph "outflow/$(TOP).lpf" --interface_designer_settings "outflow/$(TOP)_or.ini" --enable_external_master_clock "off" --oscillator_clock_divider "DIV8" --active_capture_clk_edge "posedge" --spi_low_power_mode "on" --io_weak_pullup "on" --enable_roms "smart" --mode "active" --width "1" --release_tri_then_reset "on"
configure_efinix_flash: outflow/$(TOP).bit
	openFPGALoader -b trion_t120_bga576  outflow/$(TOP).bit
clean_efinix_flash:
	rm -rf work_pnr work_pt work_syn outflow $(TOP).peri.xml

clean: clean_efinix_flash clean_efinix
	 rm -rf impl obj_dir *.svg a.out *.vcd *.json *.bit build
	 find . -name "*.svg" -type f -delete
	 find . -name "*.json" -type f -delete
	 find . -name "*.bit" -type f -delete

# export PATH=$PATH:/home/carlos/Embedded/Gowin/IDE/bin
# Install netlistsvg for svg generation
# sudo minicom -D /dev/ttyACM0

