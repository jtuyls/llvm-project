; RUN: llc -mtriple=aie2 -filetype=asm < %s | FileCheck %s

; Minimal AIE2 target smoke test: scalar i32 arithmetic, returns, and a load
; through an i32 pointer. The whole point of this target is that NONE of this
; needs i48/i20 or a non-pow2 (p:20) pointer -- everything is standard i32.

; CHECK-LABEL: ret_const:
; CHECK: mov r0, #42
; CHECK: ret
define i32 @ret_const() {
  ret i32 42
}

; CHECK-LABEL: add:
; CHECK: add r0, r0, r1
; CHECK: ret
define i32 @add(i32 %a, i32 %b) {
  %s = add i32 %a, %b
  ret i32 %s
}

; CHECK-LABEL: three_ops:
; CHECK: add r0, r0, r1
; CHECK: sub r0, r0, r2
; CHECK: ret
define i32 @three_ops(i32 %a, i32 %b, i32 %c) {
  %t = add i32 %a, %b
  %u = sub i32 %t, %c
  ret i32 %u
}

; The pointer argument is a plain i32 in a GPR -- proof that p:32 pointers work
; with no non-pow2 pointer machinery.
; CHECK-LABEL: load_ptr:
; CHECK: lw r0, [r0]
; CHECK: ret
define i32 @load_ptr(ptr %p) {
  %v = load i32, ptr %p
  ret i32 %v
}
