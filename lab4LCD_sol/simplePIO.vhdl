library ieee;
use ieee.std_logic_1164.all;

entity simplePIO is
  port(
-- Avalon interfaces signals
    clk					: in    std_logic;
    reset_n	    		: in    std_logic;
    av_address	 		: in    std_logic_vector(2 downto 0);
    av_read     		: in    std_logic;
    av_readdata			: out   std_logic_vector(7 downto 0);
    av_write			: in    std_logic;
    av_writedata		: in    std_logic_vector(7 downto 0);
-- Parallel Port external interface
    conduit_data		: inout std_logic_vector(7 downto 0);
	irq					: out 	std_logic);
end entity simplePIO;



architecture NoWait of simplePIO is
  signal reg_dir		: std_logic_vector (7 downto 0);
  signal reg_port		: std_logic_vector (7 downto 0);
  signal reg_pin		: std_logic_vector (7 downto 0);
  signal reg_pin_last	: std_logic_vector (7 downto 0);
  signal irq_enabled	: std_logic;
  signal irq_pending	: std_logic;
begin  -- architecture NoWait

  pRegWr : process(clk, reset_n)
  begin
    if reset_n = '0' then
      -- Input by default
      reg_dir <= (others => '0');
      reg_port <= (others => '0');
	  reg_pin_last <= (others => '0');
	  irq_enabled <= '0';
	  irq_pending <= '0';
    elsif rising_edge(clk) then
      if av_write = '1' then
        -- Write cycle
        case av_address(2 downto 0) is
          when "000" =>
            reg_dir <= av_writedata;
          when "010" =>
            reg_port <= av_writedata;
          when "011" =>
            reg_port <= reg_port or av_writedata;
          when "100" =>
            reg_port <= reg_port and not av_writedata;
		  when "101" =>
		    if(av_writedata(0)= '1') then
			  irq_pending <= '0';
			end if;
			irq_enabled <= av_writedata(1);
          when others => null;
        end case;
      end if;
	  
	  -- Edge detection on the Input-Signals
	  if(reg_pin_last /= reg_pin) then
        irq_pending <= '1';
	  end if;
	  -- Update Pin value for edge detection
	  reg_pin_last <= reg_pin;
    end if;
  end process pRegWr;

  -- Read from registers with wait 0
  with av_address select
    av_readdata <=
    reg_dir        when "000",
    reg_pin        when "001",
    reg_port       when "010",
    (others => '0') when others;

  -- Parallel port output value
  pPort : process(reg_dir, reg_port)
  begin
    for idx in 0 to 7 loop
      if reg_dir(idx) = '1' then
        conduit_data(idx) <= reg_port(idx);
      else
        conduit_data(idx) <= 'Z';
      end if;
    end loop;
  end process pPort;

  -- Parallel port input value
  reg_pin <= conduit_data;
  irq <= irq_pending and irq_enabled;

end architecture NoWait;
