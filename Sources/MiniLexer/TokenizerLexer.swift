/// A tokenizer lexer provides tokenization support by wrapping a bare text lexer
/// with token recognition capabilities through a parametrized token type.
open class TokenizerLexer<T: TokenProtocol> {
    public typealias Token = T
    
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
        
        let length: Int = lexer.withTemporaryIndex {
            lexer.skipWhitespace()
            return current.length(in: lexer)
        }
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
    
    /// Attempts to advance from the current point, reading a given token.
    /// If the token cannot be matched, an error is thrown.
    @discardableResult
    public func advance(over token: T) throws -> T {
        ensureLexerIndexConsistent()
        
        if current != token {
            throw lexer.syntaxError("Expected token '\(token.tokenString)' but found '\(current.tokenString)'")
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
    
    /// Returns the current token.
    public func token() -> T {
        ensureLexerIndexConsistent()
        
        return current
    }
    
    /// Returns `true` iff the current token is the one provided.
    public func token(is type: T) -> Bool {
        return token() == type
    }
    
    /// Returns `true` if the current token passes a given predicate
    public func token(matches predicate: (T) -> Bool) -> Bool {
        return predicate(token())
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

public extension TokenizerLexer where T: TokenWrapper {
    
    /// Returns `true` iff the current token is the one provided.
    func tokenType(is type: T.Token) -> Bool {
        return tokenType() == type
    }
    
    /// Returns `true` if the current token type passes a given predicate
    func tokenType(matches predicate: (T.Token) -> Bool) -> Bool {
        return predicate(tokenType())
    }
    
    /// Return the current token's type
    func tokenType() -> T.Token {
        return token().tokenType
    }
    
    /// Attempts to advance from the current point, reading a given token type.
    /// If the token cannot be matched, an error is thrown.
    @discardableResult
    func advance(overTokenType tokenType: T.Token) throws -> T {
        if self.tokenType() != tokenType {
            throw lexer.syntaxError("Expected token '\(tokenType.tokenString)' but found '\(self.tokenType().tokenString)'")
        }
        
        recordingLexerState {
            $0.skipWhitespace()
        }
        
        return nextToken()
    }
    
    /// Consumes a given token type, if the current token matches the token type,
    /// and advances to the next token.
    ///
    /// Returns the token read, or nil, in case the current token is not of the
    /// provided type.
    @discardableResult
    func consumeToken(ifTypeIs type: T.Token) -> T? {
        let tok = self.token()
        
        if tok.tokenType != type {
            return nil
        }
        
        recordingLexerState {
            $0.skipWhitespace()
        }
        
        skipToken()
        
        return tok
    }
    
}

public protocol TokenWrapper: TokenProtocol {
    associatedtype Token: TokenProtocol
    
    var tokenType: Token { get }
}

/// A structured Token type that can wrap over some simpler token types that don't
/// store a lot of data or are singletons, like enum-based tokens.
public struct FullToken<T: TokenProtocol>: TokenWrapper {
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

extension FullToken: TokenProtocol {
    public static var eofToken: FullToken {
        return FullToken(value: "", tokenType: T.eofToken, range: nil)
    }
    
    public func length(in lexer: Lexer) -> Int {
        return tokenType.length(in: lexer)
    }
    
    public var tokenString: T.Segment {
        return tokenType.tokenString
    }
    
    public static func tokenType(at lexer: Lexer) -> FullToken<T>? {
        let bt = lexer.backtracker()
        guard let t = T.tokenType(at: lexer) else {
            return nil
        }
        
        bt.backtrack(lexer: lexer)
        
        let length = t.length(in: lexer)
        
        bt.backtrack(lexer: lexer)
        
        if length > 0 {
            let range = lexer.inputIndex..<lexer.inputString.index(lexer.inputIndex, offsetBy: length)
            
            return FullToken(value: lexer.inputString[range], tokenType: t, range: range)
        }
        
        return nil
    }
}
