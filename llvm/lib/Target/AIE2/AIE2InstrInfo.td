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
// Register-register ALU
//===----------------------------------------------------------------------===//
class ALU_rr<string mn, SDPatternOperator op>
    : AIE2Inst<(outs GPR:$dst), (ins GPR:$s1, GPR:$s2),
               !strconcat(mn, " $dst, $s1, $s2"),
               [(set i32:$dst, (op i32:$s1, i32:$s2))]>;

def ADD : ALU_rr<"add", add>;
def SUB : ALU_rr<"sub", sub>;
def AND : ALU_rr<"and", and>;
def OR  : ALU_rr<"or",  or>;
def XOR : ALU_rr<"xor", xor>;

// Register-immediate add (also used for constant materialization / frame).
def ADDI : AIE2Inst<(outs GPR:$dst), (ins GPR:$s, i32imm_op:$imm),
                    "addi $dst, $s, #$imm",
                    [(set i32:$dst, (add i32:$s, imm:$imm))]>;

// Move immediate into a register.
def MOVi : AIE2Inst<(outs GPR:$dst), (ins i32imm_op:$imm),
                    "mov $dst, #$imm",
                    [(set i32:$dst, imm:$imm)]>;

// Register-register move (used by copyPhysReg; not selected from a pattern).
let hasSideEffects = 0 in
def MOVr : AIE2Inst<(outs GPR:$dst), (ins GPR:$src), "mov $dst, $src", []>;

//===----------------------------------------------------------------------===//
// Memory: a single word load through a register-held pointer. This exists only
// to demonstrate that pointers are plain i32 (p:32) -- the load address is a
// GPR, no i20/p:20 machinery involved.
//===----------------------------------------------------------------------===//
let mayLoad = 1 in
def LW : AIE2Inst<(outs GPR:$dst), (ins GPR:$addr), "lw $dst, [$addr]",
                  [(set i32:$dst, (load GPR:$addr))]>;

//===----------------------------------------------------------------------===//
// Control flow
//===----------------------------------------------------------------------===//
let isReturn = 1, isTerminator = 1, isBarrier = 1 in
def RET : AIE2Inst<(outs), (ins), "ret", [(AIE2ret_glue)]>;
