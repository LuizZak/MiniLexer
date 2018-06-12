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
        
        XCTAssertEqual(sut.nextToken(), .openParens)
        XCTAssertEqual(sut.nextToken(), .closeParens)
        XCTAssertEqual(sut.nextToken(), .eof)
    }
    
    func testTokenizeEofOnEmptyString() {
        sut = TokenizerLexer(input: "")
        
        XCTAssertEqual(sut.nextToken(), .eof)
    }
    
    func testSkipToken() {
        sut = TokenizerLexer(input: "()")
        
        sut.skipToken()
        
        XCTAssertEqual(sut.nextToken(), .closeParens)
    }
    
    func testToken() {
        sut = TokenizerLexer(input: "()")
        
        let token = sut.token()
        
        XCTAssertEqual(token.tokenString, "(")
        XCTAssertEqual(token, .openParens)
    }
    
    func testTokenIsType() {
        sut = TokenizerLexer(input: "(")
        
        XCTAssert(sut.tokenType(is: .openParens))
    }
    
    func testConsumeTokenIfTypeIsMatching() {
        sut = TokenizerLexer(input: "(")
        
        let result = sut.consumeToken(ifTypeIs: .openParens)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tokenString, "(")
        XCTAssertEqual(result, .openParens)
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
        
        XCTAssertEqual(sut.token(), .openParens)
    }
    
    func testBacktrackerWontWorkTwice() {
        sut = TokenizerLexer(input: "(,)")
        let bt = sut.backtracker()
        sut.skipToken()
        bt.backtrack()
        sut.skipToken()
        
        bt.backtrack()
        
        XCTAssertEqual(sut.token(), .comma)
    }
    
    func testBacktrackerWontEraseHasReadFirstTokenState() throws {
        sut = TokenizerLexer(input: "(")
        let bt = sut.backtracker()
        sut.skipToken()
        
        bt.backtrack()
        
        try sut.advance(over: .openParens) // Should not throw error!
    }
    
    func testAdvanceOver() throws {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertEqual(try sut.advance(over: .openParens), .openParens)
        
        XCTAssertEqual(sut.token(), .comma)
    }
    
    func testAdvanceOverFailed() {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertThrowsError(try sut.advance(over: .comma))
    }
    
    func testAdvanceOverErrorMessage() {
        sut = TokenizerLexer(input: "(,)")
        
        do {
            try sut.advance(over: .comma)
            XCTFail("Should have thrown")
        } catch let error as LexerError {
            XCTAssertEqual(error.description(withOffsetsIn: sut.lexer.inputString),
                           "Error at line 1 column 1: Expected token ',' but found '('")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testAdvanceMatching() throws {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertEqual(try sut.advance(matching: { $0 == .openParens }), .openParens)
        
        XCTAssertEqual(sut.token(), .comma)
    }
    
    func testAdvanceMatchingFailed() {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertThrowsError(try sut.advance(matching: { $0 == .comma }))
    }
    
    func testBacktracking() {
        sut = TokenizerLexer(input: "(,)")
        
        sut.backtracking {
            sut.skipToken()
            sut.skipToken()
        }
        
        XCTAssertEqual(sut.token(), .openParens)
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
            //
        }
        
        XCTAssertEqual(sut.token(), .openParens)
        XCTAssertEqual(sut.lexer.inputIndex, sut.lexer.inputString.startIndex)
    }
    
    func testAllTokens() {
        sut = TokenizerLexer(input: "(,)")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens, [.openParens, .comma, .closeParens])
    }
    
    func testAllTokensSpaced() {
        sut = TokenizerLexer(input: " ( , ) ")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens, [.openParens, .comma, .closeParens])
    }
    
    func testAdvanceUntil() {
        sut = TokenizerLexer(input: "(,)")
        
        sut.advance(until: { $0 == .closeParens })
        
        XCTAssertEqual(sut.token(), .closeParens)
    }
    
    func testAdvancesUntilStopsAtEndOfFile() {
        sut = TokenizerLexer(input: "(,)")
        
        sut.advance(until: { _ in false })
        
        XCTAssertEqual(sut.token(), .eof)
    }
    
    func testTokenMatches() {
        sut = TokenizerLexer(input: "(")
        
        XCTAssert(sut.tokenType(matches: { $0 == .openParens }))
        XCTAssertFalse(sut.tokenType(matches: { $0 == .closeParens }))
    }
    
    func testTokenMatchesWithEmptyString() {
        sut = TokenizerLexer(input: "")
        
        XCTAssert(sut.tokenType(matches: { $0 == .eof }))
        XCTAssertFalse(sut.tokenType(matches: { $0 == .closeParens }))
    }
    
    func testTokenizerConsistencyWhenLexerIndexIsModifiedExternally() throws {
        sut = TokenizerLexer(input: "(,)")
        _=sut.token()
        
        try sut.lexer.advanceLength(1)
        
        XCTAssertEqual(sut.token().tokenString, ",")
        XCTAssertEqual(sut.token(), .comma)
    }
    
    func testMakeIterator() throws {
        sut = TokenizerLexer(input: "(,,)")
        
        let iterator = sut.makeIterator()
        
        XCTAssertEqual(iterator.next()?.tokenString, "(")
        XCTAssertEqual(iterator.next()?.tokenString, ",")
        XCTAssertEqual(iterator.next()?.tokenString, ",")
        XCTAssertEqual(iterator.next()?.tokenString, ")")
        XCTAssertNil(iterator.next())
    }
    
    func testAlternativeTokenizer() throws {
        let sut = TokenizerLexer<TestStructToken>(input: "(.,.)")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens[0], TestStructToken(isEof: false, tokenString: "("))
        XCTAssertEqual(tokens[1], TestStructToken(isEof: false, tokenString: "."))
        XCTAssertEqual(tokens[2], TestStructToken(isEof: false, tokenString: ","))
        XCTAssertEqual(tokens[3], TestStructToken(isEof: false, tokenString: "."))
        XCTAssertEqual(tokens[4], TestStructToken(isEof: false, tokenString: ")"))
    }
}

struct TestStructToken: TokenProtocol {
    static var eofToken: TestStructToken = TestStructToken(isEof: true, tokenString: "")
    
    var isEof: Bool
    var tokenString: Substring
    
    func length(in lexer: Lexer) -> Int {
        return tokenString.count
    }
    
    static func tokenType(at lexer: Lexer) -> TestStructToken? {
        do {
            if lexer.safeIsNextChar(equalTo: ".") {
                return TestStructToken(isEof: false, tokenString: try lexer.consumeLength(1))
            }
            if lexer.safeIsNextChar(equalTo: ",") {
                return TestStructToken(isEof: false, tokenString: try lexer.consumeLength(1))
            }
            if lexer.safeIsNextChar(equalTo: "(") {
                return TestStructToken(isEof: false, tokenString: try lexer.consumeLength(1))
            }
            if lexer.safeIsNextChar(equalTo: ")") {
                return TestStructToken(isEof: false, tokenString: try lexer.consumeLength(1))
            }
        } catch {
            
        }
        
        return nil
    }
}

enum TestToken: String, TokenProtocol {
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
}
