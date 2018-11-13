architecture MSE of SendReceiveInterface is

  type CONTROLSTATETYPE is (IDLE, CLOCKDATAOUT, WRITELOW1, WRITELOW2,
                            INITREAD, WAITREADLOW, READCLOCK, READHI1, READHI2,
                            READHI3, READHI4);
  type RESETSTATETYPE is (NOOP, ACTIVATERESET, WAITRESET,
                          ACTIVATERECOVER, WAITRECOVER);

  signal s_current_state, s_next_state   : CONTROLSTATETYPE;
  signal s_IM0_current, s_IM0_next       : std_logic;
  signal s_data_out_reg, s_data_out_next : std_logic_vector(15 downto 0);
  signal s_read_del_reg, s_read_del_next : unsigned(4 downto 0);
  signal s_read_del_zero                 : std_logic;
  signal s_received_data_next            : std_logic_vector(15 downto 0);
  signal s_tri_bus_reg, s_tri_bus_next   : std_logic;
  signal s_current_reset, s_next_reset   : RESETSTATETYPE;
  signal s_reset_counter_reg             : unsigned(23 downto 0);
  signal s_reset_counter_next            : unsigned(23 downto 0);
  signal s_reset_counter_zero            : std_logic;
  signal s_chip_select_bar_next          : std_logic;
  signal s_reset_bar_next                : std_logic;

