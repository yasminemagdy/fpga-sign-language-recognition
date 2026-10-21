# Model training

> **TODO – add your training notebook/script here.**

Document:
- the dataset used (source, number of samples per letter)
- the 63-feature definition and preprocessing
- the model (a 26-class **linear SVM**, one weight vector + bias per letter, as used by `svm_top.vhd`)
- the float → 16-bit fixed-point quantization step
- how the weights are exported into `rtl/svm_pkg.vhd`
- the software accuracy vs. the FPGA accuracy
