/// A protocol for tokens that can be consumed serially with a `TokenizerLexer`.
public protocol TokenProtocol: Equatable {
    /// Gets the token that represents the end-of-file of an input string.
    ///
    /// It is important that this token is unique since its usage delimits the
    /// end of the input sequence on a tokenizer lexer and marks the end of token
    /// sequences.
    static var eofToken: Self { get }
    
    /// Returns a token at a given lexer index on a lexer.
    /// Returns nil, if no token could be read.
    ///
    /// It is not required for conformers to return the state of the lexer to the
    /// previous state prior to the calling of this method (i.e. `lexer.withTemporaryIndex`).
    ///
    /// - Parameter lexer: Lexer to attempt to tokenize.
    /// - Returns: A token at the current lexer point, or nil, in case no token
    /// could be read.
    static func tokenType(at lexer: Lexer) -> Self?
    
    /// Requests the length of this token type when applied to a given lexer.
    /// If this token cannot be possibly consumed from the lexer, conformers must
    /// return `0`.
    ///
    /// It is not required for tokens to return the state of the lexer to the
    /// previous state prior to the calling of this method.
    func length(in lexer: Lexer) -> Int
    
    /// Advances the lexer passed in by whatever length this token takes in the
    /// input stream.
    ///
    /// Throws an error, in case the stream could not be advanced further.
    func advance(in lexer: Lexer) throws
    
    /// Gets the string representation of this token value
    var tokenString: String { get }
}
