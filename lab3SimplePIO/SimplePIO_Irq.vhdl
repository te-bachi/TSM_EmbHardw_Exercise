
library ieee;
use ieee.std_logic_1164.all;

entity SimplePIO_Irq is
    port (
        -- Avalon interface signals
        Clk_CI          : in        std_logic;
        Reset_RLI       : in        std_logic;
        Address_DI      : in        std_logic_vector (2 downto 0);  -- Address space = 8
        Read_SI         : in        std_logic;                      -- Output Enable
        ReadData_DO     : out       std_logic_vector (7 downto 0);  -- Output
        Write_SI        : in        std_logic;                      -- Input Enable
        WriteData_DI    : in        std_logic_vector (7 downto 0);  -- Input
        Irq             : out       std_logic;                      -- Interrupt
        -- Parallel Port external interface
        ParPort_DIO     : inout     std_logic_vector (7 downto 0)
    );
end entity;

architecture RTL of SimplePIO_Irq is
    subtype     Address_T   is std_logic_vector (2 downto 0);
    constant    RegDir      : Address_T := "000";
    constant    RegPin      : Address_T := "001";
    constant    RegPort     : Address_T := "010";
    constant    RegSet      : Address_T := "011";
    constant    RegClr      : Address_T := "100";

    signal      RegDir_D    : std_logic_vector (7 downto 0);            -- Direction: 0=input, 1=output
    signal      RegPort_D   : std_logic_vector (7 downto 0);            -- Output register
    signal      RegPin_D    : std_logic_vector (7 downto 0);            -- Input register
begin

    -- Write Process to Register
    pRegWr : process(Clk_CI, Reset_RLI)
    begin
        if Reset_RLI = '0' then
            RegDir_D <= (others => '0');
            RegPort_D <= (others => '0');

        elsif rising_edge(Clk_CI) then
            if Write_SI = '1' then
                case Address_DI(2 downto 0) is
                    when RegDir     => RegDir_D  <= WriteData_DI;
                    when RegPort    => RegPort_D <= WriteData_DI;
                    when RegSet     => RegPort_D <= RegPort_D or WriteData_DI;
                    when RegClr     => RegPort_D <= RegPort_D and not WriteData_DI;
                    when others     => null;
                end case;
            end if;
        end if;
    end process;

    -- Combinatory (MUX) with wait 0
    --ReadData_DO <= RegDir_D     when Address_DI = "000"   else
    --               RegPin_D     when Address_DI = "001"   else
    --               RegPort_D    when Address_DI = "010"   else
    --               (others => '0');

    -- Read Process from Register with wait 1
    pRegRd : process(Clk_CI)
    begin
        if rising_edge(Clk_CI) then
            ReadData_DO <= (others => '0'); -- default
            if Read_SI = '1' then
                case Address_DI(2 downto 0) is
                    when RegDir     => ReadData_DO <= RegDir_D;
                    when RegPin     => ReadData_DO <= RegPin_D;
                    when RegPort    => ReadData_DO <= RegPort_D;
                    when others     => null;
                end case;
            end if;
        end if;
    end process;

    -- Parallel Port output value
    pPort : process(RegDir_D, RegPort_D)
    begin
        for idx in 0 to 7 loop
            if RegDir_D(idx) = '1' then
                ParPort_DIO(idx) <= RegPort_D(idx);
            else
                ParPort_DIO(idx) <= 'Z';
            end if;
        end loop;
    end process;

    -- Parallel Port input value
    RegPin_D <= ParPort_DIO;

    -- Interrupt Process
    pIrq : process(RegPin_D)
    begin
        if rising_edge(Clk_CI) then
            Irq <= '1';
        end if;
    end process;

end architecture;
