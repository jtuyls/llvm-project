//===-- AIE2MCCodeEmitter.cpp - AIE2 instruction encoding ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Emits the TableGen'd instruction encoding as `Size` little-endian bytes.
// AIE2 instructions are variable length (2 or 4 bytes for the scalar subset).
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/AIE2MCTargetDesc.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"

using namespace llvm;

namespace {
class AIE2MCCodeEmitter : public MCCodeEmitter {
  const MCInstrInfo &MCII;
  MCContext &Ctx;

public:
  AIE2MCCodeEmitter(const MCInstrInfo &mcii, MCContext &ctx)
      : MCII(mcii), Ctx(ctx) {}
  AIE2MCCodeEmitter(const AIE2MCCodeEmitter &) = delete;
  AIE2MCCodeEmitter &operator=(const AIE2MCCodeEmitter &) = delete;

  // TableGen'erated (-gen-emitter).
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const;

  // Operand encoder used by the generated code.
  unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &STI) const;

  void encodeInstruction(const MCInst &MI, SmallVectorImpl<char> &CB,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override {
    uint64_t Bits = getBinaryCodeForInstr(MI, Fixups, STI);
    unsigned Size = MCII.get(MI.getOpcode()).getSize();
    // Little-endian, matching base llvm-aie's object layout.
    for (unsigned I = 0; I < Size; ++I)
      CB.push_back(static_cast<char>((Bits >> (I * 8)) & 0xff));
  }
};
} // namespace

unsigned
AIE2MCCodeEmitter::getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                                     SmallVectorImpl<MCFixup> &Fixups,
                                     const MCSubtargetInfo &STI) const {
  if (MO.isReg())
    return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());
  if (MO.isImm())
    return static_cast<unsigned>(MO.getImm());
  return 0;
}

MCCodeEmitter *llvm::createAIE2MCCodeEmitter(const MCInstrInfo &MCII,
                                             MCContext &Ctx) {
  return new AIE2MCCodeEmitter(MCII, Ctx);
}

#include "AIE2GenMCCodeEmitter.inc"
