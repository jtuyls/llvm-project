//===-- AIE2ISelLowering.cpp - AIE2 DAG Lowering Implementation ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2ISelLowering.h"
#include "AIE2.h"
#include "AIE2RegisterInfo.h"
#include "AIE2Subtarget.h"
#include "MCTargetDesc/AIE2MCTargetDesc.h" // AIE2::SP/R0.. register enums
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"

using namespace llvm;

#define GET_CALLING_CONV_IMPL
#include "AIE2GenCallingConv.inc"

AIE2TargetLowering::AIE2TargetLowering(const TargetMachine &TM,
                                       const AIE2Subtarget &STI)
    : TargetLowering(TM, STI) {
  // The whole point: the only value type this target needs is standard i32.
  // No i48, no i20 -- pointers are i32 too.
  addRegisterClass(MVT::i32, &AIE2::GPRRegClass);

  setStackPointerRegisterToSaveRestore(AIE2::SP);
  computeRegisterProperties(STI.getRegisterInfo());

  setBooleanContents(ZeroOrOneBooleanContent);
}

const char *AIE2TargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  case AIE2ISD::RET_GLUE:
    return "AIE2ISD::RET_GLUE";
  default:
    return nullptr;
  }
}

SDValue AIE2TargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_AIE2);

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    const CCValAssign &VA = ArgLocs[i];
    if (VA.isRegLoc()) {
      // Pointer arguments live in eP (PTR); plain integers in eR (GPR). Match
      // the vreg class to the assigned physical register so the load/store
      // address is already in an eP register (no cross-class copy needed).
      const TargetRegisterClass *RC =
          AIE2::PTRRegClass.contains(VA.getLocReg()) ? &AIE2::PTRRegClass
                                                     : &AIE2::GPRRegClass;
      Register VReg = RegInfo.createVirtualRegister(RC);
      RegInfo.addLiveIn(VA.getLocReg(), VReg);
      InVals.push_back(DAG.getCopyFromReg(Chain, DL, VReg, VA.getLocVT()));
    } else {
      // Stack argument.
      int FI = MF.getFrameInfo().CreateFixedObject(4, VA.getLocMemOffset(),
                                                   /*IsImmutable=*/true);
      SDValue FIN = DAG.getFrameIndex(FI, MVT::i32);
      InVals.push_back(DAG.getLoad(VA.getLocVT(), DL, Chain, FIN,
                                   MachinePointerInfo::getFixedStack(MF, FI)));
    }
  }
  return Chain;
}

SDValue
AIE2TargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                bool IsVarArg,
                                const SmallVectorImpl<ISD::OutputArg> &Outs,
                                const SmallVectorImpl<SDValue> &OutVals,
                                const SDLoc &DL, SelectionDAG &DAG) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());
  CCInfo.AnalyzeReturn(Outs, RetCC_AIE2);

  SDValue Glue;
  SmallVector<SDValue, 4> RetOps(1, Chain);
  for (unsigned i = 0, e = RVLocs.size(); i != e; ++i) {
    CCValAssign &VA = RVLocs[i];
    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), OutVals[i], Glue);
    Glue = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain;
  if (Glue.getNode())
    RetOps.push_back(Glue);

  return DAG.getNode(AIE2ISD::RET_GLUE, DL, MVT::Other, RetOps);
}
