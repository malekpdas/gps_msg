cmake_minimum_required(VERSION 3.10)
project(uav-msg-gps VERSION 1.0.0)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Default installation directory to /opt/orocos if not explicitly set
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "/opt/orocos" CACHE PATH "Installation prefix" FORCE)
endif()

# Dependencies
find_package(uav-types-custom REQUIRED)

# Header-only message library
add_library(${PROJECT_NAME} INTERFACE)

target_link_libraries(${PROJECT_NAME} INTERFACE uav::uav-types-custom)

target_include_directories(${PROJECT_NAME} INTERFACE 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Install rules
install(DIRECTORY include/gps_msg DESTINATION include)
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets)
install(EXPORT ${PROJECT_NAME}-targets 
    DESTINATION share/${PROJECT_NAME}/cmake
    NAMESPACE uav::
)

# Export version info
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY ExactVersion
)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
"include(CMakeFindDependencyMacro)
find_dependency(uav-types-custom)
include(\"\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}-targets.cmake\")
")

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION share/${PROJECT_NAME}/cmake
)

