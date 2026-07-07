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
