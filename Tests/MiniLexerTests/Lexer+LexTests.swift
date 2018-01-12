import XCTest
import MiniLexer

class Lexer_LexTests: XCTestCase {
    
    func testLexInt() throws {
        XCTAssertEqual(123, try lexerTest("123") { try $0.lexInt() })
        XCTAssertEqual(123, try lexerTest("123a") { try $0.lexInt() })
        XCTAssertThrowsError(try lexerTest("abc") { try $0.lexInt() })
        XCTAssertThrowsError(try lexerTest("") { try $0.lexInt() })
    }
    
    func testLexIdentifier() throws {
        XCTAssertEqual("abc", try lexerTest("abc") { try $0.lexIdentifier() })
        XCTAssertEqual("ab_c", try lexerTest("ab_c") { try $0.lexIdentifier() })
        XCTAssertEqual("abc1", try lexerTest("abc1") { try $0.lexIdentifier() })
        XCTAssertEqual("_abc", try lexerTest("_abc") { try $0.lexIdentifier() })
        XCTAssertThrowsError(try lexerTest("1abc") { try $0.lexIdentifier() })
        XCTAssertThrowsError(try lexerTest("") { try $0.lexIdentifier() })
    }
    
    private func lexerTest<T>(_ input: String, _ block: (Lexer) throws -> T) rethrows -> T {
        let lexer = Lexer(input: input)
        return try block(lexer)
    }
}
