# TCL File Generated by Component Editor 17.0
# Tue Oct 09 08:56:04 CEST 2018
# DO NOT MODIFY


#
# LCD_controller "LCD_Controller" v1.0
#  2018.10.09.08:56:04
#
#

#
# request TCL package from ACDS 16.1
#
package require -exact qsys 16.1


#
# module LCD_controller
#
set_module_property DESCRIPTION ""
set_module_property NAME LCD_controller
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME LCD_Controller
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL lcd_avalon_slave
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file lcd_avalon_slave_entity.vhdl VHDL PATH ../source/LCD_controller/lcd_avalon_slave_entity.vhdl TOP_LEVEL_FILE
add_fileset_file lcd_avalon_slave_behavior.vhdl VHDL PATH ../source/LCD_controller/lcd_avalon_slave_behavior.vhdl
add_fileset_file LCD_controller.vhdl VHDL PATH ../source/LCD_controller/LCD_controller.vhdl


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
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset Reset reset Input 1


#
# connection point avalon_slave_0
#
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 slave_cs chipselect Input 1
add_interface_port avalon_slave_0 slave_we write Input 1
add_interface_port avalon_slave_0 slave_rd read Input 1
add_interface_port avalon_slave_0 slave_write_data writedata Input 32
add_interface_port avalon_slave_0 slave_read_data readdata Output 32
add_interface_port avalon_slave_0 slave_wait_request waitrequest Output 1
add_interface_port avalon_slave_0 slave_address address Input 2
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


#
# connection point clock
#
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock Clock clk Input 1


#
# connection point conduit_end
#
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end ChipSelectBar chipselectbar Output 1
add_interface_port conduit_end DataBus databus Bidir 16
add_interface_port conduit_end DataCommandBar datacommandbar Output 1
add_interface_port conduit_end IM0 im0 Output 1
add_interface_port conduit_end ReadBar readbar Output 1
add_interface_port conduit_end ResetBar resetbar Output 1
add_interface_port conduit_end WriteBar writebar Output 1
