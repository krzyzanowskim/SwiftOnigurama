#!/bin/bash

# Usage: ./build_xcframework.sh [--github-release]
# This script builds Oniguruma XCFramework for all Apple platforms
# --github-release: Create GitHub release and upload XCFramework

set -e

# Store the original source directory
SOURCE_DIR="$(pwd)"

# Parse command line arguments
GITHUB_RELEASE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --github-release)
            GITHUB_RELEASE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--github-release]"
            exit 1
            ;;
    esac
done

# Configuration
LIBRARY_NAME="oniguruma"
VERSION="6.9.10"
TEMP_ROOT=$(mktemp -d)
BUILD_DIR="${TEMP_ROOT}/build"
INSTALL_DIR="${TEMP_ROOT}/install"
XCFRAMEWORK_NAME="Oniguruma.xcframework"
XCFRAMEWORK_PATH="${TEMP_ROOT}/${XCFRAMEWORK_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script must be run on macOS"
fi

# Check for required tools
command -v cmake >/dev/null 2>&1 || error "cmake is required but not installed"
command -v xcodebuild >/dev/null 2>&1 || error "xcodebuild is required but not installed"

log "Using temporary root directory: ${TEMP_ROOT}"
log "BUILD_DIR: ${BUILD_DIR}"
log "INSTALL_DIR: ${INSTALL_DIR}"

# Architectures to build
ARCHS=("x86_64" "arm64")
PLATFORMS=("macosx" "iphoneos" "iphonesimulator" "maccatalyst")

# Build function
build_for_platform() {
    local platform=$1
    local arch=$2
    local build_subdir="${BUILD_DIR}/${platform}_${arch}"
    local install_subdir="${INSTALL_DIR}/${platform}_${arch}"
    
    log "Building for ${platform} ${arch}..."
    
    mkdir -p "${build_subdir}" "${install_subdir}"
    
    # Set platform-specific variables
    case ${platform} in
        "macosx")
            local sdk="macosx"
            local min_version="10.15"
            local cmake_system_name="Darwin"
            ;;
        "iphoneos")
            local sdk="iphoneos"
            local min_version="12.0"
            local cmake_system_name="iOS"
            ;;
        "iphonesimulator")
            local sdk="iphonesimulator"
            local min_version="12.0"
            local cmake_system_name="iOS"
            ;;
        "maccatalyst")
            local sdk="macosx"
            local min_version="13.0"
            local cmake_system_name="Darwin"
            ;;
    esac
    
    # Get SDK path
    local sdk_path=$(xcrun --sdk ${sdk} --show-sdk-path)
    
    # Set compiler flags
    local cflags="-arch ${arch} -isysroot ${sdk_path}"
    local ldflags="-arch ${arch} -isysroot ${sdk_path}"
    
    # Platform-specific flags
    case ${platform} in
        "macosx")
            cflags="${cflags} -mmacosx-version-min=${min_version}"
            ldflags="${ldflags} -mmacosx-version-min=${min_version}"
            ;;
        "iphoneos")
            cflags="${cflags} -miphoneos-version-min=${min_version}"
            ldflags="${ldflags} -miphoneos-version-min=${min_version}"
            ;;
        "iphonesimulator")
            cflags="${cflags} -mios-simulator-version-min=${min_version}"
            ldflags="${ldflags} -mios-simulator-version-min=${min_version}"
            ;;
        "maccatalyst")
            cflags="${cflags} -target ${arch}-apple-ios14.0-macabi"
            ldflags="${ldflags} -target ${arch}-apple-ios14.0-macabi"
            ;;
    esac
    
    # Configure with CMake
    cd "${build_subdir}"
    
    cmake "${SOURCE_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=${cmake_system_name} \
        -DCMAKE_OSX_ARCHITECTURES=${arch} \
        -DCMAKE_OSX_SYSROOT=${sdk_path} \
        -DCMAKE_C_FLAGS="${cflags}" \
        -DCMAKE_EXE_LINKER_FLAGS="${ldflags}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${ldflags}" \
        -DCMAKE_INSTALL_PREFIX="$(realpath ${install_subdir})" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TEST=OFF \
        -DINSTALL_DOCUMENTATION=OFF \
        -DINSTALL_EXAMPLES=OFF \
        || error "CMake configuration failed for ${platform} ${arch}"
    
    # Build
    make -j$(sysctl -n hw.ncpu) || error "Build failed for ${platform} ${arch}"
    
    # Install
    make install || error "Install failed for ${platform} ${arch}"
    
    cd - > /dev/null
}

