TARGET=SOC_flash
TOP=SOC_flash_syn

OBJS = SOC_flash.v
OBJS+= cores/cpu/femtorv32_quark.v
OBJS+= cores/uart/perip_uart.v
OBJS+= cores/uart/uart.v
OBJS+= cores/mult/perip_mult.v
OBJS+= cores/mult/mult.v
OBJS+= cores/spi_flash/MappedSPIFlash_V3.v
OBJS+= cores/spi_ram/MappedSPIRAM.v
SIM_OBJS = cores/sim_spi_flash/spiflash.v
SIM_OBJS += lib/verilog_model/sky130_fd_sc_hd.v
SIM_OBJS += lib/verilog_model/primitives.v



BUILD_DIR = build

all: $(TARGET).fs

$(TARGET).fs: 
	gw_sh  soc_flash_src.tcl

${TARGET}.svf : ${TARGET}.bit

clean:
	rm -rf impl obj_dir *svg a.out *.vcd *.json *.bit build *.vpp *.log SOC_flash_synth_sky
sim: 
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 bench_quark_flash.v ${OBJS} ${SIM_OBJS}
	vvp a.out
	gtkwave bench.vcd

sim_post_synth:
	rm -f a.out *.vcd
	yosys -v3 -l synth.log -s synth_femtorv
	iverilog  -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27 -DNRV_IS_IO_ADDR -s bench bench_quark_flash.v SOC_flash_synth_sky.v $(SIM_OBJS)
	vvp a.out
	gtkwave bench.vcd post.gtkw &

## ---------------------
## post-synth simulation
## ---------------------
$(TOP).json:
	yosys -v3 -l synth.log -p 'setattr -set keep 1 ; synth -flatten; synth_ecp5 -top SOC_flash -json $(TOP).json; write_verilog -attr2comment $(TOP)_synth.v' ${OBJS}
#	yosys -v3 -l synth.log -p 'synth_ecp5 -top SOC_flash -json $(TOP).json; write_verilog -attr2comment $(TOP)_synth.v' ${OBJS}


 	
svg: $(OBJS)
	yosys -p "prep -top ${TARGET}; write_json ${TARGET}.json" -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27  ${OBJS}
	netlistsvg ${TARGET}.json -o ${TARGET}.svg  #--skin default.svg
	yosys -p "prep -top ${TARGET} -flatten; write_json ${TARGET}_flat.json" ${OBJS}
	netlistsvg ${TARGET}_flat.json -o ${TARGET}_flat.svg  #--skin default.svg

configure: ${TARGET}.fs
	sudo openFPGALoader -b tangprimer20k -m impl/pnr/project.fs

# export PATH=$PATH:/home/carlos/Embedded/Gowin/IDE/bin
#Install netlistsvg for svg generation