begin

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section all the external LCD-panel signals are assigned          ---
---                                                                          ---
--------------------------------------------------------------------------------

  ---*** ChipSelectBar ***---
  s_chip_select_bar_next <= '1' when Reset = '1' or
                            s_current_reset /= NOOP else '0';
  make_chip_select : process(Clock)
  begin
    if (rising_edge(Clock)) then
      ChipSelectBar <= s_chip_select_bar_next;
    end if;
  end process make_chip_select;

  ---*** DataCommandBar ***---
  make_data_command_bar : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then
        DataCommandBar <= '0';
      elsif (StartSendReceive = '1') then
        DataCommandBar <= CommandBarData;
      end if;
    end if;
  end process make_data_command_bar;

  ---*** WriteBar ***---
  make_write_bar : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (s_current_state = WRITELOW1 or
          s_current_state = WRITELOW2) then
        WriteBar <= '0';
      else
        WriteBar <= '1';
      end if;
    end if;
  end process make_write_bar;

  ---*** ReadBar ***---
  make_read_bar : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (s_current_state = WAITREADLOW) then
        ReadBar <= '0';
      else
        ReadBar <= '1';
      end if;
    end if;
  end process make_read_bar;

  ---*** ResetBar ***---
  s_reset_bar_next <= '0' when s_current_reset = WAITRESET else '1';
  make_reset_bar : process(Clock)
  begin
    if (rising_edge(Clock)) then
      ResetBar <= s_reset_bar_next;
    end if;
  end process make_reset_bar;

  ---*** IM0 ***---
  IM0        <= s_IM0_current;
  s_IM0_next <= EightBitSixteenBitBar
                when StartSendReceive = '1' else
                s_IM0_current;

  make_IM0_current : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then s_IM0_current <= '0';
      else s_IM0_current                  <= s_IM0_next;
      end if;
    end if;
  end process make_IM0_current;

  ---*** DataBus ***---
  s_data_out_next <= s_data_out_reg when StartSendReceive = '0' or
                     WriteReadBar = '0' else
                     DataToSend(7 downto 0)&X"00" when EightBitSixteenBitBar = '1' else
                     DataToSend;

  make_data_out_reg : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then s_data_out_reg <= (others => '0');
      else s_data_out_reg                  <= s_data_out_next;
      end if;
    end if;
  end process make_data_out_reg;

  s_tri_bus_next <= '1' when s_current_state = INITREAD or
                             s_current_state = WAITREADLOW or
                             s_current_state = READHI1 or
                             s_current_state = READHI2 or
                             s_current_state = READHI3 or
                             s_current_state = READHI4 else
                    '0';

  make_tri_bus_reg : process(Clock)
  begin
    if (rising_edge(Clock)) then
      s_tri_bus_reg <= s_tri_bus_next;
    end if;
  end process make_tri_bus_reg;

  DataBus <= s_data_out_reg when s_tri_bus_reg = '0' else (others => 'Z');

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section The reset state machine is defined                       ---
---                                                                          ---
--------------------------------------------------------------------------------
  s_reset_counter_next <= to_unsigned(1199, 24) when s_current_reset = ACTIVATERESET else
                          to_unsigned(11999999, 24) when s_current_reset = ACTIVATERECOVER else
                          s_reset_counter_reg-1 when s_reset_counter_zero = '0' else
                          s_reset_counter_reg;
  s_reset_counter_zero <= '1' when s_reset_counter_reg = to_unsigned(0, 24) else
                          '0';

  make_reset_counter : process(Clock)
  begin
    if (rising_edge(Clock)) then
      s_reset_counter_reg <= s_reset_counter_next;
    end if;
  end process make_reset_counter;

  make_reset_state_next : process(s_current_reset, s_reset_counter_zero,
                                  ResetDisplay)
  begin
    case(s_current_reset) is
      when NOOP =>
        if (ResetDisplay = '1') then
          s_next_reset <= ACTIVATERESET;
        else
          s_next_reset <= NOOP;
        end if;
      when ACTIVATERESET =>
        if (s_current_state /= IDLE) then
          s_next_reset <= ACTIVATERESET;
        else
          s_next_reset <= WAITRESET;
        end if;
      when WAITRESET =>
        if (s_reset_counter_zero = '1') then
          s_next_reset <= ACTIVATERECOVER;
        else
          s_next_reset <= WAITRESET;
        end if;
      when ACTIVATERECOVER => s_next_reset <= WAITRECOVER;
      when WAITRECOVER =>
        if (s_reset_counter_zero = '1') then
          s_next_reset <= NOOP;
        else
          s_next_reset <= WAITRECOVER;
        end if;
      when others => s_next_reset <= NOOP;
    end case;
  end process make_reset_state_next;

  make_reset_state : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then s_current_reset <= ACTIVATERESET;
      else s_current_reset                  <= s_next_reset;
      end if;
    end if;
  end process make_reset_state;

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section The controlling state machine is defined                 ---
---                                                                          ---
--------------------------------------------------------------------------------
  busy <= '0' when s_current_state = IDLE and
          s_current_reset = NOOP else '1';

  update_logic : process(s_current_state, StartSendReceive,
                         WriteReadBar, s_read_del_zero)
  begin
    case (s_current_state) is
      when IDLE =>
        if (StartSendReceive = '1' and
            s_current_reset = NOOP) then
          if (WriteReadBar = '1') then
            s_next_state <= CLOCKDATAOUT;
          else
            s_next_state <= INITREAD;
          end if;
        else
          s_next_state <= IDLE;
        end if;
      when CLOCKDATAOUT => s_next_state <= WRITELOW1;
      when WRITELOW1    => s_next_state <= WRITELOW2;
      when INITREAD     => s_next_state <= WAITREADLOW;
      when WAITREADLOW =>
        if (s_read_del_zero = '1') then
          s_next_state <= READHI1;
        else
          s_next_state <= WAITREADLOW;
        end if;
      when READHI1 => s_next_state <= READHI2;
      when READHI2 => s_next_state <= READHI3;
      when READHI3 => s_next_state <= READHI4;
      when others  => s_next_state <= IDLE;
    end case;
  end process update_logic;

  state_mem : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then s_current_state <= IDLE;
      else s_current_state                  <= s_next_state;
      end if;
    end if;
  end process state_mem;

  s_read_del_zero <= '1' when s_read_del_reg = to_unsigned(0, 5) else
                     '0';
  s_read_del_next <= to_unsigned(17, 5) when s_current_state = INITREAD else
                     s_read_del_reg-1 when s_read_del_zero = '0' else
                     s_read_del_reg;

  make_read_del_reg : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then
        s_read_del_reg <= (others => '0');
      else
        s_read_del_reg <= s_read_del_next;
      end if;
    end if;
  end process make_read_del_reg;

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section the output register is defined                           ---
---                                                                          ---
--------------------------------------------------------------------------------
  s_received_data_next <= X"00"&DataBus(15 downto 8)
                          when EightBitSixteenBitBar = '1' else
                          DataBus;
  make_data_received : process(Clock)
  begin
    if (rising_edge(Clock)) then
      if (Reset = '1') then
        DataReceived <= (others => '0');
      elsif (s_current_state = READHI1) then
        DataReceived <= s_received_data_next;
      end if;
    end if;
  end process make_data_received;

end MSE;
