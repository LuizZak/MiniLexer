import XCTest
import MiniLexer

class TokenizerTests: XCTestCase {
    var sut: TokenizerLexer<TestToken>!
    
    func testInitWithLexer() {
        let lexer = Lexer(input: "()")
        sut = TokenizerLexer(lexer: lexer)
        
        XCTAssert(sut.lexer === lexer)
    }
    
    func testTokenizeStream() {
        sut = TokenizerLexer(input: "()")
        
        XCTAssertEqual(sut.nextToken().tokenType, .openParens)
        XCTAssertEqual(sut.nextToken().tokenType, .closeParens)
        XCTAssertEqual(sut.nextToken().tokenType, .eof)
    }
    
    func testTokenizeEofOnEmptyString() {
        sut = TokenizerLexer(input: "")
        
        XCTAssertEqual(sut.nextToken().tokenType, .eof)
    }
    
    func testSkipToken() {
        sut = TokenizerLexer(input: "()")
        
        sut.skipToken()
        
        XCTAssertEqual(sut.nextToken().tokenType, .closeParens)
    }
    
    func testToken() {
        sut = TokenizerLexer(input: "()")
        
        let token = sut.token()
        
        XCTAssertEqual(token.value, "(")
        XCTAssertEqual(token.tokenType, .openParens)
    }
    
    func testTokenIsType() {
        sut = TokenizerLexer(input: "(")
        
        XCTAssert(sut.isToken(.openParens))
    }
    
    func testConsumeTokenIfTypeIsMatching() {
        sut = TokenizerLexer(input: "(")
        
        XCTAssertNotNil(sut.consumeToken(ifTypeIs: .openParens))
        XCTAssert(sut.isEof)
    }
    
    func testConsumeTokenIfTypeIsNonMatching() {
        sut = TokenizerLexer(input: "(")
        
        XCTAssertNil(sut.consumeToken(ifTypeIs: .closeParens))
        XCTAssertFalse(sut.isEof)
    }
    
    func testBacktracker() {
        sut = TokenizerLexer(input: "(,)")
        let bt = sut.backtracker()
        sut.skipToken()
        sut.skipToken()
        
        bt.backtrack()
        
        XCTAssertEqual(sut.token().tokenType, .openParens)
    }
    
    func testBacktrackerWontWorkTwice() {
        sut = TokenizerLexer(input: "(,)")
        let bt = sut.backtracker()
        sut.skipToken()
        bt.backtrack()
        sut.skipToken()
        
        bt.backtrack()
        
        XCTAssertEqual(sut.token().tokenType, .comma)
    }
    
    func testBacktrackerWontEraseHasReadFirstTokenState() throws {
        sut = TokenizerLexer(input: "(")
        let bt = sut.backtracker()
        sut.skipToken()
        bt.backtrack()
        
        try sut.advance(over: .openParens)
    }
    
    func testAdvanceOver() throws {
        sut = TokenizerLexer(input: "(,)")
        
        try sut.advance(over: .openParens)
        
        XCTAssertEqual(sut.token().tokenType, .comma)
    }
    
    func testAdvanceOverFailed() {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertThrowsError(try sut.advance(over: .comma))
    }
    
    func testBacktracking() {
        sut = TokenizerLexer(input: "(,)")
        
        sut.backtracking {
            sut.skipToken()
            sut.skipToken()
        }
        
        XCTAssertEqual(sut.token().tokenType, .openParens)
    }
    
    func testBacktrackingWorksWithErrorsThrown() {
        sut = TokenizerLexer(input: "(,)")
        
        do {
            try sut.backtracking {
                sut.skipToken()
                try sut.advance(over: .openParens)
            }
            
            XCTFail("Should have thrown error")
        } catch {
            // Consume
        }
        
        XCTAssertEqual(sut.token().tokenType, .openParens)
    }
    
    func testAllTokens() {
        sut = TokenizerLexer(input: "(,)")
        
        let tokens = sut.allTokens().map { $0.tokenType }
        
        XCTAssertEqual(tokens, [.openParens, .comma, .closeParens])
    }
}

enum TestToken: String, TokenType {
    case openParens = "("
    case comma = ","
    case closeParens = ")"
    case eof = ""
    
    static var eofToken = TestToken.eof
    
    var tokenString: String {
        switch self {
        case .openParens:
            return "("
        case .comma:
            return ","
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
        if lexer.safeIsNextChar(equalTo: ",") {
            return .comma
        }
        if lexer.safeIsNextChar(equalTo: ")") {
            return .closeParens
        }
        return nil
    }
    
    func length(in lexer: Lexer) -> Int {
        switch self {
        case .openParens, .closeParens, .comma:
            return 1
        case .eof:
            return 0
        }
    }
    
    func advance(in lexer: Lexer) throws {
        switch self {
        case .openParens, .closeParens, .comma:
            try lexer.advance()
        case .eof:
            break
        }
    }
    
    func matchesText(in lexer: Lexer) -> Bool {
        switch self {
        case .openParens:
            return lexer.safeIsNextChar(equalTo: "(")
        case .comma:
            return lexer.safeIsNextChar(equalTo: ",")
        case .closeParens:
            return lexer.safeIsNextChar(equalTo: ")")
        case .eof:
            return false
        }
    }
}
