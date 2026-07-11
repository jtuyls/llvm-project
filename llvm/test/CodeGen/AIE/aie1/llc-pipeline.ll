;
; This file is licensed under the Apache License v2.0 with LLVM Exceptions.
; See https://llvm.org/LICENSE.txt for license information.
; SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
;
; (c) Copyright 2023-2024 Advanced Micro Devices, Inc. or its affiliates

; When EXPENSIVE_CHECKS are enabled, the machine verifier appears between each
; pass. Ignore it with 'grep -v'.

; RUN: llc -O0 -mtriple=aie -disable-verify -debug-pass=Structure < %s 2>&1 \
; RUN:   | grep -v 'Verify generated machine code' | FileCheck -match-full-lines -strict-whitespace -check-prefixes=AIE-O0,AIE-O0123 %s
; RUN: llc -O1 -mtriple=aie -disable-verify -debug-pass=Structure < %s 2>&1 \
; RUN:   | grep -v 'Verify generated machine code' | FileCheck -match-full-lines -strict-whitespace -check-prefixes=AIE-O123,AIE-O0123 %s
; RUN: llc -O2 -mtriple=aie -disable-verify -debug-pass=Structure < %s 2>&1 \
; RUN:   | grep -v 'Verify generated machine code' | FileCheck -match-full-lines -strict-whitespace -check-prefixes=AIE-O123,AIE-O0123 %s
; RUN: llc -O3 -mtriple=aie -disable-verify -debug-pass=Structure < %s 2>&1 \
; RUN:   | grep -v 'Verify generated machine code' | FileCheck -match-full-lines -strict-whitespace -check-prefixes=AIE-O123,AIE-O0123 %s

; REQUIRES: asserts

