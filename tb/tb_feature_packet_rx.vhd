library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.svm_pkg.all;

entity tb_feature_packet_rx is
end entity;

architecture sim of tb_feature_packet_rx is

    constant CLK_PERIOD : time := 20 ns;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal rx_done      : std_logic := '0';
    signal rx_byte      : std_logic_vector(7 downto 0) := (others => '0');
    signal features_out : feature_vec_t;
    signal packet_valid : std_logic;
    signal status_led   : std_logic_vector(4 downto 0);

    signal valid_seen   : std_logic := '0';

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

    procedure send_byte(
        signal done_s : out std_logic;
        signal byte_s : out std_logic_vector(7 downto 0);
        constant b    : in  std_logic_vector(7 downto 0)
    ) is
    begin
        wait until rising_edge(clk);
        byte_s <= b;
        done_s <= '1';

        wait until rising_edge(clk);
        done_s <= '0';
    end procedure;

begin

    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.feature_packet_rx
        port map (
            clk          => clk,
            rst          => rst,
            rx_done      => rx_done,
            rx_byte      => rx_byte,
            features_out => features_out,
            packet_valid => packet_valid,
            status_led   => status_led
        );
    valid_monitor : process(clk, rst)
    begin
        if rst = '1' then
            valid_seen <= '0';
        elsif rising_edge(clk) then
            if packet_valid = '1' then
                valid_seen <= '1';
            end if;
        end if;
    end process;

    stim : process
    begin
        rst <= '1';
        rx_done <= '0';
        rx_byte <= (others => '0');

        wait for 5 * CLK_PERIOD;

        rst <= '0';
        wait for 2 * CLK_PERIOD;


        for i in packet'range loop
            send_byte(rx_done, rx_byte, packet(i));
        end loop;

        wait until valid_seen = '1';
        stop;
        wait;
    end process;
end architecture;
