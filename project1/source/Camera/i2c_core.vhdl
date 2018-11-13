library IEEE;
use ieee.std_logic_1164.all;

entity i2c_core is
  port (clock              : in    std_logic;
        reset              : in    std_logic;
        irq                : out   std_logic;
        -- slave avalon interface
        slave_address      : in    std_logic_vector(1 downto 0);
        slave_cs           : in    std_logic;
        slave_we           : in    std_logic;
        slave_write_data   : in    std_logic_vector(31 downto 0);
        slave_byte_enables : in    std_logic_vector(3 downto 0);
        slave_read_data    : out   std_logic_vector(31 downto 0);
        -- i2c buses
        SDA                : inout std_logic;
        SCL                : out   std_logic;
        Motion_IRQ         : in    std_logic);
end i2c_core;

architecture simple of i2c_core is

  -------- register model -----------
  -- 00 Write: I2c Device Identifyer (used also for autodetection index)
  --    Read:  Detected device Identifyer indexed by I2c Device Identifyer
  -- 01 Write: I2c Device Address Read: Nr. of devices detected
  -- 10 Write: I2c Data to send Read: I2C Data received from device
  -- 11 Write: Control register
  --           Bit 0 => Two-phase bit (0 -> 3 byte transfer, 1 -> two byte
  --                                   transfer)
  --           Bit 1 => Start I2C transfer
  --           Bit 2 => Start I2C autodetect
  --           Bit 3 => Clear I2C IRQ
  --           Bit 4 => Clear Motion IRQ
  --           Bit 15..8 => prescale value (0 = 400Khz, 255=1562.5Hz)
  --           Bit 16 => Enable(1)/Disable(0) I2C IRQ generation
  --           Bit 17 => Enable(1)/Disable(0) Motion IRQ generation
  --    Read:  Status register
  --           Bit 0  => I2C transfer in progress
  --           Bit 1  => I2C autodetection in progress
  --           Bit 2  => I2C device ID ack-error
  --           Bit 3  => I2C address ack-error
  --           Bit 4  => I2C data ack-error
  --           Bit 8  => I2C irq generated
  --           Bit 9  => Motion Sensor irq generated
  --           Bit 10 => I2C IRQ enabled(1)/disabled(0)
  --           Bit 11 => Motion IRQ enabled(1)/disabled(0)

  component i2c_autodetect
    port (clock         : in  std_logic;
          reset         : in  std_logic;
          start         : in  std_logic;
          ack_errors    : in  std_logic_vector(2 downto 0);
          i2c_busy      : in  std_logic;
          start_i2cc    : out std_logic;
          i2c_did       : out std_logic_vector(7 downto 0);
          nr_of_devices : out std_logic_vector(7 downto 0);
          device_addr   : in  std_logic_vector(7 downto 0);
          device_id     : out std_logic_vector(7 downto 0);
          busy          : out std_logic);
  end component;

  component i2c_cntrl
    port (clock      : in  std_logic;
          reset      : in  std_logic;
          start      : in  std_logic;
          device_id  : in  std_logic_vector(7 downto 0);
          address    : in  std_logic_vector(7 downto 0);
          data       : in  std_logic_vector(7 downto 0);
          prescale   : in  std_logic_vector(7 downto 0);
          data_out   : out std_logic_vector(7 downto 0);
          two_phase  : in  std_logic;
          SDA_out    : out std_logic;
          SDA_in     : in  std_logic;
          SCL        : out std_logic;
          busy       : out std_logic;
          ACK_ERRORs : out std_logic_vector(2 downto 0));
  end component;

  signal s_start_auto_detection  : std_logic;
  signal s_ack_errors            : std_logic_vector(2 downto 0);
  signal s_i2c_core_busy         : std_logic;
  signal s_start_i2c_core        : std_logic;
  signal s_start_auto_i2c_core   : std_logic;
  signal s_auto_did              : std_logic_vector(7 downto 0);
  signal s_did_reg               : std_logic_vector(7 downto 0);
  signal s_i2c_did               : std_logic_vector(7 downto 0);
  signal s_auto_busy             : std_logic;
  signal s_i2c_addr              : std_logic_vector(7 downto 0);
  signal s_addr_reg              : std_logic_vector(7 downto 0);
  signal s_data_reg              : std_logic_vector(7 downto 0);
  signal s_control_reg           : std_logic_vector(15 downto 0);
  signal s_i2c_data_out          : std_logic_vector(7 downto 0);
  signal s_i2c_2_phase           : std_logic;
  signal s_sda_in                : std_logic;
  signal s_sda_out               : std_logic;
  signal s_scl_out               : std_logic;
  signal s_auto_did_out          : std_logic_vector(7 downto 0);
  signal s_auto_nr_devices       : std_logic_vector(7 downto 0);
  signal s_i2c_irq_reg           : std_logic;
  signal s_i2c_irq_enable_reg    : std_logic;
  signal s_motion_irq_reg        : std_logic;
  signal s_motion_irq_enable_reg : std_logic;
  signal s_i2c_core_busy_reg     : std_logic;
  signal s_motion_delay_reg      : std_logic_vector(2 downto 0);

