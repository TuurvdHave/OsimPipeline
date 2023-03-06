project(Sto_IMU)
cmake_minimum_required(VERSION 3.2)


set(TARGET IMU_GenSto CACHE TYPE STRING)
set(OPENSIM_INSTALL_DIR $ENV{OPENSIM_HOME}
        CACHE PATH "Top-level directory of OpenSim install")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(OpenSim REQUIRED PATHS "${OPENSIM_INSTALL_DIR}")


file(GLOB SOURCE_FILES *.h *.cpp)
add_executable(${TARGET} ${SOURCE_FILES})
target_link_libraries(${TARGET} ${OpenSim_LIBRARIES})

