import XCTest
import MiniLexer

class LexerTests: XCTestCase {
    
    func testInitState() {
        let lexer1 = Lexer(input: "abc")
        let lexer2 = Lexer(input: "abc", index: "abc".index(after: "abc".startIndex))
        
        XCTAssertEqual(lexer1.inputString, "abc")
        XCTAssertEqual(lexer1.inputIndex, "abc".startIndex)
        
        XCTAssertEqual(lexer2.inputString, "abc")
        XCTAssertEqual(lexer2.inputIndex, "abc".index(after: "abc".startIndex))
    }
    
    func testRewindToStart() {
        let sut = Lexer(input: "1234")
        sut.inputIndex = sut.inputString.index(sut.inputIndex, offsetBy: 2)
        
        sut.rewindToStart()
        
        XCTAssertEqual(sut.inputIndex, sut.inputString.startIndex)
    }
    
    func testIsEof() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssertFalse(sut.isEof())
        
        try sut.advance()
        try sut.advance()
        try sut.advance()
        
        XCTAssert(sut.isEof())
    }
    
    func testPeek() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssertEqual(try sut.peek(), "a")
    }
    
    func testPeekUsesOffsetForPeeking() throws {
        let sut = Lexer(input: "abc")
        try sut.advance()
        try sut.advance()
        
        XCTAssertEqual(try sut.peek(), "c")
    }
    
    func testPeekThrowsErrorWhenEndOfString() {
        let sut = Lexer(input: "abc")
        sut.advance(while: { _ in true })
        
        assertThrowsEof(try sut.peek()) // Throw on Eof
    }
    
    func testSafeIsNextChar() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssert(sut.safeIsNextChar(equalTo: "a"))
        try sut.advance()
        try sut.advance()
        try sut.advance()
        XCTAssertFalse(sut.safeIsNextChar(equalTo: "-"))
    }
    
    func testSafeIsNextCharWithOffset() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssert(sut.safeIsNextChar(equalTo: "b", offsetBy: 1))
        try sut.advance()
        try sut.advance()
        XCTAssertFalse(sut.safeIsNextChar(equalTo: "-", offsetBy: 1))
    }
    
    func testPeekForward() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssertEqual("b", try sut.peekForward())
        XCTAssertEqual("c", try sut.peekForward(count: 2))
    }
    
    func testPeekForwardFailsWithErrorWhenPastEndOfString() {
        let sut = Lexer(input: "abc")
        
        assertThrowsEof(try sut.peekForward(count: 4))
    }
    
    func testFindNext() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssertEqual(sut.findNext("a"), sut.inputString.startIndex)
        XCTAssertEqual(sut.findNext("c"), sut.inputString.index(sut.inputString.startIndex, offsetBy: 2))
        XCTAssertNil(sut.findNext("0"))
    }
    
    func testSkipToNext() throws {
        let sut = Lexer(input: "abc")
        let expectedIndex = sut.inputString.index(sut.inputString.startIndex, offsetBy: 2)
        
        try sut.skipToNext("c")
        
        XCTAssertEqual(sut.inputIndex, expectedIndex)
    }
    
    func testSkipToNextFailsIfNotFound() {
        let sut = Lexer(input: "abc")
        
        XCTAssertThrowsError(try sut.skipToNext("0"))
    }
    
    func testNext() throws {
        let sut = Lexer(input: "abc")
        
        XCTAssertEqual(try sut.next(), "a")
        
        XCTAssertEqual(sut.inputIndex, sut.inputString.index(after: sut.inputString.startIndex))
        
        XCTAssertEqual(try sut.next(), "b")
        XCTAssertEqual(try sut.next(), "c")
        
        assertThrowsEof(try sut.peek())
    }
    
    func testNextUsesOffsetForReading() throws {
        let sut = Lexer(input: "abc")
        try sut.advance()
        try sut.advance()
        
        XCTAssertEqual(try sut.next(), "c")
    }
    
    func testNextThrowsWhenAtEndOfString() {
        let sut = Lexer(input: "abc")
        sut.advance(while: { _ in true })
        
        assertThrowsEof(try sut.peek())
    }
    
    func testWithTemporaryIndex() throws {
        let sut = Lexer(input: "abc")
        try sut.advance()
        
        let prevIndex = sut.inputIndex
        let char = try sut.withTemporaryIndex { () -> Lexer.Atom in
            try sut.advance()
            return try sut.next()
        }
        
        XCTAssertEqual(char, "c")
        XCTAssertEqual(sut.inputIndex, prevIndex)
    }
    
    func testWithTemporaryIndexRewindsOnError() throws {
        let sut = Lexer(input: "abc")
        let prevIndex = sut.inputIndex
        
        do {
            try sut.withTemporaryIndex { () -> Void in
                try sut.advance()
                throw sut.endOfStringError()
            }
        } catch {
            
        }
        
        XCTAssertEqual(sut.inputIndex, prevIndex)
    }
    
    func testBacktracker() throws {
        let sut = Lexer(input: "abc")
        let bt = sut.backtracker()
        try sut.advance()
        
        bt.backtrack()
        
        XCTAssertEqual(sut.inputIndex, sut.inputString.startIndex)
    }
    
    func testBacktrackerWorksMultipleTimesInSequence() throws {
        let sut = Lexer(input: "abc")
        let bt = sut.backtracker()
        try sut.advance()
        bt.backtrack()
        try sut.advance()
        
        bt.backtrack()
        
        XCTAssertEqual(sut.inputIndex, sut.inputString.startIndex)
    }
}
