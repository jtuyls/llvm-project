//===-- AIE2MCAsmInfo.cpp - AIE2 Asm Info ---------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/AIE2MCAsmInfo.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

AIE2MCAsmInfo::AIE2MCAsmInfo(const Triple &TT, const MCTargetOptions &Options)
    : MCAsmInfoELF(Options) {
  CommentString = "//";
  // LLVM 23 renamed the private-label prefix field to InternalSymbolPrefix
  // (default "L"); the default is fine for this minimal target.
  Data16bitsDirective = "\t.half\t";
  Data32bitsDirective = "\t.word\t";
}