; AIE-O0:Pass Arguments:  -targetlibinfo -runtime-library-info -targetpassconfig -machinemoduleinfo -tti -libcall-lowering-info -collector-metadata -assumption-cache-tracker -profile-summary-info -machine-branch-prob -pre-isel-intrinsic-lowering -expand-ir-insts -atomic-expand -gc-lowering -shadow-stack-gc-lowering -unreachableblockelim -post-inline-ee-instrument -scalarize-masked-mem-intrin -expand-reductions -lowerinvoke -unreachableblockelim -inline-asm-prepare -safe-stack -stack-protector -domtree -basic-aa -aa -loops -postdomtree -branch-prob -debug-ata -lazy-branch-prob -lazy-block-freq -finalize-isel -localstackalloc -phi-node-elimination -twoaddressinstruction -regallocfast -removeredundantdebugvalues -fixup-statepoint-caller-saved -lazy-machine-block-freq -machine-opt-remark-emitter -prologepilog -postrapseudos -machinedomtree -machine-loops -post-RA-sched -finalize-mi-bundles -gc-analysis -fentry-insert -xray-instrumentation -patchable-function -aie-block-placement -funclet-layout -remove-loads-into-fake-uses -stackmap-liveness -livedebugvalues -machine-sanmd -lazy-machine-block-freq -machine-opt-remark-emitter -stack-frame-layout
; AIE-O123:Pass Arguments:  -targetlibinfo -runtime-library-info -targetpassconfig -machinemoduleinfo -tti -assumption-cache-tracker -libcall-lowering-info -aie-aa -external-aa -tbaa -scoped-noalias-aa -collector-metadata -profile-summary-info -machine-branch-prob -regalloc-evict -regalloc-priority -domtree -basic-aa -aa -objc-arc-contract -pre-isel-intrinsic-lowering -expand-ir-insts -atomic-expand -domtree -infer-address-spaces -basic-aa -loops -loop-simplify -scalar-evolution -canon-freeze -iv-users -loop-reduce -gc-lowering -shadow-stack-gc-lowering -unreachableblockelim -loops -postdomtree -branch-prob -block-freq -consthoist -replace-with-veclib -lazy-branch-prob -lazy-block-freq -opt-remark-emitter -partially-inline-libcalls -post-inline-ee-instrument -scalarize-masked-mem-intrin -expand-reductions -loops -postdomtree -branch-prob -block-freq -codegenprepare -lowerinvoke -unreachableblockelim -inline-asm-prepare -safe-stack -stack-protector -domtree -basic-aa -aa -loops -postdomtree -branch-prob -debug-ata -lazy-branch-prob -lazy-block-freq -finalize-isel -lazy-machine-block-freq -early-tailduplication -opt-phis -slotindexes -stack-coloring -localstackalloc -dead-mi-elimination -machinedomtree -machine-loops -machine-block-freq -early-machinelicm -machinedomtree -machine-block-freq -machine-cse -machinepostdomtree -machine-cycles -machine-sink -peephole-opt -dead-mi-elimination -detect-dead-lanes -init-undef -processimpdefs -unreachable-mbb-elimination -livevars -phi-node-elimination -twoaddressinstruction -machinedomtree -slotindexes -liveintervals -register-coalescer -rename-independent-subregs -machine-scheduler -livedebugvars -livestacks -virtregmap -liveregmatrix -edge-bundles -spill-code-placement -lazy-machine-block-freq -machine-opt-remark-emitter -greedy -virtregrewriter -regallocscoringpass -stack-slot-coloring -machine-cp -machinelicm -removeredundantdebugvalues -fixup-statepoint-caller-saved -postra-machine-sink -machine-block-freq -machinedomtree -machinepostdomtree -lazy-machine-block-freq -machine-opt-remark-emitter -shrink-wrap -prologepilog -machine-latecleanup -branch-folder -lazy-machine-block-freq -tailduplication -machine-cp -machine-cp -postrapseudos -machinedomtree -machine-loops -post-RA-sched -finalize-mi-bundles -gc-analysis -machinedomtree -machine-loops -machine-block-freq -machinepostdomtree -block-placement -fentry-insert -xray-instrumentation -patchable-function -aie-block-placement -funclet-layout -remove-loads-into-fake-uses -stackmap-liveness -livedebugvalues -machine-sanmd -lazy-machine-block-freq -machine-opt-remark-emitter -stack-frame-layout
; AIE-O0123:Target Library Information
; AIE-O0123-NEXT:Runtime Library Function Analysis
; AIE-O0123-NEXT:Target Pass Configuration
; AIE-O0123-NEXT:Machine Module Information
; AIE-O0123-NEXT:Target Transform Information
; AIE-O123:Assumption Cache Tracker
; AIE-O0123:Library Function Lowering Analysis
; AIE-O123:AIE complex addressing modes based Alias Analysis
; AIE-O123-NEXT:External Alias Analysis
; AIE-O123-NEXT:Type-Based Alias Analysis
; AIE-O123-NEXT:Scoped NoAlias Alias Analysis
; AIE-O0123:Create Garbage Collector Module Metadata
; AIE-O0:Assumption Cache Tracker
; AIE-O0123:Profile summary info
; AIE-O0123-NEXT:Machine Branch Probability Analysis
; AIE-O123:Default Regalloc Eviction Advisor
; AIE-O123-NEXT:Default Regalloc Priority Advisor
; AIE-O0123:  ModulePass Manager
; AIE-O123:    FunctionPass Manager
; AIE-O123-NEXT:      Dominator Tree Construction
; AIE-O123-NEXT:      Basic Alias Analysis (stateless AA impl)
; AIE-O123-NEXT:      Function Alias Analysis Results
; AIE-O123-NEXT:      ObjC ARC contraction
; AIE-O0123:    Pre-ISel Intrinsic Lowering
; AIE-O0123-NEXT:    FunctionPass Manager
; AIE-O0123-NEXT:      Expand IR instructions
; AIE-O0123-NEXT:      Expand Atomic instructions
; AIE-O123:      Dominator Tree Construction
; AIE-O123-NEXT:      Infer address spaces
; AIE-O123-NEXT:      Basic Alias Analysis (stateless AA impl)
; AIE-O123-NEXT:      Natural Loop Information
; AIE-O123-NEXT:      Canonicalize natural loops
; AIE-O123-NEXT:      Scalar Evolution Analysis
; AIE-O123-NEXT:      Loop Pass Manager
; AIE-O123-NEXT:        Canonicalize Freeze Instructions in Loops
; AIE-O123-NEXT:        Induction Variable Users
; AIE-O123-NEXT:        Loop Strength Reduction
; AIE-O0123:      Lower Garbage Collection Instructions
; AIE-O0123-NEXT:      Shadow Stack GC Lowering
; AIE-O0123-NEXT:      Remove unreachable blocks from the CFG
; AIE-O123:      Natural Loop Information
; AIE-O123-NEXT:      Post-Dominator Tree Construction
; AIE-O123-NEXT:      Branch Probability Analysis
; AIE-O123-NEXT:      Block Frequency Analysis
; AIE-O123-NEXT:      Constant Hoisting
; AIE-O123-NEXT:      Replace intrinsics with calls to vector library
; AIE-O123-NEXT:      Lazy Branch Probability Analysis
; AIE-O123-NEXT:      Lazy Block Frequency Analysis
; AIE-O123-NEXT:      Optimization Remark Emitter
; AIE-O123-NEXT:      Partially inline calls to library functions
; AIE-O0123:      Instrument function entry/exit with calls to e.g. mcount() (post inlining)
; AIE-O0123-NEXT:      Scalarize Masked Memory Intrinsics
; AIE-O0123-NEXT:      Expand reduction intrinsics
; AIE-O123:      Natural Loop Information
; AIE-O123-NEXT:      Post-Dominator Tree Construction
; AIE-O123-NEXT:      Branch Probability Analysis
; AIE-O123-NEXT:      Block Frequency Analysis
; AIE-O123-NEXT:      CodeGen Prepare
; AIE-O0123:      Lower invoke and unwind, for unwindless code generators
; AIE-O0123-NEXT:      Remove unreachable blocks from the CFG
; AIE-O0123-NEXT:      Prepare inline asm insts
; AIE-O0123-NEXT:      Safe Stack instrumentation pass
; AIE-O0123-NEXT:      Insert stack protectors
; AIE-O0123-NEXT:      Dominator Tree Construction
; AIE-O0123-NEXT:      Basic Alias Analysis (stateless AA impl)
; AIE-O0123-NEXT:      Function Alias Analysis Results
; AIE-O0123-NEXT:      Natural Loop Information
; AIE-O0123-NEXT:      Post-Dominator Tree Construction
; AIE-O0123-NEXT:      Branch Probability Analysis
; AIE-O0123-NEXT:      Assignment Tracking Analysis
; AIE-O0123-NEXT:      Lazy Branch Probability Analysis
; AIE-O0123-NEXT:      Lazy Block Frequency Analysis
; AIE-O0123-NEXT:      AIE DAG->DAG Pattern Instruction Selection
; AIE-O0123-NEXT:      Finalize ISel and expand pseudo-instructions
; AIE-O123:      Lazy Machine Block Frequency Analysis
; AIE-O123-NEXT:      Early Tail Duplication
; AIE-O123-NEXT:      Optimize machine instruction PHIs
; AIE-O123-NEXT:      Slot index numbering
; AIE-O123-NEXT:      Merge disjoint stack slots
; AIE-O0123:      Local Stack Slot Allocation
; AIE-O123:      Remove dead machine instructions
; AIE-O123-NEXT:      MachineDominator Tree Construction
; AIE-O123-NEXT:      Machine Natural Loop Construction
; AIE-O123-NEXT:      Machine Block Frequency Analysis
; AIE-O123-NEXT:      Early Machine Loop Invariant Code Motion
; AIE-O123-NEXT:      MachineDominator Tree Construction
; AIE-O123-NEXT:      Machine Block Frequency Analysis
; AIE-O123-NEXT:      Machine Common Subexpression Elimination
; AIE-O123-NEXT:      MachinePostDominator Tree Construction
; AIE-O123-NEXT:      Machine Cycle Info Analysis
; AIE-O123-NEXT:      Machine code sinking
; AIE-O123-NEXT:      Peephole Optimizations
; AIE-O123-NEXT:      Remove dead machine instructions
; AIE-O123-NEXT:      Detect Dead Lanes
; AIE-O123-NEXT:      Init Undef Pass
; AIE-O123-NEXT:      Process Implicit Definitions
; AIE-O123-NEXT:      Remove unreachable machine basic blocks
; AIE-O123-NEXT:      Live Variable Analysis
; AIE-O0123:      Eliminate PHI nodes for register allocation
; AIE-O0123-NEXT:      Two-Address instruction pass
; AIE-O0:      Fast Register Allocator
; AIE-O123:      MachineDominator Tree Construction
; AIE-O123-NEXT:      Slot index numbering
; AIE-O123-NEXT:      Live Interval Analysis
; AIE-O123-NEXT:      Register Coalescer
; AIE-O123-NEXT:      Rename Disconnected Subregister Components
; AIE-O123-NEXT:      Machine Instruction Scheduler
; AIE-O123-NEXT:      Debug Variable Analysis
; AIE-O123-NEXT:      Live Stack Slot Analysis
; AIE-O123-NEXT:      Virtual Register Map
; AIE-O123-NEXT:      Live Register Matrix
; AIE-O123-NEXT:      Bundle Machine CFG Edges
; AIE-O123-NEXT:      Spill Code Placement Analysis
; AIE-O123-NEXT:      Lazy Machine Block Frequency Analysis
; AIE-O123-NEXT:      Machine Optimization Remark Emitter
; AIE-O123-NEXT:      Greedy Register Allocator
; AIE-O123-NEXT:      Virtual Register Rewriter
; AIE-O123-NEXT:      Register Allocation Pass Scoring
; AIE-O123-NEXT:      Stack Slot Coloring
; AIE-O123-NEXT:      Machine Copy Propagation Pass
; AIE-O123-NEXT:      Machine Loop Invariant Code Motion
; AIE-O0123:      Remove Redundant DEBUG_VALUE analysis
; AIE-O0123-NEXT:      Fixup Statepoint Caller Saved
; AIE-O123:      PostRA Machine Sink
; AIE-O123-NEXT:      Machine Block Frequency Analysis
; AIE-O123-NEXT:      MachineDominator Tree Construction
; AIE-O123-NEXT:      MachinePostDominator Tree Construction
; AIE-O0123:      Lazy Machine Block Frequency Analysis
; AIE-O0123-NEXT:      Machine Optimization Remark Emitter
; AIE-O123:      Shrink Wrapping analysis
; AIE-O0123:      Prologue/Epilogue Insertion & Frame Finalization
; AIE-O123:      Machine Late Instructions Cleanup Pass
; AIE-O123-NEXT:      Control Flow Optimizer
; AIE-O123-NEXT:      Lazy Machine Block Frequency Analysis
; AIE-O123-NEXT:      Tail Duplication
; AIE-O123-NEXT:      Machine Copy Propagation Pass
; AIE-O123-NEXT:      Machine Copy Propagation Pass
; AIE-O0123:      Post-RA pseudo instruction expansion pass
; AIE-O0123-NEXT:      MachineDominator Tree Construction
; AIE-O0123-NEXT:      Machine Natural Loop Construction
; AIE-O0123-NEXT:      Post RA top-down list latency scheduler
; AIE-O0123-NEXT:      Finalize machine instruction bundles
; AIE-O0123-NEXT:      Analyze Machine Code For Garbage Collection
; AIE-O123:      MachineDominator Tree Construction
; AIE-O123-NEXT:      Machine Natural Loop Construction
; AIE-O123-NEXT:      Machine Block Frequency Analysis
; AIE-O123-NEXT:      MachinePostDominator Tree Construction
; AIE-O123-NEXT:      Branch Probability Basic Block Placement
; AIE-O0123:      Insert fentry calls
; AIE-O0123-NEXT:      Insert XRay ops
; AIE-O0123-NEXT:      Implement the 'patchable-function' attribute
; AIE-O0123-NEXT:      AIE Delay Slot Filler
; AIE-O0123-NEXT:      AIE Machine Block Alignment
; AIE-O0123-NEXT:      Contiguously Lay Out Funclets
; AIE-O0123-NEXT:      Remove Loads Into Fake Uses
; AIE-O0123-NEXT:      StackMap Liveness Analysis
; AIE-O0123-NEXT:      Live DEBUG_VALUE analysis
; AIE-O0123-NEXT:      Machine Sanitizer Binary Metadata
; AIE-O0123-NEXT:      Lazy Machine Block Frequency Analysis
; AIE-O0123-NEXT:      Machine Optimization Remark Emitter
; AIE-O0123-NEXT:      Stack Frame Layout Analysis
; AIE-O0123-NEXT:      AIE Assembly Printer
; AIE-O0123-NEXT:      Free MachineFunction
