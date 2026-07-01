//===- llvm/CodeGen/GlobalISel/GISelKnownBits.h ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// amd/aie/ port shim: LLVM 23 renamed GISelKnownBits -> GISelValueTracking
/// and the legacy pass GISelKnownBitsAnalysis -> GISelValueTrackingAnalysisLegacy.
/// The AIE backend (ported from LLVM 21) still refers to the old names, so we
/// alias them here and forward the legacy pass-initialization symbol.
//===----------------------------------------------------------------------===//

#ifndef LLVM_CODEGEN_GLOBALISEL_GISELKNOWNBITS_H
#define LLVM_CODEGEN_GLOBALISEL_GISELKNOWNBITS_H

#include "llvm/CodeGen/GlobalISel/GISelValueTracking.h"
#include "llvm/InitializePasses.h"
#include "llvm/PassRegistry.h"

namespace llvm {

using GISelKnownBits = GISelValueTracking;
using GISelKnownBitsAnalysis = GISelValueTrackingAnalysisLegacy;

// INITIALIZE_PASS_DEPENDENCY(GISelKnownBitsAnalysis) expands to a call to
// initializeGISelKnownBitsAnalysisPass; forward it to the renamed symbol.
inline void initializeGISelKnownBitsAnalysisPass(PassRegistry &Registry) {
  initializeGISelValueTrackingAnalysisLegacyPass(Registry);
}

} // namespace llvm

#endif // LLVM_CODEGEN_GLOBALISEL_GISELKNOWNBITS_H