begin -- architecture simple

  -- Here the outputs are defined
  SDA <= '0' when s_sda_out = '0' else 'Z';
  SCL <= '0' when s_scl_out = '0' else 'Z';
  IRQ <= s_motion_irq_reg or s_i2c_irq_reg;

  make_slave_read_data : process(slave_address, s_auto_did_out,
                                 s_auto_nr_devices, s_ack_errors,
                                 s_i2c_data_out, s_auto_busy, s_i2c_core_busy,
                                 s_i2c_irq_reg, s_motion_irq_reg,
                                 s_i2c_irq_enable_reg, s_motion_irq_enable_reg)
  begin
    case (slave_address) is
      when "00"   => slave_read_data <= X"000000"&s_auto_did_out;
      when "01"   => slave_read_data <= X"000000"&s_auto_nr_devices;
      when "10"   => slave_read_data <= X"000000"&s_i2c_data_out;
      when others => slave_read_data <= X"00000"&
                                        s_motion_irq_enable_reg&
                                        s_i2c_irq_enable_reg&
                                        s_motion_irq_reg&
                                        s_i2c_irq_reg&
                                        "000"&
                                        s_ack_errors&s_auto_busy&s_i2c_core_busy;
    end case;
  end process make_slave_read_data;

  -- Here the irq handling is defined
  make_motion_irq_enable_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_motion_irq_enable_reg <= '0';
      elsif (slave_address = "11" and
             slave_cs = '1' and
             slave_we = '1' and
             slave_byte_enables(2) = '1') then
        s_motion_irq_enable_reg <= slave_write_data(17);
      end if;
    end if;
  end process make_motion_irq_enable_reg;

  make_i2c_irq_enable_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_i2c_irq_enable_reg <= '0';
      elsif (slave_address = "11" and
             slave_cs = '1' and
             slave_we = '1' and
             slave_byte_enables(2) = '1') then
        s_i2c_irq_enable_reg <= slave_write_data(16);
      end if;
    end if;
  end process make_i2c_irq_enable_reg;

  make_i2c_irq_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or
          (slave_address = "11" and
           slave_cs = '1' and
           slave_we = '1' and
           slave_byte_enables(0) = '1' and
           slave_write_data(3) = '1')) then s_i2c_irq_reg <= '0';
      elsif (s_i2c_core_busy_reg = '1' and
             s_i2c_core_busy = '0' and
             s_i2c_irq_enable_reg = '1') then s_i2c_irq_reg <= '1';
      end if;
    end if;
  end process make_i2c_irq_reg;

  make_motion_irq_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or
          (slave_address = "11" and
           slave_cs = '1' and
           slave_we = '1' and
           slave_byte_enables(0) = '1' and
           slave_write_data(4) = '1')) then s_motion_irq_reg <= '0';
      elsif (s_motion_delay_reg(2) = '1' and
             s_motion_delay_reg(1) = '0' and
             s_motion_irq_enable_reg = '1') then s_motion_irq_reg <= '1';
      end if;
    end if;
  end process make_motion_irq_reg;

  make_i2c_core_busy_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      s_i2c_core_busy_reg <= s_i2c_core_busy;
    end if;
  end process make_i2c_core_busy_reg;

  make_motion_delay_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_motion_delay_reg <= (others => '0');
      else
        s_motion_delay_reg <= s_motion_delay_reg(1 downto 0)&Motion_IRQ;
      end if;
    end if;
  end process make_motion_delay_reg;

  -- Here the control signals are defined
  s_start_auto_detection <= '1' when slave_address = "11" and
                            slave_cs = '1' and
                            slave_we = '1' and
                            slave_byte_enables(0) = '1' and
                            slave_write_data(2) = '1' else '0';
  s_start_i2c_core <= '1' when s_start_auto_i2c_core = '1' or
                      (slave_address = "11" and
                       slave_cs = '1' and
                       slave_we = '1' and
                       slave_byte_enables(0) = '1' and
                       slave_write_data(1) = '1') else '0';
  s_i2c_did     <= s_auto_did when s_auto_busy = '1' else s_did_reg;
  s_i2c_addr    <= s_addr_reg when s_auto_busy = '0' else X"00";
  s_i2c_2_phase <= s_auto_busy or s_control_reg(0);
  s_sda_in      <= SDA;

  -- Here all internal registers are defined
  make_did_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_did_reg <= (others => '0');
      elsif (slave_address = "00" and
             slave_cs = '1' and
             slave_we = '1') then
        s_did_reg <= slave_write_data(7 downto 0);
      end if;
    end if;
  end process make_did_reg;

  make_addr_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_addr_reg <= (others => '0');
      elsif (slave_address = "01" and
             slave_cs = '1' and
             slave_we = '1') then
        s_addr_reg <= slave_write_data(7 downto 0);
      end if;
    end if;
  end process make_addr_reg;

  make_data_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_data_reg <= (others => '0');
      elsif (slave_address = "10" and
             slave_cs = '1' and
             slave_we = '1') then
        s_data_reg <= slave_write_data(7 downto 0);
      end if;
    end if;
  end process make_data_reg;

  make_control_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_control_reg <= (others => '0');
      elsif (slave_address = "11" and
             slave_cs = '1' and
             slave_we = '1') then
        if (slave_byte_enables(0) = '1') then
          s_control_reg(7 downto 0) <= slave_write_data(7 downto 0);
        end if;
        if (slave_byte_enables(1) = '1') then
          s_control_reg(15 downto 8) <= slave_write_data(15 downto 8);
        end if;
      end if;
    end if;
  end process make_control_reg;

  -- Here the components are mapped
  autodetection : i2c_autodetect
    port map (clock         => clock,
              reset         => reset,
              start         => s_start_auto_detection,
              ack_errors    => s_ack_errors,
              i2c_busy      => s_i2c_core_busy,
              start_i2cc    => s_start_auto_i2c_core,
              i2c_did       => s_auto_did,
              nr_of_devices => s_auto_nr_devices,
              device_addr   => s_did_reg,
              device_id     => s_auto_did_out,
              busy          => s_auto_busy);
  core : i2c_cntrl
    port map (clock      => clock,
              reset      => reset,
              start      => s_start_i2c_core,
              device_id  => s_i2c_did,
              address    => s_i2c_addr,
              data       => s_data_reg,
              prescale   => s_control_reg(15 downto 8),
              data_out   => s_i2c_data_out,
              two_phase  => s_i2c_2_phase,
              SDA_out    => s_sda_out,
              SDA_in     => s_sda_in,
              SCL        => s_scl_out,
              busy       => s_i2c_core_busy,
              ACK_ERRORs => s_ack_errors);

