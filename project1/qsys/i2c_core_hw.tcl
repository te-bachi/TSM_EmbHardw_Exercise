# TCL File Generated by Component Editor 13.0sp1
# Thu Dec 11 14:59:39 CET 2014
# DO NOT MODIFY


#
# i2c_core "i2c_core" v1.0
#  2014.12.11.14:59:39
#
#

#
# request TCL package from ACDS 13.1
#
package require -exact qsys 13.1


#
# module i2c_core
#
set_module_property DESCRIPTION ""
set_module_property NAME i2c_core
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME i2c_core
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL i2c_core
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file i2c_core.vhdl VHDL PATH ../source/Camera/i2c_core.vhdl TOP_LEVEL_FILE


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
add_interface_port avalon_slave_0 slave_byte_enables byteenable Input 4
add_interface_port avalon_slave_0 slave_read_data readdata Output 32
add_interface_port avalon_slave_0 slave_address address Input 2
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


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
# connection point conduit_end
#
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock_sink
set_interface_property conduit_end associatedReset reset
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end SDA export Bidir 1
add_interface_port conduit_end SCL export Output 1
add_interface_port conduit_end Motion_IRQ export Input 1


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