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

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeAIE2TargetInfo() {
  RegisterTarget<Triple::aie2, /*HasJIT=*/false> X(
      getTheAIE2Target(), "aie2", "AMD AI Engine 2 (minimal)", "AIE2");
}