end architecture simple;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_data is
  port (clock     : in  std_logic;
        reset     : in  std_logic;
        tick      : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        start     : in  std_logic;
        data_out  : out std_logic_vector(7 downto 0);
        idle      : out std_logic;
        SDA_out   : out std_logic;
        SDA_in    : in  std_logic;
        SCL       : out std_logic;
        ACK_ERROR : out std_logic);
end entity i2c_data;

architecture simple of i2c_data is

  signal s_current_state, s_next_state : std_logic_vector(5 downto 0);
  signal s_shift_reg                   : std_logic_vector(9 downto 0);
  signal s_sample_SDA_in               : std_logic;
  signal s_data_in_reg                 : std_logic_vector(8 downto 0);

begin

  idle      <= '1' when s_current_state = "111101" else '0';
  SCL       <= s_current_state(1);
  SDA_out   <= s_shift_reg(9);
  data_out  <= s_data_in_reg(8 downto 1);
  ACK_ERROR <= s_data_in_reg(0);

  -- Here the control signals are defined
  s_sample_SDA_in <= tick when s_current_state(1 downto 0) = "10" else '0';

  -- Here the data shift register is defined
  make_shift_reg : process(clock, reset, tick, data_in, start)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_shift_reg    <= (others => '0');
      elsif (start = '1') then s_shift_reg <= "0"&data_in&"1";
      elsif (tick = '1' and s_current_state(1 downto 0) = "00") then
        s_shift_reg <= s_shift_reg(8 downto 0)&"0";
      end if;
    end if;
  end process make_shift_reg;

  make_data_in_reg : process(clock, SDA_in, s_sample_SDA_in, reset)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_data_in_reg <= (others => '0');
      elsif (s_sample_SDA_in = '1') then
        s_data_in_reg <= s_data_in_reg(7 downto 0)&SDA_in;
      end if;
    end if;
  end process make_data_in_reg;

