# Host → FPGA Packet Protocol

Derived from `rtl/uart_rx.vhd` and `rtl/feature_packet_rx.vhd`.

## UART
| Parameter | Value |
|---|---|
| Format | 8 data bits, no parity, 1 stop bit (8N1), LSB first |
| Baud rate | **1,000,000** (`BAUD_RATE` generic in `uart_rx.vhd`; a 9,600 option is commented out in the source) |
| FPGA clock | 50 MHz → 50 clocks per bit |
| Input | `HC05_RX` (Bluetooth module TX → FPGA), double-flop synchronized |

> The Bluetooth module (HC-05) must be configured to the same baud rate as the FPGA.

## Packet (129 bytes)

| Bytes | Content |
|---|---|
| 0 | `0xAA` (sync 1) |
| 1 | `0x55` (sync 2) |
| 2 … 127 | 63 features × 2 bytes, **signed 16-bit, little-endian** (low byte first) |
| 128 | Checksum = (sum of the 126 data bytes) mod 256 |

- Feature order: index 0 … 62 maps to `x(0) … x(62)` in `svm_pkg.vhd`.
- A packet with a bad checksum is discarded (no classification).
- A packet takes ≈ 1.29 ms on the wire at 1 Mbaud (129 bytes × 10 bits).

## Receiver FSM (`feature_packet_rx`)
`WAIT_AA → WAIT_55 → RX_DATA (126 bytes) → RX_CHECKSUM → WAIT_AA`

## Status LEDs (`LEDR[4:0]`)
Debug indicators driven by the packet receiver: header bytes seen (bits 0–1), receiving data (bit 2), checksum byte received (bit 3), checksum valid (bit 4).

## Fixed-point format
Features are 16-bit signed integers (`DATA_W = 16`). **Scaling:** each raw landmark coordinate is standardised with the training-set `StandardScaler`, multiplied by **256** and rounded to `int16`. SVM weights use the same ×256 scale (`int16`), and biases are scaled by 256 × 256 so they line up with the products inside the MAC accumulator.
The host script and the model-weight export must use the same scaling.
