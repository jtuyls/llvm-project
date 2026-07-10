--- |
  ; ModuleID = 'llvm/test/CodeGen/AIE/aie2/GlobalISel/irtranslator-call-arguments-bfloat16.ll'
  source_filename = "llvm/test/CodeGen/AIE/aie2/GlobalISel/irtranslator-call-arguments-bfloat16.ll"
  target datalayout = "e-m:e-p:20:32-i1:8:32-i8:8:32-i16:16:32-i32:32:32-f32:32:32-i64:32-f64:32-a:0:32-n32"
  target triple = "aie2"
  
  %class.bfloat16 = type { bfloat }
  
  define dso_local void @_Z17test_get_bfloat16v() local_unnamed_addr {
  entry:
    %call = tail call %class.bfloat16 @_Z12ret_bfloat168bfloat16(%class.bfloat16 undef)
    ret void
  }
  
  declare dso_local %class.bfloat16 @_Z12ret_bfloat168bfloat16(%class.bfloat16) local_unnamed_addr
  
  define dso_local void @_Z20test_pass_v2bfloat16v() local_unnamed_addr {
  entry:
    %ret = alloca <2 x bfloat>, align 4
    %call = tail call noundef <2 x bfloat> @_Z15test_v2bfloat16Dv2_u6__bf16(<2 x bfloat> noundef undef)
    store volatile <2 x bfloat> %call, ptr %ret, align 4
    ret void
  }
  
  declare dso_local noundef <2 x bfloat> @_Z15test_v2bfloat16Dv2_u6__bf16(<2 x bfloat> noundef) local_unnamed_addr
  
  define dso_local void @_Z20test_pass_v4bfloat16v() local_unnamed_addr {
  entry:
    %ret = alloca <4 x bfloat>, align 8
    %call = tail call noundef <4 x bfloat> @_Z15test_v4bfloat16Dv4_u6__bf16(<4 x bfloat> noundef undef)
    store volatile <4 x bfloat> %call, ptr %ret, align 8
    ret void
  }
  
  declare dso_local noundef <4 x bfloat> @_Z15test_v4bfloat16Dv4_u6__bf16(<4 x bfloat> noundef) local_unnamed_addr
  
  define void @_Z20test_call_v8bfloat16v() {
  entry:
    %call = alloca <8 x bfloat>, align 16
    %0 = load volatile <8 x bfloat>, ptr %call, align 16
    %call1 = call noundef <8 x bfloat> @_Z14take_v8bfloat16Dv8_u6__bf16(<8 x bfloat> noundef %0)
    ret void
  }
  
  declare <8 x bfloat> @_Z14take_v8bfloat16Dv8_u6__bf16(<8 x bfloat> noundef)
  
  define void @_Z21test_call_v16bfloat16v() {
  entry:
    %call = alloca <16 x bfloat>, align 32
    %0 = load volatile <16 x bfloat>, ptr %call, align 32
    %call1 = call noundef <16 x bfloat> @_Z15take_v16bfloat16Dv16_u6__bf16(<16 x bfloat> noundef %0)
    ret void
  }
  
  declare <16 x bfloat> @_Z15take_v16bfloat16Dv16_u6__bf16(<16 x bfloat> noundef)
  
  define void @_Z21test_call_v32bfloat16v() {
  entry:
    %call = alloca <32 x bfloat>, align 64
    %0 = load volatile <32 x bfloat>, ptr %call, align 64
    %call1 = call noundef <32 x bfloat> @_Z15take_v32bfloat16Dv32_u6__bf16(<32 x bfloat> noundef %0)
    ret void
  }
  
  declare <32 x bfloat> @_Z15take_v32bfloat16Dv32_u6__bf16(<32 x bfloat> noundef)
  
  define void @_Z21test_call_v64bfloat16v() {
  entry:
    %call = alloca <64 x bfloat>, align 128
    %0 = load volatile <64 x bfloat>, ptr %call, align 128
    %call1 = call noundef <64 x bfloat> @_Z15take_v64bfloat16Dv64_u6__bf16(<64 x bfloat> noundef %0)
    ret void
  }
  
  declare <64 x bfloat> @_Z15take_v64bfloat16Dv64_u6__bf16(<64 x bfloat> noundef)

