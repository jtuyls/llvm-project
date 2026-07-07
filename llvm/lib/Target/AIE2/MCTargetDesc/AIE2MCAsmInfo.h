//===-- AIE2MCAsmInfo.h - AIE2 Asm Info -------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_MCTARGETDESC_AIE2MCASMINFO_H
#define LLVM_LIB_TARGET_AIE2_MCTARGETDESC_AIE2MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;
class MCTargetOptions;

class AIE2MCAsmInfo : public MCAsmInfoELF {
public:
  explicit AIE2MCAsmInfo(const Triple &TT, const MCTargetOptions &Options);
};
} // namespace llvm

#endif
