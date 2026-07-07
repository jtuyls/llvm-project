//===-- AIE2MCTargetDesc.h - AIE2 Target Descriptions ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_MCTARGETDESC_AIE2MCTARGETDESC_H
#define LLVM_LIB_TARGET_AIE2_MCTARGETDESC_AIE2MCTARGETDESC_H

// Defines symbolic names for AIE2 registers/instructions and the enums.
#define GET_REGINFO_ENUM
#include "AIE2GenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "AIE2GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "AIE2GenSubtargetInfo.inc"

#endif
