//===-- AIE2ELFObjectWriter.cpp - AIE2 ELF writer ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// EM_AIE, ELF32, little-endian -- matching base llvm-aie's object format.
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/AIE2MCTargetDesc.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCELFObjectWriter.h"

using namespace llvm;

namespace {
class AIE2ELFObjectWriter : public MCELFObjectTargetWriter {
public:
  explicit AIE2ELFObjectWriter(uint8_t OSABI)
      : MCELFObjectTargetWriter(/*Is64Bit=*/false, OSABI, ELF::EM_AIE,
                                /*HasRelocationAddend=*/true) {}
  ~AIE2ELFObjectWriter() override = default;

protected:
  unsigned getRelocType(const MCFixup &, const MCValue &,
                        bool /*IsPCRel*/) const override {
    // No relocations are exercised by the scalar subset yet (R_*_NONE == 0).
    return 0;
  }
};
} // namespace

std::unique_ptr<MCObjectTargetWriter>
llvm::createAIE2ELFObjectWriter(uint8_t OSABI) {
  return std::make_unique<AIE2ELFObjectWriter>(OSABI);
}
