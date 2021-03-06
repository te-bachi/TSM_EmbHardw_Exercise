##################################
# A very simple modelsim do file #
##################################

# 1) Create a library for working in
vlib work

# 2) Compile the half adder
set VCOM_OPTIONS {-2008 -explicit -time -check_synthesis -rangecheck -source -work work}
eval vcom $VCOM_OPTIONS source/tb.vhdl

# 3) Load it for simulation
vsim -t 100ps -novopt work.LCD_tb

# 4) Open some selected windows for viewing
#view structure
#view signals
noview process
noview signals
noview sim
noview library
noview project
view wave

# 5) Show some of the signals in the wave window
# add wave clk
add wave -r *

# 6) Set some test patterns

# 7) Run the simulation for 40 ns
# run 1us
run -all
#run 500ns

wave zoom full
