# GPS Message (`gps_msg`)

This package defines the standard Orocos RTT data structure for exchange of Global Positioning System (GNSS) information between components.

## 📂 Message Structure

The message is defined in `gps_msg.hpp` and wraps the high-level data types from `custom_types`.

```cpp
struct GpsMsg {
    uint64_t timestamp_ms;      // Arrival time at the component
    int counter;                // Message sequence counter

    CustomTypes::GpsData gpsData; // Geographic coordinates and accuracy
};
```

## 🛠️ Installation & Usage

### Building and Packaging
To build the Debian package and install it system-wide:
```bash
./create_pkg.sh
```
This installs the headers to `/opt/orocos/`.

### Manual CMake Installation
```bash
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/orocos
sudo make install
```

## 🚀 Usage in Other Projects

### CMake Integration
```cmake
list(APPEND CMAKE_PREFIX_PATH "/opt/orocos")
find_package(gps_msg-msg REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE gps_msg-msg)
```

### C++ Usage
```cpp
#include <gps_msg/gps_msg.hpp>

void handleGps(const GpsMsg& msg) {
    double lat = msg.gpsData.latitude;
    // ...
}
```
