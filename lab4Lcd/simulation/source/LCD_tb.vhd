
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LCD_tb is

end LCD_tb;

architecture testbench of LCD_tb is

    signal test_sig                 : std_logic                     := '0';

    signal clk_sti                  : std_logic                     := '0';
    signal reset_sti                : std_logic                     := '1';
    signal avalon_address_sti       : std_logic_vector(1 downto 0)  := (others => '0');
    signal avalon_cs_sti            : std_logic                     := '0';
    signal avalon_rd_sti            : std_logic                     := '0';
    signal avalon_wr_sti            : std_logic                     := '0';
    signal avalon_write_data_sti    : std_logic_vector(15 downto 0) := (others => '0');
    signal avalon_read_data_sti     : std_logic_vector(15 downto 0) := (others => '0');
    signal avalon_waitreq_obs       : std_logic;

    signal LCD_data                 : std_logic_vector(15 downto 0) := (others => 'Z');
    signal LCD_WR_n_obs             : std_logic;
    signal LCD_RD_n_obs             : std_logic;
    signal LCD_D_C_n_obs            : std_logic;
    signal LCD_CS_n                 : std_logic;
    signal LCD_Reset_n              : std_logic;
    signal LCD_IM0                  : std_logic;

    constant CLK_PERIOD             : time                          := 20 ns;
    constant TWDS80                 : time                          := 5 ns;
    constant TWLW80                 : time                          := 22.5 ns;
    constant TCYCW80                : time                          := 65 ns;
    constant TIME_OUT_WAITREQ       : integer                       := 100;

    signal LCD_WR_n_old             : std_logic;

    signal sim_end_s                : boolean                       := false;

