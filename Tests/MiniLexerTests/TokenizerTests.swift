import XCTest
import MiniLexer

class TokenizerTests: XCTestCase {
    var sut: TokenizerLexer<TestToken>!
    
    func testTokenizeStream() {
        sut = TokenizerLexer(input: "()")
        
        XCTAssertEqual(sut.nextToken().tokenType, TestToken.openParens)
        XCTAssertEqual(sut.nextToken().tokenType, TestToken.closeParens)
        XCTAssertEqual(sut.nextToken().tokenType, TestToken.eof)
    }
}

enum TestToken: String, TokenType {
    case openParens = "("
    case closeParens = ")"
    case eof = ""
    
    static var eofToken = TestToken.eof
    
    var tokenString: String {
        switch self {
        case .openParens:
            return "("
        case .closeParens:
            return ")"
        case .eof:
            return ""
        }
    }
    
    static func tokenType(at lexer: Lexer) -> TestToken? {
        if lexer.safeIsNextChar(equalTo: "(") {
            return .openParens
        }
        if lexer.safeIsNextChar(equalTo: ")") {
            return .closeParens
        }
        return nil
    }
    
    func length(in lexer: Lexer) -> Int {
        switch self {
        case .openParens, .closeParens:
            return 1
        case .eof:
            return 0
        }
    }
    
    func advance(in lexer: Lexer) throws {
        switch self {
        case .openParens, .closeParens:
            try lexer.advance()
        case .eof:
            break
        }
    }
    
    func matchesText(in lexer: Lexer) -> Bool {
        switch self {
        case .openParens:
            return lexer.safeIsNextChar(equalTo: "(")
        case .closeParens:
            return lexer.safeIsNextChar(equalTo: ")")
        case .eof:
            return false
        }
    }
}
