SwiftOniguruma
==============

**A Swift-focused distribution of the Oniguruma regular expression library**

This repository is a derivative work based on a forked copy of the source code from [https://github.com/kkos/oniguruma](https://github.com/kkos/oniguruma), specifically designed to provide Swift support with a native Swift wrapper.

## About

This project contains:
- **Original Oniguruma C library source code** for building XCFramework
- **SwiftOniguruma**: A Swift wrapper providing a modern, safe API
- **Pre-built XCFramework** for Apple platforms (iOS, macOS, Mac Catalyst)
- **Swift Package Manager** integration

For comprehensive information about the Oniguruma regular expression library, including full documentation, syntax guides, and C API reference, please visit the original repository: **[https://github.com/kkos/oniguruma](https://github.com/kkos/oniguruma)**

## Key Features

- **Swift-native API** with proper error handling and memory management
- **Unicode support** including emoji and complex character sequences
- **Multiple encoding support** (UTF-8, UTF-16, ISO-8859-*, etc.)
- **Cross-platform** XCFramework for all Apple platforms
- **Comprehensive test suite** with 30+ tests including emoji support

## License

BSD license (same as original Oniguruma).


Installation
------------

### Swift Package Manager (Recommended)

Add SwiftOniguruma to your project using Swift Package Manager:

**In Xcode:**
1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/krzyzanowskim/SwiftOniguruma.git`
3. Choose the version (6.9.10 or later)

**In Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/krzyzanowskim/SwiftOniguruma.git", from: "6.9.10")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SwiftOniguruma", package: "SwiftOniguruma")
        ]
    )
]
```

### Manual XCFramework Installation

1. Download the latest XCFramework from: https://github.com/krzyzanowskim/SwiftOniguruma/releases
2. Extract `Oniguruma.xcframework.zip`
3. In Xcode, drag and drop `Oniguruma.xcframework` into your project
4. Add it to your target's "Frameworks, Libraries, and Embedded Content"

### Building from Source

To build the XCFramework from source (requires macOS):

```bash
./build_xcframework.sh
```

This builds for all Apple platforms and can optionally create a GitHub release.

### Other Platforms

For Linux, Windows, or other platforms, please refer to the original Oniguruma repository: [https://github.com/kkos/oniguruma](https://github.com/kkos/oniguruma)


Swift Usage
-----------

### SwiftOniguruma

This package includes SwiftOniguruma, a Swift wrapper that provides a convenient API for using Oniguruma from Swift applications.

### Setup

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/krzyzanowskim/SwiftOniguruma.git", from: "6.9.10")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SwiftOniguruma", package: "SwiftOniguruma")
        ]
    )
]
```

### Basic Usage

```swift
import SwiftOniguruma

// Create a regex pattern - must specify both options and syntax
let regex = try OnigRegex(pattern: "hello", options: .default, syntax: .perlNG)

// Search for matches
if let match = regex.search(in: "hello world") {
    print(match.matchedString)  // "hello"
    print(match.range)          // Range in the original string
}

// No match returns nil
let noMatch = regex.search(in: "goodbye world")  // nil
```

### Advanced Features

#### Syntax Types

SwiftOniguruma supports multiple regex syntax flavors:

```swift
// Perl_NG syntax (default behavior for most patterns)
let perlRegex = try OnigRegex(pattern: "^world", options: .default, syntax: .perlNG)
// In Perl_NG, ^ only matches at string start

// Ruby/Oniguruma syntax  
let rubyRegex = try OnigRegex(pattern: "^world", options: .default, syntax: .ruby)
// In Ruby, ^ matches at line boundaries

// Other supported syntaxes
let pythonRegex = try OnigRegex(pattern: "\\bhello\\b", options: .default, syntax: .python)
let javaRegex = try OnigRegex(pattern: "pattern", options: .default, syntax: .java)
let posixRegex = try OnigRegex(pattern: "[[:alpha:]]+", options: .default, syntax: .posixExtended)
```

#### Capture Groups

```swift
let regex = try OnigRegex(pattern: "(\\w+)\\s+(\\w+)", options: .default, syntax: .perlNG)
if let match = regex.search(in: "hello world") {
    print(match.matchedString)           // "hello world"
    print(match.captures[0].matchedString) // "hello world" (full match)
    print(match.captures[1].matchedString) // "hello" (first group)
    print(match.captures[2].matchedString) // "world" (second group)
}
```

#### Find All Matches

```swift
let regex = try OnigRegex(pattern: "\\d+", options: .default, syntax: .perlNG)
let matches = regex.findAll(in: "There are 123 apples and 456 oranges")

for match in matches {
    print(match.matchedString)  // "123", then "456"
}
```

#### Regex Options

```swift
// Case-insensitive matching
let regex = try OnigRegex(pattern: "HELLO", options: .ignoreCase, syntax: .perlNG)
let match = regex.search(in: "hello world")  // matches

