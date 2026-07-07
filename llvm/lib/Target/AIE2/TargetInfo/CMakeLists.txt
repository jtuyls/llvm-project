add_llvm_component_library(LLVMAIE2Info
  AIE2TargetInfo.cpp
  LINK_COMPONENTS
  MC
  Support
  ADD_TO_COMPONENT
  AIE2
  )
