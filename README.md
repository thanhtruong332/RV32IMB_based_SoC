# RV32IMB_based_SoC

Portable Vivado source package for the RV32IMB_based_SoC design used in the SE-RISSP experiments.

## Contents

- `ip_repo/rv32imb_ultra_1_0`: packaged CPU IP (`xilinx.com:user:rv32imb_ultra:1.0`).
- `ip_repo/AES_hardware_final_1_1`: packaged AES-128 AXI IP.
- `design/`: Vivado block design and XCI configuration files.
- `constraints/zedboard.xdc`: ZedBoard constraints.
- `firmware/CTR_4KiB.coe`: memory initialization image used by the committed block design.
- `scripts/create_project.tcl`: creates a clean Vivado project using repository-relative paths.

## Recreate the project

On Windows, clone into a short path (for example `C:\work`) or run `git config --global core.longpaths true` first; some IP configuration paths exceed 260 characters.

Requirements: Vivado 2024.2 and device support for `xc7z020clg484-2`. The reported results use this part; the ZedBoard itself carries the `-1` speed grade (`xc7z020clg484-1`), so re-implement for that part before programming a board.

```powershell
vivado -mode batch -source scripts/create_project.tcl
```

The generated project is written under `build/` and is intentionally excluded from Git. Open the generated `.xpr` in Vivado after the script completes.

## Hardware regression suite

The repository includes all 12 hardware-accelerated AES conditions:

- Modes: ECB, CBC, CFB-128 and CTR.
- Payloads: 16 B, 256 B and 4 KiB.
- For every condition: assembly source, COE/MEM firmware images, expected
  plaintext/state/ciphertext files and a self-checking testbench.
- Each testbench executes three messages and checks raw counters, ciphertext,
  key/IV loading, feedback or counter continuity and reset anomalies.
- The exact testbench/firmware mapping is listed in [`TEST_MATRIX.md`](TEST_MATRIX.md).

Run one condition from the repository root:

```powershell
vivado -mode batch -source scripts/run_test.tcl -tclargs CBC_256B
```

Run all 12 conditions:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_all_tests.ps1 -Vivado vivado
```

Test result CSV files are written to the XSim run directory. Generated Vivado
projects and simulator products remain excluded from Git.

## Reproducibility scope

Source, packaged custom IP, block-design configuration, constraints and firmware are versioned. A compact set of measured SAIF, power, timing, utilization, seed and counter evidence is included under [`reproducibility/`](reproducibility/). Regenerable caches, checkpoints and bitstreams remain excluded.

Architecture and tool metadata are listed in [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md).

## Evidence package

The reviewer-facing [`reproducibility/`](reproducibility/) directory records tool versions, raw evidence and SHA-256 hashes for release `v1.2.2`.

## License

See `LICENSE_STATUS.md`.
