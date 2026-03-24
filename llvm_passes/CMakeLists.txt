cmake_minimum_required(VERSION 3.13)
project(ObfPassPlugin LANGUAGES CXX)

find_package(LLVM REQUIRED CONFIG)
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

add_llvm_pass_plugin(ObfPassPlugin
  ObfPass.cpp
)

target_compile_features(ObfPassPlugin PRIVATE cxx_std_17)
