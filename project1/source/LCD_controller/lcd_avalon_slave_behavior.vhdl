architecture MSE of lcd_avalon_slave is

  type LCD_READ_TYPE is (IDLE, WAITBUSY, INITREAD, WAITREAD, RELEASE);

  component LcdController is
    port (  -- Here the internal interface is defined
      Clock                 : in    std_logic;
      Reset                 : in    std_logic;
      ResetDisplay          : in    std_logic;
      StartSendReceive      : in    std_logic;
      CommandBarData        : in    std_logic;
      EightBitSixteenBitBar : in    std_logic;
      WriteReadBar          : in    std_logic;
      DataToSend            : in    std_logic_vector(15 downto 0);
      DataReceived          : out   std_logic_vector(15 downto 0);
      busy                  : out   std_logic;
      -- Here the external LCD-panel signals are defined
      ChipSelectBar         : out   std_logic;
      DataCommandBar        : out   std_logic;
      WriteBar              : out   std_logic;
      ReadBar               : out   std_logic;
      ResetBar              : out   std_logic;
      IM0                   : out   std_logic;
      DataBus               : inout std_logic_vector(15 downto 0));
  end component;

  signal s_WriteReadBar     : std_logic;
  signal s_StartSendReceive : std_logic;
  signal s_CommandBarData   : std_logic;
  signal s_busy             : std_logic;
  signal s_control_reg      : std_logic_vector(31 downto 0);
  signal s_control_next     : std_logic_vector(31 downto 0);
  signal s_LCD_data_out     : std_logic_vector(15 downto 0);
  signal s_Data_to_send     : std_logic_vector(15 downto 0);
  signal s_current_state    : LCD_READ_TYPE;
  signal s_next_state       : LCD_READ_TYPE;
  signal s_reset_display    : std_logic;

begin
--------------------------------------------------------------------------------
---                                                                          ---
--- In this section the avalon slave signals are defined                     ---
---                                                                          ---
--------------------------------------------------------------------------------
  slave_read_data <= s_control_reg when slave_address = "10" else
                     s_LCD_data_out&s_LCD_data_out when slave_address(1) = '0' else
                     (others => '0');

  slave_wait_request <= '1' when slave_cs = '1' and
                                 slave_address(1) = '0' and
                                 ((slave_we = '1' and s_busy = '1') or
                                 (slave_rd = '1' and s_current_state /= RELEASE)) else
                        '0';


--------------------------------------------------------------------------------
---                                                                          ---
--- In this section the LCD-read state machine is defined                    ---
---                                                                          ---
--------------------------------------------------------------------------------

  make_next_state : process(s_current_state, slave_cs, slave_address,
                            slave_rd, s_busy)
  begin
    case (s_current_state) is
      when IDLE =>
        if (slave_cs = '1' and slave_address(1) = '0' and slave_rd = '1') then
          s_next_state <= WAITBUSY;
        else
          s_next_state <= IDLE;
        end if;
      when WAITBUSY =>
        if s_busy = '1' then
          s_next_state <= WAITBUSY;
        else
          s_next_state <= INITREAD;
        end if;
      when INITREAD => s_next_state <= WAITREAD;
      when WAITREAD =>
        if s_busy = '1' then
          s_next_state <= WAITREAD;
        else
          s_next_state <= RELEASE;
        end if;
      when others => s_next_state <= IDLE;
    end case;
  end process make_next_state;

  make_current_state : process(Clock)
  begin
    if rising_edge(Clock) then
      if Reset = '1' then
        s_current_state <= IDLE;
      else
        s_current_state <= s_next_state;
      end if;
    end if;
  end process make_current_state;

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section the control register is defined                          ---
---                                                                          ---
--------------------------------------------------------------------------------
  s_control_next <= slave_write_data when slave_we = '1' and
                                          slave_cs = '1' and
                                          slave_address = "10" else
                    s_control_reg;

  make_control_reg : process(Clock)
  begin
    if rising_edge(Clock) then
      if Reset = '1' then
        s_control_reg <= (others => '0');
      else
        s_control_reg <= s_control_next;
      end if;
    end if;
  end process make_control_reg;

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section all control signals are defined                          ---
---                                                                          ---
--------------------------------------------------------------------------------

  s_WriteReadBar <= slave_we;



  s_StartSendReceive <= '1' when (slave_we = '1' and
                                  slave_cs = '1' and
                                  slave_address(1) = '0' and
                                  s_busy = '0') or
                                 (s_current_state = INITREAD) else
                        '0';
  s_reset_display <= '1' when slave_we = '1' and
                              slave_cs = '1' and
                              slave_address = "10" and
                              slave_write_data(1) = '1' else
                     '0';


  sample_data_to_send : process(Clock)
  begin
    if rising_edge(Clock) then
      s_Data_to_send <= slave_write_data(15 downto 0);
      s_CommandBarData <= slave_address(0);
    end if;
  end process sample_data_to_send;

--------------------------------------------------------------------------------
---                                                                          ---
--- In this section all components are connected                             ---
---                                                                          ---
--------------------------------------------------------------------------------

  interface : LcdController
    port map (Clock                 => Clock,
              Reset                 => Reset,
              ResetDisplay          => s_reset_display,
              StartSendReceive      => s_StartSendReceive,
              CommandBarData        => s_CommandBarData,
              EightBitSixteenBitBar => s_control_reg(0),
              WriteReadBar          => s_WriteReadBar,
              DataToSend            => s_Data_to_send,
              DataReceived          => s_LCD_data_out,
              busy                  => s_busy,
              -- Here the external LCD-panel signals are defined
              ChipSelectBar         => ChipSelectBar,
              DataCommandBar        => DataCommandBar,
              WriteBar              => WriteBar,
              ReadBar               => ReadBar,
              ResetBar              => ResetBar,
              IM0                   => IM0,
              DataBus               => DataBus);

end MSE;
