//===-- AIE2InstrFormats.td - AIE2 Instruction Formats -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal fixed-width 32-bit instruction format. (No VLIW bundling: one
// instruction per slot -- density is a deferred optimization.)
//===----------------------------------------------------------------------===//

class AIE2Inst<dag outs, dag ins, string asmstr, list<dag> pattern, int size = 4>
    : Instruction {
  field bits<32> Inst;
  let Namespace = "AIE2";
  let Size = size;
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// 16-bit (2-byte) instruction form -- e.g. NOP. Only the low 16 bits of Inst
// are emitted (little-endian), controlled by Size = 2.
class AIE2Inst16<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern, /*size=*/2>;

// Pseudo (no encoding) -- used for RET_GLUE lowering etc.
class AIE2Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
  let Inst{31-0} = 0;
}
