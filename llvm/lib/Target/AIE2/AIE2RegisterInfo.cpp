//===-- AIE2RegisterInfo.cpp - AIE2 Register Information ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2RegisterInfo.h"
#include "AIE2.h"
#include "AIE2FrameLowering.h" // complete type for generated static_cast in TargetDesc
#include "MCTargetDesc/AIE2MCTargetDesc.h" // GPRRegClassID and register enums
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_REGINFO_TARGET_DESC
#include "AIE2GenRegisterInfo.inc"

using namespace llvm;

AIE2RegisterInfo::AIE2RegisterInfo() : AIE2GenRegisterInfo(AIE2::LR) {}

const MCPhysReg *
AIE2RegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_AIE2_SaveList;
}

BitVector AIE2RegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(AIE2::SP);
  Reserved.set(AIE2::LR);
  return Reserved;
}

bool AIE2RegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                           int SPAdj, unsigned FIOperandNum,
                                           RegScavenger *RS) const {
  // Minimal: resolve FI to SP + offset folded into the following immediate
  // operand (all stack access goes through addi from SP).
  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  int FI = MI.getOperand(FIOperandNum).getIndex();
  int64_t Offset = MF.getFrameInfo().getObjectOffset(FI);
  MI.getOperand(FIOperandNum).ChangeToRegister(AIE2::SP, /*isDef=*/false);
  MI.getOperand(FIOperandNum + 1).setImm(MI.getOperand(FIOperandNum + 1).getImm() +
                                         Offset);
  return false;
}

Register AIE2RegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return AIE2::SP;
}
