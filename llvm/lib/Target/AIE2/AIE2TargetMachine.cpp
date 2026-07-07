//===-- AIE2TargetMachine.cpp - Define TargetMachine for AIE2 ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2TargetMachine.h"
#include "AIE2.h"
#include "TargetInfo/AIE2TargetInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeAIE2Target() {
  RegisterTargetMachine<AIE2TargetMachine> X(getTheAIE2Target());
}

// Explicit DataLayout: 32-bit little-endian, ELF, 32-bit pointers, standard
// integer widths. NOTE the pointer is p:32:32 -- NOT the fork's non-pow2
// p:20:32 -- and there are no i48/i20 types anywhere.
static StringRef computeDataLayout() {
  return "e-m:e-p:32:32-i8:8:32-i16:16:32-i32:32:32-i64:32:64-f32:32:32-a:0:32-"
         "n32";
}

static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::Static);
}

AIE2TargetMachine::AIE2TargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, computeDataLayout(), TT, CPU, FS, Options,
                               getEffectiveRelocModel(RM),
                               getEffectiveCodeModel(CM, CodeModel::Small), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()),
      Subtarget(TT, std::string(CPU), std::string(FS), *this) {
  initAsmInfo();
}

namespace {
class AIE2PassConfig : public TargetPassConfig {
public:
  AIE2PassConfig(AIE2TargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  AIE2TargetMachine &getAIE2TargetMachine() const {
    return getTM<AIE2TargetMachine>();
  }

  bool addInstSelector() override {
    addPass(createAIE2ISelDag(getAIE2TargetMachine()));
    return false;
  }
};
} // namespace

TargetPassConfig *AIE2TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new AIE2PassConfig(*this, PM);
}
