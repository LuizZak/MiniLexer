/// A tokenizer lexer provides tokenization support by wrapping a bare text lexer
/// with token recognition capabilities through a parametrized token type.
public class TokenizerLexer<T: TokenType> {
    private var hasReadFirstToken = false
    
    private var current: Token = Token(value: "", tokenType: T.eofToken)
    
    /// The lexer associated with this tokenizer lexer
    public let lexer: Lexer
    
    /// Whether the tokenizer is at the end of the input stream.
    /// When the end is reached, no more tokens can be read.
    public var isEof: Bool {
        ensureReadFirstToken()
        
        return current == Token(value: "", tokenType: T.eofToken)
    }
    
    /// Initializes this tokenizer with a given lexer.
    public init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    /// Initializes this tokenizer with a given input string.
    public convenience init(input: String) {
        self.init(lexer: Lexer(input: input))
    }
    
    /// Returns the current token and advances to the next token.
    public func nextToken() -> Token {
        defer {
            skipToken()
        }
        
        ensureReadFirstToken()
        
        return current
    }
    
    /// Skips to the next available token in the stream.
    public func skipToken() {
        ensureReadFirstToken()
        
        try? current.tokenType.advance(in: lexer)
        readToken()
    }
    
    /// Attempts to advance from the current point, reading a given token type.
    /// If the token cannot be matched, an error is thrown.
    public func advance(over tokenType: T) throws {
        ensureReadFirstToken()
        
        if current.tokenType != tokenType {
            throw LexerError.syntaxError("Missing expected token '\(tokenType.tokenString)'")
        }
        
        lexer.skipWhitespace()
        
        try tokenType.advance(in: lexer)
        
        readToken()
    }
    
    /// Returns `true` iff the current token is the one provided.
    public func isToken(_ type: T) -> Bool {
        ensureReadFirstToken()
        
        return current.tokenType == type
    }
    
    /// Consumes a given token type, if the current token matches the token type,
    /// and advances to the next token.
    ///
    /// Returns the token read, or nil, in case the current token is not of the
    /// provided type.
    @discardableResult
    public func consumeToken(ifTypeIs type: T) -> Token? {
        if self.token().tokenType != type {
            return nil
        }
        
        lexer.skipWhitespace()
        
        try? type.advance(in: lexer)
        readToken()
        
        return current
    }
    
    /// Returns the current token.
    public func token() -> Token {
        ensureReadFirstToken()
        
        return current
    }
    
    private func ensureReadFirstToken() {
        if hasReadFirstToken {
            return
        }
        
        hasReadFirstToken = true
        readToken()
    }
    
    private func readToken() {
        lexer.withTemporaryIndex {
            lexer.skipWhitespace()
            
            // Check all available tokens
            guard let token = lexer.withTemporaryIndex(changes: { T.tokenType(at: lexer) }) else {
                current = Token(value: "", tokenType: T.eofToken)
                return
            }
            
            let length = token.length(in: lexer)
            let endIndex = lexer.inputString.index(lexer.inputIndex, offsetBy: length)
            
            current = Token(value: lexer.inputString[lexer.inputIndex..<endIndex], tokenType: token)
        }
    }
    
    /// Provides a backtracker which can be used to backtrack this tokenizer lexer's
    /// state to the point at which this method was called.
    public func backtracker() -> Backtrack {
        ensureReadFirstToken()
        
        return Backtrack(lexer: self)
    }
    
    /// Performs an operation, backtracking the tokenizer lexer after it's completed.
    ///
    /// If an error is thrown, the lexer is still rewind to its previous state.
    public func backtracking<U>(do block: () throws -> (U)) rethrows -> U {
        let backtrack = backtracker()
        defer {
            backtrack.backtrack()
        }
        
        return try block()
    }
    
    /// A structured token type, with the string contents at the point at which
    /// it was read.
    public struct Token: Equatable {
        public var value: Substring
        public var tokenType: T
    }
    
    /// A backtracker instance from a `.backtracker()` call.
    public class Backtrack {
        let lexer: TokenizerLexer
        let index: Lexer.Index
        let token: Token
        private var didBacktrack: Bool
        
        fileprivate init(lexer: TokenizerLexer) {
            self.lexer = lexer
            self.index = lexer.lexer.inputIndex
            token = lexer.current
            didBacktrack = false
        }
        
        /// Backtracks the associated lexer's state to the point at which this
        /// backtracker was created.
        public func backtrack() {
            if didBacktrack {
                return
            }
            
            lexer.lexer.inputIndex = index
            lexer.current = token
            didBacktrack = true
        }
    }
}
