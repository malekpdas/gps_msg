cmake_minimum_required(VERSION 3.10)
project(gps_msg-msg VERSION 1.0.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Default installation directory to /opt/orocos if not explicitly set
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "/opt/orocos" CACHE PATH "Installation prefix" FORCE)
endif()

# This is a header-only message library template

add_library(gps_msg-msg INTERFACE)

target_include_directories(gps_msg-msg INTERFACE 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Install rules
install(DIRECTORY include/gps_msg DESTINATION include)
install(TARGETS gps_msg-msg EXPORT gps_msg-msg-targets)
install(EXPORT gps_msg-msg-targets DESTINATION share/gps_msg-msg/cmake)

