add_llvm_component_library(LLVMBlindedComputation
  BlindedInstrConversion.cpp

  DEPENDS
  intrinsics_gen
  )
