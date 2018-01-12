import XCTest
import MiniLexer

class LexerTests: XCTestCase {
    
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
        
        let peek1 = try lexer.peekIdentifier()
        try lexer.advanceLength(4)
        let peek2 = try lexer.peekIdentifier()
        
        XCTAssertEqual(peek1, "abc")
        XCTAssertEqual(peek2, "def")
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
}
