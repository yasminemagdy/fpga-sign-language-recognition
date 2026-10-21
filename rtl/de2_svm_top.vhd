library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.svm_pkg.all;
 
entity de2_svm_top is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(0 downto 0);
 
        HC05_RX  : in  std_logic;
 
        LEDR     : out std_logic_vector(4 downto 0);

        LCD_RS   : out std_logic;
        LCD_RW   : out std_logic;
        LCD_EN   : out std_logic;
        LCD_ON   : out std_logic;
        LCD_BLON : out std_logic;
        LCD_DATA : out std_logic_vector(7 downto 0)
    );
end entity;
 
architecture rtl of de2_svm_top is
 
    signal rst : std_logic;
 
    signal rx_done : std_logic;
    signal rx_byte : std_logic_vector(7 downto 0);
 
    signal rx_features  : feature_vec_t;
    signal packet_valid : std_logic;
    signal status_led   : std_logic_vector(4 downto 0);
 
    signal svm_features : feature_vec_t := (others => (others => '0'));
 
    signal svm_start : std_logic := '0';
    signal svm_busy  : std_logic := '0';
    signal svm_done  : std_logic;
 
    signal predicted_class : unsigned(4 downto 0);
 
    signal ascii_char : std_logic_vector(7 downto 0) := x"3F"; 
    signal lcd_valid  : std_logic := '0';
 
    function class_to_ascii(cls : unsigned(4 downto 0)) return std_logic_vector is
        variable idx : integer;
    begin
        idx := to_integer(cls);
 
        if idx >= 0 and idx <= 25 then
            return std_logic_vector(to_unsigned(65 + idx, 8)); 
        else
            return x"3F"; 
        end if;
    end function;
 
begin
 
    rst <= not KEY(0);
 
    uart_rx_inst : entity work.uart_rx
        generic map (
            CLK_FREQ_HZ => 50000000,
            --BAUD_RATE   => 9600
	    BAUD_RATE   => 1000000
        )
        port map (
            clk       => CLOCK_50,
            rst       => rst,
            rx_serial => HC05_RX,
            rx_done   => rx_done,
            rx_byte   => rx_byte
        );
 
    packet_rx_inst : entity work.feature_packet_rx
        port map (
            clk          => CLOCK_50,
            rst          => rst, 
            rx_done      => rx_done,
            rx_byte      => rx_byte, 
            features_out => rx_features,
            packet_valid => packet_valid, 
            status_led   => status_led
        );
 
    process(CLOCK_50, rst)
    begin
        if rst = '1' then
            svm_features <= (others => (others => '0'));
            svm_start    <= '0';
            svm_busy     <= '0';
 
        elsif rising_edge(CLOCK_50) then
 
            svm_start <= '0';
            if packet_valid = '1' and svm_busy = '0' then
                svm_features <= rx_features;
                svm_start    <= '1';
                svm_busy     <= '1';
 
            elsif svm_done = '1' then
                svm_busy <= '0';
            end if;
 
        end if;
    end process;

    svm_unit : entity work.svm_top
        port map (
            clk             => CLOCK_50,
            rst             => rst,
            start           => svm_start,
            x               => svm_features,
            predicted_class => predicted_class,
            done            => svm_done
        );
 
    process(CLOCK_50, rst)
    begin
        if rst = '1' then
            ascii_char <= x"3F";
            lcd_valid  <= '0';
 
        elsif rising_edge(CLOCK_50) then
            lcd_valid <= '0';
 
            if svm_done = '1' then
                ascii_char <= class_to_ascii(predicted_class);
                lcd_valid  <= '1';
            end if;
 
        end if;
    end process;
    lcd_unit : entity work.lcd_letter_display
        generic map (
            CLK_FREQ_HZ => 50000000
        )
        port map (
            clk        => CLOCK_50,
            rst        => rst,
            valid      => lcd_valid,
            ascii_char => ascii_char,
 
            LCD_RS     => LCD_RS,
            LCD_RW     => LCD_RW,
            LCD_EN     => LCD_EN,
            LCD_DATA   => LCD_DATA
        );
 
    LCD_ON   <= '1';
    LCD_BLON <= '1';

    LEDR <= status_led;
 
end architecture;
