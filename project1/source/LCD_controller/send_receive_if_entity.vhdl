library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SendReceiveInterface is
  port (  -- Here the internal interface is defined
    Clock                 : in  std_logic;
    Reset                 : in  std_logic;
    ResetDisplay          : in  std_logic;
    StartSendReceive      : in  std_logic;
    CommandBarData        : in  std_logic;
    EightBitSixteenBitBar : in  std_logic;
    WriteReadBar          : in  std_logic;
    DataToSend            : in  std_logic_vector(15 downto 0);
    DataReceived          : out std_logic_vector(15 downto 0);
    busy                  : out std_logic;

    -- Here the external LCD-panel signals are defined
    ChipSelectBar  : out   std_logic;
    DataCommandBar : out   std_logic;
    WriteBar       : out   std_logic;
    ReadBar        : out   std_logic;
    ResetBar       : out   std_logic;
    IM0            : out   std_logic;
    DataBus        : inout std_logic_vector(15 downto 0));
end SendReceiveInterface;
