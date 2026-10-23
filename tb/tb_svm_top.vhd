library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use ieee.math_real.all;
use work.svm_pkg.all;

entity tb_svm_top is
end entity;

architecture sim of tb_svm_top is
    constant CLK_PERIOD : time := 20 ns;

    signal clk             : std_logic := '0';
    signal rst             : std_logic := '1';
    signal start           : std_logic := '0';
    signal x               : feature_vec_t := (others => (others => '0'));
    signal predicted_class : unsigned(4 downto 0);
    signal done            : std_logic;

    function expected_class(features : feature_vec_t) return unsigned is
        variable score      : acc_t;
        variable best_score : acc_t := (others => '0');
        variable best_cls   : integer := 0;
        variable product_v  : signed((2 * DATA_W) - 1 downto 0);
    begin
        for c in 0 to NUM_CLASSES - 1 loop
            score := get_bias(c);
            for i in 0 to NUM_FEATURES - 1 loop
                product_v := features(i) * get_weight(c, i);
                score := score + resize(product_v, ACC_W);
            end loop;

            if c = 0 then
                best_score := score;
                best_cls := 0;
            elsif score > best_score then
                best_score := score;
                best_cls := c;
            end if;
        end loop;

        return to_unsigned(best_cls, 5);
    end function;

begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.svm_top
        port map (
            clk             => clk,
            rst             => rst,
            start           => start,
            x               => x,
            predicted_class => predicted_class,
            done            => done
        );

    stim : process
        constant NUM_RANDOM : integer := 25;
        variable seed1    : positive := 7;
        variable seed2    : positive := 13;
        variable r        : real;
        variable pass_cnt : integer := 0;

        procedure run_case(id : integer; vec : feature_vec_t; variable passed : inout integer) is
            variable exp_cls : unsigned(4 downto 0);
            variable cycles  : integer := 0;
        begin
            exp_cls := expected_class(vec);
            wait until rising_edge(clk);
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            cycles := 1;
            while done /= '1' loop
                wait until rising_edge(clk);
                cycles := cycles + 1;
            end loop;
            if predicted_class = exp_cls then
                passed := passed + 1;
            end if;
            assert predicted_class = exp_cls
                report "case " & integer'image(id) & ": expected class " &
                       integer'image(to_integer(exp_cls)) & ", got " &
                       integer'image(to_integer(predicted_class))
                severity error;
            if id = 1 then
                report "latency: " & integer'image(cycles) & " clock cycles from start to done" severity note;
            end if;
        end procedure;
    begin
        rst <= '1';
        wait for 5 * CLK_PERIOD;
        rst <= '0';
        wait for 2 * CLK_PERIOD;
        x(0) <= to_signed(222, DATA_W);
        x(1) <= to_signed(29, DATA_W);
        x(2) <= to_signed(-127, DATA_W);
        x(3) <= to_signed(92, DATA_W);
        x(4) <= to_signed(-33, DATA_W);
        x(5) <= to_signed(406, DATA_W);
        x(6) <= to_signed(-62, DATA_W);
        x(7) <= to_signed(33, DATA_W);
        x(8) <= to_signed(345, DATA_W);
        x(9) <= to_signed(-103, DATA_W);
        x(10) <= to_signed(150, DATA_W);
        x(11) <= to_signed(327, DATA_W);
        x(12) <= to_signed(-83, DATA_W);
        x(13) <= to_signed(224, DATA_W);
        x(14) <= to_signed(291, DATA_W);
        x(15) <= to_signed(15, DATA_W);
        x(16) <= to_signed(170, DATA_W);
        x(17) <= to_signed(67, DATA_W);
        x(18) <= to_signed(-96, DATA_W);
        x(19) <= to_signed(287, DATA_W);
        x(20) <= to_signed(161, DATA_W);
        x(21) <= to_signed(-148, DATA_W);
        x(22) <= to_signed(285, DATA_W);
        x(23) <= to_signed(212, DATA_W);
        x(24) <= to_signed(-176, DATA_W);
        x(25) <= to_signed(249, DATA_W);
        x(26) <= to_signed(233, DATA_W);
        x(27) <= to_signed(100, DATA_W);
        x(28) <= to_signed(243, DATA_W);
        x(29) <= to_signed(31, DATA_W);
        x(30) <= to_signed(-16, DATA_W);
        x(31) <= to_signed(346, DATA_W);
        x(32) <= to_signed(168, DATA_W);
        x(33) <= to_signed(-99, DATA_W);
        x(34) <= to_signed(254, DATA_W);
        x(35) <= to_signed(225, DATA_W);
        x(36) <= to_signed(-156, DATA_W);
        x(37) <= to_signed(186, DATA_W);
        x(38) <= to_signed(228, DATA_W);
        x(39) <= to_signed(168, DATA_W);
        x(40) <= to_signed(290, DATA_W);
        x(41) <= to_signed(40, DATA_W);
        x(42) <= to_signed(99, DATA_W);
        x(43) <= to_signed(363, DATA_W);
        x(44) <= to_signed(258, DATA_W);
        x(45) <= to_signed(92, DATA_W);
        x(46) <= to_signed(272, DATA_W);
        x(47) <= to_signed(342, DATA_W);
        x(48) <= to_signed(91, DATA_W);
        x(49) <= to_signed(202, DATA_W);
        x(50) <= to_signed(341, DATA_W);
        x(51) <= to_signed(221, DATA_W);
        x(52) <= to_signed(308, DATA_W);
        x(53) <= to_signed(68, DATA_W);
        x(54) <= to_signed(170, DATA_W);
        x(55) <= to_signed(342, DATA_W);
        x(56) <= to_signed(243, DATA_W);
        x(57) <= to_signed(164, DATA_W);
        x(58) <= to_signed(292, DATA_W);
        x(59) <= to_signed(317, DATA_W);
        x(60) <= to_signed(168, DATA_W);
        x(61) <= to_signed(243, DATA_W);
        x(62) <= to_signed(334, DATA_W);
        wait for CLK_PERIOD;

        -- Test 1: fixed vector (real feature sample)
        run_case(1, x, pass_cnt);

        -- Tests 2..NUM_RANDOM+1: pseudo-random feature vectors in [-512, 511]
        for t in 2 to NUM_RANDOM + 1 loop
            for i in 0 to NUM_FEATURES - 1 loop
                uniform(seed1, seed2, r);
                x(i) <= to_signed(integer(floor(r * 1024.0)) - 512, DATA_W);
            end loop;
            wait for CLK_PERIOD;
            run_case(t, x, pass_cnt);
        end loop;

        report "tb_svm_top: " & integer'image(pass_cnt) & "/" &
               integer'image(NUM_RANDOM + 1) & " cases matched the reference model" severity note;
        assert pass_cnt = NUM_RANDOM + 1 report "tb_svm_top: FAILURES DETECTED" severity failure;
	stop;
	wait;
    end process;
end architecture;

