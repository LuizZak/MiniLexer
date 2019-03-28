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
        
        XCTAssert(sut.token(is: .openParens))
    }
    
    func testTokenTypeIsType() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(")
        
        XCTAssert(sut.tokenType(is: .openParens))
    }
    
    func testTokenTypeMatches() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(")
        
        XCTAssert(sut.tokenType(matches: { $0 == .openParens }))
    }
    
    func testConsumeTokenIfTypeIsMatching() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(")
        
        let result = sut.consumeToken(ifTypeIs: .openParens)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.value, "(")
        XCTAssertEqual(result?.tokenType, .openParens)
        XCTAssert(sut.isEof)
    }
    
    func testConsumeTokenIfTypeIsNonMatching() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(")
        
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
    
    func testAdvanceOverTokenType() throws {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        XCTAssertEqual(try sut.advance(overTokenType: .openParens).tokenType, .openParens)
        
        XCTAssertEqual(sut.token().tokenType, .comma)
    }
    
    func testAdvanceOverFailed() {
        sut = TokenizerLexer(input: "(,)")
        
        XCTAssertThrowsError(try sut.advance(over: .comma))
    }
    
    func testAdvanceOverTokenTypeFailed() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        XCTAssertThrowsError(try sut.advance(overTokenType: .comma))
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
    
    func testAdvanceOverTokenTypeErrorMessage() {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        do {
            try sut.advance(overTokenType: .comma)
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
        
        XCTAssert(sut.token(matches: { $0 == .openParens }))
        XCTAssertFalse(sut.token(matches: { $0 == .closeParens }))
    }
    
    func testTokenMatchesWithEmptyString() {
        sut = TokenizerLexer(input: "")
        
        XCTAssert(sut.token(matches: { $0 == .eof }))
        XCTAssertFalse(sut.token(matches: { $0 == .closeParens }))
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
    
    func testFullToken() throws {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].tokenType, .openParens)
        XCTAssertEqual(tokens[1].tokenType, .comma)
        XCTAssertEqual(tokens[2].tokenType, .closeParens)
    }
    
    func testFullTokenValue() throws {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].value, "(")
        XCTAssertEqual(tokens[1].value, ",")
        XCTAssertEqual(tokens[2].value, ")")
    }
    
    func testFullTokenTokenString() throws {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: "(,)")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].tokenString, tokens[0].tokenType.tokenString)
        XCTAssertEqual(tokens[1].tokenString, tokens[1].tokenType.tokenString)
        XCTAssertEqual(tokens[2].tokenString, tokens[2].tokenType.tokenString)
    }
    
    func testFullTokenRange() throws {
        let sut = TokenizerLexer<FullToken<TestToken>>(input: " ( , ) ")
        
        let tokens = sut.allTokens()
        
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].range, " ".endIndex..<" (".endIndex)
        XCTAssertEqual(tokens[1].range, " ( ".endIndex..<" ( ,".endIndex)
        XCTAssertEqual(tokens[2].range, " ( , ".endIndex..<" ( , )".endIndex)
    }
    
    func testSkipTokenWithLeadingWhitespace() {
        let sut = TokenizerLexer<FullToken<TestTokenWithIdentifier>>(input: ", Array()")
        
        sut.skipToken()
        sut.skipToken()
        sut.skipToken()
        sut.skipToken()
        
        XCTAssert(sut.isEof)
    }
    
    func testTokenTypeIsAtBeginningOfGrammar() {
        let sut = TokenizerLexer<FullToken<TestToken2>>(input: "0,0,0")
        
        XCTAssert(sut.tokenType(is: .integer))
        XCTAssertNoThrow(try sut.advance(overTokenType: .integer))
        XCTAssert(sut.tokenType(is: .comma))
    }
    
    func testAllTokensAtBeginningOfGrammar() {
        let sut = TokenizerLexer<FullToken<TestToken2>>(input: "-270 0")
        
        let all = sut.allTokens()
        
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all[0].value, "-270")
        XCTAssertEqual(all[1].value, "0")
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

enum TestTokenWithIdentifier: String, TokenProtocol {
    private static let identifierLexer = (.letter | "_") + (.letter | "_" | .digit)*
    
    case openParens = "("
    case closeParens = ")"
    case identifier
    case comma
    case eof
    
    static var eofToken = TestTokenWithIdentifier.eof
    
    var tokenString: String {
        switch self {
        case .openParens:
            return "("
        case .identifier:
            return "identifier"
        case .closeParens:
            return ")"
        case .comma:
            return ","
        case .eof:
            return ""
        }
    }
    
    static func tokenType(at lexer: Lexer) -> TestTokenWithIdentifier? {
        if lexer.safeIsNextChar(equalTo: "(") {
            return .openParens
        }
        if lexer.safeIsNextChar(equalTo: ")") {
            return .closeParens
        }
        if lexer.safeIsNextChar(equalTo: ",") {
            return .comma
        }
        if lexer.safeNextCharPasses(with: Lexer.isLetter) {
            return .identifier
        }
        return nil
    }
    
    func length(in lexer: Lexer) -> Int {
        switch self {
        case .openParens, .closeParens, .comma:
            return 1
        case .identifier:
            return TestTokenWithIdentifier.identifierLexer.maximumLength(in: lexer) ?? 0
        case .eof:
            return 0
        }
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

private enum TestToken2: TokenProtocol {
    fileprivate static let floatGrammar: GrammarRule = ["-"] .. .digit+ .. ["." .. .digit+]
    
    case eof
    case comma
    case force
    case color
    case cw
    case ccw
    case integer
    case float
    
    static var eofToken: TestToken2 = .eof
    
    var tokenString: String {
        switch self {
        case .eof:
            return ""
        case .comma:
            return ","
        case .force:
            return "force"
        case .color:
            return "color"
        case .cw:
            return "cw"
        case .ccw:
            return "ccw"
        case .integer:
            return "<integer>"
        case .float:
            return "<float>"
        }
    }
    
    func length(in lexer: Lexer) -> Int {
        switch self {
        case .eof:
            return 0
        case .comma:
            return 1
        case .cw:
            return 2
        case .ccw:
            return 3
        case .force, .color:
            return 5
        case .integer:
            return (GrammarRule.digit+).maximumLength(in: lexer) ?? 0
        case .float:
            return TestToken2.floatGrammar.maximumLength(in: lexer) ?? 0
        }
    }
    
    static func tokenType(at lexer: Lexer) -> TestToken2? {
        
        if lexer.checkNext(matches: ",") {
            return .comma
        }
        
        if lexer.checkNext(matches: "force") {
            return .force
        }
        if lexer.checkNext(matches: "color") {
            return .color
        }
        if lexer.checkNext(matches: "cw") {
            return .cw
        }
        if lexer.checkNext(matches: "ccw") {
            return .ccw
        }
        
        if lexer.safeNextCharPasses(with: Lexer.isDigit) {
            let backtracker = lexer.backtracker()
            lexer.advance(while: Lexer.isDigit)
            
            if !lexer.safeIsNextChar(equalTo: ".") {
                return .integer
            }
            
            backtracker.backtrack(lexer: lexer)
        }
        
        if TestToken2.floatGrammar.passes(in: lexer) {
            return .float
        }
        
        return .eof
    }
}
