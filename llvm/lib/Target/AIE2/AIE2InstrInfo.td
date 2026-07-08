//===-- AIE2InstrInfo.td - AIE2 Instruction defs -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal scalar-i32 instruction set: enough to lower args/returns and basic
// integer arithmetic. No vectors, no i48/i20, no VLIW packing.
//===----------------------------------------------------------------------===//

include "AIE2InstrFormats.td"

// Custom SDNodes.
def SDT_AIE2Ret : SDTypeProfile<0, 0, []>;
def AIE2ret_glue : SDNode<"AIE2ISD::RET_GLUE", SDT_AIE2Ret,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def i32imm_op : Operand<i32>;

//===----------------------------------------------------------------------===//
// Register-register ALU -- real I32_ALU encodings (op codes from the fork).
//===----------------------------------------------------------------------===//
class ALU_rr<bits<4> op, string mn, SDPatternOperator node>
    : AIE2AluRR<op, (outs GPR:$mRx), (ins GPR:$mRx0, GPR:$mRy),
                mn # " $mRx, $mRx0, $mRy",
                [(set i32:$mRx, (node i32:$mRx0, i32:$mRy))]>;

def ADD : ALU_rr<0b0000, "add", add>;
def SUB : ALU_rr<0b0001, "sub", sub>;
def AND : ALU_rr<0b0100, "and", and>;
def OR  : ALU_rr<0b0101, "or",  or>;
def XOR : ALU_rr<0b0110, "xor", xor>;

// Register-immediate add -- real I32_ALU encoding.
// Verified: add r1,r1,#1 -> 0x10420719 (matches the fork).
def simm7 : Operand<i32>, ImmLeaf<i32, [{ return isInt<7>(Imm); }]>;
def ADD_ri : AIE2AluRI<(outs GPR:$mRx), (ins GPR:$mRx0, simm7:$c7s),
                       "add $mRx, $mRx0, #$c7s",
                       [(set i32:$mRx, (add i32:$mRx0, simm7:$c7s))]>;

// Move immediate into a register.
def MOVi : AIE2Inst<(outs GPR:$dst), (ins i32imm_op:$imm),
                    "mov $dst, #$imm",
                    [(set i32:$dst, imm:$imm)]>;

// Register-register move (used by copyPhysReg; not selected from a pattern).
let hasSideEffects = 0 in
def MOVr : AIE2Inst<(outs GPR:$dst), (ins GPR:$src), "mov $dst, $src", []>;

//===----------------------------------------------------------------------===//
// Memory: real AIE2 word load/store, immediate-indexed `[$ptr, #imm]`. The
// address lives in an eP (PTR) pointer register -- required for a
// hardware-valid `lda`/`st`. Data flows through eR/GPR. Encodings verified
// bit-exact vs the fork (see AIE2InstrFormats.td).
//===----------------------------------------------------------------------===//
def simm6 : Operand<i32>, ImmLeaf<i32, [{ return isInt<6>(Imm); }]>;

def LDA_idx_imm : AIE2LdaScl<(outs GPR:$mR), (ins PTR:$ptr, simm6:$imm),
                             "lda $mR, [$ptr, #$imm]", []>;
def ST_idx_imm  : AIE2StScl<(outs), (ins GPR:$mR, PTR:$ptr, simm6:$imm),
                            "st $mR, [$ptr, #$imm]", []>;

// Offset-0 addressing: the pointer register is the address directly.
def : Pat<(i32 (load PTR:$ptr)),        (LDA_idx_imm PTR:$ptr, 0)>;
def : Pat<(store i32:$mR, PTR:$ptr),    (ST_idx_imm GPR:$mR, PTR:$ptr, 0)>;

//===----------------------------------------------------------------------===//
// NOP -- real 2-byte encoding, bit-exact to base llvm-aie (`nop` = 0x0001).
// Delay-slot / packet padding uses this.
//===----------------------------------------------------------------------===//
let hasSideEffects = 0 in
def NOP : AIE2Inst16<(outs), (ins), "nop", []> {
  let Inst{31-0} = 0x00000001; // only low 16 bits emitted (Size = 2)
}

//===----------------------------------------------------------------------===//
// Control flow
//===----------------------------------------------------------------------===//
// Real standalone `ret lr` encoding, bit-exact to base llvm-aie (0x10001819,
// little-endian bytes 19 18 00 10). This is a constant encoding (no register
// operands vary), so no format-wrapper machinery is needed for it.
let isReturn = 1, isTerminator = 1, isBarrier = 1 in
def RET : AIE2Inst<(outs), (ins), "ret lr", [(AIE2ret_glue)]> {
  let Inst{31-0} = 0x10001819;
}
