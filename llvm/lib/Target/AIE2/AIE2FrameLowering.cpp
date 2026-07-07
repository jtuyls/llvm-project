//===-- AIE2FrameLowering.cpp - AIE2 Frame Lowering ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2FrameLowering.h"
#include "llvm/CodeGen/MachineFunction.h"

using namespace llvm;

// Minimal: leaf functions with no dynamic stack need no prologue/epilogue.
void AIE2FrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {}
void AIE2FrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {}
