/// A tokenizer lexer provides tokenization support by wrapping a bare text lexer
/// with token recognition capabilities through a parametrized token type.
open class TokenizerLexer<T: TokenProtocol> {
    private var hasReadFirstToken = false
    
    private var current: Token = Token(value: "", tokenType: T.eofToken, range: nil)
    
    /// The lexer associated with this tokenizer lexer
    public let lexer: Lexer
    
    /// Whether the tokenizer is at the end of the input stream.
    /// When the end is reached, no more tokens can be read.
    public var isEof: Bool {
        ensureReadFirstToken()
        
        return current == Token(value: "", tokenType: T.eofToken, range: nil)
    }
    
    /// Initializes this tokenizer with a given lexer.
    public init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    /// Initializes this tokenizer with a given input string.
    public convenience init(input: String) {
        self.init(lexer: Lexer(input: input))
    }
    
    /// Gets all remaining tokens
    public func allTokens() -> [Token] {
        return Array(makeIterator())
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
        
        if let range = current.range {
            lexer.inputIndex = range.upperBound
        }
        
        readToken()
    }
    
    /// Attempts to advance from the current point, reading a given token type.
    /// If the token cannot be matched, an error is thrown.
    @discardableResult
    public func advance(over tokenType: T) throws -> Token {
        ensureReadFirstToken()
        
        if current.tokenType != tokenType {
            throw LexerError.syntaxError("Expected token '\(tokenType.tokenString)' but found '\(current.tokenType.tokenString)'")
        }
        
        lexer.skipWhitespace()
        
        return nextToken()
    }
    
    /// Attempts to advance from the current point, reading a token and passing
    /// it to a given validating function.
    ///
    /// - Parameter predicate: A predicate for validating the current token.
    /// - Returns: The token read that passed through the precidate.
    /// - Throws: A `LexerError` in case the predicate returns false.
    @discardableResult
    public func advance(matching predicate: (T) -> Bool) throws -> Token {
        ensureReadFirstToken()
        
        if !predicate(current.tokenType) {
            throw LexerError.syntaxError("Unexpected token \(current.tokenType)")
        }
        
        lexer.skipWhitespace()
        
        return nextToken()
    }
    
    /// Returns `true` iff the current token is the one provided.
    public func tokenType(is type: T) -> Bool {
        ensureReadFirstToken()
        
        return current.tokenType == type
    }
    
    /// Returns `true` if the current token type passes a given predicate
    public func tokenType(matches predicate: (T) -> Bool) -> Bool {
        return predicate(tokenType())
    }
    
    /// Consumes a given token type, if the current token matches the token type,
    /// and advances to the next token.
    ///
    /// Returns the token read, or nil, in case the current token is not of the
    /// provided type.
    @discardableResult
    public func consumeToken(ifTypeIs type: T) -> Token? {
        let tok = self.token()
        
        if tok.tokenType != type {
            return nil
        }
        
        lexer.skipWhitespace()
        
        skipToken()
        
        return tok
    }
    
    /// Returns the current token.
    public func token() -> Token {
        ensureReadFirstToken()
        
        return current
    }
    
    /// Return the current token's type
    public func tokenType() -> T {
        return token().tokenType
    }
    
    /// Creates an iterator that advances this tokenizer along each consumable
    /// token.
    ///
    /// The iterator finishes iterating before returning the end-of-file token.
    ///
    /// - Returns: An iterator for reading the tokens from this lexer.
    public func makeIterator() -> AnyIterator<Token> {
        ensureReadFirstToken()
        
        return AnyIterator {
            if self.isEof {
                return nil
            }
            
            return self.nextToken()
        }
    }
    
    /// Advances through the tokens until a predicate returns false for a token
    /// value.
    /// The method stops such that the next token is the first token the closure
    /// returned false to.
    /// The method returns automatically when end-of-file is reached.
    public func advance(until predicate: (Token) throws -> Bool) rethrows {
        while !isEof {
            if try predicate(token()) {
                return
            }
            
            skipToken()
        }
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
                current = Token(value: "", tokenType: T.eofToken, range: nil)
                return
            }
            
            let length = token.length(in: lexer)
            let endIndex = lexer.inputString.index(lexer.inputIndex, offsetBy: length)
            
            let range = lexer.inputIndex..<endIndex
            
            current = Token(value: lexer.inputString[lexer.inputIndex..<endIndex],
                            tokenType: token,
                            range: range)
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
        
        /// Range of the string the token occupies.
        /// Is nil, in case this token is a non representable token, like `.eof`.
        public var range: Range<Lexer.Index>?
        
        public init(value: Substring, tokenType: T, range: Range<Lexer.Index>?) {
            self.value = value
            self.tokenType = tokenType
            self.range = range
        }
        
        public init(value: String, tokenType: T, range: Range<Lexer.Index>?) {
            self.value = Substring(value)
            self.tokenType = tokenType
            self.range = range
        }
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
