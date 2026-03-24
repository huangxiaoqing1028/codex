cmake_minimum_required(VERSION 3.13)
project(ObfPassPlugin LANGUAGES C CXX)
option(OBF_ALLOW_STUB "Allow configure/build success with a stub target when LLVM dev package is missing" ON)

# Auto-detect LLVM CMake directory if caller did not pass -DLLVM_DIR.
if(NOT DEFINED LLVM_DIR)
  find_program(LLVM_CONFIG_BIN
    NAMES llvm-config llvm-config-18 llvm-config-17 llvm-config-16
    PATHS
      /opt/homebrew/opt/llvm/bin
      /usr/local/opt/llvm/bin
    NO_DEFAULT_PATH
  )
  if(NOT LLVM_CONFIG_BIN)
    find_program(LLVM_CONFIG_BIN NAMES llvm-config llvm-config-18 llvm-config-17 llvm-config-16)
  endif()
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
  if(OBF_ALLOW_STUB)
    message(WARNING
      "LLVM package not found. Building STUB target only.\\n"
      "Install LLVM dev package, then provide one of:\\n"
      "  1) -DLLVM_DIR=<path-to-LLVMConfig.cmake-dir>\\n"
      "  2) CMAKE_PREFIX_PATH including LLVM install prefix\\n"
      "  3) Ensure llvm-config is in PATH (script can auto-detect --cmakedir).")
    add_custom_target(ObfPassPlugin ALL
      COMMAND ${CMAKE_COMMAND} -E echo "Stub build: LLVM dev package not found, plugin was not compiled."
      VERBATIM
    )
    return()
  else()
    message(FATAL_ERROR
      "LLVM package not found.\\n"
      "Install LLVM dev package, then provide one of:\\n"
      "  1) -DLLVM_DIR=<path-to-LLVMConfig.cmake-dir>\\n"
      "  2) CMAKE_PREFIX_PATH including LLVM install prefix\\n"
      "  3) Ensure llvm-config is in PATH (script can auto-detect --cmakedir).")
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})
include(CheckIncludeFileCXX)
set(CMAKE_REQUIRED_INCLUDES ${LLVM_INCLUDE_DIRS})

check_include_file_cxx("llvm/Passes/PassPlugin.h" HAVE_LLVM_PASS_PLUGIN_H)
if(NOT HAVE_LLVM_PASS_PLUGIN_H)
  if(OBF_ALLOW_STUB)
    message(WARNING
      "Found LLVM, but header llvm/Passes/PassPlugin.h is missing.\\n"
      "This usually means LLVM is too old or not a full dev package.\\n"
      "Build will continue in STUB mode. Recommend LLVM >= 11 (prefer 14+).")
    add_custom_target(ObfPassPlugin ALL
      COMMAND ${CMAKE_COMMAND} -E echo "Stub build: llvm/Passes/PassPlugin.h not found, plugin was not compiled."
      VERBATIM
    )
    return()
  else()
    message(FATAL_ERROR
      "Missing llvm/Passes/PassPlugin.h. Install a newer LLVM dev package (>=11, recommend 14+).")
  endif()
endif()

add_llvm_pass_plugin(ObfPassPlugin
  ObfPass.cpp
)

target_compile_features(ObfPassPlugin PRIVATE cxx_std_17)