-- Here the state machine is defined
  s_next_state <= "000000" when start = '1' else
                  "111101"        when reset = '1' or
                  (s_current_state = "100100" and tick = '1') or
                  s_current_state = "111101" else
                  s_current_state when tick = '0' else
                  std_logic_vector(unsigned(s_current_state)+1);

  make_dffs : process(clock)
  begin
    if (rising_edge(clock)) then
      s_current_state <= s_next_state;
    end if;
  end process make_dffs;

end architecture simple;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity i2c_start_stop is
  port (clock        : in  std_logic;
        reset        : in  std_logic;
        tick         : in  std_logic;
        activate     : in  std_logic;
        idle_state   : out std_logic;
        active_state : out std_logic;
        SDA          : out std_logic;
        SCL          : out std_logic);
end i2c_start_stop;

architecture simple of i2c_start_stop is

  type STATE_TYPE is (IDLE, START1, START2, START3, START4,
                      ACTIVE, STOP1, STOP2, STOP3, STOP4,
                      STOP5, STOP6);

  signal s_current_state, s_next_state : STATE_TYPE;

begin

  idle_state   <= '1' when s_current_state = IDLE   else '0';
  active_state <= '1' when s_current_state = ACTIVE else '0';
  SCL          <= '0' when s_current_state = ACTIVE or
         s_current_state = STOP1 or
         s_current_state = STOP2 else '1';
  SDA <= '0' when s_current_state = START3 or
         s_current_state = START4 or
         s_current_state = ACTIVE or
         s_current_state = STOP1 or
         s_current_state = STOP2 or
         s_current_state = STOP3 or
         s_current_state = STOP4 else '1';

  -- make state machine
  make_next_state : process(s_current_state, tick, activate,
                            reset)
  begin
    if (reset = '1') then s_next_state <= IDLE;
    elsif (activate = '1' and s_current_state = ACTIVE) then
      s_next_state <= STOP1;
    elsif (activate = '1' and s_current_state = IDLE) then
      s_next_state <= START1;
    elsif (tick = '0') then s_next_state <= s_current_state;
    else
      case (s_current_state) is
        when STOP1  => s_next_state <= STOP2;
        when STOP2  => s_next_state <= STOP3;
        when STOP3  => s_next_state <= STOP4;
        when STOP4  => s_next_state <= STOP5;
        when STOP5  => s_next_state <= STOP6;
        when STOP6  => s_next_state <= IDLE;
        when START1 => s_next_state <= START2;
        when START2 => s_next_state <= START3;
        when START3 => s_next_state <= START4;
        when START4 => s_next_state <= ACTIVE;
        when others => s_next_state <= s_current_state;
      end case;
    end if;
  end process make_next_state;

  make_state_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      s_current_state <= s_next_state;
    end if;
  end process make_state_reg;

