
LIBRARY ieee;
USE ieee.std_logic_1164.all;


-- clk               : in    std_logic;
-- avalon_address    : in    std_logic_vector(1 downto 0);
-- avalon_cs         : in    std_logic;
-- avalon_wr         : in    std_logic;
-- avalon_waitreq    : out   std_logic;
-- avalon_write_data : in    std_logic_vector(15 downto 0);
-- reset             : in    std_logic;
-- LCD_data          : inout std_logic_vector(15 downto 0);
-- LCD_WR_n          : out   std_logic;
-- LCD_RD_n          : out   std_logic;
-- LCD_D_C_n         : out   std_logic);

ENTITY lcd_ctrl_av_slave IS
    PORT (
        clk                     : IN    std_logic;
        rst_n                   : IN    std_logic;

        -- Avalon-MM slave interface definition
        avalon_address          : IN    std_logic_vector(1 DOWNTO 0);   -- address space = 4
        avalon_cs               : IN    std_logic;
        avalon_read             : IN    std_logic;
        avalon_read_data        : OUT   std_logic_vector(15 DOWNTO 0);
        avalon_write            : IN    std_logic;
        avalon_write_data       : IN    std_logic_vector(15 DOWNTO 0);
        avalon_wait_request     : OUT   std_logic;

        -- External interface to LCD panel definition
        LCD_IM0_out             : OUT   std_logic;
        LCD_RDX_n_out           : OUT   std_logic;
        LCD_CS_n_out            : OUT   std_logic;
        LCD_D_C_n_out           : OUT   std_logic;
        LCD_WR_n_out            : OUT   std_logic;
        LCD_RD_n_out            : OUT   std_logic;
        LCD_D_out               : INOUT std_logic_vector(15 DOWNTO 0)
    );
END lcd_ctrl_av_slave;

--------------------------------------------------------------------------------
-- Register model (slave_address):
--
-- 00  write: Write a command to LCD
--      read:  Read a command from LCD
--
-- 01  write: Write data to LCD
--      read: Read data from LCD
--
-- 10    r/w: Control register
--            bit 0  => Select 0 => Sixteen bit transfer
--                      Select 1 => Eight bit transfer
--            bit 1  => Busy flag (read only)
--                      Reset LCD Display (write only)
--            others => 0
--------------------------------------------------------------------------------

ARCHITECTURE rtl OF lcd_ctrl_av_slave IS

    subtype     address_t   is std_logic_vector (1 downto 0);
    constant    addr_command        : address_t := "00";
    constant    addr_data           : address_t := "01";
    constant    addr_control        : address_t := "10";

    constant    bit_IM0             : integer   := 0;
    constant    bit_RDX             : integer   := 1;

    SIGNAL s_WriteReadBar           : std_logic;
    SIGNAL s_StartSendReceive       : std_logic;
    SIGNAL s_CommandBarData         : std_logic;
    SIGNAL control_reg              : std_logic_vector(15 DOWNTO 0);
    SIGNAL control_next             : std_logic_vector(15 DOWNTO 0);
    SIGNAL s_LCD_data_out           : std_logic_vector(15 DOWNTO 0);
    signal s_data                   : std_logic_vector(15 DOWNTO 0);
BEGIN

--------------------------------------------------------------------------------
-- In this section the avalon slave signals are defined
--------------------------------------------------------------------------------

    avalon_read_data <= (others => '0');
    control_reg <= control_next;
    
    pRegWr : process(clk, rst_n)
    begin
        -- async RESET
        if rst_n = '0' then
            control_next <= (others => '0');

        -- rising clock
        elsif rising_edge(clk) then
            if avalon_write = '1' then
                case avalon_address is
                    when addr_command   => s_data <= avalon_write_data;
                    when addr_data      => s_data <= avalon_write_data;
                    when addr_control   => control_next <= avalon_write_data;
                    when others         => null;
                end case;
            end if;
        end if;
    end process;


--------------------------------------------------------------------------------
-- In this section the LCD-read state machine is defined
--------------------------------------------------------------------------------

  -- TODO...


--------------------------------------------------------------------------------
--- In this section the control register is defined
--------------------------------------------------------------------------------

  -- TODO...


--------------------------------------------------------------------------------
--- In this section all control signals are defined
--------------------------------------------------------------------------------

  -- TODO...


--------------------------------------------------------------------------------
--- In this section all components are connected
--------------------------------------------------------------------------------

    s_StartSendReceive <= '0';
    s_CommandBarData <= '0';
    s_WriteReadBar <= '0';
    s_LCD_data_out <= (others => '0');

    ili9341 : entity work.lcd_ctrl_ili9341
        PORT MAP (
            clk                     => clk,
            rst_n                   => rst_n,
            LCD_RDX_n               => control_reg(bit_RDX),
            StartSendReceive        => s_StartSendReceive,
            CommandBarData          => s_CommandBarData,
            LCD_IM0                 => control_reg(bit_IM0),
            WriteReadBar            => s_WriteReadBar,
            DataToSend              => avalon_write_data(15 DOWNTO 0),
            DataReceived            => s_LCD_data_out,
            busy                    => avalon_wait_request,

            -- Here the external LCD-panel signals are defined
            LCD_IM0_out             => LCD_IM0_out,
            LCD_RDX_n_out           => LCD_RDX_n_out,
            LCD_CS_n_out            => LCD_CS_n_out,
            LCD_D_C_n_out           => LCD_D_C_n_out,
            LCD_WR_n_out            => LCD_WR_n_out,
            LCD_RD_n_out            => LCD_RD_n_out,
            LCD_D_out               => LCD_D_out
        );

END ARCHITECTURE rtl;
