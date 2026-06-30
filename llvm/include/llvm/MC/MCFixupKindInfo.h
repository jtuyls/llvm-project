//===-- llvm/MC/MCFixupKindInfo.h - amd/aie/ port forwarding ----*- C++ -*-===//
// In LLVM 23 MCFixupKindInfo lives in MCAsmBackend.h. AIE code includes this
// path (it was a separate header on LLVM 21); forward to avoid a redefinition.
#ifndef LLVM_MC_MCFIXUPKINDINFO_H
#define LLVM_MC_MCFIXUPKINDINFO_H
#include "llvm/MC/MCAsmBackend.h"
#endif
