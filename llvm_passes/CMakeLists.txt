cmake_minimum_required(VERSION 3.13)
project(ObfPassPlugin LANGUAGES C CXX)

# Auto-detect LLVM CMake directory if caller did not pass -DLLVM_DIR.
if(NOT DEFINED LLVM_DIR)
  find_program(LLVM_CONFIG_BIN NAMES llvm-config llvm-config-18 llvm-config-17 llvm-config-16)
  if(LLVM_CONFIG_BIN)
    execute_process(
      COMMAND ${LLVM_CONFIG_BIN} --cmakedir
      OUTPUT_VARIABLE LLVM_CMAKE_DIR_DETECTED
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE LLVM_CONFIG_RESULT
    )
    if(LLVM_CONFIG_RESULT EQUAL 0 AND EXISTS "${LLVM_CMAKE_DIR_DETECTED}/LLVMConfig.cmake")
      set(LLVM_DIR "${LLVM_CMAKE_DIR_DETECTED}" CACHE PATH "LLVM CMake directory")
      message(STATUS "Auto-detected LLVM_DIR=${LLVM_DIR} via ${LLVM_CONFIG_BIN}")
    endif()
  endif()
endif()

find_package(LLVM QUIET CONFIG)
if(NOT LLVM_FOUND)
  message(FATAL_ERROR
    "LLVM package not found.\\n"
    "Install LLVM dev package, then provide one of:\\n"
    "  1) -DLLVM_DIR=<path-to-LLVMConfig.cmake-dir>\\n"
    "  2) CMAKE_PREFIX_PATH including LLVM install prefix\\n"
    "  3) Ensure llvm-config is in PATH (script can auto-detect --cmakedir).")
endif()

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

add_llvm_pass_plugin(ObfPassPlugin
  ObfPass.cpp
)

target_compile_features(ObfPassPlugin PRIVATE cxx_std_17)
