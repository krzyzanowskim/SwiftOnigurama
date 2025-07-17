import Foundation
import Oniguruma

public class OnigRegex {
    private var regex: Oniguruma.OnigRegex?
    
    public init(pattern: String, options: OnigOptions = .default, syntax: UnsafeMutablePointer<OnigSyntaxType>? = nil) throws {
        var reg: Oniguruma.OnigRegex?
        var errorInfo = OnigErrorInfo()
        
        let patternBytes = Array(pattern.utf8)
        let result: Int32
        if let syntax = syntax {
            result = patternBytes.withUnsafeBufferPointer { buffer in
                onig_new(&reg, buffer.baseAddress!, buffer.baseAddress! + buffer.count,
                         options.rawValue, &OnigEncodingUTF8, syntax, &errorInfo)
            }
        } else {
            result = patternBytes.withUnsafeBufferPointer { buffer in
                onig_new(&reg, buffer.baseAddress!, buffer.baseAddress! + buffer.count,
                         options.rawValue, &OnigEncodingUTF8, &OnigSyntaxPerl_NG, &errorInfo)
            }
        }
        
        guard result == ONIG_NORMAL else {
            throw OnigError(code: result)
        }
        
        self.regex = reg
    }
    
    /// Convenience initializer that accepts raw OnigOptionType for backward compatibility
    public convenience init(pattern: String, options: OnigOptionType, syntax: UnsafeMutablePointer<OnigSyntaxType>? = nil) throws {
        try self.init(pattern: pattern, options: OnigOptions(rawValue: options), syntax: syntax)
    }
    
    deinit {
        if let regex = regex {
            onig_free(regex)
        }
    }
    
    public func search(in string: String, range: Range<String.Index>? = nil) -> OnigMatch? {
        return search(in: string, range: range, options: .none)
    }
    
    public func search(in string: String, range: Range<String.Index>? = nil, options: SearchOptions) -> OnigMatch? {
        guard let regex = regex else { return nil }
        
        let utf8String = Array(string.utf8)
        let searchRange = range.map { r in
            (string.utf8.distance(from: string.startIndex, to: r.lowerBound),
             string.utf8.distance(from: string.startIndex, to: r.upperBound))
        } ?? (0, utf8String.count)
        
        guard let region = onig_region_new() else { return nil }
        defer { onig_region_free(region, 1) }
        
        let result = utf8String.withUnsafeBufferPointer { buffer in
            onig_search(regex, buffer.baseAddress!, buffer.baseAddress! + buffer.count,
                       buffer.baseAddress! + searchRange.0, buffer.baseAddress! + searchRange.1,
                       region, options.rawValue)
        }
        
        guard result >= 0 else { return nil }
        
        return Self.createMatch(from: region, string: string)
    }
    
    public func match(in string: String, at index: String.Index) -> OnigMatch? {
        return match(in: string, at: index, options: .none)
    }
    
    public func match(in string: String, at index: String.Index, options: SearchOptions) -> OnigMatch? {
        guard let regex = regex else { return nil }
        
        let utf8String = Array(string.utf8)
        let byteOffset = string.utf8.distance(from: string.startIndex, to: index)
        
        guard let region = onig_region_new() else { return nil }
        defer { onig_region_free(region, 1) }
        
        let result = utf8String.withUnsafeBufferPointer { buffer in
            onig_match(regex, buffer.baseAddress!, buffer.baseAddress! + buffer.count,
                      buffer.baseAddress! + byteOffset, region, options.rawValue)
        }
        
        guard result >= 0 else { return nil }
        
        return Self.createMatch(from: region, string: string)
    }
    
    public func findAll(in string: String) -> [OnigMatch] {
        var matches: [OnigMatch] = []
        var searchStart = string.startIndex
        
        while searchStart < string.endIndex {
            let searchRange = searchStart..<string.endIndex
            guard let match = search(in: string, range: searchRange) else { break }
            
            matches.append(match)
            
            if match.range.isEmpty {
                searchStart = string.index(after: match.range.lowerBound)
            } else {
                searchStart = match.range.upperBound
            }
        }
        
        return matches
    }
    
    // MARK: - Internal Helper Methods
    
