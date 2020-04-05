import XCTest
import MiniLexer

class Parser_ConsumeTests: XCTestCase {
    
    func testConsumeString() throws {
        let parser = Parser(input: "abcdef")
        
        XCTAssertEqual(parser.consumeString { _ in }, "") // Empty consume
        XCTAssertEqual(try parser.consumeString { parser in try parser.advance() }, "a")
        XCTAssertEqual(try parser.consumeString { parser in try parser.advance(); try parser.advance() }, "bc")
    }
    
    func testConsumeWhile() {
        let parser = Parser(input: "aaaaabc")
        
        let consumed = parser.consume(while: { $0 == "a" })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.index(parser.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
    }
    
    func testConsumeUntil() {
        let parser = Parser(input: "aaaaabc")
        
        let consumed = parser.consume(until: { $0 == "b" })
        
        XCTAssertEqual(parser.inputIndex, parser.inputString.index(parser.inputString.startIndex, offsetBy: 5))
        XCTAssertEqual(consumed, "aaaaa")
    }
    
    func testConsumeWhileRespectsEndOfString() {
        let parser = Parser(input: "abc")
        
        let consumed = parser.consume(while: { _ in true })
        
        XCTAssertEqual(consumed, "abc")
    }
    
    func testConsumeUntilRespectsEndOfString() {
        let parser = Parser(input: "abc")
        
        let consumed = parser.consume(until: { _ in false })
        
        XCTAssertEqual(consumed, "abc")
    }
    
    func testConsumeLength() throws {
        let parser = Parser(input: "abc")
        
        let consumed = try parser.consumeLength(2)
        
        XCTAssertEqual(consumed, "ab")
    }
    
    func testConsumeLengthThrowsEndOfStringErrorIfLengthExceedsStringEndIndex() {
        let parser = Parser(input: "abc")
        
        assertThrowsEof(try parser.consumeLength(4))
    }

    func testConsumeLengthOffsetFromStart() throws {
        let parser = Parser(input: "abcdef")
        try parser.advanceLength(2)
        
        let consumed = try parser.consumeLength(2)
        
        XCTAssertEqual(consumed, "cd")
    }
    
    func testConsumeWithLengthEndingInEndIndex() throws {
        let parser = Parser(input: "(")
        
        let consumed = try parser.consumeLength(1)
        
        XCTAssertEqual(consumed, "(")
        XCTAssert(parser.isEof())
    }
}
