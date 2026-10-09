# Reproducibility metadata

| Item | Value |
| --- | --- |
| RTL origin | Custom RTL snapshot supplied by the project owner |
| Repository | https://github.com/thanhtruong332/RV32IMB_based_SoC |
| Release | `v1.2.0` (use `git rev-parse v1.2.0^{commit}` for the immutable commit) |
| License | No open-source license is declared; see `LICENSE_STATUS.md` |
| ISA | RV32I 2.1 with integrated M operations and a B subset |
| Pipeline | Five stages: IF, ID, EX, MEM and WB |
| Branch resolution | EX stage; a taken branch or jump flushes the two younger slots |
| Forwarding | EX/MEM and MEM/WB forwarding paths |
| Hazard detection | Load-use detector stalls the dependent instruction |
| Multiplier/divider | MUL, MULH, MULHSU, MULHU and iterative DIV, DIVU, REM, REMU |
| Bit manipulation | CLZ, CTZ and CPOP subset |
| Register file | 32 x 32-bit; synchronous write and asynchronous read, with same-cycle write bypass |
| Hardware memory interface | AXI4-Lite master connected to instruction/data BRAM and the AES peripheral |
| FPGA and clock | ZedBoard `xc7z020clg484-2`; 40 MHz experiment clock |
| Vivado version | 2024.2 |

The repository contains the packaged RV32IMB and AES IP sources, block-design
configuration, constraints and the firmware image required to reconstruct the
project. Generated runs, caches, checkpoints and bitstreams are deliberately
excluded.

## Curated evidence package

The [`reproducibility/`](../reproducibility/) directory contains the measured artifacts, tool metadata and SHA-256 inventory associated with this release. Run `python reproducibility/verify_sha256.py` from any directory to verify it.