...
---
name:            _Z17test_get_bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    1
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     true
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:           []
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %1:_(s16) = G_IMPLICIT_DEF
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    %2:_(s32) = G_ANYEXT %1(s16)
    $r1 = COPY %2(s32)
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    PseudoJ_TCO_jump_imm @_Z12ret_bfloat168bfloat16, csr_aie2, implicit $r1

...
---
name:            _Z20test_pass_v2bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    4
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: ret, type: default, offset: 0, size: 4, alignment: 4, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %2:_(<2 x s16>) = G_IMPLICIT_DEF
    %0:_(p0) = G_FRAME_INDEX %stack.0.ret
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    $r1 = COPY %2(<2 x s16>)
    PseudoJL @_Z15test_v2bfloat16Dv2_u6__bf16, csr_aie2, implicit-def $lr, implicit $r1, implicit-def $r0
    %1:_(<2 x s16>) = COPY $r0
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    G_STORE %1(<2 x s16>), %0(p0) :: (volatile store (<2 x s16>) into %ir.ret)
    PseudoRET implicit $lr

...
---
name:            _Z20test_pass_v4bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    8
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: ret, type: default, offset: 0, size: 8, alignment: 8, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %2:_(<4 x s16>) = G_IMPLICIT_DEF
    %0:_(p0) = G_FRAME_INDEX %stack.0.ret
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    $l1 = COPY %2(<4 x s16>)
    PseudoJL @_Z15test_v4bfloat16Dv4_u6__bf16, CustomRegMask($lr,$l2,$l3,$p6,$p7,$r20,$r21,$r22,$r23), implicit-def $lr, implicit $l1, implicit-def $l0
    %1:_(<4 x s16>) = COPY $l0
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    G_STORE %1(<4 x s16>), %0(p0) :: (volatile store (<4 x s16>) into %ir.ret)
    PseudoRET implicit $lr

