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
        
        XCTAssertThrowsError(try lexer.advance())
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
        
        XCTAssertThrowsError(try lexer.advance(expectingCurrent: "a"))
    }
    
    func testAdvanceExpectingCurrentThrowsWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.advance(expectingCurrent: "b"))
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
        
        XCTAssertThrowsError(try lexer.advance(validatingCurrent: { $0 == "a" }))
    }
    
    func testAdvanceValidatingCurrentThrowsWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.advance(validatingCurrent: { $0 == "b" }))
    }
    
    func testAdvanceIf() {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        let advanced = lexer.advanceIf(equals: "ab")
        
        XCTAssert(advanced)
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testAdvanceIfOptions() {
        let lexer = Lexer(input: "ABc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        let advanced = lexer.advanceIf(equals: "ab", options: .caseInsensitive)
        
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
    
    func testExpect() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.expect(match: "ab")
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testExpectThrowsErrorWhenNonMatching() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.expect(match: "bc"))
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
    
    func testAdvanceLengthThrowsErrorWhenPastEndOfString() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.advanceLength(4))
    }
}
