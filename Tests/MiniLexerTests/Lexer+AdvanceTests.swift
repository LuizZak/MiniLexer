import XCTest
import MiniLexer

class Lexer_AdvanceTests: XCTestCase {
    
    func testAdvance() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(after: lexer.inputString.startIndex)
        
        try lexer.advance()
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceThrowsErrorWhenAtEndOfString() throws {
        let lexer = Lexer(input: "")
        
        assertThrowsEof(try lexer.advance())
    }
    
    func testAdvanceExpectingCurrent() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.advance(expectingCurrent: "a")
        try lexer.advance(expectingCurrent: "b")
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceExpectingCurrentThrowsWhenAtEndOfString() throws {
        let lexer = Lexer(input: "")
        
        assertThrowsEof(try lexer.advance(expectingCurrent: "a"))
    }
    
    func testAdvanceExpectingCurrentThrowsWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.advance(expectingCurrent: "b"))
    }
    
    func testAdvanceExpectingDoesNotAdvanceLexerIndexOnError() throws {
        let lexer = Lexer(input: "abc")
        
        try? lexer.advance(expectingCurrent: "b")
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.startIndex)
    }
    
    func testAdvanceValidatingCurrent() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.advance(validatingCurrent: { $0 == "a" })
        try lexer.advance(validatingCurrent: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceValidatingCurrentThrowsWhenAtEndOfString() throws {
        let lexer = Lexer(input: "")
        
        assertThrowsEof(try lexer.advance(validatingCurrent: { $0 == "a" }))
    }
    
    func testAdvanceValidatingCurrentThrowsWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.advance(validatingCurrent: { $0 == "b" }))
    }
    
    func testAdvanceValidatingDoesNotAdvanceLexerIndexOnError() throws {
        let lexer = Lexer(input: "abc")
        
        try? lexer.advance(validatingCurrent: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.startIndex)
    }
    
    func testAdvanceIf() {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        let advanced = lexer.advanceIf(equals: "ab")
        
        XCTAssert(advanced)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceIfUsesOffset() throws {
        let lexer = Lexer(input: "abcdef")
        try lexer.advanceLength(2)
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 5)
        
        let advanced = lexer.advanceIf(equals: "cde")
        
        XCTAssert(advanced)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceIfOptions() {
        let lexer = Lexer(input: "áBc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        let advanced = lexer.advanceIf(equals: "ab", options: [.caseInsensitive, .diacriticInsensitive])
        
        XCTAssert(advanced)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testNonMatchingAdvanceIf() {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.startIndex
        
        let advanced = lexer.advanceIf(equals: "bc")
        
        XCTAssertFalse(advanced)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testCheckNext() {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputIndex
        
        let matches = lexer.checkNext(matches: "ab")
        
        XCTAssert(matches)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testCheckNextUsesOffset() throws {
        let lexer = Lexer(input: "abcdef")
        try lexer.advanceLength(2)
        let expectedIndex = lexer.inputIndex
        
        let matches = lexer.checkNext(matches: "cd")
        
        XCTAssert(matches)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testCheckNextOptions() {
        let lexer = Lexer(input: "áBc")
        
        XCTAssert(lexer.checkNext(matches: "ab", options: [.caseInsensitive, .diacriticInsensitive]))
    }
    
    func testNonMatchingCheckNext() {
        let lexer = Lexer(input: "abc")
        
        XCTAssertFalse(lexer.checkNext(matches: "bc"))
    }
    
    func testConsumeMatch() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.consume(match: "ab")
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testConsumeMatchThrowsErrorWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.consume(match: "bc"))
    }
    
    func testSafeAdvance() {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(after: lexer.inputString.startIndex)
        
        XCTAssert(lexer.safeAdvance())
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testSafeAdvanceStopsAtEndOfString() {
        let lexer = Lexer(input: "ab")
        
        XCTAssert(lexer.safeAdvance())
        XCTAssert(lexer.safeAdvance())
        XCTAssertFalse(lexer.safeAdvance())
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.endIndex)
    }
    
    func testAdvanceWhile() throws {
        let lexer = Lexer(input: "aaaaabc")
        
        lexer.advance(while: { $0 == "a" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(try lexer.peek(), "b")
    }
    
    func testAdvanceUntil() throws {
        let lexer = Lexer(input: "aaaaabc")
        
        lexer.advance(until: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(try lexer.peek(), "b")
    }
    
    func testAdvanceWhileRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        lexer.advance(while: { _ in true })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.endIndex)
    }
    
    func testAdvanceUntilRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        lexer.advance(until: { _ in false })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.endIndex)
    }
    
    func testAdvanceLength() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.advanceLength(2)
        
        XCTAssertEqual(expectedIndex, lexer.inputIndex)
    }
    
    func testAdvanceLengthAdvancingToEndOfString() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.endIndex
        
        try lexer.advanceLength(3)
        
        XCTAssertEqual(expectedIndex, lexer.inputIndex)
    }
    
    func testAdvanceLengthThrowsErrorWhenPastEndOfString() throws {
        let lexer = Lexer(input: "abc")
        
        assertThrowsEof(try lexer.advanceLength(4))
    }
    
    func testAdvanceWithLengthEndingInEndIndex() throws {
        let lexer = Lexer(input: "(")
        
        try lexer.advanceLength(1)
    }
}
