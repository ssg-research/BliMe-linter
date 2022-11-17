# set(SVF_INCLUDE /home/x34duan/compiler/bc-llvm/SVF/include)
# set(SVF_LIBDIR /home/x34duan/compiler/bc-llvm/SVF/lib)
# include_directories(${SVF_INCLUDE})
# set(SVF_LIBS /home/x34duan/compiler/bc-llvm/SVF/Release-build/lib/libSvf.a /home/x34duan/compiler/bc-llvm/SVF/Release-build/lib/CUDD/libCudd.a)

add_llvm_component_library(LLVMBlindedComputation
  BlindedInstrConversion.cpp
  BlindedTaintTracking.cpp
  BlindedDataUsage.cpp
  FunctionCloning.cpp

  DEPENDS
  intrinsics_gen
  # Svf

  LINK_LIBS 
  LLVMTransformUtils 
  Svf
  
)

# include_directories(/home/x34duan/compiler/bc-llvm/SVF/include)


# llvm_map_components_to_libnames(llvm_libs bitwriter core ipo irreader instcombine instrumentation target linker analysis scalaropts support )
# target_link_libraries(LLVMBlindedComputation PRIVATE ${SVF_LIBS})

