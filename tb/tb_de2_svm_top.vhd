library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.svm_pkg.all;

entity tb_de2_svm_top is
end entity;

architecture sim of tb_de2_svm_top is

    constant CLK_PERIOD    : time := 20 ns;     
    constant CLKS_PER_BIT  : integer := 50000000 / 1000000;
    constant BIT_PERIOD    : time := CLK_PERIOD * CLKS_PER_BIT;

    signal CLOCK_50 : std_logic := '0';
    signal KEY      : std_logic_vector(0 downto 0) := "0";
    signal HC05_RX  : std_logic := '1';

    signal LEDR     : std_logic_vector(4 downto 0);
    signal LCD_RS   : std_logic;
    signal LCD_RW   : std_logic;
    signal LCD_EN   : std_logic;
    signal LCD_ON   : std_logic;
    signal LCD_BLON : std_logic;
    signal LCD_DATA : std_logic_vector(7 downto 0);

    type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);

    constant packet : byte_array_t := (
        x"AA", x"55",
        x"DE", x"00", x"1D", x"00", x"81", x"FF", x"5C", x"00",
        x"DF", x"FF", x"96", x"01", x"C2", x"FF", x"21", x"00",
        x"59", x"01", x"99", x"FF", x"96", x"00", x"47", x"01",
        x"AD", x"FF", x"E0", x"00", x"23", x"01", x"0F", x"00",
        x"AA", x"00", x"43", x"00", x"A0", x"FF", x"1F", x"01",
        x"A1", x"00", x"6C", x"FF", x"1D", x"01", x"D4", x"00",
        x"50", x"FF", x"F9", x"00", x"E9", x"00", x"64", x"00",
        x"F3", x"00", x"1F", x"00", x"F0", x"FF", x"5A", x"01",
        x"A8", x"00", x"9D", x"FF", x"FE", x"00", x"E1", x"00",
        x"64", x"FF", x"BA", x"00", x"E4", x"00", x"A8", x"00",
        x"22", x"01", x"28", x"00", x"63", x"00", x"6B", x"01",
        x"02", x"01", x"5C", x"00", x"10", x"01", x"56", x"01",
        x"5B", x"00", x"CA", x"00", x"55", x"01", x"DD", x"00",
        x"34", x"01", x"44", x"00", x"AA", x"00", x"56", x"01",
        x"F3", x"00", x"A4", x"00", x"24", x"01", x"3D", x"01",
        x"A8", x"00", x"F3", x"00", x"4E", x"01",
        x"BB"
    );

    procedure uart_send_byte(
        signal rx_line : out std_logic;
        constant data  : in  std_logic_vector(7 downto 0)
    ) is
    begin
        rx_line <= '1';
        wait for BIT_PERIOD;

        rx_line <= '0';
        wait for BIT_PERIOD;

        for i in 0 to 7 loop
            rx_line <= data(i);
            wait for BIT_PERIOD;
        end loop;

        rx_line <= '1';
        wait for BIT_PERIOD;
    end procedure;

begin

    CLOCK_50 <= not CLOCK_50 after CLK_PERIOD / 2;

    dut : entity work.de2_svm_top
        port map (
            CLOCK_50 => CLOCK_50,
            KEY      => KEY,
            HC05_RX  => HC05_RX,
            LEDR     => LEDR,
            LCD_RS   => LCD_RS,
            LCD_RW   => LCD_RW,
            LCD_EN   => LCD_EN,
            LCD_ON   => LCD_ON,
            LCD_BLON => LCD_BLON,
            LCD_DATA => LCD_DATA
        );

    stim : process
    begin
        KEY(0) <= '0';
        HC05_RX <= '1';
        wait for 1 us;
        KEY(0) <= '1';
        wait for 50 ms;
        for i in packet'range loop
            uart_send_byte(HC05_RX, packet(i));
        end loop;


        wait for 30 ms;
        stop;
        wait;
    end process;
end architecture;
