import XCTest
@testable import SwiftOniguruma

final class SwiftOnigurumaTests: XCTestCase {
    
    func testBasicPatternCompilation() throws {
        let regex = try OnigRegex(pattern: "hello", options: .none, syntax: .perlNG)
        XCTAssertNotNil(regex)
    }
    
    func testInvalidPatternThrowsError() {
        XCTAssertThrowsError(try OnigRegex(pattern: "[", options: .default, syntax: .perlNG)) { error in
            XCTAssertTrue(error is OnigError)
        }
    }
    
    func testSimpleStringMatch() throws {
        let regex = try OnigRegex(pattern: "world", options: .default, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "world")
    }
    
    func testNoMatchReturnsNil() throws {
        let regex = try OnigRegex(pattern: "xyz", options: .default, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        XCTAssertNil(match)
    }
    
    func testMatchAtPosition() throws {
        let regex = try OnigRegex(pattern: "hello", options: .default, syntax: .perlNG)
        let string = "hello world"
        let match = regex.match(in: string, at: string.startIndex)
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testMatchAtWrongPosition() throws {
        let regex = try OnigRegex(pattern: "hello", options: .default, syntax: .perlNG)
        let string = "hello world"
        let wrongIndex = string.index(string.startIndex, offsetBy: 6)
        let match = regex.match(in: string, at: wrongIndex)
        
        XCTAssertNil(match)
    }
    
    func testCaptureGroups() throws {
        let regex = try OnigRegex(pattern: "(\\w+)\\s+(\\w+)", options: .default, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello world")
        XCTAssertEqual(match?.captures.count, 3) // full match + 2 groups
        XCTAssertEqual(match?.captures[0].matchedString, "hello world") // full match
        XCTAssertEqual(match?.captures[1].matchedString, "hello") // first group
        XCTAssertEqual(match?.captures[2].matchedString, "world") // second group
    }
    
    func testEmptyCaptureGroup() throws {
        let regex = try OnigRegex(pattern: "(hello)?(world)", options: .default, syntax: .perlNG)
        let match = regex.search(in: "world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.captures.count, 3)
        XCTAssertEqual(match?.captures[0].matchedString, "world") // full match
        XCTAssertNil(match?.captures[1].matchedString) // empty group
        XCTAssertEqual(match?.captures[2].matchedString, "world") // second group
    }
    
    func testFindAllMatches() throws {
        let regex = try OnigRegex(pattern: "\\d+", options: .default, syntax: .perlNG)
        let matches = regex.findAll(in: "There are 123 apples and 456 oranges")
        
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].matchedString, "123")
        XCTAssertEqual(matches[1].matchedString, "456")
    }
    
    func testFindAllWithNoMatches() throws {
        let regex = try OnigRegex(pattern: "\\d+", options: .default, syntax: .perlNG)
        let matches = regex.findAll(in: "no numbers here")
        
        XCTAssertTrue(matches.isEmpty)
    }
    
    func testIgnoreCaseOption() throws {
        let regex = try OnigRegex(pattern: "HELLO", options: .ignoreCase, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testMultilineOption() throws {
        // In Perl_NG syntax with singleline mode (default), ^ and $ only match string boundaries
        // Need to negate singleline to make ^ and $ match line boundaries
        let regex1 = try OnigRegex(pattern: "^world", options: .negateSingleline, syntax: .perlNG)
        let match1 = regex1.search(in: "hello\nworld")
        XCTAssertNotNil(match1, "^ should match line boundaries when singleline is negated")
        XCTAssertEqual(match1?.matchedString, "world")
        
        // Test what multiline actually does - make . match newlines
        let regex2 = try OnigRegex(pattern: "hello.world", options: .default, syntax: .perlNG)
        let match2 = regex2.search(in: "hello\nworld")
        XCTAssertNil(match2, ". should not match newlines by default")
        
        let regex3 = try OnigRegex(pattern: "hello.world", options: .multiline, syntax: .perlNG)
        let match3 = regex3.search(in: "hello\nworld")
        XCTAssertNotNil(match3, ". should match newlines with multiline option")
        XCTAssertEqual(match3?.matchedString, "hello\nworld")
    }
    
    func testSyntaxDifferences() throws {
        let testString = "hello\nworld"
        
        // Test default syntax behavior (Perl_NG)
        let defaultRegex = try OnigRegex(pattern: "^world", options: .default, syntax: .perlNG)
        let defaultMatch = defaultRegex.search(in: testString)
        XCTAssertNil(defaultMatch, "With default syntax (Perl_NG), ^ should not match at line boundaries")
        
        // Test with Oniguruma syntax (Ruby-like)
        let onigurumaRegex = try OnigRegex(pattern: "^world", options: .default, syntax: .oniguruma)
        let onigurumaMatch = onigurumaRegex.search(in: testString)
        XCTAssertNotNil(onigurumaMatch, "With Oniguruma syntax, ^ should match at line boundaries by default")
        XCTAssertEqual(onigurumaMatch?.matchedString, "world")
        
        // Test with Ruby syntax
        let rubyRegex = try OnigRegex(pattern: "^world", options: .default, syntax: .ruby)
        let rubyMatch = rubyRegex.search(in: testString)
        XCTAssertNotNil(rubyMatch, "With Ruby syntax, ^ should match at line boundaries by default")
        XCTAssertEqual(rubyMatch?.matchedString, "world")
        
        // Test with Perl_NG syntax and negateSingleline option
        let perlMultilineRegex = try OnigRegex(pattern: "^world", options: .negateSingleline, syntax: .perlNG)
        let perlMultilineMatch = perlMultilineRegex.search(in: testString)
        XCTAssertNotNil(perlMultilineMatch, "With Perl_NG + negateSingleline, ^ should match at line boundaries")
        XCTAssertEqual(perlMultilineMatch?.matchedString, "world")
        
        // Test how multiline option affects dot (.) across syntaxes
        let dotTestString = "hello\nworld"
        
        // Test with different syntaxes - dot behavior should be consistent
        let perlDotRegex = try OnigRegex(pattern: "hello.world", options: .default, syntax: .perlNG)
        let perlDotMatch = perlDotRegex.search(in: dotTestString)
        XCTAssertNil(perlDotMatch, ". should not match newlines by default in Perl_NG")
        
        let rubyDotRegex = try OnigRegex(pattern: "hello.world", options: .default, syntax: .ruby)
        let rubyDotMatch = rubyDotRegex.search(in: dotTestString)
        XCTAssertNil(rubyDotMatch, ". should not match newlines by default in Ruby")
        
        // With multiline option - dot matches newlines
        let dotRegexMultiline = try OnigRegex(pattern: "hello.world", options: .multiline, syntax: .perlNG)
        let dotMatchMultiline = dotRegexMultiline.search(in: dotTestString)
        XCTAssertNotNil(dotMatchMultiline, "With multiline option, . should match newlines")
        XCTAssertEqual(dotMatchMultiline?.matchedString, "hello\nworld")
        
        // Test Python syntax
        let pythonRegex = try OnigRegex(pattern: "\\bhello\\b", options: .default, syntax: .python)
        let pythonMatch = pythonRegex.search(in: "hello world")
        XCTAssertNotNil(pythonMatch, "Python syntax should support word boundaries")
        
        // Test POSIX Basic syntax
        let posixBasicRegex = try OnigRegex(pattern: "hel\\{2\\}", options: .default, syntax: .posixBasic)
        let posixBasicMatch = posixBasicRegex.search(in: "hello")
        XCTAssertNotNil(posixBasicMatch, "POSIX Basic syntax should use escaped braces for repetition")
        XCTAssertEqual(posixBasicMatch?.matchedString, "hell")
    }
    
    func testUnicodeString() throws {
        let regex = try OnigRegex(pattern: "🚀", options: .default, syntax: .perlNG)
        let match = regex.search(in: "Hello 🚀 World")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "🚀")
    }
    
    func testComplexUnicodePattern() throws {
        let regex = try OnigRegex(pattern: "[\\p{L}]+", options: .default, syntax: .perlNG)
        let match = regex.search(in: "Héllo wørld 123")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "Héllo")
    }
    
    func testSearchWithRange() throws {
        let regex = try OnigRegex(pattern: "world", options: .default, syntax: .perlNG)
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
            _ = try OnigRegex(pattern: "[", options: .default, syntax: .perlNG)
        } catch let error as OnigError {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testZeroLengthMatch() throws {
        let regex = try OnigRegex(pattern: "(?=world)", options: .default, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        // Should find a zero-length lookahead match
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.range.isEmpty)
    }
    
    func testWordBoundaryMatches() throws {
        // Test word boundary pattern more carefully
        let regex = try OnigRegex(pattern: "\\bhello\\b", options: .default, syntax: .perlNG)
        let match = regex.search(in: "hello world")
        
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.matchedString, "hello")
    }
    
    func testPerformanceSimpleSearch() throws {
        let regex = try OnigRegex(pattern: "\\w+", options: .default, syntax: .perlNG)
        let text = String(repeating: "hello world ", count: 1000)
        
        measure {
            _ = regex.findAll(in: text)
        }
    }
    
    func testPerformancePatternCompilation() {
        measure {
            do {
                _ = try OnigRegex(pattern: "(?i)(?:hello|world|foo|bar)+", options: .default, syntax: .perlNG)
            } catch {
                XCTFail("Pattern compilation failed: \(error)")
            }
        }
    }
}