end architecture simple;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_cntrl is
  port (clock      : in  std_logic;     -- Assumed a 50MHz clock
        reset      : in  std_logic;
        start      : in  std_logic;
        device_id  : in  std_logic_vector(7 downto 0);
        address    : in  std_logic_vector(7 downto 0);
        data       : in  std_logic_vector(7 downto 0);
        prescale   : in  std_logic_vector(7 downto 0);
        data_out   : out std_logic_vector(7 downto 0);
        two_phase  : in  std_logic;
        SDA_out    : out std_logic;
        SDA_in     : in  std_logic;
        SCL        : out std_logic;
        busy       : out std_logic;
        ACK_ERRORs : out std_logic_vector(2 downto 0));
end entity i2c_cntrl;

architecture simple of i2c_cntrl is

  component i2c_start_stop
    port (clock        : in  std_logic;
          reset        : in  std_logic;
          tick         : in  std_logic;
          activate     : in  std_logic;
          idle_state   : out std_logic;
          active_state : out std_logic;
          SDA          : out std_logic;
          SCL          : out std_logic);
  end component;

  component i2c_data
    port (clock     : in  std_logic;
          reset     : in  std_logic;
          tick      : in  std_logic;
          data_in   : in  std_logic_vector(7 downto 0);
          start     : in  std_logic;
          data_out  : out std_logic_vector(7 downto 0);
          idle      : out std_logic;
          SDA_out   : out std_logic;
          SDA_in    : in  std_logic;
          SCL       : out std_logic;
          ACK_ERROR : out std_logic);
  end component;

  type STATE_TYPE is (IDLE, SCND, WSCND, DID, WDID, ADR, WADR, DAT, WDAT, SSCND, WSSCND);

  signal s_current_state, s_next_state  : STATE_TYPE;
  signal s_tick_counter                 : std_logic_vector(4 downto 0);
  signal s_prescale_counter             : std_logic_vector(7 downto 0);
  signal s_tick_pulse                   : std_logic;
  signal s_activate                     : std_logic;
  signal s_idle_state                   : std_logic;
  signal s_active_state                 : std_logic;
  signal s_sda1, s_sda2, s_scl1, s_scl2 : std_logic;
  signal s_data                         : std_logic_vector(7 downto 0);
  signal s_start_dat                    : std_logic;
  signal s_dat_idle                     : std_logic;
  signal s_sda_reg, s_scl_reg           : std_logic;
  signal s_ack_error                    : std_logic;
  signal s_ack_errors_reg               : std_logic_vector(2 downto 0);

begin -- architecture simple

