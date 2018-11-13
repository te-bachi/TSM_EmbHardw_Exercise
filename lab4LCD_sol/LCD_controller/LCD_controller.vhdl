LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity LcdController IS
   port (  -- Here the internal interface is defined
          Clock                 : IN  std_logic;
          Reset                 : IN  std_logic;
          ResetDisplay          : IN  std_logic;
          StartSendReceive      : IN  std_logic;
          CommandBarData        : IN  std_logic;
          EightBitSixteenBitBar : IN  std_logic;
          WriteReadBar          : IN  std_logic;
          DataToSend            : IN  std_logic_vector(15 DOWNTO 0);
          DataReceived          : OUT std_logic_vector(15 DOWNTO 0);
          busy                  : OUT std_logic;

          -- Here the external LCD-panel signals are defined
          ChipSelectBar  : OUT   std_logic;
          DataCommandBar : OUT   std_logic;
          WriteBar       : OUT   std_logic;
          ReadBar        : OUT   std_logic;
          ResetBar       : OUT   std_logic;
          IM0            : OUT   std_logic;
          DataBus        : INOUT std_logic_vector(15 DOWNTO 0));
end entity LcdController;

architecture Controller of LcdController is

    TYPE STATETYPES IS (ActivateReset, WaitReset, ActivateRecover, WaitRecover, Idle, ClockDataOut, WaitWriteLow, WaitWriteHigh, InitRead, WaitReadLow, WaitReadHigh);
    
    
    SIGNAL current_state, next_state        : STATETYPES := Idle;
    
    -- Counter signals
    SIGNAL counter_value                    : unsigned(23 downto 0);
    SIGNAL counter_zero                     : std_logic;
    
    SIGNAL reset_display_requested          : std_logic;
    
    SIGNAL DataCommandBar_s                 : std_logic;
    SIGNAL IM0_s                            : std_logic;
    SIGNAL DataReceived_s                   : STD_LOGIC_VECTOR(15 downto 0);
    SIGNAL DataBus_s                        : STD_LOGIC_VECTOR(15 downto 0);

begin
    -- Internal signals
    counter_zero <= '1' when counter_value = 0 else
                    '0';
    
    -- Next State Logic
    -- Cycle-Counter to stay the defined time in a state
    countDown : process(Clock)
    begin
        if(rising_edge(Clock)) then
            if (current_state = ActivateReset) then
                counter_value <= to_unsigned(1200-1, 24);
            elsif(current_state = ActivateRecover) then
                counter_value <= to_unsigned(12000000-1, 24);
            elsif(current_state = InitRead) then
                counter_value <= to_unsigned(18-1, 24);
            elsif(current_state = WaitReadLow and counter_zero = '1') then
                counter_value <= to_unsigned(5-1, 24);
            elsif(current_state = ClockDataOut) then
                counter_value <= to_unsigned(2-1, 24);
            elsif(counter_zero = '1') then
                counter_value <= counter_value;
            else
                counter_value <= counter_value-1; 
            end if;
        end if;
    end process countDown;
    
    Workarround: process(Clock) 
    begin
        if rising_edge(Clock) then
            if(ResetDisplay = '1') then
                reset_display_requested <= '1';
            elsif(current_state = WaitReset) then
                reset_display_requested <= '0';
            else
                reset_display_requested <= reset_display_requested;
            end if;
			--        reset_display_requested <= '1' when ResetDisplay = '1' else
			--                                   '0' when current_state = WaitReset else
			--                                   reset_display_requested;
        end if;
    end process;

    -- State machine
    nextState: process(Clock) 
    begin
        if(rising_edge(Clock))then
            if( Reset = '1' ) then
                current_state <= ActivateReset;
            else
                case current_state IS
                    when ActivateReset =>
                        current_state <= WaitReset;
                    when WaitReset => 
                        if counter_zero = '1' then
                            current_state <= ActivateRecover;
                        end if;
                    when ActivateRecover =>
                        current_state <= WaitRecover;
                    when WaitRecover => 
                        if counter_zero = '1' then
                            current_state <= Idle;
                        end if;
                    when IDLE =>
                        if reset_display_requested = '1' then
                            current_state <= ActivateReset;
                        elsif(StartSendReceive = '1') then
                            if(WriteReadBar = '1') then
                                current_state <= ClockDataOut;
                            else  
                                current_state <= InitRead;
                            end if;
                        end if;
                    when ClockDataOut =>
                        current_state <= WaitWriteLow;
                    when WaitWriteLow =>
                        if counter_zero = '1' then
                            current_state <= WaitWriteHigh;
                        end if;
                    when WaitWriteHigh =>
                        current_state <= Idle;
                    when InitRead =>
                        current_state <= WaitReadLow;
                    when WaitReadLow =>
                        if counter_zero = '1' then
                            current_state <= WaitReadHigh;
                        end if;
                    when WaitReadHigh =>
                        if counter_zero = '1' then
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= ActivateReset;
                end case;
            end if;
        end if;
    end process nextState; 
    
    data_path : process(Clock)
    begin
		if falling_edge(Clock) then
			DataBus_s <= DataBus_s;
			DataCommandBar_s <= DataCommandBar_s;
			case current_state is
				when ActivateReset =>
					DataCommandBar_s <= '0';   
					IM0_s <= '0';   
					DataReceived_s <= (others => '0');        
				when WaitReset => 

				when ActivateRecover =>

				when WaitRecover => 

				when IDLE =>

					DataBus_s <= (others => 'Z');
				when ClockDataOut =>
					if EightBitSixteenBitBar = '1' then
						DataBus_s <= DataToSend(7 DOWNTO 0)&X"00";
					else
						DataBus_s <= DataToSend;
					end if;
					DataCommandBar_s <= CommandBarData;
					IM0_s <= EightBitSixteenBitBar;
				when WaitWriteLow =>

				
				when WaitWriteHigh =>

				when InitRead =>
					DataBus_s <= (others => 'Z');			
				when WaitReadLow =>
					DataBus_s <= (others => 'Z');
					if(counter_zero = '1') then                          
						if EightBitSixteenBitBar = '1' then
							DataReceived_s <= X"00"&DataBus(15 DOWNTO 8);
						else
							DataReceived_s <= DataBus;
						end if;
					end if; 
				when WaitReadHigh =>
					DataBus_s <= (others => 'Z');
			end case; 
		end if;
    end process data_path;
    
    -- Output Logic

    busy <= '0' when current_state = Idle else '1';

    ChipSelectBar <= '1' when current_state = ActivateReset or
                              current_state = WaitReset or
                              current_state = ActivateRecover or
                              current_state = WaitRecover
                else '0';

    DataCommandBar <= DataCommandBar_s;

    WriteBar <= '0' when current_state = WaitWriteLow
           else '1'; 

    ReadBar <= '0' when current_state = WaitReadLow
          else '1'; 

    ResetBar <= '0' when current_state = WaitReset
           else '1'; 

    IM0 <= IM0_s; 

    DataBus <= DataBus_s;

    DataReceived <= DataReceived_s;

end architecture Controller;














