
# Due to a mutual dependencies, all the sub projects of the SVG are merged here
# Otherwise it is impossible to load the dependencies in opt
# NOTE: if the SVF should be linked into opt, we should probably use the individual sub projects here, rather than the combined project 

# if (LLVM_LINK_LLVM_DYLIB)
#     set(llvm_libs LLVM)
# else()
#     llvm_map_components_to_libnames(llvm_libs bitwriter core ipo irreader instcombine instrumentation target linker analysis scalaropts support transformutils)
# endif()
add_subdirectory(CUDD)


file (GLOB SOURCES
        SVF-FE/*.cpp
        Graphs/*.cpp
        Util/*.cpp
        MemoryModel/*.cpp
        MSSA/*.cpp
        WPA/*.cpp
        SABER/*.cpp
        DDA/*.cpp)


include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include/llvm/Analysis)
llvm_map_components_to_libnames(llvm_libs bitwriter core ipo irreader instcombine instrumentation linker analysis scalaropts support )
add_llvm_library(Svf STATIC ${SOURCES} )
target_link_libraries(Svf ${llvm_libs} Cudd LLVMTransformUtils)

add_dependencies(Svf intrinsics_gen)

# add_llvm_library(Svf STATIC ${SOURCES} LINK_LIBS Cudd)

# link_directories( ${CMAKE_BINARY_DIR}/lib/Cudd )

# if (DEFINED Z3_DIR)
#     set(ENV{Z3_DIR} "${Z3_DIR}")
# endif()

# find_library(Z3_LIBRARIES NAMES libz3.a libz3.so
#                           HINTS $ENV{Z3_DIR}
#                           PATH_SUFFIXES lib bin)
# find_path(Z3_INCLUDES NAMES z3++.h
#                       HINTS $ENV{Z3_DIR}
#                       PATH_SUFFIXES include z3)
# if(NOT Z3_LIBRARIES OR NOT Z3_INCLUDES)
#     message(FATAL_ERROR "Z3 not found!")
# endif()
# message(STATUS "Found Z3: ${Z3_LIBRARIES}")
# message(STATUS "Z3 include dir: ${Z3_INCLUDES}")

