#!/bin/bash

set -e

# Configuration
LIBRARY_NAME="oniguruma"
VERSION="6.9.10"
BUILD_DIR="build_xcframework"
INSTALL_DIR="install"
XCFRAMEWORK_NAME="Oniguruma.xcframework"

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

# Clean previous builds
log "Cleaning previous builds..."
rm -rf "${BUILD_DIR}" "${XCFRAMEWORK_NAME}" "${INSTALL_DIR}"

# Create build directory
mkdir -p "${BUILD_DIR}"

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
    
    cmake ../.. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=${cmake_system_name} \
        -DCMAKE_OSX_ARCHITECTURES=${arch} \
        -DCMAKE_OSX_SYSROOT=${sdk_path} \
        -DCMAKE_C_FLAGS="${cflags}" \
        -DCMAKE_EXE_LINKER_FLAGS="${ldflags}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${ldflags}" \
        -DCMAKE_INSTALL_PREFIX="../../${install_subdir}" \
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
    -output "${XCFRAMEWORK_NAME}" \
    || error "XCFramework creation failed"

# Verify the XCFramework
log "Verifying XCFramework..."
xcodebuild -checkFirstLaunchForSimulator || true
file "${XCFRAMEWORK_NAME}"

# Create info file
log "Creating info file..."
cat > "${XCFRAMEWORK_NAME}.info" << EOF
Oniguruma ${VERSION} XCFramework
Built on: $(date)
Platforms: macOS, iOS, iOS Simulator, Mac Catalyst
Architectures: x86_64, arm64

This XCFramework contains the Oniguruma regular expression library built as
static libraries for all Apple platforms.

To use in Xcode:
1. Drag and drop the ${XCFRAMEWORK_NAME} into your Xcode project
2. Add it to your target's "Frameworks, Libraries, and Embedded Content"
3. Set "Embed & Sign" or "Do Not Embed" as appropriate
4. Include the headers: #include <oniguruma.h>

License: BSD License (see COPYING file in the original source)
EOF

# Create zip archive for GitHub release
log "Creating zip archive..."
zip -r "${XCFRAMEWORK_NAME}.zip" "${XCFRAMEWORK_NAME}"

# Create GitHub release
log "Creating GitHub release..."
RELEASE_TAG="v${VERSION}-xcframework"
RELEASE_TITLE="Oniguruma v${VERSION} with XCFramework Support"
RELEASE_NOTES="$(cat <<EOF
# Oniguruma v${VERSION} with XCFramework Support

This release includes pre-built XCFramework binaries for all Apple platforms:
- macOS (x86_64, arm64)
- iOS (arm64)
- iOS Simulator (x86_64, arm64)
- Mac Catalyst (x86_64, arm64)

## What's New
- Added XCFramework build support for easy integration into iOS/macOS projects
- Built with CMake for consistent cross-platform compilation
- Optimized for Release configuration with static linking

## Installation

### Using XCFramework
1. Download \`${XCFRAMEWORK_NAME}.zip\`
2. Extract and add to your Xcode project
3. Add to your target's "Frameworks, Libraries, and Embedded Content"

### Using Swift Package Manager
Add this repository as a Swift Package dependency in Xcode or add to your Package.swift:

\`\`\`swift
dependencies: [
    .package(url: "https://github.com/krzyzanowskim/oniguruma.git", from: "${VERSION}")
]
\`\`\`

## License
BSD License (see COPYING file)
EOF
)"

# Check if gh CLI is available
if command -v gh >/dev/null 2>&1; then
    # Create or update the tag
    git tag -f "${RELEASE_TAG}" || git tag "${RELEASE_TAG}"
    
    # Create the release
    gh release create "${RELEASE_TAG}" \
        --title "${RELEASE_TITLE}" \
        --notes "${RELEASE_NOTES}" \
        "${XCFRAMEWORK_NAME}.zip" || warn "Failed to create GitHub release. Please create it manually."
else
    warn "gh CLI not found. Please install it to auto-create GitHub releases."
    log "Tag created: ${RELEASE_TAG}"
    log "Upload ${XCFRAMEWORK_NAME}.zip to GitHub release manually"
fi

# Create Swift Package Manager Package.swift
log "Creating Package.swift for Swift Package Manager..."
REPO_URL="https://github.com/krzyzanowskim/oniguruma"
DOWNLOAD_URL="${REPO_URL}/releases/download/${RELEASE_TAG}/${XCFRAMEWORK_NAME}.zip"

cat > Package.swift << EOF
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Oniguruma",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "Oniguruma",
            targets: ["Oniguruma"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Oniguruma",
            url: "${DOWNLOAD_URL}",
            checksum: "CHECKSUM_PLACEHOLDER"
        )
    ]
)
EOF

# Calculate checksum for the zip file
CHECKSUM=\$(swift package compute-checksum "${XCFRAMEWORK_NAME}.zip")
sed -i '' "s/CHECKSUM_PLACEHOLDER/\${CHECKSUM}/g" Package.swift

log "Package.swift created with checksum: \${CHECKSUM}"

# Cleanup
log "Cleaning up intermediate files..."
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"

# Cleanup build artifacts after successful release
if [ $? -eq 0 ]; then
    log "Cleaning up build artifacts..."
    rm -rf "${XCFRAMEWORK_NAME}" "${XCFRAMEWORK_NAME}.zip" "${XCFRAMEWORK_NAME}.info"
fi

log "XCFramework created successfully: ${XCFRAMEWORK_NAME}"
log "GitHub release: ${REPO_URL}/releases/tag/${RELEASE_TAG}"
log "Build completed!"
