import XCTest
@testable import SwiftOniguruma

final class ZWJTests: XCTestCase {
    
    func testZWJSequenceRegexMatching() throws {
        // Family emoji: 👨‍👩‍👧‍👦 = Man + ZWJ + Woman + ZWJ + Girl + ZWJ + Boy
        let man = "\u{1F468}"        // 👨 Man
        let zwj = "\u{200D}"         // ZWJ (Zero Width Joiner)
        let woman = "\u{1F469}"      // 👩 Woman
        let girl = "\u{1F467}"       // 👧 Girl  
        let boy = "\u{1F466}"        // 👦 Boy
        
        let familyEmoji = man + zwj + woman + zwj + girl + zwj + boy
        let text = "Hello \(familyEmoji) world"
        
        print("Testing ZWJ sequence: '\(text)'")
        print("Character count: \(text.count)")
        print("UTF-16 count: \(text.utf16.count)")
        print("UTF-8 count: \(text.utf8.count)")
        
        // Test simple pattern that should match the entire text
        let regex = try OnigRegex(pattern: ".*")
        let match = regex.search(in: text)
        
        XCTAssertNotNil(match, "Should find a match")
        
        guard let match = match else { return }
        
        print("Match range: \(match.range)")
        print("Match range lowerBound: \(match.range.lowerBound)")
        print("Match range upperBound: \(match.range.upperBound)")
        
        // Test the problematic UTF-16 distance calculation
        let startOffset = text.utf16.distance(from: text.startIndex, to: match.range.lowerBound)
        let endOffset = text.utf16.distance(from: text.startIndex, to: match.range.upperBound)
        
        print("StartOffset: \(startOffset)")
        print("EndOffset: \(endOffset)")
        
        XCTAssertTrue(startOffset <= endOffset, "Start offset should be <= end offset")
        XCTAssertEqual(startOffset, 0, "Should start at beginning")
        XCTAssertEqual(endOffset, text.utf16.count, "Should end at text end")
    }
    
    func testZWJSequencePartialMatching() throws {
        // Test pattern that matches just the emoji
        let familyEmoji = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let text = "Hello \(familyEmoji) world"
        
        // Pattern to match emoji characters (simplified)
        let regex = try OnigRegex(pattern: "[\u{1F000}-\u{1F9FF}\u{200D}]+")
        let match = regex.search(in: text)
        
        XCTAssertNotNil(match, "Should find emoji match")
        
        guard let match = match else { return }
        
        print("Emoji match range: \(match.range)")
        
        // This is where the issue likely occurs - partial match within ZWJ sequence
        let startOffset = text.utf16.distance(from: text.startIndex, to: match.range.lowerBound)
        let endOffset = text.utf16.distance(from: text.startIndex, to: match.range.upperBound)
        
        print("Emoji StartOffset: \(startOffset)")
        print("Emoji EndOffset: \(endOffset)")
        
        XCTAssertTrue(startOffset <= endOffset, "Start offset should be <= end offset")
    }
    
    func testProblematicZWJCase() throws {
        // This test reproduces the exact case that was causing fatal errors
        let familyEmoji = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let text = "let \(familyEmoji) = \"family\""
        
        print("Problematic case: '\(text)'")
        print("Character count: \(text.count)")
        print("UTF-16 count: \(text.utf16.count)")
        
        // Test with a complex pattern that might split the ZWJ sequence
        let regex = try OnigRegex(pattern: "\\w+")
        
        var searchRange = text.startIndex..<text.endIndex
        while let match = regex.search(in: String(text[searchRange])) {
            let absoluteStart = text.index(searchRange.lowerBound, offsetBy: text.distance(from: text.startIndex, to: match.range.lowerBound))
            let absoluteEnd = text.index(searchRange.lowerBound, offsetBy: text.distance(from: text.startIndex, to: match.range.upperBound))
            
            // Test UTF-16 distance calculation
            let startOffset = text.utf16.distance(from: text.startIndex, to: absoluteStart)
            let endOffset = text.utf16.distance(from: text.startIndex, to: absoluteEnd)
            
            print("Match: '\(text[absoluteStart..<absoluteEnd])' at UTF-16 [\(startOffset)...\(endOffset)]")
            
            if startOffset > endOffset {
                XCTFail("Invalid range detected: start=\(startOffset) > end=\(endOffset)")
            }
            
            // Move to next potential match
            if absoluteEnd < text.endIndex {
                searchRange = absoluteEnd..<text.endIndex
            } else {
                break
            }
        }
    }
    
    func testDirectZWJMatching() throws {
        // Test patterns that directly target ZWJ sequences
        let familyEmoji = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let text = "let \(familyEmoji) = \"family\""
        
        print("\nDirect ZWJ matching test:")
        print("Text: '\(text)'")
        
        // Test pattern that matches anything (like TextMate might do)
        let anyPattern = try OnigRegex(pattern: ".")
        var pos = text.startIndex
        var matchCount = 0
        
        while pos < text.endIndex && matchCount < 30 { // Safety limit
            let remainingText = String(text[pos...])
            guard let match = anyPattern.search(in: remainingText) else { break }
            
            // Calculate absolute positions
            let absoluteStart = text.index(pos, offsetBy: text.distance(from: remainingText.startIndex, to: match.range.lowerBound))
            let absoluteEnd = text.index(pos, offsetBy: text.distance(from: remainingText.startIndex, to: match.range.upperBound))
            
            // Test the problematic conversion
            let startOffset = text.utf16.distance(from: text.startIndex, to: absoluteStart)
            let endOffset = text.utf16.distance(from: text.startIndex, to: absoluteEnd)
            
            let matchedChar = text[absoluteStart..<absoluteEnd]
            print("  Match \(matchCount): '\(matchedChar)' at UTF-16 [\(startOffset)...\(endOffset)]")
            
            if startOffset > endOffset {
                XCTFail("Invalid range at match \(matchCount): start=\(startOffset) > end=\(endOffset)")
            }
            
            pos = absoluteEnd
            matchCount += 1
        }
        
        print("Total matches: \(matchCount)")
    }
    
    func testGraphemeClusterBoundaries() {
        let familyEmoji = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let text = "Hello \(familyEmoji) world"
        
        print("\nTesting grapheme cluster boundaries:")
        print("Text: '\(text)'")
        print("Character count: \(text.count)")
        print("UTF-16 count: \(text.utf16.count)")
        
        // Test that we can safely enumerate grapheme clusters
        for (index, char) in text.enumerated() {
            let charString = String(char)
            print("Char \(index): '\(charString)' (UTF-16 count: \(charString.utf16.count))")
        }
        
        // Test range of composed character sequence containing emoji
        let emojiStartIndex = text.index(text.startIndex, offsetBy: 6) // After "Hello "
        let sequenceRange = text.rangeOfComposedCharacterSequence(at: emojiStartIndex)
        print("Grapheme cluster range for emoji: \(sequenceRange)")
        
        let clusterText = text[sequenceRange]
        print("Cluster text: '\(clusterText)'")
        print("Cluster UTF-16 count: \(clusterText.utf16.count)")
    }
}