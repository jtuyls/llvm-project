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

//===----------------------------------------------------------------------===//
// Load/store, immediate-indexed addressing `[$ptr, #imm]` (the AIE2
// address-generation `ag_idx_imm` mode). Composites (AIE2CompositeFormats.td):
//   I32_LDA = {0b00000, lda[20:0], 0b01, 0b1001},  lda = {ag_all[13], mLdaScl[7], 0b1}
//   I32_ST  = {0b00001, st[20:0],  0b01, 0b1001},  st  = {ag_all[13], mSclSt[7],  0b0}
// with (AIE2GenInstrInfo.td / AIE2GenInstrFormats.td):
//   ag_all   = {ptr[3], imm[6], 0b1010}          (ag_all__ag_idx_imm mixin)
//   mLdaScl  = {mR[5], 0b00}  == (Enc << 2)       (eR data-reg field; see the
//              fork's AIE2MCCodeEmitter getmLdaScl/getmSclSt: eR -> (Enc<<2)|00)
// Both fields are plain here -- the two zero bits below the 5-bit register make
// the (Enc<<2) shift expressible without a custom encoder. Verified bit-exact:
//   lda r1,[p0,#0] -> 0x00028259 ([0x59,0x82,0x02,0x00])
//   st  r1,[p1,#0] -> 0x09028219 ([0x19,0x82,0x02,0x09])
//===----------------------------------------------------------------------===//
class AIE2LdaScl<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<5> mR;     // data (dst) register, eR
  bits<3> ptr;    // base pointer register, eP
  bits<6> imm;    // signed byte offset
  let mayLoad = 1;
  let Inst{31-27} = 0b00000;      // I32_LDA opcode
  let Inst{26-24} = ptr;          // ag_all[12:10]
  let Inst{23-18} = imm;          // ag_all[9:4]
  let Inst{17-14} = 0b1010;       // ag_all[3:0] (ag_idx_imm mode)
  let Inst{13-9}  = mR;           // mLdaScl[6:2]
  let Inst{8-7}   = 0b00;         // mLdaScl[1:0]
  let Inst{6}     = 0b1;          // lda[0]
  let Inst{5-4}   = 0b01;         // I32_LDA format tail
  let Inst{3-0}   = 0b1001;
}
class AIE2StScl<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<5> mR;     // data (src) register, eR
  bits<3> ptr;    // base pointer register, eP
  bits<6> imm;    // signed byte offset
  let mayStore = 1;
  let Inst{31-27} = 0b00001;      // I32_ST opcode
  let Inst{26-24} = ptr;          // ag_all[12:10]
  let Inst{23-18} = imm;          // ag_all[9:4]
  let Inst{17-14} = 0b1010;       // ag_all[3:0] (ag_idx_imm mode)
  let Inst{13-9}  = mR;           // mSclSt[6:2]
  let Inst{8-7}   = 0b00;         // mSclSt[1:0]
  let Inst{6}     = 0b0;          // st[0]
  let Inst{5-4}   = 0b01;         // I32_ST format tail
  let Inst{3-0}   = 0b1001;
}

//===----------------------------------------------------------------------===//
// Constant materialization: `mova $mR, #imm` with an 11-bit signed immediate
// (AIE2 lda-slot constant-generation, MOVA_lda_cg). Composite I32_LDA with
//   lda = {c11s[11], 0b00, mLdaCg[7], 0b1},  mLdaCg(eR) = {mR[5], 0b00}
// Verified bit-exact vs the fork's llvm-mc:
//   mova r1,#-1 -> [0x59,0x02,0xff,0x07]   mova r0,#1 -> [0x59,0x00,0x01,0x00]
//===----------------------------------------------------------------------===//
class AIE2MovImm<dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<5> mR;      // dst, eR
  bits<11> c11s;   // signed immediate
  let isMoveImm = 1;
  let isReMaterializable = 1;
  let Inst{31-27} = 0b00000;      // I32_LDA opcode
  let Inst{26-16} = c11s;         // lda[20:10]
  let Inst{15-14} = 0b00;         // lda[9:8]
  let Inst{13-9}  = mR;           // mLdaCg[6:2]
  let Inst{8-7}   = 0b00;         // mLdaCg[1:0]
  let Inst{6}     = 0b1;          // lda[0]
  let Inst{5-4}   = 0b01;         // I32_LDA format tail
  let Inst{3-0}   = 0b1001;
}

//===----------------------------------------------------------------------===//
// DMA locks: `acq #id, $val` / `rel #id, $val` (alu slot). Composite I32_ALU
// with alu = {mLockId[7], dc[1], op[2], mRy[5], 0b0010, 0b0} and the immediate
// lock-id form mLockId = {id[6], 0b0}; op = 0b01 (acq) / 0b00 (rel).
// Verified bit-exact vs the fork:
//   acq #0,r1 -> [0x19,0x12,0x02,0x10]   rel #0,r0 -> [0x19,0x02,0x00,0x10]
//===----------------------------------------------------------------------===//
class AIE2Lock<bits<2> op, dag outs, dag ins, string asmstr, list<dag> pattern>
    : AIE2Inst<outs, ins, asmstr, pattern> {
  bits<6> id;      // lock id (immediate)
  bits<5> mRy;     // value register, eR
  let hasSideEffects = 1;
  let Inst{31-27} = 0b00010;      // I32_ALU opcode
  let Inst{26-21} = id;           // mLockId[6:1]
  let Inst{20}    = 0b0;          // mLockId[0]
  let Inst{19}    = 0b0;          // dontcare
  let Inst{18-17} = op;           // 0b01 acq / 0b00 rel
  let Inst{16-12} = mRy;          // value register
  let Inst{11-8}  = 0b0010;       // lock sub-opcode
  let Inst{7}     = 0b0;
  let Inst{6-4}   = 0b001;        // I32_ALU format tail
  let Inst{3-0}   = 0b1001;
}
