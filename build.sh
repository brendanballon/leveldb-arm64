#!/bin/bash
set -e

# Usage: ./build.sh [platform]
# Where platform is one of: OS64, SIMULATOR64, MAC_ARM64, MAC_CATALYST_ARM64, etc.
PLATFORM=${1:-MAC_ARM64}  # Default to macOS ARM64

# Path to vcpkg in third_party folder
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VCPKG_PATH="$PROJECT_DIR/third_party/vcpkg"

# Create build directory
BUILD_DIR="build-$(echo ${PLATFORM} | tr '[:upper:]' '[:lower:]')"
mkdir -p $BUILD_DIR
IOS_TOOLCHAIN_PATH="$PROJECT_DIR/third_party/ios-cmake/ios.toolchain.cmake"

# Verify the toolchain file exists
if [ ! -f "$IOS_TOOLCHAIN_PATH" ]; then
  echo "Error: iOS toolchain file not found at $IOS_TOOLCHAIN_PATH"
  echo "Make sure you've initialized the submodule with: git submodule update --init --recursive"
  exit 1
fi

echo "Using iOS toolchain at: $IOS_TOOLCHAIN_PATH"

# Set deployment target based on platform
DEPLOYMENT_TARGET="15.0"  # Default for macOS
if [[ $PLATFORM == OS* || $PLATFORM == SIMULATOR* ]]; then
  DEPLOYMENT_TARGET="18.4"  # For iOS/simulator
fi

# Map iOS toolchain platforms to vcpkg triplets
# See third_party/ios-cmake/README.md for platform details
case "$PLATFORM" in
  # macOS platforms
  MAC)
    VCPKG_TRIPLET="x64-osx"
    ;;
  MAC_ARM64)
    VCPKG_TRIPLET="arm64-osx"
    ;;
  MAC_UNIVERSAL)
    VCPKG_TRIPLET="x64-osx"  # Default to x64 for universal builds
    ;;
  
  # iOS device platforms
  OS)
    VCPKG_TRIPLET="arm-ios"
    ;;
  OS64)
    VCPKG_TRIPLET="arm64-ios"
    ;;
  
  # iOS simulator platforms
  SIMULATOR)
    VCPKG_TRIPLET="x86-ios-simulator"
    ;;
  SIMULATOR64)
    VCPKG_TRIPLET="x64-ios-simulator"
    ;;
  SIMULATOR_ARM64)
    VCPKG_TRIPLET="arm64-ios-simulator"
    ;;
  
  # Catalyst platforms
  MAC_CATALYST|MAC_CATALYST_ARM64|MAC_CATALYST_UNIVERSAL)
    VCPKG_TRIPLET="x64-osx-catalyst"  # Default for Catalyst
    ;;
  
  # Default case for unknown platforms
  *)
    echo "Error: Unknown PLATFORM \"$PLATFORM\" for vcpkg triplet mapping"
    echo "See third_party/ios-cmake/README.md for supported platforms"
    exit 1
    ;;
esac
VCPKG_INSTALLED_DIR="$VCPKG_PATH/vcpkg_installed"

# Run CMake with only the iOS toolchain
# cd $BUILD_DIR
# cmake .. \
#   -DCMAKE_TOOLCHAIN_FILE="$IOS_TOOLCHAIN_PATH" \
#   -DPLATFORM=$PLATFORM \
#   -DENABLE_BITCODE=OFF \
#   -DCMAKE_INSTALL_PREFIX=install \
#   -DLEVELDB_BUILD_TESTS=OFF \
#   -DLEVELDB_BUILD_BENCHMARKS=OFF \
#   -DDEPLOYMENT_TARGET=$DEPLOYMENT_TARGET \
#   -DVCPKG_BASE_PATH="$VCPKG_INSTALLED_DIR" \
#   -DCMAKE_PREFIX_PATH="$VCPKG_INSTALLED_DIR"

cd "$BUILD_DIR"

# Paths
VCPKG_ROOT="$PROJECT_DIR/third_party/vcpkg"
VCPKG_TOOLCHAIN="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
IOS_TOOLCHAIN="$PROJECT_DIR/third_party/ios-cmake/ios.toolchain.cmake"

# Set CMAKE_GENERATOR for both CMake and vcpkg
CMAKE_GENERATOR="Ninja"

# Run CMake with proper configuration
cmake -G "$CMAKE_GENERATOR" .. \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_TOOLCHAIN" \
  -DVCPKG_MANIFEST_MODE=ON \
  -DVCPKG_TARGET_TRIPLET="$VCPKG_TRIPLET" \
  -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$IOS_TOOLCHAIN" \
  -DPLATFORM="$PLATFORM" \
  -DENABLE_BITCODE=OFF \
  -DCMAKE_INSTALL_PREFIX=install \
  -DLEVELDB_BUILD_TESTS=OFF \
  -DLEVELDB_BUILD_BENCHMARKS=OFF \
  -DDEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"

# Build
cmake --build . -j$(sysctl -n hw.ncpu)

# Install
cmake --install .
