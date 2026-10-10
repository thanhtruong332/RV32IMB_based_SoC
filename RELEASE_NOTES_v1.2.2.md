# v1.2.2

Documentation fix only. `docs/REPRODUCIBILITY.md` previously described the FPGA as "ZedBoard `xc7z020clg484-2`". The results in this repository were implemented on `xc7z020clg484-2`, while the ZedBoard carries the `-1` speed grade (`xc7z020clg484-1`); both are the same Zynq-7020 die and CLG484 package. The wording now states this explicitly, and the README notes that a board build must be re-implemented for `xc7z020clg484-1`.

No RTL, IP, constraint, firmware, script or measured result changed. Release references point to v1.2.2 and `reproducibility/SHA256SUMS.txt` was regenerated.
