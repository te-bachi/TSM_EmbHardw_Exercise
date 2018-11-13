library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_if is
  port (clock             : in  std_logic;
        reset             : in  std_logic;
        irq               : out std_logic;
        -- slave avalon interface
        slave_address     : in  std_logic_vector(2 downto 0);
        slave_cs          : in  std_logic;
        slave_we          : in  std_logic;
        slave_write_data  : in  std_logic_vector(31 downto 0);
        slave_read_data   : out std_logic_vector(31 downto 0);
        -- master avalon interface
        master_address    : out std_logic_vector(31 downto 0);
        master_cs         : out std_logic;
        master_we         : out std_logic;
        master_write_data : out std_logic_vector(31 downto 0);
        master_wait_req   : in  std_logic;
        -- camera interface
        cam_PX_clock      : in  std_logic;
        cam_vsync         : in  std_logic;
        cam_href          : in  std_logic;
        cam_data          : in  std_logic_vector(9 downto 0);
        cam_reset         : out std_logic;
        cam_pwdn          : out std_logic);
end entity camera_if;

architecture simple of camera_if is

  -------- register model -----------
  -- 000 camara FPS (read only)
  -- 001 camera control register
  --        bit 0 => take one picture
  --        bit 1 => start continues mode
  --        bit 2 => stop continues mode
  --        bit 3 => enable irq
  --        bit 4 => disable irq
  --        bit 5 => clear irq
  --     read:
  --        bit 0 => Busy taking picture
  --        bit 1 => In continues mode
  --        bit 4 => IRQ enabled
  --        bit 5 => IRQ generated
  -- 010 address of buffer containing current image (read only)
  -- 011 camera reset pwrdn control
  --        bit 0 => reset bit (default 0)
  --        bit 1 => power down bit (default 1)
  --        bit 2 => (0 => double buffer, 1 => quad buffer)
  -- 100 buffer 1 address
  -- 101 buffer 2 address
  -- 110 buffer 3 address
  -- 111 buffer 4 address

  component synchro_flop
    port (clock_in  : in  std_logic;
          clock_out : in  std_logic;
          reset     : in  std_logic;
          tick_in   : in  std_logic;
          tick_out  : out std_logic);
  end component;

  component ram_dp_1k
    port(clock_A : in  std_logic;
         we_A    : in  std_logic;
         addr_A  : in  std_logic_vector(9 downto 0);
         Din_A   : in  std_logic_vector(7 downto 0);
         Dout_A  : out std_logic_vector(7 downto 0);
         clock_B : in  std_logic;
         we_B    : in  std_logic;
         addr_B  : in  std_logic_vector(9 downto 0);
         Din_B   : in  std_logic_vector(7 downto 0);
         Dout_B  : out std_logic_vector(7 downto 0));
  end component;

  component ram_sp_1k_32
    port(clock : in  std_logic;
         we    : in  std_logic;
         addr  : in  std_logic_vector(7 downto 0);
         Din   : in  std_logic_vector(31 downto 0);
         Dout  : out std_logic_vector(31 downto 0));
  end component;

  type LINE_CONVERSION_TYPE is (IDLE, READ1, READ2, READ3,
                                READ4, READ5, READ6, READ7,
                                READ8, TRANSFER);
  type CAMERA_CONTROL_TYPE is (NOOP, WAIT_NEW_IMAGE, STORE_IMAGE,
                               INIT_1, STORE_IMAGE_1, INIT_2, STORE_IMAGE_2,
                               INIT_3, STORE_IMAGE_3, INIT_4, STORE_IMAGE_4,
                               GENIRQ);
  type DMA_TYPE is (NOACTION, WAITONE, WRITE, WAITWRITE);

  signal s_reset_reg           : std_logic;
  signal s_power_down_reg      : std_logic;
  signal s_buffer_reg          : std_logic;
  signal s_addr_1_reg          : std_logic_vector(32 downto 0);
  signal s_addr_2_reg          : std_logic_vector(32 downto 0);
  signal s_addr_3_reg          : std_logic_vector(32 downto 0);
  signal s_addr_4_reg          : std_logic_vector(32 downto 0);
  signal s_vsync_del_reg       : std_logic_vector(2 downto 0);
  signal s_hsync_del_reg       : std_logic_vector(2 downto 0);
  signal s_new_screen          : std_logic;
  signal s_new_screen_tick     : std_logic;
  signal s_line_done           : std_logic;
  signal s_line_done_tick      : std_logic;
  signal s_second_counter      : std_logic_vector(25 downto 0);
  signal s_second_tick         : std_logic;
  signal s_framerate_counter   : std_logic_vector(7 downto 0);
  signal s_framerate_reg       : std_logic_vector(7 downto 0);
  signal s_line_byte_count     : std_logic_vector(9 downto 0);
  signal s_buffer_select       : std_logic;
  signal s_pixel_data          : std_logic_vector(9 downto 0);
  signal s_we_line_1           : std_logic;
  signal s_we_line_2           : std_logic;
  signal s_line_conv_state     : LINE_CONVERSION_TYPE;
  signal s_line_conv_state_del : LINE_CONVERSION_TYPE;
  signal s_line_conv_next      : LINE_CONVERSION_TYPE;
  signal s_pix_read_addr       : std_logic_vector(9 downto 0);
  signal s_line_data_1         : std_logic_vector(7 downto 0);
  signal s_line_data_2         : std_logic_vector(7 downto 0);
  signal s_comp_px_data        : std_logic_vector(7 downto 0);
  signal s_pixel_1             : std_logic_vector(23 downto 0);
  signal s_pixel_2             : std_logic_vector(23 downto 0);
  signal s_pixel_3             : std_logic_vector(23 downto 0);
  signal s_pixel_4             : std_logic_vector(23 downto 0);
  signal s_combined_data       : std_logic_vector(31 downto 0);
  signal s_write_word          : std_logic;
  signal s_word_addr           : std_logic_vector(7 downto 0);
  signal s_dma_addr            : std_logic_vector(7 downto 0);
  signal s_rw_addr             : std_logic_vector(7 downto 0);
  signal s_start_snapshot      : std_logic;
  signal s_camera_state        : CAMERA_CONTROL_TYPE;
  signal s_camera_next         : CAMERA_CONTROL_TYPE;
  signal s_bus_write_address   : std_logic_vector(31 downto 2);
  signal s_bus_load_address    : std_logic_vector(31 downto 2);
  signal s_load_bus_address    : std_logic;
  signal s_bus_data_next       : std_logic_vector(31 downto 0);
  signal s_dma_state           : DMA_TYPE;
  signal s_dma_next            : DMA_TYPE;
  signal s_start_dma           : std_logic;
  signal s_dma_we_reg          : std_logic;
  signal s_red                 : std_logic_vector(4 downto 0);
  signal s_green               : std_logic_vector(5 downto 0);
  signal s_blue                : std_logic_vector(4 downto 0);
  signal s_irq_enable_reg      : std_logic;
  signal s_irq_reg             : std_logic;
  signal s_enable_irq          : std_logic;
  signal s_disable_irq         : std_logic;
  signal s_clear_irq           : std_logic;
  signal s_gen_irq             : std_logic;
  signal s_camera_busy         : std_logic;
  signal s_continues_mode      : std_logic;
  signal s_enable_cont_mode    : std_logic;
  signal s_disable_cont_mode   : std_logic;
  signal s_current_image_addr  : std_logic_vector(31 downto 2);