// Multiline mode (makes . match newlines)
let regex = try OnigRegex(pattern: "hello.world", options: .multiline, syntax: .perlNG)
let match = regex.search(in: "hello\nworld")  // matches

// For ^ and $ to match line boundaries in Perl_NG, use negateSingleline
let regex = try OnigRegex(pattern: "^world", options: .negateSingleline, syntax: .perlNG)
let match = regex.search(in: "hello\nworld")  // matches

// Multiple options
let regex = try OnigRegex(pattern: "pattern", options: [.ignoreCase, .multiline], syntax: .perlNG)
```

#### Position-Specific Matching

```swift
let regex = try OnigRegex(pattern: "world", options: .default, syntax: .perlNG)
let string = "hello world"

// Match at a specific position
if let match = regex.match(in: string, at: string.index(string.startIndex, offsetBy: 6)) {
    print(match.matchedString)  // "world"
}

// Search within a range
let startIndex = string.index(string.startIndex, offsetBy: 6)
if let match = regex.search(in: string, range: startIndex..<string.endIndex) {
    print(match.matchedString)  // "world"
}
```

#### Unicode Support

```swift
// Unicode characters work seamlessly
let regex = try OnigRegex(pattern: "🚀", options: .default, syntax: .perlNG)
let match = regex.search(in: "Hello 🚀 World")  // matches

// Unicode property classes
let regex = try OnigRegex(pattern: "[\\p{L}]+", options: .default, syntax: .perlNG)
let match = regex.search(in: "Héllo wørld")     // "Héllo"
```

#### Error Handling

```swift
do {
    let regex = try OnigRegex(pattern: "valid pattern", options: .default, syntax: .perlNG)
    // Use regex...
} catch let error as OnigError {
    print("Regex error: \(error.localizedDescription)")
} catch {
    print("Other error: \(error)")
}
```

### API Reference

#### OnigRegex

- `init(pattern: String, options: OnigOptions, syntax: OnigSyntax) throws`
- `search(in string: String, range: Range<String.Index>? = nil) -> OnigMatch?`
- `search(in string: String, range: Range<String.Index>? = nil, options: SearchOptions) -> OnigMatch?`
- `match(in string: String, at index: String.Index) -> OnigMatch?`
- `match(in string: String, at index: String.Index, options: SearchOptions) -> OnigMatch?`
- `findAll(in string: String) -> [OnigMatch]`

#### OnigMatch

- `range: Range<String.Index>` - Range of the match in the original string
- `captures: [OnigCapture]` - Array of capture groups (index 0 is the full match)
- `matchedString: String` - The matched text

#### OnigCapture

- `range: Range<String.Index>?` - Range of the capture (nil for empty groups)
- `matchedString: String?` - The captured text (nil for empty groups)

#### Available Syntax Types (OnigSyntax)

- `.asis` - ASIS syntax
- `.posixBasic` - POSIX Basic syntax
- `.posixExtended` - POSIX Extended syntax  
- `.emacs` - Emacs syntax
- `.grep` - Grep syntax
- `.gnuRegex` - GNU Regex syntax
- `.java` - Java syntax
- `.perl` - Perl syntax
- `.perlNG` - Perl syntax with named groups
- `.ruby` - Ruby syntax
- `.python` - Python syntax
- `.oniguruma` - Oniguruma syntax (Ruby-like)

#### Available Compilation Options (OnigOptions)

- `.none` / `.default` - No options
- `.ignoreCase` - Case-insensitive matching
- `.extend` - Extended pattern form (ignore whitespace and comments)
- `.multiline` - '.' matches newline
- `.singleline` - '^' and '$' match only string boundaries
- `.negateSingleline` - Clear singleline ('^' and '$' match line boundaries)
- `.findLongest` - Find the longest match
- `.findNotEmpty` - Don't match empty strings
- `.dontCaptureGroup` - Only named capture groups
- `.captureGroup` - Capture unnamed groups as well

#### Available Search Options (SearchOptions)

- `.none` - No options
- `.notBeginOfLine` - Don't regard the beginning of string as line boundary
- `.notEndOfLine` - Don't regard the end of string as line boundary
- `.notBeginString` - Don't regard the beginning of string as string start
- `.notEndString` - Don't regard the end as string endpoint
- `.notBeginPosition` - Don't regard the start position as start position of search

### Performance

SwiftOniguruma handles UTF-8 encoding conversion efficiently and provides competitive performance for regex operations. The underlying Oniguruma engine is highly optimized for various character encodings and complex patterns.

## Additional Resources

For more information about Oniguruma, including:
- **Complete API documentation**
- **Regular expression syntax guide** 
- **Sample programs and test cases**
- **Platform-specific build instructions**
- **Advanced features and options**

Please visit the original repository: **[https://github.com/kkos/oniguruma](https://github.com/kkos/oniguruma)**

## Contributing

This repository focuses specifically on Swift integration. For contributions to the core Oniguruma library, please contribute to the original repository. For Swift wrapper improvements, feel free to open issues and pull requests here.
