//===-- AIE2Subtarget.cpp - AIE2 Subtarget Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2Subtarget.h"
#include "AIE2.h"

// The generated subtarget TargetDesc uses LLVM_DEBUG, which needs DEBUG_TYPE.
#define DEBUG_TYPE "aie2-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "AIE2GenSubtargetInfo.inc"

using namespace llvm;

AIE2Subtarget::AIE2Subtarget(const Triple &TT, StringRef CPU, StringRef FS,
                             const TargetMachine &TM)
    : AIE2GenSubtargetInfo(TT, CPU, /*TuneCPU=*/CPU, FS), InstrInfo(*this),
      FrameLowering(), TLInfo(TM, *this) {}
