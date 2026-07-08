//===-- AIE2CallingConv.td - AIE2 Calling Conventions ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal: i32 args/returns in r0-r5, rest on the stack.
//===----------------------------------------------------------------------===//

// Pointer arguments live in eP (p0-p5); plain integers in eR (r0-r5). AIE2
// load/store address-generation requires the address in an eP register, so
// routing pointers here (via the core CCIfPtr / ArgFlags.isPointer()) lets
// loads/stores select directly off the incoming argument with no cross-class
// copy.
def CC_AIE2 : CallingConv<[
  CCIfPtr<CCAssignToReg<[P0, P1, P2, P3, P4, P5]>>,
  CCIfType<[i1, i8, i16], CCPromoteToType<i32>>,
  CCIfType<[i32], CCAssignToReg<[R0, R1, R2, R3, R4, R5]>>,
  CCIfType<[i32], CCAssignToStack<4, 4>>
]>;

def RetCC_AIE2 : CallingConv<[
  CCIfType<[i1, i8, i16], CCPromoteToType<i32>>,
  CCIfType<[i32], CCAssignToReg<[R0, R1]>>
]>;

def CSR_AIE2 : CalleeSavedRegs<(add R6, R7, R8, R9, R10, R11, R12, R13, LR)>;
