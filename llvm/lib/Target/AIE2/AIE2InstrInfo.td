//===-- AIE2InstrInfo.td - AIE2 Instruction defs -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal scalar-i32 instruction set: enough to lower args/returns, basic
// integer arithmetic, word load/store and DMA locks. No vectors, no i48/i20,
// no VLIW packing. Two encoding families -- aie2 and aie2p (npu2 / Strix) --
// selected by the IsAIE2/IsAIE2P subtarget predicates. Field positions match
// for the ALU forms (only the instr32 tail differs); load/store/const/lock and
// nop/ret differ, so each has an aie2 and an aie2p definition.
//===----------------------------------------------------------------------===//

include "AIE2InstrFormats.td"

// Custom SDNodes.
def SDT_AIE2Ret : SDTypeProfile<0, 0, []>;
def AIE2ret_glue : SDNode<"AIE2ISD::RET_GLUE", SDT_AIE2Ret,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def i32imm_op : Operand<i32>;

// Immediate operands (shared).
def simm7  : Operand<i32>, ImmLeaf<i32, [{ return isInt<7>(Imm); }]>;
def simm11 : Operand<i32>, ImmLeaf<i32, [{ return isInt<11>(Imm); }]>;
def simm6  : Operand<i32>, ImmLeaf<i32, [{ return isInt<6>(Imm); }]>;
def imm6   : Operand<i32>, ImmLeaf<i32, [{ return isUInt<6>(Imm); }]>;
def imm20  : Operand<i32>, ImmLeaf<i32, [{ return isUInt<20>(Imm); }]>;

// Register-register move (used by copyPhysReg; not selected from a pattern).
let hasSideEffects = 0 in
def MOVr : AIE2Inst<(outs GPR:$dst), (ins GPR:$src), "mov $dst, $src", []>;

//===----------------------------------------------------------------------===//
// aie2 encodings (base AIE2, EM_AIE). Verified bit-exact vs the fork.
//===----------------------------------------------------------------------===//
let Predicates = [IsAIE2] in {
  class ALU_rr<bits<4> op, string mn, SDPatternOperator node>
      : AIE2AluRR<op, (outs GPR:$mRx), (ins GPR:$mRx0, GPR:$mRy),
                  mn # " $mRx, $mRx0, $mRy",
                  [(set i32:$mRx, (node i32:$mRx0, i32:$mRy))]>;
  def ADD : ALU_rr<0b0000, "add", add>;
  def SUB : ALU_rr<0b0001, "sub", sub>;
  def AND : ALU_rr<0b0100, "and", and>;
  def OR  : ALU_rr<0b0101, "or",  or>;
  def XOR : ALU_rr<0b0110, "xor", xor>;

  def ADD_ri : AIE2AluRI<(outs GPR:$mRx), (ins GPR:$mRx0, simm7:$c7s),
                         "add $mRx, $mRx0, #$c7s",
                         [(set i32:$mRx, (add i32:$mRx0, simm7:$c7s))]>;

  def MOVA : AIE2MovImm<(outs GPR:$mR), (ins simm11:$c11s),
                        "mova $mR, #$c11s",
                        [(set i32:$mR, (i32 simm11:$c11s))]>;

  def ACQ_imm : AIE2Lock<0b01, (outs), (ins imm6:$id, GPR:$mRy),
                         "acq #$id, $mRy", []>;
  def REL_imm : AIE2Lock<0b00, (outs), (ins imm6:$id, GPR:$mRy),
                         "rel #$id, $mRy", []>;

  def LDA_idx_imm : AIE2LdaScl<(outs GPR:$mR), (ins PTR:$ptr, simm6:$imm),
                               "lda $mR, [$ptr, #$imm]", []>;
  def ST_idx_imm  : AIE2StScl<(outs), (ins GPR:$mR, PTR:$ptr, simm6:$imm),
                              "st $mR, [$ptr, #$imm]", []>;

  // NOP -- real 2-byte encoding (aie2 `nop` = 0x0001).
  let hasSideEffects = 0 in
  def NOP : AIE2Inst16<(outs), (ins), "nop", []> { let Inst{31-0} = 0x00000001; }

  // Real standalone `ret lr` (aie2 = 0x10001819).
  let isReturn = 1, isTerminator = 1, isBarrier = 1 in
  def RET : AIE2Inst<(outs), (ins), "ret lr", [(AIE2ret_glue)]> {
    let Inst{31-0} = 0x10001819;
  }

  def : Pat<(int_aie2_acquire imm6:$id, i32:$mRy), (ACQ_imm imm6:$id, GPR:$mRy)>;
  def : Pat<(int_aie2_release imm6:$id, i32:$mRy), (REL_imm imm6:$id, GPR:$mRy)>;
  def : Pat<(i32 (load PTR:$ptr)),     (LDA_idx_imm PTR:$ptr, 0)>;
  def : Pat<(store i32:$mR, PTR:$ptr), (ST_idx_imm GPR:$mR, PTR:$ptr, 0)>;
}

