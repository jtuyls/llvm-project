//===-- AIE2AsmPrinter.cpp - AIE2 LLVM assembly writer -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2.h"
#include "AIE2TargetMachine.h"
#include "MCTargetDesc/AIE2MCTargetDesc.h"
#include "TargetInfo/AIE2TargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

namespace {
class AIE2AsmPrinter : public AsmPrinter {
public:
  explicit AIE2AsmPrinter(TargetMachine &TM,
                          std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID) {}

  StringRef getPassName() const override { return "AIE2 Assembly Printer"; }
  void emitInstruction(const MachineInstr *MI) override;

  static char ID;
};
} // namespace

char AIE2AsmPrinter::ID = 0;

static MCOperand lowerOperand(const MachineOperand &MO) {
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    if (MO.isImplicit())
      return MCOperand();
    return MCOperand::createReg(MO.getReg());
  case MachineOperand::MO_Immediate:
    return MCOperand::createImm(MO.getImm());
  default:
    return MCOperand();
  }
}

void AIE2AsmPrinter::emitInstruction(const MachineInstr *MI) {
  MCInst TmpInst;
  TmpInst.setOpcode(MI->getOpcode());
  for (const MachineOperand &MO : MI->operands()) {
    MCOperand MCOp = lowerOperand(MO);
    if (MCOp.isValid())
      TmpInst.addOperand(MCOp);
  }
  EmitToStreamer(*OutStreamer, TmpInst);

  // AIE branches/returns have 5 delay slots. This minimal (non-bundled) target
  // does not schedule useful work into them, so pad with 5 NOPs. The preceding
  // instructions already executed, so the shadow NOPs are semantically inert.
  // Encodings differ between aie2 and aie2p (RET/NOP), so pick per subtarget.
  unsigned Op = MI->getOpcode();
  if (Op == AIE2::RET || Op == AIE2::RET_P) {
    MCInst Nop;
    Nop.setOpcode(Op == AIE2::RET_P ? AIE2::NOP_P : AIE2::NOP);
    for (unsigned i = 0; i < 5; ++i)
      EmitToStreamer(*OutStreamer, Nop);
  }
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeAIE2AsmPrinter() {
  RegisterAsmPrinter<AIE2AsmPrinter> X(getTheAIE2Target());
}