begin

  -- Here the irq handling is defined
  irq <= s_irq_reg;

  s_gen_irq <= '1' when s_irq_enable_reg = '1' and
               (s_camera_state = GENIRQ or
                s_camera_state = INIT_1 or
                s_camera_state = INIT_2 or
                s_camera_state = INIT_3 or
                s_camera_state = INIT_4) else '0';
  s_enable_irq <= '1' when slave_address = "001" and
                  slave_cs = '1' and
                  slave_we = '1' and
                  slave_write_data(3) = '1' else '0';
  s_disable_irq <= '1' when slave_address = "001" and
                   slave_cs = '1' and
                   slave_we = '1' and
                   slave_write_data(4) = '1' else '0';
  s_clear_irq <= '1' when slave_address = "001" and
                 slave_cs = '1' and
                 slave_we = '1' and
                 slave_write_data(5) = '1' else '0';

  make_irq_enable_reg : process (clock)
  begin
    if (rising_edge(clock)) then
      if (s_disable_irq = '1' or
          reset = '1') then s_irq_enable_reg <= '0';
      elsif (s_enable_irq = '1') then s_irq_enable_reg <= '1';
      end if;
    end if;
  end process make_irq_enable_reg;


  make_irq_reg : process (clock)
  begin
    if (rising_edge(clock)) then
      if (s_clear_irq = '1' or
          reset = '1') then s_irq_reg <= '0';
      elsif (s_gen_irq = '1') then s_irq_reg <= '1';
      end if;
    end if;
  end process make_irq_reg;

  -- Here the continues mode reg is defined
  s_disable_cont_mode <= '1' when slave_address = "001" and
                         slave_cs = '1' and
                         slave_we = '1' and
                         slave_write_data(2) = '1' else '0';
  s_enable_cont_mode <= '1' when slave_address = "001" and
                        slave_cs = '1' and
                        slave_we = '1' and
                        slave_write_data(1) = '1' and
                        ((s_buffer_reg = '0' and
                          s_addr_1_reg(32) = '1' and
                          s_addr_2_reg(32) = '1') or
                         (s_buffer_reg = '1' and
                          s_addr_1_reg(32) = '1' and
                          s_addr_2_reg(32) = '1' and
                          s_addr_3_reg(32) = '1' and
                          s_addr_4_reg(32) = '1'))else '0';

  make_continues_mode : process (clock)
  begin
    if (rising_edge(clock)) then
      if (s_disable_cont_mode = '1' or
          reset = '1') then s_continues_mode <= '0';
      elsif (s_enable_cont_mode = '1') then
        s_continues_mode <= '1';
      end if;
    end if;
  end process make_continues_mode;

  -- Here the outputs are defined
  cam_reset <= s_reset_reg;
  cam_pwdn  <= s_power_down_reg;

  -- Here the main state machine is defined
  s_camera_busy <= '0' when s_camera_state = NOOP else '1';
  make_camera_next : process (s_camera_state, s_start_snapshot,
                              s_new_screen_tick, s_continues_mode,
                              s_buffer_reg)
  begin
    case (s_camera_state) is
      when NOOP =>
        if (s_start_snapshot = '1' or
            s_continues_mode = '1') then
          s_camera_next <= WAIT_NEW_IMAGE;
        else
          s_camera_next <= NOOP;
        end if;
      when WAIT_NEW_IMAGE =>
        if (s_new_screen_tick = '1') then
          if (s_continues_mode = '1') then
            s_camera_next <= STORE_IMAGE_1;
          else
            s_camera_next <= STORE_IMAGE;
          end if;
        else
          s_camera_next <= WAIT_NEW_IMAGE;
        end if;
      when STORE_IMAGE =>
        if (s_new_screen_tick = '1') then
          s_camera_next <= GENIRQ;
        else
          s_camera_next <= STORE_IMAGE;
        end if;
      when INIT_1 => s_camera_next <= STORE_IMAGE_1;
      when STORE_IMAGE_1 =>
        if (s_new_screen_tick = '1') then
          s_camera_next <= INIT_2;
        else
          s_camera_next <= STORE_IMAGE_1;
        end if;
      when INIT_2 =>
        if (s_continues_mode = '0') then
          s_camera_next <= NOOP;
        else
          s_camera_next <= STORE_IMAGE_2;
        end if;
      when STORE_IMAGE_2 =>
        if (s_new_screen_tick = '1') then
          if (s_buffer_reg = '0') then
            s_camera_next <= INIT_1;
          else
            s_camera_next <= INIT_3;
          end if;
        else
          s_camera_next <= STORE_IMAGE_2;
        end if;
      when INIT_3 => s_camera_next <= STORE_IMAGE_3;
      when STORE_IMAGE_3 =>
        if (s_new_screen_tick = '1') then
          s_camera_next <= INIT_4;
        else
          s_camera_next <= STORE_IMAGE_3;
        end if;
      when INIT_4 => s_camera_next <= STORE_IMAGE_4;
      when STORE_IMAGE_4 =>
        if (s_new_screen_tick = '1') then
          s_camera_next <= INIT_1;
        else
          s_camera_next <= STORE_IMAGE_4;
        end if;
      when others => s_camera_next <= NOOP;
    end case;
  end process make_camera_next;

  make_camera_state : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_camera_state <= NOOP;
      else s_camera_state                  <= s_camera_next;
      end if;
    end if;
  end process make_camera_state;


