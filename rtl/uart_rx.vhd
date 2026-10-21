library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity uart_rx is
    generic (
       	CLK_FREQ_HZ : integer := 50000000;
       	--BAUD_RATE   : integer := 9600
	BAUD_RATE   : integer := 1000000
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx_serial : in  std_logic;
        rx_done   : out std_logic;
        rx_byte   : out std_logic_vector(7 downto 0)
    );
end entity;
 
architecture rtl of uart_rx is
 
    constant CLKS_PER_BIT : integer := CLK_FREQ_HZ / BAUD_RATE;
 
    type state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_t := IDLE;
 
    signal clk_count : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_index : integer range 0 to 7 := 0;
 
    signal rx_shift : std_logic_vector(7 downto 0) := (others => '0');
 
    signal rx_meta : std_logic := '1';
    signal rx_sync : std_logic := '1';
 
begin
 
    process(clk, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift  <= (others => '0');
            rx_done   <= '0';
            rx_byte   <= (others => '0');
            rx_meta   <= '1';
            rx_sync   <= '1';
 
        elsif rising_edge(clk) then
 

            rx_meta <= rx_serial;
            rx_sync <= rx_meta;
 
            rx_done <= '0';
 
            case state is
 
                when IDLE =>
                    clk_count <= 0;
                    bit_index <= 0;
                    if rx_sync = '0' then
                        state <= START_BIT;
                    end if;
 
                when START_BIT =>
                    if clk_count = (CLKS_PER_BIT / 2) then
                        if rx_sync = '0' then
                            clk_count <= 0;
                            state <= DATA_BITS;
                        else
                            state <= IDLE;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
 
                when DATA_BITS =>
                    if clk_count = CLKS_PER_BIT - 1 then
                        clk_count <= 0;
                        rx_shift(bit_index) <= rx_sync;
 
                        if bit_index = 7 then
                            bit_index <= 0;
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
 
                when STOP_BIT =>
                    if clk_count = CLKS_PER_BIT - 1 then
                        clk_count <= 0;
                        rx_byte <= rx_shift;
                        rx_done <= '1';
                        state <= IDLE;
                    else
                        clk_count <= clk_count + 1;
                    end if;
 
            end case;
        end if;
    end process;
 
end architecture;
