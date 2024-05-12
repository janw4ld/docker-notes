project(HelloKitty)
cmake_minimum_required(VERSION 3.22.1)

set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
set(BUILD_SHARED_LIBS OFF)
set(CMAKE_EXE_LINKER_FLAGS "-static")

add_executable(HelloKittyexe main.cpp)
