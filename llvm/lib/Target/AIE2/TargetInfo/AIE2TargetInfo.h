//===-- AIE2TargetInfo.h - AIE2 Target Info ---------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE2_TARGETINFO_AIE2TARGETINFO_H
#define LLVM_LIB_TARGET_AIE2_TARGETINFO_AIE2TARGETINFO_H

namespace llvm {
class Target;
Target &getTheAIE2Target();
} // namespace llvm

#endif
