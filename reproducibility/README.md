# Reproducibility evidence — RV32IMB_based_SoC

This directory is the compact reviewer-facing evidence package for release `v1.2.0`.
The Git commit is the commit referenced by the annotated release tag; resolve it with
`git rev-parse v1.2.0^{commit}`.

| Requested item | Location / status |
| --- | --- |
| RTL commit hash | Annotated tag `v1.2.0` |
| Firmware hash | `SHA256SUMS.txt` covers `firmware/images/` and `firmware/source/` |
| Vivado version | `metadata.json`; confirmed by the report headers |
| Tcl scripts | `scripts/` plus the project scripts at `../scripts/` |
| XDC | `../constraints/zedboard.xdc` |
| Compiler version / flags | Not applicable to the handwritten assembly snapshot; assembler version was not recorded |
| Linker script / ELF / map | Not available for this handwritten hardware-offload firmware snapshot |
| Raw counters | `raw_counters/` |
| SAIF/VCD | `activity/RV32IMB_CTR_4KiB_postroute.saif` (SAIF was the power input; no equivalent VCD was generated) |
| Power / timing / utilization | `reports/` |
| Seed scripts and run definition | `scripts/run_multirun_timing.tcl`, `scripts/query_seed_params.tcl`, and `seed/` |
| Expected NIST vectors | `expected/nist_sp_800_38a_vectors.csv` and the full payload vectors at `../expected/` |

The raw Vivado report headers retain the original workstation paths as provenance.
The Tcl files in this directory use arguments instead of those historical absolute paths.
Check all packaged files with:

```text
python reproducibility/verify_sha256.py
```