# Build for all architectures and platforms
log "Starting builds for all platforms and architectures..."

# macOS
for arch in "${ARCHS[@]}"; do
    build_for_platform "macosx" "${arch}"
done

# iOS Device
build_for_platform "iphoneos" "arm64"

# iOS Simulator
for arch in "x86_64" "arm64"; do
    build_for_platform "iphonesimulator" "${arch}"
done

# Mac Catalyst
for arch in "${ARCHS[@]}"; do
    build_for_platform "maccatalyst" "${arch}"
done

# Create universal binaries for each platform
log "Creating universal binaries..."

create_universal_binary() {
    local platform=$1
    local output_dir="${INSTALL_DIR}/${platform}_universal"
    
    mkdir -p "${output_dir}/lib" "${output_dir}/include"
    
    # Create module.modulemap for XCFramework
    cat > "${output_dir}/include/module.modulemap" << EOF
module Oniguruma {
    umbrella header "oniguruma.h"
    header "oniggnu.h"
    export *
    module * { export * }
}
EOF
    
    # Create universal library
    case ${platform} in
        "macosx")
            # Copy headers (they're the same for all architectures)
            cp -r "${INSTALL_DIR}/${platform}_x86_64/include/"* "${output_dir}/include/"
            lipo -create \
                "${INSTALL_DIR}/${platform}_x86_64/lib/libonig.a" \
                "${INSTALL_DIR}/${platform}_arm64/lib/libonig.a" \
                -output "${output_dir}/lib/libonig.a"
            ;;
        "iphonesimulator")
            # Copy headers (they're the same for all architectures)
            cp -r "${INSTALL_DIR}/${platform}_x86_64/include/"* "${output_dir}/include/"
            lipo -create \
                "${INSTALL_DIR}/${platform}_x86_64/lib/libonig.a" \
                "${INSTALL_DIR}/${platform}_arm64/lib/libonig.a" \
                -output "${output_dir}/lib/libonig.a"
            ;;
        "maccatalyst")
            # Copy headers (they're the same for all architectures)
            cp -r "${INSTALL_DIR}/${platform}_x86_64/include/"* "${output_dir}/include/"
            lipo -create \
                "${INSTALL_DIR}/${platform}_x86_64/lib/libonig.a" \
                "${INSTALL_DIR}/${platform}_arm64/lib/libonig.a" \
                -output "${output_dir}/lib/libonig.a"
            ;;
        "iphoneos")
            # iOS device only has arm64
            cp -r "${INSTALL_DIR}/${platform}_arm64/include/"* "${output_dir}/include/"
            cp "${INSTALL_DIR}/${platform}_arm64/lib/libonig.a" "${output_dir}/lib/libonig.a"
            ;;
    esac
}

create_universal_binary "macosx"
create_universal_binary "iphoneos"
create_universal_binary "iphonesimulator"
create_universal_binary "maccatalyst"

# Create XCFramework
log "Creating XCFramework..."

xcodebuild -create-xcframework \
    -library "${INSTALL_DIR}/macosx_universal/lib/libonig.a" \
    -headers "${INSTALL_DIR}/macosx_universal/include" \
    -library "${INSTALL_DIR}/iphoneos_universal/lib/libonig.a" \
    -headers "${INSTALL_DIR}/iphoneos_universal/include" \
    -library "${INSTALL_DIR}/iphonesimulator_universal/lib/libonig.a" \
    -headers "${INSTALL_DIR}/iphonesimulator_universal/include" \
    -library "${INSTALL_DIR}/maccatalyst_universal/lib/libonig.a" \
    -headers "${INSTALL_DIR}/maccatalyst_universal/include" \
    -output "${XCFRAMEWORK_PATH}" \
    || error "XCFramework creation failed"

