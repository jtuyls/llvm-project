//===-- AIE2InstrInfo.cpp - AIE2 Instruction Information ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2InstrInfo.h"
#include "AIE2Subtarget.h"
#include "MCTargetDesc/AIE2MCTargetDesc.h" // AIE2::MOVr and other opcode enums
#include "llvm/CodeGen/MachineInstrBuilder.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "AIE2GenInstrInfo.inc"

using namespace llvm;

AIE2InstrInfo::AIE2InstrInfo(const AIE2Subtarget &STI)
    : AIE2GenInstrInfo(STI, RI), RI() {}

void AIE2InstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MI,
                                const DebugLoc &DL, Register DestReg,
                                Register SrcReg, bool KillSrc,
                                bool RenamableDest, bool RenamableSrc) const {
  BuildMI(MBB, MI, DL, get(AIE2::MOVr), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc));
}
