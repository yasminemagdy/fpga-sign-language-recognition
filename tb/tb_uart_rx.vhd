library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_uart_rx is
end entity;

architecture sim of tb_uart_rx is

    constant CLK_PERIOD : time := 20 ns;

    constant BIT_PERIOD : time := 1000 ns;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal rx_serial : std_logic := '1';
    signal rx_done   : std_logic;
    signal rx_byte   : std_logic_vector(7 downto 0);

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
    end procedure;

begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.uart_rx
        generic map (
            CLK_FREQ_HZ => 50000000,
	    --BAUD_RATE   : integer := 9600
            BAUD_RATE   => 1000000
        )
        port map (
            clk       => clk,
            rst       => rst,
            rx_serial => rx_serial,
            rx_done   => rx_done,
            rx_byte   => rx_byte
        );

    stim : process
    begin
        rst <= '1';
        rx_serial <= '1';
        wait for 5 * CLK_PERIOD;

        rst <= '0';
        wait for 5 * CLK_PERIOD;

        uart_send_byte(rx_serial, x"A5");
        wait until rising_edge(clk) and rx_done = '1';
	stop;        
	wait;
    end process;

end architecture;
