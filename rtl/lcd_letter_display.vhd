library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity lcd_letter_display is
    generic (
        CLK_FREQ_HZ : integer := 50000000
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid      : in  std_logic;
        ascii_char : in  std_logic_vector(7 downto 0); 
        LCD_RS   : out std_logic;
        LCD_RW   : out std_logic;
        LCD_EN   : out std_logic;
        LCD_DATA : out std_logic_vector(7 downto 0)
    );

end entity;
 
architecture rtl of lcd_letter_display is
    type state_t is (
        POWER_WAIT,
        FUNC1_PULSE, FUNC1_WAIT,
        FUNC2_PULSE, FUNC2_WAIT,
        FUNC3_PULSE, FUNC3_WAIT,
        DISPLAY_ON_PULSE, DISPLAY_ON_WAIT,
        CLEAR_PULSE, CLEAR_WAIT,
        ENTRY_PULSE, ENTRY_WAIT,
        SET_ADDR_PULSE, SET_ADDR_WAIT,
        WRITE_CHAR_PULSE, WRITE_CHAR_WAIT,
        IDLE
    ); 
    signal state      : state_t := POWER_WAIT;
    signal counter    : integer range 0 to CLK_FREQ_HZ := 0;
    signal rs_reg     : std_logic := '0';
    signal en_reg     : std_logic := '0';
    signal data_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal letter_reg : std_logic_vector(7 downto 0) := x"3F";
    constant DELAY_20MS : integer := CLK_FREQ_HZ / 50;
    constant DELAY_5MS  : integer := CLK_FREQ_HZ / 200;
    constant DELAY_2MS  : integer := CLK_FREQ_HZ / 500;
    constant DELAY_50US : integer := CLK_FREQ_HZ / 20000;
    constant PULSE_1US  : integer := CLK_FREQ_HZ / 1000000; 
begin 
    LCD_RS   <= rs_reg;
    LCD_RW   <= '0';     
    LCD_EN   <= en_reg;
    LCD_DATA <= data_reg; 
    process(clk, rst)
    begin
        if rst = '1' then
            state      <= POWER_WAIT;
            counter    <= 0;
            rs_reg     <= '0';
            en_reg     <= '0';
            data_reg   <= (others => '0');
            letter_reg <= x"3F"; 
        elsif rising_edge(clk) then 
            if valid = '1' then
                letter_reg <= ascii_char;
            end if; 
            case state is 
                when POWER_WAIT =>
                    rs_reg   <= '0';
                    en_reg   <= '0';
                    data_reg <= x"00"; 
                    if counter < DELAY_20MS then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= FUNC1_PULSE;
                    end if; 
                when FUNC1_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"38";
                    en_reg   <= '1'; 
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= FUNC1_WAIT;
                    end if; 
                when FUNC1_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_5MS then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= FUNC2_PULSE;
                    end if; 
                when FUNC2_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"38";
                    en_reg   <= '1'; 
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= FUNC2_WAIT;
                    end if; 
                when FUNC2_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= FUNC3_PULSE;
                    end if; 
                when FUNC3_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"38";
                    en_reg   <= '1'; 
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= FUNC3_WAIT;
                    end if; 
                when FUNC3_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= DISPLAY_ON_PULSE;
                    end if;
                when DISPLAY_ON_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"0C";
                    en_reg   <= '1';
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= DISPLAY_ON_WAIT;
                    end if;
                when DISPLAY_ON_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= CLEAR_PULSE;
                    end if;
                when CLEAR_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"01";
                    en_reg   <= '1';
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= CLEAR_WAIT;
                    end if;
                when CLEAR_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_2MS then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= ENTRY_PULSE;
                    end if;
                when ENTRY_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"06";
                    en_reg   <= '1';
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= ENTRY_WAIT;
                    end if;
                when ENTRY_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= SET_ADDR_PULSE;
                    end if;
                when SET_ADDR_PULSE =>
                    rs_reg   <= '0';
                    data_reg <= x"80";
                    en_reg   <= '1';
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= SET_ADDR_WAIT;
                    end if;
                when SET_ADDR_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= WRITE_CHAR_PULSE;
                    end if;
                when WRITE_CHAR_PULSE =>
                    rs_reg   <= '1';      
                    data_reg <= letter_reg;
                    en_reg   <= '1';
                    if counter < PULSE_1US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        en_reg  <= '0';
                        state   <= WRITE_CHAR_WAIT;
                    end if;
                when WRITE_CHAR_WAIT =>
                    en_reg <= '0';
                    if counter < DELAY_50US then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state   <= IDLE;
                    end if;
                when IDLE =>
                    en_reg <= '0';
                    if valid = '1' then
                        counter <= 0;
                        state   <= SET_ADDR_PULSE;
                    end if;
            end case;
        end if;
    end process;
end architecture;
 
