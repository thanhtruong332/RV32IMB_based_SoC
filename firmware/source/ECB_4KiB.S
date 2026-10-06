.option norelax
.section .text
.globl _start
_start:
  # One message starts here. Key and IV/counter are loaded once.
  lui  x2, 0xc0002
  addi x2, x2, -256
  lui  x8, 0xc0000
  lui  x11, 0x40000
  addi x12, x0, 0
  addi x13, x0, 256
  lui  x5, %hi(0x20212223)
  addi x5, x5, %lo(0x20212223)
  sw   x5, 16(x11)
  lui  x5, %hi(0x24252627)
  addi x5, x5, %lo(0x24252627)
  sw   x5, 20(x11)
  lui  x5, %hi(0x28292a2b)
  addi x5, x5, %lo(0x28292a2b)
  sw   x5, 24(x11)
  lui  x5, %hi(0x2c2d2e2f)
  addi x5, x5, %lo(0x2c2d2e2f)
  sw   x5, 28(x11)
block_loop:
  lui  x5, %hi(0x6bc1bee2)
  addi x5, x5, %lo(0x6bc1bee2)
  sw   x5, 0(x11)
  lui  x5, %hi(0x2e409f96)
  addi x5, x5, %lo(0x2e409f96)
  sw   x5, 4(x11)
  lui  x5, %hi(0xe93d7e11)
  addi x5, x5, %lo(0xe93d7e11)
  sw   x5, 8(x11)
  lui  x5, %hi(0x7393172a)
  addi x5, x5, %lo(0x7393172a)
  add  x5, x5, x12
  sw   x5, 12(x11)
  addi x5, x0, 1
  sw   x5, 32(x11)
  # Fixed delay: no STATUS polling and no mode-state reset.
  .rept 60
  addi x0, x0, 0
  .endr
  lw   x6, 48(x11)
  lw   x7, 52(x11)
  lw   x28, 56(x11)
  lw   x29, 60(x11)
  sw   x6, 0(x8)
  sw   x7, 4(x8)
  sw   x28, 8(x8)
  sw   x29, 12(x8)
  addi x8, x8, 16
  addi x12, x12, 1
  blt  x12, x13, block_loop
  # Begin the next deterministic repeat as a new message.
  jal  x0, _start
