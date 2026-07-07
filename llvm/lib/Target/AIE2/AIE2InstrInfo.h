//===-- AIE2InstrInfo.h - AIE2 Instruction Information ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_AIE2INSTRINFO_H
#define LLVM_LIB_TARGET_AIE2_AIE2INSTRINFO_H

#include "AIE2RegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "AIE2GenInstrInfo.inc"

namespace llvm {
class AIE2Subtarget;

class AIE2InstrInfo : public AIE2GenInstrInfo {
  const AIE2RegisterInfo RI;

public:
  // LLVM 23's generated GenInstrInfo ctor requires (STI, TRI); we pass our
  // owned RI as the TRI (its address is only stored, not used, during ctor).
  explicit AIE2InstrInfo(const AIE2Subtarget &STI);

  const AIE2RegisterInfo &getRegisterInfo() const { return RI; }

  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                   const DebugLoc &DL, Register DestReg, Register SrcReg,
                   bool KillSrc, bool RenamableDest = false,
                   bool RenamableSrc = false) const override;
};
} // namespace llvm

#endif
