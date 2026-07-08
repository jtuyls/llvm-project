add_llvm_component_group(AIE2)

set(LLVM_TARGET_DEFINITIONS AIE2.td)

tablegen(LLVM AIE2GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM AIE2GenCallingConv.inc -gen-callingconv)
tablegen(LLVM AIE2GenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM AIE2GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM AIE2GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM AIE2GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM AIE2GenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(AIE2CommonTableGen)

add_llvm_target(AIE2CodeGen
  AIE2AsmPrinter.cpp
  AIE2FrameLowering.cpp
  AIE2ISelDAGToDAG.cpp
  AIE2ISelLowering.cpp
  AIE2InstrInfo.cpp
  AIE2RegisterInfo.cpp
  AIE2Subtarget.cpp
  AIE2TargetMachine.cpp

  LINK_COMPONENTS
  AsmPrinter
  CodeGen
  CodeGenTypes
  Core
  MC
  SelectionDAG
  Support
  Target
  TargetParser
  AIE2Desc
  AIE2Info

  ADD_TO_COMPONENT
  AIE2
  )

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
