//===-- AIE2MCTargetDesc.cpp - AIE2 Target Descriptions ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/AIE2MCTargetDesc.h"
#include "MCTargetDesc/AIE2InstPrinter.h"
#include "MCTargetDesc/AIE2MCAsmInfo.h"
#include "TargetInfo/AIE2TargetInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "AIE2GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "AIE2GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "AIE2GenRegisterInfo.inc"

static MCInstrInfo *createAIE2MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitAIE2MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createAIE2MCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitAIE2MCRegisterInfo(X, AIE2::LR);
  return X;
}

static MCSubtargetInfo *createAIE2MCSubtargetInfo(const Triple &TT,
                                                  StringRef CPU, StringRef FS) {
  if (CPU.empty())
    CPU = "aie2";
  return createAIE2MCSubtargetInfoImpl(TT, CPU, /*TuneCPU=*/CPU, FS);
}

static MCInstPrinter *createAIE2MCInstPrinter(const Triple &T,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  return new AIE2InstPrinter(MAI, MII, MRI);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeAIE2TargetMC() {
  Target &T = getTheAIE2Target();
  RegisterMCAsmInfo<AIE2MCAsmInfo> X(T);
  TargetRegistry::RegisterMCInstrInfo(T, createAIE2MCInstrInfo);
  TargetRegistry::RegisterMCRegInfo(T, createAIE2MCRegisterInfo);
  TargetRegistry::RegisterMCSubtargetInfo(T, createAIE2MCSubtargetInfo);
  TargetRegistry::RegisterMCInstPrinter(T, createAIE2MCInstPrinter);
}