begin

    LCD_WR_n_old <= LCD_WR_n_obs'delayed;

    test_proc : process

        --temp que WR a passer a 0 initialiser avec TCYCW80 car aux premier
        -- flanc decandant de WR le temp de periode min n'a pas besoin dètre
        -- verifier (l'assert passera)
        variable temps_down_LCD_WR_n    : time := TCYCW80;

        --convertie un std_logic_vector en string represantant la valeur binaire sous la forme "00101100011010"
        function image_std_logic_vector(vector : in std_logic_vector) return string is
            variable image_vector : string(1 to vector'LENGTH);
        begin
            for num_bit in vector'RANGE loop
                --normalement devrait fonctionner avec tous les std_logic_vector meme si vector'low n'est pas 0
                image_vector(image_vector'HIGH-(num_bit-vector'LOW)) := std_logic'image(vector(num_bit))(2);
            end loop;
            return image_vector;
        end;

        procedure test is

          variable data_fifo              : std_logic_vector(16 downto 0);  --fifo ou est stocker les data envoyer et le et LCD_D_C_n_obs (LCD_D_C_n_obs est le bit 0)
          variable ok                     : boolean;
          variable temps_up_LCD_WR_n      : time := 0 ns;
          variable temps_periode_LCD_WR_n : time := 0 ns;

        begin

            wait until falling_edge(LCD_WR_n_obs) or (sim_end_s);  --flanc montant ou fin simulation
            if falling_edge(LCD_WR_n_obs) then                     --flanc montant

                temps_up_LCD_WR_n := LCD_WR_n_old'LAST_EVENT;  --temps que le WR a passer a 1

                temps_periode_LCD_WR_n := temps_down_LCD_WR_n+temps_up_LCD_WR_n;

                assert (temps_periode_LCD_WR_n >= TCYCW80) report "LCD_WR_n_obs has had a period of "&
                    time'image(temps_periode_LCD_WR_n) &
                    ", the minimal period is " &
                    time'image(TCYCW80) severity ERROR;

                assert (LCD_WR_n_old'STABLE(TWLW80)) report "LCD_WR_n_obs is staying "&
                    time'image(LCD_WR_n_old'LAST_EVENT) &
                    " in high state, the minimum number is " &
                    time'image(TWLW80) severity ERROR;

                --assert (LCD_data'DELAYED(TWDS80*1.5)=(LCD_data'range=>'Z')) report "la valeur de LCD_data n'estpas  passé par z "&
                assert (LCD_data'DELAYED(TWDS80*1.5) = (LCD_data)) report "Propagation time not respected "&
                    time'image(TWDS80);

                assert (LCD_data'STABLE(TWDS80)) report "LCD_data has changed "&
                    time'image(LCD_data'LAST_EVENT) &
                    " befor the falling edge of LCD_WR_n_obs, the minimal time is " &
                    time'image(TWDS80) severity ERROR;

                assert (LCD_D_C_n_obs'STABLE(TWDS80)) report "LCD_D_C_n_obs has changed "&
                    time'image(LCD_D_C_n_obs'LAST_EVENT) &
                    " befor the falling edge of LCD_WR_n_obs, the minimal time is " &
                    time'image(2*TWDS80) severity ERROR;

                wait until rising_edge(LCD_WR_n_obs) or (sim_end_s);  --flanc decandant ou fin simulation
                if rising_edge(LCD_WR_n_obs) then                     --flanc decandant

                    temps_down_LCD_WR_n := LCD_WR_n_old'LAST_EVENT;

                    assert (LCD_WR_n_old'STABLE(TWLW80)) report "LCD_WR_n_obs is stucked"&
                        time'image(LCD_WR_n_old'LAST_EVENT) &
                        " to ground, the minimal time is " &
                        time'image(TWLW80) severity ERROR;

                    wait for TWDS80;

                    assert (LCD_D_C_n_obs'LAST_EVENT > TWDS80+temps_down_LCD_WR_n) report "The value of LCD_D_C_n_obs has changed between the falling en rising edges of LCD_WR_n_old at least "&
                        time'image(TWDS80) & " after resing edge" severity ERROR;

                    assert (LCD_data'LAST_EVENT > TWDS80+temps_down_LCD_WR_n) report "The value of LCD_data has changed between the falling en rising edges of LCD_WR_n_old at least"&
                        time'image(TWDS80) & " after resing edge" severity ERROR;

                end if;
            end if;
        end;

        variable ref_LCD_data_s         : std_logic_vector(15 downto 0);
        variable ref_avalon_waitreq_s   : std_logic;
        variable ref_LCD_WR_n_s         : std_logic;
        variable ref_LCD_RD_n_s         : std_logic;
        variable ref_LCD_D_C_n_s        : std_logic;

    -- BEGIN PROCESS
    begin
        while(not sim_end_s) loop
            test;
        end loop;
        wait;
    end process;

    -- AVALON INPUT PROCESS ----------------------------------------------------
    process
        -- CYCLE(i): WAIT i-TIME UNTIL RISING EDGE -----------------------------
        procedure cycle(nb_cycles : integer := 1) is
        begin
          for i in 1 to nb_cycles loop
            wait until rising_edge(clk_sti);
          end loop;
        end cycle;

        -- AVALON_WAIT_REQUEST PROCEDURE ---------------------------------------
        procedure wait_waitreq is
            variable timout : integer;
        begin
            assert (avalon_waitreq_obs'DELAYED = '1') report "Please verify your wait_request signal. It is not sure it is working correctly in here."
            severity WARNING;
            timout := 0;
            loop
                timout := timout+1;
                EXIT WHEN avalon_waitreq_obs = '0';
                if timout > TIME_OUT_WAITREQ then
                    report "avalon_waitreq_obs got stuck for more than "&
                    integer'image(TIME_OUT_WAITREQ) &" I'm quiting simulation";
                    sim_end_s <= true;
                    wait;
                end if;
                cycle(1);
            end loop;
        end wait_waitreq;

        -- GENERATE AVALON-BUS STIMULI -----------------------------------------
        procedure avalon_stimuli (
            avalon_address_s    : std_logic_vector(1 downto 0);
            avalon_cs_s         : std_logic;
            avalon_rd_s         : std_logic;
            avalon_wr_s         : std_logic;
            avalon_write_data_s : std_logic_vector(15 downto 0)
        ) is
        begin
            avalon_address_sti    <= avalon_address_s;
            avalon_cs_sti         <= avalon_cs_s;
            avalon_rd_sti         <= '0';
            avalon_wr_sti         <= avalon_wr_s;
            avalon_write_data_sti <= avalon_write_data_s;
            avalon_read_data_sti  <= (others => '0');
        end;

        variable seed1, seed2   : positive;
        variable rand           : real;
        variable int_rand       : integer;
        variable rand_address_s : std_logic_vector (avalon_address_sti'range);
        variable rand_data_s    : std_logic_vector (avalon_write_data_sti'range);
        variable rand_bit_s     : std_logic_vector (2 downto 0);
    begin

        --             addr  cs   rd   wr   write_data
        avalon_stimuli("00", '0', '0', '0', x"FFAA");
        cycle(5);

        --envoit rapidement des donner pour utiliser le fifo
        for i in 1 to 20 loop
            avalon_stimuli("00", '1', '0', '1', std_logic_vector(to_unsigned(i, avalon_write_data_sti'length)));
            cycle(1);
            wait_waitreq;
            avalon_stimuli("00", '0', '0', '0', x"FFAA");
            cycle(1);
        end loop;

        for i in 1 to 20 loop
            --genere des nombres aleatoire
            uniform(seed1, seed2, rand);
            int_rand       := INTEGER(TRUNC(rand*(2.0**rand_address_s'length)));
            rand_address_s := std_logic_vector(to_unsigned(int_rand, rand_address_s'length));

            uniform(seed1, seed2, rand);
            int_rand    := INTEGER(TRUNC(rand*(2.0**rand_data_s'length)));
            rand_data_s := std_logic_vector(to_unsigned(int_rand, rand_data_s'length));

            --genere un nombre pour tous les bit
            uniform(seed1, seed2, rand);
            int_rand   := INTEGER(TRUNC(rand*(2.0**rand_bit_s'length)));
            rand_bit_s := std_logic_vector(to_unsigned(int_rand, rand_bit_s'length));

            avalon_stimuli(rand_address_s, rand_bit_s(2), rand_bit_s(1), rand_bit_s(0), rand_data_s);

            cycle(1);

            --si on fait une lecture ou ecriture
            if avalon_cs_sti = '1' and (avalon_wr_sti = '1' or avalon_rd_sti = '1') then
                wait_waitreq;
            end if;

            avalon_stimuli("00", '0', '0', '0', x"FFAA");

            uniform(seed1, seed2, rand);
            int_rand := INTEGER(TRUNC(rand*(20.0)));

            cycle(int_rand);  --attend entre 0 et 20 clk avant le prochaine envoit sur le bus avalon
        end loop;

        cycle(100);                         --attend que tous les data soit envoyer
        sim_end_s <= true;                  --fin de simulation
        wait;
    end process;

    -- RESET PROCESS -----------------------------------------------------------
    process
    begin
        wait for CLK_PERIOD;
        reset_sti <= '0';

        wait for CLK_PERIOD*2;
        reset_sti <= '1';

        -- Wait forever
        wait;
    end process;

    -- CLOCK PROCESS -----------------------------------------------------------
    process
    begin
        clk_sti <= '0';
        wait for CLK_PERIOD/2;

        clk_sti <= '1';
        wait for CLK_PERIOD/2;

        if (sim_end_s) then
            -- Wait forever
            wait;
        end if;
    end process;

    -- DUT Instantiation -------------------------------------------------------
    dut : entity work.lcd_ctrl_av_slave
        port map(
            clk                 => clk_sti,
            rst_n               => reset_sti,

            -- Avalon-MM slave interface definition
            avalon_address      => avalon_address_sti,
            avalon_cs           => avalon_cs_sti,
            avalon_read         => avalon_rd_sti,
            avalon_read_data    => avalon_read_data_sti,
            avalon_write        => avalon_wr_sti,
            avalon_write_data   => avalon_write_data_sti,
            avalon_wait_request => avalon_waitreq_obs,

            -- External interface to LCD panel definition
            LCD_IM0_out         => LCD_IM0,
            LCD_RDX_n_out       => LCD_Reset_n,
            LCD_CS_n_out        => LCD_CS_n,
            LCD_D_C_n_out       => LCD_D_C_n_obs,
            LCD_WR_n_out        => LCD_WR_n_obs,
            LCD_RD_n_out        => LCD_RD_n_obs,
            LCD_D_out           => LCD_data
        );

end testbench;
