//===-- AIE2.td - Describe the AIE2 Target ------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

include "AIE2RegisterInfo.td"
include "AIE2CallingConv.td"
include "AIE2InstrInfo.td"

def AIE2InstrInfo : InstrInfo;

// Map the generic pseudo-instructions' pointer operands (ptr_rc) to our GPR
// class. This is the idiomatic LLVM-23 mechanism -- no core emitter change
// needed (contrast the fork, which reverted the InstrInfoEmitter hardening).
defm : RemapAllTargetPseudoPointerOperands<GPR>;

def : ProcessorModel<"aie2", NoSchedModel, []>;

def AIE2AsmWriter : AsmWriter {
  let AsmWriterClassName = "InstPrinter";
  let PassSubtarget = 0;
}

def AIE2 : Target {
  let InstructionSet = AIE2InstrInfo;
  let AssemblyWriters = [AIE2AsmWriter];
}
