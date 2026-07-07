//===-- AIE2FrameLowering.h - AIE2 Frame Lowering --------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_AIE2FRAMELOWERING_H
#define LLVM_LIB_TARGET_AIE2_AIE2FRAMELOWERING_H

#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/Support/Alignment.h"

namespace llvm {
class AIE2FrameLowering : public TargetFrameLowering {
public:
  AIE2FrameLowering()
      : TargetFrameLowering(StackGrowsDown, Align(4), 0, Align(4)) {}

  void emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const override;

protected:
  bool hasFPImpl(const MachineFunction &MF) const override { return false; }
};
} // namespace llvm

#endif
