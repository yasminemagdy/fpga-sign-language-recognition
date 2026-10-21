library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.svm_pkg.all;

entity svm_top is
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        start           : in  std_logic;
        x               : in  feature_vec_t;
        predicted_class : out unsigned(4 downto 0);
        done            : out std_logic
    );
end entity svm_top;

architecture rtl of svm_top is

    type state_t is (
        IDLE,
        INIT_CLASS,
        CALC_FEATURE,
        FINISH_CLASS,
        FINISH_ALL
    );

    signal state : state_t := IDLE;

    signal class_idx   : integer range 0 to NUM_CLASSES-1 := 0;
    signal feature_idx : integer range 0 to NUM_FEATURES-1 := 0;

    signal current_sum : acc_t := (others => '0');
    signal best_score  : acc_t := (others => '0');
    signal best_class  : unsigned(4 downto 0) := (others => '0');

begin

    process(clk, rst)
        variable product_v : signed((2 * DATA_W) - 1 downto 0);
        variable sum_v     : acc_t;
    begin
        if rst = '1' then
            state           <= IDLE;
            class_idx       <= 0;
            feature_idx     <= 0;
            current_sum     <= (others => '0');
            best_score      <= (others => '0');
            best_class      <= (others => '0');
            predicted_class <= (others => '0');
            done            <= '0';

        elsif rising_edge(clk) then
            done <= '0';

            case state is

                when IDLE =>
                    if start = '1' then
                        class_idx   <= 0;
                        feature_idx <= 0;
                        current_sum <= get_bias(0);
                        best_score  <= (others => '0');
                        best_class  <= (others => '0');
                        state       <= CALC_FEATURE;
                    end if;

                when INIT_CLASS =>
                    feature_idx <= 0;
                    current_sum <= get_bias(class_idx);
                    state       <= CALC_FEATURE;

                when CALC_FEATURE =>
                    product_v := x(feature_idx) * get_weight(class_idx, feature_idx);
                    sum_v := current_sum + resize(product_v, ACC_W);
                    current_sum <= sum_v;

                    if feature_idx = NUM_FEATURES - 1 then
                        state <= FINISH_CLASS;
                    else
                        feature_idx <= feature_idx + 1;
                    end if;

                when FINISH_CLASS =>
                    if class_idx = 0 then
                        best_score <= current_sum;
                        best_class <= to_unsigned(0, 5);
                    elsif current_sum > best_score then
                        best_score <= current_sum;
                        best_class <= to_unsigned(class_idx, 5);
                    end if;

                    if class_idx = NUM_CLASSES - 1 then
                        state <= FINISH_ALL;
                    else
                        class_idx <= class_idx + 1;
                        state     <= INIT_CLASS;
                    end if;

                when FINISH_ALL =>
                    predicted_class <= best_class;
                    done <= '1';
                    state <= IDLE;

            end case;
        end if;
    end process;

end architecture rtl;