-- Here all control signals are defined
  s_start_snapshot <= '1' when slave_address = "001" and
                      slave_cs = '1' and
                      slave_we = '1' and
                      slave_write_data(0) = '1' and
                      s_addr_1_reg(32) = '1' else '0';
  s_current_image_addr <= s_addr_2_reg(31 downto 2)
                          when (s_camera_state = STORE_IMAGE_1 and
                                s_buffer_reg = '0') or
                          s_camera_state = STORE_IMAGE_3 else
                          s_addr_3_reg(31 downto 2)
                          when s_camera_state = STORE_IMAGE_4 else
                          s_addr_4_reg(31 downto 2)
                          when (s_camera_state = STORE_IMAGE_1 and
                                s_buffer_reg = '1') else
                          s_addr_1_reg(31 downto 2);

  make_slave_data : process (slave_address, s_framerate_reg,
                             s_addr_1_reg, s_addr_2_reg,
                             s_addr_3_reg, s_addr_4_reg,
                             s_camera_state, s_camera_busy,
                             s_continues_mode, s_irq_enable_reg,
                             s_current_image_addr)
  begin
    case (slave_address) is
      when "000" => slave_read_data <= X"000000"&s_framerate_reg;
      when "001" => slave_read_data <= X"000000"&
                                       "00"&s_irq_reg&s_irq_enable_reg&
                                       "00"&s_continues_mode&s_camera_busy;
      when "010" => slave_read_data <= s_current_image_addr&"00";
      when "011" => slave_read_data <= X"0000000"&"0"&s_buffer_reg&
                                       s_power_down_reg&s_reset_reg;
      when "100"  => slave_read_data <= s_addr_1_reg(31 downto 0);
      when "101"  => slave_read_data <= s_addr_2_reg(31 downto 0);
      when "110"  => slave_read_data <= s_addr_3_reg(31 downto 0);
      when "111"  => slave_read_data <= s_addr_4_reg(31 downto 0);
      when others => slave_read_data <= (others => '0');
    end case;
  end process make_slave_data;