# Verify the XCFramework
log "Verifying XCFramework..."
file "${XCFRAMEWORK_PATH}"


if [ "$GITHUB_RELEASE" = true ]; then
    # Create zip archive for GitHub release
    log "Creating zip archive..."
    cd "${TEMP_ROOT}" && zip -r "${SOURCE_DIR}/${XCFRAMEWORK_NAME}.zip" "${XCFRAMEWORK_NAME}" && cd "${SOURCE_DIR}"

    # Create GitHub release
    log "Creating GitHub release..."
    RELEASE_TAG="${VERSION}"
    RELEASE_TITLE="Oniguruma ${VERSION} with XCFramework Support"
    REPO_URL="https://github.com/krzyzanowskim/oniguruma"
    DOWNLOAD_URL="${REPO_URL}/releases/download/${RELEASE_TAG}/${XCFRAMEWORK_NAME}.zip"

    # Check if gh CLI is available
    if command -v gh >/dev/null 2>&1; then
        # Set default repository
        gh repo set-default "${REPO_URL}" || warn "Failed to set default repository"
        
        # Calculate checksum for the zip file
        CHECKSUM=$(swift package compute-checksum "${XCFRAMEWORK_NAME}.zip")

        # Update the existing Package.swift with new URL and checksum
        sed -i '' "s|url: \"[^\"]*\"|url: \"${DOWNLOAD_URL}\"|g" Package.swift
        sed -i '' "s/checksum: \"[^\"]*\"/checksum: \"${CHECKSUM}\"/g" Package.swift

        log "Package.swift updated with URL: ${DOWNLOAD_URL} and checksum: ${CHECKSUM}"
        
        # Commit the Package.swift changes
        git add Package.swift
        git commit -m "Update Package.swift for ${RELEASE_TAG} release"
        
        # Create or update the tag
        git tag -d "${RELEASE_TAG}" 2>/dev/null || true
        git tag -a "${RELEASE_TAG}" -m "${RELEASE_TITLE}"
        git push origin master || warn "Failed to push master branch"
        git push origin "${RELEASE_TAG}" --force || warn "Failed to push tag to remote"
        
        # Create or update the release
        if gh release view "${RELEASE_TAG}" >/dev/null 2>&1; then
            log "Release ${RELEASE_TAG} already exists, deleting and recreating..."
            gh release delete "${RELEASE_TAG}" --yes || warn "Failed to delete existing release"
        fi
        gh release create "${RELEASE_TAG}" \
            --title "${RELEASE_TITLE}" \
            --notes "" \
            "${XCFRAMEWORK_NAME}.zip" || warn "Failed to create GitHub release. Please create it manually."
    else
        error "gh CLI not found. Please install it to create GitHub releases."
    fi
else
    # Create zip archive locally
    log "Creating local zip archive..."
    cd "${TEMP_ROOT}" && zip -r "${SOURCE_DIR}/${XCFRAMEWORK_NAME}.zip" "${XCFRAMEWORK_NAME}" && cd "${SOURCE_DIR}"
    log "Skipping GitHub release creation. Use --github-release flag to create release."
fi


# Cleanup
log "Cleaning up temporary files..."
rm -rf "${TEMP_ROOT}"

# Cleanup build artifacts after successful release
if [ $? -eq 0 ] && [ "$GITHUB_RELEASE" = true ]; then
    log "Cleaning up build artifacts..."
    rm -rf "${XCFRAMEWORK_NAME}.zip"
fi

log "XCFramework archive created successfully: ${SOURCE_DIR}/${XCFRAMEWORK_NAME}.zip"
if [ "$GITHUB_RELEASE" = true ]; then
    log "GitHub release: ${REPO_URL}/releases/tag/${RELEASE_TAG}"
fi
log "Build completed!"
