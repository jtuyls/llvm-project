//===-- AIE2AsmBackend.cpp - AIE2 assembler backend ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// Minimal backend: no fixups/relaxation yet (the scalar subset is self-
// contained). NOP padding uses the real 2-byte `nop` (0x0001).
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/AIE2MCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/Support/EndianStream.h"

using namespace llvm;

namespace {
class AIE2AsmBackend : public MCAsmBackend {
public:
  AIE2AsmBackend() : MCAsmBackend(llvm::endianness::little) {}

  void applyFixup(const MCFragment &, const MCFixup &, const MCValue &,
                  uint8_t *, uint64_t, bool) override {}

  std::unique_ptr<MCObjectTargetWriter>
  createObjectTargetWriter() const override {
    return createAIE2ELFObjectWriter(/*OSABI=*/0);
  }

  bool writeNopData(raw_ostream &OS, uint64_t Count,
                    const MCSubtargetInfo *) const override {
    if (Count % 2 != 0)
      return false;
    for (uint64_t I = 0; I < Count; I += 2)
      support::endian::write<uint16_t>(OS, 0x0001, llvm::endianness::little);
    return true;
  }
};
} // namespace

MCAsmBackend *llvm::createAIE2AsmBackend(const Target &, const MCSubtargetInfo &,
                                         const MCRegisterInfo &,
                                         const MCTargetOptions &) {
  return new AIE2AsmBackend();
}
