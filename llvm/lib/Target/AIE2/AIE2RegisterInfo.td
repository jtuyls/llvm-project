//===-- AIE2RegisterInfo.td - AIE2 Register defs -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal AIE2 register file: 16 32-bit general-purpose registers.
// NOTE: pointers are modeled as plain 32-bit values (no 20-bit MVT).
//===----------------------------------------------------------------------===//

class AIE2Reg<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "AIE2";
}

// r0-r13 general purpose; r14 = stack pointer; r15 = link register.
foreach i = 0-13 in {
  def R#i : AIE2Reg<i, "r"#i>, DwarfRegNum<[i]>;
}
def SP : AIE2Reg<14, "sp">, DwarfRegNum<[14]>;
def LR : AIE2Reg<15, "lr">, DwarfRegNum<[15]>;

// The general-purpose register class holds i32 (and pointers, which are i32).
def GPR : RegisterClass<"AIE2", [i32], 32, (add (sequence "R%u", 0, 13), SP, LR)>;

//===----------------------------------------------------------------------===//
// Pointer registers (eP): p0-p7, 3-bit HWEncoding. On real hardware these are
// 20-bit address registers; in the pow2 model they hold plain i32 addresses.
// The 3-bit HWEncoding is what the load/store address-generation field selects,
// so this class is required to emit hardware-valid `lda`/`st` -- the address
// MUST live in an eP register, not a general r-register.
//===----------------------------------------------------------------------===//
class AIE2PtrReg<bits<3> Enc, string n> : Register<n> {
  let HWEncoding{2-0} = Enc;
  let Namespace = "AIE2";
}
foreach i = 0-7 in {
  def P#i : AIE2PtrReg<i, "p"#i>, DwarfRegNum<[!add(i, 200)]>;
}
// Pointers are i32 values (p:32, no i20) held in the 3-bit-encoded eP class.
def PTR : RegisterClass<"AIE2", [i32], 32, (sequence "P%u", 0, 7)>;
