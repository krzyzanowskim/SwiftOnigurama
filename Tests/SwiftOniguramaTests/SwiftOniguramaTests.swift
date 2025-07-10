import XCTest
@testable import SwiftOnigurama

final class SwiftOniguramaTests: XCTestCase {
    
    func testBasicPatternCompilation() throws {
        let regex = try OnigRegex(pattern: "hello")
        XCTAssertNotNil(regex)
    }
    
    func testInvalidPatternThrowsError() {
        XCTAssertThrowsError(try OnigRegex(pattern: "[")) { error in
            XCTAssertTrue(error is OnigError)
        }
    }
    
    func testSimpleStringMatch() throws {
        let regex = try OnigRegex(pattern: "world")
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "world")
    }
    
    func testNoMatchReturnsNil() throws {
        let regex = try OnigRegex(pattern: "xyz")
        let match = regex.search(in: "hello world")
        
        XCTAssertNil(match)
    }
    
    func testMatchAtPosition() throws {
        let regex = try OnigRegex(pattern: "hello")
        let string = "hello world"
        let match = regex.match(in: string, at: string.startIndex)
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testMatchAtWrongPosition() throws {
        let regex = try OnigRegex(pattern: "hello")
        let string = "hello world"
        let wrongIndex = string.index(string.startIndex, offsetBy: 6)
        let match = regex.match(in: string, at: wrongIndex)
        
        XCTAssertNil(match)
    }
    
    func testCaptureGroups() throws {
        let regex = try OnigRegex(pattern: "(\\w+)\\s+(\\w+)")
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello world")
        XCTAssertEqual(match?.captures.count, 3) // full match + 2 groups
        XCTAssertEqual(match?.captures[0].matchedString, "hello world") // full match
        XCTAssertEqual(match?.captures[1].matchedString, "hello") // first group
        XCTAssertEqual(match?.captures[2].matchedString, "world") // second group
    }
    
    func testEmptyCaptureGroup() throws {
        let regex = try OnigRegex(pattern: "(hello)?(world)")
        let match = regex.search(in: "world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.captures.count, 3)
        XCTAssertEqual(match?.captures[0].matchedString, "world") // full match
        XCTAssertNil(match?.captures[1].matchedString) // empty group
        XCTAssertEqual(match?.captures[2].matchedString, "world") // second group
    }
    
    func testFindAllMatches() throws {
        let regex = try OnigRegex(pattern: "\\d+")
        let matches = regex.findAll(in: "There are 123 apples and 456 oranges")
        
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].matchedString, "123")
        XCTAssertEqual(matches[1].matchedString, "456")
    }
    
    func testFindAllWithNoMatches() throws {
        let regex = try OnigRegex(pattern: "\\d+")
        let matches = regex.findAll(in: "no numbers here")
        
        XCTAssertTrue(matches.isEmpty)
    }
    
    func testIgnoreCaseOption() throws {
        let regex = try OnigRegex(pattern: "HELLO", options: .ignoreCase)
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testMultilineOption() throws {
        let regex = try OnigRegex(pattern: "^world", options: .multiline)
        let match = regex.search(in: "hello\nworld")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "world")
    }
    
    func testUnicodeString() throws {
        let regex = try OnigRegex(pattern: "🚀")
        let match = regex.search(in: "Hello 🚀 World")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "🚀")
    }
    
    func testComplexUnicodePattern() throws {
        let regex = try OnigRegex(pattern: "[\\p{L}]+")
        let match = regex.search(in: "Héllo wørld 123")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "Héllo")
    }
    
    func testSearchWithRange() throws {
        let regex = try OnigRegex(pattern: "world")
        let string = "hello world, wonderful world"
        let startIndex = string.index(string.startIndex, offsetBy: 13)
        let endIndex = string.endIndex
        let match = regex.search(in: string, range: startIndex..<endIndex)
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "world")
        
        // Verify it found the second occurrence
        let matchStart = match!.range.lowerBound
        let expectedStart = string.index(string.startIndex, offsetBy: 23) // "wonderful world" starts at position 13, "world" at 23
        XCTAssertEqual(matchStart, expectedStart)
    }
    
    func testErrorDescription() throws {
        do {
            _ = try OnigRegex(pattern: "[")
        } catch let error as OnigError {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testZeroLengthMatch() throws {
        let regex = try OnigRegex(pattern: "(?=world)")
        let match = regex.search(in: "hello world")
        
        // Should find a zero-length lookahead match
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.range.isEmpty)
    }
    
    func testWordBoundaryMatches() throws {
        // Test word boundary pattern more carefully
        let regex = try OnigRegex(pattern: "\\bhello\\b")
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testPerformanceSimpleSearch() throws {
        let regex = try OnigRegex(pattern: "\\w+")
        let text = String(repeating: "hello world ", count: 1000)
        
        measure {
            _ = regex.findAll(in: text)
        }
    }
    
    func testPerformancePatternCompilation() {
        measure {
            do {
                _ = try OnigRegex(pattern: "(?i)(?:hello|world|foo|bar)+")
            } catch {
                XCTFail("Pattern compilation failed: \(error)")
            }
        }
    }
}