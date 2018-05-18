import XCTest
import MiniLexer

class Lexer_ConsumeTests: XCTestCase {
    
    func testConsumeString() throws {
        let lexer = Lexer(input: "abcdef")
        
        XCTAssertEqual(lexer.consumeString { _ in }, "") // Empty consume
        XCTAssertEqual(try lexer.consumeString { lexer in try lexer.advance() }, "a")
        XCTAssertEqual(try lexer.consumeString { lexer in try lexer.advance(); try lexer.advance() }, "bc")
    }
    
    func testConsumeWhile() {
        let lexer = Lexer(input: "aaaaabc")
        
        let consumed = lexer.consume(while: { $0 == "a" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
    }
    
    func testConsumeUntil() {
        let lexer = Lexer(input: "aaaaabc")
        
        let consumed = lexer.consume(until: { $0 == "b" })
        
        XCTAssertEqual(lexer.inputIndex, lexer.inputString.index(lexer.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
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
    
    func testConsumeLength() throws {
        let lexer = Lexer(input: "abc")
        
        let consumed = try lexer.consumeLength(2)
        
        XCTAssertEqual(consumed, "ab")
    }
    
    func testConsumeLengthThrowsEndOfStringErrorIfLengthExceedsStringEndIndex() {
        let lexer = Lexer(input: "abc")
        
        assertThrowsEof(try lexer.consumeLength(4))
    }

    func testConsumeLengthOffsetFromStart() throws {
        let lexer = Lexer(input: "abcdef")
        try lexer.advanceLength(2)
        
        let consumed = try lexer.consumeLength(2)
        
        XCTAssertEqual(consumed, "cd")
    }
}
