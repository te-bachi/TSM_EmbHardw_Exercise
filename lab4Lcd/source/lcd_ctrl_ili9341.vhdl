
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY lcd_ctrl_ili9341 IS
    PORT (
        -- Internal interface definition
        clk                     : IN    std_logic;
        rst_n                   : IN    std_logic;
        LCD_RDX_n               : IN    std_logic;
        StartSendReceive        : IN    std_logic;
        CommandBarData          : IN    std_logic;
        LCD_IM0                 : IN    std_logic;
        WriteReadBar            : IN    std_logic;
        DataToSend              : IN    std_logic_vector(15 DOWNTO 0);
        DataReceived            : OUT   std_logic_vector(15 DOWNTO 0);
        busy                    : OUT   std_logic;

        -- External interface to LCD panel definition
        LCD_IM0_out             : OUT   std_logic;
        LCD_RDX_n_out           : OUT   std_logic;
        LCD_CS_n_out            : OUT   std_logic;
        LCD_D_C_n_out           : OUT   std_logic;
        LCD_WR_n_out            : OUT   std_logic;
        LCD_RD_n_out            : OUT   std_logic;
        LCD_D_out               : INOUT std_logic_vector(15 DOWNTO 0)
    );
END lcd_ctrl_ili9341;

ARCHITECTURE rtl OF lcd_ctrl_ili9341 IS

    TYPE CONTROL_STATE_TYPE IS (
        IDLE,
        CLOCKDATAOUT,
        WRITELOW1,
        WRITELOW2,
        INITREAD,
        WAITREADLOW,
        READCLOCK,
        READHI1,
        READHI2,
        READHI3,
        READHI4
    );

    TYPE RESET_STATE_TYPE IS (
        NOOP,
        ACTIVATERESET,
        WAITRESET,
        ACTIVATERECOVER,
        WAITRECOVER
    );

    SIGNAL s_current_state          : CONTROL_STATE_TYPE;
    SIGNAL s_next_state             : CONTROL_STATE_TYPE;

    SIGNAL s_IM0_current            : std_logic;
    SIGNAL s_IM0_next               : std_logic;

    SIGNAL s_data_out_reg           : std_logic_vector(15 DOWNTO 0);
    SIGNAL s_data_out_next          : std_logic_vector(15 DOWNTO 0);

    SIGNAL s_read_del_reg           : unsigned(4 DOWNTO 0);
    SIGNAL s_read_del_next          : unsigned(4 DOWNTO 0);

    SIGNAL s_read_del_zero          : std_logic;
    SIGNAL s_received_data_next     : std_logic_vector(15 DOWNTO 0);

    SIGNAL s_tri_bus_reg            : std_logic;
    SIGNAL s_tri_bus_next           : std_logic;

    SIGNAL s_current_reset          : RESET_STATE_TYPE;
    SIGNAL s_next_reset             : RESET_STATE_TYPE;

    SIGNAL s_reset_counter_reg      : unsigned(23 DOWNTO 0);
    SIGNAL s_reset_counter_next     : unsigned(23 DOWNTO 0);
    SIGNAL s_reset_counter_zero     : std_logic;
    SIGNAL s_chip_select_bar_next   : std_logic;
    SIGNAL s_reset_bar_next         : std_logic;

BEGIN

    REG: process(clk, rst_n)
    begin
        if rst_n = '0' then
            -- Initialize outputs and internal signals
            DataReceived            <= (others => '0');
            busy                    <= '0';

            LCD_IM0_out             <= '0';
            LCD_RDX_n_out           <= '1';
            LCD_CS_n_out            <= '1';
            LCD_D_C_n_out           <= '1';
            LCD_WR_n_out            <= '1';
            LCD_RD_n_out            <= '1';
            LCD_D_out               <= (others => '0');

        elsif rising_edge(clk) then

        end if;
    end process;

    NSL: process(s_current_state)
    begin
        s_next_state <= s_current_state;
    end process;

END rtl;
