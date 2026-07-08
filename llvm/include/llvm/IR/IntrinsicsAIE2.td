//===- IntrinsicsAIE2.td - Defines AIE2 intrinsics ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Minimal AIE2 intrinsics: just the DMA lock ops needed for a scalar+DMA
// end-to-end kernel. Both take (lock_id, value) and have side effects.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "aie2" in {
  def int_aie2_acquire : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], []>;
  def int_aie2_release : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], []>;
  // Signals Core.Done. Used to terminate a self-contained core-entry kernel.
  def int_aie2_done    : Intrinsic<[], [], []>;
}
