
#!/bin/bash
set -e

# Usage: ./build.sh [platform]
# Where platform is one of: OS64, SIMULATOR64, MAC_ARM64, MAC_CATALYST_ARM64, etc.
PLATFORM=${1:-MAC_ARM64}  # Default to macOS ARM64

# Create build directory
BUILD_DIR="build-${PLATFORM}"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Map iOS toolchain platform to vcpkg triplet
case $PLATFORM in
  # iOS Device
  OS|OS64|OS64COMBINED)
    VCPKG_TRIPLET="arm64-ios"
    ;;
    
  # iOS Simulator
  SIMULATOR|SIMULATOR64|SIMULATORARM64|SIMULATOR64COMBINED)
    if [[ $PLATFORM == *"ARM64"* ]]; then
      VCPKG_TRIPLET="arm64-ios-simulator"
    else
      VCPKG_TRIPLET="x64-ios-simulator"
    fi
    ;;
    
  # macOS
  MAC)
    VCPKG_TRIPLET="x64-osx"
    ;;
  MAC_ARM64)
    VCPKG_TRIPLET="arm64-osx"
    ;;
  MAC_UNIVERSAL)
    VCPKG_TRIPLET="arm64-osx"  # Choose one for building dependencies
    ;;
    
  # Mac Catalyst
  MAC_CATALYST|MAC_CATALYST_ARM64|MAC_CATALYST_UNIVERSAL)
    if [[ $PLATFORM == *"ARM64"* ]]; then
      VCPKG_TRIPLET="arm64-osx"  # Use macOS triplet for Catalyst
    else
      VCPKG_TRIPLET="x64-osx"    # Use macOS triplet for Catalyst
    fi
    ;;
    
  # tvOS
  TVOS|TVOSCOMBINED)
    VCPKG_TRIPLET="arm64-ios"  # Use iOS triplet for tvOS
    ;;
    
  # tvOS Simulator
  SIMULATOR_TVOS|SIMULATORARM64_TVOS)
    if [[ $PLATFORM == *"ARM64"* ]]; then
      VCPKG_TRIPLET="arm64-ios-simulator"
    else
      VCPKG_TRIPLET="x64-ios-simulator"
    fi
    ;;
    
  # watchOS and visionOS - use iOS triplets as fallback
  WATCHOS|WATCHOSCOMBINED|VISIONOS|VISIONOSCOMBINED)
    VCPKG_TRIPLET="arm64-ios"  # Fallback to iOS triplet
    ;;
    
  # Default fallback
  *)
    echo "Unknown platform: $PLATFORM, defaulting to arm64-osx"
    VCPKG_TRIPLET="arm64-osx"
    ;;
esac

echo "Building for platform: $PLATFORM using vcpkg triplet: $VCPKG_TRIPLET"

# Configure with iOS toolchain
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=../third_party/vcpkg/scripts/buildsystems/vcpkg.cmake \
  -DVCPKG_TARGET_TRIPLET=$VCPKG_TRIPLET \
  -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=../third_party/ios-cmake/ios.toolchain.cmake \
  -DPLATFORM=$PLATFORM

# Build
cmake --build . -j$(sysctl -n hw.ncpu)