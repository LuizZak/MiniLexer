import XCTest
import MiniLexer

class Parser_AdvanceTests: XCTestCase {
    
    func testAdvance() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(after: parser.inputString.startIndex)
        
        try parser.advance()
        
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testAdvanceThrowsErrorWhenAtEndOfString() throws {
        let parser = Parser(input: "")
        
        assertThrowsEof(try parser.advance())
    }
    
    func testAdvanceExpectingCurrent() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        try parser.advance(expectingCurrent: "a")
        try parser.advance(expectingCurrent: "b")
        
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testAdvanceExpectingCurrentThrowsWhenAtEndOfString() throws {
        let parser = Parser(input: "")
        
        assertThrowsEof(try parser.advance(expectingCurrent: "a"))
    }
    
    func testAdvanceExpectingCurrentThrowsWhenNonMatching() throws {
        let parser = Parser(input: "abc")
        
        XCTAssertThrowsError(try parser.advance(expectingCurrent: "b"))
    }
    
    func testAdvanceExpectingDoesNotAdvanceParserIndexOnError() throws {
        let parser = Parser(input: "abc")
        
        try? parser.advance(expectingCurrent: "b")
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.startIndex)
    }
    
    func testAdvanceValidatingCurrent() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        try parser.advance(validatingCurrent: { $0 == "a" })
        try parser.advance(validatingCurrent: { $0 == "b" })
        
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testAdvanceValidatingCurrentThrowsWhenAtEndOfString() throws {
        let parser = Parser(input: "")
        
        assertThrowsEof(try parser.advance(validatingCurrent: { $0 == "a" }))
    }
    
    func testAdvanceValidatingCurrentThrowsWhenNonMatching() throws {
        let parser = Parser(input: "abc")
        
        XCTAssertThrowsError(try parser.advance(validatingCurrent: { $0 == "b" }))
    }
    
    func testAdvanceValidatingDoesNotAdvanceParserIndexOnError() throws {
        let parser = Parser(input: "abc")
        
        try? parser.advance(validatingCurrent: { $0 == "b" })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.startIndex)
    }
    
    func testAdvanceIf() {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        let advanced = parser.advanceIf(equals: "ab")
        
        XCTAssert(advanced)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testAdvanceIfUsesOffset() throws {
        let parser = Parser(input: "abcdef")
        try parser.advanceLength(2)
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 5)
        
        let advanced = parser.advanceIf(equals: "cde")
        
        XCTAssert(advanced)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testAdvanceIfOptions() {
        let parser = Parser(input: "áBc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        let advanced = parser.advanceIf(equals: "ab", options: [.caseInsensitive, .diacriticInsensitive])
        
        XCTAssert(advanced)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testNonMatchingAdvanceIf() {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.startIndex
        
        let advanced = parser.advanceIf(equals: "bc")
        
        XCTAssertFalse(advanced)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testCheckNext() {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputIndex
        
        let matches = parser.checkNext(matches: "ab")
        
        XCTAssert(matches)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testCheckNextUsesOffset() throws {
        let parser = Parser(input: "abcdef")
        try parser.advanceLength(2)
        let expectedIndex = parser.inputIndex
        
        let matches = parser.checkNext(matches: "cd")
        
        XCTAssert(matches)
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testCheckNextOptions() {
        let parser = Parser(input: "áBc")
        
        XCTAssert(parser.checkNext(matches: "ab", options: [.caseInsensitive, .diacriticInsensitive]))
    }
    
    func testNonMatchingCheckNext() {
        let parser = Parser(input: "abc")
        
        XCTAssertFalse(parser.checkNext(matches: "bc"))
    }
    
    func testConsumeMatch() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        try parser.consume(match: "ab")
        
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testConsumeMatchThrowsErrorWhenNonMatching() throws {
        let parser = Parser(input: "abc")
        
        XCTAssertThrowsError(try parser.consume(match: "bc"))
    }
    
    func testSafeAdvance() {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(after: parser.inputString.startIndex)
        
        XCTAssert(parser.safeAdvance())
        
        XCTAssertEqual(parser.inputIndex, expectedIndex)
    }
    
    func testSafeAdvanceStopsAtEndOfString() {
        let parser = Parser(input: "ab")
        
        XCTAssert(parser.safeAdvance())
        XCTAssert(parser.safeAdvance())
        XCTAssertFalse(parser.safeAdvance())
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.endIndex)
    }
    
    func testAdvanceWhile() throws {
        let parser = Parser(input: "aaaaabc")
        
        parser.advance(while: { $0 == "a" })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.index(parser.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(try parser.peek(), "b")
    }
    
    func testAdvanceUntil() throws {
        let parser = Parser(input: "aaaaabc")
        
        parser.advance(until: { $0 == "b" })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.index(parser.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(try parser.peek(), "b")
    }
    
    func testAdvanceWhileRespectsEndOfString() {
        let parser = Parser(input: "abc")
        
        parser.advance(while: { _ in true })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.endIndex)
    }
    
    func testAdvanceUntilRespectsEndOfString() {
        let parser = Parser(input: "abc")
        
        parser.advance(until: { _ in false })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.endIndex)
    }
    
    func testAdvanceLength() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.index(parser.inputString.startIndex, offsetBy: 2)
        
        try parser.advanceLength(2)
        
        XCTAssertEqual(expectedIndex, parser.inputIndex)
    }
    
    func testAdvanceLengthAdvancingToEndOfString() throws {
        let parser = Parser(input: "abc")
        let expectedIndex = parser.inputString.endIndex
        
        try parser.advanceLength(3)
        
        XCTAssertEqual(expectedIndex, parser.inputIndex)
    }
    
    func testAdvanceLengthThrowsErrorWhenPastEndOfString() throws {
        let parser = Parser(input: "abc")
        
        assertThrowsEof(try parser.advanceLength(4))
    }
    
    func testAdvanceWithLengthEndingInEndIndex() throws {
        let parser = Parser(input: "(")
        
        try parser.advanceLength(1)
    }
}
