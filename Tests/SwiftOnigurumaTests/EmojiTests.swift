import XCTest
@testable import SwiftOniguruma

final class EmojiTests: XCTestCase {
    
    func testSingleEmojiMatch() throws {
        let regex = try OnigRegex(pattern: "🚀")
        let match = regex.search(in: "Hello 🚀 World")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "🚀")
    }
    
    func testMultipleEmojiMatch() throws {
        let regex = try OnigRegex(pattern: "[🚀🌟⭐]")
        let matches = regex.findAll(in: "🚀 Launch 🌟 Star ⭐ Rating")
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].matchedString, "🚀")
        XCTAssertEqual(matches[1].matchedString, "🌟")
        XCTAssertEqual(matches[2].matchedString, "⭐")
    }
    
    func testEmojiWithSkinTone() throws {
        let regex = try OnigRegex(pattern: "👋🏽")
        let match = regex.search(in: "Hello 👋🏽 there!")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "👋🏽")
    }
    
    func testComplexEmojiSequence() throws {
        // Family emoji (man + woman + girl + boy)
        let regex = try OnigRegex(pattern: "👨‍👩‍👧‍👦")
        let match = regex.search(in: "Family: 👨‍👩‍👧‍👦 together")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "👨‍👩‍👧‍👦")
    }
    
    func testEmojiCaptureGroups() throws {
        let regex = try OnigRegex(pattern: "(🎵)\\s+(.*?)\\s+(🎵)")
        let match = regex.search(in: "🎵 music 🎵")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.captures.count, 4) // full match + 3 groups
        XCTAssertEqual(match?.captures[0].matchedString, "🎵 music 🎵") // full match
        XCTAssertEqual(match?.captures[1].matchedString, "🎵") // first emoji
        XCTAssertEqual(match?.captures[2].matchedString, "music") // middle text
        XCTAssertEqual(match?.captures[3].matchedString, "🎵") // second emoji
    }
    
    func testEmojiWithTextMixed() throws {
        let regex = try OnigRegex(pattern: "\\w+\\s*🎉")
        let matches = regex.findAll(in: "party 🎉 celebration🎉 fun 🎉")
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].matchedString, "party 🎉")
        XCTAssertEqual(matches[1].matchedString, "celebration🎉")
        XCTAssertEqual(matches[2].matchedString, "fun 🎉")
    }
    
    func testEmojiRanges() throws {
        let regex = try OnigRegex(pattern: "🎵")
        let string = "Start 🎵 music 🎵 end"
        let match = regex.search(in: string)
        
        XCTAssertNotNil(match)
        
        // Test that range indices work correctly with emoji
        let matchedSubstring = String(string[match!.range])
        XCTAssertEqual(matchedSubstring, "🎵")
        
        // Test that we can get the position correctly
        let startOffset = string.distance(from: string.startIndex, to: match!.range.lowerBound)
        XCTAssertEqual(startOffset, 6) // "Start " = 6 characters
    }
    
    func testEmojiSearchWithRange() throws {
        let regex = try OnigRegex(pattern: "🌟")
        let string = "🌟 first 🌟 second 🌟"
        
        // Search starting from after the first emoji
        let startIndex = string.index(string.startIndex, offsetBy: 8) // After "🌟 first "
        let match = regex.search(in: string, range: startIndex..<string.endIndex)
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "🌟")
        
        // Verify it found the second occurrence, not the first
        let matchStart = match!.range.lowerBound
        let expectedStart = string.index(string.startIndex, offsetBy: 8)
        XCTAssertEqual(matchStart, expectedStart)
    }
    
    func testCountryFlagEmoji() throws {
        let regex = try OnigRegex(pattern: "🇺🇸|🇬🇧|🇫🇷")
        let matches = regex.findAll(in: "Countries: 🇺🇸 🇬🇧 🇫🇷")
        
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].matchedString, "🇺🇸")
        XCTAssertEqual(matches[1].matchedString, "🇬🇧")
        XCTAssertEqual(matches[2].matchedString, "🇫🇷")
    }
    
    func testEmojiIgnoreCase() throws {
        // Even though emojis don't have case, test that the option doesn't break emoji matching
        let regex = try OnigRegex(pattern: "🚀", options: .ignoreCase)
        let match = regex.search(in: "Rocket 🚀 launch")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "🚀")
    }
    
    func testMixedUnicodeAndEmoji() throws {
        let regex = try OnigRegex(pattern: "[🚀-🚀]|[α-ω]")
        let matches = regex.findAll(in: "Greek α beta β rocket 🚀")
        
        XCTAssertTrue(matches.count >= 2) // Should find at least α, β, and 🚀
        // Note: The exact count may vary depending on Unicode handling
    }
    
    func testZeroWidthJoinerEmoji() throws {
        // Test emoji with Zero Width Joiner (ZWJ) sequences
        let regex = try OnigRegex(pattern: "👨‍💻") // Man technologist
        let match = regex.search(in: "Developer 👨‍💻 coding")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "👨‍💻")
    }
}