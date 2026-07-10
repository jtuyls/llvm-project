//===-- llvm/CodeGen/AllocationOrder.cpp - Allocation Order ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements an allocation order for virtual registers.
//
// The preferred allocation order for a virtual register depends on allocation
// hints and target hooks. The AllocationOrder class encapsulates all of that.
//
//===----------------------------------------------------------------------===//

#include "AllocationOrder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterClassInfo.h"
#include "llvm/CodeGen/VirtRegMap.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "regalloc"

// Compare VirtRegMap::getRegAllocPref().
// amd/aie/ port: singleton / copy ctors for the required-physreg order.
AllocationOrder::AllocationOrder(MCPhysReg RequiredReg) : IterationLimit(1) {
  OrderScratch = {RequiredReg};
  Order = OrderScratch;
}

AllocationOrder::AllocationOrder(const AllocationOrder &A)
    : Hints(A.Hints), IterationLimit(A.IterationLimit) {
  if (A.OrderScratch.empty()) {
    Order = A.Order;
  } else {
    OrderScratch = A.OrderScratch;
    Order = OrderScratch;
  }
}

AllocationOrder AllocationOrder::create(Register VirtReg, const VirtRegMap &VRM,
                                        const RegisterClassInfo &RegClassInfo,
                                        const LiveRegMatrix *Matrix) {
  // amd/aie/ port: a target may pin a virtual register to one physical register
  // (VirtRegMap::setRequiredPhys). AIE does this for the sub-registers of its
  // composite addressing tuples, which are jointly encoded and have no
  // composite load/store, so the pieces must land in a matching super-register.
  // The VirtRegMap API survived the port but every consumer of it was dropped,
  // so the requirement was silently ignored and greedy assigned unrelated
  // registers (e.g. $dn1/$dj1/$dc2 instead of $dn4/$dj4/$dc4), which then
  // asserted in AIESplitInstructionRewriter's getMatchingSuperReg().
  // No upstream target calls setRequiredPhys, so this is inert for them.
  if (VRM.hasRequiredPhys(VirtReg))
    return AllocationOrder(MCPhysReg(VRM.getRequiredPhys(VirtReg)));

  const MachineFunction &MF = VRM.getMachineFunction();
  const TargetRegisterInfo *TRI = &VRM.getTargetRegInfo();
  auto Order = RegClassInfo.getOrder(MF.getRegInfo().getRegClass(VirtReg));
  SmallVector<MCPhysReg, 16> Hints;
  bool HardHints =
      TRI->getRegAllocationHints(VirtReg, Order, Hints, MF, &VRM, Matrix);

  LLVM_DEBUG({
    if (!Hints.empty()) {
      dbgs() << "hints:";
      for (MCPhysReg Hint : Hints)
        dbgs() << ' ' << printReg(Hint, TRI);
      dbgs() << '\n';
    }
  });
  assert(all_of(Hints,
                [&](MCPhysReg Hint) { return is_contained(Order, Hint); }) &&
         "Target hint is outside allocation order.");
  return AllocationOrder(std::move(Hints), Order, HardHints);
}
