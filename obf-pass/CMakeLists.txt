cmake_minimum_required(VERSION 3.16)
project(SimpleObfPass LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(LLVM REQUIRED CONFIG)
message(STATUS "Using LLVM ${LLVM_PACKAGE_VERSION}")

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

add_llvm_pass_plugin(SimpleObfPass
  ObfPass.cpp
)

# LLVM 22 toolchains may not inherit include/definitions from directory scope
# when building pass plugins via AddLLVM. Set them explicitly on the target.
target_include_directories(SimpleObfPass PRIVATE ${LLVM_INCLUDE_DIRS})

separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND "${LLVM_DEFINITIONS}")
set(LLVM_DEFINITIONS_NO_D "")
foreach(def ${LLVM_DEFINITIONS_LIST})
  string(REGEX REPLACE "^-D" "" def_no_d "${def}")
  list(APPEND LLVM_DEFINITIONS_NO_D "${def_no_d}")
endforeach()
target_compile_definitions(SimpleObfPass PRIVATE ${LLVM_DEFINITIONS_NO_D})
