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

//===----------------------------------------------------------------------===//
// Real AIE2 encodings, lifted from the fork's slot + composite-format layouts
// (llvm-aie), with the composite-format constant bits inlined so plain
// -gen-emitter yields the standalone 32-bit word (no CodeGenFormat/bundling).
//
// I32_ALU composite (AIE2CompositeFormats.td): Inst = {0b00010, alu[19:0],
// 0b001, 0b1001}. The 20-bit `alu` slot layout is per AIE2GenInstrFormats.td.
//===----------------------------------------------------------------------===//

// Reg-immediate ALU add: alu = {mRx0[5], mRx[5], c7s[7], 0b11, 0b0}.
// Verified: add r1,r1,#1 -> 0x10420719 (matches fork `add r1,r1,#1`).
class AIE2AluRI<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<5> mRx;    // dst
  bits<5> mRx0;   // src
  bits<7> c7s;    // signed imm
  let Inst{31-27} = 0b00010;
  let Inst{26-22} = mRx0;
  let Inst{21-17} = mRx;
  let Inst{16-10} = c7s;
  let Inst{9-8}   = 0b11;
  let Inst{7}     = 0b0;
  let Inst{6-4}   = 0b001;
  let Inst{3-0}   = 0b1001;
}

// Reg-reg ALU: alu = {mRx0[5], mRx[5], mRy[5], op[4], 0b1}.
class AIE2AluRR<bits<4> op, dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<5> mRx;    // dst
  bits<5> mRx0;   // src1
  bits<5> mRy;    // src2
  let Inst{31-27} = 0b00010;
  let Inst{26-22} = mRx0;
  let Inst{21-17} = mRx;
  let Inst{16-12} = mRy;
  let Inst{11-8}  = op;
  let Inst{7}     = 0b1;
  let Inst{6-4}   = 0b001;
  let Inst{3-0}   = 0b1001;
}
