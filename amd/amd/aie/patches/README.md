# amd/aie/patches — the invasive core-LLVM edits that cannot relocate

The AIE backend is mostly **additive** and now lives under `amd/aie/` (the target
backend, unit tests, and the clang/lld AIE files — pulled into the build by
[../cmake/AddAIE.cmake](../cmake/AddAIE.cmake)). What stays behind are **edits to
pre-existing upstream files**: AIE-guarded code inlined into shared LLVM/clang/lld
sources. These **cannot move** to `amd/aie/` without upstream refactoring hooks, so
they are carried as in-place modifications and (for the LLVM 21→23 port) will be
extracted into a patch series.

This file is the **manifest** of that invasive surface, measured on the relocated
tree (`Xilinx/llvm-aie@bf0a7459e`, LLVM 21). It is the scope sheet for Phase 2
(forward-port onto ROCm amd-llvm 23) in
`rocm-npu-staging-workspace/.knowledge/amd-aie-prototype-plan.md`.

## Summary

- **63 pre-existing files** edited in place; **1317 AIE-mention lines** total.
- Dominated by **`clang/lib/CodeGen/CGBuiltin.cpp` (930 lines)** — AIE intrinsic
  codegen inlined into the shared builtin emitter. This single file is ~71% of the
  invasive surface and the highest-value candidate for an upstream extension point
  (a per-target builtin-codegen hook) that would let it drain into `amd/aie/` too.
- By subproject: clang/lib 26, llvm/lib 15, llvm/include 10, clang/include 7, lld 5.
- Riskiest for the 21→23 port (core type/ABI surface, 3-way-conflict-prone vs
  amd-staging): `MachineValueType.h` + `ValueTypes.td` (extends the core MVT enum),
  `BinaryFormat/ELF.h` (`EM_AIE`), `TargetParser/Triple.{h,cpp}`, `DataLayout`,
  `MCDwarf.cpp` (het-debug), and the scheduler infra AIE both subclasses and patches.

## The 63 invasive files (by AIE-mention line count)

