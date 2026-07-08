//===-- AIE2Subtarget.cpp - AIE2 Subtarget Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2Subtarget.h"
#include "AIE2.h"
// Provides the AIE2::FeatureAIE2P subtarget-feature enum (GET_SUBTARGETINFO_ENUM).
#include "MCTargetDesc/AIE2MCTargetDesc.h"

// The generated subtarget TargetDesc uses LLVM_DEBUG, which needs DEBUG_TYPE.
#define DEBUG_TYPE "aie2-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "AIE2GenSubtargetInfo.inc"

using namespace llvm;

// Default the CPU from the triple so `-mtriple=aie2p` (no -mcpu) enables the
// aie2p encodings via the aie2p ProcessorModel / FeatureAIE2P.
static StringRef getEffectiveCPU(const Triple &TT, StringRef CPU) {
  if (!CPU.empty())
    return CPU;
  return TT.isAIE2P() ? "aie2p" : "aie2";
}

AIE2Subtarget::AIE2Subtarget(const Triple &TT, StringRef CPU, StringRef FS,
                             const TargetMachine &TM)
    : AIE2GenSubtargetInfo(TT, getEffectiveCPU(TT, CPU),
                           /*TuneCPU=*/getEffectiveCPU(TT, CPU), FS),
      InstrInfo(*this), FrameLowering(), TLInfo(TM, *this) {
  // Set IsAIE2P (and any future features) from the CPU/feature string. The
  // generated base ctor does not call this, so do it explicitly here.
  StringRef EffCPU = getEffectiveCPU(TT, CPU);
  ParseSubtargetFeatures(EffCPU, /*TuneCPU=*/EffCPU, FS);
}
