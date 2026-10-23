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

    signal valid_count  : integer := 0;

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
            valid_count <= 0;
        elsif rising_edge(clk) then
            if packet_valid = '1' then
                valid_count <= valid_count + 1;
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


        -- Test 1: well-formed packet is accepted and decoded correctly
        for i in packet'range loop
            send_byte(rx_done, rx_byte, packet(i));
        end loop;
        wait for 5 * CLK_PERIOD;
        assert valid_count = 1
            report "valid packet was not accepted" severity failure;
        for f in 0 to NUM_FEATURES - 1 loop
            assert features_out(f) = signed(std_logic_vector'(packet(3 + 2*f) & packet(2 + 2*f)))
                report "feature " & integer'image(f) & " decoded incorrectly" severity failure;
        end loop;
        report "tb_feature_packet_rx: valid packet accepted, all 63 features decoded correctly" severity note;

        -- Test 2: same packet with a corrupted checksum is dropped
        for i in packet'low to packet'high - 1 loop
            send_byte(rx_done, rx_byte, packet(i));
        end loop;
        send_byte(rx_done, rx_byte, packet(packet'high) xor x"01");
        wait for 5 * CLK_PERIOD;
        assert valid_count = 1
            report "packet with bad checksum was NOT dropped" severity failure;
        report "tb_feature_packet_rx: bad-checksum packet dropped" severity note;

        -- Test 3: receiver recovers and accepts the next good packet
        for i in packet'range loop
            send_byte(rx_done, rx_byte, packet(i));
        end loop;
        wait for 5 * CLK_PERIOD;
        assert valid_count = 2
            report "receiver did not recover after a bad packet" severity failure;
        report "tb_feature_packet_rx: receiver recovered, next good packet accepted" severity note;
        stop;
        wait;
    end process;
end architecture;
