/// A protocol for tokens that can be consumed serially with a `TokenizerLexer`.
public protocol TokenProtocol: Equatable {
    associatedtype Segment: StringProtocol = String
    
    /// Gets the token that represents the end-of-file of an input string.
    ///
    /// It is important that this token is unique since its usage delimits the
    /// end of the input sequence on a tokenizer lexer and marks the end of token
    /// sequences.
    static var eofToken: Self { get }
    
    /// Returns a token at a given parser index on a parser.
    /// Returns nil, if no token could be read.
    ///
    /// It is not required for conformers to return the state of the parser to the
    /// previous state prior to the calling of this method (i.e. `parser.withTemporaryIndex`).
    ///
    /// - Parameter parser: Parser to attempt to tokenize.
    /// - Returns: A token at the current parser point, or nil, in case no token
    /// could be read.
    static func tokenType(at parser: Parser) -> Self?
    
    /// Requests the length of this token type when applied to a given parser.
    /// If this token cannot be possibly consumed from the parser, conformers must
    /// return `0`.
    ///
    /// It is not required for tokens to return the state of the parser to the
    /// previous state prior to the calling of this method.
    func length(in parser: Parser) -> Int
    
    /// Gets the string representation of this token value
    var tokenString: Segment { get }
}
