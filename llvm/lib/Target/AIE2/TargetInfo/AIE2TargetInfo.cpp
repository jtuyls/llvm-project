//===-- AIE2TargetInfo.cpp - AIE2 Target Info -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/AIE2TargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheAIE2Target() {
  static Target TheAIE2Target;
  return TheAIE2Target;
}

// One Target object serves both aie2 and aie2p (the encodings differ and are
// picked by the FeatureAIE2P subtarget feature, set from the triple). A Target
// registers only once, so match both arches here rather than via two
// RegisterTarget calls.
static bool matchAIE2(Triple::ArchType Arch) {
  return Arch == Triple::aie2 || Arch == Triple::aie2p;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeAIE2TargetInfo() {
  TargetRegistry::RegisterTarget(getTheAIE2Target(), "aie2",
                                 "AMD AI Engine 2 / 2P (minimal)", "AIE2",
                                 &matchAIE2, /*HasJIT=*/false);
}
