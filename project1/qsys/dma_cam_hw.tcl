# TCL File Generated by Component Editor 13.0sp1
# Mon Dec 08 09:47:14 CET 2014
# DO NOT MODIFY


#
# dma_cam "dma_cam" v1.0
#  2014.12.08.09:47:14
#
#

#
# request TCL package from ACDS 13.1
#
package require -exact qsys 13.1


#
# module dma_cam
#
set_module_property DESCRIPTION ""
set_module_property NAME dma_cam
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME dma_cam
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL camera_if
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file DMA_camera.vhdl VHDL PATH ../source/Camera/DMA_camera.vhdl TOP_LEVEL_FILE


#
# parameters
#


#
# display items
#


#
# connection point reset
#
add_interface reset reset end
set_interface_property reset associatedClock clock_sink
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


#
# connection point avalon_slave_0
#
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock_sink
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 slave_cs chipselect Input 1
add_interface_port avalon_slave_0 slave_we write Input 1
add_interface_port avalon_slave_0 slave_write_data writedata Input 32
add_interface_port avalon_slave_0 slave_read_data readdata Output 32
add_interface_port avalon_slave_0 slave_address address Input 3
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


#
# connection point conduit_end
#
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock_sink
set_interface_property conduit_end associatedReset reset
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end cam_reset export Output 1
add_interface_port conduit_end cam_pwdn export Output 1
add_interface_port conduit_end cam_vsync export Input 1
add_interface_port conduit_end cam_href export Input 1
add_interface_port conduit_end cam_data export Input 10
add_interface_port conduit_end cam_PX_clock export Input 1


#
# connection point clock_sink
#
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink clock clk Input 1


#
# connection point avalon_master
#
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock_sink
set_interface_property avalon_master associatedReset reset
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master master_address address Output 32
add_interface_port avalon_master master_cs chipselect Output 1
add_interface_port avalon_master master_we write Output 1
add_interface_port avalon_master master_write_data writedata Output 32
add_interface_port avalon_master master_wait_req waitrequest Input 1


#
# connection point interrupt_sender
#
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint avalon_slave_0
set_interface_property interrupt_sender associatedClock clock_sink
set_interface_property interrupt_sender associatedReset reset
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq irq Output 1
