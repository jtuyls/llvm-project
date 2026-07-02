//===--  AIEDisassemblerPP.h - Disassembler Preprocessor Macros for AIE --===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2024 Advanced Micro Devices, Inc. or its affiliates
//
//===---------------------------------------------------------------------===//
//
// This file defines common PP for AIEx
//
//===---------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_AIE_DISASSEMBLER_AIEPP_H
#define LLVM_LIB_TARGET_AIE_DISASSEMBLER_AIEPP_H

#define TABLEBASEDDECODER2(ClassName, TableClassName)                          \
  static DecodeStatus Decode##ClassName##RegisterClass(                        \
      MCInst &Inst, uint64_t RegNo, uint64_t Address,                          \
      const MCDisassembler *Decoder) {                                         \
    if (RegNo >= std::size(TableClassName##DecoderTable))                      \
      return MCDisassembler::Fail;                                             \
    unsigned Reg = TableClassName##DecoderTable[RegNo];                        \
    LLVM_DEBUG(dbgs() << "RegEnc=" << RegNo << " Reg=" << Reg << "\n");        \
    if (!Reg)                                                                  \
      return MCDisassembler::Fail;                                             \
    Inst.addOperand(MCOperand::createReg(Reg));                                \
    return MCDisassembler::Success;                                            \
  }

#define TABLEBASEDDECODER(ClassName) TABLEBASEDDECODER2(ClassName, ClassName)

// amd/aie/ port: LLVM 23 dropped MCDisassembler::decodeSingletonRegClass and
// emits 2-argument singleton register decoders (MCInst&, const MCDisassembler*).
#define FIXEDREGDECODER(ClassName)                                             \
  static DecodeStatus Decode##ClassName##RegisterClass(                        \
      MCInst &Inst, const MCDisassembler *Decoder) {                           \
    if (ClassName##RegClass.getNumRegs() != 1)                                 \
      return MCDisassembler::Fail;                                             \
    Inst.addOperand(MCOperand::createReg(ClassName##RegClass.getRegister(0))); \
    return MCDisassembler::Success;                                            \
  }

#define SLOTDECODERDecl(ClassName)                                             \
  template <typename InsnType>                                                 \
  static DecodeStatus decode##ClassName##Slot(MCInst &MI, InsnType &Insn,      \
                                              int64_t Address,                 \
                                              const MCDisassembler *Decoder)

#endif // LLVM_LIB_TARGET_AIE_DISASSEMBLER_AIEPP_H