| File | AIE lines |
| --- | --- |
| `clang/lib/CodeGen/CGBuiltin.cpp` | 930 |
| `llvm/lib/Analysis/ValueTracking.cpp` | 71 |
| `clang/lib/CodeGen/CGExprScalar.cpp` | 38 |
| `llvm/lib/Object/RelocationResolver.cpp` | 30 |
| `llvm/include/llvm/TargetParser/Triple.h` | 18 |
| `clang/lib/AST/ASTContext.cpp` | 15 |
| `llvm/include/llvm/Object/ELFObjectFile.h` | 13 |
| `llvm/include/llvm/CodeGenTypes/MachineValueType.h` | 13 |
| `clang/include/clang/AST/Type.h` | 13 |
| `llvm/lib/ObjectYAML/ELFYAML.cpp` | 10 |
| `llvm/include/llvm/BinaryFormat/ELF.h` | 9 |
| `llvm/include/llvm/BinaryFormat/Dwarf.def` | 7 |
| `clang/lib/Sema/SemaDeclAttr.cpp` | 7 |
| `llvm/include/llvm/IR/Intrinsics.td` | 6 |
| `clang/lib/Driver/Driver.cpp` | 6 |
| `clang/lib/Basic/Targets.cpp` | 6 |
| `clang/include/clang/Basic/Attr.td` | 6 |
| `lld/ELF/InputFiles.cpp` | 5 |
| `clang/lib/Driver/ToolChains/CommonArgs.cpp` | 5 |
| `clang/lib/CodeGen/CodeGenModule.cpp` | 5 |
| `clang/lib/CodeGen/CodeGenFunction.h` | 5 |
| `llvm/lib/Object/ELF.cpp` | 4 |
| `llvm/lib/IR/Intrinsics.cpp` | 4 |
| `llvm/include/llvm/CodeGen/ValueTypes.td` | 4 |
| `clang/lib/Sema/SemaExpr.cpp` | 4 |
| `clang/lib/CodeGen/CodeGenTypes.cpp` | 4 |
| `clang/lib/AST/Type.cpp` | 4 |
| `llvm/lib/ObjectYAML/ELFEmitter.cpp` | 3 |
| `llvm/lib/MC/MCDwarf.cpp` | 3 |
| `llvm/lib/DebugInfo/DWARF/DWARFExpression.cpp` | 3 |
| `llvm/lib/CodeGen/PostRASchedulerList.cpp` | 3 |
| `llvm/lib/BinaryFormat/ELF.cpp` | 3 |
| `lld/ELF/Target.cpp` | 3 |
| `clang/lib/Sema/Sema.cpp` | 3 |
| `clang/lib/CodeGen/CGDebugInfo.cpp` | 3 |
| `clang/include/clang/Serialization/ASTBitCodes.h` | 3 |
| `clang/include/clang/Driver/Options.td` | 3 |
| `clang/include/clang/Basic/TargetBuiltins.h` | 3 |
| `llvm/lib/CodeGen/TargetLoweringBase.cpp` | 2 |
| `llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp` | 2 |
| `llvm/include/llvm/CodeGen/TargetRegisterInfo.h` | 2 |
| `llvm/include/llvm/CodeGen/ScheduleHazardRecognizer.h` | 2 |
| `lld/ELF/Target.h` | 2 |
| `clang/lib/Serialization/ASTReader.cpp` | 2 |
| `clang/lib/Serialization/ASTCommon.cpp` | 2 |
| `clang/lib/Index/USRGeneration.cpp` | 2 |
| `clang/lib/CodeGen/ItaniumCXXABI.cpp` | 2 |
| `clang/lib/AST/TypeLoc.cpp` | 2 |
| `clang/lib/AST/PrintfFormatString.cpp` | 2 |
| `clang/lib/AST/NSAPI.cpp` | 2 |
| `clang/lib/AST/ItaniumMangle.cpp` | 2 |
| `clang/lib/AST/ExprConstant.cpp` | 2 |
| `clang/lib/AST/ASTImporter.cpp` | 2 |
| `clang/include/clang/AST/TypeProperties.td` | 2 |
| `clang/include/clang/AST/ASTContext.h` | 2 |
| `llvm/lib/Target/AArch64/AArch64SystemOperands.td` | 1 |
| `llvm/lib/CodeGen/TargetInstrInfo.cpp` | 1 |
| `llvm/lib/CodeGen/GlobalISel/IRTranslator.cpp` | 1 |
| `llvm/include/llvm/IR/CallingConv.h` | 1 |
| `lld/ELF/ScriptParser.cpp` | 1 |
| `lld/ELF/Driver.cpp` | 1 |
| `clang/lib/Sema/SemaType.cpp` | 1 |
| `clang/lib/CodeGen/TargetInfo.h` | 1 |

## Extracting the patch series (Phase 2)

These edits are **not** split out yet — they live inline in the stock files on the
`amd-aie-relocate` branch. A standalone `core-llvm.patch` needs a clean upstream
baseline to diff against. Recommended recipe, done **at port time against the
target LLVM**, not pre-emptively against 21 (you forward-port onto amd-llvm 23, so
the durable patch is the 23 one):

1. Identify the upstream merge-base: `git merge-base aie-public <llvm.org/main>`
   (needs unshallowing this clone, or diff each file against the matching
   `ROCm/llvm-project` 23 revision during the port).
2. `git diff <base> -- $(cat this-list)` → `core-llvm.patch`, restricted to the
   63 paths above (everything else is already isolated under `amd/aie/`).
3. Forward-port 21→22→23 (see plan T1); reconcile 3-way conflicts in the MVT /
   DataLayout / MCDwarf het-debug spots against amd-staging's own deltas.
4. Pursue the CGBuiltin.cpp extension-point upstream ask in parallel — landing it
   shrinks this manifest by ~71% and is the single biggest lever for a clean split.

Regenerate this manifest from the relocated tree:

```sh
grep -rIl --include=*.cpp --include=*.h --include=*.td --include=*.inc --include=*.def \
  -e AIE -e AIEngine llvm/lib llvm/include clang/lib clang/include lld \
  | grep -v '^amd/aie' \
  | grep -viE '/AIE/|/AIE\.|/Targets/AIE|ToolChains/AIE|Arch/AIE|IntrinsicsAIE|aie1|aie2|BuiltinsAIE|AIETypes|CodeGenFormat\.td|Headers/aie' \
  | grep -ivE '(^|/)aie' | sort -u
```