    private static func createMatch(from region: UnsafeMutablePointer<OnigRegion>, string: String) -> OnigMatch? {
        guard let regionPtr = region.pointee.beg,
              let endPtr = region.pointee.end,
              region.pointee.num_regs > 0 else { return nil }
        
        let utf8View = string.utf8
        let startByteOffset = Int(regionPtr[0])
        let endByteOffset = Int(endPtr[0])
        
        // Handle potential out-of-bounds indices more gracefully
        let startIndex = utf8View.index(utf8View.startIndex, offsetBy: startByteOffset, limitedBy: utf8View.endIndex) ?? utf8View.endIndex
        let endIndex = utf8View.index(utf8View.startIndex, offsetBy: endByteOffset, limitedBy: utf8View.endIndex) ?? utf8View.endIndex
        
        // Convert from UTF8View.Index to String.Index
        let stringStartIndex = String.Index(startIndex, within: string) ?? string.endIndex
        let stringEndIndex = String.Index(endIndex, within: string) ?? string.endIndex
        
        // Ensure valid range for ZWJ sequences and complex Unicode
        let matchRange = createSafeRange(start: stringStartIndex, end: stringEndIndex, in: string)
        
        // Create capture groups
        var captures: [OnigCapture] = []
        for i in 0..<Int(region.pointee.num_regs) {
            let capStartByte = Int(regionPtr[i])
            let capEndByte = Int(endPtr[i])
            
            if capStartByte >= 0 && capEndByte >= 0 {
                let capStartIndex = utf8View.index(utf8View.startIndex, offsetBy: capStartByte, limitedBy: utf8View.endIndex) ?? utf8View.endIndex
                let capEndIndex = utf8View.index(utf8View.startIndex, offsetBy: capEndByte, limitedBy: utf8View.endIndex) ?? utf8View.endIndex
                
                let stringCapStartIndex = String.Index(capStartIndex, within: string) ?? string.endIndex
                let stringCapEndIndex = String.Index(capEndIndex, within: string) ?? string.endIndex
                
                // Ensure valid range for ZWJ sequences and complex Unicode
                let captureRange = createSafeRange(start: stringCapStartIndex, end: stringCapEndIndex, in: string)
                captures.append(OnigCapture(range: captureRange, string: string))
            } else {
                captures.append(OnigCapture(range: nil, string: string))
            }
        }
        
        return OnigMatch(range: matchRange, captures: captures, sourceString: string)
    }
    
    /// Creates a safe range that respects ZWJ sequences and complex Unicode
    private static func createSafeRange(start: String.Index, end: String.Index, in text: String) -> Range<String.Index> {
        // Handle case where start > end (can happen with complex Unicode)
        guard start <= end else {
            // If indices are swapped, create a zero-width range at the earlier position
            return start..<start
        }
        
        // Check if the text contains ZWJ sequences that could cause issues
        let containsZWJ = text.contains("\u{200D}")
        
        if containsZWJ {
            // For ZWJ sequences, adjust to grapheme cluster boundaries
            let adjustedStart: String.Index
            let adjustedEnd: String.Index
            
            if start == text.endIndex {
                adjustedStart = text.endIndex
            } else {
                let startClusterRange = text.rangeOfComposedCharacterSequence(at: start)
                adjustedStart = startClusterRange.lowerBound
            }
            
            if end == text.endIndex {
                adjustedEnd = text.endIndex
            } else {
                let endClusterRange = text.rangeOfComposedCharacterSequence(at: end)
                // Use lowerBound to avoid being inside a cluster
                adjustedEnd = endClusterRange.lowerBound
            }
            
            // Ensure final range is valid
            if adjustedStart <= adjustedEnd {
                return adjustedStart..<adjustedEnd
            } else {
                // Fall back to zero-width range
                return adjustedStart..<adjustedStart
            }
        } else {
            // For normal text, the range should be valid as-is
            return start..<end
        }
    }
}

public struct OnigMatch {
    public let range: Range<String.Index>
    public let captures: [OnigCapture]
    private let sourceString: String
    
    // Internal initializer - no unsafe pointers in public API
    internal init(range: Range<String.Index>, captures: [OnigCapture], sourceString: String) {
        self.range = range
        self.captures = captures
        self.sourceString = sourceString
    }
    
    public var matchedString: String {
        String(sourceString[range])
    }
}

public struct OnigCapture {
    public let range: Range<String.Index>?
    private let sourceString: String
    
    internal init(range: Range<String.Index>?, string: String) {
        self.range = range
        self.sourceString = string
    }
    
