library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

--Questions : 
--why do we need data and command registers if the data is simply put through to the 
--LCD interface.  

--The provided LCD controller (dummy for test bench) doesn't seem to act according to the 8080 standard 
--why is that. [It does. It is just not that evident to see.]

--The waitrequest signal could be used to inform the NIOS that the IP block is busy when the LCD 
--controller is reset or while the ip core is doing a transfer. 

--The IM0 and LCD_RESETn signals could be mapped to a register in order to be controlled as the other ones
--For this purpose, the timings must be respected. 

--The already implemented vhdl LCD controller is split into two part, a Bus specific Wrapper 
--and a core that communicates with the LCD controller. The wrapper would allow the system to 
--be ported to another bus system ex Xilinx (Wrapper). 

entity LCD_ctrl is
  port(
-- Avalon interfaces signals
    Clk_CI     	 	: in    std_logic;
    Reset_RLI   	: in    std_logic;
    Address_DI  	: in    std_logic_vector(1 downto 0);
	ChipSelect_CS	: in 	std_logic; 
	WaitRequest 	: out 	std_logic; 
    Write_SI     	: in    std_logic;
    WriteData_DI	: in    std_logic_vector(15 downto 0);
-- Parallel Port external interface
    LCD_RESETn  	: out  	std_logic;
	LCD_CSn  		: out  	std_logic;
	LCD_D_Cn  		: out  	std_logic;
	LCD_WRn  		: out  	std_logic;
	LCD_RDn  		: out  	std_logic;
	IM0  			: out  	std_logic;
	LCD_DATA		: out 	std_logic_vector(15 downto 0)); 
end entity LCD_ctrl;

architecture simpleLCDController of LCD_ctrl is 

	type state_type is (idle, write_low, write_high); 	--FSM to control the timings 
	signal state_reg, state_next, state_reg_last : state_type; 			--FSM state signals 	
	
	signal controlReg 	: std_logic_vector(7 downto 0); 
	signal timerWRH 	: unsigned(2 downto 0); 
	signal timerWRL 	: unsigned(2 downto 0); 
	signal timerWRHen 	: std_logic; 
	signal timerWRLen 	: std_logic; 
	--signal write_si_last : std_logic; 
	--signal write_ok 	: std_logic; 
begin

	CP_SR : process(Reset_RLI, Clk_CI)
	begin 
		if Reset_RLI = '1' then 
			-- Initialize outputs and internal signals  
			LCD_DATA <= (others => 'Z'); 
			LCD_D_Cn <= '0'; 
			LCD_RDn  <= '0'; 
			LCD_RESETn <= '0'; 
			IM0 <= '0'; 
			controlReg <= "00000000"; 
			
			timerWRH <= (others => '0'); 
			timerWRL <= (others => '0');  
			state_reg <= idle; 
			--write_ok <= '0'; 
			waitrequest <= '0'; 
			LCD_CSn <= '0'; 
			
		elsif rising_edge(Clk_CI) then 
			
			LCD_DATA <= WriteData_DI;
			state_reg 	<= state_next; 
			LCD_RESETn 	<= controlReg(0); 	-- The reset signal for the LCD is active low. 
			IM0 		<= controlReg(1); 
			--write_si_last <= Write_SI; 
			--write_ok <= write_si_last and Write_SI; 
			
			if Write_SI = '1' then
				-- Write cycle
				case Address_DI(1 downto 0) is
				  when "00" =>
					LCD_D_Cn <= '0'; 
					
				  when "01" =>
					LCD_D_Cn <= '1'; 
				  
				  when "10" =>
					controlReg <= WriteData_DI(7 downto 0); 
				  when others => null;
				end case;
			end if;	

			if timerWRHen = '1' then 
				timerWRH <= timerWRH + 1; 
			
			elsif timerWRLen = '1' then
				timerWRL <= timerWRL + 1; 
			end if; 
			
			if timerWRH = 2 then 
				timerWRH <= (others => '0'); 
			end if; 
			
			if timerWRL = 2 then 
				timerWRL <= (others => '0'); 
			end if; 		
		end if; 
	end process CP_SR;
	

	state_next <= 	idle when state_reg = write_high and timerWRH = 1 else
					write_low when state_reg = idle and Write_SI = '1'  else 
					write_high when state_reg = write_low and timerWRL = 1;  
	
	
	CP_OL : process (state_reg)
	begin 
		case state_reg is 
			when idle =>
				timerWRHen <= '0';
				LCD_WRn <= '1'; 
				
			when write_low =>
				timerWRLen <= '1'; 
				LCD_WRn <= '0'; 
			
			when write_high =>
				timerWRLen <= '0';  
				timerWRHen <= '1';  
				LCD_WRn <= '1'; 
		end case; 
	end process CP_OL;
	
	--The Data are directly put through, this block only drives the DCx CS and Write signals on the 
	--LCD side in order to switch from a synchronous to an asynchronous communication. 
	 
	 --WaitRequest <= '1'; 
	 
	
end architecture simpleLCDController; 


