# ModelSim / Questa:  vsim -do sim/run_sim.do   (run from the repository root)
vlib work
vmap work work
vcom -2008 rtl/svm_pkg.vhd rtl/uart_rx.vhd rtl/feature_packet_rx.vhd \
           rtl/svm_top.vhd rtl/lcd_letter_display.vhd rtl/de2_svm_top.vhd
vcom -2008 tb/tb_uart_rx.vhd tb/tb_feature_packet_rx.vhd tb/tb_svm_top.vhd tb/tb_de2_svm_top.vhd
vsim -voptargs=+acc work.tb_de2_svm_top     ;# swap for tb_svm_top, tb_uart_rx, tb_feature_packet_rx
add wave -r /*
run -all
