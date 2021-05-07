cmake_minimum_required(VERSION 3.19)
project(CudaEnchant CUDA)

set(CMAKE_CXX_STANDARD 14)

add_executable(CudaEnchant main.cu SimpleRandom.cu)

set_target_properties(
        CudaEnchant
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)