-- Here all registers are defined
  make_addr_1_reg : process (clock, reset, slave_address,
                             slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_addr_1_reg <= (others => '0');
      elsif (slave_address = "100" and
             slave_cs = '1' and
             slave_we = '1') then
        s_addr_1_reg <= "1"&slave_write_data;
      end if;
    end if;
  end process make_addr_1_reg;

  make_addr_2_reg : process (clock, reset, slave_address,
                             slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_addr_2_reg <= (others => '0');
      elsif (slave_address = "101" and
             slave_cs = '1' and
             slave_we = '1') then
        s_addr_2_reg <= "1"&slave_write_data;
      end if;
    end if;
  end process make_addr_2_reg;

  make_addr_3_reg : process (clock, reset, slave_address,
                             slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_addr_3_reg <= (others => '0');
      elsif (slave_address = "110" and
             slave_cs = '1' and
             slave_we = '1') then
        s_addr_3_reg <= "1"&slave_write_data;
      end if;
    end if;
  end process make_addr_3_reg;

  make_addr_4_reg : process (clock, reset, slave_address,
                             slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_addr_4_reg <= (others => '0');
      elsif (slave_address = "111" and
             slave_cs = '1' and
             slave_we = '1') then
        s_addr_4_reg <= "1"&slave_write_data;
      end if;
    end if;
  end process make_addr_4_reg;

  make_buffer_reg : process (clock, reset, slave_address,
                             slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_buffer_reg <= '0';
      elsif (slave_address = "011" and
             slave_cs = '1' and
             slave_we = '1') then
        s_buffer_reg <= slave_write_data(2);
      end if;
    end if;
  end process make_buffer_reg;

  make_reset_reg : process (clock, reset, slave_address,
                            slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_reset_reg <= '0';
      elsif (slave_address = "011" and
             slave_cs = '1' and
             slave_we = '1') then
        s_reset_reg <= slave_write_data(0);
      end if;
    end if;
  end process make_reset_reg;

  make_pwdn_reg : process (clock, reset, slave_address,
                           slave_cs, slave_we, slave_write_data)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_power_down_reg <= '1';
      elsif (slave_address = "011" and
             slave_cs = '1' and
             slave_we = '1') then
        s_power_down_reg <= slave_write_data(1);
      end if;
    end if;
  end process make_pwdn_reg;

-- Here we define some detection registers for profiling
  s_new_screen <= s_vsync_del_reg(2) and not(s_vsync_del_reg(1));
  s_line_done  <= not(s_vsync_del_reg(1)) and
                 s_hsync_del_reg(2) and
                 not(s_hsync_del_reg(1));
  s_second_tick <= '1' when s_second_counter = "00"&X"000000" else '0';

  make_vsyn_del_reg : process (cam_PX_clock, cam_vsync, reset)
  begin
    if (reset = '1') then s_vsync_del_reg <= (others => '0');
    elsif (rising_edge(cam_PX_clock)) then
      s_vsync_del_reg <= s_vsync_del_reg(1 downto 0)&cam_vsync;
    end if;
  end process make_vsyn_del_reg;

  make_hsync_del_reg : process (cam_PX_clock, reset, cam_href)
  begin
    if (reset = '1') then s_hsync_del_reg <= (others => '0');
    elsif (rising_edge(cam_PX_clock)) then
      s_hsync_del_reg <= s_hsync_del_reg(1 downto 0)&cam_href;
    end if;
  end process make_hsync_del_reg;

  make_second_counter : process (clock, reset, s_second_tick)
  begin
    if (rising_edge(clock)) then
      if (s_second_tick = '1' or
          reset = '1') then
        s_second_counter <= std_logic_vector(to_unsigned(49999999, 26));
      else
        s_second_counter <= std_logic_vector(unsigned(s_second_counter)-1);
      end if;
    end if;
  end process make_second_counter;

  make_framerate_counter : process (clock, reset, s_new_screen_tick,
                                    s_second_tick)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or
          s_second_tick = '1') then s_framerate_counter <= (others => '0');
      elsif (s_new_screen_tick = '1') then
        s_framerate_counter <= std_logic_vector(unsigned(s_framerate_counter)+1);
      end if;
    end if;
  end process make_framerate_counter;

  make_framerate_reg : process (clock, reset, s_second_tick,
                                s_framerate_counter)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_framerate_reg <= (others => '0');
      elsif (s_second_tick = '1') then
        s_framerate_reg <= s_framerate_counter;
      end if;
    end if;
  end process make_framerate_reg;

  make_line_byte_count : process (cam_PX_clock, s_line_done,
                                  s_new_screen, s_hsync_del_reg,
                                  s_vsync_del_reg)
  begin
    if (falling_edge(cam_PX_clock)) then
      if (s_new_screen = '1' or
          s_line_done = '1') then s_line_byte_count <= (others => '0');
      elsif (s_hsync_del_reg(0) = '1' and
             s_vsync_del_reg(0) = '0') then
        s_line_byte_count <= std_logic_vector(unsigned(s_line_byte_count)+1);
      end if;
    end if;
  end process make_line_byte_count;

  screen_tick_sync : synchro_flop
    port map (clock_in  => cam_PX_clock,
              clock_out => clock,
              reset     => reset,
              tick_in   => s_new_screen,
              tick_out  => s_new_screen_tick);

  line_done_tick : synchro_flop
    port map (clock_in  => cam_PX_clock,
              clock_out => clock,
              reset     => reset,
              tick_in   => s_line_done,
              tick_out  => s_line_done_tick);

-- Here the line-write buffers are defined
  s_we_line_1 <= '1' when s_buffer_select = '0' and
                 s_hsync_del_reg(0) = '1' and
                 s_vsync_del_reg(0) = '0' else '0';
  s_we_line_2 <= '1' when s_buffer_select = '1' and
                 s_hsync_del_reg(0) = '1' and
                 s_vsync_del_reg(0) = '0' else '0';
  s_combined_data <= s_pixel_2(7 downto 0)&s_pixel_1
                     when s_line_conv_state_del = READ5 else
                     s_pixel_3(15 downto 0)&s_pixel_2(23 downto 8)
                     when s_line_conv_state_del = READ7 else
                     s_pixel_4&s_pixel_3(23 downto 16);

  make_buffer_select : process (cam_PX_clock, s_line_done, reset)
  begin
    if (reset = '1') then s_buffer_select <= '0';
    elsif (rising_edge(cam_PX_clock)) then
      if (s_line_done = '1') then
        s_buffer_select <= not(s_buffer_select);
      end if;
    end if;
  end process make_buffer_select;

  make_pixel_data : process (cam_PX_clock)
  begin
    if (falling_edge(cam_PX_clock)) then
      s_pixel_data <= cam_data;
    end if;
  end process make_pixel_data;

  line_1 : ram_dp_1k
    port map (clock_A => not(cam_PX_clock),
              we_A    => s_we_line_1,
              addr_A  => s_line_byte_count,
              Din_A   => s_pixel_data(9 downto 2),
              Dout_A  => open,
              clock_B => clock,
              we_B    => '0',
              addr_B  => s_pix_read_addr,
              Din_B   => X"00",
              Dout_B  => s_line_data_1);

  line_2 : ram_dp_1k
    port map (clock_A => not(cam_PX_clock),
              we_A    => s_we_line_2,
              addr_A  => s_line_byte_count,
              Din_A   => s_pixel_data(9 downto 2),
              Dout_A  => open,
              clock_B => clock,
              we_B    => '0',
              addr_B  => s_pix_read_addr,
              Din_B   => X"00",
              Dout_B  => s_line_data_2);

-- here the line-data conversion is defined
  s_comp_px_data <= s_line_data_2 when s_buffer_select = '0' else
                    s_line_data_1;

  make_line_conv_next : process (s_line_conv_state, s_line_done_tick,
                                 s_pix_read_addr)
  begin
    case (s_line_conv_state) is
      when IDLE =>
        if (s_line_done_tick = '1') then
          s_line_conv_next <= READ1;
        else
          s_line_conv_next <= IDLE;
        end if;
      when READ1 => s_line_conv_next <= READ2;
      when READ2 => s_line_conv_next <= READ3;
      when READ3 => s_line_conv_next <= READ4;
      when READ4 => s_line_conv_next <= READ5;
      when READ5 => s_line_conv_next <= READ6;
      when READ6 => s_line_conv_next <= READ7;
      when READ7 => s_line_conv_next <= READ8;
      when READ8 =>
        if (unsigned(s_pix_read_addr) <
            to_unsigned(639, 10)) then
          s_line_conv_next <= READ1;
        else
          s_line_conv_next <= TRANSFER;
        end if;
      when others => s_line_conv_next <= IDLE;
    end case;
  end process make_line_conv_next;

  make_line_conv_state : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_line_conv_state <= IDLE;
                            s_line_conv_state_del <= IDLE;
      else s_line_conv_state <= s_line_conv_next;
           s_line_conv_state_del <= s_line_conv_state;
      end if;
    end if;
  end process make_line_conv_state;

  make_pix_read_addr : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or
          s_line_conv_state = IDLE) then
        s_pix_read_addr <= (others => '0');
      elsif (s_line_conv_state /= IDLE) then
        s_pix_read_addr <= std_logic_vector(unsigned(s_pix_read_addr)+1);
      end if;
    end if;
  end process make_pix_read_addr;

  s_red   <= s_comp_px_data(7 downto 3);
  s_green <= s_comp_px_data(2 downto 0)&s_comp_px_data(7 downto 5);
--   s_green <= (OTHERS => '0');
  s_blue  <= s_comp_px_data(4 downto 0);

  make_pixel_1 : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_pixel_1 <= (others => '0');
      else
        if (s_line_conv_state_del = READ1) then
          s_pixel_1(7 downto 0)   <= s_red&"000";
          s_pixel_1(15 downto 13) <= s_green(5 downto 3);
        end if;
        if (s_line_conv_state_del = READ2) then
          s_pixel_1(12 downto 8)  <= s_green(2 downto 0)&"00";
          s_pixel_1(23 downto 16) <= s_blue&"000";
        end if;
      end if;
    end if;
  end process make_pixel_1;

  make_pixel_2 : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_pixel_2 <= (others => '0');
      else
        if (s_line_conv_state_del = READ3) then
          s_pixel_2(7 downto 0)   <= s_red&"000";
          s_pixel_2(15 downto 13) <= s_green(5 downto 3);
        end if;
        if (s_line_conv_state_del = READ4) then
          s_pixel_2(12 downto 8)  <= s_green(2 downto 0)&"00";
          s_pixel_2(23 downto 16) <= s_blue&"000";
        end if;
      end if;
    end if;
  end process make_pixel_2;

  make_pixel_3 : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_pixel_3 <= (others => '0');
      else
        if (s_line_conv_state_del = READ5) then
          s_pixel_3(7 downto 0)   <= s_red&"000";
          s_pixel_3(15 downto 13) <= s_green(5 downto 3);
        end if;
        if (s_line_conv_state_del = READ6) then
          s_pixel_3(12 downto 8)  <= s_green(2 downto 0)&"00";
          s_pixel_3(23 downto 16) <= s_blue&"000";
        end if;
      end if;
    end if;
  end process make_pixel_3;

  make_pixel_4 : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_pixel_4 <= (others => '0');
      else
        if (s_line_conv_state_del = READ7) then
          s_pixel_4(7 downto 0)   <= s_red&"000";
          s_pixel_4(15 downto 13) <= s_green(5 downto 3);
        end if;
        if (s_line_conv_state_del = READ8) then
          s_pixel_4(12 downto 8)  <= s_green(2 downto 0)&"00";
          s_pixel_4(23 downto 16) <= s_blue&"000";
        end if;
      end if;
    end if;
  end process make_pixel_4;

  make_write_word : process (clock)
  begin
    if (rising_edge(clock)) then
      if (s_line_conv_state_del = READ4 or
          s_line_conv_state_del = READ6 or
          s_line_conv_state_del = READ8) then
        s_write_word <= '1';
      else
        s_write_word <= '0';
      end if;
    end if;
  end process make_write_word;

  make_word_addr : process (clock)
  begin
    if (rising_edge(clock)) then
      if (s_line_conv_state_del = IDLE) then
        s_word_addr <= (others => '0');
      elsif (s_write_word = '1') then
        s_word_addr <= std_logic_vector(unsigned(s_word_addr)+1);
      end if;
    end if;
  end process make_word_addr;

  word_buffer : ram_sp_1k_32
    port map (clock => clock,
              we    => s_write_word,
              addr  => s_rw_addr,
              Din   => s_combined_data,
              Dout  => s_bus_data_next);

-- Here the master control is defined
  s_rw_addr <= s_word_addr when s_write_word = '1' else
               s_dma_addr;
  s_start_dma <= '1' when (s_camera_state = STORE_IMAGE or
                           s_camera_state = STORE_IMAGE_1 or
                           s_camera_state = STORE_IMAGE_2 or
                           s_camera_state = STORE_IMAGE_3 or
                           s_camera_state = STORE_IMAGE_4) and
                 s_line_conv_state_del = TRANSFER else '0';
  master_cs <= s_dma_we_reg;
  master_we <= s_dma_we_reg;

  make_dma_next : process (s_dma_state, s_start_dma,
                           master_wait_req, s_dma_addr)
  begin
    case (s_dma_state) is
      when NOACTION =>
        if (s_start_dma = '1') then
          s_dma_next <= WAITONE;
        else
          s_dma_next <= NOACTION;
        end if;
      when WAITONE => s_dma_next <= WRITE;
      when WRITE   => s_dma_next <= WAITWRITE;
      when WAITWRITE =>
        if (master_wait_req = '1') then
          s_dma_next <= WAITWRITE;
        elsif (unsigned(s_dma_addr) <
               to_unsigned(240, 8)) then
          s_dma_next <= WRITE;
        else
          s_dma_next <= NOACTION;
        end if;
      when others => s_dma_next <= NOACTION;
    end case;
  end process make_dma_next;

  make_dma_state : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_dma_state <= NOACTION;
      else s_dma_state                  <= s_dma_next;
      end if;
    end if;
  end process make_dma_state;

  make_dma_addr : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or s_start_dma = '1') then
        s_dma_addr <= (others => '0');
      elsif (s_dma_state = WRITE) then
        s_dma_addr <= std_logic_vector(unsigned(s_dma_addr)+1);
      end if;
    end if;
  end process make_dma_addr;

  s_load_bus_address <= '1' when s_camera_state = WAIT_NEW_IMAGE or
                        s_camera_state = INIT_1 or
                        s_camera_state = INIT_2 or
                        s_camera_state = INIT_3 or
                        s_camera_state = INIT_4 else '0';
  make_bus_load_address : process (s_camera_state, s_addr_1_reg,
                                   s_addr_2_reg, s_addr_3_reg, s_addr_4_reg)
  begin
    case (s_camera_state) is
      when INIT_2 => s_bus_load_address <= s_addr_2_reg(31 downto 2);
      when INIT_3 => s_bus_load_address <= s_addr_3_reg(31 downto 2);
      when INIT_4 => s_bus_load_address <= s_addr_4_reg(31 downto 2);
      when others => s_bus_load_address <= s_addr_1_reg(31 downto 2);
    end case;
  end process make_bus_load_address;

  make_master_address_data : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then master_address <= (others => '0');
                            master_write_data <= (others => '0');
      elsif (s_dma_state = WRITE) then
        master_address    <= s_bus_write_address&"00";
        master_write_data <= s_bus_data_next;
      end if;
    end if;
  end process make_master_address_data;

  make_bus_write_address : process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then s_bus_write_address <= (others => '0');
      elsif (s_load_bus_address = '1') then
        s_bus_write_address <= s_bus_load_address;
      elsif (s_dma_state = WRITE) then
        s_bus_write_address <= std_logic_vector(unsigned(s_bus_write_address)+1);
      end if;
    end if;
  end process make_bus_write_address;

  make_dma_we_reg : process (clock)
  begin
    if (rising_edge(clock)) then
      if ((s_dma_state = WRITE) or
          (s_dma_state = WAITWRITE and
           s_dma_we_reg = '1' and
           master_wait_req = '1')) then s_dma_we_reg <= '1';
      else s_dma_we_reg <= '0';
      end if;
    end if;
  end process make_dma_we_reg;

end architecture simple;


--------------------------------------------------------------------------------
--- New component                                                            ---
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchro_flop is
  port (clock_in  : in  std_logic;
        clock_out : in  std_logic;
        reset     : in  std_logic;
        tick_in   : in  std_logic;
        tick_out  : out std_logic);
end entity synchro_flop;

architecture behave of synchro_flop is

  signal s_delay_line : std_logic_vector(2 downto 0);

begin
  tick_out <= s_delay_line(2);

  del1 : process (clock_in, s_delay_line, tick_in,
                  reset)
  begin
    if (s_delay_line(2) = '1' or
        reset = '1') then s_delay_line(0) <= '0';
    elsif (rising_edge(clock_in)) then
      s_delay_line(0) <= s_delay_line(0) or tick_in;
    end if;
  end process del1;

  del2 : process (clock_out, s_delay_line, reset)
  begin
    if (s_delay_line(2) = '1' or
        reset = '1') then s_delay_line(1) <= '0';
    elsif (rising_edge(clock_out)) then
      s_delay_line(1) <= s_delay_line(0);
    end if;
  end process del2;

  del3 : process (clock_out, reset, s_delay_line)
  begin
    if (reset = '1') then s_delay_line(2) <= '0';
    elsif (rising_edge(clock_out)) then
      s_delay_line(2) <= s_delay_line(1);
    end if;
  end process del3;

end architecture behave;


--------------------------------------------------------------------------------
--- New component                                                            ---
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sp_1k_32 is
  port(clock : in  std_logic;
       we    : in  std_logic;
       addr  : in  std_logic_vector(7 downto 0);
       Din   : in  std_logic_vector(31 downto 0);
       Dout  : out std_logic_vector(31 downto 0));
end entity ram_sp_1k_32;

architecture fpga of ram_sp_1k_32 is

  type MEM_TYPE is array(255 downto 0) of std_logic_vector(31 downto 0);
  signal memory : MEM_TYPE;

begin

  make_mem : process (clock)
  begin
    if (rising_edge(clock)) then
      if (we = '1') then
        memory(to_integer(unsigned(addr))) <= Din;
      end if;
      Dout <= memory(to_integer(unsigned(addr)));
    end if;
  end process make_mem;

end architecture fpga;


--------------------------------------------------------------------------------
--- New component                                                            ---
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_dp_1k is
  port(clock_A : in  std_logic;
       we_A    : in  std_logic;
       addr_A  : in  std_logic_vector(9 downto 0);
       Din_A   : in  std_logic_vector(7 downto 0);
       Dout_A  : out std_logic_vector(7 downto 0);

       clock_B : in  std_logic;
       we_B    : in  std_logic;
       addr_B  : in  std_logic_vector(9 downto 0);
       Din_B   : in  std_logic_vector(7 downto 0);
       Dout_B  : out std_logic_vector(7 downto 0));
end entity ram_dp_1k;

architecture fpga of ram_dp_1k is

  type MEM_TYPE is array(1023 downto 0) of std_logic_vector(7 downto 0);
  signal memory : MEM_TYPE;

begin

  portA : process (clock_A)
  begin
    if (rising_edge(clock_A)) then
      if (we_A = '1') then
        memory(to_integer(unsigned(addr_A))) <= Din_A;
      end if;
      Dout_A <= memory(to_integer(unsigned(addr_A)));
    end if;
  end process portA;

  portB : process (clock_B)
  begin
    if (rising_edge(clock_B)) then
      if (we_B = '1') then
        memory(to_integer(unsigned(addr_B))) <= Din_B;
      end if;
      Dout_B <= memory(to_integer(unsigned(addr_B)));
    end if;
  end process portB;

end architecture fpga;