    public var matchedString: String? {
        guard let range = range else { return nil }
        return String(sourceString[range])
    }
}

public struct OnigError: Error {
    public let code: Int32
    
    init(code: Int32) {
        self.code = code
    }
    
    public var localizedDescription: String {
        return "Oniguruma error code: \(code)"
    }
}

/// Options for regex compilation
public struct OnigOptions: OptionSet {
    public let rawValue: OnigOptionType
    
    public init(rawValue: OnigOptionType) {
        self.rawValue = rawValue
    }
    
    /// Default options (none)
    public static let none = OnigOptions(rawValue: ONIG_OPTION_NONE)
    
    /// Default options (same as none)
    public static let `default` = OnigOptions(rawValue: ONIG_OPTION_DEFAULT)
    
    // MARK: - Basic Options
    
    /// Case insensitive matching
    public static let ignoreCase = OnigOptions(rawValue: ONIG_OPTION_IGNORECASE)
    
    /// Extended pattern form (ignore whitespace and comments)
    public static let extend = OnigOptions(rawValue: ONIG_OPTION_EXTEND)
    
    /// '.' matches newline (commonly called "dotall" or "singleline" in other engines)
    public static let multiline = OnigOptions(rawValue: ONIG_OPTION_MULTILINE)
    
    /// '^' and '$' match only string boundaries (not line boundaries)
    public static let singleline = OnigOptions(rawValue: ONIG_OPTION_SINGLELINE)
    
    /// Find longest match
    public static let findLongest = OnigOptions(rawValue: ONIG_OPTION_FIND_LONGEST)
    
    /// Ignore empty matches
    public static let findNotEmpty = OnigOptions(rawValue: ONIG_OPTION_FIND_NOT_EMPTY)
    
    /// Clear SINGLELINE option (for POSIX_BASIC, POSIX_EXTENDED, PERL, etc.)
    public static let negateSingleline = OnigOptions(rawValue: ONIG_OPTION_NEGATE_SINGLELINE)
    
    // MARK: - Capture Options
    
    /// Only named capture groups
    public static let dontCaptureGroup = OnigOptions(rawValue: ONIG_OPTION_DONT_CAPTURE_GROUP)
    
    /// Capture unnamed groups as well
    public static let captureGroup = OnigOptions(rawValue: ONIG_OPTION_CAPTURE_GROUP)
    
    // MARK: - ASCII-only Options
    
    /// IGNORECASE restricted to ASCII characters
    public static let ignoreCaseIsASCII = OnigOptions(rawValue: ONIG_OPTION_IGNORECASE_IS_ASCII)
    
    /// Word characters (\w, \p{Word}, [[:word:]]) are ASCII only
    public static let wordIsASCII = OnigOptions(rawValue: ONIG_OPTION_WORD_IS_ASCII)
    
    /// Digit characters (\d, \p{Digit}, [[:digit:]]) are ASCII only
    public static let digitIsASCII = OnigOptions(rawValue: ONIG_OPTION_DIGIT_IS_ASCII)
    
    /// Space characters (\s, \p{Space}, [[:space:]]) are ASCII only
    public static let spaceIsASCII = OnigOptions(rawValue: ONIG_OPTION_SPACE_IS_ASCII)
    
    /// POSIX properties are ASCII only
    public static let posixIsASCII = OnigOptions(rawValue: ONIG_OPTION_POSIX_IS_ASCII)
    
    // MARK: - Text Segment Options
    
    /// Extended grapheme cluster mode
    public static let textSegmentExtendedGraphemeCluster = OnigOptions(rawValue: ONIG_OPTION_TEXT_SEGMENT_EXTENDED_GRAPHEME_CLUSTER)
    
    /// Word mode
    public static let textSegmentWord = OnigOptions(rawValue: ONIG_OPTION_TEXT_SEGMENT_WORD)
    
    // MARK: - Advanced Options
    
    /// Check validity of input string
    public static let checkValidityOfString = OnigOptions(rawValue: ONIG_OPTION_CHECK_VALIDITY_OF_STRING)
    
    /// Callback for each match
    public static let callbackEachMatch = OnigOptions(rawValue: ONIG_OPTION_CALLBACK_EACH_MATCH)
    
    /// Match must consume the entire string
    public static let matchWholeString = OnigOptions(rawValue: ONIG_OPTION_MATCH_WHOLE_STRING)
}

