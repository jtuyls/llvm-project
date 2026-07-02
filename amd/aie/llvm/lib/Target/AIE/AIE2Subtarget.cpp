//===-- AIE2Subtarget.cpp - AIEngine V2 Subtarget Information-------------===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2023-2026 Advanced Micro Devices, Inc. or its affiliates
//
//===----------------------------------------------------------------------===//
//
// This file implements the AIEngine V2 specific subclass of
// TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "AIE2Subtarget.h"
#include "AIE2.h"
#include "AIE2FrameLowering.h"
#include "AIE2LegalizerInfo.h"
#include "AIE2RegisterBankInfo.h"
#include "AIE2TargetMachine.h"
#include "AIECallLowering.h"
#include "llvm/CodeGen/LibcallLoweringInfo.h"
#include "llvm/CodeGen/MachineScheduler.h"
#include "llvm/CodeGen/ScheduleDAG.h"
#include "llvm/IR/RuntimeLibcalls.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "aie2-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "AIE2GenSubtargetInfo.inc"

void AIE2Subtarget::anchor() {}

AIE2Subtarget &AIE2Subtarget::initializeSubtargetDependencies(
    const Triple &TT, StringRef CPU, StringRef FS, StringRef ABIName) {
  if (CPUName.empty())
    CPUName = "aie2";
  ParseSubtargetFeatures(CPUName, CPUName, FS);
  return *this;
}

AIE2Subtarget::AIE2Subtarget(const Triple &TT, StringRef CPU, StringRef TuneCPU,
                             StringRef FS, StringRef ABIName,
                             const TargetMachine &TM)
    : AIE2GenSubtargetInfo(TT, CPU, TuneCPU, FS),
      FrameLowering(initializeSubtargetDependencies(TT, CPU, FS, ABIName)),
      RegInfo(getHwMode()), InstrInfo(*this, RegInfo),
      TLInfo(TM, initializeSubtargetDependencies(TT, CPU, FS, ABIName)),
      InstrItins(getInstrItineraryForCPU(StringRef(CPU))) {
  LLVM_DEBUG(dbgs() << "CPU:" << CPU << "." << CPUName << "." << FS << "."
                    << ABIName << "\n");

  CallLoweringInfo.reset(new AIECallLowering(*getTargetLowering()));
  Legalizer.reset(new AIE2LegalizerInfo(*this));
  auto *RBI = new AIE2RegisterBankInfo(*getRegisterInfo());
  RegBankInfo.reset(RBI);
  InstSelector.reset(createAIE2InstructionSelector(
      *static_cast<const AIE2TargetMachine *>(&TM), *this, *RBI));
}

const CallLowering *AIE2Subtarget::getCallLowering() const {
  return CallLoweringInfo.get();
}

const LegalizerInfo *AIE2Subtarget::getLegalizerInfo() const {
  return Legalizer.get();
}

const RegisterBankInfo *AIE2Subtarget::getRegBankInfo() const {
  return RegBankInfo.get();
}

InstructionSelector *AIE2Subtarget::getInstructionSelector() const {
  return InstSelector.get();
}

const AIEBaseAddrSpaceInfo &AIE2Subtarget::getAddrSpaceInfo() const {
  return AddrSpaceInfo;
}

void AIE2Subtarget::initLibcallLoweringInfo(LibcallLoweringInfo &Info) const {
  // amd/aie/ port: LLVM 23 replaced LLVM 21's unconditional setLibcallName
  // defaults with RuntimeLibcalls.td's per-triple opt-in; AIE's triple is not
  // recognized by setTargetRuntimeLibcallSets(), so it starts with an empty
  // libcall set. Provide the standard compiler-rt / libc implementations so
  // .libcall() legalization (scalar fmul/fdiv/frem) and the memory-intrinsic
  // libcalls (G_MEMCPY/MEMSET/MEMMOVE) can be lowered.
  static const struct {
    RTLIB::Libcall Op;
    RTLIB::LibcallImpl Impl;
  } LibraryCalls[] = {
      {RTLIB::ADD_F32, RTLIB::impl___addsf3},
      {RTLIB::SUB_F32, RTLIB::impl___subsf3},
      {RTLIB::MUL_F32, RTLIB::impl___mulsf3},
      {RTLIB::DIV_F32, RTLIB::impl___divsf3},
      {RTLIB::REM_F32, RTLIB::impl_fmodf},
      {RTLIB::ADD_F64, RTLIB::impl___adddf3},
      {RTLIB::SUB_F64, RTLIB::impl___subdf3},
      {RTLIB::MUL_F64, RTLIB::impl___muldf3},
      {RTLIB::DIV_F64, RTLIB::impl___divdf3},
      {RTLIB::REM_F64, RTLIB::impl_fmod},
      {RTLIB::MEMCPY, RTLIB::impl_memcpy},
      {RTLIB::MEMSET, RTLIB::impl_memset},
      {RTLIB::MEMMOVE, RTLIB::impl_memmove},
  };
  for (const auto &LC : LibraryCalls)
    Info.setLibcallImpl(LC.Op, LC.Impl);
}
