import XCTest
@testable import MiniLexer

class LexerTests: XCTestCase {
    
    func testIsEof() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertFalse(lexer.isEof())
        
        try lexer.advance()
        try lexer.advance()
        try lexer.advance()
        
        XCTAssert(lexer.isEof())
    }
    
    func testNext() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssertEqual(try lexer.next(), "a")
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.index(after: lexer.inputSource.startIndex))
        
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
    
    func testAdvance() throws {
        let lexer = Lexer(input: "abc")
        let expectedIndex = lexer.inputSource.index(after: lexer.inputSource.startIndex)
        
        try lexer.advance()
        
        XCTAssertEqual(lexer.inputIndex, expectedIndex)
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
    
    func testSafePeek() throws {
        let lexer = Lexer(input: "abc")
        
        XCTAssert(lexer.safeIsNextChar(equalTo: "a"))
        try lexer.advance()
        try lexer.advance()
        try lexer.advance()
        XCTAssertFalse(lexer.safeIsNextChar(equalTo: "-"))
    }
    
    func testPeekIdent() throws {
        let lexer = Lexer(input: "abc def")
        
        let peek1 = try lexer.peekIdent()
        try lexer.advanceLength(4)
        let peek2 = try lexer.peekIdent()
        
        XCTAssertEqual(peek1, "abc")
        XCTAssertEqual(peek2, "def")
    }
    
    func testConsumeString() throws {
        let lexer = Lexer(input: "abcdef")
        
        XCTAssertEqual(lexer.consumeString { _ in }, "") // Empty consume
        XCTAssertEqual(try lexer.consumeString { lexer in try lexer.advance() }, "a")
        XCTAssertEqual(try lexer.consumeString { lexer in try lexer.advance(); try lexer.advance() }, "bc")
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
    
    func testAdvanceWhile() throws {
        let lexer = Lexer(input: "aaaaabc")
        
        lexer.advance(while: { $0 == "a" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.index(lexer.inputSource.startIndex, offsetBy: 5))
        XCTAssertEqual(try lexer.peek(), "b")
    }
    
    func testAdvanceUntil() throws {
        let lexer = Lexer(input: "aaaaabc")
        
        lexer.advance(until: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.index(lexer.inputSource.startIndex, offsetBy: 5))
        XCTAssertEqual(try lexer.peek(), "b")
    }
    
    func testConsumeWhile() {
        let lexer = Lexer(input: "aaaaabc")
        
        let consumed = lexer.consume(while: { $0 == "a" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.index(lexer.inputSource.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
    }
    
    func testConsumeUntil() {
        let lexer = Lexer(input: "aaaaabc")
        
        let consumed = lexer.consume(until: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.index(lexer.inputSource.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
    }
    
    func testAdvanceWhileRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        lexer.advance(while: { _ in true })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.endIndex)
    }
    
    func testAdvanceUntilRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        lexer.advance(until: { _ in false })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputSource.endIndex)
    }
    
    func testConsumeWhileRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        let consumed = lexer.consume(while: { _ in true })
        
        XCTAssertEqual(consumed, "abc")
    }
    
    func testConsumeUntilRespectsEndOfString() {
        let lexer = Lexer(input: "abc")
        
        let consumed = lexer.consume(until: { _ in false })
        
        XCTAssertEqual(consumed, "abc")
    }
}
