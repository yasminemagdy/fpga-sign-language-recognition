#!/usr/bin/env bash
# Compile and run all testbenches with GHDL (VHDL-2008).  Usage: ./sim/run_sim.sh
set -e
cd "$(dirname "$0")/.."
WORK=sim/work
mkdir -p "$WORK"
OPTS="--std=08 --workdir=$WORK"

ghdl -a $OPTS rtl/svm_pkg.vhd rtl/uart_rx.vhd rtl/feature_packet_rx.vhd \
              rtl/svm_top.vhd rtl/lcd_letter_display.vhd rtl/de2_svm_top.vhd tb/*.vhd

for tb in tb_uart_rx tb_feature_packet_rx tb_svm_top tb_de2_svm_top; do
  echo "=== Running $tb ==="
  ghdl -e $OPTS "$tb"
  ghdl -r $OPTS "$tb" --wave="$WORK/$tb.ghw"
done
echo "All testbenches finished. Waveforms: $WORK/*.ghw (open with GTKWave)."
