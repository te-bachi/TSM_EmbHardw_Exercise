


vsim work.ctrl_lcd_avalonslave
add wave Clock
add wave interface.Clock


vsim -c -do "onElabError resume; run -all; exit" -f modelsim.tops
vsim -do run.do -c -suppress 3829 test

view structure
vsim -t 1ps -voptargs=+acc -L work counter_tb
do counter_wave.do
run -all


restart
view signals
view wave
add wave EXOR_TB/*
run 200 ns


1) vlib work 
2) vmap work work 
3) vlog FA.v.  
4) vsim -c -do FA_run_msim_rtl_verilog.do FA -wlf waveform.wlf 

Modelsim> vlib rtl_work 
Modelsim> vmap work rtl_work 
Modelsim> vlog FA.v 
Modelsim> vsim FA 
Modelsim> add wave * 
Modelsim> run 10 us 

restart
force clk 1 0, 0 10ns -repeat
force reset 1 0, 0 100ns
force avalon_address XX 0, 00
XX 425ns
force avalon_write_data 16#XX
16#CC 405ns, 16#XX 425ns
force avalon_wr 0 0, 1 205ns,
force avalon_cs 0 0, 1 208ns,
run 600ns