...
---
name:            _Z20test_call_v8bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
  - { id: 3, class: _, preferred-register: '', flags: [  ] }
  - { id: 4, class: _, preferred-register: '', flags: [  ] }
  - { id: 5, class: _, preferred-register: '', flags: [  ] }
  - { id: 6, class: _, preferred-register: '', flags: [  ] }
  - { id: 7, class: _, preferred-register: '', flags: [  ] }
  - { id: 8, class: _, preferred-register: '', flags: [  ] }
  - { id: 9, class: _, preferred-register: '', flags: [  ] }
  - { id: 10, class: _, preferred-register: '', flags: [  ] }
  - { id: 11, class: _, preferred-register: '', flags: [  ] }
  - { id: 12, class: _, preferred-register: '', flags: [  ] }
  - { id: 13, class: _, preferred-register: '', flags: [  ] }
  - { id: 14, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    16
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: call, type: default, offset: 0, size: 16, alignment: 16, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %0:_(p0) = G_FRAME_INDEX %stack.0.call
    %1:_(<8 x s16>) = G_LOAD %0(p0) :: (volatile dereferenceable load (<8 x s16>) from %ir.call)
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    %4:_(s16), %5:_(s16), %6:_(s16), %7:_(s16), %8:_(s16), %9:_(s16), %10:_(s16), %11:_(s16) = G_UNMERGE_VALUES %1(<8 x s16>)
    %12:_(s16) = G_IMPLICIT_DEF
    %3:_(<16 x s16>) = G_BUILD_VECTOR %4(s16), %5(s16), %6(s16), %7(s16), %8(s16), %9(s16), %10(s16), %11(s16), %12(s16), %12(s16), %12(s16), %12(s16), %12(s16), %12(s16), %12(s16), %12(s16)
    $wl2 = COPY %3(<16 x s16>)
    PseudoJL @_Z14take_v8bfloat16Dv8_u6__bf16, csr_aie2, implicit-def $lr, implicit $wl2, implicit-def $wl0
    %13:_(<16 x s16>) = COPY $wl0
    %2:_(<8 x s16>), %14:_(<8 x s16>) = G_UNMERGE_VALUES %13(<16 x s16>)
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    PseudoRET implicit $lr

...
---
name:            _Z21test_call_v16bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    32
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: call, type: default, offset: 0, size: 32, alignment: 32, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %0:_(p0) = G_FRAME_INDEX %stack.0.call
    %1:_(<16 x s16>) = G_LOAD %0(p0) :: (volatile dereferenceable load (<16 x s16>) from %ir.call)
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    $wl2 = COPY %1(<16 x s16>)
    PseudoJL @_Z15take_v16bfloat16Dv16_u6__bf16, csr_aie2, implicit-def $lr, implicit $wl2, implicit-def $wl0
    %2:_(<16 x s16>) = COPY $wl0
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    PseudoRET implicit $lr

...
---
name:            _Z21test_call_v32bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    64
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: call, type: default, offset: 0, size: 64, alignment: 64, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %0:_(p0) = G_FRAME_INDEX %stack.0.call
    %1:_(<32 x s16>) = G_LOAD %0(p0) :: (volatile dereferenceable load (<32 x s16>) from %ir.call)
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    $x2 = COPY %1(<32 x s16>)
    PseudoJL @_Z15take_v32bfloat16Dv32_u6__bf16, csr_aie2, implicit-def $lr, implicit $x2, implicit-def $x0
    %2:_(<32 x s16>) = COPY $x0
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    PseudoRET implicit $lr

...
---
name:            _Z21test_call_v64bfloat16v
alignment:       16
exposesReturnsTwice: false
legalized:       false
regBankSelected: false
selected:        false
failedISel:      false
tracksRegLiveness: true
hasWinCFI:       false
noPhis:          false
isSSA:           true
noVRegs:         false
hasFakeUses:     false
callsEHReturn:   false
callsUnwindInit: false
hasEHContTarget:   false
hasEHScopes:     false
hasEHFunclets:   false
isOutlined:      false
debugInstrRef:   false
failsVerification: false
tracksDebugUserValues: false
registers:
  - { id: 0, class: _, preferred-register: '', flags: [  ] }
  - { id: 1, class: _, preferred-register: '', flags: [  ] }
  - { id: 2, class: _, preferred-register: '', flags: [  ] }
liveins:         []
frameInfo:
  isFrameAddressTaken: false
  isReturnAddressTaken: false
  hasStackMap:     false
  hasPatchPoint:   false
  stackSize:       0
  offsetAdjustment: 0
  maxAlignment:    128
  adjustsStack:    false
  hasCalls:        false
  stackProtector:  ''
  functionContext: ''
  maxCallFrameSize: 4294967295
  cvBytesOfCalleeSavedRegisters: 0
  hasOpaqueSPAdjustment: false
  hasVAStart:      false
  hasMustTailInVarArgFunc: false
  hasTailCall:     false
  isCalleeSavedInfoValid: false
  localFrameSize:  0
fixedStack:      []
stack:
  - { id: 0, name: call, type: default, offset: 0, size: 128, alignment: 128, 
      stack-id: default, callee-saved-register: '', callee-saved-restored: true, 
      debug-info-variable: '', debug-info-expression: '', debug-info-location: '' }
entry_values:    []
callSites:       []
debugValueSubstitutions: []
constants:       []
machineFunctionInfo:
  varArgsFrameIndex: 0
body:             |
  bb.1.entry:
    %0:_(p0) = G_FRAME_INDEX %stack.0.call
    %1:_(<64 x s16>) = G_LOAD %0(p0) :: (volatile dereferenceable load (<64 x s16>) from %ir.call)
    ADJCALLSTACKUP 0, 0, implicit-def $sp, implicit $sp
    $y3 = COPY %1(<64 x s16>)
    PseudoJL @_Z15take_v64bfloat16Dv64_u6__bf16, csr_aie2, implicit-def $lr, implicit $y3, implicit-def $y2
    %2:_(<64 x s16>) = COPY $y2
    ADJCALLSTACKDOWN 0, 0, implicit-def $sp, implicit $sp
    PseudoRET implicit $lr

...
