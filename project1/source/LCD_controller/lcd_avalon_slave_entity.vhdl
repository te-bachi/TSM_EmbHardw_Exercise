library ieee;
use ieee.std_logic_1164.all;

entity lcd_avalon_slave is
  port (  -- Here the internal interface is defined
    Clock : in std_logic;
    Reset : in std_logic;

    -- Here the avalon slave interface is defined
    slave_address      : in  std_logic_vector(1 downto 0);
    slave_cs           : in  std_logic;
    slave_we           : in  std_logic;
    slave_rd           : in  std_logic;
    slave_write_data   : in  std_logic_vector(31 downto 0);
    slave_read_data    : out std_logic_vector(31 downto 0);
    slave_wait_request : out std_logic;


    -- Here the external LCD-panel signals are defined
    ChipSelectBar  : out   std_logic;
    DataCommandBar : out   std_logic;
    WriteBar       : out   std_logic;
    ReadBar        : out   std_logic;
    ResetBar       : out   std_logic;
    IM0            : out   std_logic;
    DataBus        : inout std_logic_vector(15 downto 0));
end lcd_avalon_slave;

-------- register model -----------
-- 00  write: Write a command to LCD
--     read :  Read a command from LCD
-- 01  write: Write data to LCD
--     read : Read data from LCD
-- 10  r/w  : Control register
--            bit 0  => Select 0 => Sixteen bit transfer
--                      Select 1 => Eight bit transfer
--            bit 1  => Busy flag (read only)
--                      Reset LCD Display (write only)
--            others => 0
