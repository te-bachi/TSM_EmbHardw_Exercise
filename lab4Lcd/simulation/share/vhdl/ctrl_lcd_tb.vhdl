
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ctrl_lcd_tb IS

END;

ARCHITECTURE rtl OF ctrl_lcd_tb IS

    CONSTANT    period                  : time := 20 ns;

    SIGNAL      clk                     : std_logic;


BEGIN

    clk_gen : process
    begin
        clk <= '0';
        WAIT FOR period/2;
        clk <= '1';
        WAIT FOR period/2;
    end process;



    --dut : entity work.
    --    PORT MAP (
    --    );

END ARCHITECTURE rtl;
