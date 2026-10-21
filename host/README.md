# Host software (PC side)

> **TODO – add your Python scripts here.** They are not part of the current repository.

Expected contents:

| File | Purpose |
|---|---|
| `hand_to_fpga.py` (name it as you like) | Captures webcam frames, extracts 21 MediaPipe 3D hand landmarks (63 values), converts them to fixed-point `int16`, builds the packet and sends it over the Bluetooth serial port |
| `requirements.txt` | e.g. `mediapipe`, `opencv-python`, `numpy`, `pyserial` |

The packet format is documented in [`../docs/PROTOCOL.md`](../docs/PROTOCOL.md).
Document here: the feature definition/normalization, the fixed-point scale, the serial port name, and the baud rate.
