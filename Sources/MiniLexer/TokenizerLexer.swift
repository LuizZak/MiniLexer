/// A tokenizer lexer provides tokenization support by wrapping a bare text lexer
/// with token recognition capabilities through a parametrized token type.
open class TokenizerLexer<T: TokenProtocol> {
    /// Used to check and re-tokenize a lexer if its index is changed externally.
    private var lastLexerIndex: Lexer.Index?
    
    private var current: T = T.eofToken
    
    /// The lexer associated with this tokenizer lexer
    public let lexer: Lexer
    
    /// Whether the tokenizer is at the end of the input stream.
    /// When the end is reached, no more tokens can be read.
    public var isEof: Bool {
        ensureLexerIndexConsistent()
        
        return current == T.eofToken
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
    public func allTokens() -> [T] {
        return Array(makeIterator())
    }
    
    /// Returns the current token and advances to the next token.
    public func nextToken() -> T {
        defer {
            skipToken()
        }
        
        ensureLexerIndexConsistent()
        
        return current
    }
    
    /// Skips to the next available token in the stream.
    public func skipToken() {
        ensureLexerIndexConsistent()
        
        let length = current.length(in: lexer)
        if length > 0 {
            recordingLexerState {
                do {
                    $0.skipWhitespace()
                    try $0.advanceLength(length)
                } catch {
                    _=$0.consumeRemaining()
                    current = T.eofToken
                }
            }
        }
        
        readToken()
    }
    
    /// Attempts to advance from the current point, reading a given token type.
    /// If the token cannot be matched, an error is thrown.
    @discardableResult
    public func advance(over tokenType: T) throws -> T {
        ensureLexerIndexConsistent()
        
        if current != tokenType {
            throw lexer.syntaxError("Expected token '\(tokenType.tokenString)' but found '\(current.tokenString)'")
        }
        
        recordingLexerState {
            $0.skipWhitespace()
        }
        
        return nextToken()
    }
    
    /// Attempts to advance from the current point, reading a token and passing
    /// it to a given validating function.
    ///
    /// - Parameter predicate: A predicate for validating the current token.
    /// - Returns: The token read that passed through the precidate.
    /// - Throws: A `LexerError` in case the predicate returns false.
    @discardableResult
    public func advance(matching predicate: (T) -> Bool) throws -> T {
        ensureLexerIndexConsistent()
        
        if !predicate(current) {
            throw lexer.syntaxError("Unexpected token \(current)")
        }
        
        recordingLexerState {
            $0.skipWhitespace()
        }
        
        return nextToken()
    }
    
    /// Returns `true` iff the current token is the one provided.
    public func tokenType(is type: T) -> Bool {
        ensureLexerIndexConsistent()
        
        return current == type
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
    public func consumeToken(ifTypeIs type: T) -> T? {
        let tok = self.token()
        
        if tok != type {
            return nil
        }
        
        recordingLexerState {
            $0.skipWhitespace()
        }
        
        skipToken()
        
        return tok
    }
    
    /// Returns the current token.
    public func token() -> T {
        ensureLexerIndexConsistent()
        
        return current
    }
    
    /// Return the current token's type
    public func tokenType() -> T {
        return token()
    }
    
    /// Creates an iterator that advances this tokenizer along each consumable
    /// token.
    ///
    /// The iterator finishes iterating before returning the end-of-file token.
    ///
    /// - Returns: An iterator for reading the tokens from this lexer.
    public func makeIterator() -> AnyIterator<T> {
        ensureLexerIndexConsistent()
        
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
    public func advance(until predicate: (T) throws -> Bool) rethrows {
        while !isEof {
            if try predicate(token()) {
                return
            }
            
            skipToken()
        }
    }
    
    /// Applies changes to the state of the lexer, making sure we record the final
    /// state correctly so we can later compare states to ensure lexer consistency.
    private func recordingLexerState(do closure: (Lexer) -> Void) {
        closure(lexer)
        lastLexerIndex = lexer.inputIndex
    }
    
    private func ensureLexerIndexConsistent() {
        if lexer.inputIndex == lastLexerIndex {
            return
        }
        
        lastLexerIndex = lexer.inputIndex
        readToken()
    }
    
    private func readToken() {
        lexer.withTemporaryIndex {
            lexer.skipWhitespace()
            
            // Check all available tokens
            guard let token = lexer.withTemporaryIndex(changes: { T.tokenType(at: lexer) }) else {
                current = T.eofToken
                return
            }
            
            current = token
        }
    }
    
    /// Provides a backtracker which can be used to backtrack this tokenizer lexer's
    /// state to the point at which this method was called.
    public func backtracker() -> Backtrack {
        ensureLexerIndexConsistent()
        
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
    
    /// A backtracker instance from a `.backtracker()` call.
    public class Backtrack {
        let lexer: TokenizerLexer
        let index: Lexer.Index
        let token: T
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
