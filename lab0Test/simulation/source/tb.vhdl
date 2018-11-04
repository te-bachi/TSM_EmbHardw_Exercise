
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LCD_tb is

end LCD_tb;

architecture testbench of LCD_tb is

    signal test_sig                 : std_logic                     := '1';
    signal test_sig_delay1          : std_logic                     := '1';
    signal test_sig_delay2          : std_logic                     := '1';

    signal clk                      : std_logic                     := '0';
    signal reset_n                  : std_logic                     := '1';
    signal sim_end                  : boolean                       := false;

    constant CLK_PERIOD             : time                          := 20 ns;

begin
    test_sig_delay1 <= test_sig'delayed(5 ns);
    test_sig_delay2 <= test_sig_delay1'delayed(5 ns);

    -- RESET PROCESS -----------------------------------------------------------
    process
    begin
        wait for CLK_PERIOD;
        reset_n <= '0';

        wait for CLK_PERIOD*2;
        reset_n <= '1';

        -- Wait forever
        wait;
    end process;

    -- CLOCK PROCESS -----------------------------------------------------------
    process
    begin
        clk <= '0';
        test_sig <= '0';
        wait for CLK_PERIOD/2;

        clk <= '1';
        test_sig <= '1';
        wait for CLK_PERIOD/2;

        if sim_end then
            -- Wait forever
            wait;
        end if;
    end process;

    -- SIMULATION END PROCESS --------------------------------------------------
    process
    begin
        wait for CLK_PERIOD * 50;
        sim_end <= true;
        wait;
    end process;

end testbench;
