; This file is licensed under the Apache License v2.0 with LLVM Exceptions.
; See https://llvm.org/LICENSE.txt for license information.
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;
; (c) Copyright 2026 Advanced Micro Devices, Inc. or its affiliates
;
; GlobalISel maps <1 x T> to the scalar LLT T, so in LLVM 21 a shufflevector on
; <1 x T> reached MIR as a G_SHUFFLE_VECTOR with a scalar source. LLVM 23's
; IRTranslator now rewrites those into G_BUILD_VECTOR / G_EXTRACT_VECTOR_ELT /
; COPY, and the MachineVerifier rejects a scalar-source G_SHUFFLE_VECTOR
; outright ("G_SHUFFLE_VECTOR must have vector src").
;
; The MIR tests that fed scalar-source shuffles directly to the combiner and
; legalizer therefore cannot be expressed any more. This test pins the same
; behaviour where it is still reachable -- from IR -- and asserts that the
; broadcasts still select to vbcst, i.e. that losing the scalar-source shuffle
; path costs nothing. Output here is identical to llvm-aie's.

; RUN: llc -mtriple aie2p -global-isel %s -o - | FileCheck %s

; Splat of a <1 x i64> across <8 x i64>: was shuffle_vector_scalar_src_s64 /
; shuffle_vector_scalar_s64_to_8xs64.
; CHECK-LABEL: splat_s64_from_1elt:
; CHECK: vbcst.64
define void @splat_s64_from_1elt(i64 %s, ptr %out) {
  %v = insertelement <1 x i64> poison, i64 %s, i32 0
  %r = shufflevector <1 x i64> %v, <1 x i64> poison, <8 x i32> zeroinitializer
  store <8 x i64> %r, ptr %out
  ret void
}

; Splat of a <1 x i32> across <16 x i32>: was shuffle_vector_scalar_src_s32 /
; shuffle_vector_scalar_src_s32_elt0.
; CHECK-LABEL: splat_s32_from_1elt:
; CHECK: vbcst.32
define void @splat_s32_from_1elt(i32 %s, ptr %out) {
  %v = insertelement <1 x i32> poison, i32 %s, i32 0
  %r = shufflevector <1 x i32> %v, <1 x i32> poison, <16 x i32> zeroinitializer
  store <16 x i32> %r, ptr %out
  ret void
}

; A mask selecting only the second source: was shuffle_vector_second_src_scalar.
; The broadcast must come from %b, not %a.
; CHECK-LABEL: splat_s64_second_src:
; CHECK: vbcst.64 {{.*}}r3:r2
define void @splat_s64_second_src(i64 %a, i64 %b, ptr %out) {
  %v0 = insertelement <1 x i64> poison, i64 %a, i32 0
  %v1 = insertelement <1 x i64> poison, i64 %b, i32 0
  %r = shufflevector <1 x i64> %v0, <1 x i64> %v1,
                     <8 x i32> <i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
  store <8 x i64> %r, ptr %out
  ret void
}

; <1 x T> in, <1 x T> out, mask (0): degenerates to a copy of the first source.
; Was shuffle_vector_to_copy_scalar.
; CHECK-LABEL: shuffle_1elt_to_copy:
; CHECK-NOT: vbcst
define void @shuffle_1elt_to_copy(i32 %a, i32 %b, ptr %out) {
  %v0 = insertelement <1 x i32> poison, i32 %a, i32 0
  %v1 = insertelement <1 x i32> poison, i32 %b, i32 0
  %r = shufflevector <1 x i32> %v0, <1 x i32> %v1, <1 x i32> zeroinitializer
  store <1 x i32> %r, ptr %out
  ret void
}

; Two scalar sources combined into a <2 x i16>: was test_shuffle_vec_16_to_32 in
; legalize-shuffle-vector.mir. IRTranslator turns this into a G_BUILD_VECTOR.
; CHECK-LABEL: shuffle_1elt_srcs_to_v2:
define void @shuffle_1elt_srcs_to_v2(i16 %a, i16 %b, ptr %out) {
  %v0 = insertelement <1 x i16> poison, i16 %a, i32 0
  %v1 = insertelement <1 x i16> poison, i16 %b, i32 0
  %r = shufflevector <1 x i16> %v0, <1 x i16> %v1, <2 x i32> <i32 1, i32 0>
  store <2 x i16> %r, ptr %out
  ret void
}
