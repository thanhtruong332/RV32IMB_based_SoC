# Test matrix

Every row has a self-checking testbench, the firmware source and both Vivado COE and raw MEM images. Expected plaintext, mode state and ciphertext files are under `expected/`.

| Case | Blocks | Testbench | Firmware |
|---|---:|---|---|
| ECB_16B | 1 | `sim/tb_hw_rv32imb_ECB_16B.v` | `firmware/images/ECB_16B.coe` / `firmware/images/ECB_16B.mem` / `firmware/source/ECB_16B.S` |
| ECB_256B | 16 | `sim/tb_hw_rv32imb_ECB_256B.v` | `firmware/images/ECB_256B.coe` / `firmware/images/ECB_256B.mem` / `firmware/source/ECB_256B.S` |
| ECB_4KiB | 256 | `sim/tb_hw_rv32imb_ECB_4KiB.v` | `firmware/images/ECB_4KiB.coe` / `firmware/images/ECB_4KiB.mem` / `firmware/source/ECB_4KiB.S` |
| CBC_16B | 1 | `sim/tb_hw_rv32imb_CBC_16B.v` | `firmware/images/CBC_16B.coe` / `firmware/images/CBC_16B.mem` / `firmware/source/CBC_16B.S` |
| CBC_256B | 16 | `sim/tb_hw_rv32imb_CBC_256B.v` | `firmware/images/CBC_256B.coe` / `firmware/images/CBC_256B.mem` / `firmware/source/CBC_256B.S` |
| CBC_4KiB | 256 | `sim/tb_hw_rv32imb_CBC_4KiB.v` | `firmware/images/CBC_4KiB.coe` / `firmware/images/CBC_4KiB.mem` / `firmware/source/CBC_4KiB.S` |
| CFB_16B | 1 | `sim/tb_hw_rv32imb_CFB_16B.v` | `firmware/images/CFB_16B.coe` / `firmware/images/CFB_16B.mem` / `firmware/source/CFB_16B.S` |
| CFB_256B | 16 | `sim/tb_hw_rv32imb_CFB_256B.v` | `firmware/images/CFB_256B.coe` / `firmware/images/CFB_256B.mem` / `firmware/source/CFB_256B.S` |
| CFB_4KiB | 256 | `sim/tb_hw_rv32imb_CFB_4KiB.v` | `firmware/images/CFB_4KiB.coe` / `firmware/images/CFB_4KiB.mem` / `firmware/source/CFB_4KiB.S` |
| CTR_16B | 1 | `sim/tb_hw_rv32imb_CTR_16B.v` | `firmware/images/CTR_16B.coe` / `firmware/images/CTR_16B.mem` / `firmware/source/CTR_16B.S` |
| CTR_256B | 16 | `sim/tb_hw_rv32imb_CTR_256B.v` | `firmware/images/CTR_256B.coe` / `firmware/images/CTR_256B.mem` / `firmware/source/CTR_256B.S` |
| CTR_4KiB | 256 | `sim/tb_hw_rv32imb_CTR_4KiB.v` | `firmware/images/CTR_4KiB.coe` / `firmware/images/CTR_4KiB.mem` / `firmware/source/CTR_4KiB.S` |