//===----------------------------------------------------------------------===//
// aie2p (npu2 / Strix) encodings. Verified bit-exact vs the fork's aie2p
// llvm-mc: add r0,r0,#1=[0x18,07,00,10]; mova r0,#1=[0x18,00,01,00];
// lda r0,[p0,#0]=[0x98,16,04,00]; st r0,[p0,#0]=[0x98,11,04,08];
// acq #0,r0=[0x18,08,02,10]; rel #0,r0=[0x18,08,00,10]; ret lr=[0x18,00,28,10];
// done=[0x18,00,08,10]; nop=[0x00,0x00].
//===----------------------------------------------------------------------===//
let Predicates = [IsAIE2P] in {
  class ALU_rr_P<bits<4> op, string mn, SDPatternOperator node>
      : AIE2PAluRR<op, (outs GPR:$mRx), (ins GPR:$mRx0, GPR:$mRy),
                   mn # " $mRx, $mRx0, $mRy",
                   [(set i32:$mRx, (node i32:$mRx0, i32:$mRy))]>;
  def ADD_P : ALU_rr_P<0b0000, "add", add>;
  def SUB_P : ALU_rr_P<0b0001, "sub", sub>;
  def AND_P : ALU_rr_P<0b0100, "and", and>;
  def OR_P  : ALU_rr_P<0b0101, "or",  or>;
  def XOR_P : ALU_rr_P<0b0110, "xor", xor>;

  def ADD_ri_P : AIE2PAluRI<(outs GPR:$mRx), (ins GPR:$mRx0, simm7:$c7s),
                            "add $mRx, $mRx0, #$c7s",
                            [(set i32:$mRx, (add i32:$mRx0, simm7:$c7s))]>;

  def MOVA_P : AIE2PMovImm<(outs GPR:$mR), (ins simm11:$c11s),
                           "mova $mR, #$c11s",
                           [(set i32:$mR, (i32 simm11:$c11s))]>;

  def ACQ_imm_P : AIE2PLock<0b1, (outs), (ins imm6:$id, GPR:$mRy),
                            "acq #$id, $mRy", []>;
  def REL_imm_P : AIE2PLock<0b0, (outs), (ins imm6:$id, GPR:$mRy),
                            "rel #$id, $mRy", []>;

  def LDA_P : AIE2PLdaScl<(outs GPR:$mR), (ins PTR:$ptr),
                          "lda $mR, [$ptr, #0]", []>;
  def ST_P  : AIE2PStScl<(outs), (ins GPR:$mR, PTR:$ptr),
                         "st $mR, [$ptr, #0]", []>;

  // Materialize a fixed (numeric) address into an eP pointer register, so a
  // self-contained kernel can load/store to a known data-memory location with
  // no relocation. imm20 fits AIE's 20-bit pointer/address width.
  def MOVXM_P : AIE2PMovXM<(outs PTR:$p), (ins imm20:$imm),
                           "movxm $p, #$imm", []>;

  // NOP -- real 2-byte encoding (aie2p `nop` = 0x0000).
  let hasSideEffects = 0 in
  def NOP_P : AIE2Inst16<(outs), (ins), "nop", []> { let Inst{31-0} = 0x00000000; }

  // Real standalone `ret lr` (aie2p = 0x10280018).
  let isReturn = 1, isTerminator = 1, isBarrier = 1 in
  def RET_P : AIE2Inst<(outs), (ins), "ret lr", [(AIE2ret_glue)]> {
    let Inst{31-0} = 0x10280018;
  }

  // `done` -- signals Core.Done (aie2p = 0x10080018). Lowered from the done
  // intrinsic; marked a barrier so it can terminate a core-entry block.
  let hasSideEffects = 1, isBarrier = 1 in
  def DONE_P : AIE2Inst<(outs), (ins), "done", [(int_aie2_done)]> {
    let Inst{31-0} = 0x10080018;
  }

  def : Pat<(int_aie2_acquire imm6:$id, i32:$mRy), (ACQ_imm_P imm6:$id, GPR:$mRy)>;
  def : Pat<(int_aie2_release imm6:$id, i32:$mRy), (REL_imm_P imm6:$id, GPR:$mRy)>;
  def : Pat<(i32 (load PTR:$ptr)),     (LDA_P PTR:$ptr)>;
  def : Pat<(store i32:$mR, PTR:$ptr), (ST_P GPR:$mR, PTR:$ptr)>;
  // Load/store to a fixed numeric address: materialize it into eP first.
  def : Pat<(i32 (load (i32 imm20:$a))),      (LDA_P (MOVXM_P imm20:$a))>;
  def : Pat<(store i32:$mR, (i32 imm20:$a)),  (ST_P GPR:$mR, (MOVXM_P imm20:$a))>;
}
