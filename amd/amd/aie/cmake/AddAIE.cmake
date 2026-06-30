# AddAIE.cmake — owns the amd/aie/ relocation of the AIE backend.
#
# The bulk of the AIE-specific source (the llc/clang/lld target backend, its unit
# tests, and the clang/lld additive files) lives under amd/aie/ instead of scattered
# through stock LLVM. This module centralizes the few build-system hooks needed to
# pull that relocated source back into the in-tree build, so the footprint on stock
# CMake files is a one-line call/path each.
#
# It is include()'d once from llvm/CMakeLists.txt; the functions it defines are
# global (visible in clang/lld subprojects and every add_subdirectory below).
#
# Two stock mechanisms hard-code llvm/lib/Target/<t> and BOTH must be redirected:
#   1. build wiring        — llvm/lib/Target/CMakeLists.txt add_subdirectory loop
#   2. config-def enums     — llvm/CMakeLists.txt probes the target dir to populate
#                             AsmPrinters.def / AsmParsers.def / Disassemblers.def /
#                             TargetMCAs.def. Missing this is SILENT: the target
#                             registers in Targets.def (llc --version shows it) but
#                             cannot emit asm/obj ("target does not support
#                             generation of this file type").
# Plus the unit tests under llvm/unittests/Target/<t>.

# Root of the relocated tree (this file is amd/aie/cmake/AddAIE.cmake).
get_filename_component(AMD_AIE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(AMD_AIE_DIR "${AMD_AIE_DIR}" CACHE INTERNAL "Root of the relocated amd/aie/ tree")

# Return the relocated lib/Target/<t> source dir into ${out}, or "" if <t> is not
# relocated under amd/aie/ (i.e. a stock target staying in llvm/lib/Target).
function(amd_aie_target_source_dir t out)
  set(_d "${AMD_AIE_DIR}/llvm/lib/Target/${t}")
  if(IS_DIRECTORY "${_d}")
    set(${out} "${_d}" PARENT_SCOPE)
  else()
    set(${out} "" PARENT_SCOPE)
  endif()
endfunction()

# Return the relocated unittests/Target/<t> dir into ${out}, or "" if not relocated.
function(amd_aie_unittest_source_dir t out)
  set(_d "${AMD_AIE_DIR}/llvm/unittests/Target/${t}")
  if(IS_DIRECTORY "${_d}")
    set(${out} "${_d}" PARENT_SCOPE)
  else()
    set(${out} "" PARENT_SCOPE)
  endif()
endfunction()
