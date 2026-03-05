#!/bin/bash

# Exit on any error
set -e

MSG_NAME="gps_msg"

# 1. Detect version from CMakeLists.txt and combine with Git info
CMAKE_VERSION=$(grep "project(.*VERSION" CMakeLists.txt | sed -E 's/.*VERSION ([0-9.]+).*/\1/')
CMAKE_TAG="v${CMAKE_VERSION}"

# 2. Check if a tag for this version already exists
if ! git rev-parse "${CMAKE_TAG}" >/dev/null 2>&1; then
    echo "⚠️  New version detected in CMakeLists.txt: ${CMAKE_VERSION}"
    printf "❓ Should I create a Git tag '${CMAKE_TAG}' for this commit? (y/N): "
    read tag_response
    case "$tag_response" in
        [yY][eE][sS]|[yY])
            git tag "${CMAKE_TAG}"
            echo "✅ Tag Created: ${CMAKE_TAG}"
            ;;
        *)
            echo "ℹ️  Proceeding without tagging. Patch version will be relative to the previous tag."
            ;;
    esac
fi

# 3. Get the latest tag (for calculating the patch version)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "${CMAKE_TAG}")

# 4. Extract Major.Minor from the tag
BASE_VERSION=$(echo "${LATEST_TAG}" | sed -E 's/^v?([0-9]+\.[0-9]+).*/\1/')

# 5. Count commits SINCE that tag
COMMITS_SINCE_TAG=$(git rev-list "${LATEST_TAG}..HEAD" --count 2>/dev/null || git rev-list --count HEAD)

# 6. Check for uncommitted changes
GIT_DIRTY=$(git status --porcelain | grep -q . && echo "-dirty" || echo "")

# 7. Final Version: Major.Minor.CommitsSinceTag
VERSION="${BASE_VERSION}.${COMMITS_SINCE_TAG}${GIT_DIRTY}"

BUILD_DIR="build"

echo "🚀 Starting Debian package creation for ${MSG_NAME}-msg v${VERSION}..."

# 1. Create Build Directory
if [ -d "${BUILD_DIR}" ]; then
    echo "🧹 Cleaning existing build directory..."
    rm -rf "${BUILD_DIR}"
fi
mkdir "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 2. Configure (Header-only, so no build needed)
echo "⚙️  Configuring project..."
cmake ..

# 3. Create Package Staging Area
echo "📂 Creating package staging area..."
STAGING_DIR="pkg_stage"
if [ -d "${STAGING_DIR}" ]; then
    rm -rf "${STAGING_DIR}"
fi
mkdir -p "${STAGING_DIR}/DEBIAN"

# Install files to staging area
make install DESTDIR="$(pwd)/${STAGING_DIR}"

# 4. Create DEBIAN scripts for clean directory handling
cat << EOF > "${STAGING_DIR}/DEBIAN/preinst"
#!/bin/sh
mkdir -p /opt/orocos/include/${MSG_NAME}
mkdir -p /opt/orocos/share/${PKG_NAME}/cmake
exit 0
EOF
chmod 755 "${STAGING_DIR}/DEBIAN/preinst"

cat << EOF > "${STAGING_DIR}/DEBIAN/postrm"
#!/bin/sh
if [ "\$1" = "remove" ]; then
    rmdir /opt/orocos/include/${MSG_NAME} 2>/dev/null || true
    rmdir /opt/orocos/share/${PKG_NAME}/cmake 2>/dev/null || true
    rmdir /opt/orocos/share/${PKG_NAME} 2>/dev/null || true
fi
exit 0
EOF
chmod 755 "${STAGING_DIR}/DEBIAN/postrm"

# 5. Create DEBIAN/control file
PKG_NAME="${MSG_NAME}-msg"

cat << EOF > "${STAGING_DIR}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${VERSION}
Section: devel
Priority: optional
Architecture: all
Maintainer: $(whoami)@$(hostname)
Description: Header-only message definition: ${MSG_NAME}
EOF

# 5. Build Debian Package manually
echo "📦 Building Debian package..."
DEB_PACKAGE="${PKG_NAME}-${VERSION}-all.deb"

# Minimal deb construction
(cd "${STAGING_DIR}/DEBIAN" && tar -czf ../../control.tar.gz .)
(cd "${STAGING_DIR}" && tar -cJf ../data.tar.xz opt)

echo "2.0" > debian-binary
ar r "${DEB_PACKAGE}" debian-binary control.tar.gz data.tar.xz
rm control.tar.gz data.tar.xz debian-binary
chmod 644 "${DEB_PACKAGE}"

echo "✅ Package created: ${DEB_PACKAGE}"

# 6. Optional Installation
echo ""
printf "❓ Do you want to install the package using apt? (y/N): "
read response
case "$response" in
    [yY][eE][sS]|[yY])
        echo "📥 Installing ${DEB_PACKAGE}..."
        cp "${DEB_PACKAGE}" "/tmp/${DEB_PACKAGE}"
        sudo apt install "/tmp/${DEB_PACKAGE}" --reinstall -y
        rm "/tmp/${DEB_PACKAGE}"
        echo "🎉 Installation complete!"
        ;;
    *)
        echo "ℹ️  Skipping installation."
        ;;
esac
