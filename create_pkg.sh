#!/bin/bash
set -e

# Parse flags
ALLOW_DOWNGRADES=""
for arg in "$@"; do
    case "$arg" in
        --allow-downgrades) ALLOW_DOWNGRADES="--allow-downgrades" ;;
    esac
done

# Source shared utils
source ../../pkg_utils.sh

PKG_NAME="uav-msg-gps"
VERSION=$(get_version)
BUILD_DIR="build"

# Dependency Locking
TYPES_VER=$(get_dep_version "uav-types-custom")
DEPS="uav-types-custom (= ${TYPES_VER})"

echo "🚀 Starting Debian package creation for ${PKG_NAME} v${VERSION}..."
echo "🔗 Locked to dependency: ${DEPS}"

# 1. Build
if [ -d "${BUILD_DIR}" ]; then rm -rf "${BUILD_DIR}"; fi
mkdir "${BUILD_DIR}"
cd "${BUILD_DIR}"
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/orocos
make -j$(nproc)

# 2. Stage
STAGING_DIR="pkg_stage"
mkdir -p "${STAGING_DIR}/DEBIAN"
make install DESTDIR="$(pwd)/${STAGING_DIR}"

# 3. Control File
generate_control "${PKG_NAME}" "${VERSION}" "${DEPS}" "UAV GPS Message Definitions" "gps_msg-msg" "gps_msg-msg" "gps_msg-msg" > "${STAGING_DIR}/DEBIAN/control"

# 3.1 Build Manifest
generate_manifest "${PKG_NAME}" "${VERSION}" "${DEPS}"
mkdir -p "${STAGING_DIR}/opt/orocos/share/${PKG_NAME}"
cp manifest.json "${STAGING_DIR}/opt/orocos/share/${PKG_NAME}/"

# 4. Build Package
DEB_PACKAGE="${PKG_NAME}-${VERSION}-all.deb"
(cd "${STAGING_DIR}/DEBIAN" && tar -czf ../../control.tar.gz .)
(cd "${STAGING_DIR}" && tar -cJf ../data.tar.xz opt)
echo "2.0" > debian-binary
ar r "${DEB_PACKAGE}" debian-binary control.tar.gz data.tar.xz
rm control.tar.gz data.tar.xz debian-binary

# 5. Install
sudo apt -o APT::Sandbox::User=root install "./${DEB_PACKAGE}" --reinstall ${ALLOW_DOWNGRADES} -y
