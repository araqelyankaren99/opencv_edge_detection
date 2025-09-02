cmake_minimum_required(VERSION 3.4.1)
project(opencv_edge_detection)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fopenmp -static-openmp")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fopenmp -static-openmp")

# Include OpenCV
set(OPENCV_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/main/opencv)
include_directories(${OPENCV_DIR}/include)

# Link static OpenCV .a files
add_library(lib_opencv_imgproc STATIC IMPORTED)
add_library(lib_opencv_core STATIC IMPORTED)
add_library(lib_opencv_highgui STATIC IMPORTED)

set_target_properties(lib_opencv_highgui PROPERTIES IMPORTED_LOCATION ${OPENCV_DIR}/${ANDROID_ABI}/libopencv_highgui.a)
set_target_properties(lib_opencv_imgproc PROPERTIES IMPORTED_LOCATION ${OPENCV_DIR}/${ANDROID_ABI}/libopencv_imgproc.a)
set_target_properties(lib_opencv_core PROPERTIES IMPORTED_LOCATION ${OPENCV_DIR}/${ANDROID_ABI}/libopencv_core.a)

# Linker dependencies
find_library(log-lib log)
find_library(c-lib c)
find_library(m-lib m)
find_library(stdcpp-lib c++_static)

# Your native library name
add_library(opencv_edge_detection SHARED ../ios/Classes/opencv_edge_detection.cpp)

# Link everything
target_link_libraries(
        opencv_edge_detection
        lib_opencv_highgui
        lib_opencv_imgproc
        lib_opencv_core
        ${log-lib}
        ${c-lib}
        ${m-lib}
        ${stdcpp-lib}
)