-- make sda and scl
  make_reg : process(clock)
  begin
    if (rising_edge(clock)) then
      s_sda_reg <= s_sda1 or s_sda2;
      s_scl_reg <= s_scl1 or s_scl2;
    end if;
  end process make_reg;

  SDA_out    <= s_sda_reg;
  SCL        <= s_scl_reg;
  ACK_ERRORs <= s_ack_errors_reg;

  -- Make tick counter
  make_counter : process(clock, reset)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_tick_counter <= (others => '1');
      elsif (s_prescale_counter = X"00") then
        s_tick_counter <= std_logic_vector(unsigned(s_tick_counter)-1);
      end if;
    end if;
  end process make_counter;

  make_prescale_counter : process(clock, reset, prescale)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_prescale_counter <= (others => '0');
      elsif (s_prescale_counter = X"00") then
        s_prescale_counter <= prescale;
      else
        s_prescale_counter <= std_logic_vector(unsigned(s_prescale_counter)- 1);
      end if;
    end if;
  end process make_prescale_counter;

  s_tick_pulse <= '1' when s_tick_counter = "00000" and
                  s_prescale_counter = X"00" else '0';

  -- Make state machine
  make_next_state : process(s_current_state, start, s_active_state,
                            s_idle_state, s_dat_idle)
  begin
    case (s_current_state) is
      when IDLE =>
        if (start = '1') then s_next_state <= SCND;
        else s_next_state                  <= IDLE;
        end if;
      when SCND => s_next_state <= WSCND;
      when WSCND =>
        if (s_active_state = '1') then s_next_state <= DID;
        else s_next_state                           <= WSCND;
        end if;
      when DID => s_next_state <= WDID;
      when WDID =>
        if (s_dat_idle = '1') then s_next_state <= ADR;
        else s_next_state                       <= WDID;
        end if;
      when ADR => s_next_state <= WADR;
      when WADR =>
        if (s_dat_idle = '1') then
          if (two_phase = '1' or
              device_id(0) = '1') then s_next_state <= SSCND;
          else s_next_state <= DAT;
          end if;
        else s_next_state <= WADR;
        end if;
      when DAT => s_next_state <= WDAT;
      when WDAT =>
        if (s_dat_idle = '1') then s_next_state <= SSCND;
        else s_next_state                       <= WDAT;
        end if;
      when SSCND => s_next_state <= WSSCND;
      when WSSCND =>
        if (s_idle_state = '1') then s_next_state <= IDLE;
        else s_next_state                         <= WSSCND;
        end if;
      when others => s_next_state <= IDLE;
    end case;
  end process make_next_state;

  make_state_reg : process(clock, reset)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_current_state <= IDLE;
      else s_current_state                  <= s_next_state;
      end if;
    end if;
  end process make_state_reg;

  -- Map signals
  s_activate <= '1' when s_current_state = SCND or
                s_current_state = SSCND else '0';
  s_data <= X"FF" when s_current_state = ADR and
            device_id(0) = '1' else
            address when s_current_state = ADR else
            data    when s_current_state = DAT else
            device_id;
  s_start_dat <= '1' when s_current_state = DID or
                 s_current_state = ADR or
                 s_current_state = DAT else '0';
  busy <= '0' when s_current_state = IDLE else '1';

  -- Define Ack errors
  make_ack_errors : process(clock, reset, start,
                            s_current_state, s_ack_error)
  begin
    if (rising_edge(clock)) then
      if (start = '1' or
          reset = '1') then s_ack_errors_reg <= "000";
      else
        if (s_current_state = ADR) then s_ack_errors_reg(0) <= s_ack_error;
        end if;
        if (s_current_state = DAT or
            (s_current_state = SSCND and
             (two_phase = '1' or device_id(0) = '1'))) then
          s_ack_errors_reg(1) <= s_ack_error;
        end if;
        if (s_current_state = SSCND and
            two_phase = '0' and device_id(0) = '0') then
          s_ack_errors_reg(2) <= s_ack_error;
        end if;
      end if;
    end if;
  end process make_ack_errors;

  -- Map components
  start_stop_gen : i2c_start_stop
    port map (clock        => clock,
              reset        => reset,
              tick         => s_tick_pulse,
              activate     => s_activate,
              idle_state   => s_idle_state,
              active_state => s_active_state,
              SDA          => s_sda1,
              SCL          => s_scl1);

  data_gen : i2c_data
    port map (clock     => clock,
              reset     => reset,
              tick      => s_tick_pulse,
              data_in   => s_data,
              start     => s_start_dat,
              data_out  => data_out,
              idle      => s_dat_idle,
              SDA_out   => s_sda2,
              SDA_in    => SDA_in,
              SCL       => s_scl2,
              ACK_error => s_ack_error);
