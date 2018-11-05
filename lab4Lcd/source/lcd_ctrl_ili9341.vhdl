
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

    TYPE state_t IS (
        STATE_IDLE,
        STATE_WAITBUSY,
        STATE_INITREAD,
        STATE_WAITREAD,
        STATE_RELEASE
    );

    SIGNAL state_reg            : state_t;
    SIGNAL state_next           : state_t;

BEGIN

    -- Initialize outputs and internal signals
    DataReceived            <= (others => '0');
    --busy                    <= '0';

    LCD_IM0_out             <= '0';
    LCD_RDX_n_out           <= '1';
    LCD_CS_n_out            <= '1';
    LCD_D_C_n_out           <= '1';
    LCD_WR_n_out            <= '1';
    LCD_RD_n_out            <= '1';
    LCD_D_out               <= (others => '0');

    -- State Register Process --------------------------------------------------
    REG: process(clk, rst_n)
    begin
        if rst_n = '0' then

            state_reg               <= STATE_IDLE;

        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    -- Next-State Logic Process ------------------------------------------------
    NSL: process(state_reg)
    begin
        state_next <= state_reg;

        case state_reg is
            when STATE_IDLE     => state_next <= STATE_WAITBUSY;
            when STATE_WAITBUSY => state_next <= STATE_INITREAD;
            when STATE_INITREAD => state_next <= STATE_WAITREAD;
            when STATE_WAITREAD => state_next <= STATE_RELEASE;
            when STATE_RELEASE  => state_next <= STATE_IDLE;
            when others         => null;
        end case;
    end process;

    busy <= '1' when state_reg /= STATE_IDLE else '0';

END rtl;
