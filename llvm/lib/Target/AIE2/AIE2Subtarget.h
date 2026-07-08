//===-- AIE2Subtarget.h - Define Subtarget for AIE2 ------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_AIE2SUBTARGET_H
#define LLVM_LIB_TARGET_AIE2_AIE2SUBTARGET_H

#include "AIE2FrameLowering.h"
#include "AIE2ISelLowering.h"
#include "AIE2InstrInfo.h"
#include "llvm/CodeGen/SelectionDAGTargetInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"

#define GET_SUBTARGETINFO_HEADER
#include "AIE2GenSubtargetInfo.inc"

namespace llvm {
class StringRef;
class TargetMachine;

class AIE2Subtarget : public AIE2GenSubtargetInfo {
  // Set by ParseSubtargetFeatures from FeatureAIE2P (enabled for the aie2p
  // processor / triple). Selects the aie2p instruction encodings.
  bool IsAIE2P = false;

  AIE2InstrInfo InstrInfo;
  AIE2FrameLowering FrameLowering;
  AIE2TargetLowering TLInfo;
  // The base SelectionDAGTargetInfo is concrete and its verifyTargetNode is a
  // no-op; we need a non-null instance so DAG node verification doesn't crash.
  SelectionDAGTargetInfo TSInfo;

public:
  AIE2Subtarget(const Triple &TT, StringRef CPU, StringRef FS,
                const TargetMachine &TM);

  void ParseSubtargetFeatures(StringRef CPU, StringRef TuneCPU, StringRef FS);

  const AIE2InstrInfo *getInstrInfo() const override { return &InstrInfo; }
  const AIE2RegisterInfo *getRegisterInfo() const override {
    return &InstrInfo.getRegisterInfo();
  }
  const AIE2FrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }
  const AIE2TargetLowering *getTargetLowering() const override {
    return &TLInfo;
  }
  const SelectionDAGTargetInfo *getSelectionDAGInfo() const override {
    return &TSInfo;
  }

  bool isAIE2P() const { return IsAIE2P; }
};
} // namespace llvm

#endif
