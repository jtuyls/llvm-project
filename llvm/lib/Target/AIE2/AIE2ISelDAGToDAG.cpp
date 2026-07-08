//===-- AIE2ISelDAGToDAG.cpp - AIE2 DAG-to-DAG Instruction Selection ------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AIE2.h"
#include "AIE2Subtarget.h"
#include "AIE2TargetMachine.h"
#include "MCTargetDesc/AIE2MCTargetDesc.h" // AIE2::ADD/SUB/ADDI.. opcode enums
#include "llvm/CodeGen/SelectionDAGISel.h"

using namespace llvm;

#define DEBUG_TYPE "aie2-isel"

namespace {
class AIE2DAGToDAGISel : public SelectionDAGISel {
public:
  AIE2DAGToDAGISel() = delete;
  explicit AIE2DAGToDAGISel(AIE2TargetMachine &TM, CodeGenOptLevel OL)
      : SelectionDAGISel(TM, OL) {}

  bool runOnMachineFunction(MachineFunction &MF) override {
    // Needed by the generated predicate checks (Subtarget->isAIE2P()).
    Subtarget = &MF.getSubtarget<AIE2Subtarget>();
    return SelectionDAGISel::runOnMachineFunction(MF);
  }

  void Select(SDNode *Node) override;

  const AIE2Subtarget *Subtarget = nullptr;

#include "AIE2GenDAGISel.inc"
};

class AIE2DAGToDAGISelLegacy : public SelectionDAGISelLegacy {
public:
  static char ID;
  explicit AIE2DAGToDAGISelLegacy(AIE2TargetMachine &TM, CodeGenOptLevel OL)
      : SelectionDAGISelLegacy(
            ID, std::make_unique<AIE2DAGToDAGISel>(TM, OL)) {}
};
} // namespace

char AIE2DAGToDAGISelLegacy::ID = 0;

void AIE2DAGToDAGISel::Select(SDNode *Node) {
  if (Node->isMachineOpcode()) {
    Node->setNodeId(-1);
    return;
  }
  SelectCode(Node);
}

FunctionPass *llvm::createAIE2ISelDag(AIE2TargetMachine &TM) {
  return new AIE2DAGToDAGISelLegacy(TM, TM.getOptLevel());
}
