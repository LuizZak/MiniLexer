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
        let lexer = Lexer(input: "1234")
        lexer.inputIndex = lexer.inputString.index(lexer.inputIndex, offsetBy: 2)
        
        lexer.rewindToStart()
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.startIndex)
    }
    
    func testIsEof() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertFalse(lexer.isEof())
        
        try lexer.advance()
        try lexer.advance()
        try lexer.advance()
        
        XCTAssert(lexer.isEof())
    }
    
    func testPeek() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual(try lexer.peek(), "a")
    }
    
    func testPeekUsesOffsetForPeeking() throws {
        let lexer = Lexer(input: "abc")
        try lexer.advance()
        try lexer.advance()
        
        XCTAssertEqual(try lexer.peek(), "c")
    }
    
    func testPeekThrowsErrorWhenEndOfString() {
        let lexer = Lexer(input: "abc")
        lexer.advance(while: { _ in true })
        
        XCTAssertThrowsError(try lexer.peek()) // Throw on Eof
    }
    
    func testSafeIsNextChar() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssert(lexer.safeIsNextChar(equalTo: "a"))
        try lexer.advance()
        try lexer.advance()
        try lexer.advance()
        XCTAssertFalse(lexer.safeIsNextChar(equalTo: "-"))
    }
    
    func testSafeIsNextCharWithOffset() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssert(lexer.safeIsNextChar(equalTo: "b", offsetBy: 1))
        try lexer.advance()
        try lexer.advance()
        XCTAssertFalse(lexer.safeIsNextChar(equalTo: "-", offsetBy: 1))
    }
    
    func testPeekForward() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual("b", try lexer.peekForward())
        XCTAssertEqual("c", try lexer.peekForward(count: 2))
    }
    
    func testPeekForwardFailsWithErrorWhenPastEndOfString() {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.peekForward(count: 4))
    }
    
    func testFindNext() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual(lexer.findNext("a"), lexer.inputString.startIndex)
        XCTAssertEqual(lexer.findNext("c"), lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2))
        XCTAssertNil(lexer.findNext("0"))
    }
    
    func testSkipToNext() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 2)
        
        try lexer.skipToNext("c")
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
    }
    
    func testSkipToNextFailsIfNotFound() {
        let lexer = Lexer(input: "abc")
        
        XCTAssertThrowsError(try lexer.skipToNext("0"))
    }
    
    func testNext() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual(try lexer.next(), "a")
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.index(after: lexer.inputString.startIndex))
        
        XCTAssertEqual(try lexer.next(), "b")
        XCTAssertEqual(try lexer.next(), "c")
        
        XCTAssertThrowsError(try lexer.peek()) // Throw on Eof
    }
    
    func testNextUsesOffsetForReading() throws {
        let lexer = Lexer(input: "abc")
        try lexer.advance()
        try lexer.advance()
        
        XCTAssertEqual(try lexer.next(), "c")
    }
    
    func testNextThrowsWhenAtEndOfString() {
        let lexer = Lexer(input: "abc")
        lexer.advance(while: { _ in true })
        
        XCTAssertThrowsError(try lexer.peek()) // Throw on Eof
    }
    
    func testWithTemporaryIndex() throws {
        let lexer = Lexer(input: "abc")
        try lexer.advance()
        
        let prevIndex = lexer.inputIndex
        let char = try lexer.withTemporaryIndex { () -> Lexer.Atom in
            try lexer.advance()
            return try lexer.next()
        }
        
        XCTAssertEqual(char, "c")
        XCTAssertEqual(lexer.inputIndex, prevIndex)
    }
    
    func testWithTemporaryIndexRewindsOnError() throws {
        let lexer = Lexer(input: "abc")
        let prevIndex = lexer.inputIndex
        
        do {
            try lexer.withTemporaryIndex { () -> Void in
                try lexer.advance()
                throw lexer.endOfStringError()
            }
        } catch {
            
        }
        
        XCTAssertEqual(lexer.inputIndex, prevIndex)
    }
}
