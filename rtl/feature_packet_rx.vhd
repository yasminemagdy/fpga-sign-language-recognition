library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.svm_pkg.all;
 
entity feature_packet_rx is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
 
        rx_done      : in  std_logic;
        rx_byte      : in  std_logic_vector(7 downto 0);
 
        features_out : out feature_vec_t;
        packet_valid : out std_logic;

        status_led   : out std_logic_vector(4 downto 0)
    );
end entity;
 
architecture rtl of feature_packet_rx is
 
    constant TOTAL_DATA_BYTES : integer := NUM_FEATURES * 2; 
 
    type state_t is (
        WAIT_AA,
        WAIT_55,
        RX_DATA,
        RX_CHECKSUM
    );
 
    signal state : state_t := WAIT_AA;
 
    signal data_count   : integer range 0 to TOTAL_DATA_BYTES := 0;
    signal low_byte     : std_logic_vector(7 downto 0) := (others => '0');
    signal checksum_sum : unsigned(7 downto 0) := (others => '0');
 
    signal temp_features : feature_vec_t := (others => (others => '0'));
    signal status_reg    : std_logic_vector(4 downto 0) := (others => '0');
 
begin
 
    status_led <= status_reg;
 
    process(clk, rst)
        variable feature_index : integer range 0 to NUM_FEATURES - 1;
    begin
        if rst = '1' then
            state         <= WAIT_AA;
            data_count    <= 0;
            low_byte      <= (others => '0');
            checksum_sum  <= (others => '0');
            temp_features <= (others => (others => '0'));
            features_out  <= (others => (others => '0'));
            packet_valid  <= '0';
            status_reg    <= (others => '0');
 
        elsif rising_edge(clk) then
            packet_valid <= '0';
 
            if rx_done = '1' then
 
                case state is
                    when WAIT_AA =>
 
                        if rx_byte = x"AA" then
                            state        <= WAIT_55;
                            data_count   <= 0;
                            checksum_sum <= (others => '0');
                            status_reg   <= "00001";
                        else
                            state      <= WAIT_AA;
                            status_reg <= (others => '0');
                        end if;

                    when WAIT_55 =>
 
                        if rx_byte = x"55" then
                            state      <= RX_DATA;
                            data_count <= 0;
                            status_reg <= "00111"; 
                        elsif rx_byte = x"AA" then
                            state      <= WAIT_55;
                            status_reg <= "00001";
                        else
                            state      <= WAIT_AA;
                            status_reg <= (others => '0');
                        end if;
 
                    when RX_DATA =>
 
                        checksum_sum <= checksum_sum + unsigned(rx_byte);
                        status_reg(2) <= '1';
 
                        if (data_count mod 2) = 0 then
                            low_byte <= rx_byte;
 
                        else
                            feature_index := data_count / 2;
                            temp_features(feature_index) <= signed(rx_byte & low_byte);
                        end if;
 
                        if data_count = TOTAL_DATA_BYTES - 1 then
                            state      <= RX_CHECKSUM;
                            data_count <= 0;
                        else
                            data_count <= data_count + 1;
                        end if;

                    when RX_CHECKSUM =>
 
                        status_reg(2) <= '0';
                        status_reg(3) <= '1';
 
                        if rx_byte = std_logic_vector(checksum_sum) then
                            features_out  <= temp_features;
                            packet_valid  <= '1';
                            status_reg(4) <= '1'; 
                        else
                            status_reg(4) <= '0'; 
                        end if;
                        state <= WAIT_AA;
                end case;
            end if;
        end if;
    end process;
 
end architecture;