end architecture simple;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_autodetect is
  port (clock : in std_logic;
        reset : in std_logic;
        start : in std_logic;

        ack_errors : in  std_logic_vector(2 downto 0);
        i2c_busy   : in  std_logic;
        start_i2cc : out std_logic;
        i2c_did    : out std_logic_vector(7 downto 0);

        nr_of_devices : out std_logic_vector(7 downto 0);
        device_addr   : in  std_logic_vector(7 downto 0);
        device_id     : out std_logic_vector(7 downto 0);

        busy : out std_logic);
end entity i2c_autodetect;

architecture simple of i2c_autodetect is

  type STATE_TYPE is (IDLE, START_I2C, WAIT_I2C, UPDATE, NEXT_DID);
  type RAM_TYPE is array(255 downto 0) of std_logic_vector(6 downto 0);

  signal s_did_counter_reg             : std_logic_vector(6 downto 0);
  signal s_current_state, s_next_state : STATE_TYPE;
  signal s_device_count_reg            : std_logic_vector(7 downto 0);
  signal s_device_found                : std_logic;
  signal ram                           : RAM_TYPE;
  signal s_ram_address                 : std_logic_vector(7 downto 0);
  signal s_ram_read_address            : std_logic_vector(7 downto 0);

begin

  -- Here the outputs are defined
  busy          <= '0' when s_current_state = IDLE      else '1';
  i2c_did       <= s_did_counter_reg&"0";
  start_i2cc    <= '1' when s_current_state = START_I2C else '0';
  nr_of_devices <= s_device_count_reg;

  -- Assign control signals
  s_device_found <= '1' when s_current_state = UPDATE and
                    ack_errors = "000" else '0';
  s_ram_address <= device_addr when s_current_state = IDLE else
                   s_device_count_reg;

  -- Make device counter
  make_dev_count : process(clock, reset, start, s_device_found)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or start = '1') then
        s_device_count_reg <= (others => '0');
      elsif (s_device_found = '1') then
        s_device_count_reg <= std_logic_vector(unsigned(s_device_count_reg)+1);
      end if;
    end if;
  end process make_dev_count;

  -- Make the did counter
  make_did : process(reset, start, clock, s_current_state)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or start = '1') then
        s_did_counter_reg <= (others => '0');
      elsif (s_current_state = NEXT_DID) then
        s_did_counter_reg <= std_logic_vector(unsigned(s_did_counter_reg)+1);
      end if;
    end if;
  end process make_did;

  -- Here the memory is defined
  ramproc : process(clock)
  begin
    if (rising_edge(clock)) then
      if (s_device_found = '1') then
        ram(to_integer(unsigned(s_ram_address))) <= s_did_counter_reg;
      end if;
      s_ram_read_address <= s_ram_address;
    end if;
  end process ramproc;

  device_id(7 downto 1) <= ram(to_integer(unsigned(s_ram_read_address)));
  device_id(0)          <= '0';

  -- Here the state machine is defined
  make_next_state : process(s_current_state, i2c_busy, s_did_counter_reg,
                            start)
  begin
    case (s_current_state) is
      when IDLE =>
        if (start = '1') then s_next_state <= START_I2C;
        else s_next_state                  <= IDLE;
        end if;
      when START_I2C => s_next_state <= WAIT_I2C;
      when WAIT_I2C =>
        if (i2c_busy = '1') then s_next_state <= WAIT_I2C;
        else s_next_state                     <= UPDATE;
        end if;
      when UPDATE => s_next_state <= NEXT_DID;
      when NEXT_DID =>
        if (s_did_counter_reg = "1111111") then
          s_next_state <= IDLE;
        else
          s_next_state <= START_I2C;
        end if;
      when others => s_next_state <= IDLE;
    end case;
  end process make_next_state;

  make_state_reg : process(clock, reset, s_next_state)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_current_state <= IDLE;
      else s_current_state                  <= s_next_state;
      end if;
    end if;
  end process make_state_reg;

end architecture simple;

--------------------------------------------------------------------------------
